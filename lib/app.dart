import 'package:flutter/material.dart';
import 'api/client.dart';
import 'screens/browse.dart';

class WallKraftApp extends StatelessWidget {
  final WallhavenApi api;

  const WallKraftApp({super.key, required this.api});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WallKraft',
      debugShowCheckedModeBanner: false,
      theme: _darkTheme(),
      home: BrowseScreen(api: api),
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueAccent,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
