# Build Checklist

Use this checklist to ensure everything is properly set up before building.

## Pre-Build Checklist

### Environment Setup
- [ ] Flutter SDK 3.9.0+ installed
  ```bash
  flutter --version
  flutter doctor
  ```

- [ ] Git installed
  ```bash
  git --version
  ```

### Android Setup (if building for Android)
- [ ] Android Studio installed
- [ ] Android SDK API 24+ installed
- [ ] NDK 26.1.10909125 installed
  - Open Android Studio → SDK Manager → SDK Tools
  - Check "NDK (Side by side)" and install version 26.1.10909125
- [ ] CMake 3.22.1+ installed
  - In SDK Manager → SDK Tools
  - Check "CMake" and install
- [ ] ANDROID_HOME environment variable set
  ```bash
  echo $ANDROID_HOME  # Should show Android SDK path
  ```

### iOS Setup (if building for iOS, macOS only)
- [ ] macOS operating system
- [ ] Xcode 14.0+ installed
  ```bash
  xcodebuild -version
  ```
- [ ] Xcode Command Line Tools installed
  ```bash
  xcode-select --install
  ```
- [ ] CocoaPods installed
  ```bash
  pod --version
  # If not installed: sudo gem install cocoapods
  ```

## Project Setup

### Step 1: Clone llama.cpp (CRITICAL)
- [ ] Navigate to native directory
  ```bash
  cd offline_llm_app/native
  ```
- [ ] Clone llama.cpp repository
  ```bash
  git clone https://github.com/ggerganov/llama.cpp.git
  ```
- [ ] Verify llama.cpp exists
  ```bash
  ls llama.cpp/  # Should show llama.cpp source files
  ```

**⚠️ CRITICAL:** The build will fail without llama.cpp!

### Step 2: Install Flutter Dependencies
- [ ] Navigate to project root
  ```bash
  cd offline_llm_app
  ```
- [ ] Install packages
  ```bash
  flutter pub get
  ```
- [ ] Verify no errors in output

### Step 3: Verify Project Structure
- [ ] Check that these files exist:
  ```bash
  ls native/llama_wrapper.h
  ls native/llama_wrapper.cpp
  ls native/CMakeLists.txt
  ls native/llama.cpp/CMakeLists.txt
  ls android/app/build.gradle.kts
  ls ios/Podfile
  ls ios/llama_wrapper.podspec
  ```

## Android Build

### Pre-Build
- [ ] Connect Android device OR start emulator
  ```bash
  flutter devices  # Should show your device
  ```
- [ ] Enable USB debugging on device (if using physical device)
- [ ] Accept USB debugging prompt on device

### Build Commands
- [ ] Clean build (optional but recommended for first build)
  ```bash
  flutter clean
  ```
- [ ] Build debug APK
  ```bash
  flutter build apk --debug
  ```
  **Expected:** 5-10 minute build time (first build compiles llama.cpp)

- [ ] OR run directly on device
  ```bash
  flutter run
  ```

### Verify Build Success
- [ ] Check for APK at: `build/app/outputs/flutter-apk/app-debug.apk`
- [ ] Check for native libraries:
  ```bash
  unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep libllama_wrapper.so
  ```
  Should show:
  - `lib/arm64-v8a/libllama_wrapper.so`
  - `lib/armeabi-v7a/libllama_wrapper.so`

### Common Android Build Issues
- [ ] **"CMake not found"** → Install CMake via SDK Manager
- [ ] **"NDK not found"** → Install NDK 26.1.10909125 via SDK Manager
- [ ] **"llama.cpp not found"** → Clone llama.cpp into native/llama.cpp/
- [ ] **"C++ compiler error"** → Update NDK to 26.1.10909125

## iOS Build

### Pre-Build
- [ ] Navigate to iOS directory
  ```bash
  cd ios
  ```
- [ ] Update CocoaPods repo (optional)
  ```bash
  pod repo update
  ```
- [ ] Install pods
  ```bash
  pod install
  ```
  **Expected:** 2-5 minute install time
- [ ] Return to project root
  ```bash
  cd ..
  ```

### Configure Signing
- [ ] Open Xcode workspace
  ```bash
  open ios/Runner.xcworkspace
  ```
- [ ] In Xcode:
  - Select "Runner" project
  - Select "Runner" target
  - Go to "Signing & Capabilities"
  - Select your development team
  - Change bundle identifier if needed

### Build Commands
- [ ] Connect iOS device OR start simulator
  ```bash
  flutter devices  # Should show your device/simulator
  ```
- [ ] Build debug
  ```bash
  flutter build ios --debug
  ```
  **Expected:** 10-15 minute build time (first build)

- [ ] OR run directly
  ```bash
  flutter run
  ```

### Verify Build Success
- [ ] App launches on device/simulator
- [ ] No crash on startup
- [ ] UI loads correctly

### Common iOS Build Issues
- [ ] **"Pod install failed"** → Run `pod repo update` then retry
- [ ] **"Module not found"** → Run `pod deintegrate`, `pod install`
- [ ] **"Signing error"** → Configure signing in Xcode
- [ ] **"llama.cpp not found"** → Clone llama.cpp into native/llama.cpp/
- [ ] **"Accelerate framework not found"** → Update Xcode

## Post-Build Testing

### App Launch Test
- [ ] App launches without crash
- [ ] Main screen shows "No model loaded"
- [ ] Can navigate to Models screen
- [ ] Can navigate to Settings screen

### Model Download Test
- [ ] Connect to WiFi
- [ ] Navigate to Models screen
- [ ] Tap "Download" on Qwen 2.5 1.5B
- [ ] Progress bar shows download progress
- [ ] Download completes successfully
- [ ] Model shows as "Downloaded"

### Model Load Test
- [ ] Tap "Load Model" on downloaded model
- [ ] Loading dialog appears
- [ ] Model loads successfully (10-30 seconds)
- [ ] Model shows "Active" badge
- [ ] Return to chat screen

### Chat Test
- [ ] Type "Hello, who are you?"
- [ ] Tap send button
- [ ] AI responds with streaming text
- [ ] Response completes
- [ ] Can send follow-up message

### Stop Generation Test
- [ ] Send a message asking for a long response
- [ ] Tap red stop button during generation
- [ ] Generation stops immediately
- [ ] Partial response is preserved

### Settings Test
- [ ] Navigate to Settings
- [ ] Adjust max tokens slider
- [ ] Adjust temperature slider
- [ ] Adjust top P slider
- [ ] Return to chat
- [ ] Settings are applied

### Offline Test
- [ ] Enable airplane mode
- [ ] Send a message
- [ ] AI responds (proves offline capability)
- [ ] Disable airplane mode

## Release Build (Optional)

### Android Release
- [ ] Generate signing key (if not exists)
  ```bash
  keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] Configure signing in `android/app/build.gradle.kts`
- [ ] Build release APK
  ```bash
  flutter build apk --release
  ```
- [ ] Test release APK on device

### iOS Release
- [ ] Configure App Store signing in Xcode
- [ ] Build release
  ```bash
  flutter build ios --release
  ```
- [ ] Archive in Xcode for distribution

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Build fails with CMake error | Install CMake via Android Studio SDK Manager |
| Build fails with NDK error | Install NDK 26.1.10909125 via SDK Manager |
| "llama.cpp not found" | Clone llama.cpp into native/llama.cpp/ |
| iOS pod install fails | Run `pod repo update` then retry |
| App crashes on launch | Check that native library was built correctly |
| Model fails to load | Ensure model downloaded completely |
| Slow inference | Normal on older devices, reduce max_tokens |
| Out of memory | Unload model, restart app |

## Success Criteria

✅ **Build Successful** if:
- App builds without errors
- App launches on device
- Can download a model
- Can load a model
- Can generate text
- Text streams in real-time
- Can stop generation
- Works offline

## Build Time Expectations

| Platform | First Build | Subsequent Builds |
|----------|-------------|-------------------|
| Android Debug | 5-10 min | 1-2 min |
| Android Release | 10-15 min | 2-3 min |
| iOS Debug | 10-15 min | 2-3 min |
| iOS Release | 15-20 min | 3-5 min |

**Note:** First build compiles llama.cpp which is time-intensive.

## Final Verification

- [ ] All tests pass
- [ ] No crashes or errors
- [ ] Performance is acceptable
- [ ] Offline mode works
- [ ] Ready for use!

---

**If all checkboxes are checked, your build is successful!** 🎉
