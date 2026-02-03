import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:path_provider/path_provider.dart";

import "model_spec.dart";

class ModelManager {
  final Dio _dio = Dio();
  late final Directory _modelsDir;
  final Map<ModelId, String?> _lastError = {};

  Future<void> init() async {
    final docs = await getApplicationDocumentsDirectory();
    _modelsDir = Directory("${docs.path}/models");
    if (!await _modelsDir.exists()) {
      await _modelsDir.create(recursive: true);
    }
  }

  String modelPath(ModelSpec spec) => "${_modelsDir.path}/${spec.fileName}";

  ModelStatus getStatus(ModelSpec spec) {
    final file = File(modelPath(spec));
    final exists = file.existsSync();
    return ModelStatus(
      id: spec.id,
      isReady: exists,
      path: exists ? file.path : null,
      lastError: _lastError[spec.id],
    );
  }

  Stream<DownloadProgress> download(ModelSpec spec) {
    final controller = StreamController<DownloadProgress>();
    final tmpPath = "${modelPath(spec)}.partial";
    final tmpFile = File(tmpPath);
    final targetFile = File(modelPath(spec));

    () async {
      try {
        if (await tmpFile.exists()) {
          await tmpFile.delete();
        }
        controller.add(
          const DownloadProgress(
            receivedBytes: 0,
            totalBytes: 0,
            phase: DownloadPhase.downloading,
          ),
        );
        await _dio.download(
          spec.url,
          tmpPath,
          onReceiveProgress: (received, total) {
            controller.add(
              DownloadProgress(
                receivedBytes: received,
                totalBytes: total,
                phase: DownloadPhase.downloading,
              ),
            );
          },
        );
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tmpFile.rename(targetFile.path);
        _lastError[spec.id] = null;
        controller.add(
          DownloadProgress(
            receivedBytes: targetFile.lengthSync(),
            totalBytes: targetFile.lengthSync(),
            phase: DownloadPhase.done,
          ),
        );
      } catch (e) {
        _lastError[spec.id] = e.toString();
        controller.add(
          const DownloadProgress(
            receivedBytes: 0,
            totalBytes: 0,
            phase: DownloadPhase.error,
          ),
        );
      } finally {
        await controller.close();
      }
    }();

    return controller.stream;
  }

  Future<void> delete(ModelSpec spec) async {
    final file = File(modelPath(spec));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
