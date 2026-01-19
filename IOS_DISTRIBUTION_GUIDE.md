# iOS Distribution Guide

## The Problem

**iOS testers cannot install Android APK files.** They need an iOS build (`.ipa` file).

## The Challenge

**Building iOS apps requires macOS** - you cannot build iOS apps on Windows.

## Solutions

### Option 1: Build on a Mac (Recommended)

If you have access to a Mac (or can borrow one):

1. **On the Mac:**
   ```bash
   # Clone or copy your project
   cd /path/to/knot
   
   # Install Flutter (if not already installed)
   # Get Flutter: https://flutter.dev/docs/get-started/install/macos
   
   # Install dependencies
   flutter pub get
   
   # Build iOS app
   flutter build ipa --debug
   ```

2. **Add iOS App to Firebase:**
   - Go to: https://console.firebase.google.com/project/knot-29668/settings/general
   - Click "Add app" → Select iOS
   - Bundle ID: `com.emanneul.knot`
   - Download `GoogleService-Info.plist` (already in your project)

3. **Distribute iOS Build:**
   ```bash
   firebase appdistribution:distribute build/ios/ipa/knot.ipa \
     --project knot-29668 \
     --app <iOS_APP_ID> \
     --groups "beta-testers" \
     --release-notes "iOS beta build"
   ```

4. **Get iOS App ID:**
   - After adding iOS app in Firebase Console
   - Go to: Project Settings → Your apps
   - Copy the iOS App ID (format: `1:548250171926:ios:xxxxx`)

### Option 2: Use a Cloud Mac Service

Services that provide Mac access in the cloud:
- **MacStadium** (https://www.macstadium.com/)
- **MacinCloud** (https://www.macincloud.com/)
- **AWS EC2 Mac instances** (https://aws.amazon.com/ec2/instance-types/mac/)

**Cost:** Usually $20-50/month

**Steps:**
1. Rent a Mac instance
2. Set up Flutter on it
3. Build iOS app
4. Distribute via Firebase

### Option 3: Separate Tester Groups

Create separate groups for Android and iOS testers:

1. **In Firebase Console:**
   - Create group: "Android Testers"
   - Create group: "iOS Testers"

2. **Distribute separately:**
   - Android: Use existing `distribute.bat` script
   - iOS: Build on Mac and distribute separately

3. **Update distribution scripts:**
   - `distribute-android.bat` - for Android
   - `distribute-ios.sh` - for iOS (on Mac)

### Option 4: Use TestFlight (iOS Only)

If you have an Apple Developer account ($99/year):

1. **Build on Mac:**
   ```bash
   flutter build ipa --release
   ```

2. **Upload to App Store Connect:**
   - Use Xcode or `xcrun altool`
   - Or use Fastlane

3. **Add testers in TestFlight:**
   - App Store Connect → TestFlight
   - Add tester emails
   - They get TestFlight app and can install

**Pros:**
- Professional distribution
- Easy for testers
- Built-in feedback

**Cons:**
- Requires Apple Developer account
- Requires Mac to build
- More setup

### Option 5: Tell iOS Testers to Wait

If you don't have Mac access:
- Let them know iOS version is coming
- Focus on Android testing first
- Build iOS version when you have Mac access

## Current Status

✅ **Android:** Ready to distribute  
❌ **iOS:** Needs Mac to build

## Quick Setup for iOS (When You Have Mac)

1. **Copy project to Mac**
2. **Install Flutter on Mac:**
   ```bash
   # Download Flutter for macOS
   # https://flutter.dev/docs/get-started/install/macos
   
   # Extract and add to PATH
   export PATH="$PATH:/path/to/flutter/bin"
   ```

3. **Install Xcode:**
   ```bash
   # From App Store or Apple Developer site
   xcode-select --install
   ```

4. **Configure iOS:**
   ```bash
   cd /path/to/knot
   flutter pub get
   flutter doctor
   ```

5. **Add iOS App to Firebase:**
   - Firebase Console → Add iOS app
   - Bundle ID: `com.emanneul.knot`
   - Download `GoogleService-Info.plist`
   - Place in: `ios/Runner/GoogleService-Info.plist`

6. **Build and distribute:**
   ```bash
   flutter build ipa --debug
   
   firebase appdistribution:distribute build/ios/ipa/knot.ipa \
     --project knot-29668 \
     --app <YOUR_IOS_APP_ID> \
     --groups "beta-testers" \
     --release-notes "iOS beta build"
   ```

## Separate Distribution Scripts

### For Android (Windows):
```batch
# distribute-android.bat
@echo off
echo Building Android APK...
C:\flutter\flutter\bin\flutter.bat build apk --debug

firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk ^
  --project knot-29668 ^
  --app 1:548250171926:android:b11829f2d5aa45e4de5337 ^
  --groups "android-testers" ^
  --release-notes "%RELEASE_NOTES%"
```

### For iOS (macOS):
```bash
#!/bin/bash
# distribute-ios.sh

echo "Building iOS IPA..."
flutter build ipa --debug

echo "Distributing to Firebase..."
firebase appdistribution:distribute build/ios/ipa/knot.ipa \
  --project knot-29668 \
  --app <YOUR_IOS_APP_ID> \
  --groups "ios-testers" \
  --release-notes "$1"
```

## Recommendations

**Short term:**
1. Create separate tester groups: "android-testers" and "ios-testers"
2. Distribute Android build to Android testers
3. Let iOS testers know you're working on iOS version

**Long term:**
1. Get access to a Mac (borrow, rent, or buy)
2. Set up iOS build pipeline
3. Distribute both platforms simultaneously

## Next Steps

1. **Decide which option works for you**
2. **If you have Mac access:** Follow "Quick Setup for iOS" above
3. **If no Mac access:** Consider cloud Mac service or tell iOS testers to wait
4. **Update tester groups** to separate Android and iOS testers
