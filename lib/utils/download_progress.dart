/// Pure helpers for download progress and integrity — extracted so the
/// rules are unit-testable without an HTTP client or the file system.
class DownloadProgress {

  /// Progress fraction for [received]/[total] bytes.
  ///
  /// Returns null when the total size is unknown (server sent no
  /// Content-Length) so the UI shows an indeterminate indicator instead of
  /// dividing by zero. Clamped to 1.0: a misreporting server must not push
  /// the UI past 100%.
  static double? progressFor(int received, int total) {
    if (total <= 0) return null;
    final value = received / total;
    return value > 1.0 ? 1.0 : value;
  }

  /// A download is only registerable as complete when every announced byte
  /// arrived. When the server never announced a size (total <= 0), the
  /// stream ending normally stands as the completion signal — but an empty
  /// body is never a valid media file.
  static bool isComplete(int received, int total) {
    if (total > 0) return received >= total;
    return received > 0;
  }

  /// HTTP status codes accepted as a successful download. Anything else
  /// (404, 403, 500, redirects left unhandled) must abort — otherwise the
  /// error page body gets saved as the media file and registered as a valid
  /// offline track.
  static bool isSuccessStatus(int statusCode) =>
      statusCode >= 200 && statusCode < 300;
}
