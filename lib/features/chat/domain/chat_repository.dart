import 'chat_message_entity.dart';

abstract class ChatRepository {
  Future<String> getOrCreateConversationId();
  Future<List<ChatMessageEntity>> readMessages(String conversationId);
  Future<void> appendMessage(String conversationId, ChatMessageEntity message);
  Future<void> clearConversation(String conversationId);
  Future<void> removeLastAssistantMessage(String conversationId);
}
