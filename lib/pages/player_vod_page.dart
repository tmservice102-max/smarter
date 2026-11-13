// Movie / episode / catch-up player (ExoPlayerActivity, activity_player_exoplayer).
import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import 'player_kit.dart';

class VodPlayerPage extends StatefulWidget {
  final String title;
  final String url;
  final String resumeKey; // '' = do not remember the position
  final List<Episode> episodes;
  final int start;
  final String seriesName;
  final String seriesIcon;

  /// One video (movie, catch-up, single stream, download).
  const VodPlayerPage({super.key, required this.title, required this.url, this.resumeKey = ''})
      : episodes = const [],
        start = 0,
        seriesName = '',
        seriesIcon = '';

  /// Episodes of a season, starting at [start]; plays the next one when done.
  const VodPlayerPage.episodes(
      {super.key, required this.seriesName, required this.episodes, required this.start, this.seriesIcon = ''})
      : title = seriesName,
        url = '',
        resumeKey = '';

  @override
  State<VodPlayerPage> createState() => _VodPlayerPageState();
}

class _VodPlayerPageState extends State<VodPlayerPage> {
  late final Player _player = newPlayer();
  late final VideoController _video = VideoController(_player);
  final List<StreamSubscription> _subs = [];

  late String _title = widget.title;
  late String _key = widget.resumeKey;
  late int _ep = widget.start;
  bool get _isEpisodes => widget.episodes.isNotEmpty;

  bool _controls = true;
  bool _locked = false;
  bool _list = false;
  bool _info = false;
  bool _error = false;
  bool _buffering = true;
  bool _playing = false;
  int _fit = 0;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  double? _drag;
  Timer? _hide;
  Timer? _save;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    playerEnter();
    _subs.add(_player.stream.playing.listen((v) => setState(() => _playing = v)));
    _subs.add(_player.stream.buffering.listen((v) => setState(() => _buffering = v)));
    _subs.add(_player.stream.duration.listen((d) => setState(() => _dur = d)));
    _subs.add(_player.stream.position.listen((p) {
      if (!mounted) return;
      setState(() {
        _pos = p;
        if (p > Duration.zero) _error = false;
      });
    }));
    _subs.add(_player.stream.error.listen((e) {
      if (e.isEmpty) return;
      final t = _token;
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || t != _token) return;
        if (_player.state.position == Duration.zero) setState(() => _error = true);
      });
    }));
    _subs.add(_player.stream.completed.listen((done) {
      if (!done) return;
      _savePos(finished: true);
      if (_isEpisodes && Store.autoplayNext && _ep + 1 < widget.episodes.length) _playEp(_ep + 1);
    }));
    _save = Timer.periodic(const Duration(seconds: 10), (_) => _savePos());
    if (_isEpisodes) {
      _playEp(_ep);
    } else {
      _open(widget.url);
    }
    _autoHide();
  }

  Future<void> _open(String url) async {
    _token++;
    setState(() {
      _error = false;
      _pos = Duration.zero;
      _dur = Duration.zero;
    });
    await _player.open(media(url));
    final at = _key.isEmpty ? 0 : Store.resumeAt(_key);
    if (at > 30) {
      await _player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 15), onTimeout: () => Duration.zero);
      await _player.seek(Duration(seconds: at));
    }
  }

  void _playEp(int i) {
    _savePos();
    _ep = i;
    final e = widget.episodes[i];
    _title = '${widget.seriesName} - S${e.season.toString().padLeft(2, '0')}E${e.number.toString().padLeft(2, '0')}'
        '${e.title.isNotEmpty && !e.title.contains(widget.seriesName) ? ' - ${e.title}' : ''}';
    _key = 'episode:${e.id}';
    _open(Session.src.episodeUrl(e));
  }

  void _savePos({bool finished = false}) {
    if (_key.isEmpty) return;
    final p = _player.state.position.inSeconds, d = _player.state.duration.inSeconds;
    if (p <= 0 && !finished) return;
    Store.setResume(_key, finished || (d > 0 && p > d - 60) ? 0 : p);
  }

  void _autoHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 5), () {
      if (mounted && _drag == null && !_list && !_info) setState(() => _controls = false);
    });
  }

  void _seekBy(int s) {
    final to = _pos + Duration(seconds: s);
    _player.seek(to < Duration.zero ? Duration.zero : (_dur > Duration.zero && to > _dur ? _dur : to));
    _autoHide();
  }

  @override
  void dispose() {
    _savePos();
    _hide?.cancel();
    _save?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    playerLeave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Dim.init(context);
    final side = _list ? 250.sdp : (_info ? 235.sdp : 0.0);
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 180),
          left: side,
          top: 0,
          right: 0,
          bottom: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (_list || _info) {
                setState(() => _list = _info = false);
              } else {
                setState(() => _controls = !_controls);
              }
              if (_controls) _autoHide();
            },
            onDoubleTapDown: (d) {
              if (_locked) return;
              final w = MediaQuery.sizeOf(context).width;
              _seekBy(d.localPosition.dx < w / 2 ? -10 : 10);
            },
            onDoubleTap: () {},
            child: Video(controller: _video, controls: NoVideoControls, fit: playerFits[_fit]),
          ),
        ),
        if (!_locked && !_list && !_info) ...[
          if (_controls) Positioned.fill(child: IgnorePointer(child: Container(color: const Color(0x46000000)))),
          Center(
            child: _error
                ? RoundBtn('ic_reset', onTap: () => _isEpisodes ? _playEp(_ep) : _open(widget.url))
                : _buffering && !_playing
                    ? const Loader(size: 40)
                    : _controls
                        ? Row(mainAxisSize: MainAxisSize.min, children: [
                            RoundIcon(Icons.replay_10, onTap: () => _seekBy(-10)),
                            SizedBox(width: 30.sdp),
                            RoundBtn(_playing ? 'ic_pause' : 'ic_play', size: 42, pad: 6, onTap: () {
                              _player.playOrPause();
                              _autoHide();
                            }),
                            SizedBox(width: 30.sdp),
                            RoundIcon(Icons.forward_10, onTap: () => _seekBy(10)),
                          ])
                        : const SizedBox(),
          ),
          if (_controls) ..._bars(),
        ],
        if (_locked) Positioned.fill(child: LockOverlay(onUnlock: () => setState(() => _locked = false))),
        if (_list) Positioned(left: 0, top: 0, bottom: 0, width: 250.sdp, child: _episodeList()),
        if (_info)
          Positioned(
              left: 0, top: 0, bottom: 0, child: TracksPanel(player: _player, onClose: () => setState(() => _info = false))),
      ]),
    );
  }

  List<Widget> _bars() {
    final max = _dur.inMilliseconds.toDouble();
    final val = (_drag ?? _pos.inMilliseconds.toDouble()).clamp(0.0, max <= 0 ? 0.0 : max);
    final hasNext = _isEpisodes && _ep + 1 < widget.episodes.length;
    return [
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: Container(
          decoration: topShade,
          padding: EdgeInsets.fromLTRB(6.sdp, 6.sdp, 8.sdp, 18.sdp),
          child: SafeArea(
            bottom: false,
            child: Row(children: [
              RoundBtn('ic_player_back', size: 30, pad: 5, onTap: () => Navigator.maybePop(context)),
              Expanded(child: Padding(padding: EdgeInsets.all(10.sdp), child: T(_title, size: 12, lines: 1, weight: FontWeight.bold))),
              if (_isEpisodes)
                PBtn('ic_playlist', pad: 2, onTap: () => setState(() {
                      _list = true;
                      _controls = false;
                    })),
              PBtn('ic_crop', onTap: () {
                setState(() => _fit = (_fit + 1) % playerFits.length);
                toast(context, fitLabel(playerFits[_fit]));
                _autoHide();
              }),
              PBtn('ic_information', pad: 4, onTap: () => setState(() {
                    _info = true;
                    _controls = false;
                  })),
              PBtn('ic_unlock', onTap: () => setState(() {
                    _locked = true;
                    _controls = false;
                  })),
              PBtn('ic_close', pad: 3, onTap: () => setState(() => _controls = false)),
            ]),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          decoration: bottomShade,
          padding: EdgeInsets.fromLTRB(14.sdp, 25.sdp, 14.sdp, 8.sdp),
          child: SafeArea(
            top: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              if (hasNext)
                Tap(
                  onTap: () => _playEp(_ep + 1),
                  builder: (f) => Container(
                    padding: EdgeInsets.all(5.sdp),
                    decoration: BoxDecoration(
                      color: f ? C.primary : const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0x55FFFFFF)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Ic('ic_skip_next', size: 20.sdp),
                      SizedBox(width: 5.sdp),
                      const T('Next Episode', size: 13),
                      SizedBox(width: 4.sdp),
                    ]),
                  ),
                ),
              Row(children: [
                T(durText(Duration(milliseconds: val.toInt())), size: 10),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 2.sdp,
                      activeTrackColor: C.primary,
                      inactiveTrackColor: const Color(0x55FFFFFF),
                      thumbColor: C.primary,
                      overlayShape: SliderComponentShape.noOverlay,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.sdp),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.sdp, vertical: 8.sdp),
                      child: Slider(
                        value: val,
                        max: max <= 0 ? 1 : max,
                        onChanged: max <= 0
                            ? null
                            : (v) {
                                setState(() => _drag = v);
                                _hide?.cancel();
                              },
                        onChangeEnd: (v) {
                          _player.seek(Duration(milliseconds: v.toInt()));
                          setState(() => _drag = null);
                          _autoHide();
                        },
                      ),
                    ),
                  ),
                ),
                T(durText(_dur), size: 10),
              ]),
            ]),
          ),
        ),
      ),
    ];
  }

  /// row_player_epi list on the left.
  Widget _episodeList() {
    return Container(
      color: Colors.black,
      child: SafeArea(
        right: false,
        child: ListView.builder(
          controller: ScrollController(initialScrollOffset: (_ep * 75.sdp - 80.sdp).clamp(0, double.infinity)),
          padding: EdgeInsets.all(5.sdp),
          itemCount: widget.episodes.length,
          itemBuilder: (_, i) {
            final e = widget.episodes[i];
            final sel = i == _ep;
            final color = sel ? C.select : Colors.white;
            return Tap(
              onTap: () => setState(() {
                _list = false;
                _playEp(i);
              }),
              builder: (f) => Container(
                height: 70.sdp,
                margin: EdgeInsets.only(top: 5.sdp),
                padding: EdgeInsets.all(5.sdp),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1F22),
                  borderRadius: BorderRadius.circular(5.sdp),
                  border: Border.all(color: f ? Colors.white : const Color(0xFF1E1F22), width: 1.sdp),
                ),
                child: Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.sdp),
                    child: NetImg(e.image.isNotEmpty ? e.image : widget.seriesIcon,
                        placeholder: 'placeholder_horizontal', width: 95.sdp, height: 58.sdp),
                  ),
                  SizedBox(width: 6.sdp),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      T('Episode ${e.number}', size: 12, color: color),
                      T(e.title, size: 10, color: color, lines: 2),
                    ]),
                  ),
                ]),
              ),
            );
          },
        ),
      ),
    );
  }
}
