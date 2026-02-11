@echo off
REM Change to project root directory
cd /d "%~dp0.."

echo ========================================
echo  Flutter Chat UI - First Time Setup
echo ========================================
echo.

REM Check Flutter installation
echo [Step 1/4] Checking Flutter installation...
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [X] Flutter is NOT installed
    echo.
    echo Please install Flutter from: https://flutter.dev/docs/get-started/install
    echo After installation, restart this script.
    pause
    exit /b 1
) else (
    echo [✓] Flutter is installed
)

echo.
echo [Step 2/4] Running Flutter Doctor...
flutter doctor

echo.
echo [Step 3/4] Installing project dependencies...
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo [X] Failed to install dependencies
    pause
    exit /b 1
) else (
    echo [✓] Dependencies installed successfully
)

echo.
echo [Step 4/4] Checking available devices...
flutter devices

echo.
echo ========================================
echo  Setup Complete! 
echo ========================================
echo.
echo To run the app, you can:
echo   1. Double-click 'run.bat' in this folder
echo   2. Or open terminal and type: flutter run -d edge
echo.
echo Press any key to launch the app now...
pause >nul
echo.
echo Launching app on Microsoft Edge...
echo.
flutter run -d edge

flutter run -d edge
