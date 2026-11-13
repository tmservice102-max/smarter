// Downloaded movies and episodes (DownloadActivity / row_video_list).
import 'dart:io';
import 'package:material_ui/material_ui.dart';
import '../downloads.dart';
import '../ui/dialogs.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'player_vod_page.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  @override
  void initState() {
    super.initState();
    Downloads.instance.load();
  }

  String _size(int b) {
    if (b >= 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(2)} GB';
    if (b >= 1 << 20) return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
    return '${(b / 1024).toStringAsFixed(0)} KB';
  }

  Future<void> _delete(DownloadItem d) async {
    final ok = await appDialog(context, icon: 'ic_delete', title: S.delete, msg: S.sure_delete);
    if (ok) await Downloads.instance.remove(d);
  }

  @override
  Widget build(BuildContext context) {
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: ListenableBuilder(
          listenable: Downloads.instance,
          builder: (context, _) {
            final items = Downloads.instance.items.where((d) => d.status != DlStatus.failed).toList();
            var used = 0;
            for (final d in items) {
              if (d.status == DlStatus.done) {
                try {
                  used += File(d.path).lengthSync();
                } catch (_) {}
              }
            }
            return Column(children: [
              PageTop(title: S.downloads, icon: 'iv_downloading', trailing: [
                Padding(
                  padding: EdgeInsets.all(4.sdp),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Ic('ic_sd_storage', size: 26.sdp, pad: 2.sdp),
                    SizedBox(width: 5.sdp),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      T(_size(used), size: 10),
                      T('${items.length} ${S.downloaded}', size: 9, color: C.titleSub),
                    ]),
                    SizedBox(width: 6.sdp),
                  ]),
                ),
              ]),
              SizedBox(height: 5.sdp),
              Expanded(
                child: items.isEmpty
                    ? Empty(S.err_no_data_found)
                    : GridView.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisExtent: 138.sdp),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final d = items[i];
                          final done = d.status == DlStatus.done;
                          return Tap(
                            onTap: done
                                ? () => go(context, VodPlayerPage(title: d.title, url: d.path, resumeKey: 'dl:${d.id}'))
                                : null,
                            onLongPress: () => _delete(d),
                            builder: (f) => Container(
                              margin: EdgeInsets.all(4.sdp),
                              decoration: BoxDecoration(
                                color: C.load,
                                borderRadius: BorderRadius.circular(3.sdp),
                                border: Border.all(color: f ? C.select : Colors.transparent, width: 2.sdp),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3.sdp),
                                child: Stack(fit: StackFit.expand, children: [
                                  NetImg(d.icon),
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      color: const Color(0x99000000),
                                      padding: EdgeInsets.all(3.sdp),
                                      child: T(d.title, size: 8, lines: 2, align: TextAlign.center),
                                    ),
                                  ),
                                  if (!done)
                                    Container(
                                      color: const Color(0x88000000),
                                      alignment: Alignment.center,
                                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                                        SizedBox(
                                          width: 30.sdp,
                                          height: 30.sdp,
                                          child: CircularProgressIndicator(
                                            value: d.total > 0 ? d.progress : null,
                                            color: C.primary,
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        SizedBox(height: 4.sdp),
                                        T('${(d.progress * 100).toStringAsFixed(0)}%', size: 9),
                                      ]),
                                    ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
