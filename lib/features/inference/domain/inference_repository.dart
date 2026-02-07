import '../../chat/domain/chat_message_entity.dart';
import 'inference_config.dart';

abstract class InferenceRepository {
  bool get isModelLoaded;
  String? get loadedModelPath;

  Future<void> loadModel(String modelPath);
  Stream<String> streamCompletion(
    List<ChatMessageEntity> history,
    InferenceConfig config,
  );
  Future<void> stopGeneration();
}
