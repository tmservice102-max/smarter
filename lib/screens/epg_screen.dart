import 'package:material_ui/material_ui.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

/// TV guide for one channel: past days (catch-up) and upcoming programs.
class EpgScreen extends StatelessWidget {
  final StreamItem channel;
  const EpgScreen({super.key, required this.channel});

  Future<List<EpgEntry>> _load() async {
    var list = await Session.src.fullEpg(channel);
    if (list.isEmpty) list = await Session.src.shortEpg(channel);
    return list;
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == -1) return 'Yesterday';
    if (diff == 1) return 'Tomorrow';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[d.weekday - 1]} ${d.day}/${d.month}';
  }

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<EpgEntry>>(
      load: _load,
      builder: (context, list) {
        final days = <DateTime, List<EpgEntry>>{};
        for (final e in list) {
          final k = DateTime(e.start.year, e.start.month, e.start.day);
          days.putIfAbsent(k, () => []).add(e);
        }
        final keys = days.keys.toList()..sort();
        final now = DateTime.now();
        var initial = keys.indexWhere((k) =>
            k.year == now.year && k.month == now.month && k.day == now.day);
        if (initial < 0) initial = 0;
        return DefaultTabController(
          length: keys.isEmpty ? 1 : keys.length,
          initialIndex: keys.isEmpty ? 0 : initial,
          child: Scaffold(
            appBar: AppBar(
              title: Text(channel.name),
              bottom: keys.length > 1
                  ? TabBar(
                      isScrollable: true,
                      tabs: keys.map((k) => Tab(text: _dayLabel(k))).toList())
                  : null,
            ),
            floatingActionButton: FloatingActionButton.extended(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Watch live'),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      PlayerScreen.live(channels: [channel], start: channel))),
            ),
            body: keys.isEmpty
                ? const EmptyView('No guide data for this channel',
                    icon: Icons.event_busy)
                : TabBarView(
                    children: keys
                        .map((k) => _DayList(channel: channel, items: days[k]!))
                        .toList(),
                  ),
          ),
        );
      },
    );
  }
}

class _DayList extends StatelessWidget {
  final StreamItem channel;
  final List<EpgEntry> items;
  const _DayList({required this.channel, required this.items});

  @override
  Widget build(BuildContext context) {
    final nowIndex = items.indexWhere((e) => e.isNow);
    return ListView.separated(
      controller: ScrollController(
          initialScrollOffset: nowIndex > 2 ? (nowIndex - 1) * 96.0 : 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final e = items[i];
        final url = e.isPast ? Session.src.catchupUrl(channel, e) : '';
        return EpgCard(
          entry: e,
          onPlay: url.isEmpty
              ? null
              : () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlayerScreen.vod(
                        title: '${channel.name} • ${e.title}',
                        url: url,
                        resumeKey: ''),
                  )),
        );
      },
    );
  }
}

class EpgCard extends StatelessWidget {
  final EpgEntry entry;
  final VoidCallback? onPlay;
  const EpgCard({super.key, required this.entry, this.onPlay});
  @override
  Widget build(BuildContext context) {
    final h24 = Store.use24h;
    final past = entry.isPast;
    return Card(
      child: InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                          '${fmtTime(entry.start, h24)} - ${fmtTime(entry.end, h24)}',
                          style: TextStyle(
                              color: past ? Colors.white38 : Colors.white60)),
                      if (entry.isNow) ...[
                        const SizedBox(width: 8),
                        _badge('NOW', Colors.redAccent),
                      ],
                      if (onPlay != null) ...[
                        const SizedBox(width: 8),
                        _badge('CATCH-UP', const Color(0xFF1E88E5)),
                      ],
                    ]),
                    const SizedBox(height: 4),
                    Text(entry.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: past && onPlay == null
                                ? Colors.white54
                                : null)),
                    if (entry.isNow) ...[
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: entry.progress),
                    ],
                    if (entry.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(entry.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ]),
            ),
            if (onPlay != null)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.play_circle_fill, size: 36),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _badge(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration:
            BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
        child: Text(t, style: const TextStyle(fontSize: 11)),
      );
}
