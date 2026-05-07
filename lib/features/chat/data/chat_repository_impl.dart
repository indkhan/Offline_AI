import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../domain/chat_message_entity.dart';
import '../domain/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Database db;
  final _uuid = const Uuid();

  ChatRepositoryImpl(this.db);

  int _now() => DateTime.now().millisecondsSinceEpoch;

  @override
  Future<Conversation> createConversation({String? title, String? modelId}) async {
    final now = _now();
    final id = _uuid.v4();
    final t = title ?? 'New chat';
    await db.insert('conversations', {
      'id': id,
      'title': t,
      'model_id': modelId,
      'created_at': now,
      'updated_at': now,
    });
    return Conversation(
      id: id,
      title: t,
      modelId: modelId,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<List<Conversation>> listConversations() async {
    final rows = await db.query('conversations', orderBy: 'updated_at DESC');
    return rows.map(_rowToConv).toList();
  }

  @override
  Future<Conversation?> getConversation(String id) async {
    final rows = await db.query('conversations',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _rowToConv(rows.first);
  }

  Conversation _rowToConv(Map<String, Object?> row) => Conversation(
        id: row['id'] as String,
        title: row['title'] as String,
        modelId: row['model_id'] as String?,
        createdAt: row['created_at'] as int,
        updatedAt: row['updated_at'] as int,
      );

  @override
  Future<void> updateConversationTitle(String id, String title) async {
    await db.update('conversations',
        {'title': title, 'updated_at': _now()},
        where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteConversation(String id) async {
    await db.delete('messages', where: 'conversation_id = ?', whereArgs: [id]);
    await db.delete('conversations', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ChatMessage>> listMessages(String conversationId) async {
    final rows = await db.query(
      'messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );
    return rows
        .map((r) => ChatMessage(
              id: r['id'] as String,
              conversationId: r['conversation_id'] as String,
              role: roleFromString(r['role'] as String),
              content: r['content'] as String,
              createdAt: r['created_at'] as int,
            ))
        .toList();
  }

  @override
  Future<ChatMessage> appendMessage({
    required String conversationId,
    required ChatRole role,
    required String content,
  }) async {
    final now = _now();
    final id = _uuid.v4();
    await db.insert('messages', {
      'id': id,
      'conversation_id': conversationId,
      'role': roleToString(role),
      'content': content,
      'created_at': now,
    });
    await db.update('conversations', {'updated_at': now},
        where: 'id = ?', whereArgs: [conversationId]);
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: now,
    );
  }

  @override
  Future<void> updateMessageContent(String id, String content) async {
    await db.update('messages', {'content': content},
        where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteMessage(String id) async {
    await db.delete('messages', where: 'id = ?', whereArgs: [id]);
  }
}
