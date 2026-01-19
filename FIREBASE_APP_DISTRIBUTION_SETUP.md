# Firebase App Distribution Setup Guide

## ✅ What's Already Set Up

- ✅ Firebase project: `knot-29668`
- ✅ Android app configured: `com.emanneul.knot`
- ✅ `google-services.json` file in place

## Step 1: Enable App Distribution in Firebase Console

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Select your project**: `knot-29668`
3. **Navigate to App Distribution:**
   - Click on "Build" in the left sidebar
   - Click on "App Distribution"
   - Click "Get started" if you haven't enabled it yet

## Step 2: Install Firebase CLI (Required)

You need Firebase CLI to upload builds. Choose one method:

### Option A: Using npm (Recommended)

**First, install Node.js if you don't have it:**
1. Download from: https://nodejs.org/
2. Install it (includes npm)

**Then install Firebase CLI:**
```bash
npm install -g firebase-tools
```

### Option B: Using Standalone Binary (Windows - No Node.js needed)

1. Download from: https://firebase.tools/bin/win/instant/latest
2. Extract the `.exe` file
3. Rename it to `firebase.exe`
4. Place it in a folder (e.g., `C:\firebase\`)
5. Add that folder to your PATH, or use full path when running

### Verify Installation

```bash
firebase --version
```

If using standalone binary without PATH:
```bash
C:\firebase\firebase.exe --version
```

## Step 3: Login to Firebase

```bash
firebase login
```

This will open a browser window. Sign in with your Google account that has access to the Firebase project.

## Step 4: Get Your Firebase App ID

Your Firebase App ID is already in `google-services.json`:
- **App ID**: `1:548250171926:android:b11829f5aa45e4de5337`

You can also find it in Firebase Console:
1. Go to Project Settings (gear icon)
2. Scroll to "Your apps"
3. Find your Android app
4. Copy the "App ID"

## Step 5: Create Tester Groups

1. **In Firebase Console → App Distribution → Testers & Groups**
2. **Click "Create group"**
3. **Name it**: "Beta Testers" (or any name you like)
4. **Add tester emails:**
   - Enter email addresses of your testers
   - They'll receive an email invitation
   - They need to accept the invitation before they can download

## Step 6: Build and Distribute

### Quick Command (After setup):

```bash
# Build the APK
C:\flutter\flutter\bin\flutter.bat build apk --debug

# Distribute to Firebase
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk ^
  --app 1:548250171926:android:b11829f2d5aa45e4de5337 ^
  --groups "Beta Testers" ^
  --release-notes "Beta version for testing - Version 1.0.0"
```

### What Happens:

1. ✅ APK is built
2. ✅ APK is uploaded to Firebase
3. ✅ Testers in "Beta Testers" group receive an email
4. ✅ They click the link to download and install
5. ✅ You can track who downloaded in Firebase Console

## Step 7: Create a Distribution Script (Optional)

Create a file `distribute.bat` in your project root:

```batch
@echo off
echo Building APK...
C:\flutter\flutter\bin\flutter.bat build apk --debug

echo.
echo Distributing to Firebase App Distribution...
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk ^
  --app 1:548250171926:android:b11829f2d5aa45e4de5337 ^
  --groups "Beta Testers" ^
  --release-notes "New build - %date% %time%"

echo.
echo Done! Testers will receive an email with download link.
pause
```

**In PowerShell:** Run `.\distribute.bat`  
**In Command Prompt:** Run `distribute.bat`

## Managing Testers

### Add New Testers:
1. Firebase Console → App Distribution → Testers & Groups
2. Click on your group
3. Click "Add testers"
4. Enter email addresses

### Remove Testers:
1. Go to your group
2. Click the three dots next to a tester
3. Click "Remove"

## Viewing Distribution History

1. Firebase Console → App Distribution → Releases
2. See all distributed builds
3. See who downloaded each build
4. View release notes

## Tester Experience

1. **Tester receives email** with subject: "You've been invited to test [App Name]"
2. **Clicks "View in browser"** or **"Download on Android device"**
3. **If on Android device**: Opens Firebase App Distribution app (auto-installs if needed)
4. **Downloads and installs** the APK
5. **Can provide feedback** through the Firebase App Distribution app

## Troubleshooting

### "Firebase CLI not found"
- Make sure you installed Firebase CLI: `npm install -g firebase-tools`
- Or download the standalone binary

### "Authentication required"
- Run: `firebase login`
- Make sure you're logged in with the correct Google account

### "App not found"
- Double-check your App ID from Firebase Console
- Make sure the app is registered in Firebase

### "Group not found"
- Make sure you created the group in Firebase Console first
- Check the group name spelling (case-sensitive)

### Testers not receiving emails
- Check spam folder
- Make sure testers accepted the invitation
- Check Firebase Console → App Distribution → Testers to see status

## Next Steps

1. ✅ Install Firebase CLI
2. ✅ Login: `firebase login`
3. ✅ Create tester group in Firebase Console
4. ✅ Run the distribution command
5. ✅ Testers receive emails and can download!

## Pro Tips

- **Version your builds**: Update `version: 1.0.0+1` in `pubspec.yaml` before each build
- **Add release notes**: Describe what's new in each build
- **Use groups**: Create different groups (e.g., "Internal Testers", "External Beta")
- **Track feedback**: Testers can provide feedback through the Firebase App Distribution app
