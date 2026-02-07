import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/resource_monitor.dart';
import '../../inference/domain/inference_config.dart';
import '../../inference/domain/inference_repository.dart';
import '../../model_manager/domain/model_manager_repository.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/chat_message_entity.dart';
import '../domain/chat_repository.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required ChatRepository chatRepository,
    required InferenceRepository inferenceRepository,
    required ModelManagerRepository modelManagerRepository,
    required SettingsRepository settingsRepository,
  }) : _chatRepository = chatRepository,
       _inferenceRepository = inferenceRepository,
       _modelManagerRepository = modelManagerRepository,
       _settingsRepository = settingsRepository,
       super(const ChatState.initial());

  final ChatRepository _chatRepository;
  final InferenceRepository _inferenceRepository;
  final ModelManagerRepository _modelManagerRepository;
  final SettingsRepository _settingsRepository;
  final ResourceMonitor _resourceMonitor = const ResourceMonitor();
  final Uuid _uuid = const Uuid();

  StreamSubscription<String>? _streamSubscription;

  Future<void> initialize() async {
    final conversationId = await _chatRepository.getOrCreateConversationId();
    final messages = await _chatRepository.readMessages(conversationId);
    emit(
      state.copyWith(
        conversationId: conversationId,
        messages: messages,
        clearError: true,
      ),
    );
  }

  Future<void> sendMessage(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty || state.isGenerating || state.conversationId == null) {
      return;
    }

    final selected = await _settingsRepository.getSelectedModel();
    if (selected == null) {
      emit(state.copyWith(error: 'Select a model first.'));
      return;
    }

    final installed = await _modelManagerRepository.getInstalledModels();
    final modelPath = installed[selected];
    if (modelPath == null) {
      emit(state.copyWith(error: 'Selected model is not installed.'));
      return;
    }

    await _inferenceRepository.loadModel(modelPath);

    final userMessage = ChatMessageEntity(
      id: _uuid.v4(),
      role: 'user',
      content: trimmed,
      createdAt: DateTime.now(),
    );

    await _chatRepository.appendMessage(state.conversationId!, userMessage);

    final assistantMessage = ChatMessageEntity(
      id: _uuid.v4(),
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );

    final working = <ChatMessageEntity>[
      ...state.messages,
      userMessage,
      assistantMessage,
    ];
    final advice = _resourceMonitor.currentAdvice();

    emit(
      state.copyWith(
        messages: working,
        isGenerating: true,
        systemNotice: advice.note,
        clearError: true,
      ),
    );

    await _streamSubscription?.cancel();
    _streamSubscription = _inferenceRepository
        .streamCompletion(
          working.where((message) => message.content.isNotEmpty).toList(),
          InferenceConfig(maxTokens: advice.maxTokens, temperature: 0.7),
        )
        .listen(
          (token) {
            final current = state.messages;
            if (current.isEmpty) {
              return;
            }
            final last = current.last;
            final updatedLast = last.copyWith(content: last.content + token);
            emit(
              state.copyWith(
                messages: [
                  ...current.sublist(0, current.length - 1),
                  updatedLast,
                ],
              ),
            );
          },
          onError: (Object error) {
            emit(state.copyWith(isGenerating: false, error: error.toString()));
          },
          onDone: () async {
            final last = state.messages.isNotEmpty ? state.messages.last : null;
            if (last != null &&
                last.role == 'assistant' &&
                last.content.trim().isNotEmpty) {
              await _chatRepository.appendMessage(state.conversationId!, last);
            }
            emit(state.copyWith(isGenerating: false));
          },
          cancelOnError: true,
        );
  }

  Future<void> stopGeneration() async {
    if (!state.isGenerating) {
      return;
    }
    await _inferenceRepository.stopGeneration();
    await _streamSubscription?.cancel();
    emit(state.copyWith(isGenerating: false));
  }

  Future<void> regenerate() async {
    if (state.isGenerating ||
        state.conversationId == null ||
        state.messages.isEmpty) {
      return;
    }

    final messages = [...state.messages];
    if (messages.last.role == 'assistant') {
      messages.removeLast();
      await _chatRepository.removeLastAssistantMessage(state.conversationId!);
      emit(state.copyWith(messages: messages));
    }

    final lastUser = messages.lastWhere(
      (message) => message.role == 'user',
      orElse: () => ChatMessageEntity(
        id: '',
        role: 'user',
        content: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );

    if (lastUser.content.isEmpty) {
      return;
    }

    final assistantMessage = ChatMessageEntity(
      id: _uuid.v4(),
      role: 'assistant',
      content: '',
      createdAt: DateTime.now(),
    );

    final working = [...messages, assistantMessage];
    final advice = _resourceMonitor.currentAdvice();

    emit(
      state.copyWith(
        messages: working,
        isGenerating: true,
        systemNotice: advice.note,
        clearError: true,
      ),
    );

    await _streamSubscription?.cancel();
    _streamSubscription = _inferenceRepository
        .streamCompletion(
          working.where((message) => message.content.isNotEmpty).toList(),
          InferenceConfig(maxTokens: advice.maxTokens, temperature: 0.7),
        )
        .listen(
          (token) {
            final current = state.messages;
            final last = current.last;
            final updatedLast = last.copyWith(content: last.content + token);
            emit(
              state.copyWith(
                messages: [
                  ...current.sublist(0, current.length - 1),
                  updatedLast,
                ],
              ),
            );
          },
          onDone: () async {
            final last = state.messages.last;
            if (last.role == 'assistant' && last.content.trim().isNotEmpty) {
              await _chatRepository.appendMessage(state.conversationId!, last);
            }
            emit(state.copyWith(isGenerating: false));
          },
          onError: (Object error) {
            emit(state.copyWith(isGenerating: false, error: error.toString()));
          },
          cancelOnError: true,
        );
  }

  Future<void> clearConversation() async {
    final id = state.conversationId;
    if (id == null) {
      return;
    }
    await stopGeneration();
    await _chatRepository.clearConversation(id);
    emit(state.copyWith(messages: <ChatMessageEntity>[]));
  }

  @override
  Future<void> close() async {
    await _streamSubscription?.cancel();
    return super.close();
  }
}
