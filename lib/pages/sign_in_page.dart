// Xtream Codes / 1-Stream login (SignInActivity / activity_sign_in.xml).
import 'package:material_ui/material_ui.dart';

import '../api/xtream_api.dart';
import '../library.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../ui/kit.dart';
import '../ui/strings.dart';
import 'nav.dart';
import 'users_list_page.dart';
import 'trial_page.dart';

/// Left column shared by all login pages: big logo and small buttons.
class LoginSide extends StatelessWidget {
  final List<Widget> buttons;
  final Widget? top;
  const LoginSide({super.key, this.buttons = const [], this.top});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            top ?? Logo(size: 100.sdp, radius: 6),
            if (buttons.isNotEmpty) ...[
              SizedBox(height: 15.sdp),
              Wrap(spacing: 5.sdp, runSpacing: 5.sdp, alignment: WrapAlignment.center, children: buttons),
            ],
          ],
        ),
      ),
    );
  }
}

/// Two-column login layout: side (weight 1) and form card (weight 1.4).
class LoginLayout extends StatelessWidget {
  final Widget side;
  final Widget form;
  final double formWeight;
  const LoginLayout({super.key, required this.side, required this.form, this.formWeight = 1.4});
  @override
  Widget build(BuildContext context) {
    return PageBg(
      child: Padding(
        padding: EdgeInsets.all(5.sdp),
        child: Row(
          children: [
            Expanded(flex: 10, child: side),
            SizedBox(width: 10.sdp),
            Expanded(
              flex: (formWeight * 10).round(),
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 8.sdp),
                  child: form,
                ),
              ),
            ),
            SizedBox(width: 10.sdp),
          ],
        ),
      ),
    );
  }
}

class SignInPage extends StatefulWidget {
  final bool stream; // 1-Stream login uses the stream DNS list
  const SignInPage({super.key, required this.stream});
  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _name = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _url = TextEditingController();
  int _dns = 0;
  bool _busy = false;

  List<Dns> get _dnsList {
    final app = Session.app;
    final list = [Dns(S.external, '')];
    if (app == null) return list;
    final enabled = widget.stream ? app.streamDnsEnabled : app.xuiDnsEnabled;
    if (enabled) list.addAll(widget.stream ? app.streamDns : app.xuiDns);
    return list;
  }

  bool get _showDns {
    final app = Session.app;
    if (app == null) return false;
    return widget.stream ? app.streamDnsEnabled : app.xuiDnsEnabled;
  }

  Future<void> _login() async {
    final dns = _dnsList;
    String url = _dns == 0 ? _url.text.replaceAll(' ', '') : dns[_dns].base;
    if (_dns != 0 && url.isEmpty) url = 'https://nemosofts.com';
    final user = _user.text;
    final pass = _pass.text;
    if (pass.isEmpty || user.isEmpty || url.isEmpty) {
      toast(context, S.err_cannot_empty, error: true);
      return;
    }
    if (pass.endsWith(' ')) {
      toast(context, S.err_pass_end_space, error: true);
      return;
    }
    if (_name.text.isEmpty) _name.text = user;
    final blocked = Session.app?.blockedDns ?? const [];
    if (blocked.any((b) => url.toLowerCase().contains(b))) {
      toast(context, 'Blacklist', error: true);
      return;
    }
    setState(() => _busy = true);
    final a = Account.xtream(
      name: _name.text,
      server: url,
      username: user,
      password: pass,
      kind: widget.stream ? 'stream' : 'xui',
    );
    try {
      await XtreamSource.login(a);
      await Store.saveAccount(a);
      await Store.setCurrent(a);
      Library.reset();
      if (!mounted) return;
      toast(context, 'Login successfully.');
      openHome(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      toast(context, S.err_login_not_incorrect, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dns = _dnsList;
    final trial = !widget.stream && (Session.app?.trial ?? false);
    return LoginLayout(
      side: LoginSide(
        buttons: [
          if (trial)
            UiButton(
              text: S.trial_account,
              icon: 'ic_shield_cross',
              onTap: () => go(context, const TrialPage(), replace: true),
            ),
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
            T(S.enter_login_details, size: 12, color: C.title),
            SizedBox(height: 8.sdp),
            PillField(icon: 'ic_profile', hint: S.any_name, controller: _name),
            SizedBox(height: 6.sdp),
            PillField(icon: 'ic_profile', hint: S.user_name, controller: _user),
            SizedBox(height: 6.sdp),
            PillField(icon: 'ic_lock', hint: S.user_password, controller: _pass, password: true),
            if (_showDns) ...[
              SizedBox(height: 6.sdp),
              SizedBox(
                height: 25.sdp,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: dns.length,
                  separatorBuilder: (_, _) => SizedBox(width: 5.sdp),
                  itemBuilder: (_, i) => _DnsChip(
                    title: dns[i].title,
                    selected: i == _dns,
                    onTap: () => setState(() {
                      if (_dns != 0 && i == 0) _url.clear();
                      _dns = i;
                    }),
                  ),
                ),
              ),
            ],
            if (_dns == 0) ...[
              SizedBox(height: 6.sdp),
              PillField(
                icon: 'ic_link',
                hint: S.url_here_com_port,
                controller: _url,
                keyboard: TextInputType.url,
                onSubmitted: (_) => _login(),
              ),
            ],
            SizedBox(height: 10.sdp),
            GradButton(text: S.login, icon: 'ic_login', loading: _busy, onTap: _login),
          ],
        ),
      ),
    );
  }
}

/// row_dns_list: rounded chip with a tick when selected.
class _DnsChip extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;
  const _DnsChip({required this.title, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      builder: (f) => Container(
        padding: EdgeInsets.symmetric(horizontal: 8.sdp),
        decoration: BoxDecoration(
          color: C.fill,
          borderRadius: BorderRadius.circular(f ? 2.sdp : 50.sdp),
          border: Border.all(color: f ? C.select : C.border, width: f ? 2.sdp : 1.sdp),
        ),
        // row_dns_list: orange tick only on the chosen server.
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[Ic('ic_check_circle', size: 16.sdp, pad: 1.sdp, color: C.select), SizedBox(width: 3.sdp)],
            T(title, size: 12),
          ],
        ),
      ),
    );
  }
}
