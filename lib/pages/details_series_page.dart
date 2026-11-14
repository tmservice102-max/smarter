// Series details (DetailsSeriesActivity / activity_details_series):
// info on top, seasons as chips, episodes as cards below.
import 'package:material_ui/material_ui.dart';

import '../downloads.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'details_kit.dart';
import 'nav.dart';
import 'player_vod_page.dart';

class DetailsSeriesPage extends StatefulWidget {
  final StreamItem item;
  const DetailsSeriesPage({super.key, required this.item});
  @override
  State<DetailsSeriesPage> createState() => _DetailsSeriesPageState();
}

class _DetailsSeriesPageState extends State<DetailsSeriesPage> {
  SeriesInfo? _info;
  bool _loading = true;
  int? _season;
  bool _reverse = false;

  StreamItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final i = await Session.src.seriesInfo(item);
      if (!mounted) return;
      final keys = i.seasons.keys.toList()..sort();
      setState(() {
        _info = i;
        _season = keys.isEmpty ? null : keys.first;
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Episode> get _episodes {
    final l = [...(_info?.seasons[_season] ?? const <Episode>[])]..sort((a, b) => a.number.compareTo(b.number));
    return _reverse ? l.reversed.toList() : l;
  }

  void _play(int index) {
    Store.addRecent(item);
    go(
      context,
      VodPlayerPage.episodes(seriesName: item.name, episodes: _episodes, start: index, seriesIcon: item.icon),
    ).then((_) => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    final info = _info?.info;
    final cover = (info?.cover.isNotEmpty ?? false) ? info!.cover : item.icon;
    final fav = Store.isFavorite(item);
    final seasons = (_info?.seasons.keys.toList() ?? <int>[])..sort();
    final eps = _episodes;
    final rating = (info?.rating.isNotEmpty ?? false) ? info!.rating : item.rating;
    return BlurBg(
      image: (info?.backdrop.isNotEmpty ?? false) ? info!.backdrop : cover,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(5.sdp),
            sliver: SliverToBoxAdapter(
              child: PageTop(
                title: _info == null ? S.series_home : item.name,
                icon: 'ic_series',
                trailing: [
                  TopBtn(
                    fav ? 'ic_favorite' : 'ic_favorite_border',
                    onTap: () async {
                      final added = await Store.toggleFavorite(item);
                      if (!context.mounted) return;
                      toast(context, added ? S.fav_success : S.fav_remove_success);
                      setState(() {});
                    },
                  ),
                  TopBtn('ic_filter_list', onTap: () => setState(() => _reverse = !_reverse)),
                  TopBtn('ic_feedback', onTap: () => feedbackDialog(context, item.name)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.only(left: 10.sdp, right: 5.sdp),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.sdp),
                          child: SizedBox(height: 150.sdp, width: double.infinity, child: NetImg(cover)),
                        ),
                        SizedBox(height: 6.sdp),
                        Stars(rating),
                      ],
                    ),
                  ),
                  SizedBox(width: 15.sdp),
                  Expanded(
                    flex: 30,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InfoTable([
                          (S.directed_by, T(na(info?.director ?? ''), size: 10)),
                          (S.release_date, T(na(info?.releaseDate ?? ''), size: 10)),
                          (S.genre, T(na(info?.genre ?? ''), size: 10)),
                          ('Plot:', T(na(info?.plot ?? ''), size: 10, lines: 6)),
                        ]),
                        if (info != null && info.trailer.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(left: 10.sdp, top: 4.sdp),
                            child: SizedBox(
                              width: 110.sdp,
                              child: SaveBtn(
                                icon: 'ic_smart_display',
                                text: S.trailer,
                                onTap: () => openExternal(
                                  info.trailer.startsWith('http')
                                      ? info.trailer
                                      : 'https://www.youtube.com/watch?v=${info.trailer}',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_loading)
            SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(20.sdp), child: const Loader()),
            )
          else ...[
            // Seasons (row_seasons_list)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(10.sdp, 8.sdp, 5.sdp, 0),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 30.sdp,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final s in seasons)
                        Padding(
                          padding: EdgeInsets.only(right: 3.sdp),
                          child: Tap(
                            onTap: () => setState(() => _season = s),
                            // row_seasons_list: "Seasons N", bold, bg_edit_text pill.
                            builder: (f) => Container(
                              padding: EdgeInsets.fromLTRB(10.sdp, 5.sdp, 10.sdp, 6.sdp),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: C.fill,
                                borderRadius: BorderRadius.circular(f ? 2.sdp : 50.sdp),
                                border: Border.all(color: f ? C.select : C.border, width: f ? 2.sdp : 1.sdp),
                              ),
                              child: T(
                                'Seasons $s',
                                size: 12,
                                weight: FontWeight.bold,
                                color: s == _season ? C.select : Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (eps.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Container(
                    margin: EdgeInsets.all(15.sdp),
                    padding: EdgeInsets.symmetric(horizontal: 15.sdp, vertical: 8.sdp),
                    decoration: BoxDecoration(
                      color: const Color(0x45000000),
                      borderRadius: BorderRadius.circular(4.sdp),
                    ),
                    child: T(S.err_no_episodes_found, size: 12, color: C.primary, weight: FontWeight.bold),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(10.sdp, 6.sdp, 5.sdp, 15.sdp),
                sliver: SliverList.builder(
                  itemCount: eps.length,
                  itemBuilder: (_, i) => _EpisodeRow(ep: eps[i], fallback: cover, onTap: () => _play(i)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// row_list_episodes: inset rounded thumbnail with a play dot, title,
/// small half-star rating, duration chip, and "DOWNLOAD" with a round button.
class _EpisodeRow extends StatelessWidget {
  final Episode ep;
  final String fallback;
  final VoidCallback onTap;
  const _EpisodeRow({required this.ep, required this.fallback, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final key = 'episode:${ep.id}';
    final pos = Store.resumeAt(key);
    final secs = _secs(ep.duration);
    final canDownload = (Session.app?.download ?? true) && Store.showDownload;
    final title = ep.title.isEmpty ? 'Episode ${ep.number}' : ep.title;
    Widget round(String icon, VoidCallback onTap) => Tap(
      onTap: onTap,
      builder: (f) => Container(
        margin: EdgeInsets.all(1.sdp),
        decoration: BoxDecoration(shape: BoxShape.circle, color: f ? C.primary : const Color(0x2DFFFFFF)),
        child: Ic(icon, size: 26.sdp, pad: 4.sdp),
      ),
    );
    return Tap(
      onTap: onTap,
      builder: (f) => Container(
        height: 85.sdp,
        margin: EdgeInsets.only(bottom: 2.sdp),
        decoration: BoxDecoration(
          color: const Color(0x45000000),
          borderRadius: BorderRadius.circular(4.sdp),
          border: Border.all(color: f ? C.select : const Color(0x33000000), width: f ? 2.sdp : 1.sdp),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(6.sdp),
              child: SizedBox(
                width: 130.sdp,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3.sdp),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      NetImg(ep.image.isNotEmpty ? ep.image : fallback, placeholder: 'placeholder_horizontal'),
                      Center(
                        child: Container(
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x2DFFFFFF)),
                          child: Ic('ic_play', size: 22.sdp, pad: 2.sdp),
                        ),
                      ),
                      if (pos > 0 && secs > 0)
                        Positioned(
                          left: 5.sdp,
                          right: 5.sdp,
                          bottom: 5.sdp,
                          child: LinearProgressIndicator(
                            value: (pos / secs).clamp(0, 1),
                            minHeight: 2.sdp,
                            color: C.primary,
                            backgroundColor: const Color(0x55FFFFFF),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 5.sdp, bottom: 5.sdp, right: 10.sdp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    T(title, size: 10, lines: 1),
                    SizedBox(height: 2.sdp),
                    HalfStars(ep.rating),
                    SizedBox(height: 2.sdp),
                    Container(
                      padding: EdgeInsets.only(left: 4.sdp, right: 4.sdp, bottom: 1.sdp),
                      decoration: BoxDecoration(
                        color: const Color(0x40838383),
                        borderRadius: BorderRadius.circular(2.sdp),
                      ),
                      child: T(ep.duration.isEmpty ? '0' : episodeDuration(ep.duration), size: 8),
                    ),
                    const Spacer(),
                    if (canDownload)
                      ListenableBuilder(
                        listenable: Downloads.instance,
                        builder: (context, _) {
                          final d = Downloads.instance.find(key);
                          final running = d != null && (d.status == DlStatus.running || d.status == DlStatus.queued);
                          final done = d != null && d.status == DlStatus.done;
                          final status = done
                              ? S.downloaded
                              : running
                              ? '${S.downloading} ${(d.progress * 100).toStringAsFixed(0)}%'
                              : S.download;
                          return Row(
                            children: [
                              Expanded(child: T(status, size: 8, weight: FontWeight.bold, lines: 1)),
                              SizedBox(width: 5.sdp),
                              if (running)
                                round('ic_close', () {
                                  Downloads.instance.remove(d);
                                  toast(context, S.download_cancelled);
                                })
                              else
                                round('iv_downloading', () {
                                  if (done) {
                                    toast(context, S.already_download);
                                    return;
                                  }
                                  startDownload(
                                    context,
                                    id: key,
                                    title: title,
                                    icon: ep.image.isNotEmpty ? ep.image : fallback,
                                    url: Session.src.episodeUrl(ep),
                                  );
                                }),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _secs(String d) {
    final p = d.split(':').map((e) => int.tryParse(e) ?? 0).toList();
    if (p.length == 3) return p[0] * 3600 + p[1] * 60 + p[2];
    if (p.length == 2) return p[0] * 60 + p[1];
    return 0;
  }
}
