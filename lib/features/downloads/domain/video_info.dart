class VideoInfo {
  final String url;
  final String title;
  final String? thumbnail;
  final String? duration;
  final String? author;
  final String platform;
  final List<VideoQuality> availableQualities;
  final List<String> availableFormats;

  const VideoInfo({
    required this.url,
    required this.title,
    this.thumbnail,
    this.duration,
    this.author,
    required this.platform,
    required this.availableQualities,
    required this.availableFormats,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      url: json['url'] as String,
      title: json['title'] as String,
      thumbnail: json['thumbnail'] as String?,
      duration: json['duration'] as String?,
      author: json['author'] as String?,
      platform: json['platform'] as String,
      availableQualities: (json['qualities'] as List<dynamic>?)
              ?.map((q) => VideoQuality.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      availableFormats: (json['formats'] as List<dynamic>?)
              ?.map((f) => f.toString())
              .toList() ??
          ['mp4'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
      'thumbnail': thumbnail,
      'duration': duration,
      'author': author,
      'platform': platform,
      'qualities': availableQualities.map((q) => q.toJson()).toList(),
      'formats': availableFormats,
    };
  }
}

class VideoQuality {
  final String label;
  final String resolution;
  final String? fileSize;

  const VideoQuality({
    required this.label,
    required this.resolution,
    this.fileSize,
  });

  factory VideoQuality.fromJson(Map<String, dynamic> json) {
    return VideoQuality(
      label: json['label'] as String,
      resolution: json['resolution'] as String,
      fileSize: json['file_size'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'resolution': resolution,
      'file_size': fileSize,
    };
  }
}
