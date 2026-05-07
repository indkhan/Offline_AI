import 'model_info.dart';

class DownloadProgress {
  final String modelId;
  final int received;
  final int total;
  const DownloadProgress(this.modelId, this.received, this.total);
  double get fraction => total <= 0 ? 0 : received / total;
}

abstract class ModelManagerRepository {
  Future<List<InstalledModel>> listInstalled();
  Future<InstalledModel?> getInstalled(String modelId);
  Stream<DownloadProgress> download(ModelInfo model);
  Future<void> cancel(String modelId);
  Future<void> delete(String modelId);
}
