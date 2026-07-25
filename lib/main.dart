import 'dart:io' show Platform;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'api/client.dart';
import 'app.dart';
import 'services/update_checker.dart';

void main() {
  // ── Global error boundary ──────────────────────────────────────────
  // Prevents white screens from unhandled widget tree exceptions.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // In production, also log to file here
    debugPrint('[FATAL] ${details.exception}');
    debugPrint('[FATAL] ${details.stack}');
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PLATFORM ERROR] $error\n$stack');
    return true; // Don't kill the process
  };

  WidgetsFlutterBinding.ensureInitialized();

  // ── Desktop database backend ──────────────────────────────────────
  // sqflite uses platform channels on mobile; on desktop we need FFI.
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // ── Image cache limit ──────────────────────────────────────────────
  // Prevents unbounded memory growth from decoded images.
  // 80MB ceiling — safe for all modern devices.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 * 1024 * 1024;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Works without an API key (rate limit: ~45 req/hr).
  // To use an API key, set via --dart-define=WALLHAVEN_KEY=your-key
  // at build time and pass it to the client constructor.
  final api = WallpaperApi();
  final updater = UpdateChecker(currentVersion: '1.0.0');

  runApp(WallKraftApp(api: api, updater: updater));
}
