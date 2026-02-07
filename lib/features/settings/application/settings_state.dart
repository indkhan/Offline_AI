import 'package:equatable/equatable.dart';

import '../../model_manager/domain/model_info.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.selectedModel,
    required this.offlineGuardEnabled,
  });

  const SettingsState.initial()
    : selectedModel = null,
      offlineGuardEnabled = true;

  final ModelId? selectedModel;
  final bool offlineGuardEnabled;

  SettingsState copyWith({ModelId? selectedModel, bool? offlineGuardEnabled}) {
    return SettingsState(
      selectedModel: selectedModel ?? this.selectedModel,
      offlineGuardEnabled: offlineGuardEnabled ?? this.offlineGuardEnabled,
    );
  }

  @override
  List<Object?> get props => [selectedModel, offlineGuardEnabled];
}
