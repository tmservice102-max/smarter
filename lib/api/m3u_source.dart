import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models.dart';
import 'source.dart';

/// M3U playlist source. Groups become categories.
class M3uSource implements ContentSource {
  @override
  final Account account;
  M3uSource(this.account);

  List<StreamItem>? _items;
  final Map<String, String> _groupIds = {};

  static Future<void> validate(Account a) async {
    final s = M3uSource(a);
    final items = await s._load();
    if (items.isEmpty) throw Exception('Playlist is empty or invalid');
  }

  Future<List<StreamItem>> _load() async {
    if (_items != null) return _items!;
    if (account.server.startsWith('file://') || account.server.startsWith('/')) {
      final path = account.server.replaceFirst('file://', '');
      final bytes = await File(path).readAsBytes();
      return _items = await _parseInBackground(bytes);
    }
    final res = await http
        .get(Uri.parse(account.server))
        .timeout(const Duration(seconds: 90));
    if (res.statusCode != 200) {
      throw Exception('Playlist error ${res.statusCode}');
    }
    return _items = await _parseInBackground(res.bodyBytes);
  }

  /// Big playlists are parsed off the UI thread so the screen doesn't freeze.
  Future<List<StreamItem>> _parseInBackground(Uint8List bytes) async {
    final (items, groups) = await Isolate.run(() {
      final p = M3uSource(account);
      final items = p.parse(utf8.decode(bytes, allowMalformed: true));
      return (items, p._groupIds);
    });
    _groupIds
      ..clear()
      ..addAll(groups);
    return items;
  }

  List<StreamItem> parse(String text) {
    final out = <StreamItem>[];
    final lines = const LineSplitter().convert(text);
    String? name, logo, group, tvgId;
    final attr = RegExp(r'([\w-]+)="([^"]*)"');
    var i = 0;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#EXTINF')) {
        final attrs = {
          for (final m in attr.allMatches(line)) m.group(1)!: m.group(2)!
        };
        final comma = line.lastIndexOf(',');
        name = comma >= 0 ? line.substring(comma + 1).trim() : 'Channel';
        if (name.isEmpty) name = attrs['tvg-name'] ?? 'Channel';
        logo = attrs['tvg-logo'] ?? '';
        group = attrs['group-title'] ?? 'Other';
        tvgId = attrs['tvg-id'] ?? '';
      } else if (line.startsWith('#EXTGRP:')) {
        group = line.substring(8).trim();
      } else if (!line.startsWith('#')) {
        final g = (group == null || group.isEmpty) ? 'Other' : group;
        final gid = _groupIds.putIfAbsent(g, () => '${_groupIds.length + 1}');
        final lower = line.toLowerCase();
        ContentType type = ContentType.live;
        if (lower.contains('/movie/') ||
            RegExp(r'\.(mp4|mkv|avi|mov)(\?|$)').hasMatch(lower)) {
          type = ContentType.movie;
        }
        if (lower.contains('/series/')) type = ContentType.movie;
        out.add(StreamItem(
          type: type,
          id: '${i++}',
          name: name ?? line,
          icon: logo ?? '',
          categoryId: gid,
          epgId: tvgId ?? '',
          directUrl: line,
        ));
        name = logo = tvgId = null;
      }
    }
    return out;
  }

  @override
  Future<AccountInfo?> accountInfo() async => null;

  @override
  Future<List<Category>> categories(ContentType type) async {
    final items = await _load();
    final used = <String>{};
    for (final it in items) {
      if (it.type == type) used.add(it.categoryId);
    }
    return _groupIds.entries
        .where((e) => used.contains(e.value))
        .map((e) => Category(e.value, e.key))
        .toList();
  }

  @override
  Future<List<StreamItem>> streams(ContentType type,
      {String? categoryId}) async {
    final items = await _load();
    return items
        .where((it) =>
            it.type == type &&
            (categoryId == null ||
                categoryId.isEmpty ||
                it.categoryId == categoryId))
        .toList();
  }

  @override
  Future<MovieInfo> movieInfo(StreamItem item) async =>
      MovieInfo(cover: item.icon);

  @override
  Future<SeriesInfo> seriesInfo(StreamItem item) async =>
      SeriesInfo(MovieInfo(cover: item.icon), {});

  @override
  Future<List<EpgEntry>> shortEpg(StreamItem channel) async => [];

  @override
  Future<List<EpgEntry>> fullEpg(StreamItem channel) async => [];

  @override
  String catchupUrl(StreamItem channel, EpgEntry entry) => '';

  @override
  String streamUrl(StreamItem item) => item.directUrl;

  @override
  String episodeUrl(Episode ep) => '';
}

