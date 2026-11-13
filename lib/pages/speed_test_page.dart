// Network speed test (NetworkSpeedActivity / activity_network_speed.xml).
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:material_ui/material_ui.dart';

import '../config.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';

enum _State { idle, preparing, running, finished, error }

class SpeedTestPage extends StatefulWidget {
  const SpeedTestPage({super.key});
  @override
  State<SpeedTestPage> createState() => _SpeedTestPageState();
}

class _SpeedTestPageState extends State<SpeedTestPage> {
  static const _file = '${AppConfig.panelUrl}/uploads/1Mo.dat';
  _State _state = _State.idle;
  double _gauge = 0; // degrees, 0..240
  double _down = 0;
  double _up = 0;
  bool _gone = false;

  @override
  void dispose() {
    _gone = true;
    super.dispose();
  }

  static String _fmt(double mbps) {
    if (mbps <= 0) return '0 Mbps';
    if (mbps >= 1000) return '${(mbps / 1000).toStringAsFixed(2)} Gbps';
    return '${mbps.toStringAsFixed(2)} Mbps';
  }

  /// getPositionByRate: the needle angle for a speed.
  static double _angle(double rate) {
    final r = rate.clamp(0, 100).toDouble();
    if (r <= 1) return r * 30;
    if (r <= 10) return r * 6 + 30;
    if (r <= 30) return (r - 10) * 3 + 90;
    if (r <= 50) return (r - 30) * 1.5 + 150;
    if (r <= 100) return (r - 50) * 1.2 + 180;
    return 240;
  }

  void _set(VoidCallback f) {
    if (!_gone && mounted) setState(f);
  }

  Future<void> _run() async {
    if (_state == _State.preparing || _state == _State.running) {
      toast(context, S.speed_test_in_progress);
      return;
    }
    _set(() {
      _state = _State.preparing;
      _gauge = 0;
      _down = 0;
      _up = 0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (_gone) return;
    final client = http.Client();
    try {
      // Download: read the test file (again, up to 8 seconds) and show the
      // speed as it comes in.
      _set(() => _state = _State.running);
      final sw = Stopwatch()..start();
      var bytes = 0;
      var rounds = 0;
      while (rounds < 10 && sw.elapsedMilliseconds < 8000) {
        final res = await client
            .send(http.Request('GET', Uri.parse('$_file?r=${DateTime.now().microsecondsSinceEpoch}')))
            .timeout(const Duration(seconds: 15));
        if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
        await for (final chunk in res.stream) {
          if (_gone) return;
          bytes += chunk.length;
          final secs = sw.elapsedMicroseconds / 1e6;
          if (secs > 0) {
            final mbps = bytes * 8 / secs / 1e6;
            _set(() {
              _down = mbps;
              _gauge = _angle(mbps);
            });
          }
        }
        rounds++;
      }
      if (bytes == 0) throw Exception('empty');
      // Upload: send 1 MB and time it.
      final data = Uint8List(1024 * 1024);
      final r = math.Random();
      for (var i = 0; i < data.length; i += 997) {
        data[i] = r.nextInt(256);
      }
      final up = Stopwatch()..start();
      try {
        await client.post(Uri.parse(_file), body: data).timeout(const Duration(seconds: 20));
        final secs = up.elapsedMicroseconds / 1e6;
        if (secs > 0) _up = data.length * 8 / secs / 1e6;
      } catch (_) {}
      _set(() {
        _gauge = _angle((_down + _up) / 2);
        _state = _State.finished;
      });
    } catch (_) {
      if (_gone || !mounted) return;
      toast(context, S.err_internet_not_connected, error: true);
      _set(() {
        _state = _State.error;
        _gauge = 0;
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget layer(String name, Color color) => Positioned.fill(
      child: Image.asset('assets/img/$name.webp', color: color, colorBlendMode: BlendMode.srcIn),
    );
    final showResult = _state == _State.running || _state == _State.finished;
    final avg = _down > 0 ? (_down + _up) / 2 : _up;
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            PageTop(title: S.speed_test, icon: 'ic_speed'),
            SizedBox(height: 5.sdp),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 10,
                    child: Container(
                      decoration: cardSub(),
                      alignment: Alignment.center,
                      child: FittedBox(
                        child: Padding(
                          padding: EdgeInsets.only(top: 20.sdp),
                          child: SizedBox(
                            width: 190.sdp,
                            height: 190.sdp,
                            child: Stack(
                              children: [
                                layer('speed_bg_one', C.title),
                                layer('speed_bg_two', C.primary),
                                layer('speed_bg_c', C.primarySub),
                                layer('speed_num', C.titleSub),
                                Positioned.fill(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(end: _gauge),
                                    duration: const Duration(milliseconds: 500),
                                    builder: (_, a, child) => Transform.rotate(angle: a * math.pi / 180, child: child),
                                    child: Image.asset(
                                      'assets/img/speed_bar.webp',
                                      color: C.primary,
                                      colorBlendMode: BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.sdp),
                  Expanded(
                    flex: 13,
                    child: Container(
                      decoration: cardSub(),
                      padding: EdgeInsets.all(15.sdp),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_state != _State.running)
                            Tap(
                              onTap: _state == _State.preparing ? null : _run,
                              builder: (f) => SaveBox(
                                focused: f,
                                padding: EdgeInsets.only(right: 10.sdp),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 35.sdp,
                                      height: 30.sdp,
                                      child: _state == _State.preparing
                                          ? Padding(
                                              padding: EdgeInsets.all(8.sdp),
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Ic('ic_speed', size: 30.sdp, pad: 7.sdp),
                                    ),
                                    T('START SPEED TEST', size: 14),
                                  ],
                                ),
                              ),
                            ),
                          if (showResult) ...[
                            SizedBox(height: 10.sdp),
                            T(S.speed_download_label.replaceFirst('%s', _fmt(_down)), size: 12, color: _orange),
                            if (_state == _State.finished)
                              T(
                                '${S.speed_upload_label.replaceFirst('%s', _fmt(_up))}\n'
                                '${S.speed_average_label.replaceFirst('%s', _fmt(avg))}',
                                size: 12,
                                color: _orange,
                                align: TextAlign.center,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _orange = Color(0xFFFF9800);
