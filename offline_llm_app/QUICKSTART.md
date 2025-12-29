# Quick Start Guide

This guide will get you up and running with the Offline LLM Chat app in 15 minutes.

## Prerequisites Checklist

Before starting, ensure you have:

- [ ] Flutter SDK 3.9.0+ installed (`flutter --version`)
- [ ] Git installed
- [ ] **For Android:**
  - [ ] Android Studio installed
  - [ ] Android SDK API 24+ installed
  - [ ] NDK 26.1.10909125 installed (via SDK Manager)
  - [ ] CMake 3.22.1+ installed (via SDK Manager)
  - [ ] Android device or emulator
- [ ] **For iOS (macOS only):**
  - [ ] Xcode 14.0+ installed
  - [ ] CocoaPods installed (`sudo gem install cocoapods`)
  - [ ] iOS device or simulator

## Step-by-Step Setup

### 1. Clone llama.cpp (Required)

The app requires llama.cpp for inference. Clone it into the native directory:

```bash
cd offline_llm_app/native
git clone https://github.com/ggerganov/llama.cpp.git
```

**Important:** This step is mandatory. The app will not build without llama.cpp.

### 2. Install Dependencies

```bash
cd offline_llm_app
flutter pub get
```

This installs all required Flutter packages.

### 3. Build for Your Platform

#### Android

```bash
# Connect your Android device or start an emulator
flutter devices

# Build and install
flutter run
```

The first build will take 5-10 minutes as it compiles llama.cpp.

**Troubleshooting Android:**
- If CMake errors occur, install CMake via Android Studio → SDK Manager → SDK Tools
- If NDK errors occur, install NDK 26.1.10909125 via SDK Manager
- Ensure `ANDROID_HOME` environment variable is set

#### iOS (macOS only)

```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..

# Build and run
flutter run
```

The first build will take 10-15 minutes.

**Troubleshooting iOS:**
- If pod install fails, run `pod repo update` first
- Ensure Xcode Command Line Tools are installed: `xcode-select --install`
- Open `ios/Runner.xcworkspace` in Xcode to configure signing

### 4. Using the App

Once the app launches:

1. **Download a Model**
   - Tap the robot icon (top right) to open Models screen
   - Choose "Qwen 2.5 1.5B" (recommended, ~1.1 GB)
   - Tap "Download" and wait for completion
   - Ensure you have stable WiFi and sufficient storage

2. **Load the Model**
   - After download completes, tap "Load Model"
   - Wait 10-30 seconds for model to load into memory
   - You'll see "Active" badge when ready

3. **Start Chatting**
   - Return to chat screen (back button)
   - Type your message in the input box
   - Tap the send button (arrow icon)
   - Watch the AI respond in real-time!

4. **Adjust Settings** (Optional)
   - Tap settings icon (top right)
   - Adjust Max Tokens (higher = longer responses)
   - Adjust Temperature (higher = more creative)

## Performance Tips

- **First message is slow:** The first token takes longer (prompt processing)
- **Subsequent messages are faster:** Context is cached
- **Reduce max_tokens:** For faster responses, set max tokens to 256 or less
- **Use Qwen 2.5 1.5B:** It's the fastest and most efficient model

## Storage Requirements

- **Qwen 2.5 1.5B:** ~1.1 GB
- **Gemma 2B:** ~1.5 GB  
- **Function Gemma 2B:** ~1.5 GB

Ensure you have at least 2 GB free storage before downloading.

## Common Issues

### "Failed to load model"
- Ensure download completed fully (check file size)
- Restart the app
- Try deleting and re-downloading the model

### "No model loaded"
- Download a model first from the Models screen
- Tap "Load Model" after downloading

### Slow inference
- This is normal on older devices
- Try reducing max_tokens in Settings
- Use Qwen 2.5 1.5B (fastest model)

### Build errors
- Ensure llama.cpp is cloned in `native/llama.cpp/`
- Run `flutter clean` then rebuild
- Check that NDK and CMake are installed

## What's Next?

- Try different models to compare quality
- Adjust temperature and top_p for different response styles
- The app works completely offline after model download
- Clear chat history with the trash icon

## Need Help?

Check the full README.md for:
- Detailed architecture explanation
- FFI API documentation
- Advanced troubleshooting
- Project structure details

## Quick Reference

| Action | Location |
|--------|----------|
| Download models | Robot icon → Models screen |
| Adjust settings | Settings icon → Settings screen |
| Clear chat | Trash icon → Confirm |
| Stop generation | Red stop button (appears during generation) |
| Delete model | Models screen → Model card → Delete icon |

---

**Enjoy your fully offline AI assistant!** 🚀
