import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DlStatus { queued, running, done, failed }

class DownloadItem {
  final String id;
  final String title;
  final String icon;
  final String url;
  String path;
  DlStatus status;
  int received;
  int total;

  DownloadItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.url,
    this.path = '',
    this.status = DlStatus.queued,
    this.received = 0,
    this.total = 0,
  });

  double get progress => total > 0 ? received / total : 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'url': url,
        'path': path,
        'status': status == DlStatus.done ? 'done' : 'failed',
        'received': received,
        'total': total,
      };

  factory DownloadItem.fromJson(Map<String, dynamic> j) => DownloadItem(
        id: j['id'],
        title: j['title'] ?? '',
        icon: j['icon'] ?? '',
        url: j['url'] ?? '',
        path: j['path'] ?? '',
        status: j['status'] == 'done' ? DlStatus.done : DlStatus.failed,
        received: j['received'] ?? 0,
        total: j['total'] ?? 0,
      );
}

/// Downloads movies and episodes to the phone for offline viewing.
/// Downloads run while the app is open.
class Downloads extends ChangeNotifier {
  static final Downloads instance = Downloads._();
  Downloads._();

  final List<DownloadItem> items = [];
  final Map<String, http.Client> _clients = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final p = await SharedPreferences.getInstance();
    for (final s in p.getStringList('downloads') ?? []) {
      try {
        final d = DownloadItem.fromJson(jsonDecode(s));
        if (d.status == DlStatus.done && !File(d.path).existsSync()) continue;
        items.add(d);
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
        'downloads', items.map((d) => jsonEncode(d.toJson())).toList());
  }

  DownloadItem? find(String id) {
    for (final d in items) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<void> start(
      {required String id,
      required String title,
      required String icon,
      required String url}) async {
    await load();
    final existing = find(id);
    if (existing != null && existing.status != DlStatus.failed) return;
    if (existing != null) items.remove(existing);
    final item = DownloadItem(id: id, title: title, icon: icon, url: url);
    items.insert(0, item);
    notifyListeners();
    unawaited(_run(item));
  }

  Future<void> _run(DownloadItem item) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/downloads');
    if (!folder.existsSync()) folder.createSync(recursive: true);
    final ext = Uri.parse(item.url).path.split('.').last;
    final safe = item.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    item.path = '${folder.path}/$safe.${ext.length <= 4 ? ext : 'mp4'}';
    item.status = DlStatus.running;
    notifyListeners();

    final client = http.Client();
    _clients[item.id] = client;
    IOSink? sink;
    try {
      final req = http.Request('GET', Uri.parse(item.url))
        ..headers['User-Agent'] = 'IPTVSmartersPro';
      final res = await client.send(req);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      item.total = res.contentLength ?? 0;
      sink = File(item.path).openWrite();
      var lastNotify = DateTime.now();
      await for (final chunk in res.stream) {
        sink.add(chunk);
        item.received += chunk.length;
        if (DateTime.now().difference(lastNotify).inMilliseconds > 500) {
          lastNotify = DateTime.now();
          notifyListeners();
        }
      }
      await sink.close();
      item.status = DlStatus.done;
    } catch (e) {
      await sink?.close();
      item.status = DlStatus.failed;
      try {
        File(item.path).deleteSync();
      } catch (_) {}
    } finally {
      _clients.remove(item.id)?.close();
      notifyListeners();
      await _save();
    }
  }

  Future<void> remove(DownloadItem item) async {
    _clients.remove(item.id)?.close();
    items.remove(item);
    try {
      if (item.path.isNotEmpty) File(item.path).deleteSync();
    } catch (_) {}
    notifyListeners();
    await _save();
  }
}
