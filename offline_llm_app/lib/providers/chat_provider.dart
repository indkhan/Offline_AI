// chat_provider.dart
// State management for chat functionality
// Handles message sending, streaming responses, and conversation management

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/llama_service.dart';
import '../services/model_manager.dart';
import 'conversation_provider.dart';
import 'streaming_message_notifier.dart';

/// Provider for chat state and operations
/// Optimized for extreme performance with:
/// - Optimistic UI (no blocking on message insert)
/// - Token buffering (30 FPS updates, not per-token)
/// - Minimal rebuilds (only active message bubble)
class ChatProvider extends ChangeNotifier {
  final LlamaService _llamaService = LlamaService.instance;
  final ModelManager _modelManager = ModelManager.instance;
  ConversationProvider? _conversationProvider;
  
  bool _isGenerating = false;
  bool _isModelLoading = false;
  String? _currentModelId;
  String? _error;
  StreamSubscription<String>? _generationSubscription;
  
  // Streaming message notifier - only this rebuilds during generation
  StreamingMessageNotifier? _streamingNotifier;
  String? _streamingMessageId;
  
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
  StreamingMessageNotifier? get streamingNotifier => _streamingNotifier;
  String? get streamingMessageId => _streamingMessageId;
  
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
  /// OPTIMISTIC UI: Messages appear instantly, no blocking
  void sendMessage(String content) {
    if (content.trim().isEmpty) return;
    if (!hasModel) {
      _error = 'No model loaded';
      notifyListeners();
      return;
    }
    if (_isGenerating) return;
    
    _error = null;
    
    // OPTIMISTIC UI: Add user message immediately to in-memory state
    final userMessage = ChatMessage(
      role: MessageRole.user,
      content: content.trim(),
    );
    _conversationProvider?.addMessageOptimistic(userMessage);
    notifyListeners(); // Trigger rebuild to show user message
    
    // Create assistant message placeholder immediately
    final assistantMessage = ChatMessage(
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    _conversationProvider?.addMessageOptimistic(assistantMessage);
    _streamingMessageId = assistantMessage.id;
    
    // Create streaming notifier for this message
    _streamingNotifier?.dispose();
    _streamingNotifier = StreamingMessageNotifier();
    
    _isGenerating = true;
    notifyListeners(); // Show assistant placeholder
    
    // Persist messages asynchronously (non-blocking)
    _conversationProvider?.persistMessagesAsync([userMessage, assistantMessage]);
    
    // Start generation in background
    _startGeneration();
  }
  
  /// Start generation (separated for clarity)
  void _startGeneration() {
    try {
      final prompt = _buildPrompt();
      
      final stream = _llamaService.generate(GenerationParams(
        prompt: prompt,
        maxTokens: _maxTokens,
        temperature: _temperature,
        topP: _topP,
      ));
      
      _generationSubscription = stream.listen(
        (token) {
          // TOKEN BUFFERING: Append to buffer, updates at 30 FPS
          _streamingNotifier?.appendToken(token);
        },
        onError: (error) {
          _error = error.toString();
          _finalizeGeneration();
        },
        onDone: () {
          _finalizeGeneration();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }
  
  /// Finalize generation and persist
  void _finalizeGeneration() {
    // Force final flush of buffer
    _streamingNotifier?.finalize();
    
    final finalContent = _streamingNotifier?.value ?? '';
    
    // Update in-memory message
    _conversationProvider?.updateMessageOptimistic(
      _streamingMessageId!,
      finalContent,
      isStreaming: false,
    );
    
    // Persist final message asynchronously (checkpoint)
    _conversationProvider?.persistMessageCheckpoint(_streamingMessageId!, finalContent);
    
    _isGenerating = false;
    _streamingMessageId = null;
    notifyListeners(); // Update generation state only
  }

  /// Stop the current generation
  void stopGeneration() {
    if (_isGenerating) {
      _llamaService.cancelGeneration();
      _generationSubscription?.cancel();
      _generationSubscription = null;
      
      // Finalize partial generation
      _finalizeGeneration();
    }
  }
  
  @override
  void dispose() {
    _streamingNotifier?.dispose();
    _generationSubscription?.cancel();
    super.dispose();
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
}
