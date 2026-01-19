# Install Knot App on Your Phone

## Quick Options

### Option 1: Install Android Studio (Recommended - ~1GB download)

**Steps:**
1. Download Android Studio: https://developer.android.com/studio
2. Install it (includes Android SDK automatically)
3. Open Android Studio once to complete setup
4. Accept Android SDK licenses:
   ```bash
   C:\flutter\flutter\bin\flutter.bat doctor --android-licenses
   ```
5. Build APK:
   ```bash
   cd C:\Users\emann\OneDrive\Desktop\knot
   C:\flutter\flutter\bin\flutter.bat build apk --release
   ```
6. Find APK: `build\app\outputs\flutter-apk\app-release.apk`
7. Transfer to phone and install

**Time:** ~30-60 minutes (mostly download/install time)

### Option 2: Use Online Build Service (No Installation Needed)

**Use Codemagic, AppCircle, or GitHub Actions:**
- Upload your code
- They build the APK for you
- Download the APK

**Time:** ~15-30 minutes

### Option 3: Use USB Debugging (If Phone Already Connected)

If your Android phone is connected:

1. **Enable Developer Mode on Phone:**
   - Settings → About Phone
   - Tap "Build Number" 7 times
   - Go back → Developer Options
   - Enable "USB Debugging"

2. **Check if phone is detected:**
   ```bash
   C:\flutter\flutter\bin\flutter.bat devices
   ```

3. **If detected, run directly:**
   ```bash
   C:\flutter\flutter\bin\flutter.bat run
   ```

**Time:** ~5 minutes (if phone is already connected)

### Option 4: Build APK Without Android Studio (Advanced)

Install only Android SDK Command Line Tools:

1. Download: https://developer.android.com/studio#command-tools
2. Extract to: `C:\Android\sdk`
3. Set environment variable:
   ```powershell
   [System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Android\sdk', 'User')
   ```
4. Add to PATH:
   - `C:\Android\sdk\platform-tools`
   - `C:\Android\sdk\tools\bin`
5. Install SDK components:
   ```bash
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
   ```
6. Accept licenses:
   ```bash
   sdkmanager --licenses
   ```
7. Build APK:
   ```bash
   C:\flutter\flutter\bin\flutter.bat build apk --release
   ```

**Time:** ~20-30 minutes

## Recommended: Option 1 (Android Studio)

This is the easiest and most reliable way. Android Studio includes everything you need.

## After Building APK

1. **Transfer APK to phone:**
   - Email it to yourself
   - Use Google Drive/Dropbox
   - USB transfer
   - QR code (generate QR for download link)

2. **Install on Android:**
   - Open the APK file on your phone
   - Allow "Install from Unknown Sources" if prompted
   - Tap Install

3. **Test all features:**
   - ✅ Phone contacts import
   - ✅ Camera for business cards
   - ✅ Voice recording
   - ✅ OCR text recognition
   - ✅ LinkedIn OAuth (with proper redirect URI)

## What You'll Need

- **Android Phone:** Any Android device (Android 5.0+)
- **Storage:** ~100MB for APK
- **Time:** 30-60 minutes for setup + build

## Quick Start Command (After Android SDK Installed)

```bash
# Build release APK
cd C:\Users\emann\OneDrive\Desktop\knot
C:\flutter\flutter\bin\flutter.bat build apk --release

# APK will be at:
# build\app\outputs\flutter-apk\app-release.apk
```

Let me know which option you'd like to use, or if you already have Android SDK installed somewhere!
