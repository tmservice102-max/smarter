// "Live with EPG" (CategoriesActivity -> EPGOneActivity / EPGTwoActivity).
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../ads.dart';
import '../library.dart';
import '../models.dart';
import '../parental.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'catch_up_page.dart';
import 'player_kit.dart';
import 'player_live_page.dart';

/// row_cat_catch_up: icon (or channel logo), name and arrow on a
/// near-black card (Classic theme bg_sub #121212, border #CC0E0E0E).
class CatTile extends StatelessWidget {
  final String name;
  final String icon;
  final String? logo;
  final VoidCallback onTap;
  const CatTile({super.key, required this.name, this.icon = 'ic_tv', this.logo, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      height: 40.sdp,
      margin: EdgeInsets.all(3.sdp),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(1.sdp),
        border: Border.all(color: f ? const Color(0xFFFFAB00) : const Color(0xCC0E0E0E), width: 1.sdp),
      ),
      child: Row(
        children: [
          SizedBox(width: 5.sdp),
          logo == null
              ? Ic(icon, size: 40.sdp, pad: 7.sdp)
              : Padding(
                  padding: EdgeInsets.all(7.sdp),
                  child: NetImg(
                    logo!,
                    placeholder: 'placeholder_live',
                    width: 26.sdp,
                    height: 26.sdp,
                    fit: BoxFit.contain,
                  ),
                ),
          SizedBox(width: 5.sdp),
          Expanded(child: T(name, size: 15, color: C.title, lines: 1)),
          Ic('ic_arrow_right', size: 40.sdp, pad: 10.sdp),
          SizedBox(width: 5.sdp),
        ],
      ),
    ),
  );
}

/// Title row with the "Filter" box on the right (activity_categories /
/// activity_catch_up).
class _FilterTop extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const _FilterTop({required this.title, required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: PageTop(title: title, icon: 'list_channels'),
      ),
      Container(
        width: 200.sdp,
        margin: EdgeInsets.only(right: 2.sdp),
        decoration: BoxDecoration(color: const Color(0x2DFFFFFF), borderRadius: BorderRadius.circular(2.sdp)),
        child: TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          style: TextStyle(color: C.title, fontSize: 11.ssp),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: S.filter,
            hintStyle: TextStyle(color: C.titleSub, fontSize: 11.ssp),
            contentPadding: EdgeInsets.all(5.sdp),
            suffixIcon: Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.sdp),
              child: Ic('ic_search', size: 16.sdp),
            ),
            suffixIconConstraints: BoxConstraints(minWidth: 22.sdp, minHeight: 16.sdp),
          ),
        ),
      ),
    ],
  );
}

/// Grid of live categories, 2 columns.
class EpgCategoriesPage extends StatefulWidget {
  final bool catchUp;
  const EpgCategoriesPage({super.key, this.catchUp = false});
  @override
  State<EpgCategoriesPage> createState() => _EpgCategoriesPageState();
}

class _EpgCategoriesPageState extends State<EpgCategoriesPage> {
  final _q = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Library.I.load(ContentType.live).catchError((_) {}).whenComplete(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  List<StreamItem> _channels(String catId) {
    final all = Library.I.items(ContentType.live, catId);
    return widget.catchUp ? all.where((c) => c.hasArchive).toList() : all;
  }

  @override
  Widget build(BuildContext context) {
    final lib = Library.I;
    final hidden = Store.hiddenCategories.toSet();
    final q = _q.text.trim().toLowerCase();
    final cats = _loading
        ? <(Category, int)>[]
        : [
            for (final c in lib.categories(ContentType.live))
              if (!hidden.contains('live:${c.id}') && (q.isEmpty || c.name.toLowerCase().contains(q)))
                (c, _channels(c.id).length),
          ].where((e) => e.$2 > 0).toList();
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            _FilterTop(
              title: widget.catchUp ? S.catch_up_home : S.categories,
              controller: _q,
              onChanged: () => setState(() {}),
            ),
            SizedBox(height: 5.sdp),
            Expanded(
              child: _loading
                  ? const Loader()
                  : cats.isEmpty
                  ? Empty(S.err_no_data_found)
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 46.sdp,
                      ),
                      itemCount: cats.length,
                      itemBuilder: (_, i) {
                        final (c, _) = cats[i];
                        return CatTile(
                          name: c.name,
                          // CategoriesActivity shows folders, CatchUpActivity a TV.
                          icon: widget.catchUp ? 'ic_tv' : 'ic_folders',
                          onTap: () => Ads.inter(() async {
                            if (!context.mounted || !await Parental.check(context, c.name) || !context.mounted) {
                              return;
                            }
                            final list = _channels(c.id);
                            if (widget.catchUp) {
                              go(context, CatchUpChannelsPage(title: c.name, channels: list));
                            } else {
                              go(context, EpgPage(title: c.name, channels: list));
                            }
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Channels with their guide. Theme 1 = list only (EPGOne), else with a
/// small preview player on top (EPGTwo).
class EpgPage extends StatefulWidget {
  final String title;
  final List<StreamItem> channels;
  const EpgPage({super.key, required this.title, required this.channels});
  @override
  State<EpgPage> createState() => _EpgPageState();
}

class _EpgPageState extends State<EpgPage> {
  final bool _preview = (Session.app?.epgTheme ?? 2) != 1;
  Player? _player;
  VideoController? _video;
  int _i = 0;
  List<EpgEntry>? _epg;
  final List<StreamSubscription> _subs = [];
  bool _buffering = false;

  @override
  void initState() {
    super.initState();
    if (_preview) {
      _player = newPlayer();
      _video = VideoController(_player!);
      _subs.add(_player!.stream.buffering.listen((b) => setState(() => _buffering = b)));
    }
    if (widget.channels.isNotEmpty) _select(0);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player?.dispose();
    super.dispose();
  }

  Future<void> _select(int i) async {
    setState(() {
      _i = i;
      _epg = null;
    });
    final ch = widget.channels[i];
    _player?.open(media(Session.src.streamUrl(ch)));
    try {
      final list = await Session.src.fullEpg(ch);
      final now = DateTime.now();
      final today = list.where((e) => e.end.isAfter(now.subtract(const Duration(hours: 3)))).toList();
      if (mounted && _i == i) setState(() => _epg = today.isEmpty ? list : today);
    } catch (_) {
      if (mounted && _i == i) setState(() => _epg = []);
    }
  }

  void _openPlayer() async {
    await _player?.pause();
    if (!mounted) return;
    await go(context, PlayerLivePage(channels: widget.channels, index: _i));
    if (mounted) _player?.play();
  }

  @override
  Widget build(BuildContext context) {
    final now = _epg?.where((e) => e.isNow).toList() ?? [];
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            Row(
              children: [
                IconTap('ic_player_back', size: 33, pad: 5, onTap: () => Navigator.maybePop(context)),
                Ic('list_channels', size: 30.sdp, pad: 5.sdp, color: C.title),
                SizedBox(width: 6.sdp),
                Expanded(child: T(S.live_with_epg_home, size: 11, lines: 1)),
              ],
            ),
            SizedBox(height: 4.sdp),
            Expanded(
              child: widget.channels.isEmpty
                  ? Empty(S.err_no_data_found)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 12,
                          child: ListView.builder(
                            itemCount: widget.channels.length,
                            itemBuilder: (_, i) => _EpgChannelRow(
                              item: widget.channels[i],
                              selected: i == _i,
                              onTap: () => i == _i && !_preview ? _openPlayer() : _select(i),
                            ),
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
                        Expanded(
                          flex: 25,
                          child: Column(
                            children: [
                              if (_preview)
                                Padding(
                                  padding: EdgeInsets.only(left: 6.sdp, bottom: 5.sdp),
                                  child: SizedBox(
                                    height: 110.sdp,
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: _openPlayer,
                                          child: Container(
                                            width: 200.sdp,
                                            color: Colors.black,
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Video(controller: _video!, controls: NoVideoControls),
                                                if (_buffering) const Loader(size: 35),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10.sdp),
                                        Expanded(
                                          child: Container(
                                            color: const Color(0x08FFFFFF),
                                            padding: EdgeInsets.all(5.sdp),
                                            alignment: Alignment.center,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                T(
                                                  now.isEmpty ? S.err_no_data_found : now.first.title,
                                                  size: 11,
                                                  lines: 2,
                                                  align: TextAlign.center,
                                                  weight: FontWeight.bold,
                                                ),
                                                SizedBox(height: 4.sdp),
                                                T(
                                                  now.isEmpty
                                                      ? '-'
                                                      : '${clockText(now.first.start)} - ${clockText(now.first.end)}',
                                                  size: 10,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Container(
                                  color: const Color(0x3C000000),
                                  child: _epg == null
                                      ? const Loader(size: 30)
                                      : _epg!.isEmpty
                                      // setEpg(null): one "No Data Found" listing.
                                      ? ListView(padding: EdgeInsets.all(5.sdp), children: [const _NoEpgRow()])
                                      : ListView.builder(
                                          padding: EdgeInsets.all(5.sdp),
                                          itemCount: _epg!.length,
                                          itemBuilder: (_, i) => EpgRow(entry: _epg![i]),
                                        ),
                                ),
                              ),
                              // activity_epg_one: banner under the guide.
                              AdBanner(show: Ads.bannerEpg),
                            ],
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

/// row_epg_live_list
class _EpgChannelRow extends StatelessWidget {
  final StreamItem item;
  final bool selected;
  final VoidCallback onTap;
  const _EpgChannelRow({required this.item, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
    onTap: onTap,
    builder: (f) => Container(
      height: 35.sdp,
      decoration: f
          ? const BoxDecoration(gradient: LinearGradient(colors: [Color(0x40FFFFFF), Color(0x00000000)]))
          : null,
      child: Row(
        children: [
          Container(width: 2.sdp, height: 30.sdp, color: selected ? C.select : Colors.transparent),
          SizedBox(width: 5.sdp),
          NetImg(item.icon, placeholder: 'placeholder_live', width: 50.sdp, height: 30.sdp, fit: BoxFit.contain),
          SizedBox(width: 6.sdp),
          Expanded(child: T(item.name, size: 12, color: selected ? C.select : Colors.white, lines: 1)),
        ],
      ),
    ),
  );
}

/// The single listing shown when a channel has no guide.
class _NoEpgRow extends StatelessWidget {
  const _NoEpgRow();
  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: 4.sdp),
    padding: EdgeInsets.fromLTRB(15.sdp, 5.sdp, 8.sdp, 5.sdp),
    color: const Color(0x27FFFFFF),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        T(S.err_no_data_found, size: 11, lines: 1, weight: FontWeight.bold),
        SizedBox(height: 2.sdp),
        T('-', size: 9, color: C.titleSub),
      ],
    ),
  );
}

/// row_epg_listings: title and time; the program on now is highlighted.
class EpgRow extends StatelessWidget {
  final EpgEntry entry;
  final VoidCallback? onTap;
  const EpgRow({super.key, required this.entry, this.onTap});
  @override
  Widget build(BuildContext context) {
    final now = entry.isNow;
    return Tap(
      onTap: onTap,
      builder: (f) => Container(
        margin: EdgeInsets.only(bottom: 4.sdp),
        padding: EdgeInsets.fromLTRB(15.sdp, 5.sdp, 8.sdp, 5.sdp),
        decoration: BoxDecoration(
          color: f || now ? C.primarySub : const Color(0x27FFFFFF),
          border: f || now ? Border.all(color: C.primary, width: 1.sdp) : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  T(entry.title, size: 11, lines: 1, color: entry.isPast ? Colors.white60 : Colors.white),
                  SizedBox(height: 2.sdp),
                  T(
                    '${_day(entry.start)}  ${clockText(entry.start)} - ${clockText(entry.end)}',
                    size: 9,
                    color: C.titleSub,
                  ),
                ],
              ),
            ),
            if (now)
              SizedBox(
                width: 50.sdp,
                child: LinearProgressIndicator(
                  value: entry.progress,
                  color: C.primary,
                  backgroundColor: const Color(0x33FFFFFF),
                ),
              ),
            if (onTap != null) Ic('ic_play', size: 22.sdp, pad: 3.sdp),
          ],
        ),
      ),
    );
  }

  static String _day(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }
}

/// Channels of a category that keep recordings (CatchUpLiveActivity):
/// "Catch Up | name", the Filter box, and each channel's logo.
class CatchUpChannelsPage extends StatefulWidget {
  final String title;
  final List<StreamItem> channels;
  const CatchUpChannelsPage({super.key, required this.title, required this.channels});
  @override
  State<CatchUpChannelsPage> createState() => _CatchUpChannelsPageState();
}

class _CatchUpChannelsPageState extends State<CatchUpChannelsPage> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final list = q.isEmpty ? widget.channels : widget.channels.where((c) => c.name.toLowerCase().contains(q)).toList();
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            _FilterTop(title: '${S.catch_up_home} | ${widget.title}', controller: _q, onChanged: () => setState(() {})),
            SizedBox(height: 5.sdp),
            Expanded(
              child: list.isEmpty
                  ? Empty(S.err_no_data_found)
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 46.sdp,
                      ),
                      itemCount: list.length,
                      itemBuilder: (_, i) => CatTile(
                        name: list[i].name,
                        logo: list[i].icon,
                        onTap: () => Ads.inter(() {
                          if (context.mounted) go(context, CatchUpEpgPage(channel: list[i]));
                        }),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
