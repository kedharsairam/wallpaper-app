import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages download progress and completion notifications.
///
/// Uses a single ongoing notification for the current download and
/// a completion notification when done.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'wallkraft_downloads';
  static const _channelName = 'Downloads';
  static const _channelDesc = 'Wallpaper download progress and completion';
  static const _progressNotificationId = 1000;
  static const _completionNotificationId = 1001;

  bool _initialized = false;

  /// Initialize the notification plugin.
  /// Call once at app startup.
  Future<void> init() async {
    if (_initialized) return;
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      await _plugin.initialize(settings: initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Init failed: $e');
    }
  }

  /// Create the download notification channel (called before showing).
  Future<void> _ensureChannel() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.low,
            playSound: false,
            enableVibration: false,
          ),
        );
      }
    } catch (e) {
      debugPrint('[NotificationService] Channel creation failed: $e');
    }
  }

  /// Show or update a download progress notification.
  Future<void> showProgress({
    required int progress,
    required String wallpaperId,
    bool isIndeterminate = false,
  }) async {
    await _ensureChannel();
    try {
      final androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.low,
        priority: Priority.defaultPriority,
        progress: isIndeterminate ? 0 : progress,
        maxProgress: isIndeterminate ? 0 : 100,
        indeterminate: isIndeterminate,
        onlyAlertOnce: true,
        showProgress: true,
        playSound: false,
        enableVibration: false,
        ongoing: true,
        autoCancel: false,
      );
      await _plugin.show(
        id: _progressNotificationId,
        title: 'Downloading…',
        body: 'Wallpaper $wallpaperId',
        notificationDetails: NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('[NotificationService] Show progress failed: $e');
    }
  }

  /// Show a download completion notification.
  Future<void> showComplete({
    required String wallpaperId,
    required String filePath,
  }) async {
    try {
      // Cancel the progress notification.
      await _plugin.cancel(id: _progressNotificationId);

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
        enableVibration: true,
        ongoing: false,
        autoCancel: true,
      );
      await _plugin.show(
        id: _completionNotificationId,
        title: 'Download complete',
        body: wallpaperId,
        notificationDetails: const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('[NotificationService] Show complete failed: $e');
    }
  }

  /// Show a download failure notification.
  Future<void> showError({
    required String wallpaperId,
    required String error,
  }) async {
    try {
      await _plugin.cancel(id: _progressNotificationId);
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: true,
        enableVibration: true,
        ongoing: false,
        autoCancel: true,
      );
      await _plugin.show(
        id: _completionNotificationId,
        title: 'Download failed: $wallpaperId',
        body: error,
        notificationDetails: const NotificationDetails(android: androidDetails),
      );
    } catch (e) {
      debugPrint('[NotificationService] Show error failed: $e');
    }
  }
}
