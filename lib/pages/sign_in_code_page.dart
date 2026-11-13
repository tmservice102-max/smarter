// Login with activation code (SignInCodeActivity / activity_sign_in_code.xml).
import 'package:material_ui/material_ui.dart';

import '../api/panel_api.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'panel_login.dart';
import 'sign_in_page.dart';
import 'users_list_page.dart';

class SignInCodePage extends StatefulWidget {
  const SignInCodePage({super.key});
  @override
  State<SignInCodePage> createState() => _SignInCodePageState();
}

class _SignInCodePageState extends State<SignInCodePage> {
  final _code = TextEditingController();
  bool _busy = false;

  Future<void> _go() async {
    if (_code.text.trim().isEmpty) {
      toast(context, S.err_cannot_empty, error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final users = await PanelApi.activationCode(_code.text.trim());
      if (!mounted) return;
      setState(() => _busy = false);
      if (users.isEmpty) {
        toast(context, S.err_activation_code_incorrect, error: true);
      } else {
        await loginPanelUser(context, users.first);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, S.err_server_not_connected, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        padding: EdgeInsets.all(10.sdp),
        decoration: cardSub(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            T(S.enter_activation_details, size: 12, color: C.title),
            SizedBox(height: 8.sdp),
            PillField(icon: 'ic_keyhole', hint: S.activation_code, controller: _code, onSubmitted: (_) => _go()),
            SizedBox(height: 8.sdp),
            GradButton(text: S.activation, icon: 'ic_keyhole', loading: _busy, onTap: _go),
          ],
        ),
      ),
    );
  }
}
