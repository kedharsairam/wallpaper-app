import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'services/wallhaven_api.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const WallKraftApp());
}

class WallKraftApp extends StatelessWidget {
  const WallKraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    );

    return MaterialApp(
      title: 'WallKraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueAccent,
        useMaterial3: true,
        textTheme: textTheme,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      home: HomeScreen(
        api: WallhavenApi(
          // Get your free API key at https://wallhaven.cc/settings/account
          // Set it here or pass via env for higher rate limits
          apiKey: 'xM9Surws3qoMo2U7HwMhDlT1bJ2fJyfl',
        ),
      ),
    );
  }
}
