import 'api/source.dart';
import 'models.dart';

/// Holds what the app is currently using.
class Session {
  static AppDetails? app;
  static ContentSource? source;

  static ContentSource get src => source!;
}
