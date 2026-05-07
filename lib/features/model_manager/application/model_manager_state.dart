import 'package:equatable/equatable.dart';

import '../domain/model_info.dart';

enum ModelStatus { idle, downloading, installed, failed }

class ModelEntry extends Equatable {
  final ModelInfo info;
  final ModelStatus status;
  final double progress;
  final int receivedBytes;
  final int totalBytes;
  final InstalledModel? installed;
  final String? error;

  const ModelEntry({
    required this.info,
    this.status = ModelStatus.idle,
    this.progress = 0,
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.installed,
    this.error,
  });

  ModelEntry copyWith({
    ModelStatus? status,
    double? progress,
    int? receivedBytes,
    int? totalBytes,
    InstalledModel? installed,
    String? error,
    bool clearError = false,
    bool clearInstalled = false,
  }) {
    return ModelEntry(
      info: info,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      receivedBytes: receivedBytes ?? this.receivedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      installed: clearInstalled ? null : (installed ?? this.installed),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [info.id, status, progress, receivedBytes, totalBytes, installed, error];
}

class ModelManagerState extends Equatable {
  final Map<String, ModelEntry> entries;
  final bool ready;

  const ModelManagerState({this.entries = const {}, this.ready = false});

  ModelManagerState copyWith({Map<String, ModelEntry>? entries, bool? ready}) =>
      ModelManagerState(
        entries: entries ?? this.entries,
        ready: ready ?? this.ready,
      );

  @override
  List<Object?> get props => [entries, ready];
}
