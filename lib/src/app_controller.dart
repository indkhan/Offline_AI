import "dart:async";

import "package:flutter/foundation.dart";

import "chat_message.dart";
import "conversation_store.dart";
import "inference_engine.dart";
import "model_manager.dart";
import "model_spec.dart";

class AppController extends ChangeNotifier {
  final ModelManager _modelManager = ModelManager();
  final ConversationStore _store = ConversationStore();
  final InferenceEngine _inference = InferenceEngine();

  final List<ChatMessage> _messages = [];
  final Map<ModelId, DownloadProgress?> _progress = {};
  final Set<ModelId> _downloading = {};

  bool _isGenerating = false;
  ModelId _activeModel = ModelId.qwen;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isGenerating => _isGenerating;
  ModelId get activeModel => _activeModel;

  Future<void> init() async {
    await _modelManager.init();
    _messages.addAll(await _store.load());
    notifyListeners();
  }

  ModelSpec specFor(ModelId id) =>
      kModels.firstWhere((m) => m.id == id);

  ModelStatus getModelStatus(ModelId id) =>
      _modelManager.getStatus(specFor(id));

  DownloadProgress? downloadProgressFor(ModelId id) => _progress[id];

  bool isDownloading(ModelId id) => _downloading.contains(id);

  Future<void> startDownload(ModelId id) async {
    final spec = specFor(id);
    if (_downloading.contains(id)) return;
    _downloading.add(id);
    _progress[id] = const DownloadProgress(
      receivedBytes: 0,
      totalBytes: 0,
      phase: DownloadPhase.downloading,
    );
    notifyListeners();

    _modelManager.download(spec).listen(
      (progress) {
        _progress[id] = progress;
        if (progress.phase == DownloadPhase.done ||
            progress.phase == DownloadPhase.error) {
          _downloading.remove(id);
        }
        notifyListeners();
      },
      onError: (_) {
        _downloading.remove(id);
        _progress[id] = const DownloadProgress(
          receivedBytes: 0,
          totalBytes: 0,
          phase: DownloadPhase.error,
        );
        notifyListeners();
      },
    );
  }

  Future<void> deleteModel(ModelId id) async {
    final spec = specFor(id);
    await _modelManager.delete(spec);
    if (_activeModel == id) {
      _activeModel = ModelId.qwen;
    }
    notifyListeners();
  }

  Future<void> setActiveModel(ModelId id) async {
    _activeModel = id;
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isGenerating) return;
    _messages.add(ChatMessage(role: ChatRole.user, content: text.trim()));
    final assistant = ChatMessage(role: ChatRole.assistant, content: "");
    _messages.add(assistant);
    await _store.save(_messages);
    notifyListeners();

    _isGenerating = true;
    notifyListeners();

    try {
      await _ensureModelLoaded();
      final prompt = _buildChatMlPrompt(_messages);
      await for (final chunk in _inference.generate(prompt)) {
        assistant.content += chunk;
        notifyListeners();
      }
    } catch (e) {
      assistant.content += "\n\n[Error: $e]";
    } finally {
      _isGenerating = false;
      await _store.save(_messages);
      notifyListeners();
    }
  }

  Future<void> stopGeneration() async {
    await _inference.stop();
    _isGenerating = false;
    notifyListeners();
  }

  Future<void> clearConversation() async {
    _messages.clear();
    await _store.save(_messages);
    notifyListeners();
  }

  Future<void> _ensureModelLoaded() async {
    final status = getModelStatus(_activeModel);
    if (!status.isReady || status.path == null) {
      throw StateError("Model not downloaded");
    }
    await _inference.loadModel(status.path!);
  }

  String _buildChatMlPrompt(List<ChatMessage> history) {
    final buffer = StringBuffer();
    for (final msg in history) {
      if (msg.role == ChatRole.assistant && msg.content.isEmpty) continue;
      final role = switch (msg.role) {
        ChatRole.system => "system",
        ChatRole.user => "user",
        ChatRole.assistant => "assistant",
      };
      buffer.write("<|im_start|>$role\n");
      buffer.write(msg.content);
      buffer.write("<|im_end|>\n");
    }
    buffer.write("<|im_start|>assistant\n");
    return buffer.toString();
  }

  @override
  void dispose() {
    unawaited(_inference.dispose());
    super.dispose();
  }
}
