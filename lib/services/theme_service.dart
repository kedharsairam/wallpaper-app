import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and applies the user's theme preference.
///
/// Supports three modes:
///   - [ThemeMode.system] — follow device setting (default)
///   - [ThemeMode.dark]   — force dark
///   - [ThemeMode.light]  — force light
class ThemeService {
  static const _key = 'theme_mode';
  static const _systemValue = 'system';
  static const _darkValue = 'dark';
  static const _lightValue = 'light';

  /// Load the saved theme mode (defaults to system).
  static Future<ThemeMode> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key);
      switch (value) {
        case _darkValue:
          return ThemeMode.dark;
        case _lightValue:
          return ThemeMode.light;
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      debugPrint('[ThemeService] Load failed: $e');
      return ThemeMode.system;
    }
  }

  /// Persist a theme mode.
  static Future<void> save(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = switch (mode) {
        ThemeMode.dark => _darkValue,
        ThemeMode.light => _lightValue,
        _ => _systemValue,
      };
      await prefs.setString(_key, value);
    } catch (e) {
      debugPrint('[ThemeService] Save failed: $e');
    }
  }

  /// Human-readable label for a theme mode.
  static String label(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
    };
  }

  /// Icon for a theme mode.
  static IconData icon(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.settings_brightness,
      ThemeMode.dark => Icons.dark_mode,
      ThemeMode.light => Icons.light_mode,
    };
  }
}
