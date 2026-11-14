// Splash screen (LauncherActivity / activity_launcher.xml).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  Player? _audio;
  Future<void>? _audioDone;

  @override
  void initState() {
    super.initState();
    // "Splash Screen Music" (General settings): the opener sound plays first
    // and the app moves on when it ends, like LauncherActivity.
    if (Store.splashAudio) _audioDone = _playAudio();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _audio?.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    final p = Player();
    _audio = p;
    final done = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    final subs = [
      p.stream.completed.listen((c) {
        if (c) finish();
      }),
      p.stream.error.listen((_) => finish()),
    ];
    try {
      await p.open(Media('asset:///assets/audio/opener_logo.mp3'));
      await done.future.timeout(const Duration(seconds: 9), onTimeout: () {});
    } catch (_) {}
    for (final s in subs) {
      await s.cancel();
    }
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
    final app = Session.app;
    Session.rtl.value = app?.rtl ?? false;
    // Update popup first, then maintenance, like LauncherActivity. Not
    // forced: DO IT NOW opens the store link, Cancel or X goes on.
    final outdated = app != null && app.updateOn && await _outdated(app.updateVersion);
    if (!mounted) return;
    if (outdated) {
      while (true) {
        if (!mounted) return;
        final yes = await appDialog(
          context,
          icon: 'ic_error',
          title: S.upgrade,
          msg: S.its_time_to_upgrade,
          yes: S.do_it_now,
          no: S.cancel,
        );
        if (!yes) break;
        if (app.updateUrl.isNotEmpty) await openExternal(app.updateUrl);
      }
      if (!mounted) return;
    }
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

  /// The installed app is older than the panel's version: on iPhone the
  /// version (1.0.1), on Android the version code like the Android app.
  Future<bool> _outdated(String want) async {
    if (want.trim().isEmpty) return false;
    final info = await PackageInfo.fromPlatform();
    if (!Platform.isIOS) {
      final w = int.tryParse(want.trim());
      return w != null && w != int.tryParse(info.buildNumber);
    }
    List<int> parts(String v) =>
        v.split(RegExp(r'[^0-9]+')).where((e) => e.isNotEmpty).map((e) => int.tryParse(e) ?? 0).toList();
    final a = parts(info.version), b = parts(want);
    for (var i = 0; i < max(a.length, b.length); i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }

  Future<void> _next() async {
    if (_audioDone != null) {
      await _audioDone;
      if (!mounted) return;
    }
    final a = Store.currentAccount;
    if (a == null) {
      openSelectPlayer(context);
      return;
    }
    // Refresh the saved lists when they are older than the Automation
    // setting (Android default 5 hours).
    if (a.kind != 'playlist') {
      final lib = Library.I;
      final dates = ContentType.values.map(lib.updated).whereType<DateTime>().toList();
      final hours = Store.autoUpdateHours;
      final old = hours > 0 && dates.isNotEmpty && dates.any((d) => DateTime.now().difference(d).inHours >= hours);
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
