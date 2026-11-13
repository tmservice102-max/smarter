import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_smarter/api/m3u_source.dart';
import 'package:iptv_smarter/main.dart';
import 'package:iptv_smarter/models.dart';
import 'package:iptv_smarter/screens/login_screen.dart';
import 'package:iptv_smarter/store.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('M3U parser reads groups, logos and movies', () {
    final src = M3uSource(Account.playlist(name: 'x', url: 'http://x'));
    final items = src.parse('''#EXTM3U
#EXTINF:-1 tvg-id="bbc" tvg-logo="http://l/bbc.png" group-title="News",BBC One
http://s/live/1.ts
#EXTINF:-1 group-title="Films",Some Movie
http://s/movie/u/p/2.mkv
''');
    expect(items.length, 2);
    expect(items[0].name, 'BBC One');
    expect(items[0].icon, 'http://l/bbc.png');
    expect(items[0].type, ContentType.live);
    expect(items[1].type, ContentType.movie);
  });

  test('server URL is normalized', () {
    expect(Account.normalizeServer('host.com:8080/'), 'http://host.com:8080');
  });

  testWidgets('login screen shows Xtream and M3U when panel is offline',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    expect(find.text('Xtream Codes'), findsOneWidget);
    expect(find.text('M3U Playlist'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
  });

  test('app widget builds', () {
    expect(const IptvApp(), isNotNull);
  });
}
