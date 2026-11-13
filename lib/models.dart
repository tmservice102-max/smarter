// Data models shared across the app.

String _s(dynamic v) => v == null ? '' : v.toString();
bool _b(dynamic v) => v == true || v == 1 || v == '1' || v == 'true';

class Dns {
  final String title;
  final String base;
  Dns(this.title, this.base);
}

class AppDetails {
  final Map<String, dynamic> raw;
  final List<Dns> xuiDns;
  final List<Dns> streamDns;
  final List<Map<String, dynamic>> notifications;
  AppDetails(this.raw, this.xuiDns, this.streamDns, this.notifications);

  Map<String, dynamic> get details {
    final d = raw['details'];
    if (d is List && d.isNotEmpty) return Map<String, dynamic>.from(d.first);
    return {};
  }

  bool flag(String key) => _b(details[key]);
  String get(String key) => _s(details[key]);

  bool get maintenance => flag('is_maintenance');
  bool get allowXtream => flag('is_select_xui') || flag('is_select_stream');
  bool get allowPlaylist => flag('is_select_playlist');
  bool get allowActivation => flag('is_select_activation_code');
  bool get allowDeviceId => flag('is_select_device_id');
  bool get xuiDnsOnly => flag('is_xui_dns');
  String get tmdbKey => get('tmdb_key');

  factory AppDetails.fromJson(Map<String, dynamic> j) {
    List<Dns> dns(String k) => (j[k] is List ? j[k] as List : [])
        .whereType<Map>()
        .map((m) => Dns(_s(m['dns_title']), _s(m['dns_base'])))
        .toList();
    final notes = (j['notification_data'] is List
            ? j['notification_data'] as List
            : [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
    return AppDetails(j, dns('xui_dns'), dns('stream_dns'), notes);
  }
}

/// A login stored in the panel (activation code / device id).
class PanelUser {
  final String type; // xui, stream, playlist
  final String userName;
  final String password;
  final String dnsBase;
  PanelUser(this.type, this.userName, this.password, this.dnsBase);
  factory PanelUser.fromJson(Map<String, dynamic> j) => PanelUser(
      _s(j['user_type']),
      _s(j['user_name']),
      _s(j['user_password']),
      _s(j['dns_base']));

  Account toAccount() => type == 'playlist'
      ? Account.playlist(name: userName.isEmpty ? 'Playlist' : userName, url: dnsBase)
      : Account.xtream(
          name: userName, server: dnsBase, username: userName, password: password);
}

enum AccountType { xtream, playlist }

/// A saved login on this phone.
class Account {
  final AccountType type;
  final String name;
  final String server; // xtream base url, or m3u url
  final String username;
  final String password;

  Account._(this.type, this.name, this.server, this.username, this.password);
  factory Account.xtream(
          {required String name,
          required String server,
          required String username,
          required String password}) =>
      Account._(AccountType.xtream, name, normalizeServer(server), username,
          password);
  factory Account.playlist({required String name, required String url}) =>
      Account._(AccountType.playlist, name, url.trim(), '', '');

  String get id => '${type.name}|$server|$username';

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'name': name,
        'server': server,
        'username': username,
        'password': password,
      };
  factory Account.fromJson(Map<String, dynamic> j) => Account._(
      j['type'] == 'playlist' ? AccountType.playlist : AccountType.xtream,
      _s(j['name']),
      _s(j['server']),
      _s(j['username']),
      _s(j['password']));

  static String normalizeServer(String s) {
    var v = s.trim();
    if (v.isEmpty) return v;
    if (!v.startsWith('http://') && !v.startsWith('https://')) v = 'http://$v';
    while (v.endsWith('/')) {
      v = v.substring(0, v.length - 1);
    }
    return v;
  }
}

enum ContentType { live, movie, series }

class Category {
  final String id;
  final String name;
  Category(this.id, this.name);
}

/// A channel, movie or series in a list.
class StreamItem {
  final ContentType type;
  final String id;
  final String name;
  final String icon;
  final String categoryId;
  final String extension;
  final String rating;
  final String epgId;
  final String directUrl; // for M3U entries
  final bool hasArchive;

  StreamItem({
    required this.type,
    required this.id,
    required this.name,
    this.icon = '',
    this.categoryId = '',
    this.extension = '',
    this.rating = '',
    this.epgId = '',
    this.directUrl = '',
    this.hasArchive = false,
  });

  String get key => '${type.name}:$id';

  Map<String, dynamic> toJson() => {
        't': type.name,
        'id': id,
        'n': name,
        'i': icon,
        'c': categoryId,
        'x': extension,
        'r': rating,
        'e': epgId,
        'u': directUrl,
      };
  factory StreamItem.fromJson(Map<String, dynamic> j) => StreamItem(
        type: ContentType.values.firstWhere((t) => t.name == j['t'],
            orElse: () => ContentType.live),
        id: _s(j['id']),
        name: _s(j['n']),
        icon: _s(j['i']),
        categoryId: _s(j['c']),
        extension: _s(j['x']),
        rating: _s(j['r']),
        epgId: _s(j['e']),
        directUrl: _s(j['u']),
      );
}

class MovieInfo {
  final String plot;
  final String cast;
  final String director;
  final String genre;
  final String releaseDate;
  final String duration;
  final String rating;
  final String cover;
  final String backdrop;
  final String trailer;
  MovieInfo({
    this.plot = '',
    this.cast = '',
    this.director = '',
    this.genre = '',
    this.releaseDate = '',
    this.duration = '',
    this.rating = '',
    this.cover = '',
    this.backdrop = '',
    this.trailer = '',
  });
}

class Episode {
  final String id;
  final String title;
  final int season;
  final int number;
  final String extension;
  final String plot;
  final String image;
  final String duration;
  Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.number,
    required this.extension,
    this.plot = '',
    this.image = '',
    this.duration = '',
  });
}

class SeriesInfo {
  final MovieInfo info;
  final Map<int, List<Episode>> seasons;
  SeriesInfo(this.info, this.seasons);
}

class EpgEntry {
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  EpgEntry(this.title, this.description, this.start, this.end);
  bool get isNow {
    final n = DateTime.now();
    return n.isAfter(start) && n.isBefore(end);
  }

  double get progress {
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    return (DateTime.now().difference(start).inSeconds / total).clamp(0, 1);
  }
}

class AccountInfo {
  final String status;
  final DateTime? expires;
  final String maxConnections;
  final String activeConnections;
  AccountInfo(
      this.status, this.expires, this.maxConnections, this.activeConnections);
}
