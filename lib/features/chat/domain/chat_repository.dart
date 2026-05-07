import 'chat_message_entity.dart';

abstract class ChatRepository {
  Future<Conversation> createConversation({String? title, String? modelId});
  Future<List<Conversation>> listConversations();
  Future<Conversation?> getConversation(String id);
  Future<void> updateConversationTitle(String id, String title);
  Future<void> deleteConversation(String id);

  Future<List<ChatMessage>> listMessages(String conversationId);
  Future<ChatMessage> appendMessage({
    required String conversationId,
    required ChatRole role,
    required String content,
  });
  Future<void> updateMessageContent(String id, String content);
  Future<void> deleteMessage(String id);
}
