enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

class DownloadTask {
  final String id;
  final String url;
  final String title;
  final String? thumbnail;
  final String quality;
  final String format;
  final String savePath;
  final DownloadStatus status;
  final double progress;
  final int? downloadedBytes;
  final int? totalBytes;
  final double? speed;
  final String? eta;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? completedAt;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.title,
    this.thumbnail,
    required this.quality,
    required this.format,
    required this.savePath,
    required this.status,
    this.progress = 0.0,
    this.downloadedBytes,
    this.totalBytes,
    this.speed,
    this.eta,
    this.errorMessage,
    required this.createdAt,
    this.completedAt,
  });

  DownloadTask copyWith({
    String? id,
    String? url,
    String? title,
    String? thumbnail,
    String? quality,
    String? format,
    String? savePath,
    DownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    double? speed,
    String? eta,
    String? errorMessage,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      thumbnail: thumbnail ?? this.thumbnail,
      quality: quality ?? this.quality,
      format: format ?? this.format,
      savePath: savePath ?? this.savePath,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'title': title,
      'thumbnail': thumbnail,
      'quality': quality,
      'format': format,
      'savePath': savePath,
      'status': status.name,
      'progress': progress,
      'downloadedBytes': downloadedBytes,
      'totalBytes': totalBytes,
      'speed': speed,
      'eta': eta,
      'errorMessage': errorMessage,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      thumbnail: json['thumbnail'] as String?,
      quality: json['quality'] as String,
      format: json['format'] as String,
      savePath: json['savePath'] as String,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.queued,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      downloadedBytes: json['downloadedBytes'] as int?,
      totalBytes: json['totalBytes'] as int?,
      speed: (json['speed'] as num?)?.toDouble(),
      eta: json['eta'] as String?,
      errorMessage: json['errorMessage'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}
