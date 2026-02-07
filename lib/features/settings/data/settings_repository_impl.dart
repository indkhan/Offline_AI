import '../../storage/app_database.dart';
import '../../model_manager/domain/model_info.dart';
import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required AppDatabase database})
    : _database = database;

  final AppDatabase _database;

  @override
  Future<ModelId?> getSelectedModel() async {
    final raw = await _database.readSetting('selected_model');
    if (raw == null) {
      return null;
    }
    return ModelId.values.firstWhere(
      (value) => value.name == raw,
      orElse: () => ModelId.qwen,
    );
  }

  @override
  Future<bool> isOfflineGuardEnabled() async {
    final raw = await _database.readSetting('offline_guard');
    if (raw == null) {
      return true;
    }
    return raw == 'true';
  }

  @override
  Future<void> setOfflineGuardEnabled(bool value) {
    return _database.upsertSetting('offline_guard', value.toString());
  }

  @override
  Future<void> setSelectedModel(ModelId modelId) {
    return _database.upsertSetting('selected_model', modelId.name);
  }
}
