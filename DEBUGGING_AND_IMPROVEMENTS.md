# Debugging & Code Improvements Report

## 🐛 Issue Identified: Mock Data Fallback Behavior

### Problem
When you paste a video link, the Android app catches **mock data** instead of fetching real video information. This happens because:

1. **Primary Issue**: The `VideoExtractionService` has a try-catch that falls back to mock data when yt-dlp fails (line 44-46)
2. **Root Cause**: `yt-dlp` process execution fails (likely not installed or not in PATH on Android/mobile platforms)
3. **No Error Feedback**: Users don't know why real data wasn't fetched

### Why It Happens
- **Desktop/Linux**: yt-dlp can be installed system-wide
- **Android/iOS**: Process-based yt-dlp won't work due to platform limitations
- **Silent Fallback**: The error is caught but ignored, returning mock data silently

---

## 🔧 Code Improvements

### 1. **Enhanced Error Handling & Logging**
Add logging to understand why yt-dlp fails:

```dart
// lib/services/video_extraction_service.dart
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/video_info.dart';
import '../core/utils/url_parser.dart';

class VideoExtractionService {
  // Add debugging flag
  static const bool _enableLogging = kDebugMode;

  Future<VideoInfo> extractVideoInfo(String url) async {
    // Try real extraction with error tracking
    try {
      return await extractWithYtDlp(url);
    } catch (e, stackTrace) {
      _logError('yt-dlp extraction failed', e, stackTrace);
      _logInfo('Falling back to mock data for: $url');
      return _mockVideoInfo(url);
    }
  }
  
  Future<VideoInfo> extractWithYtDlp(String url) async {
    _logInfo('Attempting to extract: $url');
    
    try {
      // First check if yt-dlp is available
      final which = await Process.run(
        'which',
        ['yt-dlp'],
      );
      
      if (which.exitCode != 0) {
        throw Exception('yt-dlp not found in PATH');
      }

      _logInfo('yt-dlp found, extracting video info...');

      final result = await Process.run(
        'yt-dlp',
        [
          '--dump-json',
          '--no-playlist',
          url,
        ],
        timeout: const Duration(seconds: 30),
      );
      
      if (result.exitCode != 0) {
        final error = result.stderr.toString();
        _logError('yt-dlp exit code: ${result.exitCode}', error, null);
        throw Exception('Failed to extract video info: $error');
      }
      
      _logInfo('Video info extracted successfully');
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
      rethrow;
    }
  }
  
  VideoInfo _mockVideoInfo(String url) {
    final platform = UrlParser.detectPlatform(url) ?? 'Unknown';
    _logInfo('Generating mock data for platform: $platform');
    
    return VideoInfo(
      url: url,
      title: '🔄 [DEMO MODE] ${_getMockTitle(platform)}',
      thumbnail: _getMockThumbnail(platform),
      duration: '3:45',
      author: _getMockAuthor(platform),
      platform: platform,
      availableQualities: [
        const VideoQuality(label: '360p', resolution: '640x360', fileSize: '25 MB'),
        const VideoQuality(label: '480p', resolution: '854x480', fileSize: '45 MB'),
        const VideoQuality(label: '720p', resolution: '1280x720', fileSize: '85 MB'),
        const VideoQuality(label: '1080p', resolution: '1920x1080', fileSize: '150 MB'),
      ],
      availableFormats: ['mp4', 'mkv', 'webm', 'mp3'],
    );
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
        fileSize: _formatFileSize(formatMap['filesize']),
      ));
    }
    
    qualities.sort((a, b) {
      final numericRegex = RegExp(r'[^0-9]');
      final aH = int.tryParse(a.label.replaceAll(numericRegex, '')) ?? 0;
      final bH = int.tryParse(b.label.replaceAll(numericRegex, '')) ?? 0;
      return bH.compareTo(aH); // Descending order
    });
    
    return qualities;
  }
  
  String _formatFileSize(dynamic bytes) {
    if (bytes == null) return 'Unknown';
    if (bytes is! int) return 'Unknown';
    
    const sizes = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int sizeIndex = 0;
    
    while (size > 1024 && sizeIndex < sizes.length - 1) {
      size /= 1024;
      sizeIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${sizes[sizeIndex]}';
  }
  
  String _getMockTitle(String platform) {
    switch (platform) {
      case 'YouTube':
        return 'Amazing Tutorial - Learn Something New';
      case 'TikTok':
        return 'Viral TikTok Video';
      case 'Instagram':
        return 'Instagram Reel';
      default:
        return 'Sample Video Title';
    }
  }
  
  String _getMockThumbnail(String platform) {
    return 'https://via.placeholder.com/480x360.png?text=${platform}+Demo';
  }
  
  String _getMockAuthor(String platform) {
    switch (platform) {
      case 'YouTube':
        return 'Cool Channel';
      case 'TikTok':
        return '@tiktokuser';
      case 'Instagram':
        return '@instagramuser';
      default:
        return 'Content Creator';
    }
  }

  // Logging helpers
  static void _logInfo(String message) {
    if (_enableLogging) {
      debugPrint('📹 VideoExtractionService: $message');
    }
  }

  static void _logError(String message, dynamic error, StackTrace? stackTrace) {
    if (_enableLogging) {
      debugPrint('❌ VideoExtractionService ERROR: $message');
      debugPrint('   Error: $error');
      if (stackTrace != null) {
        debugPrint('   StackTrace: $stackTrace');
      }
    }
  }
}
```

### 2. **URL Validation Improvements**
Better URL validation and error messaging:

```dart
// lib/core/utils/url_parser.dart
import '../constants/app_constants.dart';

class UrlParser {
  UrlParser._();

  static String? detectPlatform(String url) {
    final normalizedUrl = url.toLowerCase().trim();
    
    for (final platform in AppConstants.supportedPlatforms) {
      final regex = RegExp(platform.pattern, caseSensitive: false);
      if (regex.hasMatch(normalizedUrl)) {
        return platform.name;
      }
    }
    return null;
  }

  static bool isValidUrl(String url) {
    final trimmedUrl = url.trim();
    
    // Check basic URL format
    if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
      return false;
    }

    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    return urlPattern.hasMatch(trimmedUrl);
  }

  static String? validateAndNormalizeUrl(String url) {
    final trimmedUrl = url.trim();
    
    // Add https:// if missing
    String normalizedUrl = trimmedUrl;
    if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    if (isValidUrl(normalizedUrl)) {
      return normalizedUrl;
    }
    return null;
  }

  static String getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
        return '🎥';
      case 'tiktok':
        return '🎵';
      case 'instagram':
        return '📷';
      case 'twitter':
      case 'x':
        return '🐦';
      case 'facebook':
        return '👍';
      case 'reddit':
        return '🤖';
      case 'vimeo':
        return '▶️';
      case 'dailymotion':
        return '📹';
      default:
        return '🌐';
    }
  }
}
```

### 3. **Enhanced UI Feedback**
Show users when mock data is being used:

```dart
// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/video_info.dart';
import '../../models/download_task.dart';
import '../../services/video_extraction_service.dart';
import '../../providers/download_provider.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/skeleton_loader.dart';
import '../../core/utils/url_parser.dart';
import 'widgets/url_input_field.dart';
import 'widgets/video_preview_card.dart';
import 'widgets/quality_selector.dart';
import 'widgets/format_selector.dart';

final videoExtractionServiceProvider = Provider((ref) => VideoExtractionService());

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _urlController = TextEditingController();
  VideoInfo? _videoInfo;
  bool _isLoading = false;
  bool _isMockData = false; // Track if mock data is being used
  String? _selectedQuality;
  String? _selectedFormat;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _extractVideoInfo(String url) async {
    // Normalize and validate URL
    final normalizedUrl = UrlParser.validateAndNormalizeUrl(url);
    if (normalizedUrl == null) {
      setState(() {
        _errorMessage = 'Please enter a valid video URL (e.g., https://youtube.com/watch?v=...')';
        _videoInfo = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoInfo = null;
      _isMockData = false;
    });

    try {
      final service = ref.read(videoExtractionServiceProvider);
      final info = await service.extractVideoInfo(normalizedUrl);
      
      // Check if mock data was returned
      final isMock = info.title.contains('[DEMO MODE]');
      
      setState(() {
        _videoInfo = info;
        _isMockData = isMock;
        _selectedQuality = info.availableQualities.isNotEmpty
            ? info.availableQualities.last.label
            : null;
        _selectedFormat = info.availableFormats.isNotEmpty
            ? info.availableFormats[0]
            : null;
        _isLoading = false;
      });

      // Show warning if mock data
      if (isMock && mounted) {
        _showMockDataWarning();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to extract video info: $e';
        _isLoading = false;
      });
    }
  }

  void _showMockDataWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('⚠️ Using demo data - yt-dlp not available'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Learn More',
          onPressed: () {
            // Show info dialog
            _showYtDlpInfoDialog();
          },
        ),
      ),
    );
  }

  void _showYtDlpInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Mode Detected'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The app is showing demo data because yt-dlp is not installed.',
                style: TextStyle(marginBottom: 16),
              ),
              SizedBox(height: 12),
              Text(
                'To enable real video downloads:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Desktop/Linux: Install yt-dlp system-wide'),
              Text('2. Mobile: Use the integrated HTTP download method'),
              Text('3. Web: Use a backend API with yt-dlp'),
              SizedBox(height: 12),
              Text(
                'See YT-DLP_INTEGRATION.md for detailed setup instructions.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownload() async {
    if (_videoInfo == null || _selectedQuality == null || _selectedFormat == null) {
      return;
    }

    if (_isMockData) {
      _showDownloadWarning();
      return;
    }

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: _videoInfo!.url,
      title: _videoInfo!.title,
      thumbnail: _videoInfo!.thumbnail,
      quality: _selectedQuality!,
      format: _selectedFormat!,
      savePath: '',
      status: DownloadStatus.queued,
      createdAt: DateTime.now(),
    );

    ref.read(downloadNotifierProvider.notifier).startDownload(task);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Download started! Check Downloads tab'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      setState(() {
        _urlController.clear();
        _videoInfo = null;
        _selectedQuality = null;
        _selectedFormat = null;
      });
    }
  }

  void _showDownloadWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Mode - Cannot Download'),
        content: const Text(
          'This is demo data. Real downloads require yt-dlp to be installed.\n\n'
          'Please set up yt-dlp first or paste a URL to a real video service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Downloader'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UrlInputField(
              controller: _urlController,
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              onPaste: () {
                _extractVideoInfo(_urlController.text);
              },
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),

            GradientButton(
              text: 'Fetch Video Info',
              icon: Icons.search,
              onPressed: _urlController.text.isEmpty || _isLoading
                  ? null
                  : () => _extractVideoInfo(_urlController.text),
              isLoading: _isLoading,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isMockData && _videoInfo != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Demo Mode - Not Real Data',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'yt-dlp is not installed. Download will use mock data.',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showYtDlpInfoDialog,
                            child: const Text(
                              'Setup Instructions →',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const SkeletonVideoCard(),
            ],

            if (_videoInfo != null && !_isLoading) ...[
              const SizedBox(height: 24),
              VideoPreviewCard(videoInfo: _videoInfo!),
              const SizedBox(height: 24),

              QualitySelector(
                qualities: _videoInfo!.availableQualities,
                selectedQuality: _selectedQuality,
                onSelected: (quality) {
                  setState(() => _selectedQuality = quality);
                },
              ),
              const SizedBox(height: 24),

              FormatSelector(
                formats: _videoInfo!.availableFormats,
                selectedFormat: _selectedFormat,
                onSelected: (format) {
                  setState(() => _selectedFormat = format);
                },
              ),
              const SizedBox(height: 32),

              GradientButton(
                text: _isMockData ? 'Download (Demo)' : 'Download Video',
                icon: Icons.download,
                onPressed: _selectedQuality != null && _selectedFormat != null
                    ? _startDownload
                    : null,
              ),
            ],

            if (_videoInfo == null && !_isLoading && _errorMessage == null) ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.cloud_download,
                      size: 80,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Paste a video URL to get started',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supports YouTube, TikTok, Instagram, and 1700+ sites',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 🎯 Key Improvements Summary

| Issue | Solution | Benefit |
|-------|----------|---------|
| Silent fallback to mock data | Add logging and error tracking | Developers can debug issues |
| No user feedback | Show banner when mock data used | Users know it's demo data |
| URL validation missing | Validate and normalize URLs | Fewer errors, better UX |
| Quality sorting wrong | Sort descending (best first) | Better quality selection |
| File size formatting | Add proper byte conversion | More readable sizes |
| No yt-dlp availability check | Check if yt-dlp exists | Fail fast instead of silent |
| No timeout handling | Add 30-second timeout | Prevent app hangs |

---

## 🚀 How to Test

1. **Test Mock Data Detection**:
   ```bash
   flutter run --debug
   # Paste a YouTube URL
   # Should show orange warning banner if yt-dlp not found
   ```

2. **View Logs** (if using Android Studio):
   - Run: `flutter run`
   - Look for logs with prefix "📹 VideoExtractionService:"

3. **Enable Real yt-dlp** (Desktop only):
   ```bash
   pip install yt-dlp  # or: brew install yt-dlp
   flutter run
   ```

---

## 📋 To Implement These Changes

1. Update `lib/services/video_extraction_service.dart` with enhanced version
2. Update `lib/core/utils/url_parser.dart` with improved validation
3. Update `lib/screens/home/home_screen.dart` with better UI feedback
4. Run `flutter pub get`
5. Test on Android/iOS/Desktop platforms
