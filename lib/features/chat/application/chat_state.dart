import 'package:equatable/equatable.dart';

import '../domain/chat_message_entity.dart';

enum ChatPhase { idle, loading, streaming, error }

class ChatState extends Equatable {
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final ChatPhase phase;
  final String? errorMessage;
  final String? notice;

  const ChatState({
    this.conversation,
    this.messages = const [],
    this.phase = ChatPhase.idle,
    this.errorMessage,
    this.notice,
  });

  ChatState copyWith({
    Conversation? conversation,
    List<ChatMessage>? messages,
    ChatPhase? phase,
    String? errorMessage,
    String? notice,
    bool clearError = false,
    bool clearNotice = false,
  }) {
    return ChatState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      notice: clearNotice ? null : (notice ?? this.notice),
    );
  }

  @override
  List<Object?> get props =>
      [conversation, messages, phase, errorMessage, notice];
}
