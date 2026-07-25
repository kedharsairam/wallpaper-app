import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Simple file-based cache for the most recent browse results.
///
/// Stores the raw JSON of the last successful search response.
/// When a network request fails, the UI can fall back to this cache.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const _fileName = 'wallkraft_cache.json';

  Future<File> get _cacheFile async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Saves raw JSON response to cache.
  Future<void> save(Map<String, dynamic> data) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Cache write failures are non-critical — silently ignore.
    }
  }

  /// Loads cached response, or null if no cache exists.
  Future<Map<String, dynamic>?> load() async {
    try {
      final file = await _cacheFile;
      if (await file.exists()) {
        final raw = await file.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
      }
    } catch (_) {
      // Corrupted cache — silently ignore.
    }
    return null;
  }

  /// Clears the cache (e.g., when filters change).
  Future<void> clear() async {
    try {
      final file = await _cacheFile;
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
