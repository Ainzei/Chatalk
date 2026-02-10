#!/bin/bash

echo "========================================"
echo " Flutter Chat UI - First Time Setup"
echo "========================================"
echo ""

# Check Flutter installation
echo "[Step 1/4] Checking Flutter installation..."
if ! command -v flutter &> /dev/null
then
    echo "[X] Flutter is NOT installed"
    echo ""
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    echo "After installation, restart this script."
    exit 1
else
    echo "[✓] Flutter is installed"
fi

echo ""
echo "[Step 2/4] Running Flutter Doctor..."
flutter doctor

echo ""
echo "[Step 3/4] Installing project dependencies..."
if flutter pub get; then
    echo "[✓] Dependencies installed successfully"
else
    echo "[X] Failed to install dependencies"
    exit 1
fi

echo ""
echo "[Step 4/4] Checking available devices..."
flutter devices

echo ""
echo "========================================"
echo " Setup Complete!"
echo "========================================"
echo ""
echo "To run the app, you can:"
echo "  1. Run: ./run.sh"
echo "  2. Or type: flutter run -d chrome"
echo ""
echo "Press Enter to launch the app now..."
read

flutter run -d chrome
