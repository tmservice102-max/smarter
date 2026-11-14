// Live TV / Movies / Series list (LiveTvActivity, MovieActivity, SeriesActivity
// with activity_list.xml): categories on the left, grid on the right.
import 'package:material_ui/material_ui.dart';

import '../library.dart';
import '../models.dart';
import '../parental.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'details_movie_page.dart';
import 'details_series_page.dart';
import 'filter_categories_page.dart';
import 'player_live_page.dart';
import 'search_page.dart';

String typeTitle(ContentType t) => switch (t) {
  ContentType.live => S.live_tv_home,
  ContentType.movie => S.movies_home,
  ContentType.series => S.series_home,
};

String typeIcon(ContentType t) => switch (t) {
  ContentType.live => 'list_channels',
  ContentType.movie => 'ic_movie',
  ContentType.series => 'ic_series',
};

/// Opens one item the way the Android lists do.
void openItem(BuildContext context, StreamItem item, List<StreamItem> list) {
  switch (item.type) {
    case ContentType.live:
      final i = list.indexWhere((e) => e.key == item.key);
      go(context, PlayerLivePage(channels: list, index: i < 0 ? 0 : i));
      break;
    case ContentType.movie:
      go(context, DetailsMoviePage(item: item));
      break;
    case ContentType.series:
      go(context, DetailsSeriesPage(item: item));
      break;
  }
}

class ListPage extends StatefulWidget {
  final ContentType type;
  final bool playlist; // M3U lists have no special categories

  /// Multiscreen channel picker (FilterActivity): a tap returns the item.
  final bool pick;
  const ListPage({super.key, required this.type, this.playlist = false, this.pick = false});
  @override
  State<ListPage> createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final _catSearch = TextEditingController();
  List<Category> _cats = [];
  String _sel = '';
  List<StreamItem>? _items;
  bool _loading = true;

  ContentType get t => widget.type;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await Library.I.load(t);
    } catch (_) {}
    if (!mounted) return;
    final hidden = Store.hiddenCategories.toSet();
    final server = Library.I.categories(t).where((c) => !hidden.contains('${t.name}:${c.id}')).toList();
    final specials = widget.playlist
        ? <Category>[]
        : [
            Category(Library.fav, S.favourite),
            Category(Library.recent, S.recently),
            Category(Library.recentlyAdded, S.recently_add),
            if (t != ContentType.live) Category(Library.ai, S.ai_recommend),
          ];
    _cats = [...specials, ...server];
    if (_cats.isEmpty) {
      setState(() {
        _loading = false;
        _items = [];
      });
      return;
    }
    final def = server.isNotEmpty ? server.first : _cats.first;
    _loading = false;
    _select(def);
  }

  Future<void> _select(Category c) async {
    if (!await Parental.check(context, c.name)) return;
    if (!mounted) return;
    setState(() {
      _sel = c.id;
      _items = Library.I.items(t, c.id);
    });
  }

  Future<void> _filter() async {
    final lib = Library.I;
    var rev = lib.reversed(t);
    final ok = await panelDialog<bool>(
      context,
      title: S.filter,
      child: StatefulBuilder(
        builder: (ctx, set) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, label) in [(true, 'Date: Oldest first'), (false, 'Date: Newest')])
              Tap(
                onTap: () => set(() => rev = i),
                builder: (f) => Container(
                  padding: EdgeInsets.all(10.sdp),
                  color: f ? const Color(0x2DFFFFFF) : null,
                  child: Row(
                    children: [
                      Icon(
                        rev == i ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: Colors.white,
                        size: 16.sdp,
                      ),
                      SizedBox(width: 8.sdp),
                      T(label, size: 13, color: C.title),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(10.sdp),
              child: Row(
                children: [
                  Expanded(
                    child: GradButton(
                      text: S.filter_remove,
                      textSize: 13,
                      onTap: () {
                        rev = false;
                        Navigator.pop(ctx, true);
                      },
                    ),
                  ),
                  SizedBox(width: 6.sdp),
                  Expanded(
                    child: GradButton(
                      text: S.apply_filter,
                      textSize: 13,
                      gradient: G.primaryBtn,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await lib.setReversed(t, rev);
      if (mounted) setState(() => _items = lib.items(t, _sel));
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _catSearch.text.trim().toLowerCase();
    final cats = q.isEmpty ? _cats : _cats.where((c) => c.name.toLowerCase().contains(q)).toList();
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: PageTop(
                title: typeTitle(t),
                // activity_list keeps the same list icon for all three.
                icon: 'list_channels',
                trailing: [
                  if (!widget.playlist)
                    TopBtn(
                      'ic_list_ordered',
                      onTap: () async {
                        await go(context, FilterCategoriesPage(type: t));
                        _load();
                      },
                    ),
                  TopBtn('ic_filter_list', onTap: _filter),
                  TopBtn(
                    'ic_search',
                    onTap: () async {
                      final r = await go<StreamItem>(context, SearchPage(type: t, pick: widget.pick));
                      if (r != null && context.mounted) Navigator.pop(context, r);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Categories
                  Expanded(
                    flex: 10,
                    child: Column(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 2.sdp),
                          decoration: BoxDecoration(
                            color: const Color(0x2DFFFFFF),
                            borderRadius: BorderRadius.circular(2.sdp),
                          ),
                          child: TextField(
                            controller: _catSearch,
                            onChanged: (_) => setState(() {}),
                            style: TextStyle(color: C.title, fontSize: 11.ssp),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: S.search_categories,
                              hintStyle: TextStyle(color: C.titleSub, fontSize: 11.ssp),
                              contentPadding: EdgeInsets.fromLTRB(5.sdp, 5.sdp, 3.sdp, 5.sdp),
                              // drawableEnd="@drawable/ic_search"
                              suffixIcon: Padding(
                                padding: EdgeInsets.only(left: 3.sdp, right: 3.sdp),
                                child: Ic('ic_search', size: 16.sdp),
                              ),
                              suffixIconConstraints: BoxConstraints(minWidth: 22.sdp, minHeight: 16.sdp),
                            ),
                          ),
                        ),
                        SizedBox(height: 2.sdp),
                        Expanded(
                          child: _loading
                              ? const Loader()
                              : ListView.builder(
                                  itemCount: cats.length,
                                  itemBuilder: (_, i) => _CatRow(
                                    name: cats[i].name,
                                    selected: cats[i].id == _sel,
                                    onTap: () => _select(cats[i]),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1.sdp,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0x1BFFFFFF), Color(0x00000000)],
                      ),
                    ),
                  ),
                  // Grid
                  Expanded(
                    flex: 28,
                    child: _items == null
                        ? const Loader()
                        : _items!.isEmpty
                        ? Empty(S.err_no_data_found, sub: S.error_category_list)
                        : _Grid(
                            type: t,
                            items: _items!,
                            pick: widget.pick,
                            onBack: () => setState(() => _items = Library.I.items(t, _sel)),
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

/// row_category: white text, orange text and left bar when selected.
class _CatRow extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback onTap;
  const _CatRow({required this.name, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      builder: (f) => Container(
        decoration: f
            ? const BoxDecoration(gradient: LinearGradient(colors: [Color(0x40FFFFFF), Color(0x00000000)]))
            : null,
        child: Row(
          children: [
            Container(width: 2.sdp, height: 28.sdp, color: selected ? C.select : Colors.transparent),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.sdp, vertical: 7.sdp),
                child: T(
                  name.isEmpty ? 'Uncategorized' : name,
                  size: 12,
                  color: selected ? C.select : Colors.white,
                  lines: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final ContentType type;
  final List<StreamItem> items;
  final VoidCallback onBack;
  final bool pick;
  const _Grid({required this.type, required this.items, required this.onBack, this.pick = false});
  @override
  Widget build(BuildContext context) {
    final live = type == ContentType.live;
    return GridView.builder(
      padding: EdgeInsets.only(left: 3.sdp, bottom: 10.sdp),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisExtent: posterHeight(context, live),
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => PosterCard(
        item: items[i],
        live: live,
        onTap: () => pick ? Navigator.pop(context, items[i]) : openItem(context, items[i], items),
      ),
    );
  }
}

/// Card height in the 5-column lists: AdapterChannel / AdapterMovie make
/// each card a seventh of the screen width high (x1.15 for posters), plus
/// the 2sdp margins.
double posterHeight(BuildContext context, bool live) {
  final w = MediaQuery.sizeOf(context).width / 7;
  return (live ? w : w * 1.15) + 4.sdp;
}

/// row_list_live / row_list_movie: image, title strip at the bottom, rating.
class PosterCard extends StatelessWidget {
  final StreamItem item;
  final bool live;
  final VoidCallback onTap;
  const PosterCard({super.key, required this.item, required this.live, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final rating = item.rating;
    final showRating = !live && rating.isNotEmpty && rating != '0';
    return Tap(
      onTap: onTap,
      builder: (f) => Container(
        margin: EdgeInsets.all(2.sdp),
        decoration: live
            ? BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(2.sdp),
                border: Border.all(color: const Color(0x0FFFFFFF), width: 1.sdp),
              )
            : null,
        foregroundDecoration: f
            ? BoxDecoration(
                color: const Color(0x22000000),
                borderRadius: BorderRadius.circular(2.sdp),
                border: Border.all(color: C.select, width: 2.sdp),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2.sdp),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetImg(item.icon, placeholder: live ? 'placeholder_live' : 'placeholder_vertical'),
              // UI settings "Show Movie/ Series Name" (channels always show it).
              if (item.name.isNotEmpty && (live || Store.showCardTitle))
                Positioned(
                  left: 5.sdp,
                  right: 5.sdp,
                  bottom: 5.sdp,
                  child: Container(
                    padding: EdgeInsets.all(2.sdp),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(2.sdp),
                    ),
                    child: Text(
                      item.name,
                      maxLines: live ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 8.ssp, height: live ? 1.08 : 1.2),
                    ),
                  ),
                ),
              if (showRating)
                Positioned(
                  top: 5.sdp,
                  right: 5.sdp,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.sdp, vertical: 1.sdp),
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(2.sdp),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Ic('ic_star_border', size: 11.sdp),
                        SizedBox(width: 2.sdp),
                        T(rating, size: 8),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
