// llama_bindings.dart
// FFI bindings to the native llama_wrapper library
// Provides Dart interface to llama.cpp inference engine

import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';

// Type definitions matching the C API
typedef LlamaContext = Pointer<Void>;

// Native function signatures (C types)
typedef LlamaWrapperInitNative = Void Function();
typedef LlamaWrapperCleanupNative = Void Function();
typedef LlamaWrapperLoadModelNative = Pointer<Void> Function(
  Pointer<Utf8> modelPath,
  Int32 nCtx,
  Int32 nGpuLayers,
);
typedef LlamaWrapperUnloadModelNative = Void Function(Pointer<Void> ctx);
typedef LlamaWrapperGenerateNative = Int32 Function(
  Pointer<Void> ctx,
  Pointer<Utf8> prompt,
  Int32 maxTokens,
  Float temperature,
  Float topP,
  Pointer<NativeFunction<TokenCallbackNative>> callback,
  Pointer<Void> userData,
);
typedef LlamaWrapperCancelGenerateNative = Void Function(Pointer<Void> ctx);
typedef LlamaWrapperIsModelLoadedNative = Bool Function(Pointer<Void> ctx);
typedef LlamaWrapperGetErrorNative = Pointer<Utf8> Function();
typedef LlamaWrapperGetModelInfoNative = Pointer<Utf8> Function(Pointer<Void> ctx);

// Dart function signatures
typedef LlamaWrapperInit = void Function();
typedef LlamaWrapperCleanup = void Function();
typedef LlamaWrapperLoadModel = Pointer<Void> Function(
  Pointer<Utf8> modelPath,
  int nCtx,
  int nGpuLayers,
);
typedef LlamaWrapperUnloadModel = void Function(Pointer<Void> ctx);
typedef LlamaWrapperGenerate = int Function(
  Pointer<Void> ctx,
  Pointer<Utf8> prompt,
  int maxTokens,
  double temperature,
  double topP,
  Pointer<NativeFunction<TokenCallbackNative>> callback,
  Pointer<Void> userData,
);
typedef LlamaWrapperCancelGenerate = void Function(Pointer<Void> ctx);
typedef LlamaWrapperIsModelLoaded = bool Function(Pointer<Void> ctx);
typedef LlamaWrapperGetError = Pointer<Utf8> Function();
typedef LlamaWrapperGetModelInfo = Pointer<Utf8> Function(Pointer<Void> ctx);

// Callback type for token streaming
typedef TokenCallbackNative = Int32 Function(Pointer<Utf8> token, Pointer<Void> userData);

/// FFI bindings to the native llama_wrapper library
class LlamaBindings {
  late final DynamicLibrary _lib;
  
  // Function pointers
  late final LlamaWrapperInit _init;
  late final LlamaWrapperCleanup _cleanup;
  late final LlamaWrapperLoadModel _loadModel;
  late final LlamaWrapperUnloadModel _unloadModel;
  late final LlamaWrapperGenerate _generate;
  late final LlamaWrapperCancelGenerate _cancelGenerate;
  late final LlamaWrapperIsModelLoaded _isModelLoaded;
  late final LlamaWrapperGetError _getError;
  late final LlamaWrapperGetModelInfo _getModelInfo;

  LlamaBindings() {
    _lib = _loadLibrary();
    _bindFunctions();
  }

  /// Load the native library based on platform
  DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid) {
      return DynamicLibrary.open('libllama_wrapper.so');
    } else if (Platform.isIOS) {
      return DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libllama_wrapper.dylib');
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('llama_wrapper.dll');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libllama_wrapper.so');
    }
    throw UnsupportedError('Platform not supported');
  }

  /// Bind all native functions
  void _bindFunctions() {
    _init = _lib
        .lookup<NativeFunction<LlamaWrapperInitNative>>('llama_wrapper_init')
        .asFunction();
    
    _cleanup = _lib
        .lookup<NativeFunction<LlamaWrapperCleanupNative>>('llama_wrapper_cleanup')
        .asFunction();
    
    _loadModel = _lib
        .lookup<NativeFunction<LlamaWrapperLoadModelNative>>('llama_wrapper_load_model')
        .asFunction();
    
    _unloadModel = _lib
        .lookup<NativeFunction<LlamaWrapperUnloadModelNative>>('llama_wrapper_unload_model')
        .asFunction();
    
    _generate = _lib
        .lookup<NativeFunction<LlamaWrapperGenerateNative>>('llama_wrapper_generate')
        .asFunction();
    
    _cancelGenerate = _lib
        .lookup<NativeFunction<LlamaWrapperCancelGenerateNative>>('llama_wrapper_cancel_generate')
        .asFunction();
    
    _isModelLoaded = _lib
        .lookup<NativeFunction<LlamaWrapperIsModelLoadedNative>>('llama_wrapper_is_model_loaded')
        .asFunction();
    
    _getError = _lib
        .lookup<NativeFunction<LlamaWrapperGetErrorNative>>('llama_wrapper_get_error')
        .asFunction();
    
    _getModelInfo = _lib
        .lookup<NativeFunction<LlamaWrapperGetModelInfoNative>>('llama_wrapper_get_model_info')
        .asFunction();
  }

  /// Initialize the llama backend
  void init() => _init();

  /// Cleanup the llama backend
  void cleanup() => _cleanup();

  /// Load a model from the specified path
  LlamaContext loadModel(String modelPath, {int nCtx = 2048, int nGpuLayers = 0}) {
    final pathPtr = modelPath.toNativeUtf8();
    try {
      return _loadModel(pathPtr, nCtx, nGpuLayers);
    } finally {
      calloc.free(pathPtr);
    }
  }

  /// Unload the model and free resources
  void unloadModel(LlamaContext ctx) {
    if (ctx != nullptr) {
      _unloadModel(ctx);
    }
  }

  /// Generate text with callback for streaming
  int generate(
    LlamaContext ctx,
    String prompt, {
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    required Pointer<NativeFunction<TokenCallbackNative>> callback,
    Pointer<Void>? userData,
  }) {
    final promptPtr = prompt.toNativeUtf8();
    try {
      return _generate(
        ctx,
        promptPtr,
        maxTokens,
        temperature,
        topP,
        callback,
        userData ?? nullptr,
      );
    } finally {
      calloc.free(promptPtr);
    }
  }

  /// Cancel ongoing generation
  void cancelGenerate(LlamaContext ctx) {
    if (ctx != nullptr) {
      _cancelGenerate(ctx);
    }
  }

  /// Check if model is loaded
  bool isModelLoaded(LlamaContext ctx) {
    if (ctx == nullptr) return false;
    return _isModelLoaded(ctx);
  }

  /// Get last error message
  String getError() {
    final errorPtr = _getError();
    if (errorPtr == nullptr) return '';
    return errorPtr.toDartString();
  }

  /// Get model info as JSON string
  String getModelInfo(LlamaContext ctx) {
    if (ctx == nullptr) return '{}';
    final infoPtr = _getModelInfo(ctx);
    if (infoPtr == nullptr) return '{}';
    return infoPtr.toDartString();
  }
}

/// Global singleton instance
final llamaBindings = LlamaBindings();
