// AdMob like the Android app (Helper, AdManagerInterAdmob, RewardAdAdmob,
// GDPRChecker). What to show comes from the panel's ads_details:
// - banners on the Live TV, Movies, Series and EPG screens,
// - an interstitial every N taps on list items,
// - a rewarded ad after N minutes of playback.
import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

import 'config.dart';
import 'session.dart';

class Ads {
  static Completer<bool>? _ready;
  static InterstitialAd? _inter;
  static RewardedAd? _reward;
  static bool _interLoading = false;
  static bool _rewardLoading = false;
  static int _count = 0;
  static bool _ok = false; // AdMob started and ads may be requested

  static Map<String, dynamic> get _cfg => Session.app?.ads ?? const {};
  static bool _f(String k) => '${_cfg[k] ?? ''}'.trim().toLowerCase() == 'true';
  static int _n(String k) => int.tryParse('${_cfg[k] ?? ''}'.trim()) ?? 0;

  /// Ads are on in the panel and the network is AdMob.
  static bool get on =>
      (Platform.isAndroid || Platform.isIOS) &&
      _f('ad_status') &&
      '${_cfg['ad_network'] ?? ''}'.trim().toLowerCase() == 'admob';

  /// Ad unit IDs from the panel. On iPhone the panel's ios_* fields are used
  /// (Google needs separate iOS IDs); until they're filled in, test builds use
  /// the test IDs in AppConfig and App Store builds show no ads.
  static String _id(String key, String iosFallback) {
    String v(String k) => '${_cfg[k] ?? ''}'.trim();
    if (!Platform.isIOS) return v(key);
    final ios = v('ios_$key');
    if (ios.isNotEmpty) return ios;
    return kReleaseMode ? '' : iosFallback;
  }

  static String get _bannerId => _id('banner_ad_id', AppConfig.iosBannerAdId);
  static String get _interId => _id('interstital_ad_id', AppConfig.iosInterstitialAdId);
  static String get _rewardId => _id('reward_ad_id', AppConfig.iosRewardAdId);

  static bool get bannerMovie => _f('banner_movie');
  static bool get bannerSeries => _f('banner_series');
  static bool get bannerEpg => _f('banner_epg');
  static bool get _interOn => _f('interstital_ad') && _interId.isNotEmpty;
  static int get _every => _n('interstital_ad_click') < 1 ? 1 : _n('interstital_ad_click');
  static int get rewardMinutes => _n('reward_minutes');
  static bool _anyReward() => [
    'reward_ad_on_movie',
    'reward_ad_on_episodes',
    'reward_ad_on_live',
    'reward_ad_on_single',
    'reward_ad_on_local',
  ].any(_f);

  /// Rewarded ads are on for this kind of video (reward_ad_on_movie, ...).
  static bool rewardFor(String key) => _f(key) && rewardMinutes > 0 && _rewardId.isNotEmpty;

  /// Starts AdMob once the panel settings are loaded (home screen), after the
  /// consent form where the law needs one. Completes with false when ads are off.
  static Future<bool> start() {
    if (_ready != null) return _ready!.future;
    final c = _ready = Completer<bool>();
    () async {
      if (!on) return c.complete(false);
      if (_bannerId.isEmpty && _interId.isEmpty && _rewardId.isEmpty) return c.complete(false);
      try {
        await _consent();
        // Like GDPRChecker.canLoadAd: only "required but not given" blocks ads.
        final st = await ConsentInformation.instance.getConsentStatus();
        if (st == ConsentStatus.required) return c.complete(false);
        // iPhone: Apple's "Allow tracking?" prompt (App Tracking Transparency),
        // asked once after the consent form. Ads still show if the user says no.
        if (Platform.isIOS) {
          try {
            if (await AppTrackingTransparency.trackingAuthorizationStatus ==
                TrackingStatus.notDetermined) {
              await AppTrackingTransparency.requestTrackingAuthorization();
            }
          } catch (_) {}
        }
        await MobileAds.instance.initialize();
        _ok = true;
        if (_interOn) _loadInter();
        if (_anyReward() && _rewardId.isNotEmpty) _loadReward();
        c.complete(true);
      } catch (_) {
        if (!c.isCompleted) c.complete(false);
      }
    }();
    return c.future;
  }

  static Future<void> _consent() {
    final done = Completer<void>();
    void finish([_]) {
      if (!done.isCompleted) done.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => ConsentForm.loadAndShowConsentFormIfRequired(finish).catchError(finish),
      finish,
    );
    return done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
  }

  static void _loadInter() {
    if (_inter != null || _interLoading) return;
    _interLoading = true;
    InterstitialAd.load(
      adUnitId: _interId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interLoading = false;
          _inter = ad;
        },
        onAdFailedToLoad: (_) => _interLoading = false,
      ),
    );
  }

  static void _loadReward() {
    if (_reward != null || _rewardLoading) return;
    _rewardLoading = true;
    RewardedAd.load(
      adUnitId: _rewardId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardLoading = false;
          _reward = ad;
        },
        onAdFailedToLoad: (_) => _rewardLoading = false,
      ),
    );
  }

  /// Helper.showInterAd: every [interstital_ad_click] taps, shows the
  /// interstitial first, then runs [next].
  static void inter(VoidCallback next) {
    if (!_ok || !_interOn) {
      next();
      return;
    }
    _count++;
    final ad = _inter;
    if (_count % _every != 0 || ad == null) {
      if (ad == null) _loadInter();
      next();
      return;
    }
    _inter = null;
    var called = false;
    void after(InterstitialAd a) {
      a.dispose();
      _loadInter();
      if (!called) {
        called = true;
        next();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: after,
      onAdFailedToShowFullScreenContent: (a, _) => after(a),
    );
    ad.show();
  }

  /// Shows the rewarded ad if one is ready. [paused] runs before it shows and
  /// [resumed] after it closes, so the video doesn't play under the ad.
  static bool showReward({VoidCallback? paused, VoidCallback? resumed}) {
    final ad = _reward;
    if (!_ok) return false;
    if (ad == null) {
      _loadReward();
      return false;
    }
    _reward = null;
    void after(RewardedAd a) {
      a.dispose();
      _loadReward();
      resumed?.call();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: after,
      onAdFailedToShowFullScreenContent: (a, _) => after(a),
    );
    paused?.call();
    ad.show(onUserEarnedReward: (_, _) {});
    return true;
  }
}

/// The player's reward countdown (ExoPlayerActivity.startTimer): starts the
/// first time the video plays and shows one rewarded ad when it runs out.
class RewardTimer {
  final String key;
  Timer? _t;
  RewardTimer(this.key);

  void start({required bool Function() playing, required VoidCallback pause, required VoidCallback play}) {
    if (_t != null || !Ads.on || !Ads.rewardFor(key)) return;
    _t = Timer(Duration(minutes: Ads.rewardMinutes), () async {
      if (!await Ads.start()) return;
      final was = playing();
      Ads.showReward(paused: pause, resumed: () => was ? play() : null);
    });
  }

  void cancel() => _t?.cancel();
}

/// A 320x50 AdMob banner (Helper.showBannerAd). Takes no space until an ad
/// has loaded, and none at all when [show] is false or ads are off.
class AdBanner extends StatefulWidget {
  final bool show;
  const AdBanner({super.key, required this.show});
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.show && Ads.on && Ads._bannerId.isNotEmpty) _load();
  }

  Future<void> _load() async {
    if (!await Ads.start() || !mounted) return;
    _ad = BannerAd(
      adUnitId: Ads._bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: AdSize.banner.width.toDouble(),
      height: AdSize.banner.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
