// Radio (RadioActivity / activity_radio): category chips, station grid and
// a small player bar at the bottom.
import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import '../library.dart';
import '../models.dart';
import '../session.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'player_kit.dart';

class RadioPage extends StatefulWidget {
  const RadioPage({super.key});
  @override
  State<RadioPage> createState() => _RadioPageState();
}

class _RadioPageState extends State<RadioPage> {
  final Player _player = newPlayer();
  final List<StreamSubscription> _subs = [];
  List<StreamItem> _all = [];
  List<Category> _cats = [];
  String _cat = '';
  StreamItem? _now;
  bool _playing = false;
  bool _buffering = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subs.add(_player.stream.playing.listen((v) => setState(() => _playing = v)));
    _subs.add(_player.stream.buffering.listen((v) => setState(() => _buffering = v)));
    _load();
  }

  Future<void> _load() async {
    try {
      await Library.I.load(ContentType.live);
    } catch (_) {}
    final all = Library.I.all(ContentType.live).where((i) => i.extension == 'radio').toList();
    final ids = all.map((e) => e.categoryId).toSet();
    if (!mounted) return;
    setState(() {
      _all = all;
      _cats = [Category('', 'All'), ...Library.I.categories(ContentType.live).where((c) => ids.contains(c.id))];
      _loading = false;
    });
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  List<StreamItem> get _list => _cat.isEmpty ? _all : _all.where((i) => i.categoryId == _cat).toList();

  void _play(StreamItem i) {
    setState(() => _now = i);
    _player.open(media(Session.src.streamUrl(i)));
  }

  void _step(int d) {
    final l = _list;
    if (l.isEmpty) return;
    final at = _now == null ? -1 : l.indexWhere((e) => e.key == _now!.key);
    _play(l[(at + d + l.length) % l.length]);
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final catName = _now == null
        ? ''
        : _cats.firstWhere((c) => c.id == _now!.categoryId, orElse: () => Category('', '')).name;
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(children: [
          PageTop(title: 'Radio', icon: 'ic_radio'),
          if (_cats.length > 1)
            SizedBox(
              height: 30.sdp,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final c in _cats)
                  Padding(
                    padding: EdgeInsets.only(right: 5.sdp),
                    child: Tap(
                      onTap: () => setState(() => _cat = c.id),
                      builder: (f) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.sdp),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0x12FFFFFF),
                          borderRadius: BorderRadius.circular(1.sdp),
                          border: Border.all(color: f ? const Color(0xFFFFAB00) : C.border, width: 1.sdp),
                        ),
                        child: T(c.name, size: 12, color: c.id == _cat ? C.select : Colors.white),
                      ),
                    ),
                  ),
              ]),
            ),
          SizedBox(height: 5.sdp),
          Expanded(
            child: _loading
                ? const Loader()
                : list.isEmpty
                    ? Empty(S.err_no_data_found)
                    : GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisExtent: 104.sdp),
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final r = list[i];
                          final on = _now?.key == r.key;
                          return Tap(
                            onTap: () => _play(r),
                            builder: (f) => Container(
                              margin: EdgeInsets.all(2.sdp),
                              decoration: BoxDecoration(
                                color: const Color(0x0DFFFFFF),
                                borderRadius: BorderRadius.circular(3.sdp),
                                border: Border.all(color: f || on ? C.select : Colors.transparent, width: 2.sdp),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.sdp),
                                child: Stack(fit: StackFit.expand, children: [
                                  NetImg(r.icon, placeholder: 'placeholder_live', fit: BoxFit.contain),
                                  Positioned(
                                    left: 3.sdp,
                                    right: 3.sdp,
                                    bottom: 3.sdp,
                                    child: Container(
                                      color: const Color(0x99000000),
                                      padding: EdgeInsets.all(2.sdp),
                                      child: T(r.name, size: 8, lines: 1, align: TextAlign.center),
                                    ),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_now != null)
            Container(
              height: 46.sdp,
              decoration: const BoxDecoration(
                color: Color(0x59000000),
                border: Border(top: BorderSide(color: Color(0xFF191919))),
              ),
              child: Row(children: [
                SizedBox(width: 25.sdp),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.sdp),
                  child: NetImg(_now!.icon, placeholder: 'placeholder_live', width: 30.sdp, height: 30.sdp),
                ),
                SizedBox(width: 10.sdp),
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    T(_now!.name, size: 11, color: C.title, lines: 1),
                    if (catName.isNotEmpty) T(catName, size: 9, color: C.titleSub, lines: 1),
                  ]),
                ),
                IconTap('ic_skip_previous', size: 35, pad: 6, onTap: () => _step(-1)),
                SizedBox(
                  width: 35.sdp,
                  child: _buffering && !_playing
                      ? const Loader(size: 20)
                      : IconTap(_playing ? 'ic_pause' : 'ic_play', size: 35, pad: 6, onTap: _player.playOrPause),
                ),
                IconTap('ic_skip_next', size: 35, pad: 6, onTap: () => _step(1)),
                SizedBox(width: 10.sdp),
              ]),
            ),
        ]),
      ),
    );
  }
}
