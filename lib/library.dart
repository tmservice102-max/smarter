// Local copy of the account's channels, movies and series, like the
// Android app's JSHelper: each section is downloaded once (tile on the home
// screen) and then read from the phone.
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/source.dart';
import 'models.dart';
import 'store.dart';

class Library {
  static Library? _current;
  static Library get I {
    final a = Store.currentAccount;
    if (a == null) throw StateError('No account');
    if (_current == null || _current!.account.id != a.id) _current = Library._(a);
    return _current!;
  }

  static void reset() => _current = null;

  final Account account;
  final ContentSource source;
  Library._(this.account) : source = ContentSource.forAccount(account);

  final Map<ContentType, List<Category>> _cats = {};
  final Map<ContentType, List<StreamItem>> _items = {};

  SharedPreferences get _p => Store.prefs;
  String _k(ContentType t, String what) => 'lib|${account.id}|${t.name}|$what';

  /// When this section was last downloaded, or null if never.
  DateTime? updated(ContentType t) {
    final ms = _p.getInt(_k(t, 'date'));
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool has(ContentType t) => updated(t) != null;
  int count(ContentType t) => _p.getInt(_k(t, 'count')) ?? 0;

  Future<File> _file(ContentType t) async {
    final dir = await getApplicationSupportDirectory();
    final safe = account.id.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_');
    final d = Directory('${dir.path}/library');
    if (!d.existsSync()) d.createSync(recursive: true);
    return File('${d.path}/${safe}_${t.name}.json');
  }

  /// Downloads categories and all items of one section and saves them.
  Future<int> download(ContentType t) async {
    final cats = await source.categories(t);
    final items = await source.streams(t);
    if (items.isEmpty && cats.isEmpty) {
      throw Exception('No data found');
    }
    _cats[t] = cats;
    _items[t] = items;
    final path = (await _file(t)).path;
    await Isolate.run(() => _writeLib(path, cats, items));
    await _p.setInt(_k(t, 'date'), DateTime.now().millisecondsSinceEpoch);
    await _p.setInt(_k(t, 'count'), items.length);
    return items.length;
  }

  /// Puts data in memory without the network (tests and screenshots).
  @visibleForTesting
  Future<void> debugSet(ContentType t, List<Category> cats, List<StreamItem> items) async {
    _cats[t] = cats;
    _items[t] = items;
    await _p.setInt(_k(t, 'date'), DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch);
    await _p.setInt(_k(t, 'count'), items.length);
  }

  Future<void> clear(ContentType t) async {
    _cats.remove(t);
    _items.remove(t);
    await _p.remove(_k(t, 'date'));
    await _p.remove(_k(t, 'count'));
    try {
      final f = await _file(t);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    for (final t in ContentType.values) {
      await clear(t);
    }
  }

  /// Reads a downloaded section into memory (downloads it if missing).
  Future<void> load(ContentType t) async {
    if (_items[t] != null) return;
    final f = await _file(t);
    if (!has(t) || !f.existsSync()) {
      await download(t);
      return;
    }
    // Read in the background: a big section (100k+ movies) would freeze the UI.
    final path = f.path;
    final (cats, items) = await Isolate.run(() => _readLib(path));
    _cats[t] = cats;
    _items[t] = items;
  }

  List<Category> categories(ContentType t) {
    final list = _cats[t] ?? const [];
    // Categories that have items but are not in the list (M3U groups).
    return list;
  }

  List<StreamItem> all(ContentType t) => _items[t] ?? const [];

  /// Special category ids used by the Android app.
  static const fav = '01', recent = '02', recentlyAdded = '03', ai = '04';

  /// "Filter" dialog choice: true reverses the list (Android getIs*Order).
  bool reversed(ContentType t) => _p.getBool('order|${t.name}') ?? false;
  Future<void> setReversed(ContentType t, bool v) => _p.setBool('order|${t.name}', v);

  List<StreamItem> items(ContentType t, String catId) {
    final all = this.all(t);
    List<StreamItem> out;
    switch (catId) {
      case fav:
        return Store.favorites(t);
      case recent:
        return Store.recent(t);
      case recentlyAdded:
        final l = [...all]
          ..sort((a, b) {
            final ia = int.tryParse(a.id), ib = int.tryParse(b.id);
            if (ia != null && ib != null) return ib.compareTo(ia);
            return b.added.compareTo(a.added);
          });
        out = l.take(50).toList();
        break;
      case ai:
        double r(StreamItem i) => double.tryParse(i.rating) ?? 0;
        final seen = <String>{};
        out = [];
        for (final i in [
          ...Store.recent(t),
          ...Store.favorites(t),
          ...([...all]..sort((a, b) => r(b).compareTo(r(a)))),
        ]) {
          if (seen.add(i.id)) out.add(i);
          if (out.length >= 50) break;
        }
        return out;
      case '':
      case '*':
        out = all;
        break;
      default:
        out = all.where((i) => i.categoryId == catId).toList();
    }
    return reversed(t) ? out.reversed.toList() : out;
  }

  int countIn(ContentType t, String catId) => items(t, catId).length;

  List<StreamItem> search(ContentType t, String text) {
    final q = text.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return all(t).where((i) => i.name.toLowerCase().contains(q)).toList();
  }
}

void _writeLib(String path, List<Category> cats, List<StreamItem> items) {
  File(path).writeAsStringSync(
    jsonEncode({
      'cats': [
        for (final c in cats) {'id': c.id, 'n': c.name},
      ],
      'items': [for (final i in items) i.toJson()],
    }),
  );
}

(List<Category>, List<StreamItem>) _readLib(String path) {
  final j = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  return (
    [for (final c in (j['cats'] as List? ?? const [])) Category('${c['id']}', '${c['n']}')],
    [for (final i in (j['items'] as List? ?? const [])) StreamItem.fromJson(Map<String, dynamic>.from(i as Map))],
  );
}

/// "3 secs ago" style text used on the home tiles (FormatUtils.calculateTimeSpan).
String timeSpan(DateTime? d) {
  if (d == null) return '';
  final s = DateTime.now().difference(d).inSeconds;
  if (s < 60) return '$s secs ago';
  final m = s ~/ 60;
  if (m < 60) return '$m min ago';
  final h = m ~/ 60;
  if (h < 24) return '$h hours ago';
  final days = h ~/ 24;
  return '$days days ago';
}

/// 12345 -> "12.3k" like FormatUtils.format.
String shortCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
  return '${(n / 1000000).toStringAsFixed(1)}M';
}
