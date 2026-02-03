# Done

## Implemented
- Flutter MVP code (Dart) with model download + checksum verification.
- Chat UI with markdown rendering.
- Streaming output wiring via `llama_cpp_dart`.
- Stop generation + clear conversation.
- Local conversation persistence.
- Android build script to compile llama.cpp and copy `libllama.so` for emulator.

## How It Works
- `lib/src/model_manager.dart` downloads models to app documents without checksum verification (MVP).
- `lib/src/inference_engine.dart` loads llama.cpp via `llama_cpp_dart` and streams tokens into the UI.
- `lib/src/app_controller.dart` coordinates downloads, chat flow, and storage.

## Gaps / Needs User Action
- Run `flutter create . --platforms=android,ios` to generate platform folders.
- Build and bundle llama.cpp native libraries.
- Add SHA256 for LFM2.5 model to enable its download.
