// llama_service.dart
// High-level service for LLM inference using llama.cpp via FFI
// Handles model loading, text generation, and streaming

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import '../ffi/llama_bindings.dart';

/// Message types for isolate communication
enum LlamaMessageType {
  init,
  loadModel,
  unloadModel,
  generate,
  cancel,
  token,
  done,
  error,
}

/// Message wrapper for isolate communication
class LlamaMessage {
  final LlamaMessageType type;
  final dynamic data;
  
  LlamaMessage(this.type, [this.data]);
}

/// Generation parameters
class GenerationParams {
  final String prompt;
  final int maxTokens;
  final double temperature;
  final double topP;
  
  GenerationParams({
    required this.prompt,
    this.maxTokens = 512,
    this.temperature = 0.7,
    this.topP = 0.9,
  });
}

/// Result of model loading
class LoadModelResult {
  final bool success;
  final String? error;
  
  LoadModelResult({required this.success, this.error});
}

/// Service for LLM inference
/// Runs inference in a separate isolate to prevent UI blocking
class LlamaService {
  static LlamaService? _instance;
  static LlamaService get instance => _instance ??= LlamaService._();
  
  LlamaService._();
  
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;
  StreamController<String>? _tokenController;
  Completer<LoadModelResult>? _loadCompleter;
  Completer<int>? _generateCompleter;
  
  bool _isInitialized = false;
  bool _isModelLoaded = false;
  bool _isGenerating = false;
  String? _currentModelPath;
  
  bool get isInitialized => _isInitialized;
  bool get isModelLoaded => _isModelLoaded;
  bool get isGenerating => _isGenerating;
  String? get currentModelPath => _currentModelPath;

  /// Initialize the service and spawn the inference isolate
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _receivePort = ReceivePort();
    
    _isolate = await Isolate.spawn(
      _isolateEntry,
      _receivePort!.sendPort,
    );
    
    final completer = Completer<SendPort>();
    
    _receivePort!.listen((message) {
      if (message is SendPort) {
        completer.complete(message);
      } else if (message is LlamaMessage) {
        _handleMessage(message);
      }
    });
    
    _sendPort = await completer.future;
    _sendPort!.send(LlamaMessage(LlamaMessageType.init));
    
    _isInitialized = true;
  }

  /// Handle messages from the isolate
  void _handleMessage(LlamaMessage message) {
    switch (message.type) {
      case LlamaMessageType.loadModel:
        final result = message.data as LoadModelResult;
        _isModelLoaded = result.success;
        _loadCompleter?.complete(result);
        _loadCompleter = null;
        break;
        
      case LlamaMessageType.token:
        _tokenController?.add(message.data as String);
        break;
        
      case LlamaMessageType.done:
        _isGenerating = false;
        _generateCompleter?.complete(message.data as int);
        _generateCompleter = null;
        _tokenController?.close();
        _tokenController = null;
        break;
        
      case LlamaMessageType.error:
        _isGenerating = false;
        _tokenController?.addError(message.data);
        _tokenController?.close();
        _tokenController = null;
        _generateCompleter?.completeError(message.data);
        _generateCompleter = null;
        break;
        
      default:
        break;
    }
  }

  /// Load a model from the specified path
  Future<LoadModelResult> loadModel(String modelPath) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_isModelLoaded) {
      await unloadModel();
    }
    
    _loadCompleter = Completer<LoadModelResult>();
    _currentModelPath = modelPath;
    
    _sendPort!.send(LlamaMessage(LlamaMessageType.loadModel, modelPath));
    
    return _loadCompleter!.future;
  }

  /// Unload the current model
  Future<void> unloadModel() async {
    if (!_isModelLoaded) return;
    
    _sendPort!.send(LlamaMessage(LlamaMessageType.unloadModel));
    _isModelLoaded = false;
    _currentModelPath = null;
  }

  /// Generate text with streaming tokens
  /// Returns a stream of tokens as they are generated
  Stream<String> generate(GenerationParams params) {
    if (!_isModelLoaded) {
      throw StateError('No model loaded');
    }
    
    if (_isGenerating) {
      throw StateError('Generation already in progress');
    }
    
    _isGenerating = true;
    _tokenController = StreamController<String>();
    _generateCompleter = Completer<int>();
    
    _sendPort!.send(LlamaMessage(LlamaMessageType.generate, params));
    
    return _tokenController!.stream;
  }

  /// Cancel ongoing generation
  void cancelGeneration() {
    if (_isGenerating) {
      _sendPort!.send(LlamaMessage(LlamaMessageType.cancel));
    }
  }

  /// Dispose the service
  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _tokenController?.close();
    _isInitialized = false;
    _isModelLoaded = false;
  }
}

/// Isolate entry point for inference
void _isolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);
  
  LlamaBindings? bindings;
  Pointer<Void>? context;
  bool cancelRequested = false;
  
  // Native callback for token streaming
  // We use a static function and communicate via ports
  late final SendPort tokenPort;
  
  receivePort.listen((message) {
    if (message is! LlamaMessage) return;
    
    switch (message.type) {
      case LlamaMessageType.init:
        bindings = LlamaBindings();
        bindings!.init();
        break;
        
      case LlamaMessageType.loadModel:
        final modelPath = message.data as String;
        try {
          context = bindings!.loadModel(modelPath, nCtx: 2048, nGpuLayers: 0);
          
          if (context == nullptr || !bindings!.isModelLoaded(context!)) {
            final error = bindings!.getError();
            mainSendPort.send(LlamaMessage(
              LlamaMessageType.loadModel,
              LoadModelResult(success: false, error: error),
            ));
          } else {
            mainSendPort.send(LlamaMessage(
              LlamaMessageType.loadModel,
              LoadModelResult(success: true),
            ));
          }
        } catch (e) {
          mainSendPort.send(LlamaMessage(
            LlamaMessageType.loadModel,
            LoadModelResult(success: false, error: e.toString()),
          ));
        }
        break;
        
      case LlamaMessageType.unloadModel:
        if (context != null && context != nullptr) {
          bindings!.unloadModel(context!);
          context = null;
        }
        break;
        
      case LlamaMessageType.generate:
        if (context == null || context == nullptr) {
          mainSendPort.send(LlamaMessage(
            LlamaMessageType.error,
            'No model loaded',
          ));
          return;
        }
        
        final params = message.data as GenerationParams;
        cancelRequested = false;
        
        // For simplicity, we'll use synchronous generation and send tokens
        // In production, you'd use proper callback mechanism
        _runGeneration(
          bindings!,
          context!,
          params,
          mainSendPort,
          () => cancelRequested,
        );
        break;
        
      case LlamaMessageType.cancel:
        cancelRequested = true;
        if (context != null && context != nullptr) {
          bindings!.cancelGenerate(context!);
        }
        break;
        
      default:
        break;
    }
  });
}

/// Run generation with token streaming
void _runGeneration(
  LlamaBindings bindings,
  Pointer<Void> context,
  GenerationParams params,
  SendPort mainSendPort,
  bool Function() isCancelled,
) {
  // Since FFI callbacks are complex with isolates, we'll use a polling approach
  // by implementing generation in chunks on the Dart side
  
  // For the actual implementation, we need to handle callbacks properly
  // This is a simplified version that demonstrates the architecture
  
  try {
    // Create the callback for token streaming
    final tokenCallback = Pointer.fromFunction<TokenCallbackNative>(
      _nativeTokenCallback,
      1, // Default return value on exception
    );
    
    // Store the send port in a global for the callback to use
    _globalSendPort = mainSendPort;
    _globalCancelCheck = isCancelled;
    
    final result = bindings.generate(
      context,
      params.prompt,
      maxTokens: params.maxTokens,
      temperature: params.temperature,
      topP: params.topP,
      callback: tokenCallback,
    );
    
    mainSendPort.send(LlamaMessage(LlamaMessageType.done, result));
  } catch (e) {
    mainSendPort.send(LlamaMessage(LlamaMessageType.error, e.toString()));
  } finally {
    _globalSendPort = null;
    _globalCancelCheck = null;
  }
}

// Global variables for callback communication (isolate-local)
SendPort? _globalSendPort;
bool Function()? _globalCancelCheck;

/// Native callback function for token streaming
int _nativeTokenCallback(Pointer<Utf8> token, Pointer<Void> userData) {
  if (_globalSendPort == null) return 1;
  
  if (_globalCancelCheck?.call() ?? false) {
    return 1; // Stop generation
  }
  
  final tokenStr = token.toDartString();
  _globalSendPort!.send(LlamaMessage(LlamaMessageType.token, tokenStr));
  
  return 0; // Continue generation
}
