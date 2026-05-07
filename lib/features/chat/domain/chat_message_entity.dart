import 'package:equatable/equatable.dart';

enum ChatRole { user, assistant, system }

ChatRole roleFromString(String s) {
  switch (s) {
    case 'assistant':
      return ChatRole.assistant;
    case 'system':
      return ChatRole.system;
    default:
      return ChatRole.user;
  }
}

String roleToString(ChatRole r) {
  switch (r) {
    case ChatRole.assistant:
      return 'assistant';
    case ChatRole.system:
      return 'system';
    case ChatRole.user:
      return 'user';
  }
}

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final ChatRole role;
  final String content;
  final int createdAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  ChatMessage copyWith({String? content}) => ChatMessage(
        id: id,
        conversationId: conversationId,
        role: role,
        content: content ?? this.content,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, content];
}

class Conversation extends Equatable {
  final String id;
  final String title;
  final String? modelId;
  final int createdAt;
  final int updatedAt;

  const Conversation({
    required this.id,
    required this.title,
    required this.modelId,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, title, updatedAt];
}
