@echo off
title Flutter Chat UI - Android
color 0B
echo.
echo  ==========================================
echo   FLUTTER CHAT UI - ANDROID EMULATOR
echo  ==========================================
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo  [X] Flutter is not installed!
    echo.
    echo  Please install Flutter first:
    echo  https://flutter.dev/docs/get-started/install
    echo.
    pause
    exit /b 1
)

REM Get dependencies
echo  [*] Getting dependencies...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo  [X] Failed to get dependencies!
    echo.
    pause
    exit /b 1
)

echo.
echo  [*] Launching Android emulator...
echo  (This may take 30-60 seconds...)
echo.

REM Launch emulator in background
start /min cmd /c "flutter emulators --launch Medium_Phone_API_36.1"

REM Wait for emulator to boot
echo  [*] Waiting for emulator to boot...
timeout /t 15 /nobreak >nul

REM Launch the app
echo.
echo  [*] Starting app on Android emulator...
echo.
echo  Press 'r' for hot reload, 'R' for restart, 'q' to quit
echo.
call flutter run

REM Handle exit
echo.
if %ERRORLEVEL% NEQ 0 (
    echo  [X] App exited with error
) else (
    echo  [✓] App closed
)
echo.
pause
