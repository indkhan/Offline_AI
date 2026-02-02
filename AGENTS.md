# Repository Guidelines

## Project Structure & Module Organization
This repository is currently a minimal skeleton (only `README.md` and `.gitignore`). As code is added, follow standard Flutter layout and keep this section updated.
- `lib/` for Dart source (app, services, UI)
- `test/` for unit/widget tests
- `integration_test/` for end-to-end tests
- `android/`, `ios/` for platform shells
- `assets/` for bundled models, images, and other static files
- `pubspec.yaml` for dependencies and assets

## Build, Test, and Development Commands
Once `pubspec.yaml` exists:
- `flutter pub get` installs dependencies
- `flutter run` launches on a device/emulator
- `flutter test` runs unit/widget tests
- `flutter analyze` runs static analysis
- `dart format .` formats all Dart code

## Coding Style & Naming Conventions
Use Dart defaults: 2-space indentation, `lower_snake_case` for file names, `UpperCamelCase` for types, and `lowerCamelCase` for variables/functions. Format with `dart format .` before committing. Platform code should follow Kotlin/Swift conventions when added.

## Testing Guidelines
Use the Flutter `flutter_test` package for unit/widget tests and `integration_test` for end-to-end flows. Name tests `*_test.dart` and keep them close to the code they cover. There is no explicit coverage target yet; add tests for any user-visible behavior or bug fix.

## Commit & Pull Request Guidelines
Git history uses Conventional Commits (`feat:`, `fix:`, `chore:`). Keep the subject short and scoped, e.g. `feat: add offline model loader`. PRs should include a summary, test results (commands run), and screenshots or screen recordings for UI changes. Link related issues when available.

## Security & Configuration
Do not commit secrets, signing keys, or local paths. Keep `android/local.properties`, keystore files (`*.jks`), and model binaries out of Git unless explicitly intended and documented.

## Agent-Specific Instructions
If automation updates structure or commands, update this file to stay accurate.
