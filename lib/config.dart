/// App-wide settings. Change these to rebrand the app.
class AppConfig {
  /// Name shown in the app.
  static const appName = 'IPTV SMARTER PRO';
  static const version = '1.1.0';

  /// Your admin panel (the PHP backend). No trailing slash.
  static const panelUrl = 'https://smartersapp.org';

  /// Must match "Package name" in the panel settings (envato_package_name).
  static const applicationId = 'nemosofts.playersapp';

  /// Key in the panel's JSON replies (API_HEADER_APP in the panel's .env).
  static const apiHeader = 'NEMOSOFTS_APP';

  /// AdMob on iPhone. The panel's ad IDs are for the Android app, and Google
  /// needs separate IDs for an iOS app. These are Google's sample test IDs
  /// (they show "Test Ad"). Before the App Store release, create an iOS app
  /// in AdMob, put its ad unit IDs here and its app ID in
  /// ios/Runner/Info.plist (GADApplicationIdentifier).
  static const iosBannerAdId = 'ca-app-pub-3940256099942544/2934735716';
  static const iosInterstitialAdId = 'ca-app-pub-3940256099942544/4411468910';
  static const iosRewardAdId = 'ca-app-pub-3940256099942544/1712485313';

  /// Timeout for network calls.
  static const timeout = Duration(seconds: 30);
}
