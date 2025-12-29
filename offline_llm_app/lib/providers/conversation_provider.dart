// conversation_provider.dart
// State management for conversations
// Manages conversation list, active conversation, and persistence

import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../services/conversation_storage.dart';

class ConversationProvider with ChangeNotifier {
  final ConversationStorage _storage = ConversationStorage();
  
  List<Conversation> _conversations = [];
  Conversation? _activeConversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;

  List<Conversation> get conversations => _conversations;
  Conversation? get activeConversation => _activeConversation;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get hasActiveConversation => _activeConversation != null;

  /// Initialize and load conversations from storage
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _storage.loadConversations();
      _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      final activeId = await _storage.getActiveConversationId();
      if (activeId != null) {
        final active = _conversations.firstWhere(
          (c) => c.id == activeId,
          orElse: () => _conversations.isNotEmpty ? _conversations.first : _createNewConversation(),
        );
        await switchConversation(active.id);
      } else if (_conversations.isEmpty) {
        await createNewConversation();
      } else {
        await switchConversation(_conversations.first.id);
      }
    } catch (e) {
      await createNewConversation();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new conversation
  Future<void> createNewConversation() async {
    final newConversation = _createNewConversation();
    _conversations.insert(0, newConversation);
    _activeConversation = newConversation;
    _messages = [];
    
    await _saveConversations();
    await _storage.setActiveConversationId(newConversation.id);
    notifyListeners();
  }

  /// Switch to a different conversation
  Future<void> switchConversation(String conversationId) async {
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => _createNewConversation(),
    );

    _activeConversation = conversation;
    _messages = await _storage.loadMessages(conversationId);
    await _storage.setActiveConversationId(conversationId);
    notifyListeners();
  }

  /// Add a message to the active conversation
  Future<void> addMessage(ChatMessage message) async {
    if (_activeConversation == null) return;

    _messages.add(message);
    
    // Update conversation metadata
    String title = _activeConversation!.title;
    if (_activeConversation!.messageCount == 0 && message.isUser) {
      title = Conversation.generateTitle(message.content);
    }

    _activeConversation = _activeConversation!.copyWith(
      title: title,
      updatedAt: DateTime.now(),
      messageCount: _messages.length,
    );

    // Update in list
    final index = _conversations.indexWhere((c) => c.id == _activeConversation!.id);
    if (index != -1) {
      _conversations[index] = _activeConversation!;
      // Move to top
      if (index != 0) {
        _conversations.removeAt(index);
        _conversations.insert(0, _activeConversation!);
      }
    }

    await _saveMessages();
    await _saveConversations();
    notifyListeners();
  }

  /// Update a message in the active conversation
  Future<void> updateMessage(String messageId, String content) async {
    if (_activeConversation == null) return;

    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(content: content);
      await _saveMessages();
      notifyListeners();
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    await _storage.deleteConversation(conversationId);
    await _saveConversations();

    // If deleted conversation was active, switch to another
    if (_activeConversation?.id == conversationId) {
      if (_conversations.isNotEmpty) {
        await switchConversation(_conversations.first.id);
      } else {
        await createNewConversation();
      }
    } else {
      notifyListeners();
    }
  }

  /// Rename a conversation
  Future<void> renameConversation(String conversationId, String newTitle) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index] = _conversations[index].copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      
      if (_activeConversation?.id == conversationId) {
        _activeConversation = _conversations[index];
      }

      await _saveConversations();
      notifyListeners();
    }
  }

  /// Clear all messages in the active conversation
  Future<void> clearActiveConversation() async {
    if (_activeConversation == null) return;

    _messages.clear();
    _activeConversation = _activeConversation!.copyWith(
      messageCount: 0,
      updatedAt: DateTime.now(),
    );

    final index = _conversations.indexWhere((c) => c.id == _activeConversation!.id);
    if (index != -1) {
      _conversations[index] = _activeConversation!;
    }

    await _saveMessages();
    await _saveConversations();
    notifyListeners();
  }

  /// Save conversations metadata
  Future<void> _saveConversations() async {
    await _storage.saveConversations(_conversations);
  }

  /// Save messages for active conversation
  Future<void> _saveMessages() async {
    if (_activeConversation != null) {
      await _storage.saveMessages(_activeConversation!.id, _messages);
    }
  }

  /// Create a new conversation instance
  Conversation _createNewConversation() {
    return Conversation(
      title: 'New Chat',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
