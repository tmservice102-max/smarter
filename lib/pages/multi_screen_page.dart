// Multiscreen (MultipleScreenActivity): up to four live channels at once.
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../library.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/dialogs.dart';
import 'list_page.dart';
import 'player_kit.dart';

class MultiScreenPage extends StatefulWidget {
  /// Opened from the live player: this channel plays in the first screen and
  /// the saved layout is used without asking ("is_player").
  final StreamItem? first;
  const MultiScreenPage({super.key, this.first});
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
  int _layout = Store.multiScreenLayout.clamp(1, 5);

  @override
  void initState() {
    super.initState();
    playerEnter();
    Library.I.load(ContentType.live).catchError((_) {});
    final first = widget.first;
    if (first != null) {
      _start(0, first);
    } else if (Store.multiScreenPopup) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _chooseLayout());
    }
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
    final r = await screenDialog(context);
    if (r != null && mounted) setState(() => _layout = r);
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
    final playlist = Store.currentAccount?.type == AccountType.playlist;
    final ch = await go<StreamItem>(context, ListPage(type: ContentType.live, playlist: playlist, pick: true));
    if (ch == null || !mounted) return;
    await _start(i, ch);
  }

  Future<void> _start(int i, StreamItem ch) async {
    final s = _slots[i];
    s.player ??= newPlayer();
    s.video ??= VideoController(s.player!);
    s.item = ch;
    // The first screen with a channel has the sound.
    final anyOn = _slots.any((x) => x != s && x.item != null && !x.muted);
    s.muted = anyOn;
    await s.player!.setVolume(s.muted ? 0 : 100);
    s.player!.open(media(Session.src.streamUrl(ch)));
    if (mounted) setState(() {});
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
                builder: (f) => Stack(
                  fit: StackFit.expand,
                  children: [
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
                          decoration: BoxDecoration(
                            border: Border.all(color: C.select, width: 2.sdp),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = _visible(_layout);
    final gap = SizedBox(width: 10.sdp, height: 10.sdp);
    return PageBg(
      side: 10,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(10.sdp),
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      _screen(0),
                      if (v[1]) ...[gap, _screen(1)],
                    ],
                  ),
                ),
                if (v[2] || v[3]) ...[
                  gap,
                  Expanded(
                    child: Row(
                      children: [
                        if (v[2]) _screen(2),
                        if (v[3]) ...[gap, _screen(3)],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Android uses the system back key; the iPhone needs a button.
          Positioned(
            left: 4.sdp,
            top: 4.sdp,
            child: Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x66000000)),
              child: IconTap('ic_arrow_left', size: 26, pad: 5, onTap: () => Navigator.maybePop(context)),
            ),
          ),
        ],
      ),
    );
  }
}
