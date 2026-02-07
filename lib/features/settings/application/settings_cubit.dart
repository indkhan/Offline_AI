import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model_manager/domain/model_info.dart';
import '../domain/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsRepository settingsRepository})
    : _repository = settingsRepository,
      super(const SettingsState.initial());

  final SettingsRepository _repository;

  Future<void> load() async {
    final selected = await _repository.getSelectedModel();
    final guard = await _repository.isOfflineGuardEnabled();
    emit(SettingsState(selectedModel: selected, offlineGuardEnabled: guard));
  }

  Future<void> selectModel(ModelId modelId) async {
    await _repository.setSelectedModel(modelId);
    emit(state.copyWith(selectedModel: modelId));
  }

  Future<void> setOfflineGuard(bool value) async {
    await _repository.setOfflineGuardEnabled(value);
    emit(state.copyWith(offlineGuardEnabled: value));
  }
}
