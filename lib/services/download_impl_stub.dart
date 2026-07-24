/// Stub implementation — throws on unsupported platforms.
class DownloadService {
  static String? _lastDownloadPath;

  static String? get lastDownloadPath => _lastDownloadPath;

  static Future<String?> download(String url, String filename) async {
    throw UnsupportedError('Download not supported on this platform');
  }
}
