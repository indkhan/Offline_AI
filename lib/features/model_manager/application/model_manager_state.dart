import 'package:equatable/equatable.dart';

import '../../../core/constants/model_catalog.dart';
import '../domain/model_info.dart';

enum DownloadStatus { idle, downloading, installed, failed }

class ModelDownloadState extends Equatable {
  const ModelDownloadState({
    required this.status,
    this.progress = 0,
    this.error,
    this.path,
  });

  final DownloadStatus status;
  final double progress;
  final String? error;
  final String? path;

  static const idle = ModelDownloadState(status: DownloadStatus.idle);

  @override
  List<Object?> get props => [status, progress, error, path];
}

class ModelManagerState extends Equatable {
  const ModelManagerState({required this.models, required this.states});

  factory ModelManagerState.initial() {
    return ModelManagerState(
      models: modelCatalog,
      states: {
        for (final model in modelCatalog) model.id: ModelDownloadState.idle,
      },
    );
  }

  final List<ModelInfo> models;
  final Map<ModelId, ModelDownloadState> states;

  ModelManagerState copyWith({
    List<ModelInfo>? models,
    Map<ModelId, ModelDownloadState>? states,
  }) {
    return ModelManagerState(
      models: models ?? this.models,
      states: states ?? this.states,
    );
  }

  @override
  List<Object?> get props => [models, states];
}
