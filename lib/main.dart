import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api/client.dart';
import 'app.dart';
import 'services/notification_service.dart';
import 'services/update_checker.dart';
import 'services/db_init_stub.dart'
    if (dart.library.io) 'services/db_init_io.dart';

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

  // ── Download notifications ────────────────────────────────────────
  NotificationService.instance.init();

  // ── Desktop database backend ──────────────────────────────────────
  // sqflite uses platform channels on mobile; on desktop we need FFI.
  // On web, this is a no-op (stub).
  initDesktopDatabase();

  // ── Image cache limit ──────────────────────────────────────────────
  // Prevents unbounded memory growth from decoded images.
  // 80MB ceiling — safe for all modern devices.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 * 1024 * 1024;

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Works without an API key (rate limit: ~45 req/hr).
  // Users can paste their Wallhaven API key in Settings to raise
  // the limit to ~5000 req/hr. The key is loaded automatically.
  const api = WallpaperApi();
  final updater = UpdateChecker(currentVersion: '1.0.0');

  runApp(WallKraftApp(api: api, updater: updater));
}
