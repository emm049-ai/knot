# Firebase Setup Guide for Knot App

## What You Need from Firebase Console

For push notifications, you'll need to set up Firebase and provide these files:

### 1. Creating Firebase Project (Handling Parent Resource)

When Firebase asks for a "parent resource" in Google Cloud:

**Option 1: Skip it (Recommended for most users)**
- You can leave the "Parent resource" field **empty** or **unselected**
- Firebase will create the project without a parent organization
- This is fine for personal/small projects
- Click "Continue" or "Create project" without selecting a parent resource

**Option 2: Use Your Google Cloud Organization (if you have one)**
- If you're part of a Google Cloud Organization, you can select it
- This is only needed for enterprise/organizational setups
- For individual developers, this is **not required**

**What is a Parent Resource?**
- A parent resource is a Google Cloud Organization or Folder
- It's used for billing and resource management in large organizations
- For individual projects, you don't need it

### 2. Firebase Console Setup Steps

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. **Enter project name**: "Knot" (or your preferred name)
4. **Parent resource**: Leave empty/unselected (unless you have a specific organization)
5. **Google Analytics**: Optional - you can enable or skip
6. Click "Create project"
7. Wait for project creation (takes ~30 seconds)

### 3. Add Your Apps

After project creation, add your apps:

#### Android App:
1. Click "Add app" → Select Android icon
2. **Package name**: Check your `android/app/build.gradle` file for `applicationId`
   - Default might be: `com.example.knot` or similar
   - You can change this to: `com.yourcompany.knot`
3. **App nickname**: "Knot Android" (optional)
4. **Debug signing certificate**: Leave blank for now
5. Click "Register app"
6. **Download `google-services.json`**
7. Place it in: `android/app/google-services.json`

#### iOS App:
1. Click "Add app" → Select iOS icon
2. **Bundle ID**: Check your `ios/Runner.xcodeproj` or `Info.plist`
   - Default might be: `com.example.knot` or similar
   - You can change this to: `com.yourcompany.knot`
3. **App nickname**: "Knot iOS" (optional)
4. **App Store ID**: Leave blank (add later if publishing)
5. Click "Register app"
6. **Download `GoogleService-Info.plist`**
7. Place it in: `ios/Runner/GoogleService-Info.plist`

### 4. Firebase Cloud Messaging Setup

1. In Firebase Console → Project Settings → Cloud Messaging
2. Enable Cloud Messaging API (if not already enabled)
3. Note your **Server Key** (for backend use, if needed later)

### 5. Android Configuration

#### Update `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'
    }
}
```

#### Update `android/app/build.gradle`:
Add at the **bottom** of the file (after all other plugins):
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 6. iOS Configuration

1. Open `ios/Runner.xcworkspace` in Xcode (not .xcodeproj)
2. Drag `GoogleService-Info.plist` into the Runner folder in Xcode
3. Ensure "Copy items if needed" is checked
4. Ensure it's added to the "Runner" target

### 7. Verify Setup

After adding the files, you can verify:

**Android:**
```bash
cd android
./gradlew app:dependencies | grep firebase
```

**iOS:**
- Open Xcode and check if `GoogleService-Info.plist` appears in the project navigator

### 8. Environment Variable (Optional)

If you need the project ID in your app:
```
FIREBASE_PROJECT_ID=your-firebase-project-id
```

You can find this in Firebase Console → Project Settings → General

## Troubleshooting

### "Parent resource required" error
- **Solution**: Leave the field empty and continue
- Firebase projects don't require a parent resource for basic use

### "Billing account required"
- **Solution**: Firebase has a free tier (Spark plan)
- You only need billing for paid features
- For push notifications, free tier is sufficient

### Can't find Cloud Messaging
- **Solution**: 
  1. Go to Project Settings
  2. Click "Cloud Messaging" tab
  3. If it's not there, your project might need to be upgraded (but free tier should work)

### Files not found errors
- **Solution**: 
  - Ensure files are in exact locations specified
  - Check file names are correct (case-sensitive)
  - For Android: `android/app/google-services.json`
  - For iOS: `ios/Runner/GoogleService-Info.plist`

## Note

The app will work without Firebase - push notifications are optional. The app will gracefully handle missing Firebase configuration.

If you skip Firebase setup for now, you can add it later. The app code already handles missing Firebase gracefully.
