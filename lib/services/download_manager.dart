import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/wallpaper.dart';
import 'database.dart';

/// Tracks download progress for a single wallpaper.
class DownloadProgress {
  final String id;
  final double progress; // 0.0 to 1.0
  final String? error;

  const DownloadProgress({
    required this.id,
    this.progress = 0.0,
    this.error,
  });

  bool get isComplete => progress >= 1.0;
  bool get hasError => error != null;
}

/// Singleton download manager that deduplicates in-flight downloads.
///
/// Ensures that the same wallpaper is never downloaded concurrently,
/// even if multiple screens or callbacks request it simultaneously.
class DownloadManager {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  final Map<String, Completer<String>> _inFlight = {};

  /// Whether a download for [wallpaperId] is currently in progress.
  bool isDownloading(String wallpaperId) => _inFlight.containsKey(wallpaperId);

  /// Downloads a wallpaper, returning the local file path.
  ///
  /// If the file already exists, returns immediately.
  /// If a download is already in progress for the same [wallpaperId],
  /// returns the same future without starting a second download.
  ///
  /// [onProgress] is called with 0.0 → 1.0 as bytes arrive.
  Future<String> download(
    Wallpaper wallpaper, {
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final id = wallpaper.id;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'wallkraft-$id.jpg';
    final file = File('${dir.path}/$fileName');

    // Already on disk — immediate return
    if (await file.exists()) {
      onProgress?.call(DownloadProgress(id: id, progress: 1.0));
      return file.path;
    }

    // Already in-flight — join the existing future
    if (_inFlight.containsKey(id)) {
      return _inFlight[id]!.future;
    }

    final completer = Completer<String>();
    _inFlight[id] = completer;

    try {
      final request = await HttpClient().getUrl(Uri.parse(wallpaper.path));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException(
          'Download failed: HTTP ${response.statusCode}',
          uri: Uri.parse(wallpaper.path),
        );
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final p = receivedBytes / totalBytes;
          onProgress?.call(DownloadProgress(id: id, progress: p));
        }
      }

      await sink.close();

      // Verify the file was fully written
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Downloaded file is empty or missing');
      }

      await WallKraftDatabase.recordDownload(id, file.path);

      onProgress?.call(DownloadProgress(id: id, progress: 1.0));
      completer.complete(file.path);
      return file.path;
    } catch (e) {
      onProgress?.call(DownloadProgress(id: id, error: e.toString()));
      completer.completeError(e);
      rethrow;
    } finally {
      _inFlight.remove(id);
    }
  }

  /// Returns the local file path if the wallpaper has already been downloaded.
  Future<String?> getExistingPath(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/wallkraft-$id.jpg');
    if (await file.exists()) return file.path;
    return null;
  }
}
