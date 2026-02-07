# Offline AI (Android)

Fully offline-first AI chat app built with Flutter for Android.

## Features
- ChatGPT-style chat UI with message bubbles.
- Streaming token output from local GGUF models.
- Markdown and code block rendering in assistant responses.
- Model manager with download progress, cancel, delete, replace.
- Generation controls: stop, regenerate, clear conversation.
- Local-only storage for conversation history and settings.
- No analytics, telemetry, login, or cloud fallback.

## Models
Direct download URLs used by the app:
- Qwen: `https://huggingface.co/ggml-org/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q4_0.gguf`
- LFM2.5: `https://huggingface.co/LiquidAI/LFM2.5-1.2B-Thinking-GGUF/resolve/main/LFM2.5-1.2B-Thinking-Q4_0.gguf`

Inference backend:
- `llama_flutter_android` (`llama.cpp` on-device).

## Architecture
Feature-first clean layers:
- `lib/features/chat`: UI, state, chat domain/data.
- `lib/features/model_manager`: catalog, download/install state, management UI.
- `lib/features/inference`: local model loading and streaming generation adapter.
- `lib/features/settings`: selected model + privacy guard settings.
- `lib/features/storage`: SQLite schema + persistence API.
- `lib/core`: theme, model catalog, resource policy.

## Storage
SQLite tables:
- `conversations`
- `messages`
- `model_installs`
- `app_settings`

Model files are stored under app documents directory in `models/`.

## Build and Run (Android)
Prerequisites:
- Flutter SDK (stable)
- Android SDK / emulator or device

Commands:
```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Privacy + Offline Behavior
- Network is used only for explicit model download actions.
- Inference uses only local model files.
- Conversation and settings remain on device.

## Current Limitations
- Release scope is Android only.
- Resource adaptation currently uses a conservative CPU-based heuristic for generation length.


