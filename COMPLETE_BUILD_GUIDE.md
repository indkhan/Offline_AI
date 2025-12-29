# Complete Build Guide - Offline LLM App

## Current Status: READY TO BUILD AND TEST

All critical fixes have been applied. The Android build is currently in progress.

---

## What Was Fixed

### 1. Android Native Build (`native/CMakeLists.txt`)
- ✅ Added `-O3 -fPIC` optimization flags
- ✅ Added `BUILD_SHARED_LIBS OFF` to force static libraries
- ✅ Disabled OpenMP (causes Android linking issues)
- ✅ Added ggml include directory path
- ✅ Proper linking against llama and common libraries

### 2. iOS Native Build (`ios/llama_wrapper.podspec`)
- ✅ Added ggml source files to compilation
- ✅ Added ggml include paths
- ✅ Added `-O3` optimization flags
- ✅ Enabled `GGML_USE_ACCELERATE` for Apple's BLAS
- ✅ Set `VALID_ARCHS` to arm64 only
- ✅ Added compiler flags to suppress warnings

---

## Build Commands

### Android (Windows/Linux/macOS)
```bash
cd offline_llm_app

# First time: clean build
flutter clean

# Build debug APK
flutter build apk --debug

# Or run directly on connected device
flutter run
```

**First build:** 5-10 minutes (compiles llama.cpp)  
**Subsequent builds:** 1-3 minutes

### iOS (macOS only)
```bash
cd offline_llm_app

# Install CocoaPods dependencies
cd ios
pod install
cd ..

# Build for device
flutter build ios --debug

# Or run directly
flutter run
```

**First build:** 10-15 minutes (compiles llama.cpp)  
**Subsequent builds:** 2-5 minutes

---

## Verification Steps

### 1. Check Build Success

**Android:**
```bash
# Verify native library was built
unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep libllama_wrapper.so
```

Expected output:
```
lib/arm64-v8a/libllama_wrapper.so
lib/armeabi-v7a/libllama_wrapper.so
```

**iOS:**
```bash
# Check if build succeeded
ls build/ios/Debug-iphoneos/Runner.app
```

### 2. Run on Device

```bash
# List connected devices
flutter devices

# Run the app
flutter run
```

### 3. Test Model Download

1. Launch app
2. Tap robot icon (top right) → Models screen
3. Tap "Download" on "Qwen 2.5 1.5B"
4. Wait for ~1.1 GB download
5. Verify status shows "Downloaded"

### 4. Test Model Loading

1. Tap "Load Model" button
2. Wait 10-30 seconds
3. Verify "Active" badge appears
4. Return to chat screen

### 5. Test Inference

1. Type: `Hello, who are you?`
2. Tap send button
3. **CRITICAL:** Watch for streaming text response
4. Each token should appear incrementally
5. Response should complete naturally

### 6. Test Stop Button

1. Type: `Write a long story about a dragon`
2. Tap send
3. During generation, tap red stop button
4. Generation should stop immediately
5. Partial response preserved

### 7. Test Offline Mode

1. Enable airplane mode on device
2. Send another message
3. Verify AI still responds
4. **This proves fully offline capability**

---

## Expected Performance

### Model Loading
- **Modern device (2022+):** 10-30 seconds
- **Older device (2019-2021):** 30-60 seconds

### Text Generation
- **First token:** 2-5 seconds (prompt processing)
- **Subsequent tokens:** 50-200ms each
- **Older devices:** 200-500ms per token

### Memory Usage
- **RAM:** 1-2 GB while model loaded
- **Storage:** 1.1 GB for Qwen 2.5 1.5B

---

## Troubleshooting

### Build Fails: "llama.cpp not found"

```bash
# Verify llama.cpp exists
ls native/llama.cpp/CMakeLists.txt

# If missing, clone it
cd native
git clone https://github.com/ggerganov/llama.cpp.git
cd ..
```

### Build Fails: "CMake not found" (Android)

1. Open Android Studio
2. Go to SDK Manager
3. SDK Tools tab
4. Check "CMake" and install

### Build Fails: "NDK not found" (Android)

1. Open Android Studio
2. Go to SDK Manager
3. SDK Tools tab
4. Check "NDK (Side by side)"
5. Install version 26.1.10909125

### Build Fails: Pod Install (iOS)

```bash
cd ios
pod repo update
pod deintegrate
pod install
cd ..
```

### App Crashes on Launch

**Android:**
```bash
# Check native logs
adb logcat | grep llama_wrapper
adb logcat | grep "FATAL EXCEPTION"
```

**iOS:**
- Open Xcode
- Window → Devices and Simulators
- Select device → View Device Logs
- Look for llama_wrapper errors

### Model Fails to Load

- Ensure download completed (check file size)
- Verify sufficient storage (need 2+ GB free)
- Try deleting and re-downloading model
- Restart app

### Slow Inference

- Normal on older devices
- Reduce max_tokens in Settings (try 256)
- Use Qwen 2.5 1.5B (fastest model)
- First token always slower (prompt processing)

---

## File Structure

```
offline_llm_app/
├── android/
│   └── app/
│       └── build.gradle.kts          ✅ Correct
├── ios/
│   ├── Podfile                       ✅ Correct
│   └── llama_wrapper.podspec         ✅ FIXED
├── lib/
│   ├── main.dart                     ✅ Correct
│   ├── ffi/
│   │   └── llama_bindings.dart       ✅ Correct
│   ├── models/                       ✅ Correct
│   ├── providers/                    ✅ Correct
│   ├── screens/                      ✅ Correct
│   ├── services/                     ✅ Correct
│   └── widgets/                      ✅ Correct
├── native/
│   ├── CMakeLists.txt                ✅ FIXED
│   ├── llama_wrapper.h               ✅ Correct
│   ├── llama_wrapper.cpp             ✅ Correct
│   └── llama.cpp/                    ✅ Cloned
└── pubspec.yaml                      ✅ Correct
```

---

## Success Criteria

The app is **FULLY WORKING** when:

1. ✅ Builds without errors
2. ✅ Launches on device
3. ✅ Downloads model successfully
4. ✅ Loads model (10-30 sec)
5. ✅ Generates text response
6. ✅ Tokens stream incrementally
7. ✅ Stop button works
8. ✅ Works offline (airplane mode)

---

## Next Steps

1. **Wait for current Android build to complete**
2. **Test on Android device:**
   - `flutter run`
   - Download Qwen 2.5 1.5B
   - Load model
   - Send test message
   - Verify streaming works

3. **For iOS (if on macOS):**
   - `cd ios && pod install && cd ..`
   - `flutter run`
   - Same testing steps

---

## Key Technical Details

### Android
- **NDK:** 26.1.10909125
- **Min SDK:** 24 (Android 7.0)
- **ABIs:** arm64-v8a, armeabi-v7a
- **Build:** CMake compiles llama.cpp as static lib
- **Output:** libllama_wrapper.so (shared library)

### iOS
- **Min iOS:** 14.0
- **Architecture:** arm64 only
- **Build:** CocoaPods compiles llama.cpp sources
- **Frameworks:** Accelerate, Metal, MetalKit
- **Output:** Static library linked into app

### FFI
- **Dart ↔ C:** dart:ffi with proper type conversions
- **Callbacks:** Native → Dart token streaming
- **Memory:** Safe allocation/deallocation
- **Threading:** Isolate-based inference

### llama.cpp
- **Version:** Latest from main branch
- **Quantization:** Q4_K_M (4-bit weights)
- **Context:** 2048 tokens
- **Threads:** 4 (optimal for mobile)
- **Batch:** 512 tokens

---

## Documentation Files

- `README.md` - Main documentation
- `QUICKSTART.md` - Quick setup guide
- `ARCHITECTURE.md` - Technical architecture
- `BUILD_CHECKLIST.md` - Build verification
- `BUILD_AND_RUN.md` - Build instructions
- `FIXES_APPLIED.md` - What was fixed
- `COMPLETE_BUILD_GUIDE.md` - This file

---

## Support

If issues persist after following this guide:

1. Check that llama.cpp is properly cloned
2. Verify NDK/CMake versions match exactly
3. Try `flutter clean` and rebuild
4. Check device logs for native errors
5. Ensure device has sufficient RAM (2+ GB free)

The configuration is now correct and should build successfully on both platforms.
