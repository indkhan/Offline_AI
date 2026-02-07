import '../../features/model_manager/domain/model_info.dart';

const modelCatalog = <ModelInfo>[
  ModelInfo(
    id: ModelId.qwen,
    displayName: 'Qwen3 0.6B Q4_0',
    filename: 'Qwen3-0.6B-Q4_0.gguf',
    url:
        'https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_0.gguf',
  ),
  ModelInfo(
    id: ModelId.lfm,
    displayName: 'LFM2.5 1.2B Thinking Q4_0',
    filename: 'LFM2.5-1.2B-Thinking-Q4_0.gguf',
    url:
        'https://huggingface.co/LiquidAI/LFM2.5-1.2B-Thinking-GGUF/resolve/main/LFM2.5-1.2B-Thinking-Q4_0.gguf',
  ),
];
