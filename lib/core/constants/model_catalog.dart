import '../../features/model_manager/domain/model_info.dart';

class ModelCatalog {
  ModelCatalog._();

  static const List<ModelInfo> models = [
    ModelInfo(
      id: 'qwen3.5-0.8b-q4km',
      name: 'Qwen3.5 0.8B',
      description: 'Smallest. ~533 MB. Fast on any phone.',
      url:
          'https://huggingface.co/unsloth/Qwen3.5-0.8B-GGUF/resolve/main/Qwen3.5-0.8B-Q4_K_M.gguf',
      fileName: 'Qwen3.5-0.8B-Q4_K_M.gguf',
      sizeBytes: 533 * 1024 * 1024,
      contextSize: 4096,
    ),
    ModelInfo(
      id: 'gemma-4-e2b-it-q4km',
      name: 'Gemma 4 E2B IT',
      description: 'Higher quality. ~2 GB. Needs 4 GB+ free RAM.',
      url:
          'https://huggingface.co/unsloth/gemma-4-E2B-it-GGUF/resolve/main/gemma-4-E2B-it-Q4_K_M.gguf',
      fileName: 'gemma-4-E2B-it-Q4_K_M.gguf',
      sizeBytes: 2 * 1024 * 1024 * 1024,
      contextSize: 4096,
    ),
  ];

  static ModelInfo? byId(String id) {
    for (final m in models) {
      if (m.id == id) return m;
    }
    return null;
  }
}
