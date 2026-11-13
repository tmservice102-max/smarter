// Home dashboard (OneUIActivity / activity_themes_one_ui.xml).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../api/source.dart';
import '../library.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';
import 'list_page.dart';
import 'epg_categories_page.dart';
import 'multi_screen_page.dart';
import 'catch_up_page.dart';
import 'notifications_page.dart';
import 'downloads_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'radio_page.dart';

String greeting() {
  final h = DateTime.now().hour;
  if (h < 6) return S.title_good_night;
  if (h < 12) return S.title_good_morning;
  if (h < 16) return S.title_good_afternoon;
  if (h < 20) return S.title_good_evening;
  return S.title_good_night;
}

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _mon = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String longDate(DateTime d) => '${_months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
String shortDate(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_mon[d.month - 1]} ${d.year}';

/// Expiry date saved after each login check.
DateTime? savedExpiry() {
  final a = Store.currentAccount;
  if (a == null) return null;
  final v = Store.prefs.getInt('exp|${a.id}');
  return v == null || v == 0 ? null : DateTime.fromMillisecondsSinceEpoch(v);
}

Future<void> refreshAccountInfo() async {
  final a = Store.currentAccount;
  if (a == null || a.type != AccountType.xtream) return;
  try {
    final info = await ContentSource.forAccount(a).accountInfo();
    if (info != null) {
      await Store.prefs.setInt('exp|${a.id}', info.expires?.millisecondsSinceEpoch ?? 0);
      await Store.prefs.setString('info|${a.id}', '${info.status}|${info.maxConnections}|${info.activeConnections}');
    }
  } catch (_) {}
}

/// Download / reload / open of the home tiles, shared by both dashboards.
mixin HomeActions<W extends StatefulWidget> on State<W> {
  final Map<ContentType, double?> progress = {}; // null = not loading

  Library get lib => Library.I;

  /// [quiet]: no blocking "loading" dialog (automatic load after login).
  Future<void> downloadSection(ContentType t, {bool quiet = false}) async {
    if (progress[t] != null) return;
    setState(() => progress[t] = 0);
    final timer = Timer.periodic(const Duration(milliseconds: 40), (tm) {
      final p = progress[t];
      if (p == null || p >= 0.5) return;
      setState(() => progress[t] = p + 0.01);
    });
    if (!quiet) Busy.show(context);
    try {
      await lib.download(t);
      timer.cancel();
      if (!quiet) Busy.hide();
      for (var p = (progress[t] ?? 0.5); p < 1; p += 0.02) {
        await Future.delayed(const Duration(milliseconds: 10));
        if (!mounted) return;
        setState(() => progress[t] = p);
      }
      if (!mounted) return;
      setState(() => progress[t] = null);
      toast(context, S.added_success);
    } catch (e) {
      timer.cancel();
      if (!quiet) Busy.hide();
      await lib.clear(t);
      if (!mounted) return;
      setState(() => progress[t] = null);
      final msg = e.toString().replaceFirst('Exception: ', '');
      toast(context, msg.contains('No data') ? msg : S.err_server_not_connected, error: true);
    }
  }

  Future<void> reloadSection(ContentType t) async {
    final ok = await appDialog(context, icon: 'ic_reset', title: S.reload_data, msg: S.sure_reload_data);
    if (ok) downloadSection(t);
  }

  void openSection(ContentType t, {bool playlist = false}) {
    if (!lib.has(t)) {
      downloadSection(t);
      return;
    }
    go(context, ListPage(type: t, playlist: playlist)).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> needLive(Widget page) async {
    if (lib.has(ContentType.live)) {
      go(context, page);
      return;
    }
    final ok = await appDialog(
      context,
      icon: 'ic_file_download',
      title: S.live_not_downloaded,
      msg: S.want_to_download,
    );
    if (ok) downloadSection(ContentType.live);
  }
}

class HomePage extends StatefulWidget {
  /// Download the sections that aren't on the phone yet (after login).
  final bool autoLoad;
  const HomePage({super.key, this.autoLoad = false});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with HomeActions {
  Timer? _tick;
  static bool _adShown = false;

  @override
  void initState() {
    super.initState();
    refreshAccountInfo().then((_) {
      if (mounted) setState(() {});
    });
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _popupAd();
      if (widget.autoLoad) _autoLoad();
    });
  }

  Future<void> _autoLoad() async {
    for (final t in [ContentType.live, ContentType.movie, ContentType.series]) {
      if (!mounted) return;
      if (!lib.has(t)) await downloadSection(t, quiet: true);
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _popupAd() async {
    final ad = Session.app?.popupAd;
    if (_adShown || ad == null || !(ad['image'] ?? '').startsWith('http') || (ad['url'] ?? '').isEmpty) return;
    _adShown = true;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                if (ad['type'] == 'external') {
                  openExternal(ad['url']!);
                } else {
                  openWeb(ad['url']!);
                }
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6.sdp),
                child: NetImg(ad['image']!, placeholder: 'placeholder_horizontal', fit: BoxFit.contain),
              ),
            ),
            Positioned(right: 4, top: 4, child: IconTap('ic_close', onTap: () => Navigator.pop(ctx))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = Session.app;
    final exp = savedExpiry();
    final a = Store.currentAccount;
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            // Top bar
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Logo(size: 30.sdp),
                  SizedBox(width: 10.sdp),
                  T(S.app_name, size: 16),
                  Expanded(child: T(shortDate(DateTime.now()), size: 11, align: TextAlign.center, lines: 1)),
                  Ic('ic_wifi', size: 35.sdp, pad: 8.sdp),
                  IconTap('ic_round_notifications', onTap: () => go(context, const NotificationsPage())),
                  if (app?.download ?? true) IconTap('iv_downloading', onTap: () => go(context, const DownloadsPage())),
                  if (app?.radio ?? false) IconTap('ic_radio', onTap: () => needLive(const RadioPage())),
                  IconTap('ic_outline_person', pad: 7, onTap: () => go(context, const ProfilePage())),
                  IconTap('ic_people', pad: 6, onTap: () => signOut(context)),
                  IconTap(
                    'ic_player_setting',
                    onTap: () => go(context, const SettingsPage()).then((_) {
                      if (mounted) setState(() {});
                    }),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.sdp),
            // Tiles
            Expanded(
              flex: 20,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: BigTile(
                      gradient: G.tv,
                      icon: 'ic_tv',
                      iconSize: 60,
                      title: S.live_tv_home,
                      titleSize: 19,
                      type: ContentType.live,
                      progress: progress[ContentType.live],
                      onTap: () => openSection(ContentType.live),
                      onRenew: () => lib.has(ContentType.live)
                          ? reloadSection(ContentType.live)
                          : downloadSection(ContentType.live),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          flex: 20,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 10.sdp),
                              Expanded(
                                child: BigTile(
                                  gradient: G.movies,
                                  icon: 'ic_movie',
                                  iconSize: 50,
                                  contentTop: 1,
                                  contentBottom: 15,
                                  title: S.movies_home,
                                  titleSize: 15,
                                  type: ContentType.movie,
                                  progress: progress[ContentType.movie],
                                  onTap: () => openSection(ContentType.movie),
                                  onRenew: () => lib.has(ContentType.movie)
                                      ? reloadSection(ContentType.movie)
                                      : downloadSection(ContentType.movie),
                                ),
                              ),
                              SizedBox(width: 10.sdp),
                              Expanded(
                                child: BigTile(
                                  gradient: G.series,
                                  icon: 'ic_series',
                                  iconSize: 50,
                                  contentTop: 1,
                                  contentBottom: 15,
                                  title: S.series_home,
                                  titleSize: 15,
                                  type: ContentType.series,
                                  progress: progress[ContentType.series],
                                  onTap: () => openSection(ContentType.series),
                                  onRenew: () => lib.has(ContentType.series)
                                      ? reloadSection(ContentType.series)
                                      : downloadSection(ContentType.series),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.sdp),
                        Expanded(
                          flex: 7,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(width: 10.sdp),
                              Expanded(
                                child: SmallTile(
                                  icon: 'ic_note',
                                  title: S.live_with_epg_home,
                                  dim: !lib.has(ContentType.live) || progress[ContentType.live] != null,
                                  onTap: () => needLive(const EpgCategoriesPage()),
                                ),
                              ),
                              SizedBox(width: 10.sdp),
                              Expanded(
                                child: SmallTile(
                                  icon: 'ic_multiple_screen',
                                  title: S.multiple_screen,
                                  dim: !lib.has(ContentType.live) || progress[ContentType.live] != null,
                                  onTap: () => needLive(const MultiScreenPage()),
                                ),
                              ),
                              SizedBox(width: 10.sdp),
                              Expanded(
                                child: SmallTile(
                                  icon: 'ic_timer_start',
                                  title: S.catch_up_home,
                                  dim: !lib.has(ContentType.live) || progress[ContentType.live] != null,
                                  onTap: () => needLive(const CatchUpPage()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom line
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  T(
                    '${S.expiration} ${exp == null ? (a?.type == AccountType.xtream ? 'Unlimited' : '') : longDate(exp)}',
                    size: 12,
                  ),
                  const Spacer(),
                  T('${greeting()} ${a?.name ?? ''}', size: 12, lines: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big gradient tile (Live TV / Movies / Series).
class BigTile extends StatelessWidget {
  final Gradient gradient;
  final String icon;
  final double iconSize;
  final String title;
  final double titleSize;
  final ContentType type;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback onRenew;

  /// Movies / Series: paddingTop 1sdp, paddingBottom 15sdp (icon sits higher).
  final double contentTop;
  final double contentBottom;
  const BigTile({
    super.key,
    this.contentTop = 0,
    this.contentBottom = 0,
    required this.gradient,
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.titleSize,
    required this.type,
    required this.progress,
    required this.onTap,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final lib = Library.I;
    final has = lib.has(type);
    return Tap(
      onTap: onTap,
      onLongPress: has ? onRenew : null,
      builder: (f) => ClipRRect(
        borderRadius: BorderRadius.circular(5.sdp),
        child: Container(
          decoration: BoxDecoration(gradient: gradient),
          foregroundDecoration: f
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(4.sdp),
                  border: Border.all(color: Colors.white, width: 3.sdp),
                )
              : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Not downloaded / loading: the background is darkened
              // (vw_live_tv), the loaded part shows again as a bar that
              // fills from the left (ProgressBar pb_gradient). Icon and
              // title stay white on top.
              if (!has || progress != null) const ColoredBox(color: Color(0xB3000000)),
              if (progress != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (progress ?? 0).clamp(0.0, 1.0),
                    heightFactor: 1,
                    child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
                  ),
                ),
              const Positioned.fill(child: TilePattern()),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: contentTop.sdp, bottom: contentBottom.sdp),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Ic(icon, size: iconSize.sdp),
                      SizedBox(height: 2.sdp),
                      T(title, size: titleSize, weight: FontWeight.bold),
                    ],
                  ),
                ),
              ),
              // count badge
              Positioned(
                top: 4.sdp,
                right: 4.sdp,
                child: SaveBox(
                  padding: EdgeInsets.fromLTRB(4.sdp, 2.sdp, 4.sdp, 3.sdp),
                  child: T(shortCount(lib.count(type)), size: 8, weight: FontWeight.bold),
                ),
              ),
              // last updated / download pill
              Positioned(
                left: 10.sdp,
                right: 10.sdp,
                bottom: 10.sdp,
                height: 30.sdp,
                child: GestureDetector(
                  onTap: onRenew,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x4D000000),
                      borderRadius: BorderRadius.circular(10.sdp),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (has)
                          Flexible(
                            child: Padding(
                              padding: EdgeInsets.only(left: 5.sdp),
                              child: T('${S.last_updated} ${timeSpan(lib.updated(type))}', size: 7, lines: 1),
                            ),
                          ),
                        SizedBox(width: 5.sdp),
                        Container(
                          width: 25.sdp,
                          height: 20.sdp,
                          padding: EdgeInsets.all(2.sdp),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.sdp),
                            border: Border.all(color: const Color(0x79494949), width: 1.sdp),
                          ),
                          child: Ic(has ? 'ic_repeate' : 'ic_file_download', size: 16.sdp, color: Colors.black),
                        ),
                      ],
                    ),
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

/// Small teal tile (Live with EPG / Multiscreen / Catch up).
class SmallTile extends StatelessWidget {
  final String icon;
  final String title;
  final bool dim;
  final VoidCallback onTap;
  const SmallTile({super.key, required this.icon, required this.title, required this.dim, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      builder: (f) => Container(
        decoration: BoxDecoration(
          // bg_card_all, darkened (vw_*) until Live TV is downloaded.
          color: dim ? Color.alphaBlend(const Color(0xB3000000), const Color(0xFF4DB6AC)) : const Color(0xFF4DB6AC),
          borderRadius: BorderRadius.circular(5.sdp),
          border: f ? Border.all(color: Colors.white, width: 3.sdp) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Ic(icon, size: 18.sdp, pad: 1.sdp),
            SizedBox(width: 3.sdp),
            Flexible(child: T(title, size: 10, lines: 1, weight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
