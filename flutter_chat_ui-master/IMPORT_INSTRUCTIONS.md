# Facebook Data Import Instructions

Your Facebook data is on your PC but the app runs on your phone, so we need to import the data from your PC directly to Firebase.

## Steps:

### 1. Get Firebase Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ (Settings) → Project settings
4. Go to "Service accounts" tab
5. Click "Generate new private key"
6. Save the JSON file as `serviceAccountKey.json` in this folder

### 2. Install Python Requirements

Open PowerShell in this folder and run:
```powershell
pip install firebase-admin beautifulsoup4 html5lib
```

### 3. Run the Import Script

```powershell
python import_facebook_data.py
```

The script will:
- ✅ Read all Facebook conversations from the inbox folder
- ⏭️ Skip any conversations with "Althea Maon"
- 📥 Create a user profile for each contact
- 💬 Create a chat document for each conversation
- 👥 Add each contact as your friend

### 4. Restart Your App

After the import completes, restart your Flutter app on your phone. The imported chats should now appear in your recent chats list!

## What Gets Created

For each Facebook contact:
- **User Document**: `users/{contactname_fb_import}`
  - Name: Contact's name from folder
  - Email: contactname@imported.com (placeholder)
  - Friends: Includes you
  
- **Chat Document**: `chats/{your_id}_{contact_id}`
  - Participants: [you, contact]
  - Last message: "Imported from Facebook"
  - Timestamp: Now

- **Your Friends List**: Updated to include the contact

## Troubleshooting

**"Module not found"**: Run `pip install firebase-admin beautifulsoup4 html5lib`

**"Path not found"**: The script is already configured with your path:
```
c:\Users\zippe\Downloads\flutter_chat_ui-master11\flutter_chat_ui-master\facebook-AceSandoval3206-2026-02-03-alN4NiXy\your_facebook_activity\messages\inbox
```

**"Permission denied"**: Make sure you downloaded the service account key JSON file

**Chats don't appear**: Make sure you're logged in as `sandovalchristianace3206@gmail.com` in the app
