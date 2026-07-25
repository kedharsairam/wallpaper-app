import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api/client.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Wallhaven API works without a key (rate limit: ~45 req/hr).
  // To use an API key, pass it to WallhavenApi(apiKey: 'your-key')
  // or set via --dart-define=WALLHAVEN_KEY=your-key at build time.
  final api = WallhavenApi();

  runApp(WallKraftApp(api: api));
}
