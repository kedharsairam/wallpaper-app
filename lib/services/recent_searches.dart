import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages recent search queries using SharedPreferences.
///
/// Stores up to [maxItems] recent searches as a JSON array.
/// Oldest entries are evicted when the limit is exceeded.
class RecentSearchesService {
  static const _key = 'recent_searches';
  static const maxItems = 10;

  /// Load recent searches from SharedPreferences.
  static Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Save a new search query. Moves to front if already exists.
  /// Evicts oldest if over [maxItems].
  static Future<void> save(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final searches = await load();
    searches.remove(trimmed);
    searches.insert(0, trimmed);

    // Trim to max
    while (searches.length > maxItems) {
      searches.removeLast();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(searches));
  }

  /// Remove a single search query.
  static Future<void> remove(String query) async {
    final searches = await load();
    searches.remove(query);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(searches));
  }

  /// Clear all recent searches.
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
