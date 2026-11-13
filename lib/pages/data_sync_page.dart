// Refreshes saved lists on start (DataSyncActivity / activity_data_sync.xml).
import 'package:material_ui/material_ui.dart';

import '../library.dart';
import '../models.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';

class DataSyncPage extends StatefulWidget {
  const DataSyncPage({super.key});
  @override
  State<DataSyncPage> createState() => _DataSyncPageState();
}

class _DataSyncPageState extends State<DataSyncPage> {
  int _stage = 0; // 0 idle, 1 live, 2 movies, 3 series
  int _percent = 5;
  String _status = S.sync_preparing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _step(ContentType t, int stage, int pct, String text) async {
    if (!mounted) return;
    setState(() {
      _stage = stage;
      _percent = pct;
      _status = text;
    });
    final lib = Library.I;
    if (!lib.has(t)) return;
    // Automation settings: which sections are refreshed.
    final on = switch (t) {
      ContentType.live => Store.updateLive,
      ContentType.movie => Store.updateMovies,
      ContentType.series => Store.updateSeries,
    };
    if (!on) return;
    try {
      await lib.download(t);
    } catch (_) {}
  }

  Future<void> _run() async {
    await _step(ContentType.live, 1, 45, S.sync_live);
    await _step(ContentType.movie, 2, 70, S.sync_movies);
    await _step(ContentType.series, 3, 90, S.sync_series);
    if (!mounted) return;
    setState(() {
      _percent = 100;
      _status = S.sync_done;
    });
    toast(context, S.sync_done);
    openHome(context);
  }

  @override
  Widget build(BuildContext context) {
    Widget dot(bool on) => Container(
      width: 14.sdp,
      height: 14.sdp,
      decoration: BoxDecoration(shape: BoxShape.circle, color: on ? C.primary : C.primarySub),
    );
    Widget line(bool on) => Expanded(
      flex: 2,
      child: Container(height: 4.sdp, color: on ? C.primary : C.primarySub),
    );
    Widget label(String t) => Expanded(
      flex: 10,
      child: T(t, size: 12, align: TextAlign.center, weight: FontWeight.bold),
    );
    return PageBg(
      side: 0,
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Logo(size: 40.sdp),
            SizedBox(height: 15.sdp),
            SizedBox(
              width: 55.sdp,
              height: 55.sdp,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 54.sdp,
                    height: 54.sdp,
                    child: const CircularProgressIndicator(color: C.primary, strokeWidth: 4),
                  ),
                  T('$_percent%', size: 12, weight: FontWeight.bold),
                ],
              ),
            ),
            SizedBox(height: 10.sdp),
            T(S.sync_wait_message, size: 15, align: TextAlign.center, weight: FontWeight.bold),
            SizedBox(height: 8.sdp),
            T(_status, size: 11),
            SizedBox(height: 15.sdp),
            Padding(
              padding: EdgeInsets.only(left: 120.sdp, right: 30.sdp),
              child: Row(
                children: [
                  label(S.live_tv_home),
                  const Spacer(flex: 3),
                  label(S.movies_home),
                  const Spacer(flex: 3),
                  label(S.series_home),
                ],
              ),
            ),
            SizedBox(height: 10.sdp),
            Padding(
              padding: EdgeInsets.only(left: 90.sdp, right: 60.sdp),
              child: Row(
                children: [
                  dot(true),
                  line(_stage >= 1),
                  dot(_stage >= 1),
                  line(_stage >= 2),
                  dot(_stage >= 2),
                  line(_stage >= 3),
                  dot(_stage >= 3),
                ],
              ),
            ),
            SizedBox(height: 24.sdp),
            T(S.sync_footer_note.replaceAll('TV', 'phone'), size: 8),
          ],
        ),
      ),
    );
  }
}
