// Login type chooser (SelectPlayerActivity / activity_select_player.xml).
import 'package:material_ui/material_ui.dart';

import '../session.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';
import 'sign_in_page.dart';
import 'add_playlist_page.dart';
import 'sign_in_device_page.dart';
import 'sign_in_code_page.dart';
import 'single_stream_page.dart';
import 'users_list_page.dart';
import 'downloads_page.dart';

class _Opt {
  final String title;
  final String icon;
  final VoidCallback onTap;

  /// Shows the ">" arrow (Android ItemSelect isMore).
  final bool more;
  _Opt(this.title, this.icon, this.onTap, {this.more = false});
}

class SelectPlayerPage extends StatelessWidget {
  const SelectPlayerPage({super.key});

  List<_Opt> _options(BuildContext context) {
    final app = Session.app;
    final list = <_Opt>[];
    if (app == null || app.selectXui) {
      list.add(
        _Opt(
          S.login_with_xtream_codes,
          'ic_folder_connection',
          () => go(context, const SignInPage(stream: false), replace: true),
        ),
      );
    }
    if (app?.selectStream == true) {
      list.add(_Opt(S.x_1_stream, 'ic_mist_line', () => go(context, const SignInPage(stream: true), replace: true)));
    }
    if (app == null || app.selectPlaylist) {
      list.add(_Opt(S.m3u_playlist, 'ic_play_list', () => go(context, const AddPlaylistPage(), replace: true)));
    }
    if (app?.selectDevice == true) {
      list.add(_Opt(S.login_with_device_id, 'ic_devices', () => go(context, const SignInDevicePage(), replace: true)));
    }
    if (app?.selectActivation == true) {
      list.add(
        _Opt(S.login_with_activation_code, 'ic_unlock', () => go(context, const SignInCodePage(), replace: true)),
      );
    }
    if (app?.selectSingle == true) {
      list.add(_Opt(S.play_single_stream, 'ic_movie', () => go(context, const SingleStreamPage())));
    }
    list.add(
      _Opt(S.list_users, 'ic_user_octagon', () => go(context, const UsersListPage(), replace: true), more: true),
    );
    list.add(_Opt(S.x_downloads, 'iv_downloading', () => go(context, const DownloadsPage()), more: true));
    for (final p in app?.selectPages ?? const <Map<String, String>>[]) {
      final type = (p['type'] ?? '').toLowerCase();
      final icon = type == 'whatsapp'
          ? 'ic_whatsapp'
          : type == 'telegram'
          ? 'ic_telegram'
          : 'ic_link';
      list.add(
        _Opt(p['title'] ?? '', icon, () {
          final url = p['url'] ?? '';
          if (type == 'internal') {
            openWeb(url);
          } else {
            openExternal(url);
          }
        }, more: true),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return PageBg(
      child: LayoutBuilder(
        builder: (context, box) {
          final opts = _options(context);
          return Padding(
            padding: EdgeInsets.fromLTRB(25.sdp, 5.sdp, 25.sdp, 5.sdp),
            child: Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Logo(size: 30.sdp),
                      SizedBox(width: 10.sdp),
                      T(S.app_name, size: 16),
                    ],
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10.sdp),
                      padding: EdgeInsets.all(10.sdp),
                      decoration: cardSub(),
                      // RecyclerView with GridLayoutManager(2): rows of two tiles.
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < opts.length; i += 2)
                              Row(
                                children: [
                                  Expanded(child: _LoginRow(opts[i])),
                                  Expanded(child: i + 1 < opts.length ? _LoginRow(opts[i + 1]) : const SizedBox()),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: T(S.by_using_this_application, size: 10, color: C.titleSub, lines: 1)),
                      SizedBox(width: 3.sdp),
                      Tap(
                        onTap: openTerms,
                        builder: (f) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.sdp),
                          child: T(S.terms_and_conditions, size: 10, color: C.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// row_login_list: white card, black icon and text, arrow on the right.
class _LoginRow extends StatelessWidget {
  final _Opt o;
  const _LoginRow(this.o);
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: o.onTap,
      builder: (f) => Container(
        height: 36.sdp,
        margin: EdgeInsets.all(5.sdp),
        decoration: BoxDecoration(
          color: C.mdBackground,
          borderRadius: BorderRadius.circular(4.sdp),
          border: Border.all(color: f ? const Color(0xFFE62E2F) : const Color(0x1A0C1318), width: f ? 2.sdp : 1.sdp),
        ),
        child: Row(
          children: [
            Ic(o.icon, size: 36.sdp, pad: 6.sdp, color: Colors.black),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 10.sdp),
                child: T(
                  o.title,
                  size: 9,
                  color: Colors.black,
                  lines: 1,
                  weight: FontWeight.bold,
                  align: TextAlign.center,
                ),
              ),
            ),
            if (o.more) Ic('ic_arrow_right', size: 30.sdp, pad: 8.sdp, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
