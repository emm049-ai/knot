# Flutter Setup Guide

## Your Flutter Location
Flutter is currently in: `C:\Users\emann\Downloads\flutter_windows_3.38.5-stable.zip\flutter`

## Step 1: Extract Flutter

The Flutter folder is inside a zip file. You need to extract it:

1. **Navigate to:** `C:\Users\emann\Downloads\`
2. **Right-click** on `flutter_windows_3.38.5-stable.zip`
3. **Select "Extract All..."**
4. **Choose extraction location** (recommended: `C:\flutter` or `C:\Users\emann\flutter`)
5. **Click "Extract"**

After extraction, Flutter should be at:
- `C:\flutter\flutter\bin\flutter.bat` (if extracted to C:\)
- OR `C:\Users\emann\flutter\flutter\bin\flutter.bat` (if extracted to your user folder)

## Step 2: Add Flutter to PATH (Optional but Recommended)

### Option A: Temporary (for this session only)
In PowerShell, run:
```powershell
$env:Path += ";C:\flutter\flutter\bin"
```
(Adjust path based on where you extracted it)

### Option B: Permanent
1. Press `Win + X` and select "System"
2. Click "Advanced system settings"
3. Click "Environment Variables"
4. Under "User variables", find "Path" and click "Edit"
5. Click "New" and add: `C:\flutter\flutter\bin` (adjust path)
6. Click "OK" on all dialogs
7. **Restart your terminal/IDE** for changes to take effect

## Step 3: Verify Flutter Installation

Open a new terminal and run:
```bash
flutter --version
```

You should see Flutter version information.

## Step 4: Install Dependencies

Once Flutter is set up, run:
```bash
cd C:\Users\emann\OneDrive\Desktop\knot
flutter pub get
```

## Alternative: Use Full Path (No PATH Setup Needed)

If you don't want to set up PATH, you can use the full path:

```powershell
cd C:\Users\emann\OneDrive\Desktop\knot
C:\flutter\flutter\bin\flutter.bat pub get
```

(Adjust the path based on where you extracted Flutter)

## Quick Commands (After Extraction)

Assuming you extracted to `C:\flutter\flutter`:

```powershell
# Install dependencies
cd C:\Users\emann\OneDrive\Desktop\knot
C:\flutter\flutter\bin\flutter.bat pub get

# Run the app
C:\flutter\flutter\bin\flutter.bat run

# Check Flutter doctor (diagnostics)
C:\flutter\flutter\bin\flutter.bat doctor
```

## Recommended Extraction Location

I recommend extracting to: `C:\flutter\flutter`

This way, the path will be:
- `C:\flutter\flutter\bin\flutter.bat`

And you can add `C:\flutter\flutter\bin` to your PATH.

## Next Steps After Flutter Setup

1. ✅ Extract Flutter zip file
2. ✅ (Optional) Add Flutter to PATH
3. ✅ Run `flutter pub get` in the project
4. ✅ Set up Supabase database (run `database/schema.sql`)
5. ✅ Test the app with `flutter run`
