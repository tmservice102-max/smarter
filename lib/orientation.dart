import 'package:flutter/services.dart';

/// Go back to portrait after a full-screen player, then allow rotation again.
/// iOS keeps the last forced orientation if we only re-allow all of them.
void restoreOrientation() {
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  Future.delayed(const Duration(milliseconds: 600), () {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  });
}
