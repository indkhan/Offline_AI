# Implemented So Far

## Project Bootstrap
- Created Flutter Android project in-place with package name `offline_ai`.
- Added architecture-oriented folder structure under `lib/features`, `lib/core`, and `lib/app`.

## Dependency Setup
- Added and resolved:
  - `llama_flutter_android`
  - `flutter_bloc`
  - `dio`
  - `sqflite`
  - `flutter_markdown`
  - `uuid`
  - supporting packages (`path`, `path_provider`, `equatable`)

## Android Configuration
- Updated `android/app/build.gradle.kts` to `minSdk = 26` for llama backend compatibility.
- Added `INTERNET` permission in `android/app/src/main/AndroidManifest.xml` for model downloads.

## Implemented Architecture and Modules

### App Bootstrap
- `lib/main.dart`: initializes local database and repositories, injects into app.
- `lib/app/offline_ai_app.dart`: wires repositories + cubits with `MultiRepositoryProvider` and `MultiBlocProvider`.
- `lib/core/theme/app_theme.dart`: dark-first theme.

### Model Manager
- `lib/core/constants/model_catalog.dart`: fixed catalog with provided direct GGUF links.
- `lib/features/model_manager/data/model_manager_repository_impl.dart`:
  - downloads models with `dio`
  - emits progress
  - supports cancel
  - stores model files in app documents `models/`
  - persists installed path/size in DB
- `lib/features/model_manager/application/model_manager_cubit.dart` + state:
  - tracks idle/downloading/installed/failed per model
- `lib/features/model_manager/ui/model_manager_sheet.dart`:
  - download/cancel/delete/replace actions
  - select installed model

### Inference Engine
- `lib/features/inference/data/llama_inference_repository.dart`:
  - loads model with `LlamaController.loadModel`
  - streams chat tokens via `generateChat`
  - stops generation with `stop`

### Chat
- `lib/features/chat/application/chat_cubit.dart`:
  - initializes/restores conversation
  - validates selected + installed model before inference
  - appends user message
  - streams assistant output token-by-token
  - persists final assistant response
  - supports stop/regenerate/clear
- `lib/features/chat/ui/chat_screen.dart`:
  - bubble UI
  - markdown rendering
  - input composer + controls
  - model/status panel

### Storage
- `lib/features/storage/app_database.dart`:
  - SQLite schema for `conversations`, `messages`, `model_installs`, `app_settings`
  - CRUD methods used by chat/model/settings repositories

### Settings
- `lib/features/settings/data/settings_repository_impl.dart`:
  - selected model and offline guard persistence
- `lib/features/settings/application/settings_cubit.dart`:
  - loads and updates settings state

### Device Constraint Handling
- `lib/core/utils/resource_monitor.dart`:
  - adaptive max token cap heuristic for lower-resource devices
  - emits user notice used in chat state

## Validation
- `flutter analyze`: clean (no issues).
- `flutter test`: passing.

## Documentation
- Replaced `README.md` with build/run, architecture, privacy/offline behavior, and model details.
- Replaced `plan.md` with updated implementation plan and backlog.
