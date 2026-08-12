import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_downloader/features/downloads/domain/download_history.dart';
import 'package:video_downloader/features/downloads/domain/download_task.dart';
import 'package:video_downloader/features/downloads/data/download_service.dart';
import 'package:video_downloader/services/storage_service.dart';
import 'package:video_downloader/providers/storage_provider.dart';

final downloadServiceProvider = Provider((ref) => DownloadService());

class DownloadNotifier extends StateNotifier<List<DownloadTask>> {
  final DownloadService _service;
  final StorageService _storage;

  DownloadNotifier(this._service, this._storage) : super([]);

  void startDownload(DownloadTask task) {
    state = [...state, task];
    _listenToDownload(task);
  }

  void resumeDownload(String taskId) {
    final matchingTasks = state.where((t) => t.id == taskId);
    if (matchingTasks.isEmpty) return;
    final task = matchingTasks.first;
    final resumedTask = task.copyWith(status: DownloadStatus.queued);
    state = [
      for (final t in state)
        if (t.id == taskId) resumedTask else t,
    ];
    _listenToDownload(resumedTask);
  }

  void _listenToDownload(DownloadTask task) {
    _service.downloadVideo(task).listen(
      (updatedTask) {
        state = [
          for (final t in state)
            if (t.id == updatedTask.id) updatedTask else t,
        ];
        if (updatedTask.status == DownloadStatus.completed) {
          _saveToHistory(updatedTask);
        }
      },
      onError: (Object error) {
        state = [
          for (final t in state)
            if (t.id == task.id)
              t.copyWith(
                status: DownloadStatus.failed,
                errorMessage: error.toString(),
              )
            else
              t,
        ];
      },
    );
  }

  Future<void> pauseDownload(String taskId) async {
    await _service.pauseDownload(taskId);
    state = [
      for (final t in state)
        if (t.id == taskId) t.copyWith(status: DownloadStatus.paused) else t,
    ];
  }

  Future<void> cancelDownload(String taskId) async {
    await _service.cancelDownload(taskId);
    state = state.where((t) => t.id != taskId).toList();
  }

  void clearCompleted() {
    state = state.where((t) => t.status != DownloadStatus.completed).toList();
  }

  void _saveToHistory(DownloadTask task) {
    final historyItem = DownloadHistory(
      id: task.id,
      title: task.title,
      url: task.url,
      thumbnail: task.thumbnail,
      filePath: task.savePath,
      format: task.format,
      quality: task.quality,
      fileSize: task.totalBytes ?? 0,
      downloadedAt: task.completedAt ?? DateTime.now(),
    );
    _storage.addToHistory(historyItem);
  }
}

final downloadNotifierProvider =
    StateNotifierProvider<DownloadNotifier, List<DownloadTask>>(
  (ref) {
    final service = ref.watch(downloadServiceProvider);
    final storage = ref.watch(storageServiceProvider);
    ref.onDispose(service.dispose);
    return DownloadNotifier(service, storage);
  },
);
