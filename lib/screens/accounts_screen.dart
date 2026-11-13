import 'package:material_ui/material_ui.dart';
import '../api/source.dart';
import '../models.dart';
import '../session.dart';
import '../store.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// List of saved logins, plus "add new".
class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});
  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  @override
  void initState() {
    super.initState();
    if (Store.accounts.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _add(replace: true));
    }
  }

  Future<void> _add({bool replace = false}) async {
    final route = MaterialPageRoute(builder: (_) => const LoginScreen());
    if (replace) {
      Navigator.of(context).pushReplacement(route);
    } else {
      await Navigator.of(context).push(route);
      setState(() {});
    }
  }

  void _open(Account a) async {
    await Store.setCurrent(a);
    Session.source = ContentSource.forAccount(a);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final list = Store.accounts;
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Add user'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final a = list[i];
          return Card(
            child: ListTile(
              leading: Icon(a.type == AccountType.xtream
                  ? Icons.dns_rounded
                  : Icons.playlist_play_rounded),
              title: Text(a.name),
              subtitle: Text(a.type == AccountType.xtream
                  ? '${a.username} • ${a.server}'
                  : a.server,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await Store.removeAccount(a);
                  setState(() {});
                },
              ),
              onTap: () => _open(a),
            ),
          );
        },
      ),
    );
  }
}
