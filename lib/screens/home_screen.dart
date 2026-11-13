import 'package:material_ui/material_ui.dart';
import '../models.dart';
import 'content_tab.dart';
import 'settings_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;

  static const _titles = ['Live TV', 'Movies', 'Series', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final pages = const [
      ContentTab(type: ContentType.live, key: PageStorageKey('live')),
      ContentTab(type: ContentType.movie, key: PageStorageKey('movie')),
      ContentTab(type: ContentType.series, key: PageStorageKey('series')),
      SettingsScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_i]),
        actions: [
          if (_i < 3)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      SearchScreen(type: ContentType.values[_i]))),
            ),
        ],
      ),
      body: IndexedStack(index: _i, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (i) => setState(() => _i = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.live_tv), label: 'Live TV'),
          NavigationDestination(icon: Icon(Icons.movie), label: 'Movies'),
          NavigationDestination(
              icon: Icon(Icons.video_library), label: 'Series'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
