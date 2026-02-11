# Chatalk 💬

A real-time chat application built with Flutter and Firebase. Send messages, create group conversations, share stories, and connect with friends through an intuitive interface.

## 🚀 Features

- **User Authentication** - Secure login and registration
- **Real-time Messaging** - Individual and group chats with live updates
- **Stories** - Post and view stories with gradient rings
- **Group Chats** - Create and manage group conversations
- **Friend System** - Add friends and see online status
- **Search** - Find users and start conversations
- **Media Sharing** - Upload and share images and videos
- **Profile Management** - Customizable profiles with pictures and bios

## 🛠️ Tech Stack

**Frontend**
- Flutter/Dart - Cross-platform UI framework
- Google Fonts - Typography
- Curved Navigation Bar - Bottom navigation
- Cached Network Image - Image loading and caching

**Backend**
- Firebase Auth - User authentication
- Cloud Firestore - Real-time database
- Firebase Storage - Media file storage

## 🚀 How to Run

**Prerequisites:** Install [Flutter SDK](https://flutter.dev/docs/get-started/install) first (v3.3.0+)

Simply double-click `RUN HERE\START_APP.bat` and choose your platform (Web or Android).

> ℹ️ The script will automatically check for Flutter and guide you if it's not installed.

## 📂 Project Structure

```
chatalk/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase configuration
│   ├── screens/                     # UI screens
│   │   ├── auth/                    # Login & Registration
│   │   ├── home_screen.dart         # Main chat list
│   │   ├── chat_screen.dart         # Individual chat
│   │   ├── group_chat_screen.dart   # Group conversations
│   │   ├── profile_screen.dart      # User profile
│   │   └── settings_screen.dart     # App settings
│   ├── widgets/                     # Reusable UI components
│   ├── services/                    # Business logic
│   │   └── chat_service.dart        # Chat operations
│   ├── models/                      # Data models
│   │   ├── user_model.dart          # User entity
│   │   ├── message_model.dart       # Message entity
│   │   └── group_model.dart         # Group entity
│   ├── utils/                       # Helper functions
│   └── data/                        # Static data
├── assets/
│   ├── images/profiles/             # User profile pictures
│   ├── badge/                       # UI badges
│   └── fonts/                       # Custom fonts
├── android/                         # Android platform files
│   └── app/google-services.json     # Firebase config
├── RUN HERE/                        # Setup & launch scripts
│   └── START_APP.bat                # One-click launcher
└── pubspec.yaml                     # Dependencies
```

---
