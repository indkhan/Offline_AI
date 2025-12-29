# Build and Run Instructions

## Android Build Steps

### 1. Clean and Build
```bash
cd offline_llm_app
flutter clean
flutter build apk --debug
```

Build time: 5-10 minutes (first build)

### 2. Verify Native Library
```bash
unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep libllama_wrapper.so
```

Expected: arm64-v8a and armeabi-v7a libraries

### 3. Run on Device
```bash
flutter run
```

## iOS Build Steps

### 1. Install Pods
```bash
cd ios
pod install
cd ..
```

### 2. Configure Signing in Xcode
```bash
open ios/Runner.xcworkspace
```

### 3. Build and Run
```bash
flutter run
```

Build time: 10-15 minutes (first build)

## Verification

1. App launches without crash
2. Navigate to Models screen
3. Download Qwen 2.5 1.5B model
4. Load model (10-30 seconds)
5. Send message: "Hello"
6. AI responds with streaming text
7. Test offline mode

## Troubleshooting

### Android
- CMake not found: Install via SDK Manager
- NDK not found: Install 26.1.10909125
- llama.cpp missing: Clone into native/llama.cpp

### iOS
- Pod install fails: Run pod repo update
- Build errors: Clean and rebuild
- Signing errors: Configure in Xcode
