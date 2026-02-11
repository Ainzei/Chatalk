@echo off
REM Change to project root directory
cd /d "%~dp0.."

echo ========================================
echo  Flutter Chat UI - Quick Launch
echo ========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter is not installed or not in PATH
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo [1/3] Checking Flutter setup...
flutter doctor --version

echo.
echo [2/3] Installing dependencies...
flutter pub get

echo.
echo [3/3] Launching app on Microsoft Edge...
echo.
echo The app will open in your browser shortly.
echo Press 'r' for hot reload, 'R' for hot restart, 'q' to quit.
echo.
flutter run -d edge

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Failed to launch app
    echo.
    pause
)
