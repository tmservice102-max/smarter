import 'api/source.dart';
import 'library.dart';
import 'models.dart';

/// Holds what the app is currently using.
class Session {
  static AppDetails? app;

  /// Where the current account's content comes from.
  static ContentSource get src => Library.I.source;
}
