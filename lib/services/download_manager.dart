import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/wallpaper.dart';
import 'database.dart';
import 'notification_service.dart';

class DownloadProgress {
  final String id;
  final double progress;
  final String? error;
  const DownloadProgress({required this.id, this.progress = 0.0, this.error});
  bool get isComplete => progress >= 1.0;
  bool get hasError => error != null;
}

/// Manages wallpaper downloads with deduplication, progress reporting,
/// and cleanup on failure.
class DownloadManager {
  DownloadManager._();
  static final DownloadManager instance = DownloadManager._();

  final Map<String, Completer<String>> _inFlight = {};
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 30);

  bool isDownloading(String wallpaperId) => _inFlight.containsKey(wallpaperId);

  /// Downloads a wallpaper image and saves it to the app documents directory.
  ///
  /// Returns the local file path. If the file is already cached, returns
  /// immediately. If a download for the same [wallpaper] is already in
  /// progress, awaits that instead of starting a second download.
  Future<String> download(
    Wallpaper wallpaper, {
    void Function(DownloadProgress progress)? onProgress,
  }) async {
    final id = wallpaper.id;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'wallkraft-$id.jpg';
    final file = File('${dir.path}/$fileName');

    // Already cached on disk.
    if (await file.exists()) {
      onProgress?.call(DownloadProgress(id: id, progress: 1.0));
      return file.path;
    }

    // Already downloading — join the in-flight request.
    if (_inFlight.containsKey(id)) {
      return _inFlight[id]!.future;
    }

    final completer = Completer<String>();
    _inFlight[id] = completer;

    try {
      NotificationService.instance.showProgress(
        progress: 0,
        wallpaperId: id,
        isIndeterminate: true,
      );

      final request = await _client.getUrl(Uri.parse(wallpaper.path));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw HttpException('Download failed: HTTP ${response.statusCode}',
            uri: Uri.parse(wallpaper.path));
      }

      final totalBytes = response.contentLength;
      var receivedBytes = 0;
      final sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final p = receivedBytes / totalBytes;
          final percent = (p * 100).round();
          NotificationService.instance.showProgress(
            progress: percent,
            wallpaperId: id,
          );
          onProgress?.call(DownloadProgress(id: id, progress: p));
        }
      }

      await sink.close();

      // Validate the downloaded file.
      if (!await file.exists() || await file.length() == 0) {
        throw Exception('Downloaded file is empty or missing');
      }

      await WallKraftDatabase.recordDownload(id, file.path);

      NotificationService.instance.showComplete(
        wallpaperId: id,
        filePath: file.path,
      );

      onProgress?.call(DownloadProgress(id: id, progress: 1.0));
      completer.complete(file.path);
      return file.path;
    } catch (e) {
      // Clean up partial file on error.
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint('[DownloadManager] Cleanup failed: $e');
      }

      NotificationService.instance.showError(
        wallpaperId: id,
        error: e.toString(),
      );

      onProgress?.call(DownloadProgress(id: id, error: e.toString()));
      completer.completeError(e);
      rethrow;
    } finally {
      _inFlight.remove(id);
    }
  }

  Future<String?> getExistingPath(String id) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/wallkraft-$id.jpg');
      if (await file.exists()) return file.path;
    } catch (e) {
      debugPrint('[DownloadManager] getExistingPath failed: $e');
    }
    return null;
  }
}
