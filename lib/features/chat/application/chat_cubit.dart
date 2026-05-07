import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/resource_monitor.dart';
import '../../inference/domain/inference_config.dart';
import '../../inference/domain/inference_repository.dart';
import '../../model_manager/domain/model_info.dart';
import '../../model_manager/domain/model_manager_repository.dart';
import '../domain/chat_message_entity.dart';
import '../domain/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository chatRepo;
  final ModelManagerRepository modelRepo;
  final InferenceRepository inference;

  StreamSubscription<String>? _streamSub;
  String _streamingId = '';
  String _buffer = '';

  ChatCubit({
    required this.chatRepo,
    required this.modelRepo,
    required this.inference,
  }) : super(const ChatState());

  Future<void> startNew({String? modelId}) async {
    emit(state.copyWith(phase: ChatPhase.loading, clearError: true));
    final conv = await chatRepo.createConversation(modelId: modelId);
    emit(ChatState(conversation: conv, messages: const [], phase: ChatPhase.idle));
  }

  Future<void> open(String conversationId) async {
    emit(state.copyWith(phase: ChatPhase.loading, clearError: true));
    final conv = await chatRepo.getConversation(conversationId);
    if (conv == null) {
      emit(state.copyWith(phase: ChatPhase.error, errorMessage: 'Conversation not found'));
      return;
    }
    final msgs = await chatRepo.listMessages(conversationId);
    emit(ChatState(conversation: conv, messages: msgs, phase: ChatPhase.idle));
  }

  Future<void> send(String text, {required ModelInfo model}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (state.phase == ChatPhase.streaming) return;

    var conv = state.conversation;
    conv ??= await chatRepo.createConversation(modelId: model.id);

    final installed = await modelRepo.getInstalled(model.id);
    if (installed == null) {
      emit(state.copyWith(
        conversation: conv,
        phase: ChatPhase.error,
        errorMessage: 'Model not installed. Download it first.',
      ));
      return;
    }

    final user = await chatRepo.appendMessage(
      conversationId: conv.id,
      role: ChatRole.user,
      content: trimmed,
    );

    final assistantPlaceholder = await chatRepo.appendMessage(
      conversationId: conv.id,
      role: ChatRole.assistant,
      content: '',
    );

    final updatedMsgs = List<ChatMessage>.from(state.messages)
      ..add(user)
      ..add(assistantPlaceholder);

    final maybeTitle = (state.messages.isEmpty)
        ? trimmed.substring(0, trimmed.length.clamp(0, 60))
        : null;
    if (maybeTitle != null) {
      await chatRepo.updateConversationTitle(conv.id, maybeTitle);
      conv = await chatRepo.getConversation(conv.id) ?? conv;
    }

    emit(state.copyWith(
      conversation: conv,
      messages: updatedMsgs,
      phase: ChatPhase.streaming,
      clearError: true,
    ));

    _streamingId = assistantPlaceholder.id;
    _buffer = '';

    final profile = ResourceMonitor.pick();
    final history = updatedMsgs
        .where((m) => m.id != assistantPlaceholder.id)
        .map((m) => ChatTurn(role: roleToString(m.role), content: m.content))
        .toList();

    final cfg = InferenceConfig(
      modelPath: installed.path,
      messages: history,
      maxTokens: 512,
      contextSize: profile.contextSize,
      gpuLayers: profile.gpuLayers,
    );

    _streamSub?.cancel();
    _streamSub = inference.generate(cfg).listen(
      (delta) {
        _buffer += delta;
        final list = state.messages.map((m) {
          if (m.id == _streamingId) return m.copyWith(content: _buffer);
          return m;
        }).toList();
        emit(state.copyWith(messages: list));
      },
      onError: (e) async {
        await chatRepo.updateMessageContent(_streamingId, _buffer);
        emit(state.copyWith(
          phase: ChatPhase.error,
          errorMessage: e.toString(),
        ));
      },
      onDone: () async {
        await chatRepo.updateMessageContent(_streamingId, _buffer);
        emit(state.copyWith(phase: ChatPhase.idle));
      },
    );
  }

  Future<void> stop() async {
    await inference.stop();
    await _streamSub?.cancel();
    if (_streamingId.isNotEmpty) {
      await chatRepo.updateMessageContent(_streamingId, _buffer);
    }
    emit(state.copyWith(phase: ChatPhase.idle));
  }

  Future<void> regenerate({required ModelInfo model}) async {
    if (state.messages.length < 2) return;
    if (state.phase == ChatPhase.streaming) return;
    final last = state.messages.last;
    if (last.role != ChatRole.assistant) return;
    await chatRepo.deleteMessage(last.id);
    final pruned = state.messages.sublist(0, state.messages.length - 1);
    final lastUser = pruned.lastWhere(
      (m) => m.role == ChatRole.user,
      orElse: () => const ChatMessage(
          id: '', conversationId: '', role: ChatRole.user, content: '', createdAt: 0),
    );
    if (lastUser.id.isEmpty) return;
    await chatRepo.deleteMessage(lastUser.id);
    final base = pruned.where((m) => m.id != lastUser.id).toList();
    emit(state.copyWith(messages: base));
    await send(lastUser.content, model: model);
  }

  Future<void> clear() async {
    if (state.conversation != null) {
      await chatRepo.deleteConversation(state.conversation!.id);
    }
    emit(const ChatState());
  }

  @override
  Future<void> close() async {
    await _streamSub?.cancel();
    return super.close();
  }
}
