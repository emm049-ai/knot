# Sync Project to Mac via OneDrive

## The Easiest Way (Since You're Using OneDrive)

Your project is already in OneDrive! Here's how to access it on your Mac:

### Step 1: Install OneDrive on Mac

1. **Download OneDrive:**
   - Go to: https://www.microsoft.com/en-us/microsoft-365/onedrive/download
   - Download "OneDrive for Mac"
   - Install it

2. **Sign in:**
   - Use the same Microsoft account you use on Windows
   - This ensures you see the same files

### Step 2: Enable Desktop Sync (If Needed)

1. **Open OneDrive preferences:**
   - Click OneDrive icon in menu bar (top right)
   - Click the gear icon → Preferences

2. **Check sync settings:**
   - Go to "Account" tab
   - Make sure "Desktop" folder is checked for syncing
   - If not, click "Choose folders" and enable Desktop

### Step 3: Find Your Project

**On your Mac:**
```bash
# The project should be at:
~/OneDrive/Desktop/knot

# Or check:
ls ~/OneDrive/Desktop/
```

If you see the `knot` folder, you're all set!

### Step 4: Open in Cursor on Mac

1. **Open Cursor** on your Mac
2. **File → Open Folder**
3. **Navigate to:** `~/OneDrive/Desktop/knot`
4. **Click "Open"**

That's it! The project should be there and synced.

---

## If OneDrive Isn't Syncing Desktop

If Desktop folder isn't syncing, you have two options:

### Option A: Move Project to OneDrive Folder

**On Windows:**
1. Move `knot` folder from `Desktop` to `OneDrive` root:
   ```
   From: C:\Users\emann\OneDrive\Desktop\knot
   To:   C:\Users\emann\OneDrive\knot
   ```

2. OneDrive will sync it automatically

**On Mac:**
- Find it at: `~/OneDrive/knot`

### Option B: Create a Zip and Upload

**On Windows (PowerShell):**
```powershell
# Navigate to Desktop
cd C:\Users\emann\OneDrive\Desktop

# Create zip (excludes build folders to save space)
Compress-Archive -Path "knot" -DestinationPath "C:\Users\emann\OneDrive\knot.zip" -Force
```

**On Mac:**
1. Download `knot.zip` from OneDrive
2. Extract it:
   ```bash
   cd ~/OneDrive
   unzip knot.zip
   ```
3. Delete the zip file after extraction

---

## Verify Project is Complete

**On Mac, check these files exist:**
```bash
cd ~/OneDrive/Desktop/knot  # or wherever it is

# Check important files
ls -la .env              # Should exist (your API keys!)
ls -la pubspec.yaml      # Should exist
ls -la lib/              # Should have your source code
```

**If `.env` is missing:**
- You'll need to copy it manually (it might be in `.gitignore`)
- Or recreate it with your API keys

---

## Quick Test

**On Mac:**
```bash
cd ~/OneDrive/Desktop/knot

# Install dependencies
flutter pub get

# Check Flutter setup
flutter doctor
```

If these work, you're ready to build iOS!

---

## Troubleshooting

**"OneDrive folder not found"**
- Make sure OneDrive is installed and signed in
- Check sync status in OneDrive preferences

**"Project folder empty"**
- Wait a few minutes for sync to complete
- Check OneDrive sync status

**".env file missing"**
- Copy it manually from Windows
- Or recreate it (see your `.env.example` if you have one)

**"Files not syncing"**
- Check OneDrive sync status
- Make sure you're signed in with the same account
- Try pausing and resuming sync

---

## Next Steps After Sync

Once the project is on your Mac:

1. ✅ Open in Cursor
2. ✅ Follow `QUICK_START_MAC.md`
3. ✅ Build iOS app
4. ✅ Distribute to testers!
