import 'package:equatable/equatable.dart';

import '../domain/chat_message_entity.dart';

class ChatState extends Equatable {
  const ChatState({
    required this.conversationId,
    required this.messages,
    required this.isGenerating,
    required this.error,
    required this.systemNotice,
  });

  const ChatState.initial()
    : conversationId = null,
      messages = const <ChatMessageEntity>[],
      isGenerating = false,
      error = null,
      systemNotice = null;

  final String? conversationId;
  final List<ChatMessageEntity> messages;
  final bool isGenerating;
  final String? error;
  final String? systemNotice;

  ChatState copyWith({
    String? conversationId,
    List<ChatMessageEntity>? messages,
    bool? isGenerating,
    String? error,
    String? systemNotice,
    bool clearError = false,
    bool clearSystemNotice = false,
  }) {
    return ChatState(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : error ?? this.error,
      systemNotice: clearSystemNotice
          ? null
          : systemNotice ?? this.systemNotice,
    );
  }

  @override
  List<Object?> get props => [
    conversationId,
    messages,
    isGenerating,
    error,
    systemNotice,
  ];
}
