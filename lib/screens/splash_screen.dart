import 'package:material_ui/material_ui.dart';
import '../api/panel_api.dart';
import '../api/source.dart';
import '../config.dart';
import '../session.dart';
import '../store.dart';
import 'home_screen.dart';
import 'accounts_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _maintenance;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      Session.app = await PanelApi.appDetails();
    } catch (_) {
      // Panel unreachable: the app still works with saved or manual logins.
    }
    if (!mounted) return;
    if (Session.app?.maintenance == true) {
      setState(() => _maintenance =
          'The app is under maintenance. Please try again later.');
      return;
    }
    final acc = Store.currentAccount;
    if (acc != null) {
      Session.source = ContentSource.forAccount(acc);
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AccountsScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.live_tv_rounded, size: 80, color: Color(0xFF1E88E5)),
          const SizedBox(height: 16),
          Text(AppConfig.appName,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          if (_maintenance == null)
            const CircularProgressIndicator()
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_maintenance!, textAlign: TextAlign.center),
            ),
        ]),
      ),
    );
  }
}
