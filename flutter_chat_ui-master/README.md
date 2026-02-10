# Flutter Chat UI

A modern, feature-rich Flutter chat application with stories, groups, and real-time messaging powered by Firebase.

## ✨ Features

- 📱 **Real-time Messaging** - Individual and group chats with live updates
- 🎭 **Stories** - Add and view stories with beautiful gradient rings
- 👥 **Groups** - Create and manage group conversations
- 🔍 **Search** - Find users and start conversations
- 📷 **Profile Pictures** - Custom profile photo support
- 🌐 **Cross-platform** - Runs on web, mobile, and desktop

## 🚀 Quick Start

> **⚡ Super Quick Start:**
> - **Windows**: Double-click `setup.bat` (first time) or `run.bat` (after setup)
> - **macOS/Linux**: Run `./setup.sh` (first time) or `./run.sh` (after setup)
> - See `START_HERE.txt` or `QUICKSTART.md` for step-by-step guide

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (v3.3.0 or higher)
- [Dart](https://dart.dev/get-dart) (included with Flutter)
- [Git](https://git-scm.com/downloads)
- A code editor ([VS Code](https://code.visualstudio.com/) recommended)
- Microsoft Edge browser (for web development)

### Installation

1. **Clone or download this repository**
   ```bash
   cd flutter_chat_ui-master
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter installation**
   ```bash
   flutter doctor
   ```
   Make sure all required components are installed.

### Running the App

#### Easiest Way (Using Scripts)
- **Windows**: Double-click `run.bat`
- **macOS/Linux**: Run `./run.sh` (see `UNIX_SETUP.md` for first-time setup)

#### On Web (Microsoft Edge) - Recommended
```bash
flutter run -d edge
```
The app will automatically open in Microsoft Edge browser.

#### On Other Platforms
- **Chrome**: `flutter run -d chrome`
- **Windows**: `flutter run -d windows`
- **Android Emulator**: `flutter run` (with emulator running)
- **iOS Simulator**: `flutter run` (macOS only, with simulator running)

### First Time Setup

When you first run the app, it will:
1. Initialize Firebase connection
2. Set up chat repair for existing conversations
3. Load profile pictures from the `ProfilePictures/` folder
4. Display the main chat interface

## 📂 Project Structure

```
flutter_chat_ui-master/
├── lib/
│   ├── main.dart              # App entry point
│   ├── screens/               # UI screens (home, chat, profile, etc.)
│   ├── widgets/               # Reusable UI components
│   ├── services/              # Firebase & business logic
│   ├── models/                # Data models
│   └── utils/                 # Helper functions
├── assets/                    # Images, fonts, badges
├── ProfilePictures/           # User profile photos
└── pubspec.yaml              # Project dependencies
```

## 🎯 Navigation

The app has 5 main tabs:
- **Messages** - View recent conversations
- **Online** - See who's currently active
- **Groups** - Manage group chats
- **Friends** - Browse your friends list
- **History** - View chat history

## 🛠️ Development

### Hot Reload
While the app is running, press `r` in the terminal to hot reload changes instantly.

### Hot Restart
Press `R` (capital) to perform a full restart with state reset.

### Clear Build Cache
If you encounter issues:
```bash
flutter clean
flutter pub get
flutter run -d edge
```

## 📝 Common Commands

| Command | Description |
|---------|-------------|
| `flutter pub get` | Install/update dependencies |
| `flutter run -d edge` | Run on Edge browser |
| `flutter clean` | Clear build cache |
| `flutter doctor` | Check Flutter installation |
| `r` | Hot reload (while app is running) |
| `R` | Hot restart (while app is running) |
| `q` | Quit the app |

## 🔧 Troubleshooting

### "No device found"
- Make sure Microsoft Edge is installed
- Try: `flutter devices` to see available devices

### "Failed to compile"
- Run `flutter clean` then `flutter pub get`
- Check for syntax errors in recent changes

### Profile pictures not showing
- Profile pictures should be placed in `ProfilePictures/` folder
- Named format: `FirstnameLastname.jpg` (e.g., `EnricoReprima.jpg`)

### Firebase connection issues
- Check internet connection
- Verify `google-services.json` is present in `android/app/`
- Ensure `firebase_options.dart` exists in `lib/`

## 📱 Features Overview

### Stories
- Long-press on any chat to add/remove from stories
- Stories appear with gradient rings (purple, orange, pink)
- "Your Story" shows first with blue add button

### Chat Management
- Tap to open conversation
- Long-press for chat actions
- Swipe to see timestamps and badges

### Groups
- Create groups with multiple members
- Group indicator badge on avatars
- Member count displayed

## 🎨 Customization

### Profile Pictures
Add your profile pictures to `ProfilePictures/` folder:
```
ProfilePictures/
├── JohnDoe.jpg
├── JaneSmith.jpg
└── ...
```

### Colors & Theme
Main colors can be modified in respective widget files:
- Orange accent: `Colors.orange`
- Story gradient: Purple → Orange → Pink

## 📄 License

See the original tutorial: [Flutter Chat UI Tutorial](https://youtu.be/h-igXZCCrrc)

## 🆘 Need Help?

1. Check troubleshooting section above
2. Run `flutter doctor` to verify your setup
3. Ensure all dependencies are installed with `flutter pub get`
4. Try `flutter clean` if you encounter build issues

---

**Happy Chatting! 💬**