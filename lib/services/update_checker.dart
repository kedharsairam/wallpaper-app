import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Checks GitHub Releases for newer versions of WallKraft.
///
/// On launch, fetches the latest release tag from
/// github.com/kedharsairam/wallkraft and compares it
/// against the current version. If a newer version exists,
/// the caller can show an update prompt.
///
/// To avoid hitting GitHub API rate limits (60 req/hr unauthenticated),
/// the result is cached in SharedPreferences and only re-checked
/// once every 24 hours per session.
class UpdateChecker {
  static const _repo = 'kedharsairam/wallkraft';
  static const _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';
  static const _cacheKey = 'update_check_result';
  static const _cacheTimeKey = 'update_check_time';
  static const _cacheVersionKey = 'update_check_app_version';
  static const _cacheDuration = Duration(hours: 24);

  /// The current app version (from package_info_plus).
  /// Format: "1.1.0"
  final String currentVersion;

  UpdateChecker({required this.currentVersion});

  /// Checks if a newer release exists on GitHub.
  ///
  /// Returns the latest version string (e.g., "1.1.1") if newer,
  /// or `null` if already up-to-date or the check fails.
  Future<String?> checkForUpdate() async {
    // Return cached result only if the app version hasn't changed
    // AND the cached version is still newer than current.
    final cached = await _getCachedResult();
    if (cached != null) {
      if (_compareVersions(cached, currentVersion) > 0) {
        return cached;
      }
      // Cached version is stale — clear it so we re-check.
      await _cacheResult(null);
      // Fall through to re-check.
    }

    try {
      final response = await http
          .get(
            Uri.parse(_apiUrl),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[Update] API returned ${response.statusCode}');
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('[Update] Unexpected API response format');
        return null;
      }

      final tagName = decoded['tag_name'];
      if (tagName is! String) return null;

      // Strip "v" prefix: "v1.1.0" → "1.1.0"
      final latestVersion =
          tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (latestVersion.isEmpty) return null;

      String? result;
      if (_compareVersions(latestVersion, currentVersion) > 0) {
        result = latestVersion;
      }

      await _cacheResult(result);
      return result;
    } catch (e) {
      debugPrint('[Update] Check failed: $e');
      return null;
    }
  }

  /// Returns the cached result only if the cache is fresh AND the
  /// app version at cache time matches [currentVersion]. If the app
  /// was updated, the cache is invalidated automatically.
  Future<String?> _getCachedResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Invalidate cache if the app version changed since last check.
      final cachedAppVersion = prefs.getString(_cacheVersionKey);
      if (cachedAppVersion != currentVersion) return null;

      final cachedTime = prefs.getInt(_cacheTimeKey);
      if (cachedTime == null) return null;
      final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
      if (age > _cacheDuration.inMilliseconds) return null;

      final cached = prefs.getString(_cacheKey);
      // Empty string means "checked recently, no update found".
      if (cached == null || cached.isEmpty) return null;

      return cached;
    } catch (e) {
      debugPrint('[UpdateChecker] Cache read failed: $e');
      return null;
    }
  }

  Future<void> _cacheResult(String? result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, result ?? '');
      await prefs.setString(_cacheVersionKey, currentVersion);
      await prefs.setInt(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[UpdateChecker] Cache write failed: $e');
    }
  }

  /// Returns > 0 if [a] is newer than [b], < 0 if older, 0 if equal.
  static int _compareVersions(String a, String b) {
    // Strip any pre-release suffix (e.g., "1.2.3-beta" → "1.2.3").
    String clean(String s) => s.split(RegExp(r'[-\+]')).first;
    final aClean = clean(a);
    final bClean = clean(b);

    final aParts =
        aClean.split('.').map(int.tryParse).whereNotNull().toList();
    final bParts =
        bClean.split('.').map(int.tryParse).whereNotNull().toList();

    for (var i = 0; i < aParts.length && i < bParts.length; i++) {
      if (aParts[i] != bParts[i]) return aParts[i] - bParts[i];
    }
    return aParts.length - bParts.length;
  }
}

extension _WhereNotNull<T> on Iterable<T?> {
  Iterable<T> whereNotNull() => where((e) => e != null).cast<T>();
}
