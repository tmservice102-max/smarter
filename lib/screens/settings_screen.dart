import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/panel_api.dart';
import '../config.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'accounts_screen.dart';
import 'downloads_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AccountInfo? _info;
  bool _infoLoaded = false;

  @override
  void initState() {
    super.initState();
    Session.src.accountInfo().then((i) {
      if (mounted) setState(() { _info = i; _infoLoaded = true; });
    }).catchError((_) {
      if (mounted) setState(() => _infoLoaded = true);
    });
  }

  void _switchUser() {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AccountsScreen()));
  }

  Future<void> _logout() async {
    await Store.setCurrent(null);
    Session.source = null;
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AccountsScreen()), (_) => false);
  }

  void _report() {
    final title = TextEditingController();
    final msg = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report a problem'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 8),
          TextField(controller: msg, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final a = Session.src.account;
              try {
                await PanelApi.report(
                    user: a.username.isEmpty ? a.name : a.username,
                    pass: a.password,
                    title: title.text,
                    msg: msg.text);
                if (mounted) toast(context, 'Thanks, your report was sent');
              } catch (e) {
                if (mounted) toast(context, friendlyError(e));
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _notifications() {
    final notes = Session.app?.notifications ?? [];
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: notes.isEmpty
            ? const EmptyView('No notifications', icon: Icons.notifications_none)
            : ListView(
                children: notes
                    .map((n) => ListTile(
                          leading: const Icon(Icons.notifications),
                          title: Text('${n['notification_title'] ?? ''}'),
                          subtitle: Text('${n['notification_msg'] ?? ''}\n${n['notification_on'] ?? ''}'),
                          isThreeLine: true,
                        ))
                    .toList(),
              ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final a = Session.src.account;
    final app = Session.app;
    String expiry = '';
    if (_info?.expires != null) {
      final e = _info!.expires!;
      expiry = '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
    }
    return ListView(padding: const EdgeInsets.all(12), children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(a.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            if (a.type == AccountType.xtream) Text('User: ${a.username}'),
            if (!_infoLoaded && a.type == AccountType.xtream)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            if (_info != null) ...[
              Text('Status: ${_info!.status}'),
              if (expiry.isNotEmpty) Text('Expires: $expiry'),
              if (_info!.maxConnections.isNotEmpty)
                Text('Connections: ${_info!.activeConnections} of ${_info!.maxConnections}'),
            ],
          ]),
        ),
      ),
      const SizedBox(height: 8),
      ListTile(
        leading: const Icon(Icons.download),
        title: const Text('Downloads'),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const DownloadsScreen())),
      ),
      ListTile(leading: const Icon(Icons.people), title: const Text('Switch user'), onTap: _switchUser),
      ListTile(leading: const Icon(Icons.logout), title: const Text('Log out'), onTap: _logout),
      const Divider(),
      SwitchListTile(
        secondary: const Icon(Icons.access_time),
        title: const Text('24-hour time'),
        value: Store.use24h,
        onChanged: (v) => setState(() => Store.use24h = v),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.skip_next),
        title: const Text('Play next episode automatically'),
        value: Store.autoplayNext,
        onChanged: (v) => setState(() => Store.autoplayNext = v),
      ),
      ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Clear recently watched'),
        onTap: () async {
          await Store.clearRecent();
          if (context.mounted) toast(context, 'Cleared');
        },
      ),
      const Divider(),
      ListTile(leading: const Icon(Icons.notifications), title: const Text('Notifications'), onTap: _notifications),
      ListTile(leading: const Icon(Icons.report_problem_outlined), title: const Text('Report a problem'), onTap: _report),
      ListTile(
        leading: const Icon(Icons.privacy_tip_outlined),
        title: const Text('Privacy policy'),
        onTap: () => launchUrl(Uri.parse('${AppConfig.panelUrl}/privacy-policy')),
      ),
      ListTile(
        leading: const Icon(Icons.description_outlined),
        title: const Text('Terms'),
        onTap: () => launchUrl(Uri.parse('${AppConfig.panelUrl}/terms')),
      ),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('About'),
        onTap: () => showAboutDialog(
          context: context,
          applicationName: AppConfig.appName,
          applicationVersion: '1.0.0',
          children: [
            if (app != null && app.get('app_description').isNotEmpty)
              Text(app.get('app_description').replaceAll(RegExp(r'<[^>]*>'), '')),
            if (app != null && app.get('app_email').isNotEmpty)
              Text('\nContact: ${app.get('app_email')}'),
          ],
        ),
      ),
      const SizedBox(height: 24),
    ]);
  }
}
