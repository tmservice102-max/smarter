// Pieces shared by the live and video players (custom_controls_live,
// activity_player_exoplayer): buttons, chips, lock overlay, tracks panel.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';

const playerAgent = 'IPTVSmartersPro';

Player newPlayer() => Player(configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024));

Media media(String url) =>
    Media(url, httpHeaders: {'User-Agent': Store.agentName.isEmpty ? playerAgent : Store.agentName});

/// Call when a player page opens / closes.
void playerEnter() {
  WakelockPlus.enable();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

void playerLeave() {
  WakelockPlus.disable();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

/// Aspect ratio button: fit, fill, zoom (like RESIZE_MODE_FIT/FILL/ZOOM).
const playerFits = [BoxFit.contain, BoxFit.fill, BoxFit.cover];
String fitLabel(BoxFit f) => switch (f) {
  BoxFit.fill => 'Fill',
  BoxFit.cover => 'Zoom',
  _ => 'Fit',
};

/// focused_btn_player: square icon, light fill when pressed.
class PBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double pad;
  final Color? color;
  const PBtn(this.icon, {super.key, this.onTap, this.size = 30, this.pad = 5, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      color: f ? const Color(0x2DFFFFFF) : Colors.transparent,
      child: Ic(icon, size: size.sdp, pad: pad.sdp, color: color),
    ),
  );
}

/// focused_btn_play: round translucent button, yellow when pressed.
class RoundBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final double size;
  final double pad;
  const RoundBtn(this.icon, {super.key, this.onTap, this.size = 36, this.pad = 6});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      decoration: BoxDecoration(shape: BoxShape.circle, color: f ? C.primary : const Color(0x2DFFFFFF)),
      child: Ic(icon, size: size.sdp, pad: pad.sdp),
    ),
  );
}

/// ExoPlayer rewind / fast-forward button: circular arrow with the seconds
/// inside (Android defaults: back 5 s, forward 15 s).
class SeekBtn extends StatelessWidget {
  final int seconds;
  final bool forward;
  final VoidCallback? onTap;
  final double size;
  const SeekBtn({super.key, required this.seconds, required this.forward, this.onTap, this.size = 36});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      width: size.sdp,
      height: size.sdp,
      decoration: BoxDecoration(shape: BoxShape.circle, color: f ? C.primary : const Color(0x2DFFFFFF)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.flip(
            flipX: forward,
            child: Icon(Icons.replay, color: Colors.white, size: size.sdp * 0.75),
          ),
          Padding(
            padding: EdgeInsets.only(top: size.sdp * 0.08),
            child: Text(
              '$seconds',
              style: TextStyle(color: Colors.white, fontSize: size.sdp * 0.22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ),
  );
}

/// bg_player_chip
class PChip extends StatelessWidget {
  final String text;
  final Color? color;
  const PChip(this.text, {super.key, this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7.sdp, vertical: 2.sdp),
    decoration: BoxDecoration(
      color: color ?? const Color(0x33FFFFFF),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0x55FFFFFF)),
    ),
    child: T(text, size: 10, weight: FontWeight.bold),
  );
}

/// Top and bottom shades behind the controls.
const topShade = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xE6000000), Color(0x88000000), Color(0x00000000)],
  ),
);
const bottomShade = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [Color(0xE6000000), Color(0x88000000), Color(0x00000000)],
  ),
);

/// "Player locked" overlay with the unlock button.
class LockOverlay extends StatefulWidget {
  final VoidCallback onUnlock;
  const LockOverlay({super.key, required this.onUnlock});
  @override
  State<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends State<LockOverlay> {
  bool _show = true;
  Timer? _t;
  @override
  void initState() {
    super.initState();
    _hideLater();
  }

  void _hideLater() {
    _t?.cancel();
    _t = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _show = false);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      setState(() => _show = true);
      _hideLater();
    },
    child: Center(
      child: AnimatedOpacity(
        opacity: _show ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: 200.sdp,
          height: 200.sdp,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [Color(0xCC000000), Color(0x66000000), Colors.transparent]),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RoundBtn('ic_lock', size: 40, onTap: _show ? widget.onUnlock : null),
              SizedBox(height: 10.sdp),
              T(S.player_locked, size: 14, weight: FontWeight.bold),
              SizedBox(height: 4.sdp),
              T(S.tap_to_unlock, size: 12),
            ],
          ),
        ),
      ),
    ),
  );
}

/// ll_media: the "Information" side panel with video, audio and subtitle tracks.
class TracksPanel extends StatelessWidget {
  final Player player;
  final VoidCallback onClose;
  const TracksPanel({super.key, required this.player, required this.onClose});

  String _label(String id, String? title, String? lang) {
    if (id == 'auto') return 'Auto';
    if (id == 'no') return 'Off';
    final parts = [title, lang].where((s) => s != null && s.isNotEmpty).join(' • ');
    return parts.isEmpty ? 'Track $id' : parts;
  }

  Widget _head(String icon, String text) => Container(
    margin: EdgeInsets.only(top: 10.sdp),
    padding: EdgeInsets.all(2.sdp),
    decoration: BoxDecoration(color: const Color(0x12FFFFFF), borderRadius: BorderRadius.circular(3.sdp)),
    child: Row(
      children: [
        Ic(icon, size: 30.sdp, pad: 5.sdp),
        T(text, size: 13, weight: FontWeight.bold),
      ],
    ),
  );

  Widget _row(String text, bool sel, VoidCallback onTap) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      color: f ? const Color(0x2DFFFFFF) : null,
      padding: EdgeInsets.symmetric(vertical: 6.sdp, horizontal: 3.sdp),
      child: Row(
        children: [
          Icon(
            sel ? Icons.radio_button_checked : Icons.radio_button_off,
            color: sel ? C.select : Colors.white70,
            size: 15.sdp,
          ),
          SizedBox(width: 6.sdp),
          Expanded(child: T(text, size: 11, color: sel ? C.select : Colors.white, lines: 1)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Tracks>(
      stream: player.stream.tracks,
      initialData: player.state.tracks,
      builder: (_, snap) {
        final tr = snap.data ?? const Tracks();
        final cur = player.state.track;
        final w = player.state.width, h = player.state.height;
        return Container(
          width: 235.sdp,
          color: Colors.black,
          child: SafeArea(
            right: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    RoundBtn('ic_close', size: 30, pad: 5, onTap: onClose),
                    SizedBox(width: 8.sdp),
                    const T('Information', size: 15, weight: FontWeight.bold),
                  ],
                ),
                Container(
                  height: 1.sdp,
                  color: const Color(0x12FFFFFF),
                  margin: EdgeInsets.only(top: 4.sdp),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(left: 15.sdp, right: 8.sdp, bottom: 10.sdp),
                    children: [
                      _head('ic_series', S.video_tracks),
                      if (w != null && h != null && w > 0)
                        Padding(
                          padding: EdgeInsets.all(3.sdp),
                          child: T('${w}x$h', size: 11, color: C.titleSub),
                        ),
                      for (final v in tr.video)
                        _row(_label(v.id, v.title, v.language), v.id == cur.video.id, () => player.setVideoTrack(v)),
                      _head('ic_audiotrack', S.audio_tracks),
                      for (final a in tr.audio)
                        _row(_label(a.id, a.title, a.language), a.id == cur.audio.id, () => player.setAudioTrack(a)),
                      if (tr.subtitle.length > 2) ...[
                        _head('ic_closed_captioning', 'Subtitles'),
                        for (final s in tr.subtitle)
                          _row(
                            _label(s.id, s.title, s.language),
                            s.id == cur.subtitle.id,
                            () => player.setSubtitleTrack(s),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Clock text for the live chip (follows the 12/24 h setting).
String clockText(DateTime d) {
  if (Store.use24h) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "HD", "FHD", "4K" from the video height, like the Android player.
String resolutionText(int? height) {
  if (height == null || height <= 0) return '--';
  if (height >= 2160) return '4K';
  if (height >= 1440) return '2K';
  if (height >= 1080) return 'FHD';
  if (height >= 720) return 'HD';
  return '${height}p';
}

String durText(Duration d) {
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
