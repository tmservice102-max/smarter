// Log in with a user saved in the panel (activation code / device id).
import 'package:material_ui/material_ui.dart';

import '../api/xtream_api.dart';
import '../library.dart';
import '../models.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';

Future<void> loginPanelUser(BuildContext context, PanelUser u) async {
  Busy.show(context);
  try {
    late Account a;
    if (u.type == 'playlist') {
      a = Account.playlist(name: u.userName.isEmpty ? 'Playlist' : u.userName, url: u.dnsBase);
      await Store.saveAccount(a);
      await Store.setCurrent(a);
      Library.reset();
      await Library.I.download(ContentType.live);
      try {
        await Library.I.download(ContentType.movie);
      } catch (_) {}
    } else {
      a = Account.xtream(
        name: u.userName,
        server: u.dnsBase.replaceAll(' ', ''),
        username: u.userName,
        password: u.password,
        kind: u.type == 'xui' ? 'xui' : 'stream',
      );
      final info = await XtreamSource.login(a);
      Store.streamFormat = info.formats.isEmpty ? 0 : (info.formats.contains('m3u8') ? 2 : 1);
      await Store.saveAccount(a);
      await Store.setCurrent(a);
      Library.reset();
    }
    Busy.hide();
    if (!context.mounted) return;
    toast(context, 'Login successfully.');
    openHome(context, fresh: true);
  } catch (_) {
    Busy.hide();
    if (context.mounted) toast(context, S.err_login_not_incorrect, error: true);
  }
}
