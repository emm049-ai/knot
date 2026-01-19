# Firebase App Distribution - Quick Start 🚀

## Your Firebase Info
- **Project**: `knot-29668`
- **App ID**: `1:548250171926:android:b11829f2d5aa45e4de5337`
- **Package**: `com.emanneul.knot`

## Setup Steps (One-Time)

### 1. Install Firebase CLI

**Option A: Using npm (if you have Node.js)**
```bash
npm install -g firebase-tools
```

**Option B: Standalone (no Node.js needed)**
1. Download: https://firebase.tools/bin/win/instant/latest
2. Extract `firebase.exe`
3. Place in `C:\firebase\` (or any folder)
4. Add to PATH, or use full path: `C:\firebase\firebase.exe`

### 2. Login to Firebase

```bash
firebase login
```

Opens browser → Sign in with your Google account

### 3. Initialize Firebase in Project (One-time)

```bash
cd C:\Users\emann\OneDrive\Desktop\knot
firebase init appdistribution
```

**When prompted:**
- Select project: `knot-29668`
- App ID: `1:548250171926:android:b11829f2d5aa45e4de5337`
- Testers: Leave blank (we'll use groups)

### 4. Create Tester Group in Firebase Console

1. Go to: https://console.firebase.google.com/project/knot-29668/appdistribution
2. Click **"Testers & Groups"** → **"Create group"**
3. Name: **"Beta Testers"**
4. Add tester email addresses
5. Click **"Create"**

Testers will receive an email invitation - they need to accept it!

## Distribute Your App (Every Time)

### Easy Way: Use the Script

**In PowerShell:**
```powershell
.\distribute.bat
```

**In Command Prompt (cmd):**
```bash
distribute.bat
```

It will:
1. Build the APK
2. Ask for release notes
3. Upload to Firebase
4. Notify testers

### Manual Way

```bash
# 1. Build APK
C:\flutter\flutter\bin\flutter.bat build apk --debug

# 2. Distribute
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk ^
  --app 1:548250171926:android:b11829f2d5aa45e4de5337 ^
  --groups "Beta Testers" ^
  --release-notes "Your release notes here"
```

## What Testers See

### Android Testers:
1. **Email**: "You've been invited to test Knot"
2. **Click link** → Opens Firebase App Distribution
3. **Download** → Installs APK automatically
4. **Done!** They can test your app

### iOS Testers:
⚠️ **Important:** iOS testers **cannot** install Android APK files. They need an iOS build (`.ipa` file).

**Current Status:**
- ✅ Android build ready
- ❌ iOS build requires macOS to build

**Options for iOS testers:**
1. Wait for iOS build (requires Mac access)
2. See `IOS_DISTRIBUTION_GUIDE.md` for details

## View Distribution Status

Go to: https://console.firebase.google.com/project/knot-29668/appdistribution/releases

See:
- All distributed builds
- Who downloaded each build
- Release notes
- Download statistics

## Troubleshooting

**"firebase: command not found"**
→ Install Firebase CLI (Step 1)

**"Authentication required"**
→ Run `firebase login`

**"App not found"**
→ Check App ID matches: `1:548250171926:android:b11829f2d5aa45e4de5337`

**"Group not found"**
→ Create "Beta Testers" group in Firebase Console first

**Testers not receiving emails**
→ Check they accepted the invitation in Firebase Console

**iOS testers can't install Android APK**
→ iOS requires separate iOS build (`.ipa` file). See `IOS_DISTRIBUTION_GUIDE.md` for options.

## Next Steps

1. ✅ Install Firebase CLI
2. ✅ Run `firebase login`
3. ✅ Run `firebase init appdistribution`
4. ✅ Create "Beta Testers" group in Firebase Console
5. ✅ Add tester emails
6. ✅ Run `.\distribute.bat` (PowerShell) or `distribute.bat` (cmd) to send your first build!

---

**Full guide**: See `FIREBASE_APP_DISTRIBUTION_SETUP.md` for detailed instructions.
