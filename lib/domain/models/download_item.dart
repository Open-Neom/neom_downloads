import 'package:neom_core/domain/model/app_media_item.dart';

import 'download_enums.dart';

/// Represents a single download task in the queue with progress tracking.
class SaiaDownloadItem {
  final String id;
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String coverUrl;
  final String sourceUrl;
  DownloadStatus status;
  double progress;
  double speedMBps;
  int bytesReceived;
  int bytesTotal;
  String? filePath;
  String? error;
  DownloadErrorType? errorType;
  DateTime createdAt;
  String? quality;
  String? playlistName;

  SaiaDownloadItem({
    required this.id,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    this.albumName = '',
    this.coverUrl = '',
    required this.sourceUrl,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.speedMBps = 0.0,
    this.bytesReceived = 0,
    this.bytesTotal = 0,
    this.filePath,
    this.error,
    this.errorType,
    DateTime? createdAt,
    this.quality,
    this.playlistName,
  }) : createdAt = createdAt ?? DateTime.now();

  SaiaDownloadItem copyWith({
    String? id,
    String? trackId,
    String? trackName,
    String? artistName,
    String? albumName,
    String? coverUrl,
    String? sourceUrl,
    DownloadStatus? status,
    double? progress,
    double? speedMBps,
    int? bytesReceived,
    int? bytesTotal,
    String? filePath,
    String? error,
    DownloadErrorType? errorType,
    DateTime? createdAt,
    String? quality,
    String? playlistName,
  }) {
    return SaiaDownloadItem(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      trackName: trackName ?? this.trackName,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      coverUrl: coverUrl ?? this.coverUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speedMBps: speedMBps ?? this.speedMBps,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
      errorType: errorType ?? this.errorType,
      createdAt: createdAt ?? this.createdAt,
      quality: quality ?? this.quality,
      playlistName: playlistName ?? this.playlistName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'coverUrl': coverUrl,
      'sourceUrl': sourceUrl,
      'status': status.index,
      'progress': progress,
      'speedMBps': speedMBps,
      'bytesReceived': bytesReceived,
      'bytesTotal': bytesTotal,
      'filePath': filePath,
      'error': error,
      'errorType': errorType?.index,
      'createdAt': createdAt.toIso8601String(),
      'quality': quality,
      'playlistName': playlistName,
    };
  }

  factory SaiaDownloadItem.fromJson(Map<String, dynamic> json) {
    return SaiaDownloadItem(
      id: json['id'] as String? ?? '',
      trackId: json['trackId'] as String? ?? '',
      trackName: json['trackName'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      status: DownloadStatus.values[json['status'] as int? ?? 0],
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      speedMBps: (json['speedMBps'] as num?)?.toDouble() ?? 0.0,
      bytesReceived: json['bytesReceived'] as int? ?? 0,
      bytesTotal: json['bytesTotal'] as int? ?? 0,
      filePath: json['filePath'] as String?,
      error: json['error'] as String?,
      errorType: json['errorType'] != null
          ? DownloadErrorType.values[json['errorType'] as int]
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      quality: json['quality'] as String?,
      playlistName: json['playlistName'] as String?,
    );
  }

  /// Whether this item is currently being processed.
  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.finalizing;

  /// Whether this item completed successfully.
  bool get isDone => status == DownloadStatus.completed;

  /// Whether this item failed.
  bool get isFailed => status == DownloadStatus.failed;

  /// Returns a user-friendly error message based on the error type.
  String get errorMessage {
    switch (errorType) {
      case DownloadErrorType.notFound:
        return 'Track not found or no longer available.';
      case DownloadErrorType.rateLimit:
        return 'Too many requests. Retrying shortly.';
      case DownloadErrorType.network:
        return 'Network error. Check your connection.';
      case DownloadErrorType.permission:
        return 'Storage permission denied.';
      case DownloadErrorType.diskFull:
        return 'Not enough disk space.';
      case DownloadErrorType.cancelled:
        return 'Download cancelled.';
      case DownloadErrorType.unknown:
      case null:
        return error ?? 'An unknown error occurred.';
    }
  }

  /// Create from [AppMediaItem] for queue entry.
  factory SaiaDownloadItem.fromMediaItem(
    AppMediaItem item, {
    String? playlistName,
  }) {
    return SaiaDownloadItem(
      id: '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
      trackId: item.id,
      trackName: item.name,
      artistName: item.ownerName,
      albumName: item.album,
      coverUrl: item.imgUrl,
      sourceUrl: item.url,
      createdAt: DateTime.now(),
      playlistName: playlistName,
    );
  }

  @override
  String toString() => 'SaiaDownloadItem($trackName - $artistName, $status)';
}
