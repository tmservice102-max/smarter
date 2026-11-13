import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../api/m3u_source.dart';
import '../api/panel_api.dart';
import '../api/source.dart';
import '../api/xtream_api.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _busy = false;

  List<_Tab> get _tabs {
    final app = Session.app;
    final tabs = <_Tab>[];
    // When the panel is unreachable, show Xtream and M3U so the app still works.
    if (app == null || app.allowXtream) tabs.add(_Tab.xtream);
    if (app == null || app.allowPlaylist) tabs.add(_Tab.playlist);
    if (app != null && app.allowActivation) tabs.add(_Tab.activation);
    if (app != null && app.allowDeviceId) tabs.add(_Tab.device);
    if (tabs.isEmpty) tabs.add(_Tab.xtream);
    return tabs;
  }

  Future<void> _finish(Account a) async {
    await Store.saveAccount(a);
    await Store.setCurrent(a);
    Session.source = ContentSource.forAccount(a);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  Future<void> _run(Future<Account> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final a = await job();
      await _finish(a);
    } catch (e) {
      if (mounted) toast(context, friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Account> _fromPanelUsers(List<PanelUser> users) async {
    if (users.isEmpty) throw Exception('No account found for this code');
    final a = users.first.toAccount();
    if (a.type == AccountType.xtream) {
      await XtreamSource.login(a);
    } else {
      await M3uSource.validate(a);
    }
    return a;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add user'),
          bottom: tabs.length > 1
              ? TabBar(
                  isScrollable: true,
                  tabs: tabs.map((t) => Tab(text: t.label)).toList())
              : null,
        ),
        bottomNavigationBar: const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'This app is a media player. It does not include any channels or content. '
              'Use the login or playlist given to you by your own provider.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ),
        body: Stack(children: [
          TabBarView(
            children: tabs.map((t) {
              switch (t) {
                case _Tab.xtream:
                  return _XtreamForm(onSubmit: (a) => _run(() async {
                        await XtreamSource.login(a);
                        return a;
                      }));
                case _Tab.playlist:
                  return _PlaylistForm(onSubmit: (a) => _run(() async {
                        await M3uSource.validate(a);
                        return a;
                      }));
                case _Tab.activation:
                  return _ActivationForm(
                      onSubmit: (code) => _run(() async => _fromPanelUsers(
                          await PanelApi.activationCode(code))));
                case _Tab.device:
                  return _DeviceForm(
                      onSubmit: () => _run(() async => _fromPanelUsers(
                          await PanelApi.deviceUsers(Store.deviceId))));
              }
            }).toList(),
          ),
          if (_busy)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ]),
      ),
    );
  }
}

enum _Tab {
  xtream('Xtream Codes'),
  playlist('M3U Playlist'),
  activation('Activation code'),
  device('Device ID');

  final String label;
  const _Tab(this.label);
}

class _XtreamForm extends StatefulWidget {
  final void Function(Account) onSubmit;
  const _XtreamForm({required this.onSubmit});
  @override
  State<_XtreamForm> createState() => _XtreamFormState();
}

class _XtreamFormState extends State<_XtreamForm> {
  final _name = TextEditingController();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  Dns? _dns;
  bool _hide = true;

  List<Dns> get _dnsList =>
      [...?Session.app?.xuiDns, ...?Session.app?.streamDns];

  @override
  Widget build(BuildContext context) {
    final dnsOnly = (Session.app?.xuiDnsOnly ?? false) && _dnsList.isNotEmpty;
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Any name')),
      const SizedBox(height: 12),
      TextField(
          controller: _user,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Username')),
      const SizedBox(height: 12),
      TextField(
        controller: _pass,
        obscureText: _hide,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
            onPressed: () => setState(() => _hide = !_hide),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (_dnsList.isNotEmpty)
        DropdownButtonFormField<Dns>(
          initialValue: _dns,
          decoration: const InputDecoration(labelText: 'Server'),
          items: _dnsList
              .map((d) => DropdownMenuItem(value: d, child: Text(d.title)))
              .toList(),
          onChanged: (d) => setState(() => _dns = d),
        ),
      if (!dnsOnly) ...[
        if (_dnsList.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: Text('or enter a server URL')),
          ),
        TextField(
          controller: _server,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration:
              const InputDecoration(labelText: 'http://server.com:8080'),
        ),
      ],
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        onPressed: () {
          final server =
              _server.text.trim().isNotEmpty ? _server.text : (_dns?.base ?? '');
          if (_user.text.trim().isEmpty ||
              _pass.text.isEmpty ||
              server.trim().isEmpty) {
            toast(context, 'Please fill in username, password and server');
            return;
          }
          widget.onSubmit(Account.xtream(
            name: _name.text.trim().isEmpty ? _user.text.trim() : _name.text.trim(),
            server: server,
            username: _user.text.trim(),
            password: _pass.text,
          ));
        },
        child: const Text('Add user'),
      ),
    ]);
  }
}

class _PlaylistForm extends StatefulWidget {
  final void Function(Account) onSubmit;
  const _PlaylistForm({required this.onSubmit});
  @override
  State<_PlaylistForm> createState() => _PlaylistFormState();
}

class _PlaylistFormState extends State<_PlaylistForm> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Playlist name')),
      const SizedBox(height: 12),
      TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'M3U URL')),
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        onPressed: () {
          final url = _url.text.trim();
          if (!url.startsWith('http')) {
            toast(context, 'Please enter a valid playlist URL');
            return;
          }
          widget.onSubmit(Account.playlist(
              name: _name.text.trim().isEmpty ? 'Playlist' : _name.text.trim(),
              url: url));
        },
        child: const Text('Add playlist'),
      ),
    ]);
  }
}

class _ActivationForm extends StatefulWidget {
  final void Function(String) onSubmit;
  const _ActivationForm({required this.onSubmit});
  @override
  State<_ActivationForm> createState() => _ActivationFormState();
}

class _ActivationFormState extends State<_ActivationForm> {
  final _code = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Enter the activation code you received.'),
      const SizedBox(height: 12),
      TextField(
          controller: _code,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Activation code')),
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        onPressed: () {
          if (_code.text.trim().isEmpty) return;
          widget.onSubmit(_code.text.trim());
        },
        child: const Text('Activate'),
      ),
    ]);
  }
}

class _DeviceForm extends StatelessWidget {
  final VoidCallback onSubmit;
  const _DeviceForm({required this.onSubmit});
  @override
  Widget build(BuildContext context) {
    final id = Store.deviceId;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text(
          'Give this device ID to your provider. Once they add it, tap "Check".'),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          title: SelectableText(id,
              style: const TextStyle(fontSize: 24, letterSpacing: 2)),
          trailing: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: id));
              toast(context, 'Copied');
            },
          ),
        ),
      ),
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        onPressed: onSubmit,
        child: const Text('Check'),
      ),
    ]);
  }
}
