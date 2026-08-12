import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_downloader/features/downloads/domain/download_task.dart';
import 'package:video_downloader/features/downloads/providers/download_provider.dart';
import 'widgets/download_tile.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadNotifierProvider);
    final notifier = ref.read(downloadNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Downloads'),
        actions: [
          if (tasks.any((t) => t.status == DownloadStatus.completed))
            TextButton.icon(
              onPressed: notifier.clearCompleted,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Completed'),
            ),
        ],
      ),
      body: tasks.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return DownloadTile(
                  task: task,
                  onPause: task.status == DownloadStatus.downloading
                      ? () => notifier.pauseDownload(task.id)
                      : null,
                  onResume: task.status == DownloadStatus.paused
                      ? () => notifier.resumeDownload(task.id)
                      : null,
                  onCancel: task.status != DownloadStatus.completed
                      ? () => notifier.cancelDownload(task.id)
                      : null,
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.download_done,
            size: 80,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(
            'No active downloads',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Downloads will appear here when you start them',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
