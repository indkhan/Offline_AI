import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/model_catalog.dart';
import '../domain/model_info.dart';
import '../domain/model_manager_repository.dart';
import 'model_manager_state.dart';

class ModelManagerCubit extends Cubit<ModelManagerState> {
  final ModelManagerRepository repo;
  final Map<String, StreamSubscription<DownloadProgress>> _subs = {};

  ModelManagerCubit(this.repo) : super(const ModelManagerState());

  Future<void> load() async {
    final installed = await repo.listInstalled();
    final installedById = {for (final m in installed) m.slug: m};
    final entries = <String, ModelEntry>{};
    for (final m in ModelCatalog.models) {
      final inst = installedById[m.id];
      entries[m.id] = ModelEntry(
        info: m,
        status: inst != null ? ModelStatus.installed : ModelStatus.idle,
        installed: inst,
        progress: inst != null ? 1 : 0,
      );
    }
    emit(state.copyWith(entries: entries, ready: true));
  }

  void download(ModelInfo model) {
    final current = state.entries[model.id];
    if (current == null) return;
    if (current.status == ModelStatus.downloading ||
        current.status == ModelStatus.installed) {
      return;
    }

    _update(model.id, current.copyWith(
      status: ModelStatus.downloading,
      progress: 0,
      receivedBytes: 0,
      totalBytes: 0,
      clearError: true,
    ));

    _subs[model.id]?.cancel();
    _subs[model.id] = repo.download(model).listen(
      (p) {
        final entry = state.entries[model.id];
        if (entry == null) return;
        _update(model.id, entry.copyWith(
          status: ModelStatus.downloading,
          progress: p.fraction,
          receivedBytes: p.received,
          totalBytes: p.total,
        ));
      },
      onError: (e) {
        final entry = state.entries[model.id];
        if (entry == null) return;
        _update(model.id, entry.copyWith(
          status: ModelStatus.failed,
          error: e.toString(),
        ));
      },
      onDone: () async {
        final installed = await repo.getInstalled(model.id);
        final entry = state.entries[model.id];
        if (entry == null) return;
        _update(model.id, entry.copyWith(
          status: installed != null ? ModelStatus.installed : ModelStatus.idle,
          progress: installed != null ? 1 : 0,
          installed: installed,
        ));
      },
    );
  }

  Future<void> cancel(String modelId) async {
    await repo.cancel(modelId);
    final entry = state.entries[modelId];
    if (entry == null) return;
    _update(modelId, entry.copyWith(
      status: ModelStatus.idle,
      progress: 0,
      receivedBytes: 0,
      totalBytes: 0,
    ));
    _subs[modelId]?.cancel();
    _subs.remove(modelId);
  }

  Future<void> delete(String modelId) async {
    await repo.delete(modelId);
    final entry = state.entries[modelId];
    if (entry == null) return;
    _update(modelId, entry.copyWith(
      status: ModelStatus.idle,
      progress: 0,
      receivedBytes: 0,
      totalBytes: 0,
      clearInstalled: true,
    ));
  }

  void _update(String id, ModelEntry entry) {
    final next = Map<String, ModelEntry>.from(state.entries);
    next[id] = entry;
    emit(state.copyWith(entries: next));
  }

  @override
  Future<void> close() async {
    for (final sub in _subs.values) {
      await sub.cancel();
    }
    return super.close();
  }
}
