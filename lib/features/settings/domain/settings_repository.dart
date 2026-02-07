import '../../model_manager/domain/model_info.dart';

abstract class SettingsRepository {
  Future<ModelId?> getSelectedModel();
  Future<void> setSelectedModel(ModelId modelId);
  Future<bool> isOfflineGuardEnabled();
  Future<void> setOfflineGuardEnabled(bool value);
}
