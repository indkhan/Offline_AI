# Offline AI
Offline AI chat app (Flutter) with local GGUF models.

## Status
MVP implemented: model download + checksum verification + chat UI + llama.cpp
integration stub.

## Quick Start
1. Ensure Flutter SDK is installed and on your PATH.
2. If platform folders are missing, run `flutter create . --platforms=android,ios`.
3. Fetch dependencies with `flutter pub get`.
4. Build and bundle llama.cpp native libraries.
   - Emulator (x86_64): place `libllama.so` under `android/app/src/main/jniLibs/x86_64/`.
   - Real device (arm64): place `libllama.so` under `android/app/src/main/jniLibs/arm64-v8a/`.
   - iOS: bundle `libllama.dylib` in the Runner target (or build as a framework).
5. Run with `flutter run`.

## Build llama.cpp for Android (Emulator)
Run:
```
scripts\\build_llama_android.bat -Abi x86_64 -Api 28
```
This clones `llama.cpp` into `third_party/llama.cpp`, builds, and copies `libllama.so`
to `android/app/src/main/jniLibs/x86_64/`.

## Models
Default model: Qwen 0.6B Q4_0.
LFM2.5 is also available for download.
