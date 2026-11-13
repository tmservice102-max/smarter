// Catch up (CatchUpActivity -> CatchUpLiveActivity -> CatchUpEpgActivity).
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../session.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'epg_categories_page.dart';
import 'player_vod_page.dart';

/// Live categories that have channels with recordings.
class CatchUpPage extends StatelessWidget {
  const CatchUpPage({super.key});
  @override
  Widget build(BuildContext context) => const EpgCategoriesPage(catchUp: true);
}

/// Past programs of one channel, grouped by day (tabs on top).
class CatchUpEpgPage extends StatefulWidget {
  final StreamItem channel;
  const CatchUpEpgPage({super.key, required this.channel});
  @override
  State<CatchUpEpgPage> createState() => _CatchUpEpgPageState();
}

class _CatchUpEpgPageState extends State<CatchUpEpgPage> {
  List<EpgEntry>? _all;
  String _day = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = await Session.src.fullEpg(widget.channel);
      final past = l.where((e) => e.isPast && (e.hasArchive || widget.channel.hasArchive)).toList();
      if (!mounted) return;
      setState(() {
        _all = past;
        final days = _days(past);
        _day = days.isEmpty ? '' : days.last;
      });
    } catch (_) {
      if (mounted) setState(() => _all = []);
    }
  }

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<String> _days(List<EpgEntry> l) => l.map((e) => _key(e.start)).toSet().toList()..sort();

  String _label(String key) {
    final d = DateTime.parse(key);
    final today = DateTime.now();
    if (_key(today) == key) return 'Today';
    if (_key(today.subtract(const Duration(days: 1))) == key) return 'Yesterday';
    const w = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${w[d.weekday - 1]} ${d.day}/${d.month}';
  }

  void _play(EpgEntry e) {
    final url = Session.src.catchupUrl(widget.channel, e);
    if (url.isEmpty) {
      toast(context, S.err_no_data_found, error: true);
      return;
    }
    go(context, VodPlayerPage(title: '${widget.channel.name} - ${e.title}', url: url));
  }

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final days = all == null ? <String>[] : _days(all);
    final list = all?.where((e) => _key(e.start) == _day).toList().reversed.toList() ?? [];
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Column(
          children: [
            PageTop(title: widget.channel.name, icon: 'list_channels'),
            if (days.isNotEmpty)
              SizedBox(
                height: 30.sdp,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  children: [
                    for (final d in days.reversed)
                      Padding(
                        padding: EdgeInsets.only(left: 5.sdp),
                        child: Tap(
                          onTap: () => setState(() => _day = d),
                          builder: (f) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.sdp),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0x12FFFFFF),
                              borderRadius: BorderRadius.circular(1.sdp),
                              border: Border.all(color: f ? const Color(0xFFFFAB00) : C.border, width: 1.sdp),
                            ),
                            child: T(_label(d), size: 12, color: d == _day ? C.select : Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            SizedBox(height: 5.sdp),
            Expanded(
              child: all == null
                  ? const Loader()
                  : list.isEmpty
                  ? Empty(S.err_no_data_found)
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => EpgRow(entry: list[i], onTap: () => _play(list[i])),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
