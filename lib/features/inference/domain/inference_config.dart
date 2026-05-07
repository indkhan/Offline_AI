class ChatTurn {
  final String role;
  final String content;
  const ChatTurn({required this.role, required this.content});
}

class InferenceConfig {
  final String modelPath;
  final List<ChatTurn> messages;
  final int maxTokens;
  final int contextSize;
  final int gpuLayers;
  final double temperature;
  final double topP;

  const InferenceConfig({
    required this.modelPath,
    required this.messages,
    this.maxTokens = 512,
    this.contextSize = 4096,
    this.gpuLayers = 0,
    this.temperature = 0.7,
    this.topP = 0.95,
  });
}
