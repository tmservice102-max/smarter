import 'package:material_ui/material_ui.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

/// Simple TV guide for one channel (now and upcoming programs).
class EpgScreen extends StatelessWidget {
  final StreamItem channel;
  const EpgScreen({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(channel.name)),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_arrow),
        label: const Text('Watch'),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                PlayerScreen.live(channels: [channel], start: channel))),
      ),
      body: AsyncView<List<EpgEntry>>(
        load: () => Session.src.shortEpg(channel),
        builder: (context, list) {
          final now = DateTime.now();
          final items = list.where((e) => e.end.isAfter(now)).toList();
          if (items.isEmpty) {
            return const EmptyView('No guide data for this channel',
                icon: Icons.event_busy);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => EpgCard(entry: items[i]),
          );
        },
      ),
    );
  }
}

class EpgCard extends StatelessWidget {
  final EpgEntry entry;
  const EpgCard({super.key, required this.entry});
  @override
  Widget build(BuildContext context) {
    final h24 = Store.use24h;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('${fmtTime(entry.start, h24)} - ${fmtTime(entry.end, h24)}',
                style: const TextStyle(color: Colors.white60)),
            if (entry.isNow) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(4)),
                child: const Text('NOW', style: TextStyle(fontSize: 11)),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Text(entry.title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (entry.isNow) ...[
            const SizedBox(height: 6),
            LinearProgressIndicator(value: entry.progress),
          ],
          if (entry.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(entry.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70)),
          ],
        ]),
      ),
    );
  }
}
