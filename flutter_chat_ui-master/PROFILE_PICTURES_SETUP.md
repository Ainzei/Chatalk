# Local Profile Pictures Setup

## Overview
The app now loads profile pictures directly from local folder paths instead of storing URLs in Firebase Firestore or using external storage like Supabase.

## Folder Structure

Create a `profile_pictures` folder in your project root:
```
c:/Users/zippe/Downloads/flutter_chat_ui-master11/flutter_chat_ui-master/profile_pictures/
```

## File Naming Convention

Profile pictures should be named using one of these patterns:

### 1. By User ID (Recommended)
```
profile_pictures/{userId}.jpg
profile_pictures/{userId}.jpeg
profile_pictures/{userId}.png
```

Example:
```
profile_pictures/abc123xyz.jpg
profile_pictures/def456uvw.png
```

### 2. By Username (Fallback)
```
profile_pictures/{username}.jpg
profile_pictures/{username}.jpeg
profile_pictures/{username}.png
```

Example:
```
profile_pictures/john_smith.jpg
profile_pictures/jane_doe.png
```

## How It Works

1. **ProfilePhotoHelper** utility class handles all profile picture loading
2. Checks for local files in this order:
   - `{userId}.jpg`
   - `{userId}.jpeg`
   - `{userId}.png`
   - `{username}.jpg` (if username provided)
   - `{username}.jpeg`
   - `{username}.png`
3. Falls back to `assets/images/profile.jpg` if no file found

## Adding Profile Pictures

1. Get the user's Firebase Auth UID
2. Save their profile picture as `{uid}.jpg` in the `profile_pictures` folder
3. Hot reload the app - picture will appear automatically

## Example Setup

```powershell
# Create profile pictures folder
New-Item -ItemType Directory -Path "profile_pictures"

# Add some profile pictures
Copy-Item "C:\Photos\user1.jpg" "profile_pictures\abc123xyz.jpg"
Copy-Item "C:\Photos\user2.png" "profile_pictures\def456uvw.png"
```

## Benefits

✅ No database storage needed  
✅ No cloud storage costs  
✅ Fast local file access  
✅ Simple file management  
✅ Works offline  

## Customization

To change the profile pictures folder location, edit:
```dart
// lib/utils/profile_photo_helper.dart
static const String profilePicturesPath = 'your/custom/path';
```

## Fallback Behavior

- If no local file exists, shows default asset image
- Default: `assets/images/profile.jpg`
- Displays user's initial letter in colored circle
