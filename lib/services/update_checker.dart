import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Checks GitHub Releases for newer versions of WallKraft.
///
/// On launch, fetches the latest release tag from
/// github.com/kedharsairam/wallpaper-app and compares it
/// against the current version. If a newer version exists,
/// the caller can show an update prompt.
class UpdateChecker {
  static const _repo = 'kedharsairam/wallpaper-app';
  static const _apiUrl = 'https://api.github.com/repos/$_repo/releases/latest';

  /// The current app version (from pubspec.yaml).
  /// Format: "1.0.0"
  final String currentVersion;

  UpdateChecker({required this.currentVersion});

  /// Checks if a newer release exists on GitHub.
  ///
  /// Returns the latest version string (e.g., "1.1.0") if newer,
  /// or `null` if already up-to-date or the check fails.
  Future<String?> checkForUpdate() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode != 200) {
        debugPrint('[Update] API returned ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      // Strip "v" prefix: "v1.1.0" → "1.1.0"
      final latestVersion = tagName.startsWith('v')
          ? tagName.substring(1)
          : tagName;

      if (latestVersion.isEmpty) return null;

      if (_compareVersions(latestVersion, currentVersion) > 0) {
        return latestVersion;
      }

      return null;
    } catch (e) {
      debugPrint('[Update] Check failed: $e');
      return null;
    }
  }

  /// Returns > 0 if [a] is newer than [b], < 0 if older, 0 if equal.
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.').map(int.tryParse).whereNotNull().toList();
    final bParts = b.split('.').map(int.tryParse).whereNotNull().toList();

    for (var i = 0; i < aParts.length && i < bParts.length; i++) {
      if (aParts[i] != bParts[i]) return aParts[i] - bParts[i];
    }
    return aParts.length - bParts.length;
  }
}

extension _WhereNotNull<T> on Iterable<T?> {
  Iterable<T> whereNotNull() => where((e) => e != null).cast<T>();
}
