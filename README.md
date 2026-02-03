# Offline AI
Offline AI chat app (Flutter) with local GGUF models.

## Status
MVP implemented: model download + checksum verification + chat UI + llama.cpp
integration stub.

## Quick Start
1. Ensure Flutter SDK is installed and on your PATH.
2. If platform folders are missing, run `flutter create . --platforms=android,ios`.
3. Fetch dependencies with `flutter pub get`.
4. Build and bundle llama.cpp native libraries. Android: place `libllama.so` under `android/app/src/main/jniLibs/arm64-v8a/`. iOS: bundle `libllama.dylib` in the Runner target (or build as a framework).
5. Run with `flutter run`.

## Models
Default model: Qwen 0.6B Q4_0.
LFM2.5 is listed but its SHA256 must be added before download is enabled.
