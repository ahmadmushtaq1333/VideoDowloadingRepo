class DownloadHistory {
  final String id;
  final String title;
  final String url;
  final String? thumbnail;
  final String filePath;
  final String format;
  final String quality;
  final int fileSize;
  final DateTime downloadedAt;

  const DownloadHistory({
    required this.id,
    required this.title,
    required this.url,
    this.thumbnail,
    required this.filePath,
    required this.format,
    required this.quality,
    required this.fileSize,
    required this.downloadedAt,
  });

  factory DownloadHistory.fromJson(Map<String, dynamic> json) {
    return DownloadHistory(
      id: json['id'] as String,
      title: json['title'] as String,
      url: json['url'] as String,
      thumbnail: json['thumbnail'] as String?,
      filePath: json['filePath'] as String,
      format: json['format'] as String,
      quality: json['quality'] as String,
      fileSize: json['fileSize'] as int,
      downloadedAt: DateTime.parse(json['downloadedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'thumbnail': thumbnail,
      'filePath': filePath,
      'format': format,
      'quality': quality,
      'fileSize': fileSize,
      'downloadedAt': downloadedAt.toIso8601String(),
    };
  }
}
