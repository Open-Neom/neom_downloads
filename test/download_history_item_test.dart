// Tests for `SaiaDownloadHistoryItem`.

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_downloads/domain/models/download_history_item.dart';

void main() {
  group('SaiaDownloadHistoryItem — defaults', () {
    test('constructor con required positivos', () {
      final item = SaiaDownloadHistoryItem(
        id: 'd1',
        trackId: 't1',
        trackName: 'My Song',
        artistName: 'Artist',
        filePath: '/path/song.m4a',
      );
      expect(item.id, 'd1');
      expect(item.trackId, 't1');
      expect(item.trackName, 'My Song');
      expect(item.artistName, 'Artist');
      expect(item.albumName, '');
      expect(item.format, 'm4a');
      expect(item.quality, '320 kbps');
      expect(item.fileSizeBytes, 0);
      expect(item.isrc, isNull);
      expect(item.bitDepth, isNull);
      expect(item.downloadedAt.year, greaterThanOrEqualTo(2024));
    });

    test('downloadedAt custom se respeta', () {
      final dt = DateTime(2024, 1, 15);
      final item = SaiaDownloadHistoryItem(
        id: 'x', trackId: 'x', trackName: 'X',
        artistName: 'A', filePath: '/x',
        downloadedAt: dt,
      );
      expect(item.downloadedAt, dt);
    });
  });

  group('SaiaDownloadHistoryItem.trackArtistKey', () {
    test('formato lowercase: "trackname|artistname"', () {
      final item = SaiaDownloadHistoryItem(
        id: '', trackId: '', trackName: 'My Song',
        artistName: 'Artist', filePath: '',
      );
      expect(item.trackArtistKey, 'my song|artist');
    });

    test('caracteres especiales se conservan', () {
      final item = SaiaDownloadHistoryItem(
        id: '', trackId: '', trackName: 'Niño Año',
        artistName: 'Café', filePath: '',
      );
      expect(item.trackArtistKey, 'niño año|café');
    });
  });

  group('SaiaDownloadHistoryItem — round-trip JSON (toJson/fromJson)', () {
    test('preserva todos los campos', () {
      final original = SaiaDownloadHistoryItem(
        id: 'd1', trackId: 't1',
        trackName: 'Song', artistName: 'Artist',
        albumName: 'Album', coverUrl: 'https://x',
        filePath: '/songs/track.m4a',
        format: 'flac',
        isrc: 'USRC12300001',
        downloadedAt: DateTime.utc(2024, 1, 15, 12),
        quality: 'lossless',
        bitDepth: 24,
        sampleRate: 192000,
        genre: 'Rock',
        composer: 'Composer',
        fileSizeBytes: 50000000,
      );
      final restored = SaiaDownloadHistoryItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.trackId, original.trackId);
      expect(restored.trackName, original.trackName);
      expect(restored.artistName, original.artistName);
      expect(restored.albumName, original.albumName);
      expect(restored.format, original.format);
      expect(restored.isrc, original.isrc);
      expect(restored.quality, original.quality);
      expect(restored.bitDepth, original.bitDepth);
      expect(restored.sampleRate, original.sampleRate);
      expect(restored.fileSizeBytes, original.fileSizeBytes);
      expect(restored.downloadedAt, original.downloadedAt);
    });

    test('mapa vacío usa defaults', () {
      final item = SaiaDownloadHistoryItem.fromJson({});
      expect(item.id, '');
      expect(item.format, 'm4a');
      expect(item.quality, '320 kbps');
      expect(item.fileSizeBytes, 0);
      expect(item.isrc, isNull);
    });

    test('downloadedAt null → DateTime.now()', () {
      final item = SaiaDownloadHistoryItem.fromJson({});
      expect(item.downloadedAt.year, greaterThanOrEqualTo(2024));
    });
  });

  group('SaiaDownloadHistoryItem — toMap/fromMap (snake_case)', () {
    test('toMap usa snake_case keys', () {
      final item = SaiaDownloadHistoryItem(
        id: 'd1', trackId: 't1',
        trackName: 'X', artistName: 'A',
        filePath: '/x',
      );
      final map = item.toMap();
      expect(map.containsKey('track_id'), isTrue);
      expect(map.containsKey('track_name'), isTrue);
      expect(map.containsKey('artist_name'), isTrue);
      expect(map.containsKey('downloaded_at'), isTrue);
      expect(map.containsKey('file_size_bytes'), isTrue);
      // No camelCase
      expect(map.containsKey('trackId'), isFalse);
      expect(map.containsKey('trackName'), isFalse);
    });

    test('round-trip via toMap/fromMap', () {
      final original = SaiaDownloadHistoryItem(
        id: 'd1', trackId: 't1',
        trackName: 'Song', artistName: 'Artist',
        filePath: '/x',
        downloadedAt: DateTime.utc(2024, 6, 1),
        bitDepth: 24,
      );
      final restored = SaiaDownloadHistoryItem.fromMap(original.toMap());
      expect(restored.id, original.id);
      expect(restored.trackName, original.trackName);
      expect(restored.bitDepth, original.bitDepth);
      expect(restored.downloadedAt.millisecondsSinceEpoch,
          original.downloadedAt.millisecondsSinceEpoch);
    });

    test('fromMap con mapa vacío usa defaults', () {
      final item = SaiaDownloadHistoryItem.fromMap({});
      expect(item.id, '');
      expect(item.format, 'm4a');
    });
  });
}
