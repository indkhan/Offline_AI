import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../../storage/app_database.dart';
import '../domain/model_info.dart';
import '../domain/model_manager_repository.dart';

class ModelManagerRepositoryImpl implements ModelManagerRepository {
  ModelManagerRepositoryImpl({required AppDatabase database})
    : _database = database;

  final Dio _dio = Dio();
  final AppDatabase _database;
  final Map<ModelId, CancelToken> _tokens = <ModelId, CancelToken>{};

  @override
  Future<Map<ModelId, String>> getInstalledModels() async {
    return _database.readInstalledModels();
  }

  @override
  Future<void> downloadModel(
    ModelInfo model,
    void Function(double progress) onProgress,
  ) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final modelsDir = Directory(path.join(documentsDir.path, 'models'));
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }

    final outPath = path.join(modelsDir.path, model.filename);
    final token = CancelToken();
    _tokens[model.id] = token;

    await _dio.download(
      model.url,
      outPath,
      cancelToken: token,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (total <= 0) {
          onProgress(0);
          return;
        }
        onProgress(received / total);
      },
    );

    final file = File(outPath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw Exception('Downloaded model file is missing or empty.');
    }

    await _database.upsertInstalledModel(
      modelId: model.id.name,
      filePath: outPath,
      sizeBytes: file.lengthSync(),
    );
    _tokens.remove(model.id);
  }

  @override
  Future<void> cancelDownload(ModelId id) async {
    final token = _tokens[id];
    token?.cancel('Download cancelled by user');
    _tokens.remove(id);
  }

  @override
  Future<void> deleteModel(ModelInfo model) async {
    final installed = await _database.readInstalledModels();
    final filePath = installed[model.id];
    if (filePath != null) {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
      }
    }
    await _database.removeInstalledModel(model.id.name);
  }
}
