@echo off
REM Change to project root directory
cd /d "%~dp0.."

title Flutter Chat UI
color 0A
echo.
echo  ========================================
echo   FLUTTER CHAT UI - ONE-CLICK LAUNCHER
echo  ========================================
echo.
echo  [1] Microsoft Edge (web)
echo  [2] Android Emulator
echo.
set /p choice="Choose platform (1 or 2): "
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

REM Handle platform choice
if "%choice%"=="2" goto android
if "%choice%"=="1" goto edge

REM Default to Edge if invalid choice
:edge
echo.
echo  [*] Launching app in Microsoft Edge...
echo.
echo  Press 'r' for hot reload, 'R' for restart, 'q' to quit
echo.
call flutter run -d edge
goto end

:android
echo.
echo  [*] Launching Android emulator...
echo  (This may take 30-60 seconds...)
echo.
start /min cmd /c "flutter emulators --launch Medium_Phone_API_36.1"
echo  [*] Waiting for emulator to boot...
timeout /t 15 /nobreak >nul
echo.
echo  [*] Starting app on Android emulator...
echo.
echo  Press 'r' for hot reload, 'R' for restart, 'q' to quit
echo.
call flutter run
goto end

:end
REM Handle exit
echo.
if %ERRORLEVEL% NEQ 0 (
    echo  [X] App exited with error
) else (
    echo  [✓] App closed
)
echo.
pause
