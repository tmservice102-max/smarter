// Movie details (DetailsMovieActivity / activity_details_movie).
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'details_kit.dart';
import 'nav.dart';
import 'player_vod_page.dart';

class DetailsMoviePage extends StatefulWidget {
  final StreamItem item;
  const DetailsMoviePage({super.key, required this.item});
  @override
  State<DetailsMoviePage> createState() => _DetailsMoviePageState();
}

class _DetailsMoviePageState extends State<DetailsMoviePage> {
  MovieInfo? _info;
  bool _loading = true;
  List<(String, String)>? _cast; // null while loading

  StreamItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final i = await Session.src.movieInfo(item);
      if (mounted) setState(() => _info = i);
      if (Store.showCast && i.tmdbId.isNotEmpty && (Session.app?.tmdbKey ?? '').isNotEmpty) _loadCast(i.tmdbId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadCast(String id) async {
    setState(() => _cast = null);
    var list = <(String, String)>[];
    try {
      list = await tmdbCast(id);
    } catch (_) {}
    if (mounted) setState(() => _cast = list);
  }

  bool get _castShown =>
      Store.showCast && (_info?.tmdbId.isNotEmpty ?? false) && (Session.app?.tmdbKey ?? '').isNotEmpty;

  void _play() {
    Store.addRecent(item);
    go(
      context,
      VodPlayerPage(title: item.name, url: Session.src.streamUrl(item), resumeKey: item.key),
    ).then((_) => mounted ? setState(() {}) : null);
  }

  @override
  Widget build(BuildContext context) {
    final i = _info;
    final cover = (i?.cover.isNotEmpty ?? false) ? i!.cover : item.icon;
    final fav = Store.isFavorite(item);
    final resume = Store.resumeAt(item.key) > 30;
    final rating = (i?.rating.isNotEmpty ?? false) ? i!.rating : item.rating;
    final canDownload = Session.app?.download ?? true;
    return BlurBg(
      image: (i?.backdrop.isNotEmpty ?? false) ? i!.backdrop : cover,
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            PageTop(
              title: i == null ? S.movies_home : item.name,
              icon: 'ic_movie',
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
                TopBtn('ic_feedback', onTap: () => feedbackDialog(context, item.name)),
              ],
            ),
            SizedBox(height: 5.sdp),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Poster + stars
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 5,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.sdp),
                            child: SizedBox.expand(child: NetImg(cover)),
                          ),
                        ),
                        Expanded(flex: 1, child: Center(child: Stars(rating))),
                      ],
                    ),
                  ),
                  SizedBox(width: 15.sdp),
                  Expanded(
                    flex: 3,
                    child: _loading
                        ? const Loader()
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InfoTable([
                                  (S.directed_by, T(na(i?.director ?? ''), size: 10)),
                                  (S.release_date, T(na(i?.releaseDate ?? ''), size: 10)),
                                  (
                                    S.duration,
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: SaveBox(
                                        padding: EdgeInsets.symmetric(horizontal: 5.sdp, vertical: 1.sdp),
                                        child: T(durationText(i?.duration ?? ''), size: 10),
                                      ),
                                    ),
                                  ),
                                  (S.genre, T(na(i?.genre ?? ''), size: 10)),
                                  (S.cast, T(na(i?.cast ?? ''), size: 10, lines: 3)),
                                ]),
                                DownloadLine(item.key),
                                SizedBox(height: 5.sdp),
                                SaveBtn(icon: 'ic_smart_display', text: resume ? S.resume : S.play, onTap: _play),
                                SizedBox(height: 10.sdp),
                                Row(
                                  children: [
                                    if (canDownload)
                                      Expanded(
                                        flex: 10,
                                        child: SaveBtn(
                                          icon: 'iv_downloading',
                                          text: S.download,
                                          onTap: () => startDownload(
                                            context,
                                            id: item.key,
                                            title: item.name,
                                            icon: cover,
                                            url: Session.src.streamUrl(item),
                                          ),
                                        ),
                                      ),
                                    if (i != null && i.trailer.isNotEmpty) ...[
                                      SizedBox(width: 6.sdp),
                                      Expanded(
                                        flex: 8,
                                        child: SaveBtn(
                                          icon: 'ic_smart_display',
                                          text: S.trailer,
                                          onTap: () => openExternal(
                                            i.trailer.startsWith('http')
                                                ? i.trailer
                                                : 'https://www.youtube.com/watch?v=${i.trailer}',
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (i != null && i.backdrop.isNotEmpty) ...[
                                      SizedBox(width: 6.sdp),
                                      Expanded(
                                        flex: 9,
                                        child: SaveBtn(
                                          icon: 'ic_image',
                                          text: S.gallery,
                                          onTap: () => openGallery(context, [i.backdrop, cover]),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (_castShown && (_cast == null || _cast!.isNotEmpty)) ...[
                                  Padding(
                                    padding: EdgeInsets.only(top: 10.sdp, bottom: 3.sdp),
                                    child: T(S.top_billed_cast, size: 10, weight: FontWeight.bold),
                                  ),
                                  _cast == null
                                      ? SizedBox(height: 35.sdp, child: const Loader(size: 30))
                                      : CastRow(_cast!),
                                ],
                                Padding(padding: EdgeInsets.all(10.sdp), child: T(na(i?.plot ?? ''), size: 10)),
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
