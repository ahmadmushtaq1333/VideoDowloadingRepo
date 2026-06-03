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
  String? _selectedQuality;
  String? _selectedFormat;
  String? _errorMessage;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _extractVideoInfo(String url) async {
    if (!UrlParser.isValidUrl(url)) {
      setState(() {
        _errorMessage = 'Please enter a valid URL';
        _videoInfo = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _videoInfo = null;
    });

    try {
      final service = ref.read(videoExtractionServiceProvider);
      final info = await service.extractVideoInfo(url);
      
      setState(() {
        _videoInfo = info;
        _selectedQuality = info.availableQualities.isNotEmpty
            ? info.availableQualities.last.label
            : null;
        _selectedFormat = info.availableFormats.isNotEmpty
            ? info.availableFormats[0]
            : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to extract video info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _startDownload() async {
    if (_videoInfo == null || _selectedQuality == null || _selectedFormat == null) {
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

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Download started! Check Downloads tab'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Clear form
      setState(() {
        _urlController.clear();
        _videoInfo = null;
        _selectedQuality = null;
        _selectedFormat = null;
      });
    }
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
            // URL Input
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
              onSubmitted: (value) {
                _extractVideoInfo(value);
              },
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),

            // Fetch Button
            GradientButton(
              text: 'Fetch Video Info',
              icon: Icons.search,
              onPressed: _urlController.text.isEmpty || _isLoading
                  ? null
                  : () => _extractVideoInfo(_urlController.text),
              isLoading: _isLoading,
            ),

            // Error Message
            if (_errorMessage != null) ...[\n              const SizedBox(height: 16),
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

            // Loading State
            if (_isLoading) ...[\n              const SizedBox(height: 24),
              const SkeletonVideoCard(),
            ],

            // Video Preview
            if (_videoInfo != null && !_isLoading) ...[\n              const SizedBox(height: 24),
              VideoPreviewCard(videoInfo: _videoInfo!),
              const SizedBox(height: 24),

              // Quality Selector
              QualitySelector(
                qualities: _videoInfo!.availableQualities,
                selectedQuality: _selectedQuality,
                onSelected: (quality) {
                  setState(() => _selectedQuality = quality);
                },
              ),
              const SizedBox(height: 24),

              // Format Selector
              FormatSelector(
                formats: _videoInfo!.availableFormats,
                selectedFormat: _selectedFormat,
                onSelected: (format) {
                  setState(() => _selectedFormat = format);
                },
              ),
              const SizedBox(height: 32),

              // Download Button
              GradientButton(
                text: 'Download Video',
                icon: Icons.download,
                onPressed: _selectedQuality != null && _selectedFormat != null
                    ? _startDownload
                    : null,
              ),
            ],

            // Initial State
            if (_videoInfo == null && !_isLoading && _errorMessage == null) ...[\n              const SizedBox(height: 60),
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
