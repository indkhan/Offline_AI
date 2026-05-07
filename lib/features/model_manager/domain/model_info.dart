import 'package:equatable/equatable.dart';

class ModelInfo extends Equatable {
  final String id;
  final String name;
  final String description;
  final String url;
  final String fileName;
  final int sizeBytes;
  final int contextSize;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.fileName,
    required this.sizeBytes,
    required this.contextSize,
  });

  @override
  List<Object?> get props => [id];
}

class InstalledModel extends Equatable {
  final String id;
  final String slug;
  final String path;
  final int sizeBytes;
  final int installedAt;

  const InstalledModel({
    required this.id,
    required this.slug,
    required this.path,
    required this.sizeBytes,
    required this.installedAt,
  });

  @override
  List<Object?> get props => [id, slug, path];
}
