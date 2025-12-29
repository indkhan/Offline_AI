#!/bin/bash
# Setup script for Offline LLM App
# This script clones llama.cpp and installs dependencies

set -e

echo "=== Offline LLM App Setup ==="
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "Project directory: $PROJECT_DIR"
echo ""

# Step 1: Clone llama.cpp
echo "Step 1: Cloning llama.cpp..."
NATIVE_DIR="$PROJECT_DIR/native"
LLAMA_DIR="$NATIVE_DIR/llama.cpp"

if [ -d "$LLAMA_DIR" ]; then
    echo "llama.cpp already exists, updating..."
    cd "$LLAMA_DIR"
    git pull
else
    echo "Cloning llama.cpp..."
    cd "$NATIVE_DIR"
    git clone https://github.com/ggerganov/llama.cpp.git
    cd "$LLAMA_DIR"
    # Checkout a stable release
    git checkout b3577 2>/dev/null || echo "Using latest version"
fi

echo "llama.cpp ready!"
echo ""

# Step 2: Install Flutter dependencies
echo "Step 2: Installing Flutter dependencies..."
cd "$PROJECT_DIR"
flutter pub get

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. For Android: flutter build apk"
echo "  2. For iOS: cd ios && pod install && cd .. && flutter build ios"
echo ""
echo "Make sure you have:"
echo "  - Android: NDK 26.1.10909125, CMake 3.22.1+"
echo "  - iOS: Xcode 14+, CocoaPods"
echo ""
