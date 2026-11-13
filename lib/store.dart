import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Saves accounts, favorites, recently watched and settings on the phone.
class Store {
  static late SharedPreferences _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();
  static SharedPreferences get prefs => _p;

  // Accounts
  static List<Account> get accounts {
    final raw = _p.getStringList('accounts') ?? [];
    return raw.map((s) => Account.fromJson(Map<String, dynamic>.from(jsonDecode(s)))).toList();
  }

  static Future<void> saveAccount(Account a) async {
    final list = accounts.where((x) => x.id != a.id).toList()..insert(0, a);
    await _p.setStringList('accounts', list.map((x) => jsonEncode(x.toJson())).toList());
  }

  static Future<void> removeAccount(Account a) async {
    final list = accounts.where((x) => x.id != a.id).toList();
    await _p.setStringList('accounts', list.map((x) => jsonEncode(x.toJson())).toList());
    if (currentAccountId == a.id) await _p.remove('current');
  }

  static String? get currentAccountId => _p.getString('current');
  static Future<void> setCurrent(Account? a) async => a == null ? _p.remove('current') : _p.setString('current', a.id);

  static Account? get currentAccount {
    final id = currentAccountId;
    if (id == null) return null;
    for (final a in accounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  // Favorites and recent, stored per account
  static String _k(String what) => '$what|${currentAccountId ?? ''}';

  static List<StreamItem> _items(String what) => (_p.getStringList(_k(what)) ?? [])
      .map((s) => StreamItem.fromJson(Map<String, dynamic>.from(jsonDecode(s))))
      .toList();

  static Future<void> _setItems(String what, List<StreamItem> items) =>
      _p.setStringList(_k(what), items.map((x) => jsonEncode(x.toJson())).toList());

  static List<StreamItem> favorites(ContentType t) => _items('fav').where((x) => x.type == t).toList();

  static bool isFavorite(StreamItem it) => _items('fav').any((x) => x.key == it.key);

  static Future<bool> toggleFavorite(StreamItem it) async {
    final list = _items('fav');
    final exists = list.any((x) => x.key == it.key);
    if (exists) {
      list.removeWhere((x) => x.key == it.key);
    } else {
      list.insert(0, it);
    }
    await _setItems('fav', list);
    return !exists;
  }

  static List<StreamItem> recent(ContentType t) => _items('recent').where((x) => x.type == t).toList();

  /// Keeps the newest [liveLimit] channels and [movieLimit] movies / series
  /// (General settings "Recently Added Limit").
  static Future<void> addRecent(StreamItem it) async {
    final list = _items('recent')..removeWhere((x) => x.key == it.key);
    list.insert(0, it);
    final count = <ContentType, int>{};
    final kept = <StreamItem>[];
    for (final x in list) {
      final n = (count[x.type] ?? 0) + 1;
      count[x.type] = n;
      if (n <= (x.type == ContentType.live ? liveLimit : movieLimit)) kept.add(x);
    }
    await _setItems('recent', kept);
  }

  static Future<void> clearRecent() => _p.remove(_k('recent'));

  /// Clears the watch history of one type; returns false if it was empty.
  static Future<bool> clearRecentOf(ContentType t) async {
    final list = _items('recent');
    if (!list.any((x) => x.type == t)) return false;
    await _setItems('recent', list.where((x) => x.type != t).toList());
    return true;
  }

  /// Forgets saved positions whose key starts with [prefix] (movie:, episode:).
  static Future<bool> clearResume(String prefix) async {
    final keys = _p.getKeys().where((k) => k.startsWith('pos|$prefix')).toList();
    for (final k in keys) {
      await _p.remove(k);
    }
    return keys.isNotEmpty;
  }

  // Resume position for movies/episodes (seconds)
  static int resumeAt(String key) => _p.getInt('pos|$key') ?? 0;
  static Future<void> setResume(String key, int seconds) => _p.setInt('pos|$key', seconds);

  // Settings
  static bool get use24h => _p.getBool('use24h') ?? false;
  static set use24h(bool v) => _p.setBool('use24h', v);

  // Defaults as in the Android SPHelper.
  static bool get autoplayNext => _p.getBool('autoplayNext') ?? false;
  static set autoplayNext(bool v) => _p.setBool('autoplayNext', v);

  /// Live stream format: 0 default, 1 MPEGTS (.ts), 2 HLS (.m3u8).
  /// Multi-screen: ask for the layout each time (is_screen) and the saved
  /// layout 1..5 (screen_data).
  static bool get multiScreenPopup => _p.getBool('is_screen') ?? true;
  static set multiScreenPopup(bool v) => _p.setBool('is_screen', v);
  static int get multiScreenLayout => _p.getInt('screen_data') ?? 5;
  static set multiScreenLayout(int v) => _p.setInt('screen_data', v);

  /// Automation: which sections the start-up sync refreshes.
  static bool get updateLive => _p.getBool('auto_update_live') ?? true;
  static set updateLive(bool v) => _p.setBool('auto_update_live', v);
  static bool get updateMovies => _p.getBool('auto_update_movies') ?? true;
  static set updateMovies(bool v) => _p.setBool('auto_update_movies', v);
  static bool get updateSeries => _p.getBool('auto_update_series') ?? true;
  static set updateSeries(bool v) => _p.setBool('auto_update_series', v);

  /// General: recently-watched list sizes and the player User-Agent.
  static int get liveLimit => _p.getInt('live_limit') ?? 20;
  static set liveLimit(int v) => _p.setInt('live_limit', v);
  static int get movieLimit => _p.getInt('movie_limit') ?? 20;
  static set movieLimit(int v) => _p.setInt('movie_limit', v);
  static String get agentName => _p.getString('agent_name') ?? '';
  static set agentName(String v) => _p.setString('agent_name', v);
  static bool get splashAudio => _p.getBool('splash_audio') ?? true;
  static set splashAudio(bool v) => _p.setBool('splash_audio', v);

  static int get streamFormat => _p.getInt('stream_format') ?? 0;
  static set streamFormat(int v) => _p.setInt('stream_format', v);

  /// Hours between automatic data updates (0 = off).
  static int get autoUpdateHours => _p.getInt('auto_update') ?? 5;
  static set autoUpdateHours(int v) => _p.setInt('auto_update', v);

  static bool get showDownload => _p.getBool('ui_download') ?? true;
  static set showDownload(bool v) => _p.setBool('ui_download', v);

  static bool get showCardTitle => _p.getBool('ui_card_title') ?? true;
  static set showCardTitle(bool v) => _p.setBool('ui_card_title', v);

  static bool get hardwareDecoding => _p.getBool('hw_decoding') ?? true;
  static set hardwareDecoding(bool v) => _p.setBool('hw_decoding', v);

  static String get parentalPin => _p.getString('pin') ?? '';
  static set parentalPin(String v) => _p.setString('pin', v);

  static List<String> get hiddenCategories => _p.getStringList(_k('hidden')) ?? [];
  static Future<void> setHiddenCategories(List<String> ids) => _p.setStringList(_k('hidden'), ids);

  // Device id used for panel "device id" login
  static String get deviceId {
    var id = _p.getString('device_id');
    if (id == null) {
      final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
      id = now.substring(now.length - 8).toUpperCase().padLeft(8, '0');
      id = '${id.substring(0, 4)}-${id.substring(4)}';
      _p.setString('device_id', id);
    }
    return id;
  }
}
