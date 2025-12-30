// conversation_provider.dart
// State management for conversations
// Manages conversation list, active conversation, and persistence

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';
import '../services/conversation_storage.dart';

// Top-level function for compute() - search in messages
bool _searchInMessages(Map<String, dynamic> params) {
  final messages = params['messages'] as List<ChatMessage>;
  final query = params['query'] as String;
  
  return messages.any((msg) => msg.content.toLowerCase().contains(query));
}

class ConversationProvider with ChangeNotifier {
  final ConversationStorage _storage = ConversationStorage();
  
  List<Conversation>? _conversations; // Nullable - lazy load
  Conversation? _activeConversation;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _initialized = false;

  // Search state
  String _searchQuery = '';
  List<Conversation> _filteredConversations = [];
  bool _isSearching = false;
  Timer? _searchDebounce;
  final Map<String, List<ChatMessage>> _messageCache = {}; // Cache for search

  List<Conversation> get conversations => _conversations ?? [];
  Conversation? get activeConversation => _activeConversation;
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get hasActiveConversation => _activeConversation != null;
  
  // Search getters
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;
  List<Conversation> get displayedConversations => 
      _searchQuery.isEmpty ? conversations : _filteredConversations;

  /// Initialize - lazy load, only create new conversation
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    
    // Create a default conversation without loading from storage
    // Storage will be loaded only when drawer is opened
    _activeConversation = _createNewConversation();
    _messages = [];
    
    // Load active conversation ID in background without blocking
    _loadActiveConversationInBackground();
  }

  /// Load conversations and active conversation in background
  Future<void> _loadActiveConversationInBackground() async {
    try {
      final activeId = await _storage.getActiveConversationId();
      if (activeId != null && _conversations == null) {
        // Only load if we don't have conversations yet
        await ensureConversationsLoaded();
        final active = _conversations?.firstWhere(
          (c) => c.id == activeId,
          orElse: () => _activeConversation!,
        );
        if (active != null && active.id != _activeConversation?.id) {
          await switchConversation(active.id);
        }
      }
    } catch (e) {
      // Silent fail - keep using default conversation
    }
  }

  /// Ensure conversations are loaded (called when drawer opens)
  Future<void> ensureConversationsLoaded() async {
    if (_conversations != null) return; // Already loaded
    
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _storage.loadConversations();
      _conversations!.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      // Add current active conversation if not in list
      if (_activeConversation != null && 
          !_conversations!.any((c) => c.id == _activeConversation!.id)) {
        _conversations!.insert(0, _activeConversation!);
      }
    } catch (e) {
      _conversations = [_activeConversation ?? _createNewConversation()];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new conversation
  Future<void> createNewConversation() async {
    final newConversation = _createNewConversation();
    _conversations ??= [];
    _conversations!.insert(0, newConversation);
    _activeConversation = newConversation;
    _messages = [];
    
    await _saveConversations();
    await _storage.setActiveConversationId(newConversation.id);
    notifyListeners();
  }

  /// Switch to a different conversation
  Future<void> switchConversation(String conversationId) async {
    await ensureConversationsLoaded();
    
    final conversation = _conversations!.firstWhere(
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
    if (_conversations != null) {
      final index = _conversations!.indexWhere((c) => c.id == _activeConversation!.id);
      if (index != -1) {
        _conversations![index] = _activeConversation!;
        // Move to top
        if (index != 0) {
          _conversations!.removeAt(index);
          _conversations!.insert(0, _activeConversation!);
        }
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
    _conversations?.removeWhere((c) => c.id == conversationId);
    await _storage.deleteConversation(conversationId);
    await _saveConversations();

    // If deleted conversation was active, switch to another
    if (_activeConversation?.id == conversationId) {
      if (_conversations?.isNotEmpty ?? false) {
        await switchConversation(_conversations!.first.id);
      } else {
        await createNewConversation();
      }
    } else {
      notifyListeners();
    }
  }

  /// Rename a conversation
  Future<void> renameConversation(String conversationId, String newTitle) async {
    if (_conversations == null) return;
    final index = _conversations!.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations![index] = _conversations![index].copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      
      if (_activeConversation?.id == conversationId) {
        _activeConversation = _conversations![index];
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

    if (_conversations != null) {
      final index = _conversations!.indexWhere((c) => c.id == _activeConversation!.id);
      if (index != -1) {
        _conversations![index] = _activeConversation!;
      }
    }

    await _saveMessages();
    await _saveConversations();
    notifyListeners();
  }

  /// Save conversations metadata
  Future<void> _saveConversations() async {
    if (_conversations != null) {
      await _storage.saveConversations(_conversations!);
    }
  }

  /// Save messages for active conversation
  Future<void> _saveMessages() async {
    if (_activeConversation != null) {
      await _storage.saveMessages(_activeConversation!.id, _messages);
    }
  }

  /// Search conversations by title and content
  void searchConversations(String query) {
    _searchQuery = query.trim();
    
    // Cancel previous debounce timer
    _searchDebounce?.cancel();
    
    if (_searchQuery.isEmpty) {
      _filteredConversations = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    // Debounce search - wait 300ms after user stops typing
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }
  
  /// Perform the actual search (called after debounce)
  Future<void> _performSearch() async {
    await ensureConversationsLoaded();
    
    final query = _searchQuery.toLowerCase();
    final results = <Conversation>[];
    final contentMatches = <Conversation>[];
    
    // Phase 1: Quick title search (instant)
    for (final conversation in _conversations ?? []) {
      if (conversation.title.toLowerCase().contains(query)) {
        results.add(conversation);
      }
    }
    
    // Update UI with title results immediately
    _filteredConversations = List.from(results);
    _isSearching = false;
    notifyListeners();
    
    // Phase 2: Content search in background (non-blocking)
    _searchInContent(query, results, contentMatches);
  }
  
  /// Search in conversation content (background)
  Future<void> _searchInContent(
    String query,
    List<Conversation> titleMatches,
    List<Conversation> contentMatches,
  ) async {
    for (final conversation in _conversations ?? []) {
      // Skip if already matched by title
      if (titleMatches.any((c) => c.id == conversation.id)) continue;
      
      // Load messages (with caching)
      List<ChatMessage> messages;
      if (_messageCache.containsKey(conversation.id)) {
        messages = _messageCache[conversation.id]!;
      } else {
        messages = await _storage.loadMessages(conversation.id);
        _messageCache[conversation.id] = messages;
      }
      
      // Search in message content using compute for large message lists
      if (messages.length > 20) {
        final hasMatch = await compute(
          _searchInMessages,
          {'messages': messages, 'query': query},
        );
        if (hasMatch) contentMatches.add(conversation);
      } else {
        // Quick search for small lists
        final hasMatch = messages.any(
          (msg) => msg.content.toLowerCase().contains(query),
        );
        if (hasMatch) contentMatches.add(conversation);
      }
      
      // Update UI progressively as matches are found
      if (contentMatches.isNotEmpty && _searchQuery == query) {
        _filteredConversations = [...titleMatches, ...contentMatches];
        notifyListeners();
      }
    }
  }
  
  /// Clear search and show all conversations
  void clearSearch() {
    _searchQuery = '';
    _filteredConversations = [];
    _isSearching = false;
    _searchDebounce?.cancel();
    notifyListeners();
  }
  
  /// Dispose search resources
  @override
  void dispose() {
    _searchDebounce?.cancel();
    _messageCache.clear();
    super.dispose();
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
