import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' hide Database;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/model_info.dart';
import '../domain/model_manager_repository.dart';

class ModelManagerRepositoryImpl implements ModelManagerRepository {
  final Database db;

  // modelId → unique taskId per attempt (avoids WorkManager ID collisions on retry)
  final Map<String, String> _taskIds = {};
  final Map<String, StreamController<DownloadProgress>> _controllers = {};

  ModelManagerRepositoryImpl(this.db);

  Future<String> _modelPath(ModelInfo model) async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'models', model.fileName);
  }

  // Synchronous — safe to call from inside a callback.
  void _cleanup(String modelId) {
    _taskIds.remove(modelId);
    _controllers.remove(modelId);
    FileDownloader().unregisterCallbacks(group: modelId);
  }

  // Full async teardown: cancel WorkManager task, close controller, unregister callbacks.
  Future<void> _teardown(String modelId) async {
    final taskId = _taskIds.remove(modelId);
    final controller = _controllers.remove(modelId);
    FileDownloader().unregisterCallbacks(group: modelId);
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
    if (taskId != null) {
      await FileDownloader().cancelTasksWithIds([taskId]);
    }
  }

  @override
  Future<List<InstalledModel>> listInstalled() async {
    final rows = await db.query('model_installs', orderBy: 'installed_at DESC');
    return rows.map(_rowToInstalled).toList();
  }

  @override
  Future<InstalledModel?> getInstalled(String modelId) async {
    final rows = await db.query(
      'model_installs',
      where: 'slug = ?',
      whereArgs: [modelId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final path = row['path'] as String;
    if (!File(path).existsSync()) {
      await db.delete('model_installs', where: 'slug = ?', whereArgs: [modelId]);
      return null;
    }
    return _rowToInstalled(row);
  }

  InstalledModel _rowToInstalled(Map<String, Object?> row) => InstalledModel(
        id: row['id'] as String,
        slug: row['slug'] as String,
        path: row['path'] as String,
        sizeBytes: row['size_bytes'] as int,
        installedAt: row['installed_at'] as int,
      );

  @override
  Stream<DownloadProgress> download(ModelInfo model) async* {
    // Tear down any in-progress download for this model first.
    await _teardown(model.id);

    // Unique taskId per attempt so stale canceled events from prior attempt
    // don't match the new task, even if they arrive late.
    final taskId = '${model.id}-${DateTime.now().millisecondsSinceEpoch}';
    _taskIds[model.id] = taskId;

    final controller = StreamController<DownloadProgress>();
    _controllers[model.id] = controller;

    // Use group = model.id so callbacks are scoped per model, not global.
    // registerCallbacks replaces .updates.listen() which is single-subscription.
    FileDownloader().registerCallbacks(
      group: model.id,
      taskStatusCallback: (update) async {
        if (update.task.taskId != taskId) return;
        switch (update.status) {
          case TaskStatus.complete:
            final dest = await _modelPath(model);
            final size =
                File(dest).existsSync() ? await File(dest).length() : model.sizeBytes;
            await db.insert(
              'model_installs',
              {
                'id': model.id,
                'slug': model.id,
                'path': dest,
                'size_bytes': size,
                'installed_at': DateTime.now().millisecondsSinceEpoch,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            if (!controller.isClosed) {
              controller.add(DownloadProgress(model.id, size, size));
              await controller.close();
            }
            _cleanup(model.id);
          case TaskStatus.failed:
          case TaskStatus.notFound:
            if (!controller.isClosed) {
              controller.addError(Exception('Download failed: ${update.status}'));
              await controller.close();
            }
            _cleanup(model.id);
          case TaskStatus.canceled:
            if (!controller.isClosed) await controller.close();
            _cleanup(model.id);
          default:
            break;
        }
      },
      taskProgressCallback: (update) {
        if (update.task.taskId != taskId) return;
        if (!controller.isClosed) {
          final received =
              (update.progress * model.sizeBytes).round().clamp(0, model.sizeBytes);
          controller.add(DownloadProgress(model.id, received, model.sizeBytes));
        }
      },
    );

    controller.onCancel = () => _cleanup(model.id);

    final task = DownloadTask(
      taskId: taskId,
      url: model.url,
      filename: model.fileName,
      directory: 'models',
      baseDirectory: BaseDirectory.applicationDocuments,
      group: model.id,
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: false,
    );

    final enqueued = await FileDownloader().enqueue(task);
    if (!enqueued) {
      _cleanup(model.id);
      if (!controller.isClosed) {
        controller.addError(Exception('Failed to enqueue download'));
        await controller.close();
      }
    }

    yield* controller.stream;
  }

  @override
  Future<void> cancel(String modelId) async {
    await _teardown(modelId);
  }

  @override
  Future<void> delete(String modelId) async {
    final installed = await getInstalled(modelId);
    if (installed != null) {
      try {
        final f = File(installed.path);
        if (f.existsSync()) await f.delete();
      } catch (_) {}
    }
    await db.delete('model_installs', where: 'slug = ?', whereArgs: [modelId]);
  }
}
