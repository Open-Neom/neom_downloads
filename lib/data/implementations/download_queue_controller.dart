import 'dart:async';
import 'dart:math';

import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:neom_core/app_config.dart';
import 'package:neom_core/utils/neom_error_logger.dart';
import 'package:sint/sint.dart';

import '../../domain/models/download_enums.dart';
import '../../domain/models/download_history_item.dart';
import '../../domain/models/download_item.dart';
import '../../utils/constants/download_queue_constants.dart';

/// Main download queue orchestration engine.
///
/// Manages concurrent downloads, retry logic, duplicate detection,
/// history persistence, and filename/folder organization.
class SaiaDownloadQueueController extends SintController {
  // ========== State ==========

  final RxList<SaiaDownloadItem> queue = <SaiaDownloadItem>[].obs;
  final RxList<SaiaDownloadHistoryItem> history = <SaiaDownloadHistoryItem>[].obs;
  final RxInt activeDownloads = 0.obs;
  final RxBool isPaused = false.obs;

  // ========== Config ==========

  int maxConcurrentDownloads = DownloadQueueConstants.defaultMaxConcurrent;

  // ========== Multi-index lookup maps for history ==========

  final Map<String, SaiaDownloadHistoryItem> _byTrackId = {};
  final Map<String, SaiaDownloadHistoryItem> _byIsrc = {};
  final Map<String, SaiaDownloadHistoryItem> _byTrackArtistKey = {};

  // ========== Retry tracking ==========

  final Map<String, int> _retryCount = {};

  // ========== Active HTTP clients (for cancellation) ==========

  final Map<String, http.Client> _activeClients = {};

  // ========== Lifecycle ==========

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  @override
  void onClose() {
    for (final client in _activeClients.values) {
      client.close();
    }
    _activeClients.clear();
    super.onClose();
  }

  // ========== Queue Management ==========

  /// Add a single item to the queue. Returns false if a duplicate is detected.
  Future<bool> enqueue(SaiaDownloadItem item) async {
    if (isDuplicate(item)) {
      AppConfig.logger.w('Duplicate detected for ${item.trackName}, skipping enqueue');
      return false;
    }
    queue.add(item);
    AppConfig.logger.i('Enqueued: ${item.trackName} - ${item.artistName}');
    _processQueue();
    return true;
  }

  /// Add a batch of items (album/playlist download).
  /// Returns the number of items actually added (excluding duplicates).
  Future<int> enqueueBatch(List<SaiaDownloadItem> items) async {
    int added = 0;
    for (final item in items) {
      if (!isDuplicate(item)) {
        queue.add(item);
        added++;
      }
    }
    if (added > 0) {
      AppConfig.logger.i('Enqueued batch: $added of ${items.length} items');
      _processQueue();
    }
    return added;
  }

  /// Cancel a specific download by item ID.
  void cancel(String itemId) {
    final index = queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;

    final item = queue[index];
    if (item.status == DownloadStatus.downloading) {
      _activeClients[itemId]?.close();
      _activeClients.remove(itemId);
      activeDownloads.value = max(0, activeDownloads.value - 1);
    }

    queue.removeAt(index);
    _retryCount.remove(itemId);
    AppConfig.logger.i('Cancelled download: ${item.trackName}');
    _processQueue();
  }

  /// Cancel all queued and downloading items.
  void cancelAll() {
    for (final client in _activeClients.values) {
      client.close();
    }
    _activeClients.clear();
    activeDownloads.value = 0;
    _retryCount.clear();

    queue.removeWhere((item) =>
        item.status == DownloadStatus.queued ||
        item.status == DownloadStatus.downloading);
    AppConfig.logger.i('Cancelled all downloads');
  }

  /// Toggle pause/resume for queue processing.
  void togglePause() {
    isPaused.value = !isPaused.value;
    AppConfig.logger.i('Queue ${isPaused.value ? "paused" : "resumed"}');
    if (!isPaused.value) {
      _processQueue();
    }
  }

  /// Retry all failed downloads.
  void retryFailed() {
    for (final item in queue) {
      if (item.status == DownloadStatus.failed) {
        item.status = DownloadStatus.queued;
        item.progress = 0.0;
        item.error = null;
        item.errorType = null;
        _retryCount.remove(item.id);
      }
    }
    queue.refresh();
    AppConfig.logger.i('Retrying all failed downloads');
    _processQueue();
  }

  /// Remove completed items from the queue list.
  void clearCompleted() {
    queue.removeWhere((item) => item.status == DownloadStatus.completed);
    AppConfig.logger.i('Cleared completed downloads from queue');
  }

  // ========== Queue Processing ==========

  void _processQueue() {
    if (isPaused.value) return;

    while (activeDownloads.value < maxConcurrentDownloads) {
      final next = queue.cast<SaiaDownloadItem?>().firstWhere(
        (i) => i!.status == DownloadStatus.queued,
        orElse: () => null,
      );
      if (next == null) break;
      activeDownloads.value++;
      _downloadItem(next);
    }
  }

  Future<void> _downloadItem(SaiaDownloadItem item) async {
    _updateItemStatus(item.id, DownloadStatus.downloading);
    final stopwatch = Stopwatch()..start();

    final client = http.Client();
    _activeClients[item.id] = client;

    try {
      final request = http.Request('GET', Uri.parse(item.sourceUrl));
      final response = await client.send(request);

      if (response.statusCode == 404) {
        _handleDownloadError(item, 'Source not found', DownloadErrorType.notFound);
        return;
      }
      if (response.statusCode == 429) {
        _handleDownloadError(item, 'Rate limited', DownloadErrorType.rateLimit);
        return;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _handleDownloadError(item, 'HTTP ${response.statusCode}', DownloadErrorType.network);
        return;
      }

      final totalBytes = response.contentLength ?? 0;
      item.bytesTotal = totalBytes;

      final bytes = <int>[];
      int received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        item.bytesReceived = received;

        // Calculate progress
        if (totalBytes > 0) {
          item.progress = received / totalBytes;
        }

        // Calculate speed (MB/s)
        final elapsedSec = stopwatch.elapsedMilliseconds / 1000.0;
        if (elapsedSec > 0) {
          item.speedMBps = (received / (1024 * 1024)) / elapsedSec;
        }

        // Notify UI periodically (every ~50KB to avoid excessive updates)
        if (received % 51200 < chunk.length) {
          queue.refresh();
        }
      }

      stopwatch.stop();

      // Finalizing
      _updateItemStatus(item.id, DownloadStatus.finalizing);

      // Mark completed
      item.bytesReceived = received;
      item.progress = 1.0;
      item.speedMBps = 0.0;
      _updateItemStatus(item.id, DownloadStatus.completed);

      // Add to history
      await _addToHistory(item, received);

      AppConfig.logger.i(
        'Download complete: ${item.trackName} '
        '(${(received / (1024 * 1024)).toStringAsFixed(1)} MB in '
        '${stopwatch.elapsed.inSeconds}s)',
      );
    } catch (e, st) {
      final errorType = _classifyError(e);
      _handleDownloadError(item, e.toString(), errorType);
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'downloadItem');
    } finally {
      _activeClients.remove(item.id);
      client.close();
      activeDownloads.value = max(0, activeDownloads.value - 1);
      _processQueue();
    }
  }

  // ========== Error Handling ==========

  void _handleDownloadError(
    SaiaDownloadItem item,
    String errorMsg,
    DownloadErrorType errorType,
  ) {
    AppConfig.logger.e('Download error for ${item.trackName}: $errorMsg');

    // Retryable errors: network and rate limit
    if (errorType == DownloadErrorType.network ||
        errorType == DownloadErrorType.rateLimit) {
      final count = (_retryCount[item.id] ?? 0) + 1;
      _retryCount[item.id] = count;

      if (count <= DownloadQueueConstants.maxRetries) {
        AppConfig.logger.i('Retry $count/${DownloadQueueConstants.maxRetries} '
            'for ${item.trackName}');
        _scheduleRetry(item, count);
        return;
      }
    }

    // Non-retryable or exhausted retries
    item.status = DownloadStatus.failed;
    item.error = errorMsg;
    item.errorType = errorType;
    queue.refresh();
  }

  void _scheduleRetry(SaiaDownloadItem item, int attemptCount) {
    final delaySec = pow(2, attemptCount).toInt(); // 2, 4, 8 seconds
    item.status = DownloadStatus.queued;
    item.progress = 0.0;
    item.bytesReceived = 0;
    queue.refresh();

    Future.delayed(Duration(seconds: delaySec), () {
      if (queue.contains(item) && item.status == DownloadStatus.queued) {
        _processQueue();
      }
    });
  }

  DownloadErrorType _classifyError(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('socketexception') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('handshake')) {
      return DownloadErrorType.network;
    }
    if (msg.contains('permission') || msg.contains('access denied')) {
      return DownloadErrorType.permission;
    }
    if (msg.contains('no space') || msg.contains('disk full')) {
      return DownloadErrorType.diskFull;
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return DownloadErrorType.notFound;
    }
    return DownloadErrorType.unknown;
  }

  // ========== Duplicate Detection ==========

  /// Checks if an item is already in the active queue or download history.
  bool isDuplicate(SaiaDownloadItem item) {
    // Check active queue (exclude failed items which can be retried)
    final inQueue = queue.any((q) =>
        q.trackId == item.trackId &&
        q.status != DownloadStatus.failed &&
        q.status != DownloadStatus.skipped);
    if (inQueue) return true;

    // Check history by trackId
    if (_byTrackId.containsKey(item.trackId)) return true;

    // Check history by trackName + artistName combo
    final key = _trackArtistKey(item.trackName, item.artistName);
    if (_byTrackArtistKey.containsKey(key)) return true;

    return false;
  }

  /// Check if a track has been downloaded by its track ID.
  bool isDownloaded(String trackId) => _byTrackId.containsKey(trackId);

  /// Check if a track has been downloaded by ISRC.
  bool isDownloadedByIsrc(String isrc) => _byIsrc.containsKey(isrc);

  String _trackArtistKey(String track, String artist) =>
      '${track.toLowerCase().trim()}|${artist.toLowerCase().trim()}';

  // ========== History Management ==========

  Future<void> _loadHistory() async {
    try {
      final box = await Hive.openBox(DownloadQueueConstants.downloadHistoryBox);
      final raw = box.get(DownloadQueueConstants.historyItemsKey);

      if (raw != null && raw is List) {
        for (final entry in raw) {
          if (entry is Map) {
            try {
              final item = SaiaDownloadHistoryItem.fromJson(
                Map<String, dynamic>.from(entry),
              );
              history.add(item);
              _indexHistoryItem(item);
            } catch (e) {
              AppConfig.logger.w('Skipping corrupt history entry: $e');
            }
          }
        }
        AppConfig.logger.i('Loaded ${history.length} download history items');
      }
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'loadHistory');
    }
  }

  Future<void> _addToHistory(SaiaDownloadItem item, int fileSize) async {
    final historyItem = SaiaDownloadHistoryItem(
      id: item.trackId,
      trackName: item.trackName,
      artistName: item.artistName,
      albumName: item.albumName,
      filePath: item.filePath ?? '',
      quality: item.quality ?? '320 kbps',
      fileSizeBytes: fileSize,
    );

    history.add(historyItem);
    _indexHistoryItem(historyItem);

    await _persistHistory();
  }

  void _indexHistoryItem(SaiaDownloadHistoryItem item) {
    _byTrackId[item.id] = item;
    if (item.isrc != null && item.isrc!.isNotEmpty) {
      _byIsrc[item.isrc!] = item;
    }
    final key = _trackArtistKey(item.trackName, item.artistName);
    _byTrackArtistKey[key] = item;
  }

  void _deindexHistoryItem(SaiaDownloadHistoryItem item) {
    _byTrackId.remove(item.id);
    if (item.isrc != null && item.isrc!.isNotEmpty) {
      _byIsrc.remove(item.isrc!);
    }
    final key = _trackArtistKey(item.trackName, item.artistName);
    _byTrackArtistKey.remove(key);
  }

  Future<void> removeFromHistory(String id) async {
    final index = history.indexWhere((h) => h.id == id);
    if (index == -1) return;

    final item = history[index];
    _deindexHistoryItem(item);
    history.removeAt(index);
    await _persistHistory();
    AppConfig.logger.i('Removed from history: ${item.trackName}');
  }

  Future<void> clearHistory() async {
    history.clear();
    _byTrackId.clear();
    _byIsrc.clear();
    _byTrackArtistKey.clear();
    await _persistHistory();
    AppConfig.logger.i('Download history cleared');
  }

  Future<void> _persistHistory() async {
    try {
      final box = await Hive.openBox(DownloadQueueConstants.downloadHistoryBox);
      final serialized = history.map((h) => h.toJson()).toList();
      await box.put(DownloadQueueConstants.historyItemsKey, serialized);
    } catch (e, st) {
      NeomErrorLogger.recordError(e, st,
          module: 'neom_downloads', operation: 'persistHistory');
    }
  }

  // ========== Filename Generation ==========

  /// Generate a sanitized filename for a download item.
  ///
  /// [filenameFormat] controls naming order:
  /// - 0: "Title - Artist.m4a"
  /// - 1: "Artist - Title.m4a"
  /// - 2: "Title.m4a"
  String generateFilename(SaiaDownloadItem item, {int filenameFormat = 0}) {
    String name;
    switch (filenameFormat) {
      case 0:
        name = '${item.trackName} - ${item.artistName}';
        break;
      case 1:
        name = '${item.artistName} - ${item.trackName}';
        break;
      default:
        name = item.trackName;
    }

    // Sanitize: remove invalid characters and collapse double spaces
    name = name
        .replaceAll(DownloadQueueConstants.invalidCharsRegex, '')
        .replaceAll('  ', ' ')
        .trim();

    // Enforce max length
    if (name.length > DownloadQueueConstants.maxFilenameLength) {
      name = name.substring(0, DownloadQueueConstants.maxFilenameLength);
    }

    return '$name${DownloadQueueConstants.defaultExtension}';
  }

  // ========== Folder Organization ==========

  /// Build the folder path for a download item based on the organization strategy.
  String organizePath(
    String basePath,
    SaiaDownloadItem item, {
    FolderOrganization org = FolderOrganization.flat,
  }) {
    switch (org) {
      case FolderOrganization.flat:
        return basePath;
      case FolderOrganization.artist:
        return '$basePath/${_sanitizeFolderName(item.artistName)}';
      case FolderOrganization.artistAlbum:
        return '$basePath/${_sanitizeFolderName(item.artistName)}'
            '/${_sanitizeFolderName(item.albumName)}';
    }
  }

  String _sanitizeFolderName(String name) {
    if (name.isEmpty) return 'Unknown';
    return name
        .replaceAll(DownloadQueueConstants.invalidCharsRegex, '')
        .replaceAll('  ', ' ')
        .trim();
  }

  // ========== Item Update Helpers ==========

  void _updateItemStatus(String itemId, DownloadStatus status) {
    final index = queue.indexWhere((i) => i.id == itemId);
    if (index == -1) return;
    queue[index].status = status;
    queue.refresh();
  }

  // ========== Getters ==========

  List<SaiaDownloadItem> get downloading =>
      queue.where((i) => i.status == DownloadStatus.downloading).toList();

  List<SaiaDownloadItem> get queued =>
      queue.where((i) => i.status == DownloadStatus.queued).toList();

  List<SaiaDownloadItem> get completed =>
      queue.where((i) => i.status == DownloadStatus.completed).toList();

  List<SaiaDownloadItem> get failed =>
      queue.where((i) => i.status == DownloadStatus.failed).toList();

  int get totalInQueue => queue.length;

  /// Overall weighted progress across all active and queued downloads.
  double get overallProgress {
    final activeItems = queue.where((i) =>
        i.status == DownloadStatus.downloading ||
        i.status == DownloadStatus.queued ||
        i.status == DownloadStatus.finalizing);
    if (activeItems.isEmpty) return 1.0;

    double totalProgress = 0.0;
    for (final item in activeItems) {
      totalProgress += item.progress;
    }
    return totalProgress / activeItems.length;
  }

  /// Total bytes received across all currently downloading items.
  int get totalBytesReceived =>
      downloading.fold(0, (sum, item) => sum + item.bytesReceived);

  /// Total bytes expected across all currently downloading items.
  int get totalBytesExpected =>
      downloading.fold(0, (sum, item) => sum + item.bytesTotal);
}
