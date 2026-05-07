import 'inference_config.dart';

abstract class InferenceRepository {
  Stream<String> generate(InferenceConfig cfg);
  Future<void> stop();
}
