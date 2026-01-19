# Build App for Your Phone

## Option 1: Build APK (Easiest - No Android Studio Needed)

### Step 1: Install Android SDK (if not already installed)

You have two options:

**Option A: Install Android Studio (Recommended)**
1. Download from: https://developer.android.com/studio
2. Install Android Studio
3. Open Android Studio → More Actions → SDK Manager
4. Install Android SDK (API 34 recommended)
5. Accept licenses: `flutter doctor --android-licenses`

**Option B: Install Android SDK Command Line Tools Only**
1. Download: https://developer.android.com/studio#command-tools
2. Extract to a folder (e.g., `C:\Android\sdk`)
3. Set environment variable: `ANDROID_HOME=C:\Android\sdk`
4. Add to PATH: `C:\Android\sdk\platform-tools` and `C:\Android\sdk\tools`

### Step 2: Build the APK

Once Android SDK is installed:

```bash
cd C:\Users\emann\OneDrive\Desktop\knot
C:\flutter\flutter\bin\flutter.bat build apk --release
```

This will create: `build\app\outputs\flutter-apk\app-release.apk`

### Step 3: Install on Your Phone

**For Android:**
1. Transfer the APK to your phone (USB, email, cloud storage)
2. On your phone: Settings → Security → Enable "Install from Unknown Sources"
3. Open the APK file and install

**For iPhone (iOS):**
- Requires Mac with Xcode
- Or use TestFlight (requires Apple Developer account)
- Or build on a Mac

## Option 2: Use USB Debugging (If Phone Connected)

If your phone is connected via USB:

1. Enable USB Debugging on your phone:
   - Settings → About Phone → Tap "Build Number" 7 times
   - Settings → Developer Options → Enable "USB Debugging"

2. Check if phone is detected:
   ```bash
   C:\flutter\flutter\bin\flutter.bat devices
   ```

3. Run directly on phone:
   ```bash
   C:\flutter\flutter\bin\flutter.bat run
   ```

## Option 3: Use Flutter DevTools (Web Preview)

For quick testing without building:
- The web version works for most features
- Mobile-specific features (camera, contacts, voice) need actual phone

## Current Status

- ✅ App is configured for Android (package: `com.emanneul.knot`)
- ⚠️ Android SDK not detected - need to install first
- ✅ All permissions configured in AndroidManifest.xml

## Quick Start (If Android SDK Already Installed)

If you already have Android SDK somewhere:

1. Tell Flutter where it is:
   ```bash
   C:\flutter\flutter\bin\flutter.bat config --android-sdk C:\path\to\android\sdk
   ```

2. Build APK:
   ```bash
   C:\flutter\flutter\bin\flutter.bat build apk --release
   ```

3. Find APK: `build\app\outputs\flutter-apk\app-release.apk`

## What Features Will Work on Phone

✅ **Will Work:**
- Phone contacts import
- Camera for business cards
- Voice recording
- OCR text recognition
- Calendar integration
- All import features

❌ **Won't Work on Web:**
- Phone contacts (as you've seen)
- Camera/OCR (limited)
- Voice recording

Let me know if you have Android SDK installed or if you need help installing it!
