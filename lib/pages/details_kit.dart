// Shared parts of the movie and series detail pages.
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import '../api/panel_api.dart';
import '../downloads.dart';
import '../store.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';

/// iv_bg_blur + iv_alpha: the poster blurred behind the page, dimmed by bg_dark at 80 %.
class BlurBg extends StatelessWidget {
  final String image;
  final Widget child;
  const BlurBg({super.key, required this.image, required this.child});
  @override
  Widget build(BuildContext context) {
    Dim.init(context);
    return Scaffold(
      backgroundColor: C.bgBottom,
      body: Stack(fit: StackFit.expand, children: [
        if (image.startsWith('http'))
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: NetImg(image, placeholder: 'placeholder_horizontal'),
          ),
        Opacity(
          opacity: image.startsWith('http') ? 0.8 : 1,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [C.bgBottom, C.bgTop]),
            ),
          ),
        ),
        SafeArea(child: child),
      ]),
    );
  }
}

/// Five stars from a 0–10 rating (ApplicationUtil.setRating: floor, max 5).
class Stars extends StatelessWidget {
  final String rating;
  final double size;
  final bool tenScale;
  const Stars(this.rating, {super.key, this.size = 18, this.tenScale = false});
  @override
  Widget build(BuildContext context) {
    var r = double.tryParse(rating) ?? 0;
    if (tenScale) r = r / 2;
    final n = r.floor().clamp(0, 5);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < 5; i++) Ic(i < n ? 'ic_star' : 'ic_star_border', size: size.sdp, color: null),
    ]);
  }
}

/// Two-column "Directed By: / value" table.
class InfoTable extends StatelessWidget {
  final List<(String, Widget)> rows;
  const InfoTable(this.rows, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.all(10.sdp),
        child: Table(
          columnWidths: const {0: FlexColumnWidth(0.9), 1: FlexColumnWidth(2)},
          defaultVerticalAlignment: TableCellVerticalAlignment.top,
          children: [
            for (final (k, v) in rows)
              TableRow(children: [
                Padding(padding: EdgeInsets.only(bottom: 4.sdp), child: T(k, size: 10)),
                Padding(padding: EdgeInsets.only(bottom: 4.sdp), child: v),
              ]),
          ],
        ),
      );
}

String na(String v) => v.isEmpty || v == 'null' ? S.n_a : v;

/// "0h 0m" from Xtream's "01:45:00" or minutes.
String durationText(String v) {
  if (v.isEmpty) return '0h 0m';
  final p = v.split(':');
  if (p.length >= 2) {
    final h = int.tryParse(p[0]) ?? 0, m = int.tryParse(p[1]) ?? 0;
    return '${h}h ${m}m';
  }
  final mins = int.tryParse(v) ?? 0;
  return '${mins ~/ 60}h ${mins % 60}m';
}

/// focused_save_btn with icon + text (Play, Download, Trailer, Gallery).
class SaveBtn extends StatelessWidget {
  final String icon;
  final String text;
  final VoidCallback? onTap;
  final bool busy;
  const SaveBtn({super.key, required this.icon, required this.text, this.onTap, this.busy = false});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: busy ? null : onTap,
        builder: (f) => SaveBox(
          focused: f,
          padding: EdgeInsets.symmetric(vertical: 5.sdp, horizontal: 6.sdp),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            busy
                ? SizedBox(
                    width: 16.sdp,
                    height: 16.sdp,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Ic(icon, size: 20.sdp, pad: 2.sdp),
            SizedBox(width: 6.sdp),
            Flexible(child: T(text, size: 11, lines: 1)),
          ]),
        ),
      );
}

/// Download progress line (ll_download_progress) for one download id.
class DownloadLine extends StatelessWidget {
  final String id;
  const DownloadLine(this.id, {super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Downloads.instance,
        builder: (_, _) {
          final d = Downloads.instance.find(id);
          if (d == null || d.status == DlStatus.done || d.status == DlStatus.failed) return const SizedBox();
          final pct = (d.progress * 100).toStringAsFixed(0);
          return Padding(
            padding: EdgeInsets.only(top: 5.sdp),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  T('${S.downloading} $pct%', size: 9),
                  SizedBox(height: 4.sdp),
                  LinearProgressIndicator(
                    value: d.total > 0 ? d.progress : null,
                    minHeight: 3.sdp,
                    color: C.primary,
                    backgroundColor: const Color(0x33FFFFFF),
                  ),
                ]),
              ),
              IconTap('ic_close', size: 22, pad: 4, onTap: () {
                Downloads.instance.remove(d);
                toast(context, S.download_cancelled);
              }),
            ]),
          );
        },
      );
}

/// Starts a download unless it is already there (DownloadService).
void startDownload(BuildContext context,
    {required String id, required String title, required String icon, required String url}) {
  final d = Downloads.instance.find(id);
  if (d != null && d.status == DlStatus.done) {
    toast(context, S.already_download);
    return;
  }
  if (d != null && d.status == DlStatus.running) return;
  Downloads.instance.start(id: id, title: title, icon: icon, url: url);
  toast(context, S.downloading);
}

/// dialog_feed_back: sends a report to the panel.
Future<void> feedbackDialog(BuildContext context, String title) async {
  final ctrl = TextEditingController();
  final msg = await panelDialog<String>(
    context,
    title: S.feedback,
    width: 280,
    child: Builder(
      builder: (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 5.sdp),
          decoration: BoxDecoration(
            color: C.fill,
            borderRadius: BorderRadius.circular(3.sdp),
            border: Border.all(color: C.border),
          ),
          child: TextField(
            controller: ctrl,
            minLines: 3,
            maxLines: 5,
            style: TextStyle(color: C.title, fontSize: 12.ssp),
            cursorColor: Colors.white,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: S.please_describe_the_problem,
              hintStyle: TextStyle(color: Colors.white54, fontSize: 12.ssp),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(10.sdp),
          child: Row(children: [
            Expanded(child: GradButton(text: S.cancel, textSize: 13, onTap: () => Navigator.pop(ctx))),
            SizedBox(width: 8.sdp),
            Expanded(
                child: GradButton(
                    text: S.submit,
                    textSize: 13,
                    gradient: G.primaryBtn,
                    onTap: () {
                      if (ctrl.text.trim().isEmpty) {
                        toast(ctx, S.err_cannot_empty, error: true);
                        return;
                      }
                      Navigator.pop(ctx, ctrl.text.trim());
                    })),
          ]),
        ),
      ]),
    ),
  );
  if (msg == null || msg.isEmpty) return;
  final a = Store.currentAccount;
  try {
    await PanelApi.report(user: a?.username ?? '', pass: a?.password ?? '', title: title, msg: msg);
    if (context.mounted) toast(context, 'Thanks for your feedback');
  } catch (e) {
    if (context.mounted) toast(context, '$e', error: true);
  }
}

/// GalleryActivity: swipe through the pictures of a movie or series.
void openGallery(BuildContext context, List<String> images) {
  final list = images.where((e) => e.startsWith('http')).toSet().toList();
  if (list.isEmpty) return;
  go(
    context,
    Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        PageView(children: [
          for (final u in list) InteractiveViewer(child: Center(child: NetImg(u, fit: BoxFit.contain))),
        ]),
        SafeArea(
            child: Builder(builder: (c) => IconTap('ic_arrow_left', size: 33, pad: 5, onTap: () => Navigator.pop(c)))),
      ]),
    ),
  );
}
