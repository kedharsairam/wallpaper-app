import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Simple file-based cache for the most recent browse results.
///
/// Stores the raw JSON of the last successful search response.
/// When a network request fails, the UI can fall back to this cache.
///
/// Writes are atomic (write to temp file, then rename) to prevent
/// corruption from concurrent access or mid-write crashes.
class CacheService {
  CacheService._();
  static final CacheService instance = CacheService._();

  static const _fileName = 'wallkraft_cache.json';
  static const _tempSuffix = '.tmp';

  Future<File> get _cacheFile async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<File> get _tempFile async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/$_fileName$_tempSuffix');
  }

  /// Saves raw JSON response to cache (atomic write).
  Future<void> save(Map<String, dynamic> data) async {
    try {
      final tmp = await _tempFile;
      final target = await _cacheFile;
      // Write to temp file first, then rename for atomicity.
      await tmp.writeAsString(jsonEncode(data));
      await tmp.rename(target.path);
    } catch (e) {
      debugPrint('[CacheService] Save failed: $e');
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
    } catch (e) {
      debugPrint('[CacheService] Load failed: $e');
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
      // Also clean up any leftover temp file from a crashed write.
      final tmp = await _tempFile;
      if (await tmp.exists()) {
        await tmp.delete();
      }
    } catch (e) {
      debugPrint('[CacheService] Clear failed: $e');
    }
  }
}
