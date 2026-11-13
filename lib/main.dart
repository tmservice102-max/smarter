import 'package:material_ui/material_ui.dart';
import 'package:media_kit/media_kit.dart';
import 'config.dart';
import 'store.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Store.init();
  runApp(const IptvApp());
}

class IptvApp extends StatelessWidget {
  const IptvApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1E88E5);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
            seedColor: accent, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0E1117),
        cardColor: const Color(0xFF1A1F2B),
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF0E1117), elevation: 0),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A1F2B),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
