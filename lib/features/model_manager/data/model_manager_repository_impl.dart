import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/model_info.dart';
import '../domain/model_manager_repository.dart';

class ModelManagerRepositoryImpl implements ModelManagerRepository {
  final Database db;
  final Dio _dio;
  final Map<String, CancelToken> _active = {};

  ModelManagerRepositoryImpl(this.db) : _dio = Dio();

  Future<Directory> _modelsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'models'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
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
    final dir = await _modelsDir();
    final dest = p.join(dir.path, model.fileName);
    final part = '$dest.part';

    final cancelToken = CancelToken();
    _active[model.id] = cancelToken;

    final controller = StreamController<DownloadProgress>();
    unawaited(
      _dio
          .download(
        model.url,
        part,
        cancelToken: cancelToken,
        onReceiveProgress: (r, t) =>
            controller.add(DownloadProgress(model.id, r, t)),
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
          headers: {'User-Agent': 'OfflineAI/1.0 (Flutter)'},
        ),
      )
          .then((_) async {
        await File(part).rename(dest);
        final size = await File(dest).length();
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
        controller.add(DownloadProgress(model.id, size, size));
        await controller.close();
      }).catchError((e) async {
        try {
          if (File(part).existsSync()) await File(part).delete();
        } catch (_) {}
        controller.addError(e);
        await controller.close();
      }).whenComplete(() => _active.remove(model.id)),
    );

    yield* controller.stream;
  }

  @override
  Future<void> cancel(String modelId) async {
    _active[modelId]?.cancel('user_cancelled');
    _active.remove(modelId);
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
