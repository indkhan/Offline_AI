import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  const ChatMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String content;
  final DateTime createdAt;

  ChatMessageEntity copyWith({
    String? id,
    String? role,
    String? content,
    DateTime? createdAt,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, role, content, createdAt];
}
