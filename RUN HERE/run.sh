#!/bin/bash

# Change to project root directory
cd "$(dirname "$0")/.."

echo "========================================"
echo " Flutter Chat UI - Quick Launch"
echo "========================================"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null
then
    echo "[ERROR] Flutter is not installed or not in PATH"
    echo "Please install Flutter from: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "[1/3] Checking Flutter setup..."
flutter doctor --version

echo ""
echo "[2/3] Installing dependencies..."
flutter pub get

echo ""
echo "[3/3] Launching app..."
echo ""
echo "The app will launch shortly."
echo "Press 'r' for hot reload, 'R' for hot restart, 'q' to quit."
echo ""

# Try to run on Chrome (most common for Linux/Mac)
flutter run -d chrome
