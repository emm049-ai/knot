# iOS Distribution Setup on Mac

## Step 1: Clone/Copy Project to Mac

If you haven't already:

1. **Option A: Clone from Git** (if you have a repo)
   ```bash
   git clone <your-repo-url>
   cd knot
   ```

2. **Option B: Copy project folder**
   - Copy the entire `knot` folder to your Mac
   - Or use OneDrive sync if you're using OneDrive

## Step 2: Install Flutter on Mac

1. **Download Flutter:**
   ```bash
   cd ~
   git clone https://github.com/flutter/flutter.git -b stable
   ```

2. **Add to PATH:**
   ```bash
   # Add to ~/.zshrc or ~/.bash_profile
   export PATH="$PATH:$HOME/flutter/bin"
   
   # Then reload:
   source ~/.zshrc  # or source ~/.bash_profile
   ```

3. **Verify installation:**
   ```bash
   flutter doctor
   ```

4. **Install Xcode:**
   ```bash
   # Install from App Store, then:
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   ```

5. **Accept licenses:**
   ```bash
   sudo xcodebuild -license accept
   ```

## Step 3: Install Dependencies

```bash
cd /path/to/knot
flutter pub get
```

## Step 4: Add iOS App to Firebase

1. **Go to Firebase Console:**
   - https://console.firebase.google.com/project/knot-29668/settings/general

2. **Click "Add app" → Select iOS**

3. **Enter details:**
   - **Bundle ID**: `com.emanneul.knot`
   - **App nickname**: "Knot iOS" (optional)
   - **App Store ID**: Leave blank

4. **Click "Register app"**

5. **Download `GoogleService-Info.plist`**

6. **Add to project:**
   ```bash
   # Place in ios/Runner/GoogleService-Info.plist
   # (Should already be there if you copied from Windows)
   ```

7. **Get iOS App ID:**
   - After registering, copy the iOS App ID
   - Format: `1:548250171926:ios:xxxxx`
   - Save this for the distribution script

## Step 5: Configure iOS Project

1. **Open in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```
   (Important: Use `.xcworkspace`, not `.xcodeproj`)

2. **In Xcode:**
   - Select "Runner" project in left sidebar
   - Select "Runner" target
   - Go to "Signing & Capabilities" tab
   - **Bundle Identifier**: Should be `com.emanneul.knot`
   - **Team**: Select your Apple Developer team (or create one)
   - **Signing Certificate**: Xcode will auto-manage

3. **Verify GoogleService-Info.plist:**
   - Should appear in Xcode project navigator
   - If not, drag it into `Runner` folder
   - Make sure "Copy items if needed" is checked
   - Make sure it's added to "Runner" target

## Step 6: Install Firebase CLI (if not already)

```bash
npm install -g firebase-tools
```

Or if you don't have Node.js:
```bash
# Download standalone binary
curl -sL https://firebase.tools | bash
```

## Step 7: Login to Firebase

```bash
firebase login
```

## Step 8: Build iOS App

### Debug Build (for testing):
```bash
flutter build ipa --debug
```

### Release Build (for production):
```bash
flutter build ipa --release
```

**Output location:** `build/ios/ipa/knot.ipa`

## Step 9: Get iOS App ID

After adding iOS app in Firebase Console:
- Go to: Project Settings → Your apps
- Find iOS app
- Copy the App ID (format: `1:548250171926:ios:xxxxx`)

## Step 10: Distribute to Firebase

### Manual Command:
```bash
firebase appdistribution:distribute build/ios/ipa/knot.ipa \
  --project knot-29668 \
  --app <YOUR_IOS_APP_ID> \
  --groups "beta-testers" \
  --release-notes "iOS beta build - First release"
```

Replace `<YOUR_IOS_APP_ID>` with your actual iOS App ID.

### Or Use the Script:
```bash
./distribute-ios.sh "iOS beta build - First release"
```

## Troubleshooting

### "No code signing certificate found"
- Open Xcode → Preferences → Accounts
- Add your Apple ID
- Select team in Signing & Capabilities

### "GoogleService-Info.plist not found"
- Download from Firebase Console
- Place in `ios/Runner/GoogleService-Info.plist`
- Add to Xcode project

### "Flutter command not found"
- Add Flutter to PATH (see Step 2)
- Or use full path: `~/flutter/bin/flutter`

### "Firebase CLI not found"
- Install: `npm install -g firebase-tools`
- Or use standalone binary

## Next Steps

1. ✅ Set up Flutter on Mac
2. ✅ Add iOS app to Firebase
3. ✅ Build iOS app
4. ✅ Distribute to testers
5. ✅ iOS testers can now install!
