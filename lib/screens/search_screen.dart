import 'dart:async';
import 'package:material_ui/material_ui.dart';
import '../models.dart';
import '../session.dart';
import '../widgets/common.dart';
import 'items_screen.dart';

class SearchScreen extends StatefulWidget {
  final ContentType type;
  const SearchScreen({super.key, required this.type});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<StreamItem>? _all;
  List<StreamItem> _results = [];
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final all = await Session.src.streams(widget.type, categoryId: '');
      if (mounted) setState(() => _all = all);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  void _search(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final s = q.trim().toLowerCase();
      setState(() => _results = s.length < 2 || _all == null
          ? []
          : _all!.where((x) => x.name.toLowerCase().contains(s)).take(200).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search ${widget.type == ContentType.live ? 'channels' : widget.type == ContentType.movie ? 'movies' : 'series'}',
            filled: false,
            border: InputBorder.none,
          ),
          onChanged: _search,
        ),
      ),
      body: _error != null
          ? ErrorRetry(message: _error!, onRetry: () {
              setState(() => _error = null);
              _loadAll();
            })
          : _all == null
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty
                  ? const EmptyView('Type at least 2 letters', icon: Icons.search)
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (_, i) {
                        final it = _results[i];
                        return ListTile(
                          leading: SizedBox(
                            width: 48,
                            height: 48,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: NetImage(it.icon,
                                  fit: widget.type == ContentType.live
                                      ? BoxFit.contain
                                      : BoxFit.cover),
                            ),
                          ),
                          title: Text(it.name),
                          onTap: () => openItem(context, it,
                              list: widget.type == ContentType.live ? _results : const []),
                        );
                      },
                    ),
    );
  }
}
