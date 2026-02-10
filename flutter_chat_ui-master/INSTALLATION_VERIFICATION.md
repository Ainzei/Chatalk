# Flutter Installation Verification Guide

This guide helps you verify that Flutter is properly installed and ready to run this chat application.

## ✅ Step 1: Check Flutter Installation

Open a terminal/command prompt and run:

```bash
flutter --version
```

**Expected Output:**
```
Flutter 3.x.x • channel stable
...
```

**If you see an error:**
- Flutter is not installed or not in your PATH
- Install Flutter from: https://flutter.dev/docs/get-started/install

## ✅ Step 2: Run Flutter Doctor

Run:
```bash
flutter doctor
```

**What to look for:**

```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, x.x.x)
[✓] Windows/macOS/Linux (depending on your OS)
[✓] Chrome/Edge - Web Browser
[!] Android toolchain (optional for web)
[!] Xcode (optional, macOS only)
```

**You MUST have:**
- ✓ Flutter installed
- ✓ A web browser (Chrome or Edge)

**Optional (not needed for web):**
- Android toolchain (only if you want to run on Android)
- Xcode (only if you want to run on iOS)

## ✅ Step 3: Check Available Devices

Run:
```bash
flutter devices
```

**Expected Output (Windows):**
```
2 connected devices:

Edge (web) • edge • web-javascript • Microsoft Edge ...
Chrome (web) • chrome • web-javascript • Google Chrome ...
```

**Expected Output (Mac/Linux):**
```
1 connected device:

Chrome (web) • chrome • web-javascript • Google Chrome ...
```

**If you don't see any web browsers:**
- Install Microsoft Edge or Google Chrome
- Restart your terminal

## ✅ Step 4: Test Flutter

Create a test project:
```bash
flutter create test_app
cd test_app
flutter run -d edge
```

If a Flutter demo app opens in your browser, you're ready!

You can delete the test_app folder after verification.

## 🔧 Common Issues

### "flutter: command not found"

**Windows:**
1. Reinstall Flutter
2. Make sure to add Flutter to PATH during installation
3. Restart your computer

**Mac/Linux:**
Add to your `~/.bashrc` or `~/.zshrc`:
```bash
export PATH="$PATH:/path/to/flutter/bin"
```
Then restart terminal.

### "No devices found"

**Solution:**
1. Install Chrome or Edge browser
2. Run `flutter config --enable-web`
3. Restart terminal
4. Run `flutter devices` again

### "Unable to locate Android SDK"

**If you only want to run on web:**
This warning is fine! You don't need Android SDK for web apps.

**If you want Android support:**
Download Android Studio and follow the setup wizard.

### "Xcode not found"

**If you're on macOS and only want web:**
This warning is fine! You don't need Xcode for web apps.

**If you want iOS support:**
Install Xcode from the Mac App Store.

## 📊 Verification Checklist

Before running this chat app, verify:

- [ ] `flutter --version` works
- [ ] `flutter doctor` shows Flutter installed
- [ ] `flutter devices` shows at least one web browser
- [ ] You can navigate to the project folder
- [ ] `flutter pub get` completes without errors

If all checks pass, you're ready to run the app!

## 🆘 Still Having Issues?

1. **Uninstall and reinstall Flutter completely**
2. **Make sure to restart your computer after installation**
3. **Try running the setup scripts:**
   - Windows: `setup.bat`
   - Mac/Linux: `./setup.sh`

## 📚 Official Resources

- Flutter Installation: https://flutter.dev/docs/get-started/install
- Flutter Web Setup: https://flutter.dev/docs/get-started/web
- Flutter Doctor: https://flutter.dev/docs/get-started/test-drive

---

**Once everything checks out, go back and run:**
- Windows: `run.bat`
- Mac/Linux: `./run.sh`
