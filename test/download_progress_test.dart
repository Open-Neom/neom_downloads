import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:neom_downloads/utils/download_progress.dart';

/// Unit tests for the pure download progress/integrity rules, plus
/// source-level structural assertions that DownloadController keeps the
/// guarantees (streaming to disk, status validation, integrity check).
void main() {
  group('DownloadProgress.progressFor', () {
    test('returns null when the total size is unknown (no division by zero)', () {
      expect(DownloadProgress.progressFor(500, 0), isNull);
      expect(DownloadProgress.progressFor(500, -1), isNull);
    });

    test('computes the fraction for known totals', () {
      expect(DownloadProgress.progressFor(50, 100), 0.5);
      expect(DownloadProgress.progressFor(0, 100), 0.0);
      expect(DownloadProgress.progressFor(100, 100), 1.0);
    });

    test('clamps at 1.0 when the server misreports content-length', () {
      expect(DownloadProgress.progressFor(150, 100), 1.0);
    });
  });

  group('DownloadProgress.isComplete', () {
    test('requires every announced byte', () {
      expect(DownloadProgress.isComplete(100, 100), isTrue);
      expect(DownloadProgress.isComplete(99, 100), isFalse);
      expect(DownloadProgress.isComplete(0, 100), isFalse);
    });

    test('unknown total: stream end is completion, but empty is never valid', () {
      expect(DownloadProgress.isComplete(10, 0), isTrue);
      expect(DownloadProgress.isComplete(0, 0), isFalse);
    });
  });

  group('DownloadProgress.isSuccessStatus', () {
    test('accepts only 2xx', () {
      expect(DownloadProgress.isSuccessStatus(200), isTrue);
      expect(DownloadProgress.isSuccessStatus(206), isTrue);
      expect(DownloadProgress.isSuccessStatus(301), isFalse);
      expect(DownloadProgress.isSuccessStatus(403), isFalse);
      expect(DownloadProgress.isSuccessStatus(404), isFalse);
      expect(DownloadProgress.isSuccessStatus(500), isFalse);
    });
  });

  group('DownloadController offline-reliability invariants (source level)', () {
    late String controllerSource;

    String stripComments(String src) {
      var out = src.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
      out = out.replaceAll(RegExp(r'//[^\n]*'), '');
      return out;
    }

    setUpAll(() {
      final file = File('lib/data/implementations/download_controller.dart');
      expect(file.existsSync(), isTrue,
          reason: 'download_controller.dart not found — '
              'are tests being run from the module root?');
      controllerSource = stripComments(file.readAsStringSync());
    });

    test('streams chunks to disk instead of accumulating bytes in memory', () {
      expect(controllerSource.contains('openWrite()'), isTrue,
          reason: 'Downloads must stream to disk via an open sink.');
      expect(controllerSource.contains('bytes.addAll'), isFalse,
          reason: 'Accumulating the whole file in memory is what caused '
              'multi-hundred-MB downloads to spike RAM.');
    });

    test('rejects non-2xx responses before writing anything', () {
      expect(controllerSource.contains('isSuccessStatus'), isTrue,
          reason: 'An error page saved as .m4a becomes a dead offline track.');
    });

    test('validates integrity before registering in Hive', () {
      final integrityIndex = controllerSource.indexOf('isComplete');
      final hiveIndex = controllerSource.indexOf('put(downloadedMediaItem.id');
      expect(integrityIndex, greaterThan(-1));
      expect(hiveIndex, greaterThan(-1));
      expect(integrityIndex, lessThan(hiveIndex),
          reason: 'The integrity check must run before the download is '
              'registered as complete in Hive.');
    });

    test('cleans up partial files on failure and cancellation', () {
      expect('_deleteIfExists'.allMatches(controllerSource).length,
          greaterThanOrEqualTo(3),
          reason: 'Declaration plus at least the failure and cancellation '
              'call sites must remove partial files.');
    });

    test('progress never divides by zero', () {
      expect(controllerSource.contains('received / total'), isFalse,
          reason: 'Raw division broke with unknown content-length; '
              'DownloadProgress.progressFor must be used.');
    });
  });
}
