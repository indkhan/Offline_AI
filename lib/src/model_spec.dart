enum ModelId { qwen, lfm }

class ModelSpec {
  ModelSpec({
    required this.id,
    required this.name,
    required this.url,
    required this.fileName,
    required this.sha256,
    required this.description,
    required this.sizeLabel,
  });

  final ModelId id;
  final String name;
  final String url;
  final String fileName;
  final String? sha256;
  final String description;
  final String sizeLabel;

  bool get hasChecksum => sha256 != null && sha256!.isNotEmpty;
}

class ModelStatus {
  const ModelStatus({
    required this.id,
    required this.isReady,
    required this.path,
    required this.lastError,
  });

  final ModelId id;
  final bool isReady;
  final String? path;
  final String? lastError;
}

class DownloadProgress {
  const DownloadProgress({
    required this.receivedBytes,
    required this.totalBytes,
    required this.phase,
  });

  final int receivedBytes;
  final int totalBytes;
  final DownloadPhase phase;

  double get fraction =>
      totalBytes == 0 ? 0 : receivedBytes / totalBytes;
}

enum DownloadPhase { downloading, verifying, done, error }

final List<ModelSpec> kModels = [
  ModelSpec(
    id: ModelId.qwen,
    name: "Qwen 0.6B Q4_0",
    url:
        "https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_0.gguf",
    fileName: "Qwen3-0.6B-Q4_0.gguf",
    sha256:
        "667ce68a637d8b03679458640977297910e6c3d23edf6b4dc4cbf222e394d5bf",
    description: "Smaller, faster model for on-device chat.",
    sizeLabel: "~0.5 GB",
  ),
  ModelSpec(
    id: ModelId.lfm,
    name: "LFM2.5 1.2B Q4_0",
    url:
        "https://huggingface.co/LiquidAI/LFM2.5-1.2B-Thinking-GGUF/resolve/main/LFM2.5-1.2B-Thinking-Q4_0.gguf",
    fileName: "LFM2.5-1.2B-Thinking-Q4_0.gguf",
    sha256: null,
    description: "Larger model, better reasoning.",
    sizeLabel: "~0.9 GB",
  ),
];
