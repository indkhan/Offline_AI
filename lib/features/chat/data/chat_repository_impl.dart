import '../../storage/app_database.dart';
import '../domain/chat_message_entity.dart';
import '../domain/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  @override
  Future<void> appendMessage(String conversationId, ChatMessageEntity message) {
    return _database.insertMessage(
      conversationId: conversationId,
      messageId: message.id,
      role: message.role,
      content: message.content,
      createdAt: message.createdAt,
    );
  }

  @override
  Future<void> clearConversation(String conversationId) {
    return _database.clearConversation(conversationId);
  }

  @override
  Future<String> getOrCreateConversationId() {
    return _database.getOrCreateDefaultConversation();
  }

  @override
  Future<List<ChatMessageEntity>> readMessages(String conversationId) {
    return _database.readMessages(conversationId);
  }

  @override
  Future<void> removeLastAssistantMessage(String conversationId) {
    return _database.removeLastAssistantMessage(conversationId);
  }
}
