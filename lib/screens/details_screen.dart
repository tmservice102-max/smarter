import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

/// Movie or series details.
class DetailsScreen extends StatefulWidget {
  final StreamItem item;
  const DetailsScreen({super.key, required this.item});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  int _season = -1;

  bool get _isSeries => widget.item.type == ContentType.series;

  Future<SeriesInfo> _load() async {
    if (_isSeries) return Session.src.seriesInfo(widget.item);
    return SeriesInfo(await Session.src.movieInfo(widget.item), {});
  }

  void _playMovie() async {
    await Store.addRecent(widget.item);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen.vod(
        title: widget.item.name,
        url: Session.src.streamUrl(widget.item),
        resumeKey: widget.item.key,
      ),
    ));
    setState(() {});
  }

  void _playEpisode(List<Episode> eps, int index) async {
    await Store.addRecent(widget.item);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen.episodes(
          seriesName: widget.item.name, episodes: eps, start: index),
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fav = Store.isFavorite(widget.item);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        actions: [
          IconButton(
            icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
                color: fav ? Colors.redAccent : null),
            onPressed: () async {
              await Store.toggleFavorite(widget.item);
              setState(() {});
            },
          ),
        ],
      ),
      body: AsyncView<SeriesInfo>(
        load: _load,
        builder: (context, data) {
          final info = data.info;
          final seasons = data.seasons.keys.toList()..sort();
          if (_season == -1 && seasons.isNotEmpty) _season = seasons.first;
          final eps = data.seasons[_season] ?? [];
          final resume = Store.resumeAt(widget.item.key);
          return ListView(children: [
            SizedBox(
              height: 220,
              child: Stack(fit: StackFit.expand, children: [
                NetImage(info.backdrop.isNotEmpty ? info.backdrop : info.cover,
                    fallback: Icons.movie),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xFF0E1117)],
                    ),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.item.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Wrap(spacing: 12, runSpacing: 4, children: [
                    if (info.rating.isNotEmpty)
                      Text('★ ${info.rating}',
                          style: const TextStyle(color: Colors.amber)),
                    if (info.releaseDate.isNotEmpty) Text(info.releaseDate),
                    if (info.duration.isNotEmpty) Text(info.duration),
                    if (info.genre.isNotEmpty) Text(info.genre),
                  ]),
                  const SizedBox(height: 16),
                  if (!_isSeries)
                    Row(children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48)),
                          onPressed: _playMovie,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(resume > 30 ? 'Resume' : 'Play'),
                        ),
                      ),
                      if (info.trailer.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48)),
                          onPressed: () => launchUrl(
                              Uri.parse(
                                  'https://www.youtube.com/watch?v=${info.trailer}'),
                              mode: LaunchMode.externalApplication),
                          icon: const Icon(Icons.ondemand_video),
                          label: const Text('Trailer'),
                        ),
                      ],
                    ]),
                  if (info.plot.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(info.plot, style: const TextStyle(height: 1.4)),
                  ],
                  if (info.cast.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Cast: ${info.cast}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                  if (info.director.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Director: ${info.director}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ],
              ),
            ),
            if (_isSeries && seasons.isNotEmpty) ...[
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: seasons
                      .map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('Season $s'),
                              selected: s == _season,
                              onSelected: (_) => setState(() => _season = s),
                            ),
                          ))
                      .toList(),
                ),
              ),
              ...List.generate(eps.length, (i) {
                final e = eps[i];
                return ListTile(
                  leading: SizedBox(
                    width: 96,
                    height: 56,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: NetImage(e.image, fallback: Icons.play_circle),
                    ),
                  ),
                  title: Text('${e.number}. ${e.title}',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: e.duration.isNotEmpty ? Text(e.duration) : null,
                  onTap: () => _playEpisode(eps, i),
                );
              }),
            ],
            if (_isSeries && seasons.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyView('No episodes found'),
              ),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}
