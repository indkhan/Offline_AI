import 'model_info.dart';

abstract class ModelManagerRepository {
  Future<Map<ModelId, String>> getInstalledModels();
  Future<void> downloadModel(
    ModelInfo model,
    void Function(double progress) onProgress,
  );
  Future<void> cancelDownload(ModelId id);
  Future<void> deleteModel(ModelInfo model);
}
