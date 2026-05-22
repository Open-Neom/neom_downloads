import 'constants/download_queue_constants.dart';

/// Utility for path normalization and format-agnostic duplicate detection.
class SaiaPathMatchUtils {
  SaiaPathMatchUtils._();

  static final Map<String, Set<String>> _cache = {};
  static const int _maxCacheSize = 2000;

  /// Generates normalized path variations for matching across formats and platforms.
  ///
  /// Returns a set of normalized keys that can be compared for equality.
  /// Handles URL-encoded paths, different separators, and format-agnostic matching.
  static Set<String> buildMatchKeys(String? filePath) {
    if (filePath == null || filePath.isEmpty) return {};
    if (_cache.containsKey(filePath)) return _cache[filePath]!;

    final keys = <String>{};
    String normalized = filePath.trim();

    // Strip common prefixes
    if (normalized.startsWith('EXISTS:')) {
      normalized = normalized.substring(7);
    }

    // Normalize path separators to forward slash
    normalized = normalized.replaceAll('\\', '/');
    keys.add(normalized);

    // Add lowercase variant
    keys.add(normalized.toLowerCase());

    // URL decode variant
    try {
      final decoded = Uri.decodeFull(normalized);
      if (decoded != normalized) {
        keys.add(decoded);
        keys.add(decoded.toLowerCase());
      }
    } catch (_) {
      // Ignore decoding errors
    }

    // Strip audio extensions for format-agnostic matching
    for (final ext in DownloadQueueConstants.audioExtensions) {
      if (normalized.toLowerCase().endsWith(ext)) {
        final withoutExt = normalized.substring(0, normalized.length - ext.length);
        keys.add(withoutExt);
        keys.add(withoutExt.toLowerCase());
        break;
      }
    }

    // Extract filename only (without directory path)
    final lastSlash = normalized.lastIndexOf('/');
    if (lastSlash >= 0 && lastSlash < normalized.length - 1) {
      final filenameOnly = normalized.substring(lastSlash + 1);
      keys.add(filenameOnly);
      keys.add(filenameOnly.toLowerCase());
    }

    // Cache with LRU eviction (remove oldest entry)
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[filePath] = keys;

    return keys;
  }

  /// Checks if two file paths likely refer to the same file,
  /// accounting for format differences and path normalization.
  static bool pathsMatch(String? path1, String? path2) {
    if (path1 == null || path2 == null) return false;
    if (path1 == path2) return true;

    final keys1 = buildMatchKeys(path1);
    final keys2 = buildMatchKeys(path2);
    return keys1.intersection(keys2).isNotEmpty;
  }

  /// Clears the internal cache. Call when memory pressure is detected.
  static void clearCache() => _cache.clear();
}
