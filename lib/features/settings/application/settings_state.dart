import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final String? selectedModelId;
  final bool ready;

  const SettingsState({this.selectedModelId, this.ready = false});

  SettingsState copyWith({String? selectedModelId, bool? ready, bool clearModel = false}) {
    return SettingsState(
      selectedModelId: clearModel ? null : (selectedModelId ?? this.selectedModelId),
      ready: ready ?? this.ready,
    );
  }

  @override
  List<Object?> get props => [selectedModelId, ready];
}
