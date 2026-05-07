import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _kSelectedModel = 'selected_model_id';

  @override
  Future<String?> getSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kSelectedModel);
  }

  @override
  Future<void> setSelectedModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSelectedModel, modelId);
  }

  @override
  Future<void> clearSelectedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSelectedModel);
  }
}
