import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and retrieves the user's Wallhaven API key.
///
/// The key is stored in SharedPreferences and never transmitted anywhere
/// except to the Wallhaven API as the `X-API-Key` header.
class ApiKeyService {
  static const _key = 'wallhaven_api_key';
  static const _keyUrl = 'https://wallhaven.cc/settings/account';

  /// Load the saved API key, or null if not set.
  static Future<String?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_key);
    } catch (e) {
      debugPrint('[ApiKey] Load failed: $e');
      return null;
    }
  }

  /// Persist an API key. Pass null to clear it.
  static Future<void> save(String? apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (apiKey != null && apiKey.trim().isNotEmpty) {
        await prefs.setString(_key, apiKey.trim());
      } else {
        await prefs.remove(_key);
      }
    } catch (e) {
      debugPrint('[ApiKey] Save failed: $e');
    }
  }

  /// Check whether a key has been saved.
  static Future<bool> hasKey() async {
    final key = await load();
    return key != null && key.isNotEmpty;
  }

  /// The URL where users can find their API key.
  static String get settingsUrl => _keyUrl;
}
