import "dart:async";
import "dart:io";

import "package:llama_cpp_dart/llama_cpp_dart.dart";

class InferenceEngine {
  LlamaParent? _parent;
  LlamaScope? _scope;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<dynamic>? _completionSub;
  String? _currentPath;

  Future<void> loadModel(String path) async {
    if (_parent != null && _currentPath == path) return;
    await _scope?.dispose();
    await _parent?.dispose();
    Llama.libraryPath = _libraryPath();
    final contextParams = ContextParams()..nCtx = 2048;
    final samplingParams = SamplerParams()
      ..temp = 0.7
      ..topP = 0.9;
    final load = LlamaLoad(
      path: path,
      modelParams: ModelParams(),
      contextParams: contextParams,
      samplingParams: samplingParams,
    );
    _parent = LlamaParent(load);
    await _parent!.init();
    _currentPath = path;
  }

  Stream<String> generate(String prompt) {
    if (_parent == null) {
      return Stream.error(StateError("Model not loaded"));
    }
    final controller = StreamController<String>();
    _scope?.dispose();
    _scope = LlamaScope(_parent!);
    _tokenSub?.cancel();
    _completionSub?.cancel();

    _tokenSub = _scope!.stream.listen(
      controller.add,
      onError: controller.addError,
    );
    _completionSub = _scope!.completions.listen(
      (_) async {
        await controller.close();
      },
      onError: controller.addError,
    );

    _scope!.sendPrompt(prompt);
    return controller.stream;
  }

  Future<void> stop() async {
    await _scope?.stop();
  }

  Future<void> dispose() async {
    await _scope?.dispose();
    await _parent?.dispose();
  }

  String _libraryPath() {
    if (Platform.isAndroid) return "libllama.so";
    if (Platform.isIOS) return "libllama.dylib";
    return "libllama.so";
  }
}
