# Plan (MVP: Download + Chat)

## Goal
Create a Flutter app that can download a GGUF model, verify checksum, load via
llama.cpp, and chat with streaming output.

## Scope
- Model download screen with progress + checksum verification
- Chat UI with bubbles, markdown rendering, streaming output
- Stop generation and clear conversation
- Local-only storage for current conversation

## Key Decisions
- Framework: Flutter
- Inference backend: llama.cpp via `llama_cpp_dart`
- Default model: Qwen 0.6B Q4_0
- Platforms: Android (API 28+) + iOS (14+)

## Dependencies
- `dio`, `crypto`, `path_provider`, `flutter_markdown`, `llama_cpp_dart`

## TODO for Full App
- Add Android/iOS platform folders if not present (`flutter create`)
- Bundle llama.cpp native libraries for Android/iOS
- Add SHA256 for LFM2.5 model
