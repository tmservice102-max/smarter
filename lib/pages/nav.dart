// Where to go after splash / login, like ThemeHelper in the Android app.
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../library.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'home_page.dart';
import 'playlist_home_page.dart';
import 'select_player_page.dart';
import 'users_list_page.dart';

void openSelectPlayer(BuildContext context) => go(context, const SelectPlayerPage(), clear: true);

/// [fresh]: right after logging in, so the home screen downloads Live TV,
/// Movies and Series by itself.
void openHome(BuildContext context, {bool fresh = false}) {
  final a = Store.currentAccount;
  if (a == null) {
    openSelectPlayer(context);
  } else if (a.kind == 'playlist') {
    go(context, const PlaylistHomePage(), clear: true);
  } else {
    go(context, HomePage(autoLoad: fresh), clear: true);
  }
}

/// Open a web page inside the app (WebActivity).
Future<void> openWeb(String url) async {
  final u = Uri.tryParse(url);
  if (u == null) return;
  await launchUrl(u, mode: LaunchMode.inAppBrowserView);
}

Future<void> openExternal(String url) async {
  final u = Uri.tryParse(url);
  if (u == null) return;
  await launchUrl(u, mode: LaunchMode.externalApplication);
}

void openTerms() => openWeb('${AppConfig.panelUrl}/terms');
void openPrivacy() => openWeb('${AppConfig.panelUrl}/privacy-policy');

/// "Sign out" from the home screen (iv_profile_re): back to the users list.
Future<void> signOut(BuildContext context) async {
  final ok = await appDialog(context, icon: 'ic_logout', title: S.logout, msg: S.sure_logout);
  if (!ok || !context.mounted) return;
  try {
    await Library.I.clearAll();
  } catch (_) {}
  await Store.setCurrent(null);
  Library.reset();
  if (!context.mounted) return;
  toast(context, S.logout_success);
  go(context, const UsersListPage(), clear: true);
}
