import 'package:material_ui/material_ui.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'details_screen.dart';
import 'epg_screen.dart';
import 'player_screen.dart';

/// Opens the right screen for an item (player for live, details otherwise).
Future<void> openItem(BuildContext context, StreamItem item,
    {List<StreamItem> list = const []}) async {
  if (item.type == ContentType.live) {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerScreen.live(channels: list.isEmpty ? [item] : list, start: item),
    ));
  } else {
    await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => DetailsScreen(item: item)));
  }
}

class ItemsScreen extends StatefulWidget {
  final ContentType type;
  final String title;
  final String? categoryId;
  final String? special; // fav, recent
  const ItemsScreen(
      {super.key,
      required this.type,
      required this.title,
      this.categoryId,
      this.special});
  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  int _reload = 0;
  String _sort = 'default';

  Future<List<StreamItem>> _load() async {
    if (widget.special == 'fav') return Store.favorites(widget.type);
    if (widget.special == 'recent') return Store.recent(widget.type);
    return Session.src.streams(widget.type, categoryId: widget.categoryId);
  }

  List<StreamItem> _sorted(List<StreamItem> items) {
    final l = [...items];
    if (_sort == 'az') {
      l.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sort == 'za') {
      l.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    } else if (_sort == 'rating') {
      l.sort((a, b) => (double.tryParse(b.rating) ?? 0)
          .compareTo(double.tryParse(a.rating) ?? 0));
    }
    return l;
  }

  Future<void> _fav(StreamItem it) async {
    final added = await Store.toggleFavorite(it);
    if (!mounted) return;
    toast(context, added ? 'Added to favorites' : 'Removed from favorites');
    setState(() {
      if (widget.special == 'fav') _reload++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => setState(() => _sort = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'default', child: Text('Default')),
              const PopupMenuItem(value: 'az', child: Text('A to Z')),
              const PopupMenuItem(value: 'za', child: Text('Z to A')),
              if (widget.type != ContentType.live)
                const PopupMenuItem(value: 'rating', child: Text('Top rated')),
            ],
          ),
          if (widget.special == 'recent')
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () async {
                await Store.clearRecent();
                setState(() => _reload++);
              },
            ),
        ],
      ),
      body: AsyncView<List<StreamItem>>(
        key: ValueKey('$_reload'),
        load: _load,
        builder: (context, raw) {
          final items = _sorted(raw);
          if (items.isEmpty) return const EmptyView('Nothing here yet');
          if (widget.type == ContentType.live) {
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) => _ChannelTile(
                item: items[i],
                onTap: () async {
                  await openItem(context, items[i], list: items);
                  setState(() {});
                },
                onFav: () => _fav(items[i]),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              childAspectRatio: 0.58,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _PosterTile(
              item: items[i],
              onTap: () async {
                await openItem(context, items[i]);
                setState(() {});
              },
              onLongPress: () => _fav(items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final StreamItem item;
  final VoidCallback onTap;
  final VoidCallback onFav;
  const _ChannelTile(
      {required this.item, required this.onTap, required this.onFav});

  @override
  Widget build(BuildContext context) {
    final fav = Store.isFavorite(item);
    return ListTile(
      leading: SizedBox(
        width: 56,
        height: 40,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: NetImage(item.icon, fit: BoxFit.contain),
        ),
      ),
      title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      onLongPress: onFav,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: 'TV guide',
          icon: const Icon(Icons.event_note_outlined),
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EpgScreen(channel: item))),
        ),
        IconButton(
          icon: Icon(fav ? Icons.favorite : Icons.favorite_border,
              color: fav ? Colors.redAccent : null),
          onPressed: onFav,
        ),
      ]),
    );
  }
}

class _PosterTile extends StatelessWidget {
  final StreamItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _PosterTile(
      {required this.item, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final fav = Store.isFavorite(item);
    final rating = double.tryParse(item.rating) ?? 0;
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(fit: StackFit.expand, children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: NetImage(item.icon, fallback: Icons.movie),
            ),
            if (rating > 0)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11)),
                  ]),
                ),
              ),
            if (fav)
              const Positioned(
                right: 6,
                top: 6,
                child: Icon(Icons.favorite, color: Colors.redAccent, size: 18),
              ),
          ]),
        ),
        const SizedBox(height: 6),
        Text(item.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
