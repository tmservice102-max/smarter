// Play single stream (AddSingleURL + activity_themes_single_stream):
// a form to add a video link and a list of saved links.
import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'downloads_page.dart';
import 'notifications_page.dart';
import 'player_vod_page.dart';
import 'sign_in_page.dart';

List<(String, String)> _saved() => [
      for (final s in Store.prefs.getStringList('single_urls') ?? const <String>[])
        if (jsonDecode(s) case {'n': final String n, 'u': final String u}) (n, u)
    ];

Future<void> _save(List<(String, String)> l) => Store.prefs
    .setStringList('single_urls', [for (final (n, u) in l) jsonEncode({'n': n, 'u': u})]);

/// List of saved links (opened from the login chooser).
class SingleStreamPage extends StatefulWidget {
  const SingleStreamPage({super.key});
  @override
  State<SingleStreamPage> createState() => _SingleStreamPageState();
}

class _SingleStreamPageState extends State<SingleStreamPage> {
  @override
  void initState() {
    super.initState();
    if (_saved().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _add());
    }
  }

  Future<void> _add() async {
    await go(context, const _AddSinglePage());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final list = _saved();
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(children: [
          Expanded(
            flex: 4,
            child: Row(children: [
              IconTap('ic_arrow_left', size: 33, pad: 5, onTap: () => Navigator.maybePop(context)),
              Logo(size: 30.sdp),
              SizedBox(width: 10.sdp),
              const Expanded(child: T(S.app_name, size: 16, lines: 1)),
              Ic('ic_wifi', size: 35.sdp, pad: 8.sdp),
              IconTap('ic_round_notifications', onTap: () => go(context, const NotificationsPage())),
              IconTap('iv_downloading', onTap: () => go(context, const DownloadsPage())),
              SizedBox(width: 5.sdp),
              Tap(
                onTap: _add,
                builder: (f) => SaveBox(
                  focused: f,
                  padding: EdgeInsets.only(right: 8.sdp),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Ic('ic_link', size: 30.sdp, pad: 7.sdp),
                    T(S.add_video, size: 12),
                  ]),
                ),
              ),
            ]),
          ),
          Expanded(
            flex: 20,
            child: list.isEmpty
                ? Empty(S.err_no_data_found)
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisExtent: 56.sdp),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final (n, u) = list[i];
                      final colors = G.users[i % G.users.length];
                      return Tap(
                        onTap: () => go(context, VodPlayerPage(title: n, url: u)),
                        onLongPress: () async {
                          final ok = await appDialog(context, icon: 'ic_trash', title: S.delete, msg: S.sure_delete);
                          if (!ok) return;
                          await _save(list..removeAt(i));
                          if (mounted) setState(() {});
                        },
                        builder: (f) => Container(
                          margin: EdgeInsets.all(3.sdp),
                          padding: EdgeInsets.all(5.sdp),
                          decoration: BoxDecoration(
                            color: const Color(0x12FFFFFF),
                            borderRadius: BorderRadius.circular(3.sdp),
                            border: Border.all(color: f ? C.select : C.border, width: 1.sdp),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40.sdp,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: colors),
                                borderRadius: BorderRadius.circular(3.sdp),
                              ),
                              child: Ic('ic_play', size: 40.sdp, pad: 10.sdp),
                            ),
                            SizedBox(width: 5.sdp),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  T(n, size: 10, color: C.title, lines: 1),
                                  SizedBox(height: 6.sdp),
                                  T(u, size: 8, color: C.titleSub, lines: 1),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}

/// activity_sign_in_single_url
class _AddSinglePage extends StatefulWidget {
  const _AddSinglePage();
  @override
  State<_AddSinglePage> createState() => _AddSinglePageState();
}

class _AddSinglePageState extends State<_AddSinglePage> {
  final _name = TextEditingController();
  final _url = TextEditingController();

  Future<void> _addVideo() async {
    final n = _name.text.trim(), u = _url.text.trim();
    if (n.isEmpty || u.isEmpty) {
      toast(context, S.err_cannot_empty, error: true);
      return;
    }
    if (!u.startsWith('http://') && !u.startsWith('https://') && !u.startsWith('rtmp')) {
      toast(context, 'Please enter a valid link', error: true);
      return;
    }
    await _save([..._saved(), (n, u)]);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return LoginLayout(
      side: LoginSide(buttons: [
        UiButton(text: S.stream_list, icon: 'ic_play_list', onTap: () => Navigator.pop(context)),
      ]),
      form: Container(
        padding: EdgeInsets.all(15.sdp),
        decoration: cardSub(),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          T(S.play_single_stream_url, size: 11, color: C.title),
          SizedBox(height: 8.sdp),
          PillField(icon: 'ic_profile', hint: S.any_name, controller: _name),
          SizedBox(height: 6.sdp),
          PillField(
            icon: 'ic_link',
            hint: S.stream_name_extension,
            controller: _url,
            keyboard: TextInputType.url,
            onSubmitted: (_) => _addVideo(),
          ),
          SizedBox(height: 8.sdp),
          GradButton(text: S.add_video, icon: 'ic_add_circle', onTap: _addVideo),
        ]),
      ),
    );
  }
}
