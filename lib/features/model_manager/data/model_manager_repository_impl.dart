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

  ModelManagerRepositoryImpl(this.db);

  Future<String> _modelPath(ModelInfo model) async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'models', model.fileName);
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
    final controller = StreamController<DownloadProgress>();

    final task = DownloadTask(
      taskId: model.id,
      url: model.url,
      filename: model.fileName,
      directory: 'models',
      baseDirectory: BaseDirectory.applicationDocuments,
      updates: Updates.statusAndProgress,
      retries: 3,
      allowPause: false,
    );

    late StreamSubscription<TaskUpdate> sub;
    sub = FileDownloader().updates.listen((update) async {
      if (update.task.taskId != model.id) return;

      if (update is TaskProgressUpdate) {
        if (!controller.isClosed) {
          final received =
              (update.progress * model.sizeBytes).round().clamp(0, model.sizeBytes);
          controller.add(DownloadProgress(model.id, received, model.sizeBytes));
        }
      } else if (update is TaskStatusUpdate) {
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
              unawaited(controller.close());
            }
          case TaskStatus.failed:
          case TaskStatus.notFound:
            if (!controller.isClosed) {
              controller.addError(Exception('Download failed: ${update.status}'));
              unawaited(controller.close());
            }
          case TaskStatus.canceled:
            if (!controller.isClosed) unawaited(controller.close());
          default:
            break;
        }
        if (controller.isClosed) unawaited(sub.cancel());
      }
    });

    controller.onCancel = () => sub.cancel();

    final enqueued = await FileDownloader().enqueue(task);
    if (!enqueued) {
      unawaited(sub.cancel());
      controller.addError(Exception('Failed to enqueue download'));
      unawaited(controller.close());
    }

    yield* controller.stream;
  }

  @override
  Future<void> cancel(String modelId) async {
    await FileDownloader().cancelTasksWithIds([modelId]);
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
