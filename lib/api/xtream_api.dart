import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';
import 'source.dart';

String _s(dynamic v) => v == null ? '' : v.toString();

/// Xtream Codes player API (player_api.php).
class XtreamSource implements ContentSource {
  @override
  final Account account;
  XtreamSource(this.account);

  final Map<String, List<StreamItem>> _cache = {};

  Uri _uri(Map<String, String> extra) =>
      Uri.parse('${account.server}/player_api.php').replace(queryParameters: {
        'username': account.username,
        'password': account.password,
        ...extra,
      });

  Future<dynamic> _get(Map<String, String> extra) async {
    final res = await http
        .get(_uri(extra), headers: {'User-Agent': 'IPTVSmartersPro'})
        .timeout(AppConfig.timeout);
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    if (res.body.trim().isEmpty) return null;
    return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
  }

  /// Checks the login. Throws with a readable message if it fails.
  static Future<AccountInfo> login(Account a) async {
    final src = XtreamSource(a);
    final info = await src.accountInfo();
    if (info == null) throw Exception('Wrong username or password');
    if (info.status.toLowerCase() != 'active') {
      throw Exception('Account status: ${info.status}');
    }
    return info;
  }

  @override
  Future<AccountInfo?> accountInfo() async {
    final j = await _get({});
    if (j is! Map || j['user_info'] is! Map) return null;
    final u = j['user_info'] as Map;
    if (_s(u['auth']) == '0') return null;
    DateTime? exp;
    final e = int.tryParse(_s(u['exp_date']));
    if (e != null) exp = DateTime.fromMillisecondsSinceEpoch(e * 1000);
    return AccountInfo(_s(u['status']), exp, _s(u['max_connections']),
        _s(u['active_cons']));
  }

  String _action(ContentType t, String what) {
    switch (t) {
      case ContentType.live:
        return 'get_live_$what';
      case ContentType.movie:
        return 'get_vod_$what';
      case ContentType.series:
        return what == 'streams' ? 'get_series' : 'get_series_categories';
    }
  }

  @override
  Future<List<Category>> categories(ContentType type) async {
    final j = await _get({'action': _action(type, 'categories')});
    if (j is! List) return [];
    return j
        .whereType<Map>()
        .map((m) => Category(_s(m['category_id']), _s(m['category_name'])))
        .toList();
  }

  @override
  Future<List<StreamItem>> streams(ContentType type,
      {String? categoryId}) async {
    final key = '${type.name}:${categoryId ?? '*'}';
    if (_cache[key] != null) return _cache[key]!;
    final params = {'action': _action(type, 'streams')};
    if (categoryId != null && categoryId.isNotEmpty) {
      params['category_id'] = categoryId;
    }
    final j = await _get(params);
    if (j is! List) return [];
    final list = j.whereType<Map>().map((m) {
      switch (type) {
        case ContentType.live:
          return StreamItem(
            type: type,
            id: _s(m['stream_id']),
            name: _s(m['name']),
            icon: _s(m['stream_icon']),
            categoryId: _s(m['category_id']),
            epgId: _s(m['epg_channel_id']),
            hasArchive: _s(m['tv_archive']) == '1',
          );
        case ContentType.movie:
          return StreamItem(
            type: type,
            id: _s(m['stream_id']),
            name: _s(m['name']),
            icon: _s(m['stream_icon']),
            categoryId: _s(m['category_id']),
            extension: _s(m['container_extension']),
            rating: _s(m['rating']),
          );
        case ContentType.series:
          return StreamItem(
            type: type,
            id: _s(m['series_id']),
            name: _s(m['name']),
            icon: _s(m['cover']),
            categoryId: _s(m['category_id']),
            rating: _s(m['rating']),
          );
      }
    }).toList();
    _cache[key] = list;
    return list;
  }

  @override
  Future<MovieInfo> movieInfo(StreamItem item) async {
    final j = await _get({'action': 'get_vod_info', 'vod_id': item.id});
    final i = (j is Map && j['info'] is Map) ? j['info'] as Map : {};
    return _info(i, item.icon);
  }

  MovieInfo _info(Map i, String fallbackCover) {
    String backdrop = '';
    final b = i['backdrop_path'];
    if (b is List && b.isNotEmpty) backdrop = _s(b.first);
    if (b is String) backdrop = b;
    return MovieInfo(
      plot: _s(i['plot'] ?? i['description']),
      cast: _s(i['cast'] ?? i['actors']),
      director: _s(i['director']),
      genre: _s(i['genre']),
      releaseDate: _s(i['releasedate'] ?? i['releaseDate'] ?? i['release_date']),
      duration: _s(i['duration']),
      rating: _s(i['rating']),
      cover: _s(i['movie_image'] ?? i['cover']).isNotEmpty
          ? _s(i['movie_image'] ?? i['cover'])
          : fallbackCover,
      backdrop: backdrop,
      trailer: _s(i['youtube_trailer']),
    );
  }

  @override
  Future<SeriesInfo> seriesInfo(StreamItem item) async {
    final j = await _get({'action': 'get_series_info', 'series_id': item.id});
    final info = (j is Map && j['info'] is Map) ? j['info'] as Map : {};
    final seasons = <int, List<Episode>>{};
    final eps = j is Map ? j['episodes'] : null;
    void addEp(dynamic e) {
      if (e is! Map) return;
      final s = int.tryParse(_s(e['season'])) ?? 1;
      final inf = e['info'] is Map ? e['info'] as Map : {};
      seasons.putIfAbsent(s, () => []).add(Episode(
            id: _s(e['id']),
            title: _s(e['title']),
            season: s,
            number: int.tryParse(_s(e['episode_num'])) ?? 0,
            extension: _s(e['container_extension']),
            plot: _s(inf['plot']),
            image: _s(inf['movie_image']),
            duration: _s(inf['duration']),
          ));
    }

    if (eps is Map) {
      for (final list in eps.values) {
        if (list is List) list.forEach(addEp);
      }
    } else if (eps is List) {
      for (final list in eps) {
        if (list is List) list.forEach(addEp);
      }
    }
    for (final l in seasons.values) {
      l.sort((a, b) => a.number.compareTo(b.number));
    }
    return SeriesInfo(_info(info, item.icon), seasons);
  }

  @override
  Future<List<EpgEntry>> shortEpg(StreamItem channel) async {
    final j = await _get(
        {'action': 'get_short_epg', 'stream_id': channel.id, 'limit': '10'});
    final list = (j is Map && j['epg_listings'] is List)
        ? j['epg_listings'] as List
        : [];
    String dec(dynamic v) {
      try {
        return utf8.decode(base64.decode(_s(v)));
      } catch (_) {
        return _s(v);
      }
    }

    DateTime ts(dynamic v, dynamic fallback) {
      final n = int.tryParse(_s(v));
      if (n != null) return DateTime.fromMillisecondsSinceEpoch(n * 1000);
      return DateTime.tryParse(_s(fallback)) ?? DateTime.now();
    }

    return list.whereType<Map>().map((m) {
      return EpgEntry(
        dec(m['title']),
        dec(m['description']),
        ts(m['start_timestamp'], m['start']),
        ts(m['stop_timestamp'], m['end']),
      );
    }).toList();
  }

  @override
  String streamUrl(StreamItem item) {
    final base = account.server;
    final u = account.username;
    final p = account.password;
    switch (item.type) {
      case ContentType.live:
        return '$base/live/$u/$p/${item.id}.m3u8';
      case ContentType.movie:
        final ext = item.extension.isEmpty ? 'mp4' : item.extension;
        return '$base/movie/$u/$p/${item.id}.$ext';
      case ContentType.series:
        return '';
    }
  }

  @override
  String episodeUrl(Episode ep) {
    final ext = ep.extension.isEmpty ? 'mp4' : ep.extension;
    return '${account.server}/series/${account.username}/${account.password}/${ep.id}.$ext';
  }
}
