// conversation.dart
// Data model for chat conversations
// Stores conversation metadata and references to messages

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Represents a chat conversation
class Conversation {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? modelId;
  final int messageCount;

  Conversation({
    String? id,
    required this.title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.modelId,
    this.messageCount = 0,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Create a copy with updated fields
  Conversation copyWith({
    String? title,
    DateTime? updatedAt,
    String? modelId,
    int? messageCount,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      modelId: modelId ?? this.modelId,
      messageCount: messageCount ?? this.messageCount,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'modelId': modelId,
      'messageCount': messageCount,
    };
  }

  /// Create from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      modelId: json['modelId'] as String?,
      messageCount: json['messageCount'] as int? ?? 0,
    );
  }

  /// Generate a title from the first user message
  static String generateTitle(String firstMessage) {
    final cleaned = firstMessage.trim();
    if (cleaned.length <= 40) return cleaned;
    return '${cleaned.substring(0, 37)}...';
  }
}
