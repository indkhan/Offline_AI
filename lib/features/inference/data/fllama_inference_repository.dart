import 'dart:async';

import 'package:fllama/fllama.dart';

import '../domain/inference_config.dart';
import '../domain/inference_repository.dart';

class FllamaInferenceRepository implements InferenceRepository {
  int? _activeRequestId;

  @override
  Stream<String> generate(InferenceConfig cfg) {
    final controller = StreamController<String>();
    String last = '';

    final request = OpenAiRequest(
      modelPath: cfg.modelPath,
      messages: cfg.messages
          .map((m) => Message(_roleFor(m.role), m.content))
          .toList(),
      maxTokens: cfg.maxTokens,
      temperature: cfg.temperature,
      topP: cfg.topP,
      contextSize: cfg.contextSize,
      numGpuLayers: cfg.gpuLayers,
    );

    fllamaChat(request, (response, _, done) {
      if (response.length > last.length) {
        controller.add(response.substring(last.length));
        last = response;
      }
      if (done) {
        if (!controller.isClosed) controller.close();
        _activeRequestId = null;
      }
    }).then((id) {
      _activeRequestId = id;
    }).catchError((e) {
      if (!controller.isClosed) {
        controller.addError(e);
        controller.close();
      }
    });

    return controller.stream;
  }

  @override
  Future<void> stop() async {
    final id = _activeRequestId;
    if (id != null) {
      fllamaCancelInference(id);
      _activeRequestId = null;
    }
  }

  Role _roleFor(String r) {
    switch (r) {
      case 'system':
        return Role.system;
      case 'assistant':
        return Role.assistant;
      case 'user':
      default:
        return Role.user;
    }
  }
}
