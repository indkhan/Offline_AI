# Architecture Documentation

## Overview

This document explains the technical architecture of the Offline LLM Chat application, including how all components work together to enable on-device AI inference.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ ChatScreen   │  │ ModelScreen  │  │ SettingsScreen│          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      State Management                            │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ ChatProvider (ChangeNotifier)                        │       │
│  │ - Message history                                    │       │
│  │ - Generation state                                   │       │
│  │ - Settings (temperature, max_tokens, top_p)         │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Service Layer                               │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │ LlamaService     │              │ ModelManager     │         │
│  │ - Load model     │              │ - Download models│         │
│  │ - Generate text  │              │ - Manage storage │         │
│  │ - Stream tokens  │              │ - Track progress │         │
│  │ - Cancel gen     │              │ - Delete models  │         │
│  └──────────────────┘              └──────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      FFI Bindings (Dart)                         │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ llama_bindings.dart                                  │       │
│  │ - DynamicLibrary loading                             │       │
│  │ - Function pointer binding                           │       │
│  │ - Type conversions (Dart ↔ C)                       │       │
│  │ - Callback handling                                  │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Native C/C++ Layer                            │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ llama_wrapper.cpp/h                                  │       │
│  │ - Clean C API wrapper                                │       │
│  │ - Thread-safe operations                             │       │
│  │ - Token streaming callbacks                          │       │
│  │ - Error handling                                     │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      llama.cpp Engine                            │
│  ┌──────────────────────────────────────────────────────┐       │
│  │ - GGUF model loading                                 │       │
│  │ - Tokenization                                       │       │
│  │ - Inference engine                                   │       │
│  │ - Sampling (temperature, top_p)                      │       │
│  │ - KV cache management                                │       │
│  └──────────────────────────────────────────────────────┘       │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Platform Native                               │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │ Android (NDK)    │              │ iOS (Accelerate) │         │
│  │ - arm64-v8a      │              │ - Metal (opt)    │         │
│  │ - armeabi-v7a    │              │ - NEON SIMD      │         │
│  │ - NEON SIMD      │              │ - vDSP           │         │
│  └──────────────────┘              └──────────────────┘         │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. UI Layer (Flutter Widgets)

**ChatScreen** (`lib/screens/chat_screen.dart`)
- Main chat interface with message list
- Auto-scrolling during generation
- Input field with send/stop button
- Error banner display
- Navigation to other screens

**ModelSelectionScreen** (`lib/screens/model_selection_screen.dart`)
- Lists available models
- Download progress tracking
- Model loading/unloading
- Storage management
- Model deletion

**SettingsScreen** (`lib/screens/settings_screen.dart`)
- Generation parameter controls
- Max tokens slider (64-2048)
- Temperature slider (0.0-2.0)
- Top P slider (0.0-1.0)

**Widgets**
- `ChatBubble`: Message display with user/assistant styling
- `ChatInput`: Multi-line text input with keyboard handling

### 2. State Management

**ChatProvider** (`lib/providers/chat_provider.dart`)
- Extends `ChangeNotifier` for reactive UI updates
- Manages conversation history
- Handles message sending and streaming
- Controls generation lifecycle
- Stores generation settings
- Integrates with LlamaService and ModelManager

**Key Methods:**
```dart
Future<bool> loadModel(String modelId)
Future<void> sendMessage(String content)
void stopGeneration()
void updateSettings({int? maxTokens, double? temperature, double? topP})
```

### 3. Service Layer

**LlamaService** (`lib/services/llama_service.dart`)
- Singleton service for inference operations
- Runs inference in separate isolate (prevents UI blocking)
- Manages model loading/unloading
- Streams tokens via callback mechanism
- Thread-safe cancellation support

**Isolate Communication:**
```
Main Isolate                    Inference Isolate
     │                                 │
     ├─── SendPort ──────────────────→│
     │    (commands)                   │
     │                                 │
     │←─── ReceivePort ────────────────┤
          (tokens, status)             │
```

**ModelManager** (`lib/services/model_manager.dart`)
- Singleton for model lifecycle management
- HTTP streaming download with progress
- Local storage in app documents directory
- Model metadata tracking
- Storage usage calculation

### 4. FFI Layer

**LlamaBindings** (`lib/ffi/llama_bindings.dart`)
- Loads native library based on platform
- Binds C functions to Dart function pointers
- Handles type conversions:
  - `String` ↔ `Pointer<Utf8>`
  - `int` ↔ `Int32`
  - `double` ↔ `Float`
  - `bool` ↔ `Bool`
  - `void*` ↔ `Pointer<Void>`

**Platform Library Loading:**
- Android: `libllama_wrapper.so`
- iOS: `DynamicLibrary.process()` (static linking)
- Windows: `llama_wrapper.dll`
- Linux: `libllama_wrapper.so`
- macOS: `libllama_wrapper.dylib`

### 5. Native Layer

**llama_wrapper.cpp/h** (`native/`)
- Clean C API for FFI consumption
- Thread-safe with mutex protection
- Token streaming via callbacks
- Error message storage
- Context management

**Key Functions:**
```c
void llama_wrapper_init(void);
LlamaContext llama_wrapper_load_model(const char* path, int n_ctx, int n_gpu_layers);
int llama_wrapper_generate(LlamaContext ctx, const char* prompt, ...);
void llama_wrapper_cancel_generate(LlamaContext ctx);
void llama_wrapper_unload_model(LlamaContext ctx);
```

**Internal Structure:**
```cpp
struct LlamaContextInternal {
    llama_model* model;
    llama_context* ctx;
    llama_sampler* sampler;
    std::atomic<bool> cancel_requested;
    std::mutex generate_mutex;
    std::string model_path;
    int n_ctx;
};
```

### 6. Build System

**Android (CMake)**
- `android/app/build.gradle.kts`: Configures NDK and CMake
- `native/CMakeLists.txt`: Builds llama.cpp and wrapper
- Outputs: `libllama_wrapper.so` for arm64-v8a and armeabi-v7a
- Linked with: `liblog.so`, `libandroid.so`, C++ STL

**iOS (CocoaPods)**
- `ios/Podfile`: Configures pod dependencies
- `ios/llama_wrapper.podspec`: Defines native library
- Uses Accelerate framework for BLAS operations
- Optional Metal support for GPU acceleration
- Outputs: Static library linked into app binary

## Data Flow

### Model Download Flow
```
User taps "Download"
    ↓
ModelManager.downloadModel(modelId)
    ↓
HTTP streaming download with progress
    ↓
Save to: Documents/models/{filename}.gguf
    ↓
Update download status
    ↓
UI updates via ChangeNotifier
```

### Model Loading Flow
```
User taps "Load Model"
    ↓
ChatProvider.loadModel(modelId)
    ↓
LlamaService.loadModel(modelPath)
    ↓
Isolate: llamaBindings.loadModel(path)
    ↓
Native: llama_wrapper_load_model()
    ↓
llama.cpp: Load GGUF, create context
    ↓
Return context pointer
    ↓
Update UI state
```

### Text Generation Flow
```
User sends message
    ↓
ChatProvider.sendMessage(content)
    ↓
Build prompt with chat template
    ↓
LlamaService.generate(params)
    ↓
Isolate: llamaBindings.generate()
    ↓
Native: llama_wrapper_generate()
    ↓
llama.cpp: Tokenize, decode, sample
    ↓
For each token:
    ↓
    Callback to Dart
    ↓
    Stream to UI
    ↓
    ChatProvider updates message
    ↓
    UI rebuilds with new token
```

## Threading Model

**Main Thread (UI)**
- Flutter UI rendering
- User input handling
- State management updates

**Inference Isolate**
- Model loading
- Text generation
- Token streaming
- Isolated from main thread (no blocking)

**Native Threads**
- llama.cpp internal threading (4 threads default)
- Batch processing
- Token sampling

## Memory Management

**Model Storage**
- Models: 1-2 GB each on disk
- Only one model in RAM at a time
- KV cache: ~100-200 MB during inference
- Context size: 2048 tokens default

**Lifecycle**
- Models persist on disk until deleted
- Context loaded on-demand
- Context unloaded when switching models
- Automatic cleanup on app termination

## Security Considerations

- No network requests after model download
- All data stored locally
- No telemetry or analytics
- Models from trusted sources (Hugging Face)
- No code execution from models (GGUF is data-only)

## Performance Optimizations

**Mobile-Specific**
- Q4_K_M quantization (4-bit weights)
- NEON SIMD instructions (ARM)
- Accelerate framework (iOS)
- Batch size: 512 tokens
- Thread count: 4 (balanced for mobile)

**Memory**
- Single model in memory
- Streaming token generation
- Efficient KV cache management
- No unnecessary copies

**UI**
- Isolate-based inference (non-blocking)
- Incremental UI updates
- Efficient list rendering
- Minimal rebuilds

## Error Handling

**Levels**
1. **UI Level**: User-friendly error messages
2. **Service Level**: Try-catch with error propagation
3. **FFI Level**: Null checks and error strings
4. **Native Level**: Error message storage, safe defaults

**Recovery**
- Model load failures: Show error, allow retry
- Generation errors: Stop gracefully, preserve chat
- Download failures: Cleanup temp files, allow retry
- OOM: Unload model, show error

## Testing Strategy

**Unit Tests**
- Model info calculations
- Chat message models
- Download progress tracking

**Integration Tests**
- Model download flow
- FFI bindings (with mock)
- State management

**Manual Tests**
- Full generation flow
- Multi-turn conversations
- Model switching
- Cancellation
- Error scenarios

## Future Enhancements

Potential improvements (not implemented):
- Multiple conversation threads
- Model quantization options
- GPU acceleration toggle
- Conversation export/import
- Custom model URLs
- Voice input/output
- Multi-modal models (vision)

---

This architecture provides a solid foundation for on-device AI inference while maintaining clean separation of concerns and platform independence.
