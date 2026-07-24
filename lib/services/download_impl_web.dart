import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'package:http/http.dart' as http;

/// Web implementation — fetches the image bytes and triggers a browser download.
class DownloadService {
  static String? _lastDownloadPath;

  static String? get lastDownloadPath => _lastDownloadPath;

  static Future<String?> download(String url, String filename) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Download failed: ${response.statusCode}');
    }

    final bytes = response.bodyBytes;
    final data = bytes.buffer.toJS;
    final blob = web.Blob([data].toJS, web.BlobPropertyBag(type: 'image/jpeg'));
    final objectUrl = web.URL.createObjectURL(blob);

    final anchor = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = filename
      ..style.display = 'none';

    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(objectUrl);

    _lastDownloadPath = filename;
    return filename;
  }
}
