import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/settings_repository.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final SettingsRepository repo;
  SettingsCubit(this.repo) : super(const SettingsState());

  Future<void> load() async {
    final id = await repo.getSelectedModel();
    emit(state.copyWith(selectedModelId: id, ready: true));
  }

  Future<void> select(String modelId) async {
    await repo.setSelectedModel(modelId);
    emit(state.copyWith(selectedModelId: modelId));
  }

  Future<void> clear() async {
    await repo.clearSelectedModel();
    emit(state.copyWith(clearModel: true));
  }
}
