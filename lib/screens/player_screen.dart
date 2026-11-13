import '../orientation.dart';
import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';

enum PlayerMode { live, vod, episodes }

/// Video player for live channels, movies and episodes.
class PlayerScreen extends StatefulWidget {
  final PlayerMode mode;
  final List<StreamItem> channels;
  final StreamItem? startChannel;
  final String title;
  final String url;
  final String resumeKey;
  final List<Episode> episodes;
  final int startEpisode;

  const PlayerScreen._({
    required this.mode,
    this.channels = const [],
    this.startChannel,
    this.title = '',
    this.url = '',
    this.resumeKey = '',
    this.episodes = const [],
    this.startEpisode = 0,
  });

  factory PlayerScreen.live(
          {required List<StreamItem> channels, required StreamItem start}) =>
      PlayerScreen._(mode: PlayerMode.live, channels: channels, startChannel: start);

  factory PlayerScreen.vod(
          {required String title,
          required String url,
          required String resumeKey}) =>
      PlayerScreen._(
          mode: PlayerMode.vod, title: title, url: url, resumeKey: resumeKey);

  factory PlayerScreen.episodes(
          {required String seriesName,
          required List<Episode> episodes,
          required int start}) =>
      PlayerScreen._(
          mode: PlayerMode.episodes,
          title: seriesName,
          episodes: episodes,
          startEpisode: start);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player = Player(
      configuration: const PlayerConfiguration(bufferSize: 64 * 1024 * 1024));
  late final VideoController _video = VideoController(_player);
  final List<StreamSubscription> _subs = [];

  int _channelIndex = 0;
  int _episodeIndex = 0;
  String _title = '';
  String _resumeKey = '';
  String? _error;
  EpgEntry? _now;
  EpgEntry? _next;
  Timer? _saveTimer;
  bool _showChannels = false;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _subs.add(_player.stream.error.listen((e) {
      if (!mounted || e.isEmpty) return;
      // media_kit also reports minor errors (a bad track, a dropped segment)
      // while the video keeps playing. Only show the overlay if playback
      // really did not start.
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        final st = _player.state;
        final playing = st.playing && (st.width ?? 0) > 0 || st.position > Duration.zero;
        if (!playing) setState(() => _error = 'Could not play this stream.');
      });
    }));
    _subs.add(_player.stream.position.listen((p) {
      if (_error != null && p > Duration.zero && mounted) setState(() => _error = null);
    }));
    _subs.add(_player.stream.completed.listen((done) {
      if (done && widget.mode == PlayerMode.episodes && Store.autoplayNext) {
        if (_episodeIndex + 1 < widget.episodes.length) {
          _playEpisode(_episodeIndex + 1);
        }
      }
    }));

    switch (widget.mode) {
      case PlayerMode.live:
        _channelIndex = widget.channels
            .indexWhere((c) => c.key == widget.startChannel!.key)
            .clamp(0, widget.channels.length - 1);
        _playChannel(_channelIndex);
        break;
      case PlayerMode.vod:
        _title = widget.title;
        _resumeKey = widget.resumeKey;
        _open(widget.url, resume: true);
        break;
      case PlayerMode.episodes:
        _playEpisode(widget.startEpisode);
        break;
    }

    if (widget.mode != PlayerMode.live) {
      _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _savePos());
    }
  }

  Future<void> _open(String url, {bool resume = false}) async {
    setState(() => _error = null);
    await _player.open(Media(url, httpHeaders: {'User-Agent': 'IPTVSmartersPro'}));
    if (resume && _resumeKey.isNotEmpty) {
      final pos = Store.resumeAt(_resumeKey);
      if (pos > 30) {
        // Wait until the duration is known before seeking.
        await _player.stream.duration.firstWhere((d) => d > Duration.zero)
            .timeout(const Duration(seconds: 15), onTimeout: () => Duration.zero);
        await _player.seek(Duration(seconds: pos));
      }
    }
  }

  void _savePos() {
    if (_resumeKey.isEmpty) return;
    final pos = _player.state.position.inSeconds;
    final dur = _player.state.duration.inSeconds;
    // Forget the position when nearly finished.
    Store.setResume(_resumeKey, dur > 0 && pos > dur - 60 ? 0 : pos);
  }

  void _playChannel(int i) {
    if (widget.channels.isEmpty) return;
    _channelIndex = (i + widget.channels.length) % widget.channels.length;
    final ch = widget.channels[_channelIndex];
    _title = ch.name;
    _now = _next = null;
    Store.addRecent(ch);
    _open(Session.src.streamUrl(ch));
    _loadEpg(ch);
    setState(() {});
  }

  Future<void> _loadEpg(StreamItem ch) async {
    try {
      final list = await Session.src.shortEpg(ch);
      final now = DateTime.now();
      final upcoming = list.where((e) => e.end.isAfter(now)).toList();
      if (!mounted || widget.channels[_channelIndex].key != ch.key) return;
      setState(() {
        _now = upcoming.isNotEmpty ? upcoming[0] : null;
        _next = upcoming.length > 1 ? upcoming[1] : null;
      });
    } catch (_) {}
  }

  void _playEpisode(int i) {
    _savePos();
    _episodeIndex = i;
    final ep = widget.episodes[i];
    _title = '${widget.title} • S${ep.season} E${ep.number}';
    _resumeKey = 'episode:${ep.id}';
    _open(Session.src.episodeUrl(ep), resume: true);
    setState(() {});
  }

  @override
  void dispose() {
    _savePos();
    _saveTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    WakelockPlus.disable();
    restoreOrientation();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  List<Widget> _topBar() {
    final isLive = widget.mode == PlayerMode.live;
    final ch = isLive ? widget.channels[_channelIndex] : null;
    return [
      IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            if (_now != null)
              Text(
                  'Now: ${_now!.title}${_next != null ? '   •   Next: ${_next!.title}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
      if (isLive) ...[
        IconButton(
          icon: Icon(Store.isFavorite(ch!) ? Icons.favorite : Icons.favorite_border,
              color: Colors.white),
          onPressed: () async {
            await Store.toggleFavorite(ch);
            setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.list, color: Colors.white),
          onPressed: () => setState(() => _showChannels = !_showChannels),
        ),
      ],
      if (widget.mode == PlayerMode.episodes &&
          _episodeIndex + 1 < widget.episodes.length)
        IconButton(
          tooltip: 'Next episode',
          icon: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: () => _playEpisode(_episodeIndex + 1),
        ),
      IconButton(
        tooltip: 'Audio and subtitles',
        icon: const Icon(Icons.subtitles_outlined, color: Colors.white),
        onPressed: _tracksSheet,
      ),
    ];
  }

  void _tracksSheet() {
    final tracks = _player.state.tracks;
    final cur = _player.state.track;
    String label(String? title, String? lang, String id) =>
        [title, lang].where((s) => s != null && s.isNotEmpty).join(' • ').isEmpty
            ? id
            : [title, lang].where((s) => s != null && s.isNotEmpty).join(' • ');
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(children: [
        const ListTile(title: Text('Audio')),
        ...tracks.audio.map((t) => ListTile(
              leading: Icon(t.id == cur.audio.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text(label(t.title, t.language, t.id)),
              onTap: () {
                _player.setAudioTrack(t);
                Navigator.pop(context);
              },
            )),
        const Divider(),
        const ListTile(title: Text('Subtitles')),
        ...tracks.subtitle.map((t) => ListTile(
              leading: Icon(t.id == cur.subtitle.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked),
              title: Text(label(t.title, t.language, t.id)),
              onTap: () {
                _player.setSubtitleTrack(t);
                Navigator.pop(context);
              },
            )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.mode == PlayerMode.live;
    final theme = MaterialVideoControlsThemeData(
      topButtonBar: _topBar(),
      seekBarMargin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      bottomButtonBarMargin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      bottomButtonBar: [
        if (isLive)
          MaterialCustomButton(
            icon: const Icon(Icons.skip_previous),
            onPressed: () => _playChannel(_channelIndex - 1),
          ),
        const MaterialPlayOrPauseButton(),
        if (isLive)
          MaterialCustomButton(
            icon: const Icon(Icons.skip_next),
            onPressed: () => _playChannel(_channelIndex + 1),
          ),
        if (!isLive) const MaterialPositionIndicator(),
        const Spacer(),
      ],
      displaySeekBar: !isLive,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        MaterialVideoControlsTheme(
          normal: theme,
          fullscreen: theme,
          child: Video(
            controller: _video,
            controls: MaterialVideoControls,
          ),
        ),
        if (_error != null)
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => isLive
                      ? _playChannel(_channelIndex)
                      : widget.mode == PlayerMode.episodes
                          ? _playEpisode(_episodeIndex)
                          : _open(widget.url, resume: true),
                  child: const Text('Try again'),
                ),
              ]),
            ),
          ),
        if (isLive && _showChannels)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 300,
            child: Container(
              color: Colors.black.withValues(alpha: 0.85),
              child: SafeArea(
                child: ListView.builder(
                  itemCount: widget.channels.length,
                  itemBuilder: (_, i) {
                    final c = widget.channels[i];
                    return ListTile(
                      selected: i == _channelIndex,
                      leading: SizedBox(
                          width: 40,
                          height: 30,
                          child: NetImage(c.icon, fit: BoxFit.contain)),
                      title: Text(c.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        _playChannel(i);
                        setState(() => _showChannels = false);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
