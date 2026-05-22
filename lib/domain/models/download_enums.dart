/// Enums for the download queue system.

enum DownloadStatus {
  queued,
  downloading,
  finalizing,
  completed,
  failed,
  skipped,
  cancelled,
}

enum DownloadErrorType {
  unknown,
  notFound,
  rateLimit,
  network,
  permission,
  diskFull,
  cancelled,
}

enum FolderOrganization {
  flat,
  artist,
  artistAlbum,
}

enum FilenameFormat {
  titleArtist,
  artistTitle,
  titleOnly,
}
