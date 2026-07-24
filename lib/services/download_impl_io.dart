import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Mobile/desktop implementation — downloads to app documents directory.
class DownloadService {
  static String? _lastDownloadPath;

  static String? get lastDownloadPath => _lastDownloadPath;

  static Future<String?> download(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(response.bodyBytes);

    _lastDownloadPath = file.path;
    return file.path;
  }
}
