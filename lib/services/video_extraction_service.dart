import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/video_info.dart';
import '../core/utils/url_parser.dart';

class VideoExtractionService {
  final Dio _dio = Dio();
  
  // Backend URL - Must match your Railway deployment
  final String _backendUrl = 'https://video-downloader-backend.railway.app/api/extract';
  
  Future<VideoInfo> extractVideoInfo(String url) async {
    // Android & iOS MUST use backend (no yt-dlp on mobile)
    if (Platform.isAndroid || Platform.isIOS) {
      print('DEBUG: Platform is mobile - using backend API');
      return await extractWithBackend(url);
    }
    
    // Desktop: try local yt-dlp first
    print('DEBUG: Platform is desktop - trying local yt-dlp');
    try {
      return await extractWithYtDlp(url);
    } catch (e) {
      print('DEBUG: yt-dlp failed, falling back to backend');
      return await extractWithBackend(url);
    }
  }
  
  Future<VideoInfo> extractWithBackend(String url) async {
    try {
      print('DEBUG: Calling backend API: $_backendUrl');
      print('DEBUG: URL parameter: $url');
      
      final response = await _dio.post(
        _backendUrl,
        data: {'url': url},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      
      print('DEBUG: Backend response status: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('DEBUG: Backend error status: ${response.statusCode}');
        throw Exception('Backend error: ${response.statusMessage}');
      }
      
      final json = response.data as Map<String, dynamic>;
      print('DEBUG: Backend returned title: ${json['title']}');
      
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
      print('DEBUG: Backend extraction failed: $e');
      throw Exception('Backend error: $e');
    }
  }
  
  Future<VideoInfo> extractWithYtDlp(String url) async {
    try {
      print('DEBUG: Calling local yt-dlp');
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
      print('DEBUG: yt-dlp error: $e');
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
