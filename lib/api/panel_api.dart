import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models.dart';

/// Talks to the PHP admin panel (POST /api with a base64 "data" field).
class PanelApi {
  static Future<dynamic> _call(Map<String, dynamic> body, {bool check = true}) async {
    final payload = {'application_id': AppConfig.applicationId, ...body};
    final data = base64.encode(
        utf8.encode(Uri.encodeComponent(jsonEncode(payload))));
    final res = await http
        .post(Uri.parse('${AppConfig.panelUrl}/api'), body: {'data': data})
        .timeout(AppConfig.timeout);
    if (res.statusCode != 200) {
      throw Exception('Panel error ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    final out = json[AppConfig.apiHeader];
    if (check && out is List && out.isNotEmpty && out.first is Map) {
      final first = out.first as Map;
      if (first['success'] == '0' || first['success'] == '-1') {
        throw Exception(first['MSG'] ?? 'Panel error');
      }
    }
    return out;
  }

  /// App settings, DNS list, notifications.
  static Future<AppDetails> appDetails() async {
    final out = await _call({'helper_name': 'app_details'});
    return AppDetails.fromJson(Map<String, dynamic>.from(out as Map));
  }

  /// Logins saved in the panel for an activation code.
  static Future<List<PanelUser>> activationCode(String code) async {
    final out = await _call(
        {'helper_name': 'get_activation_code', 'activation_code': code});
    return _users(out);
  }

  /// Logins saved in the panel for a device id.
  static Future<List<PanelUser>> deviceUsers(String deviceId) async {
    final out =
        await _call({'helper_name': 'get_device_user', 'device_id': deviceId});
    return _users(out);
  }

  static List<PanelUser> _users(dynamic out) {
    if (out is! List) return [];
    return out
        .whereType<Map>()
        .where((m) => m.containsKey('user_name'))
        .map((m) => PanelUser.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Trial status for this device: (success, message). success 1 = has a
  /// trial to log in to, 2 = can create one, other = not allowed.
  static Future<(String, String)> getTrial(String deviceId) async {
    final out = await _call({'helper_name': 'get_trial', 'device_id': deviceId}, check: false);
    if (out is List && out.isNotEmpty && out.first is Map) {
      final m = out.first as Map;
      return ('${m['success'] ?? ''}', '${m['MSG'] ?? ''}');
    }
    return ('0', '');
  }

  /// Creates (or returns) the trial login for this device.
  static Future<PanelUser?> addTrial(String deviceId) async {
    final out = await _call({'helper_name': 'add_trial', 'device_id': deviceId}, check: false);
    if (out is List) {
      for (final m in out.whereType<Map>()) {
        if (m.containsKey('user_type')) {
          return PanelUser(
              '${m['user_type']}', '${m['user_name']}', '${m['user_password']}', '${m['dns_base']}');
        }
      }
    }
    return null;
  }

  static Future<void> report(
      {required String user,
      required String pass,
      required String title,
      required String msg}) async {
    await _call({
      'helper_name': 'post_report',
      'user_name': user,
      'user_pass': pass,
      'report_title': title,
      'report_msg': msg,
    });
  }
}
