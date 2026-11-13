// Trial account (TrialAccountActivity / activity_sign_in_trial.xml).
import 'package:material_ui/material_ui.dart';

import '../api/panel_api.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'panel_login.dart';
import 'sign_in_page.dart';
import 'users_list_page.dart';

class TrialPage extends StatefulWidget {
  const TrialPage({super.key});
  @override
  State<TrialPage> createState() => _TrialPageState();
}

class _TrialPageState extends State<TrialPage> {
  String _status = '';
  String _msg = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final (s, m) = await PanelApi.getTrial(Store.deviceId);
      if (mounted) {
        setState(() {
          _status = s;
          _msg = m;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      toast(context, S.err_server_not_connected, error: true);
    }
  }

  Future<void> _login() async {
    try {
      final u = await PanelApi.addTrial(Store.deviceId);
      if (!mounted) return;
      if (u == null) {
        toast(context, S.err_server_not_connected, error: true);
        return;
      }
      await loginPanelUser(context, u);
    } catch (_) {
      if (mounted) toast(context, S.err_server_not_connected, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ok = _status == '1' || _status == '2';
    return LoginLayout(
      side: LoginSide(
        buttons: [
          UiButton(
            text: S.list_users,
            icon: 'ic_shield_user',
            onTap: () => go(context, const UsersListPage(), replace: true),
          ),
        ],
      ),
      form: Container(
        padding: EdgeInsets.all(13.sdp),
        decoration: cardSub(),
        child: _loading
            ? SizedBox(height: 120.sdp, child: const Loader())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  T(S.trial_account_details, size: 12, color: C.title),
                  SizedBox(height: 8.sdp),
                  Container(
                    height: 30.sdp,
                    decoration: BoxDecoration(
                      color: C.fill,
                      borderRadius: BorderRadius.circular(50.sdp),
                      border: Border.all(color: C.border, width: 1.sdp),
                    ),
                    child: Row(
                      children: [
                        Ic('ic_profile', size: 30.sdp, pad: 8.sdp),
                        Container(width: 1.sdp, color: C.border),
                        SizedBox(width: 8.sdp),
                        Expanded(child: T(Store.deviceId, size: 10, lines: 1)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8.sdp),
                  T(_msg, size: 11, color: ok ? const Color(0xFF4CAF50) : const Color(0xFFE91E63)),
                  if (!ok && (Session.app?.get('admin_trial_note') ?? '').isNotEmpty) ...[
                    SizedBox(height: 6.sdp),
                    T(Session.app!.get('admin_trial_note'), size: 11, color: C.title),
                  ],
                  if (ok) ...[
                    SizedBox(height: 8.sdp),
                    GradButton(
                      text: _status == '2' ? S.create_trial_account : S.login_trial_account,
                      icon: 'ic_login',
                      onTap: _login,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
