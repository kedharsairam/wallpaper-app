import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as client;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  static Future<String?> download(String url, String filename) async {
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Download failed: ${response.statusCode}');
      }

      final dir = await _downloadDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(response.bodyBytes);

      return file.path;
    } catch (e) {
      debugPrint('Download error: $e');
      return null;
    }
  }

  static Future<Directory> _downloadDirectory() async {
    // Use app documents directory on mobile (always writable, no permissions needed).
    // On desktop, use the system Downloads folder.
    if (!kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        final dir = await getApplicationDocumentsDirectory();
        return Directory(dir.path);
      }
    }

    // Desktop fallback
    final home = Platform.environment['USERPROFILE'] ?? '';
    if (home.isNotEmpty) {
      final downloads = Directory('$home\\Downloads');
      if (downloads.existsSync()) return downloads;
    }

    // Last resort
    final dir = await getApplicationDocumentsDirectory();
    return Directory(dir.path);
  }
}
