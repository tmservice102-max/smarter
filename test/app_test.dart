import 'package:flutter_test/flutter_test.dart';
import 'package:iptv_smarter/api/m3u_source.dart';
import 'package:iptv_smarter/main.dart';
import 'package:iptv_smarter/models.dart';
import 'package:iptv_smarter/library.dart';
import 'package:iptv_smarter/pages/details_kit.dart';
import 'package:iptv_smarter/pages/select_player_page.dart';
import 'package:iptv_smarter/parental.dart';
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

  testWidgets('login chooser shows Xtream, M3U and list users when panel is offline', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Store.init();
    // Landscape phone, like the Android app.
    tester.view.physicalSize = const Size(2532, 1170);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: SelectPlayerPage()));
    await tester.pump();
    expect(find.text('XTREAM CODES'), findsOneWidget);
    expect(find.text('M3U PLAYLIST'), findsOneWidget);
    expect(find.text('LIST USERS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('helpers match the Android formatting', () {
    expect(shortCount(950), '950');
    expect(shortCount(12345), '12.3K');
    expect(durationText('01:45:00'), '1h 45m');
    expect(durationText('95'), '1h 35m');
    expect(Parental.isAdult('Adults 18+'), isTrue);
    expect(Parental.isAdult('Sports'), isFalse);
  });

  test('app widget builds', () {
    expect(const IptvApp(), isNotNull);
  });
}
