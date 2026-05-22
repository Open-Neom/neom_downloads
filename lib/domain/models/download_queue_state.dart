import 'download_history_item.dart';

/// Holds the indexed download history for O(1) lookups.
///
/// Three index maps are maintained for fast deduplication:
/// - By trackId (primary key)
/// - By ISRC (international standard recording code)
/// - By trackName+artistName composite key (fuzzy fallback)
class SaiaDownloadHistoryState {
  final List<SaiaDownloadHistoryItem> items;
  final Map<String, SaiaDownloadHistoryItem> _byTrackId;
  final Map<String, SaiaDownloadHistoryItem> _byIsrc;
  final Map<String, SaiaDownloadHistoryItem> _byTrackArtistKey;

  SaiaDownloadHistoryState({List<SaiaDownloadHistoryItem>? items})
      : items = items ?? [],
        _byTrackId = {},
        _byIsrc = {},
        _byTrackArtistKey = {} {
    for (final item in this.items) {
      _byTrackId[item.trackId] = item;
      if (item.isrc != null && item.isrc!.isNotEmpty) {
        _byIsrc[item.isrc!] = item;
      }
      _byTrackArtistKey[item.trackArtistKey] = item;
    }
  }

  /// Whether a track with this ID has been downloaded.
  bool isDownloaded(String trackId) => _byTrackId.containsKey(trackId);

  /// Whether a track with this ISRC has been downloaded.
  bool isDownloadedByIsrc(String isrc) => _byIsrc.containsKey(isrc);

  /// Get history item by track ID, or null.
  SaiaDownloadHistoryItem? getByTrackId(String trackId) =>
      _byTrackId[trackId];

  /// Get history item by ISRC, or null.
  SaiaDownloadHistoryItem? getByIsrc(String isrc) => _byIsrc[isrc];

  /// Find by track name + artist name composite key.
  SaiaDownloadHistoryItem? findByTrackAndArtist(
    String trackName,
    String artistName,
  ) {
    final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
    return _byTrackArtistKey[key];
  }

  /// Checks if a track is downloaded by any matching strategy.
  ///
  /// Tries trackId first, then ISRC, then trackName+artistName composite.
  bool isDuplicate({
    String? trackId,
    String? isrc,
    String? trackName,
    String? artistName,
  }) {
    if (trackId != null && _byTrackId.containsKey(trackId)) return true;
    if (isrc != null && isrc.isNotEmpty && _byIsrc.containsKey(isrc)) {
      return true;
    }
    if (trackName != null && artistName != null) {
      final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
      if (_byTrackArtistKey.containsKey(key)) return true;
    }
    return false;
  }

  /// Number of downloaded items.
  int get length => items.length;

  /// Whether the history is empty.
  bool get isEmpty => items.isEmpty;
}
