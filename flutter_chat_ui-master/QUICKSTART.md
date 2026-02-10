# 🚀 QUICK START GUIDE

## First Time Users

### Step 1: Install Flutter (if not already installed)
1. Go to: https://flutter.dev/docs/get-started/install
2. Download Flutter for Windows
3. Follow the installation instructions
4. Restart your computer after installation

### Step 2: Run Setup
Double-click the **`setup.bat`** file in this folder.

This will:
- Check your Flutter installation
- Install all required dependencies
- Launch the app automatically

### Step 3: Start Chatting!
The app will open in Microsoft Edge browser.

---

## Already Set Up?

Just double-click **`run.bat`** to launch the app!

---

## Manual Installation (Alternative)

If the batch files don't work, open PowerShell or Command Prompt in this folder and run:

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run -d edge
```

---

## Troubleshooting

### "Flutter is not recognized"
- Make sure Flutter is installed
- Restart your computer after installing Flutter
- Check that Flutter is added to your system PATH

### "No devices found"
- Make sure Microsoft Edge browser is installed
- Try: `flutter devices` to see available options

### Build errors
Run these commands in order:
```bash
flutter clean
flutter pub get
flutter run -d edge
```

---

## Hot Reload While Running

When the app is running, you can use these keyboard shortcuts in the terminal:

- Press **`r`** - Hot reload (apply changes instantly)
- Press **`R`** - Hot restart (full restart)
- Press **`q`** - Quit the app

---

## Need More Help?

See the full **README.md** file for detailed documentation.
