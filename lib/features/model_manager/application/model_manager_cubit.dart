import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/model_info.dart';
import '../domain/model_manager_repository.dart';
import 'model_manager_state.dart';

class ModelManagerCubit extends Cubit<ModelManagerState> {
  ModelManagerCubit({required ModelManagerRepository modelManagerRepository})
    : _repository = modelManagerRepository,
      super(ModelManagerState.initial());

  final ModelManagerRepository _repository;

  Future<void> load() async {
    final installed = await _repository.getInstalledModels();
    final newStates = Map<ModelId, ModelDownloadState>.from(state.states);
    for (final model in state.models) {
      final path = installed[model.id];
      if (path != null) {
        newStates[model.id] = ModelDownloadState(
          status: DownloadStatus.installed,
          path: path,
          progress: 1,
        );
      }
    }
    emit(state.copyWith(states: newStates));
  }

  Future<void> download(ModelInfo model) async {
    final downloading = Map<ModelId, ModelDownloadState>.from(state.states)
      ..[model.id] = const ModelDownloadState(
        status: DownloadStatus.downloading,
        progress: 0,
      );
    emit(state.copyWith(states: downloading));

    try {
      await _repository.downloadModel(model, (progress) {
        final updated = Map<ModelId, ModelDownloadState>.from(state.states)
          ..[model.id] = ModelDownloadState(
            status: DownloadStatus.downloading,
            progress: progress,
          );
        emit(state.copyWith(states: updated));
      });
      await load();
    } catch (error) {
      final failed = Map<ModelId, ModelDownloadState>.from(state.states)
        ..[model.id] = ModelDownloadState(
          status: DownloadStatus.failed,
          error: error.toString(),
        );
      emit(state.copyWith(states: failed));
    }
  }

  Future<void> cancel(ModelId id) async {
    await _repository.cancelDownload(id);
    final reset = Map<ModelId, ModelDownloadState>.from(state.states)
      ..[id] = ModelDownloadState.idle;
    emit(state.copyWith(states: reset));
  }

  Future<void> delete(ModelInfo model) async {
    await _repository.deleteModel(model);
    final reset = Map<ModelId, ModelDownloadState>.from(state.states)
      ..[model.id] = ModelDownloadState.idle;
    emit(state.copyWith(states: reset));
  }
}
