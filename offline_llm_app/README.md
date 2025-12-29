# Offline LLM Chat

A Flutter application that runs small open-source LLMs fully offline on-device using llama.cpp.

## Features

- **Fully Offline**: Download models once, then use without internet
- **Multiple Models**: Support for Qwen 2.5, Gemma 2B, and Function Gemma
- **ChatGPT-style UI**: Clean, modern chat interface with streaming responses
- **Cross-platform**: Single codebase for Android and iOS
- **Native Performance**: Uses llama.cpp via FFI for fast inference

## Supported Models

| Model | Size | Description |
|-------|------|-------------|
| Qwen 2.5 1.5B | ~1.1 GB | Recommended default, great for general chat |
| Gemma 2B | ~1.5 GB | Google's lightweight open model |
| Function Gemma 2B | ~1.5 GB | Fine-tuned for structured outputs |

All models use Q4_K_M quantization for optimal mobile performance.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter UI Layer                        │
│  (ChatScreen, ModelSelectionScreen, SettingsScreen)         │
├─────────────────────────────────────────────────────────────┤
│                    Service Layer (Dart)                      │
│  (LlamaService, ModelManager, ChatProvider)                 │
├─────────────────────────────────────────────────────────────┤
│                    FFI Bindings (Dart)                       │
│  (llama_bindings.dart - dart:ffi)                           │
├─────────────────────────────────────────────────────────────┤
│                 Native C/C++ Layer                           │
│  (llama_wrapper.cpp → llama.cpp)                            │
├─────────────────────────────────────────────────────────────┤
│     Android (NDK/CMake)    │      iOS (Xcode/CocoaPods)     │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Flutter SDK 3.9.0 or later
- For Android:
  - Android Studio with NDK 26.1.10909125
  - CMake 3.22.1+
  - Android SDK with API level 24+
- For iOS:
  - Xcode 14.0+
  - CocoaPods
  - macOS for building

## Setup Instructions

### 1. Clone llama.cpp

First, clone llama.cpp into the native directory:

```bash
cd offline_llm_app/native
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
git checkout b3577  # Use a stable release tag
```

### 2. Install Flutter Dependencies

```bash
cd offline_llm_app
flutter pub get
```

### 3. Build for Android

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# Install on device
flutter install
```

**Android Build Notes:**
- The native library is built automatically via CMake
- Supports arm64-v8a and armeabi-v7a architectures
- Minimum SDK: 24 (Android 7.0)

### 4. Build for iOS

```bash
cd ios
pod install
cd ..

# Debug build
flutter build ios --debug

# Release build (requires signing)
flutter build ios --release
```

**iOS Build Notes:**
- Requires Xcode and a valid development certificate
- Uses Accelerate framework for optimized BLAS operations
- Metal support can be enabled for GPU acceleration
- Minimum iOS: 14.0

## Project Structure

```
offline_llm_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── ffi/
│   │   └── llama_bindings.dart   # FFI bindings to native code
│   ├── models/
│   │   ├── chat_message.dart     # Chat message data model
│   │   └── model_info.dart       # LLM model information
│   ├── providers/
│   │   └── chat_provider.dart    # Chat state management
│   ├── screens/
│   │   ├── chat_screen.dart      # Main chat UI
│   │   ├── model_selection_screen.dart
│   │   └── settings_screen.dart
│   ├── services/
│   │   ├── llama_service.dart    # Inference service
│   │   └── model_manager.dart    # Model download/storage
│   └── widgets/
│       ├── chat_bubble.dart      # Message bubble widget
│       └── chat_input.dart       # Text input widget
├── native/
│   ├── CMakeLists.txt            # Android native build
│   ├── llama_wrapper.h           # C API header
│   ├── llama_wrapper.cpp         # C++ implementation
│   └── llama.cpp/                # llama.cpp source (clone this)
├── android/
│   └── app/build.gradle.kts      # Android config with CMake
└── ios/
    ├── Podfile                   # iOS dependencies
    └── llama_wrapper.podspec     # Native library spec
```

## FFI API

The native library exposes these functions:

```c
// Initialize/cleanup
void llama_wrapper_init(void);
void llama_wrapper_cleanup(void);

// Model management
LlamaContext llama_wrapper_load_model(const char* path, int n_ctx, int n_gpu_layers);
void llama_wrapper_unload_model(LlamaContext ctx);

// Inference
int llama_wrapper_generate(
    LlamaContext ctx,
    const char* prompt,
    int max_tokens,
    float temperature,
    float top_p,
    TokenCallback callback,
    void* user_data
);

// Control
void llama_wrapper_cancel_generate(LlamaContext ctx);
bool llama_wrapper_is_model_loaded(LlamaContext ctx);
const char* llama_wrapper_get_error(void);
```

## Configuration

### Generation Settings

Adjustable in the Settings screen:
- **Max Tokens**: 64-2048 (default: 512)
- **Temperature**: 0.0-2.0 (default: 0.7)
- **Top P**: 0.0-1.0 (default: 0.9)

### Model Storage

Models are stored in the app's documents directory:
- Android: `/data/data/com.example.offline_llm_app/app_flutter/models/`
- iOS: `Documents/models/`

## Troubleshooting

### Build Errors

**"CMake not found"**
```bash
# Install CMake via Android Studio SDK Manager
# Or: sudo apt install cmake (Linux)
```

**"NDK not found"**
```bash
# Install NDK 26.1.10909125 via Android Studio SDK Manager
```

**iOS "Module not found"**
```bash
cd ios
pod deintegrate
pod install
```

### Runtime Issues

**"Failed to load model"**
- Ensure model file is fully downloaded
- Check available storage (models are 1-2 GB)
- Verify the model is a valid GGUF file

**Slow inference**
- Q4_K_M quantization is optimized for mobile
- First token may take longer (prompt processing)
- Reduce max_tokens for faster responses

## Model URLs

These URLs are hardcoded in the app. Update in `lib/models/model_info.dart` if needed:

```
Qwen 2.5 1.5B:
https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf

Gemma 2B:
https://huggingface.co/google/gemma-2b-it-GGUF/resolve/main/gemma-2b-it-q4_k_m.gguf

Function Gemma 2B:
https://huggingface.co/NousResearch/Function-Gemma-2B-GGUF/resolve/main/function-gemma-2b-q4_k_m.gguf
```

## License

This project is for personal use. llama.cpp is MIT licensed.

## Acknowledgments

- [llama.cpp](https://github.com/ggerganov/llama.cpp) - Inference engine
- [Qwen](https://huggingface.co/Qwen) - Qwen 2.5 model
- [Google](https://huggingface.co/google) - Gemma model
- [NousResearch](https://huggingface.co/NousResearch) - Function Gemma
