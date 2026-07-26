import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel for setting wallpapers on Android.
///
/// Uses `WallpaperManager` via Kotlin host to set
/// home screen, lock screen, or both.
class WallpaperSetter {
  static const _channel = MethodChannel('com.wallkraft.app/wallpaper');

  /// Set wallpaper from [filePath].
  ///
  /// [which]: 'home', 'lock', or 'both'. Defaults to 'both'.
  /// Returns true on success, false on failure.
  static Future<bool> setWallpaper(String filePath,
      {String which = 'both'}) async {
    try {
      await _channel.invokeMethod('setWallpaper', {
        'path': filePath,
        'which': which,
      });
      return true;
    } catch (e) {
      debugPrint('[WallpaperSetter] Failed to set wallpaper: $e');
      return false;
    }
  }
}
