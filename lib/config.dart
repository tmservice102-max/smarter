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

  /// Timeout for network calls.
  static const timeout = Duration(seconds: 30);
}
