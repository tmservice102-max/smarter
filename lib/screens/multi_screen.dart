import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models.dart';
import '../parental.dart';
import '../session.dart';
import '../widgets/common.dart';

/// Watch 2 or 4 live channels at once. Tap a screen to hear it.
class MultiScreen extends StatefulWidget {
  const MultiScreen({super.key});
  @override
  State<MultiScreen> createState() => _MultiScreenState();
}

class _Cell {
  final Player player = Player();
  late final VideoController video = VideoController(player);
  StreamItem? channel;
}

class _MultiScreenState extends State<MultiScreen> {
  int _count = 4;
  int _active = 0;
  final List<_Cell> _cells = List.generate(4, (_) => _Cell());

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    for (final c in _cells) {
      c.player.dispose();
    }
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _setActive(int i) {
    setState(() => _active = i);
    for (var k = 0; k < _cells.length; k++) {
      _cells[k].player.setVolume(k == i ? 100 : 0);
    }
  }

  Future<void> _pick(int i) async {
    final ch = await showModalBottomSheet<StreamItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const FractionallySizedBox(
          heightFactor: 0.9, child: _ChannelPicker()),
    );
    if (ch == null) return;
    final cell = _cells[i];
    cell.channel = ch;
    await cell.player.open(Media(Session.src.streamUrl(ch),
        httpHeaders: {'User-Agent': 'IPTVSmartersPro'}));
    _setActive(i);
  }

  void _setCount(int n) {
    for (var k = n; k < _cells.length; k++) {
      _cells[k].player.stop();
      _cells[k].channel = null;
    }
    if (_active >= n) _active = 0;
    setState(() => _count = n);
  }

  Widget _cell(int i) {
    final c = _cells[i];
    return GestureDetector(
      onTap: () => c.channel == null ? _pick(i) : _setActive(i),
      onLongPress: () => _pick(i),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
              color: i == _active ? const Color(0xFF1E88E5) : Colors.white12,
              width: 2),
        ),
        child: c.channel == null
            ? const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add_circle_outline, size: 40, color: Colors.white54),
                  SizedBox(height: 6),
                  Text('Add channel', style: TextStyle(color: Colors.white54)),
                ]),
              )
            : Stack(fit: StackFit.expand, children: [
                IgnorePointer(
                  child: Video(controller: c.video, controls: NoVideoControls),
                ),
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    color: Colors.black54,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(i == _active ? Icons.volume_up : Icons.volume_off,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(c.channel!.name,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ]),
                  ),
                ),
              ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grid = _count == 2
        ? Row(children: [
            Expanded(child: _cell(0)),
            Expanded(child: _cell(1)),
          ])
        : Column(children: [
            Expanded(
                child: Row(children: [
              Expanded(child: _cell(0)),
              Expanded(child: _cell(1)),
            ])),
            Expanded(
                child: Row(children: [
              Expanded(child: _cell(2)),
              Expanded(child: _cell(3)),
            ])),
          ]);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          grid,
          Positioned(
            right: 8,
            bottom: 8,
            child: Row(children: [
              _btn(Icons.splitscreen, '2', () => _setCount(2)),
              const SizedBox(width: 8),
              _btn(Icons.grid_view, '4', () => _setCount(4)),
              const SizedBox(width: 8),
              _btn(Icons.close, '', () => Navigator.of(context).pop()),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback onTap) => Material(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(icon, size: 18, color: Colors.white),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: Colors.white)),
              ],
            ]),
          ),
        ),
      );
}

class _ChannelPicker extends StatefulWidget {
  const _ChannelPicker();
  @override
  State<_ChannelPicker> createState() => _ChannelPickerState();
}

class _ChannelPickerState extends State<_ChannelPicker> {
  String _q = '';

  Future<List<StreamItem>> _load() async {
    final all = await Session.src.streams(ContentType.live, categoryId: '');
    if (Parental.unlocked) return all;
    final cats = await Session.src.categories(ContentType.live);
    final locked =
        cats.where((c) => Parental.isAdult(c.name)).map((c) => c.id).toSet();
    return all.where((x) => !locked.contains(x.categoryId)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search), hintText: 'Search channels'),
          onChanged: (v) => setState(() => _q = v.toLowerCase()),
        ),
      ),
      Expanded(
        child: AsyncView<List<StreamItem>>(
          load: _load,
          builder: (context, all) {
            final list = _q.isEmpty
                ? all
                : all.where((c) => c.name.toLowerCase().contains(_q)).toList();
            return ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => ListTile(
                leading: SizedBox(
                    width: 48,
                    height: 34,
                    child: NetImage(list[i].icon, fit: BoxFit.contain)),
                title: Text(list[i].name),
                onTap: () => Navigator.pop(context, list[i]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}
