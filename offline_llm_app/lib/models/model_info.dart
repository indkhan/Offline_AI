// model_info.dart
// Data models for LLM model information and management

/// Information about an available LLM model
class ModelInfo {
  final String id;
  final String name;
  final String description;
  final String downloadUrl;
  final int sizeBytes;
  final String quantization;
  final bool isDefault;
  
  const ModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.quantization,
    this.isDefault = false,
  });
  
  /// Get human-readable size string
  String get sizeString {
    if (sizeBytes >= 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    } else {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
  }
  
  /// Get the filename from the download URL
  String get fileName => downloadUrl.split('/').last;
}

/// Status of a downloaded model
enum ModelStatus {
  notDownloaded,
  downloading,
  downloaded,
  error,
}

/// Download progress information
class DownloadProgress {
  final String modelId;
  final int downloadedBytes;
  final int totalBytes;
  final ModelStatus status;
  final String? error;
  
  const DownloadProgress({
    required this.modelId,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.status = ModelStatus.notDownloaded,
    this.error,
  });
  
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0;
  
  String get progressString {
    if (totalBytes == 0) return '0%';
    return '${(progress * 100).toStringAsFixed(1)}%';
  }
  
  DownloadProgress copyWith({
    String? modelId,
    int? downloadedBytes,
    int? totalBytes,
    ModelStatus? status,
    String? error,
  }) {
    return DownloadProgress(
      modelId: modelId ?? this.modelId,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      error: error,
    );
  }
}

/// List of available models with hardcoded URLs
class AvailableModels {
  static const List<ModelInfo> models = [
    ModelInfo(
      id: 'qwen2.5-1.5b',
      name: 'Qwen 2.5 1.5B',
      description: 'Compact and fast model from Alibaba. Great for general chat and coding assistance.',
      downloadUrl: 'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf',
      sizeBytes: 1100000000, // ~1.1 GB
      quantization: 'Q4_K_M',
      isDefault: true,
    ),
    ModelInfo(
      id: 'gemma-2b',
      name: 'Gemma 2B',
      description: 'Google\'s lightweight open model. Good for general conversation.',
      downloadUrl: 'https://huggingface.co/google/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-q4_k_m.gguf',
      sizeBytes: 1500000000, // ~1.5 GB
      quantization: 'Q4_K_M',
    ),
    ModelInfo(
      id: 'function-gemma-2b',
      name: 'Function Gemma 2B',
      description: 'Gemma fine-tuned for function calling. Good for structured outputs.',
      downloadUrl: 'https://huggingface.co/NousResearch/Function-Gemma-2B-GGUF/resolve/main/function-gemma-2b-q4_k_m.gguf',
      sizeBytes: 1500000000, // ~1.5 GB
      quantization: 'Q4_K_M',
    ),
  ];
  
  static ModelInfo? getById(String id) {
    try {
      return models.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
  
  static ModelInfo get defaultModel => models.firstWhere((m) => m.isDefault);
}
