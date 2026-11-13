import 'package:material_ui/material_ui.dart';
import '../downloads.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final dl = Downloads.instance;

  @override
  void initState() {
    super.initState();
    dl.load();
  }

  String _size(int b) {
    if (b <= 0) return '';
    if (b > 1 << 30) return '${(b / (1 << 30)).toStringAsFixed(1)} GB';
    return '${(b / (1 << 20)).toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: ListenableBuilder(
        listenable: dl,
        builder: (context, _) {
          if (dl.items.isEmpty) {
            return const EmptyView('No downloads yet',
                icon: Icons.download_outlined);
          }
          return ListView.builder(
            itemCount: dl.items.length,
            itemBuilder: (_, i) {
              final d = dl.items[i];
              Widget sub;
              switch (d.status) {
                case DlStatus.running:
                case DlStatus.queued:
                  sub = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                            value: d.total > 0 ? d.progress : null),
                        const SizedBox(height: 4),
                        Text(
                            '${_size(d.received)}${d.total > 0 ? ' of ${_size(d.total)}' : ''}  •  keep the app open'),
                      ]);
                  break;
                case DlStatus.done:
                  sub = Text('Downloaded  •  ${_size(d.received)}');
                  break;
                case DlStatus.failed:
                  sub = const Text('Failed. Tap to try again.',
                      style: TextStyle(color: Colors.redAccent));
                  break;
              }
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: NetImage(d.icon, fallback: Icons.movie),
                  ),
                ),
                title: Text(d.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: sub,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => dl.remove(d),
                ),
                onTap: () {
                  if (d.status == DlStatus.done) {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PlayerScreen.vod(
                          title: d.title, url: d.path, resumeKey: 'dl:${d.id}'),
                    ));
                  } else if (d.status == DlStatus.failed) {
                    dl.start(id: d.id, title: d.title, icon: d.icon, url: d.url);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
