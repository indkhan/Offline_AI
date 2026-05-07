abstract class SettingsRepository {
  Future<String?> getSelectedModel();
  Future<void> setSelectedModel(String modelId);
  Future<void> clearSelectedModel();
}
