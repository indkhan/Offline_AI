import 'package:equatable/equatable.dart';

enum ModelId { qwen, lfm }

class ModelInfo extends Equatable {
  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.filename,
    required this.url,
  });

  final ModelId id;
  final String displayName;
  final String filename;
  final String url;

  @override
  List<Object?> get props => [id, displayName, filename, url];
}
