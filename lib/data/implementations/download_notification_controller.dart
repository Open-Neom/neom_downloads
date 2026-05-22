import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';

import '../../domain/models/download_item.dart';
import '../../utils/constants/download_queue_constants.dart';

/// Manages system notifications for download progress and completion.
///
/// Uses flutter_local_notifications to show progress bars, completion,
/// and failure notifications for the download queue.
class SaiaDownloadNotificationController {
  SaiaDownloadNotificationController._();

  static final SaiaDownloadNotificationController _instance =
      SaiaDownloadNotificationController._();

  static SaiaDownloadNotificationController get instance => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Notification IDs: use item hashCode for per-item, fixed IDs for aggregate.
  static const int _queueCompleteNotificationId = 99000;

  // ========== Initialization ==========

  /// Initialize the notification plugin. Call once at app startup.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _plugin.initialize(settings);
      _initialized = true;
      AppConfig.logger.i('Download notification controller initialized');
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'notificationInit');
    }
  }

  // ========== Notification Methods ==========

  /// Show a progress notification for an active download.
  Future<void> showProgress(SaiaDownloadItem item) async {
    if (!_initialized) return;

    try {
      final progressPercent = (item.progress * 100).toInt();
      final speedText = item.speedMBps > 0
          ? ' - ${item.speedMBps.toStringAsFixed(1)} MB/s'
          : '';

      final androidDetails = AndroidNotificationDetails(
        DownloadQueueConstants.notificationChannelId,
        DownloadQueueConstants.notificationChannelName,
        channelDescription: DownloadQueueConstants.notificationChannelDesc,
        importance: Importance.low,
        priority: Priority.low,
        showProgress: true,
        maxProgress: 100,
        progress: progressPercent,
        ongoing: true,
        onlyAlertOnce: true,
        showWhen: false,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        item.id.hashCode,
        'Downloading ${item.trackName}',
        '$progressPercent%$speedText',
        details,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'showProgress');
    }
  }

  /// Show a completion notification for a single download.
  Future<void> showComplete(SaiaDownloadItem item) async {
    if (!_initialized) return;

    try {
      // Cancel the progress notification first
      await _plugin.cancel(item.id.hashCode);

      final androidDetails = AndroidNotificationDetails(
        DownloadQueueConstants.notificationChannelId,
        DownloadQueueConstants.notificationChannelName,
        channelDescription: DownloadQueueConstants.notificationChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        item.id.hashCode,
        'Download complete',
        '${item.trackName} - ${item.artistName}',
        details,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'showComplete');
    }
  }

  /// Show a notification that the entire download queue has completed.
  Future<void> showQueueComplete(int totalDownloaded) async {
    if (!_initialized) return;

    try {
      final androidDetails = AndroidNotificationDetails(
        DownloadQueueConstants.notificationChannelId,
        DownloadQueueConstants.notificationChannelName,
        channelDescription: DownloadQueueConstants.notificationChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        _queueCompleteNotificationId,
        'All downloads complete',
        '$totalDownloaded tracks downloaded successfully',
        details,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'showQueueComplete');
    }
  }

  /// Show a failure notification for a download.
  Future<void> showFailed(SaiaDownloadItem item) async {
    if (!_initialized) return;

    try {
      // Cancel any existing progress notification
      await _plugin.cancel(item.id.hashCode);

      final androidDetails = AndroidNotificationDetails(
        DownloadQueueConstants.notificationChannelId,
        DownloadQueueConstants.notificationChannelName,
        channelDescription: DownloadQueueConstants.notificationChannelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );

      final details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        item.id.hashCode,
        'Download failed',
        '${item.trackName}: ${item.errorMessage}',
        details,
      );
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'showFailed');
    }
  }

  /// Cancel a specific notification by item ID.
  Future<void> cancelNotification(String itemId) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(itemId.hashCode);
    } catch (_) {}
  }

  /// Cancel all download notifications.
  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
