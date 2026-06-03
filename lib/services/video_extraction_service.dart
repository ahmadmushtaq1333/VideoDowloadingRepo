import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/video_info.dart';
import '../core/utils/url_parser.dart';

class VideoExtractionService {
  final Dio _dio = Dio();
  
  // Point to your backend server - UPDATE THIS WITH YOUR BACKEND URL
  final String _backendUrl = 'https://your-backend.com/api/extract';
  
  Future<VideoInfo> extractVideoInfo(String url) async {
    // For Android/iOS, use backend API
    if (Platform.isAndroid || Platform.isIOS) {
      return await extractWithBackend(url);
    }
    
    // For desktop platforms, try yt-dlp first
    try {
      return await extractWithYtDlp(url);
    } catch (e) {
      // If yt-dlp fails on desktop, fall back to backend
      return await extractWithBackend(url);
    }
  }
  
  Future<VideoInfo> extractWithBackend(String url) async {
    try {
      final response = await _dio.post(
        _backendUrl,
        data: {'url': url},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Backend error: ${response.statusMessage}');
      }
      
      final json = response.data as Map<String, dynamic>;
      final qualities = _parseQualities(json);
      
      return VideoInfo(
        url: url,
        title: json['title'] as String? ?? 'Unknown',
        thumbnail: json['thumbnail'] as String?,
        duration: json['duration']?.toString(),
        author: json['uploader'] as String?,
        platform: UrlParser.detectPlatform(url) ?? 'Unknown',
        availableQualities: qualities.isNotEmpty ? qualities : const [
          VideoQuality(label: 'best', resolution: 'best available', fileSize: null),
        ],
        availableFormats: List<String>.from(json['formats'] ?? ['mp4', 'mkv', 'webm', 'mp3']),
      );
    } catch (e) {
      throw Exception('Failed to extract video: $e');
    }
  }
  
  Future<VideoInfo> extractWithYtDlp(String url) async {
    try {
      // Call yt-dlp to get video info
      final result = await Process.run(
        'yt-dlp',
        [
          '--dump-json',
          '--no-playlist',
          url,
        ],
      );
      
      if (result.exitCode != 0) {
        throw Exception('Failed to extract video info: ${result.stderr}');
      }
      
      final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      
      final qualities = _parseQualities(json);
      return VideoInfo(
        url: url,
        title: json['title'] as String? ?? 'Unknown',
        thumbnail: json['thumbnail'] as String?,
        duration: json['duration']?.toString(),
        author: json['uploader'] as String?,
        platform: UrlParser.detectPlatform(url) ?? 'Unknown',
        availableQualities: qualities.isNotEmpty
            ? qualities
            : const [
                VideoQuality(label: 'best', resolution: 'best available', fileSize: null),
              ],
        availableFormats: ['mp4', 'mkv', 'webm', 'mp3'],
      );
    } catch (e) {
      throw Exception('yt-dlp error: $e');
    }
  }
  
  List<VideoQuality> _parseQualities(Map<String, dynamic> json) {
    final formats = json['formats'] as List<dynamic>? ?? [];
    final qualities = <VideoQuality>[];
    final seen = <String>{};
    
    for (final format in formats) {
      final formatMap = format as Map<String, dynamic>;
      final height = formatMap['height'] as int?;
      if (height == null) continue;
      
      final label = '${height}p';
      if (seen.contains(label)) continue;
      seen.add(label);
      
      qualities.add(VideoQuality(
        label: label,
        resolution: '${formatMap['width'] ?? '?'}x$height',
        fileSize: formatMap['filesize']?.toString(),
      ));
    }
    
    qualities.sort((a, b) {
      final numericRegex = RegExp(r'[^0-9]');
      final aH = int.tryParse(a.label.replaceAll(numericRegex, '')) ?? 0;
      final bH = int.tryParse(b.label.replaceAll(numericRegex, '')) ?? 0;
      return aH.compareTo(bH);
    });
    return qualities;
  }
}
