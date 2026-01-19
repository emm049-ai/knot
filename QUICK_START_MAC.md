# Quick Start: iOS Distribution on Mac 🍎

## Prerequisites Check

Run these to see what you need:

```bash
# Check Flutter
flutter --version

# Check Xcode
xcodebuild -version

# Check Firebase CLI
firebase --version
```

## Quick Setup (5 Steps)

### 1. Navigate to Project
```bash
cd /path/to/knot
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Add iOS App to Firebase

**Go to:** https://console.firebase.google.com/project/knot-29668/settings/general

1. Click **"Add app"** → Select **iOS**
2. **Bundle ID**: `com.emanneul.knot`
3. Click **"Register app"**
4. **Download** `GoogleService-Info.plist`
5. **Place it in:** `ios/Runner/GoogleService-Info.plist`
6. **Copy the iOS App ID** (format: `1:548250171926:ios:xxxxx`)

### 4. Set iOS App ID

```bash
# Add to your shell profile (~/.zshrc or ~/.bash_profile)
export IOS_APP_ID='1:548250171926:ios:xxxxx'  # Replace with your actual ID

# Then reload:
source ~/.zshrc  # or source ~/.bash_profile
```

### 5. Make Script Executable and Run

```bash
chmod +x distribute-ios.sh
./distribute-ios.sh "First iOS beta build"
```

## That's It! 🎉

iOS testers will receive an email with the download link.

## Troubleshooting

**"Flutter not found"**
→ Install Flutter: https://flutter.dev/docs/get-started/install/macos

**"Xcode not found"**
→ Install from App Store, then:
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
```

**"Firebase CLI not found"**
→ Install: `npm install -g firebase-tools`

**"No code signing certificate"**
→ Open Xcode → Preferences → Accounts → Add Apple ID

**"GoogleService-Info.plist not found"**
→ Download from Firebase Console and place in `ios/Runner/`

## Full Guide

See `IOS_SETUP_MAC.md` for detailed instructions.
