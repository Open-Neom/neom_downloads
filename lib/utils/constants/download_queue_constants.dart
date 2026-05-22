/// Constants for the download queue system.
class DownloadQueueConstants {
  DownloadQueueConstants._();

  static const int defaultMaxConcurrent = 3;
  static const int maxRetries = 3;
  static const int maxFilenameLength = 200;
  static const String downloadHistoryBox = 'download_history';
  static const String downloadQueueBox = 'download_queue';
  static const String historyItemsKey = 'history_items';
  static const String queueItemsKey = 'queue_items';

  /// Characters not allowed in filenames.
  static RegExp invalidCharsRegex = RegExp(r'[\.\\\*\:\"\?#/;\|]');

  /// Audio file extensions recognized by the system.
  static const List<String> audioExtensions = [
    '.flac', '.m4a', '.mp3', '.opus', '.ogg', '.wav', '.aac',
  ];

  /// Default download file extension.
  static const String defaultExtension = '.m4a';

  /// Notification channel ID for download progress.
  static const String notificationChannelId = 'download_progress';
  static const String notificationChannelName = 'Download Progress';
  static const String notificationChannelDesc = 'Shows download progress for media files';
}
