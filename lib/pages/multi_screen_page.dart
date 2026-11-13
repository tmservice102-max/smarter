// Multiscreen (MultipleScreenActivity): up to four live channels at once.
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../library.dart';
import '../models.dart';
import '../parental.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'player_kit.dart';

class MultiScreenPage extends StatefulWidget {
  const MultiScreenPage({super.key});
  @override
  State<MultiScreenPage> createState() => _MultiScreenPageState();
}

class _Slot {
  Player? player;
  VideoController? video;
  StreamItem? item;
  bool muted = true;
}

class _MultiScreenPageState extends State<MultiScreenPage> {
  final _slots = List.generate(4, (_) => _Slot());
  int _layout = Store.prefs.getInt('multi_screen') ?? 0; // 1..5, 0 = ask

  @override
  void initState() {
    super.initState();
    playerEnter();
    Library.I.load(ContentType.live).catchError((_) {});
    if (_layout == 0) WidgetsBinding.instance.addPostFrameCallback((_) => _chooseLayout());
  }

  @override
  void dispose() {
    for (final s in _slots) {
      s.player?.dispose();
    }
    playerLeave();
    super.dispose();
  }

  Future<void> _chooseLayout() async {
    final r = await showGeneralDialog<int>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black54,
      pageBuilder: (ctx, _, _) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 380.sdp,
            padding: EdgeInsets.all(15.sdp),
            color: const Color(0xCB1B1B1B),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              T(S.choose_multi_screen_layout, size: 12),
              SizedBox(height: 8.sdp),
              Row(children: [for (var i = 1; i <= 3; i++) _layoutBtn(ctx, i)]),
              SizedBox(height: 5.sdp),
              Row(children: [for (var i = 4; i <= 5; i++) _layoutBtn(ctx, i), const Expanded(child: SizedBox())]),
            ]),
          ),
        ),
      ),
    );
    if (r != null) {
      await Store.prefs.setInt('multi_screen', r);
      setState(() => _layout = r);
    } else if (_layout == 0) {
      setState(() => _layout = 5);
    }
  }

  /// Layout pictures from the Android app (screen_one ... screen_five).
  Widget _layoutBtn(BuildContext ctx, int n) {
    const names = ['one', 'two', 'three', 'four', 'five'];
    return Expanded(
      child: Tap(
        onTap: () => Navigator.pop(ctx, n),
        builder: (f) => Container(
          height: 80.sdp,
          margin: EdgeInsets.all(3.sdp),
          padding: EdgeInsets.all(5.sdp),
          decoration: BoxDecoration(
            border: Border.all(color: f || n == _layout ? C.select : const Color(0x33FFFFFF), width: 2.sdp),
          ),
          child: Image.asset('assets/img/screen_${names[n - 1]}.webp', fit: BoxFit.contain),
        ),
      ),
    );
  }

  /// Which of the 4 screens show in each layout (setScreen in the Android app).
  List<bool> _visible(int n) => switch (n) {
        1 => [true, true, false, false],
        2 => [true, false, true, false],
        3 => [true, false, true, true],
        4 => [true, true, true, false],
        _ => [true, true, true, true],
      };

  Future<void> _add(int i) async {
    final ch = await go<StreamItem>(context, const _PickChannelPage());
    if (ch == null || !mounted) return;
    final s = _slots[i];
    s.player ??= newPlayer();
    s.video ??= VideoController(s.player!);
    s.item = ch;
    // The first screen with a channel has the sound.
    final anyOn = _slots.any((x) => x != s && x.item != null && !x.muted);
    s.muted = anyOn;
    await s.player!.setVolume(s.muted ? 0 : 100);
    s.player!.open(media(Session.src.streamUrl(ch)));
    setState(() {});
  }

  void _sound(int i) {
    for (var k = 0; k < 4; k++) {
      final s = _slots[k];
      s.muted = k != i;
      s.player?.setVolume(s.muted ? 0 : 100);
    }
    setState(() {});
  }

  void _remove(int i) {
    final s = _slots[i];
    s.player?.stop();
    s.item = null;
    setState(() {});
  }

  Widget _screen(int i) {
    final s = _slots[i];
    return Expanded(
      child: Container(
        color: Colors.black,
        child: s.item == null
            ? Center(child: IconTap('ic_add_circle', size: 40, pad: 5, onTap: () => _add(i)))
            : Tap(
                onTap: () => _sound(i),
                onLongPress: () => _remove(i),
                builder: (f) => Stack(fit: StackFit.expand, children: [
                  Video(controller: s.video!, controls: NoVideoControls),
                  StreamBuilder<bool>(
                    stream: s.player!.stream.buffering,
                    builder: (_, b) => b.data == true ? const Loader(size: 35) : const SizedBox(),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Ic(s.muted ? 'ic_volume_off' : 'ic_volume_up', size: 30.sdp, pad: 7.sdp),
                  ),
                  Positioned(
                    left: 6.sdp,
                    bottom: 4.sdp,
                    right: 6.sdp,
                    child: T(s.item!.name, size: 9, lines: 1, color: Colors.white70),
                  ),
                  if (!s.muted || f)
                    IgnorePointer(
                      child: Container(
                          decoration: BoxDecoration(border: Border.all(color: C.select, width: 2.sdp))),
                    ),
                ]),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _visible(_layout);
    final gap = SizedBox(width: 10.sdp, height: 10.sdp);
    return PageBg(
      child: Stack(children: [
        Padding(
          padding: EdgeInsets.all(10.sdp),
          child: Column(children: [
            Expanded(child: Row(children: [_screen(0), if (v[1]) ...[gap, _screen(1)]])),
            if (v[2] || v[3]) ...[
              gap,
              Expanded(child: Row(children: [if (v[2]) _screen(2), if (v[3]) ...[gap, _screen(3)]])),
            ],
          ]),
        ),
        Positioned(
          left: 12.sdp,
          top: 12.sdp,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x66000000)),
            child: IconTap('ic_arrow_left', size: 30, pad: 5, onTap: () => Navigator.maybePop(context)),
          ),
        ),
        Positioned(
          right: 12.sdp,
          top: 12.sdp,
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x66000000)),
            child: IconTap('ic_multiple_screen', size: 30, pad: 6, onTap: _chooseLayout),
          ),
        ),
      ]),
    );
  }
}

/// Pick a channel for one screen (FilterActivity): categories left, channels right.
class _PickChannelPage extends StatefulWidget {
  const _PickChannelPage();
  @override
  State<_PickChannelPage> createState() => _PickChannelPageState();
}

class _PickChannelPageState extends State<_PickChannelPage> {
  String _cat = '';
  @override
  void initState() {
    super.initState();
    final cats = Library.I.categories(ContentType.live);
    _cat = cats.isEmpty ? '' : cats.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final hidden = Store.hiddenCategories.toSet();
    final cats = [
      Category(Library.fav, S.favourite),
      ...Library.I.categories(ContentType.live).where((c) => !hidden.contains('live:${c.id}')),
    ];
    final items = Library.I.items(ContentType.live, _cat);
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(children: [
          PageTop(title: S.channels, icon: 'list_channels'),
          SizedBox(height: 4.sdp),
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                flex: 10,
                child: ListView(children: [
                  for (final c in cats)
                    Tap(
                      onTap: () async {
                        if (!await Parental.check(context, c.name)) return;
                        setState(() => _cat = c.id);
                      },
                      builder: (f) => Container(
                        color: f ? const Color(0x2DFFFFFF) : null,
                        padding: EdgeInsets.symmetric(horizontal: 8.sdp, vertical: 7.sdp),
                        child: T(c.name, size: 12, lines: 1, color: c.id == _cat ? C.select : Colors.white),
                      ),
                    ),
                ]),
              ),
              Container(width: 1.sdp, color: const Color(0x1BFFFFFF)),
              Expanded(
                flex: 20,
                child: items.isEmpty
                    ? Empty(S.err_no_data_found)
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => Tap(
                          onTap: () => Navigator.pop(context, items[i]),
                          builder: (f) => Container(
                            height: 35.sdp,
                            color: f ? const Color(0x2DFFFFFF) : null,
                            padding: EdgeInsets.symmetric(horizontal: 6.sdp),
                            child: Row(children: [
                              SizedBox(
                                  width: 50.sdp,
                                  height: 30.sdp,
                                  child: NetImg(items[i].icon, placeholder: 'placeholder_live', fit: BoxFit.contain)),
                              SizedBox(width: 6.sdp),
                              Expanded(child: T(items[i].name, size: 12, lines: 1)),
                            ]),
                          ),
                        ),
                      ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
