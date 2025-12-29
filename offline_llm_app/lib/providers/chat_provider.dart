// chat_provider.dart
// State management for chat functionality
// Handles message sending, streaming responses, and conversation management

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/llama_service.dart';
import '../services/model_manager.dart';
import 'conversation_provider.dart';

/// Provider for chat state and operations
class ChatProvider extends ChangeNotifier {
  final LlamaService _llamaService = LlamaService.instance;
  final ModelManager _modelManager = ModelManager.instance;
  ConversationProvider? _conversationProvider;
  
  bool _isGenerating = false;
  bool _isModelLoading = false;
  String? _currentModelId;
  String? _error;
  StreamSubscription<String>? _generationSubscription;
  
  // Generation settings
  int _maxTokens = 512;
  double _temperature = 0.7;
  double _topP = 0.9;
  
  List<ChatMessage> get messages => _conversationProvider?.messages ?? [];
  bool get isGenerating => _isGenerating;
  bool get isModelLoading => _isModelLoading;
  String? get currentModelId => _currentModelId;
  String? get error => _error;
  bool get hasModel => _currentModelId != null && _llamaService.isModelLoaded;
  
  int get maxTokens => _maxTokens;
  double get temperature => _temperature;
  double get topP => _topP;

  /// Set the conversation provider
  void setConversationProvider(ConversationProvider provider) {
    _conversationProvider = provider;
  }

  /// Initialize the provider
  Future<void> initialize() async {
    await _llamaService.initialize();
    
    // Try to load the previously active model
    final activeModelId = _modelManager.activeModelId;
    if (activeModelId != null && _modelManager.isModelDownloaded(activeModelId)) {
      await loadModel(activeModelId);
    }
  }

  /// Load a model by ID
  Future<bool> loadModel(String modelId) async {
    if (_isModelLoading) return false;
    
    final modelPath = _modelManager.getModelPath(modelId);
    if (modelPath == null) {
      _error = 'Model not downloaded';
      notifyListeners();
      return false;
    }
    
    _isModelLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final result = await _llamaService.loadModel(modelPath);
      
      if (result.success) {
        _currentModelId = modelId;
        await _modelManager.setActiveModel(modelId);
        _error = null;
      } else {
        _error = result.error ?? 'Failed to load model';
        _currentModelId = null;
      }
      
      return result.success;
    } catch (e) {
      _error = e.toString();
      _currentModelId = null;
      return false;
    } finally {
      _isModelLoading = false;
      notifyListeners();
    }
  }

  /// Unload the current model
  Future<void> unloadModel() async {
    await _llamaService.unloadModel();
    _currentModelId = null;
    await _modelManager.setActiveModel(null);
    notifyListeners();
  }

  /// Send a message and get a response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (!hasModel) {
      _error = 'No model loaded';
      notifyListeners();
      return;
    }
    if (_isGenerating) return;
    
    _error = null;
    
    // Add user message
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: content.trim(),
    );
    await _conversationProvider?.addMessage(userMessage);
    notifyListeners();
    
    // Create assistant message placeholder
    final assistantMessage = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    await _conversationProvider?.addMessage(assistantMessage);
    _isGenerating = true;
    notifyListeners();
    
    try {
      // Build the prompt with chat history
      final prompt = _buildPrompt();
      
      // Start generation
      final stream = _llamaService.generate(GenerationParams(
        prompt: prompt,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topP: _topP,
      ));
      
      final buffer = StringBuffer();
      
      _generationSubscription = stream.listen(
        (token) {
          buffer.write(token);
          _updateLastMessage(buffer.toString(), isStreaming: true);
        },
        onError: (error) {
          _error = error.toString();
          _isGenerating = false;
          _updateLastMessage(buffer.toString(), isStreaming: false).then((_) => notifyListeners());
        },
        onDone: () {
          _isGenerating = false;
          _updateLastMessage(buffer.toString(), isStreaming: false).then((_) => notifyListeners());
        },
      );
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Stop the current generation
  void stopGeneration() {
    if (_isGenerating) {
      _llamaService.cancelGeneration();
      _generationSubscription?.cancel();
      _generationSubscription = null;
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Update the last message content
  Future<void> _updateLastMessage(String content, {required bool isStreaming}) async {
    final messages = _conversationProvider?.messages ?? [];
    if (messages.isEmpty) return;
    
    final lastMsg = messages.last;
    if (lastMsg.role == MessageRole.assistant) {
      await _conversationProvider?.updateMessage(lastMsg.id, content);
      notifyListeners();
    }
  }

  /// Build the prompt from chat history
  String _buildPrompt() {
    final buffer = StringBuffer();
    final messages = _conversationProvider?.messages ?? [];
    
    // Use appropriate chat template based on model
    if (_currentModelId?.contains('qwen') ?? false) {
      // Qwen chat template
      buffer.writeln('<|im_start|>system');
      buffer.writeln('You are a helpful AI assistant.<|im_end|>');
      
      for (final msg in messages) {
        if (msg.role == MessageRole.user) {
          buffer.writeln('<|im_start|>user');
          buffer.writeln('${msg.content}<|im_end|>');
        } else if (msg.role == MessageRole.assistant && msg.content.isNotEmpty) {
          buffer.writeln('<|im_start|>assistant');
          buffer.writeln('${msg.content}<|im_end|>');
        }
      }
      buffer.writeln('<|im_start|>assistant');
    } else if (_currentModelId?.contains('gemma') ?? false) {
      // Gemma chat template
      buffer.writeln('<start_of_turn>user');
      
      for (final msg in messages) {
        if (msg.role == MessageRole.user) {
          buffer.writeln('${msg.content}<end_of_turn>');
          buffer.writeln('<start_of_turn>model');
        } else if (msg.role == MessageRole.assistant && msg.content.isNotEmpty) {
          buffer.writeln('${msg.content}<end_of_turn>');
          buffer.writeln('<start_of_turn>user');
        }
      }
    } else {
      // Generic chat template
      buffer.writeln('### System: You are a helpful AI assistant.\n');
      
      for (final msg in messages) {
        if (msg.role == MessageRole.user) {
          buffer.writeln('### User: ${msg.content}\n');
        } else if (msg.role == MessageRole.assistant && msg.content.isNotEmpty) {
          buffer.writeln('### Assistant: ${msg.content}\n');
        }
      }
      buffer.writeln('### Assistant:');
    }
    
    return buffer.toString();
  }

  /// Clear chat history
  Future<void> clearChat() async {
    await _conversationProvider?.clearActiveConversation();
    _error = null;
    notifyListeners();
  }

  /// Update generation settings
  void updateSettings({int? maxTokens, double? temperature, double? topP}) {
    if (maxTokens != null) _maxTokens = maxTokens;
    if (temperature != null) _temperature = temperature;
    if (topP != null) _topP = topP;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _generationSubscription?.cancel();
    super.dispose();
  }
}
