import 'package:flutter/foundation.dart';

import 'api/source.dart';
import 'library.dart';
import 'models.dart';

/// Holds what the app is currently using.
class Session {
  static AppDetails? app;

  /// Right-to-left layout for the whole app (panel is_rtl, IfSupported.isRTL).
  static final rtl = ValueNotifier<bool>(false);

  /// Where the current account's content comes from.
  static ContentSource get src => Library.I.source;
}
