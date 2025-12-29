// conversation_storage.dart
// Persistent storage service for conversations and messages
// Uses shared_preferences for metadata and JSON files for message history

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';

class ConversationStorage {
  static const String _conversationsKey = 'conversations';
  static const String _activeConversationKey = 'active_conversation';

  /// Get the directory for storing conversation messages
  Future<Directory> _getConversationsDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final conversationsDir = Directory('${appDir.path}/conversations');
    if (!await conversationsDir.exists()) {
      await conversationsDir.create(recursive: true);
    }
    return conversationsDir;
  }

  /// Get file path for a conversation's messages
  Future<File> _getMessagesFile(String conversationId) async {
    final dir = await _getConversationsDir();
    return File('${dir.path}/$conversationId.json');
  }

  /// Load all conversations metadata
  Future<List<Conversation>> loadConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_conversationsKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save all conversations metadata
  Future<void> saveConversations(List<Conversation> conversations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = conversations.map((c) => c.toJson()).toList();
      await prefs.setString(_conversationsKey, json.encode(jsonList));
    } catch (e) {
      // Silent fail
    }
  }

  /// Load messages for a specific conversation
  Future<List<ChatMessage>> loadMessages(String conversationId) async {
    try {
      final file = await _getMessagesFile(conversationId);
      if (!await file.exists()) return [];

      final jsonString = await file.readAsString();
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Save messages for a specific conversation
  Future<void> saveMessages(
    String conversationId,
    List<ChatMessage> messages,
  ) async {
    try {
      final file = await _getMessagesFile(conversationId);
      final jsonList = messages.map((m) => m.toJson()).toList();
      await file.writeAsString(json.encode(jsonList));
    } catch (e) {
      // Silent fail
    }
  }

  /// Delete a conversation and its messages
  Future<void> deleteConversation(String conversationId) async {
    try {
      final file = await _getMessagesFile(conversationId);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Silent fail
    }
  }

  /// Get the active conversation ID
  Future<String?> getActiveConversationId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_activeConversationKey);
    } catch (e) {
      return null;
    }
  }

  /// Set the active conversation ID
  Future<void> setActiveConversationId(String? conversationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (conversationId == null) {
        await prefs.remove(_activeConversationKey);
      } else {
        await prefs.setString(_activeConversationKey, conversationId);
      }
    } catch (e) {
      // Silent fail
    }
  }
}
