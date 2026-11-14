// Live channel player (ExoPlayerLiveActivity + custom_controls_live).
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../ads.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'multi_screen_page.dart';
import 'settings_page.dart';
import 'player_kit.dart';

class PlayerLivePage extends StatefulWidget {
  final List<StreamItem> channels;
  final int index;
  const PlayerLivePage({super.key, required this.channels, this.index = 0});
  @override
  State<PlayerLivePage> createState() => _PlayerLivePageState();
}

class _PlayerLivePageState extends State<PlayerLivePage> {
  late final Player _player = newPlayer();
  late final VideoController _video = VideoController(_player);
  final List<StreamSubscription> _subs = [];
  late int _i = widget.index.clamp(0, widget.channels.isEmpty ? 0 : widget.channels.length - 1);

  bool _controls = true;
  bool _list = false;
  bool _info = false;
  bool _locked = false;
  bool _error = false;
  bool _buffering = true;
  bool _playing = false;
  int _fit = 0;
  EpgEntry? _epg;
  Timer? _hide;
  Timer? _clock;
  int _errorToken = 0;

  StreamItem get ch => widget.channels[_i];

  // ExoPlayerLiveActivity.startTimer: one rewarded ad after N minutes.
  final _reward = RewardTimer('reward_ad_on_live');

  @override
  void initState() {
    super.initState();
    playerEnter();
    _subs.add(
      _player.stream.playing.listen((v) {
        setState(() => _playing = v);
        if (v) _reward.start(playing: () => _player.state.playing, pause: _player.pause, play: _player.play);
      }),
    );
    _subs.add(_player.stream.buffering.listen((v) => setState(() => _buffering = v)));
    _subs.add(_player.stream.height.listen((_) => setState(() {})));
    _subs.add(_player.stream.tracks.listen((_) => setState(() {})));
    _subs.add(
      _player.stream.position.listen((p) {
        if (_error && p > Duration.zero) setState(() => _error = false);
      }),
    );
    _subs.add(
      _player.stream.error.listen((e) {
        if (e.isEmpty) return;
        // Small errors happen while a stream keeps playing; only show the
        // retry button if nothing plays after a few seconds.
        final token = _errorToken;
        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted || token != _errorToken) return;
          final st = _player.state;
          final ok = st.position > Duration.zero || (st.playing && (st.width ?? 0) > 0);
          if (!ok) setState(() => _error = true);
        });
      }),
    );
    _clock = Timer.periodic(const Duration(seconds: 20), (_) => setState(() {}));
    if (widget.channels.isNotEmpty) _play(_i);
    _autoHide();
  }

  void _play(int i) {
    if (widget.channels.isEmpty) return;
    _i = (i + widget.channels.length) % widget.channels.length;
    _errorToken++;
    _error = false;
    _epg = null;
    Store.addRecent(ch);
    _player.open(media(Session.src.streamUrl(ch)));
    _loadEpg(ch);
    setState(() {});
  }

  Future<void> _loadEpg(StreamItem c) async {
    try {
      final list = await Session.src.shortEpg(c);
      final now = list.where((e) => e.isNow).toList();
      if (!mounted || ch.key != c.key) return;
      setState(() => _epg = now.isNotEmpty ? now.first : null);
    } catch (_) {}
  }

  void _autoHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 5), () {
      if (mounted && !_list && !_info) setState(() => _controls = false);
    });
  }

  void _toggleControls() {
    setState(() => _controls = !_controls);
    if (_controls) _autoHide();
  }

  @override
  void dispose() {
    _reward.cancel();
    _hide?.cancel();
    _clock?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    playerLeave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Dim.init(context);
    if (widget.channels.isEmpty) {
      return Scaffold(backgroundColor: Colors.black, body: Empty(S.err_no_data_found));
    }
    final listW = 234.sdp;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video (moves right when the channel list is open)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            left: _list ? listW : (_info ? 235.sdp : 0),
            top: _list ? 30.sdp : 0,
            right: _list ? 10.sdp : 0,
            bottom: _list ? 30.sdp : 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_list || _info) {
                  setState(() => _list = _info = false);
                  _autoHide();
                } else {
                  _toggleControls();
                }
              },
              child: Video(controller: _video, controls: NoVideoControls, fit: playerFits[_fit]),
            ),
          ),
          if (!_list && !_info && !_locked) ...[
            // Center: loader / retry / play-pause
            Center(
              child: _error
                  ? RoundBtn('ic_reset', onTap: () => _play(_i))
                  : _buffering && !_playing
                  ? const Loader(size: 38)
                  : _controls
                  ? RoundBtn(
                      _playing ? 'ic_pause' : 'ic_play',
                      size: 40,
                      onTap: () {
                        _player.playOrPause();
                        _autoHide();
                      },
                    )
                  : const SizedBox(),
            ),
            if (_controls) ..._overlay(),
          ],
          if (_locked) Positioned.fill(child: LockOverlay(onUnlock: () => setState(() => _locked = false))),
          if (_list) Positioned(left: 0, top: 0, bottom: 0, width: listW, child: _channelList()),
          if (_info)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: TracksPanel(player: _player, onClose: () => setState(() => _info = false)),
            ),
        ],
      ),
    );
  }

  List<Widget> _overlay() {
    final tr = _player.state.tracks;
    final fav = Store.isFavorite(ch);
    return [
      // Top bar
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: Container(
          decoration: topShade,
          padding: EdgeInsets.fromLTRB(15.sdp, 10.sdp, 15.sdp, 8.sdp),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                RoundBtn('ic_player_back', size: 34, onTap: () => Navigator.maybePop(context)),
                SizedBox(width: 10.sdp),
                // LIVE TV and resolution chips, the clock below them.
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.sdp),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PChip(S.live_tv_home.toUpperCase()),
                          SizedBox(width: 5.sdp),
                          PChip(resolutionText(_player.state.height), bold: false),
                        ],
                      ),
                    ),
                    PChip(clockText(DateTime.now()), bold: false),
                  ],
                ),
                const Spacer(),
                const BatteryIcon(),
                _gap,
                PBtn(
                  fav ? 'ic_favorite' : 'ic_favorite_border',
                  pad: 4,
                  onTap: () async {
                    final added = await Store.toggleFavorite(ch);
                    if (!mounted) return;
                    toast(context, added ? S.fav_success : S.fav_remove_success);
                    setState(() {});
                  },
                ),
                if (tr.subtitle.length > 2) ...[_gap, PBtn('ic_closed_captioning', onTap: _openInfo)],
                if (tr.video.length > 3) ...[_gap, PBtn('ic_hd', onTap: _openInfo)],
                if (tr.audio.length > 3) ...[_gap, PBtn('ic_audiotrack', onTap: _openInfo)],
                if (Store.currentAccount?.type == AccountType.xtream) ...[
                  _gap,
                  PBtn(
                    'ic_file_settings',
                    onTap: () async {
                      await go(context, const StreamFormatPage());
                      if (mounted) _play(_i);
                    },
                  ),
                ],
                _gap,
                PBtn('ic_information', pad: 4, onTap: _openInfo),
                _gap,
                PBtn(
                  'ic_unlock',
                  onTap: () => setState(() {
                    _locked = true;
                    _controls = false;
                  }),
                ),
                _gap,
                PBtn('ic_close', pad: 4, onTap: () => setState(() => _controls = false)),
              ],
            ),
          ),
        ),
      ),
      // Bottom bar
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          decoration: bottomShade,
          padding: EdgeInsets.fromLTRB(15.sdp, 25.sdp, 15.sdp, 10.sdp),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    PBtn(
                      'ic_skip_previous',
                      size: 38,
                      pad: 6,
                      onTap: () {
                        _play(_i - 1);
                        _autoHide();
                      },
                    ),
                    SizedBox(width: 10.sdp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          T(S.now_playing.toUpperCase(), size: 10, color: C.primary, weight: FontWeight.bold),
                          T(ch.name, size: 13, lines: 1, weight: FontWeight.bold),
                        ],
                      ),
                    ),
                    if (_epg != null) ...[
                      SizedBox(width: 10.sdp),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            T(
                              '${clockText(_epg!.start)} - ${clockText(_epg!.end)}',
                              size: 10,
                              color: C.primary,
                              weight: FontWeight.bold,
                            ),
                            T(_epg!.title, size: 13, lines: 1, weight: FontWeight.bold),
                          ],
                        ),
                      ),
                    ],
                    PBtn(
                      'ic_skip_next',
                      size: 38,
                      pad: 6,
                      onTap: () {
                        _play(_i + 1);
                        _autoHide();
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12.sdp),
                Row(
                  children: [
                    _action(
                      'list_channels',
                      S.channels,
                      () => setState(() {
                        _list = true;
                        _controls = false;
                      }),
                    ),
                    _action('ic_multiple_screen', S.multiple_screen, () {
                      go(context, MultiScreenPage(first: ch), replace: true);
                    }),
                    _action('ic_crop', S.aspect_ratio, () {
                      setState(() => _fit = (_fit + 1) % playerFits.length);
                      toast(context, fitLabel(playerFits[_fit]));
                      _autoHide();
                    }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget get _gap => SizedBox(width: 7.sdp);

  void _openInfo() => setState(() {
    _info = true;
    _controls = false;
  });

  Widget _action(String icon, String text, VoidCallback onTap) => Expanded(
    child: Tap(
      onTap: onTap,
      builder: (f) => Container(
        padding: EdgeInsets.all(6.sdp),
        color: f ? const Color(0x2DFFFFFF) : Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Ic(icon, size: 20.sdp),
            SizedBox(width: 6.sdp),
            Flexible(child: T(text, size: 12, lines: 1)),
          ],
        ),
      ),
    ),
  );

  /// row_player_live list on the left: number and name, then the logo in
  /// a thin bordered box.
  Widget _channelList() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        right: false,
        child: ListView.builder(
          controller: ScrollController(initialScrollOffset: (_i * 75.sdp - 100.sdp).clamp(0, double.infinity)),
          padding: EdgeInsets.fromLTRB(15.sdp, 10.sdp, 30.sdp, 10.sdp),
          itemCount: widget.channels.length,
          itemBuilder: (_, i) {
            final c = widget.channels[i];
            final color = i == _i ? C.select : Colors.white;
            return Tap(
              onTap: () => _play(i),
              builder: (f) => Container(
                margin: EdgeInsets.only(top: 5.sdp),
                padding: EdgeInsets.all(5.sdp),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22),
                  borderRadius: BorderRadius.circular(5.sdp),
                  border: Border.all(color: f ? Colors.white : const Color(0xFF1E1F22), width: 1.sdp),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55.sdp,
                        child: Padding(
                          padding: EdgeInsets.all(5.sdp),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              T('${i + 1}', size: 13, color: color, weight: FontWeight.bold),
                              T(c.name, size: 12, color: color, lines: 1),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 55.sdp,
                      height: 55.sdp,
                      margin: EdgeInsets.all(2.sdp),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2.sdp),
                        border: Border.all(color: const Color(0x32FFFFFF), width: 1.sdp),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2.sdp),
                        child: NetImg(c.icon, placeholder: 'placeholder_live', fit: BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
