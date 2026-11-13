// Add M3U playlist (AddPlaylistActivity / activity_sign_in_playlist.xml).
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../library.dart';
import '../models.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';
import 'sign_in_page.dart';
import 'users_list_page.dart';

class AddPlaylistPage extends StatefulWidget {
  const AddPlaylistPage({super.key});
  @override
  State<AddPlaylistPage> createState() => _AddPlaylistPageState();
}

class _AddPlaylistPageState extends State<AddPlaylistPage> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  bool _file = false;
  String _filePath = '';
  String _fileName = '';
  bool _busy = false;

  Future<void> _browse() async {
    final r = await FilePicker.pickFiles(type: FileType.any);
    final f = r.isEmpty ? null : r.single;
    if (f == null || f.path == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dst = File('${dir.path}/playlist_${DateTime.now().millisecondsSinceEpoch}.m3u');
    await File(f.path!).copy(dst.path);
    setState(() {
      _filePath = dst.path;
      _fileName = f.name;
    });
  }

  Future<void> _add() async {
    final src = _file ? _filePath : _url.text.trim();
    if (src.isEmpty) {
      toast(context, _file ? S.err_file_invalid : S.err_cannot_empty, error: true);
      return;
    }
    if (_name.text.isEmpty) _name.text = 'Playlist';
    setState(() => _busy = true);
    final a = Account.playlist(name: _name.text, url: _file ? 'file://$src' : src);
    try {
      await Store.saveAccount(a);
      await Store.setCurrent(a);
      Library.reset();
      final lib = Library.I;
      await lib.download(ContentType.live);
      try {
        await lib.download(ContentType.movie);
      } catch (_) {}
      if (!mounted) return;
      toast(context, S.added_success);
      openHome(context);
    } catch (e) {
      await Store.setCurrent(null);
      await Store.removeAccount(a);
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, _file ? S.err_file_invalid : S.err_server_not_connected, error: true);
    }
  }

  Widget _radio(String text, bool on, VoidCallback tap) => Expanded(
    child: Tap(
      onTap: tap,
      builder: (f) => Container(
        height: 30.sdp,
        decoration: BoxDecoration(
          color: f ? const Color(0x2DFFFFFF) : null,
          borderRadius: BorderRadius.circular(2.sdp),
        ),
        child: Row(
          children: [
            Icon(on ? Icons.radio_button_checked : Icons.radio_button_off, color: Colors.white, size: 16.sdp),
            SizedBox(width: 6.sdp),
            T(text, size: 10, color: C.title),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return LoginLayout(
      side: LoginSide(
        buttons: [
          UiButton(
            text: S.list_users,
            icon: 'ic_shield_user',
            onTap: () => go(context, const UsersListPage(), replace: true),
          ),
        ],
      ),
      form: Container(
        padding: EdgeInsets.all(15.sdp),
        decoration: cardSub(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            T(S.add_m3u_playlist, size: 11, color: C.title),
            SizedBox(height: 8.sdp),
            PillField(icon: 'ic_profile', hint: S.any_name, controller: _name),
            SizedBox(height: 4.sdp),
            Row(
              children: [
                _radio(S.file, _file, () => setState(() => _file = true)),
                SizedBox(width: 10.sdp),
                _radio(S.m3u_url, !_file, () => setState(() => _file = false)),
                const Spacer(flex: 1),
              ],
            ),
            SizedBox(height: 4.sdp),
            if (_file)
              Row(
                children: [
                  Tap(
                    onTap: _browse,
                    builder: (f) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 5.sdp),
                      decoration: BoxDecoration(
                        gradient: f ? null : G.primaryBtn,
                        color: f ? const Color(0xFFFFB347) : null,
                        borderRadius: BorderRadius.circular(3.sdp),
                      ),
                      child: T(S.browse, size: 14),
                    ),
                  ),
                  SizedBox(width: 5.sdp),
                  Expanded(child: T(_fileName, size: 13, lines: 1)),
                ],
              )
            else
              PillField(icon: 'ic_link', hint: S.url_here_com_port, controller: _url, keyboard: TextInputType.url),
            SizedBox(height: 10.sdp),
            GradButton(text: S.add_playlist, icon: 'ic_add_circle', loading: _busy, onTap: _add),
          ],
        ),
      ),
    );
  }
}
