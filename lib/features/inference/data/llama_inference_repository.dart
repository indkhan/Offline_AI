import 'package:llama_flutter_android/llama_flutter_android.dart' as llama;

import '../../chat/domain/chat_message_entity.dart';
import '../domain/inference_config.dart';
import '../domain/inference_repository.dart';

class LlamaInferenceRepository implements InferenceRepository {
  final llama.LlamaController _controller = llama.LlamaController();

  bool _loaded = false;
  String? _loadedPath;

  @override
  bool get isModelLoaded => _loaded;

  @override
  String? get loadedModelPath => _loadedPath;

  @override
  Future<void> loadModel(String modelPath) async {
    if (_loaded && _loadedPath == modelPath) {
      return;
    }
    await _controller.loadModel(modelPath: modelPath);
    _loaded = true;
    _loadedPath = modelPath;
  }

  @override
  Stream<String> streamCompletion(
    List<ChatMessageEntity> history,
    InferenceConfig config,
  ) {
    final messages = history
        .map(
          (item) => llama.ChatMessage(role: item.role, content: item.content),
        )
        .toList();

    return _controller.generateChat(
      messages: messages,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
    );
  }

  @override
  Future<void> stopGeneration() {
    return _controller.stop();
  }
}
