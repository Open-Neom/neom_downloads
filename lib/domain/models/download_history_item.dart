/// Represents a completed download record for history tracking.
class SaiaDownloadHistoryItem {
  final String id;
  final String trackId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String coverUrl;
  final String filePath;
  final String format;
  final String? isrc;
  final DateTime downloadedAt;
  final String quality;
  final int? bitDepth;
  final int? sampleRate;
  final String? genre;
  final String? composer;
  final int fileSizeBytes;

  SaiaDownloadHistoryItem({
    required this.id,
    required this.trackId,
    required this.trackName,
    required this.artistName,
    this.albumName = '',
    this.coverUrl = '',
    required this.filePath,
    this.format = 'm4a',
    this.isrc,
    DateTime? downloadedAt,
    this.quality = '320 kbps',
    this.bitDepth,
    this.sampleRate,
    this.genre,
    this.composer,
    this.fileSizeBytes = 0,
  }) : downloadedAt = downloadedAt ?? DateTime.now();

  /// Generates lookup key for deduplication: "trackname|artistname" lowercase.
  String get trackArtistKey =>
      '${trackName.toLowerCase()}|${artistName.toLowerCase()}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackId': trackId,
      'trackName': trackName,
      'artistName': artistName,
      'albumName': albumName,
      'coverUrl': coverUrl,
      'filePath': filePath,
      'format': format,
      'isrc': isrc,
      'downloadedAt': downloadedAt.toIso8601String(),
      'quality': quality,
      'bitDepth': bitDepth,
      'sampleRate': sampleRate,
      'genre': genre,
      'composer': composer,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory SaiaDownloadHistoryItem.fromJson(Map<String, dynamic> json) {
    return SaiaDownloadHistoryItem(
      id: json['id'] as String? ?? '',
      trackId: json['trackId'] as String? ?? '',
      trackName: json['trackName'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      filePath: json['filePath'] as String? ?? '',
      format: json['format'] as String? ?? 'm4a',
      isrc: json['isrc'] as String?,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : DateTime.now(),
      quality: json['quality'] as String? ?? '320 kbps',
      bitDepth: json['bitDepth'] as int?,
      sampleRate: json['sampleRate'] as int?,
      genre: json['genre'] as String?,
      composer: json['composer'] as String?,
      fileSizeBytes: json['fileSizeBytes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'track_id': trackId,
      'track_name': trackName,
      'artist_name': artistName,
      'album_name': albumName,
      'cover_url': coverUrl,
      'file_path': filePath,
      'format': format,
      'isrc': isrc,
      'downloaded_at': downloadedAt.millisecondsSinceEpoch,
      'quality': quality,
      'bit_depth': bitDepth,
      'sample_rate': sampleRate,
      'genre': genre,
      'composer': composer,
      'file_size_bytes': fileSizeBytes,
    };
  }

  factory SaiaDownloadHistoryItem.fromMap(Map<String, dynamic> map) {
    return SaiaDownloadHistoryItem(
      id: map['id'] as String? ?? '',
      trackId: map['track_id'] as String? ?? '',
      trackName: map['track_name'] as String? ?? '',
      artistName: map['artist_name'] as String? ?? '',
      albumName: map['album_name'] as String? ?? '',
      coverUrl: map['cover_url'] as String? ?? '',
      filePath: map['file_path'] as String? ?? '',
      format: map['format'] as String? ?? 'm4a',
      isrc: map['isrc'] as String?,
      downloadedAt: map['downloaded_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['downloaded_at'] as int)
          : DateTime.now(),
      quality: map['quality'] as String? ?? '320 kbps',
      bitDepth: map['bit_depth'] as int?,
      sampleRate: map['sample_rate'] as int?,
      genre: map['genre'] as String?,
      composer: map['composer'] as String?,
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'SaiaDownloadHistoryItem($trackName - $artistName, $quality)';
}
