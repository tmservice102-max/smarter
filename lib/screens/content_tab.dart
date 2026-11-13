import 'package:material_ui/material_ui.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'items_screen.dart';

/// Category list for live, movies or series.
class ContentTab extends StatefulWidget {
  final ContentType type;
  const ContentTab({super.key, required this.type});
  @override
  State<ContentTab> createState() => _ContentTabState();
}

class _ContentTabState extends State<ContentTab>
    with AutomaticKeepAliveClientMixin {
  int _reload = 0;

  @override
  bool get wantKeepAlive => true;

  void _openItems(String title, {String? categoryId, String? special}) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ItemsScreen(
          type: widget.type,
          title: title,
          categoryId: categoryId,
          special: special),
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AsyncView<List<Category>>(
      key: ValueKey(_reload),
      load: () => Session.src.categories(widget.type),
      builder: (context, cats) {
        final hidden = Store.hiddenCategories.toSet();
        final visible = cats.where((c) => !hidden.contains(c.id)).toList();
        final favCount = Store.favorites(widget.type).length;
        final recentCount = Store.recent(widget.type).length;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _reload++),
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _tile(Icons.apps, 'All', null, () => _openItems('All', categoryId: '')),
              _tile(Icons.favorite, 'Favorites', '$favCount',
                  () => _openItems('Favorites', special: 'fav')),
              _tile(Icons.history, 'Recently watched', '$recentCount',
                  () => _openItems('Recently watched', special: 'recent')),
              const Divider(height: 24),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: EmptyView('No categories'),
                ),
              ...visible.map((c) => _tile(Icons.folder_outlined, c.name, null,
                  () => _openItems(c.name, categoryId: c.id))),
            ],
          ),
        );
      },
    );
  }

  Widget _tile(IconData icon, String title, String? count, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: count == null
            ? const Icon(Icons.chevron_right)
            : Text(count, style: const TextStyle(color: Colors.white54)),
        onTap: onTap,
      ),
    );
  }
}
