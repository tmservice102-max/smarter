// Splash screen (LauncherActivity / activity_launcher.xml).
import 'dart:convert';

import 'package:material_ui/material_ui.dart';

import '../api/panel_api.dart';
import '../config.dart';
import '../library.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';
import 'data_sync_page.dart';

class LauncherPage extends StatefulWidget {
  const LauncherPage({super.key});
  @override
  State<LauncherPage> createState() => _LauncherPageState();
}

class _LauncherPageState extends State<LauncherPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    setState(() => _loading = true);
    final cached = Store.prefs.getString('app_details');
    try {
      final d = await PanelApi.appDetails();
      Session.app = d;
      await Store.prefs.setString('app_details', jsonEncode(d.raw));
    } catch (_) {
      if (cached != null) {
        Session.app = AppDetails.fromJson(Map<String, dynamic>.from(jsonDecode(cached) as Map));
      } else {
        if (!mounted) return;
        setState(() => _loading = false);
        final again = await appDialog(
          context,
          icon: 'ic_wifi_off',
          title: S.err_server_error,
          msg: S.err_server_not_connected,
          yes: S.try_again_later,
          no: null,
        );
        if (again) _start();
        return;
      }
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (Session.app?.maintenance == true) {
      await appDialog(
        context,
        icon: 'ic_engineering',
        title: S.temporarily_down_for_maintenance,
        msg: S.we_are_performing_scheduled,
        yes: S.try_again_later,
        no: null,
      );
      if (mounted) _start();
      return;
    }
    _next();
  }

  void _next() {
    final a = Store.currentAccount;
    if (a == null) {
      openSelectPlayer(context);
      return;
    }
    // Refresh the saved lists when they are older than the Android default (5 hours).
    if (a.kind != 'playlist') {
      final lib = Library.I;
      final dates = ContentType.values.map(lib.updated).whereType<DateTime>().toList();
      final old = dates.isNotEmpty && dates.any((d) => DateTime.now().difference(d).inHours > 5);
      if (old) {
        go(context, const DataSyncPage(), clear: true);
        return;
      }
    }
    openHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return PageBg(
      side: 0,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                T(S.app_name, size: 28, weight: FontWeight.bold, align: TextAlign.center),
                SizedBox(height: 2.sdp),
                Opacity(
                  opacity: 0.7,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Ic('ic_keyhole', size: 14.sdp),
                      SizedBox(width: 5.sdp),
                      T(S.encrypted_data_security, size: 11),
                    ],
                  ),
                ),
                SizedBox(height: 15.sdp),
                SizedBox(
                  height: 30.sdp,
                  width: 30.sdp,
                  child: _loading ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3) : null,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 20.sdp,
            child: T('${S.version} ${AppConfig.version}', size: 11, color: C.titleSub, align: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
