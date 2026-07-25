import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<String?> download(String url, String filename) async {
    final safeName = _sanitize(filename);
    if (safeName.isEmpty) return null;

    try {
      final request = http.Request('GET', Uri.parse(url));
      final streamed = await request.send().timeout(const Duration(minutes: 2));

      if (streamed.statusCode != 200) {
        debugPrint('Download failed: HTTP ${streamed.statusCode}');
        return null;
      }

      final dir = await _downloadDirectory();
      final file = File('${dir.path}/$safeName');
      final sink = file.openWrite();

      try {
        await streamed.stream.pipe(sink);
        await sink.flush();
      } finally {
        await sink.close();
      }

      return file.path;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  static String _sanitize(String name) {
    // Remove or replace characters illegal in filenames across platforms
    final sanitized = name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    // Prevent path traversal
    final cleaned = sanitized.replaceAll(RegExp(r'\.\.'), '_');
    // Trim and limit length
    final trimmed = cleaned.trim();
    if (trimmed.isEmpty || trimmed == '.' || trimmed == '..') {
      return 'wallpaper.jpg';
    }
    // Keep extension but limit total length
    if (trimmed.length > 200) {
      final dot = trimmed.lastIndexOf('.');
      if (dot > 0 && dot < trimmed.length - 1) {
        return '${trimmed.substring(0, 190)}.${trimmed.substring(dot + 1)}';
      }
      return trimmed.substring(0, 200);
    }
    return trimmed;
  }

  static Future<Directory> _downloadDirectory() async {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      final dir = await getApplicationDocumentsDirectory();
      return Directory(dir.path);
    }

    // Desktop: use platform-appropriate Downloads folder
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null) {
        final downloads = Directory('$home\\Downloads');
        if (downloads.existsSync()) return downloads;
      }
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final downloads = Directory('$home/Downloads');
        if (downloads.existsSync()) return downloads;
      }
    }

    // Fallback
    final dir = await getApplicationDocumentsDirectory();
    return Directory(dir.path);
  }
}
