# Offline AI Android Implementation Plan

## Objective
Ship a clean, Android-first Flutter app that runs GGUF models fully on-device with ChatGPT-style UX and local-only data.

## Locked Decisions
- Platform: Android implementation now, iOS deferred.
- Inference backend: `llama_flutter_android` (llama.cpp).
- Architecture: strict clean feature layers (UI/domain/data boundaries).
- State management: Bloc/Cubit.
- Persistence: SQLite local database.
- Offline guard: adaptive generation limits on constrained devices.

## Delivery Phases

### Phase 1: Foundation (Completed)
- Flutter Android project scaffold.
- Dark theme and app bootstrap.
- Feature-first folder structure and repository interfaces.

### Phase 2: Model Manager (Completed)
- Fixed catalog for Qwen and LFM2.5 with direct download links.
- Download with progress updates and cancellation.
- Delete/replace model flow.
- Installed model registry persisted in SQLite.

### Phase 3: Inference Engine (Completed Baseline)
- Llama controller adapter for model load + chat streaming.
- Streaming tokens wired into UI.
- Stop generation action wired to llama stop API.
- Selected-model validation before generation.

### Phase 4: Chat Experience (Completed Baseline)
- Chat bubble layout with markdown rendering.
- Send, stop, regenerate, clear conversation controls.
- Assistant stream accumulation and persistence.
- Conversation reload on app startup.

### Phase 5: Reliability + Constraints (Completed Baseline)
- Adaptive max-token cap via resource monitor heuristic.
- Error feedback for missing model/selection states.
- No cloud fallback paths implemented.

### Phase 6: Validation + Delivery (Completed Baseline)
- `flutter analyze` clean.
- `flutter test` passing baseline test.
- README updated with architecture and build/run instructions.

## Next Iteration Backlog
- Add battery-level and memory-pressure telemetry hooks for stronger adaptive policy.
- Add checksum validation for model downloads.
- Add integration tests for model download + generation lifecycle.
- Add multiple conversation/thread support.
- Add export/import local conversation backups.
