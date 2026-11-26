// Walks through the app like a first-time user, for the App Review screen
// recording: open app, choose Xtream Codes, sign in with the built-in demo
// account, play a live channel, open a movie and play it, open a series.
//
// Run on a simulator (Codemagic workflow ios-demo-video):
//   flutter test integration_test/demo_flow_test.dart --dart-define=NO_ADS=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:iptv_smarter/main.dart' as app;
import 'package:iptv_smarter/ui/strings.dart';
import 'package:iptv_smarter/pages/list_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester t, double seconds) async {
    final end = DateTime.now().add(Duration(milliseconds: (seconds * 1000).round()));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> waitFor(WidgetTester t, Finder f, {double timeout = 40}) async {
    final end = DateTime.now().add(Duration(seconds: timeout.round()));
    while (DateTime.now().isBefore(end)) {
      await t.pump(const Duration(milliseconds: 200));
      if (f.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Not found on screen: $f');
  }

  Future<void> tap(WidgetTester t, Finder f) async {
    await waitFor(t, f);
    await t.tap(f.first, warnIfMissed: false);
    await wait(t, 1.5);
  }

  /// Taps [f] until [then] shows up (pages can ignore taps while they animate).
  Future<void> tapUntil(WidgetTester t, Finder f, Finder then, {int tries = 8}) async {
    for (var i = 0; i < tries; i++) {
      await waitFor(t, f);
      await wait(t, 1.5);
      if (then.evaluate().isNotEmpty) return;
      final hit = find.ancestor(of: f.first, matching: find.byType(GestureDetector));
      await t.tap(hit.evaluate().isNotEmpty ? hit.first : f.first, warnIfMissed: false);
      await wait(t, 3);
      if (then.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Tapping $f never opened $then');
  }

  Future<void> back(WidgetTester t) async {
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await wait(t, 2);
  }

  Future<void> typeInto(WidgetTester t, int index, String text) async {
    final f = find.byType(TextField).at(index);
    await t.tap(f, warnIfMissed: false);
    await wait(t, 0.4);
    await t.enterText(f, text);
    await wait(t, 0.8);
  }

  testWidgets('demo walkthrough', (t) async {
    app.main();
    await wait(t, 4);

    // Login type chooser (tap again if the page was still animating in).
    await tapUntil(t, find.text(S.login_with_xtream_codes), find.byType(TextField));
    await typeInto(t, 0, 'Demo');
    await typeInto(t, 1, 'test');
    await typeInto(t, 2, 'test');
    await typeInto(t, 3, 'http://test.test');
    FocusManager.instance.primaryFocus?.unfocus();
    await wait(t, 1);
    await tap(t, find.text(S.login));

    // Home: sections download automatically after login.
    await waitFor(t, find.text(S.live_tv_home), timeout: 60);
    await wait(t, 6);

    // Live TV: play a channel for a while.
    await tap(t, find.text(S.live_tv_home));
    await waitFor(t, find.byType(PosterCard));
    await wait(t, 2);
    await tap(t, find.byType(PosterCard));
    await wait(t, 12);
    await back(t);
    await back(t);

    // Movies: open details, play.
    await tap(t, find.text(S.movies_home));
    await waitFor(t, find.byType(PosterCard));
    await wait(t, 2);
    await tap(t, find.byType(PosterCard));
    await wait(t, 3);
    await tap(t, find.text(S.play));
    await wait(t, 12);
    await back(t);
    await back(t);
    await back(t);

    // Series: open the demo series.
    await tap(t, find.text(S.series_home));
    await waitFor(t, find.byType(PosterCard));
    await wait(t, 2);
    await tap(t, find.byType(PosterCard));
    await wait(t, 5);
    await back(t);
    await back(t);
    await wait(t, 3);
  });
}
