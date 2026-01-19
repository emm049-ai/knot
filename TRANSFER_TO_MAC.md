# Transfer Project from Windows to Mac

## Option 1: OneDrive Sync (Easiest - If Using OneDrive) ⭐

Since your project is in `C:\Users\emann\OneDrive\Desktop\knot`, it should already be syncing to OneDrive!

**On your Mac:**
1. **Install OneDrive** (if not already):
   - Download from: https://www.microsoft.com/en-us/microsoft-365/onedrive/download
   - Sign in with the same Microsoft account

2. **Find your project:**
   - OneDrive should sync automatically
   - Look in: `~/OneDrive/Desktop/knot` (or wherever OneDrive syncs to)

3. **Open in Cursor:**
   ```bash
   cd ~/OneDrive/Desktop/knot
   # Or wherever OneDrive synced it
   ```

**That's it!** The project should already be there if OneDrive is syncing.

---

## Option 2: Git Repository (Best for Development)

If you have a Git repository (GitHub, GitLab, etc.):

### On Windows (Current Machine):
```bash
# If you haven't committed yet, commit your changes:
git add .
git commit -m "Prepare for iOS build"

# Push to remote (if you have one):
git push
```

### On Mac:
```bash
# Clone the repository:
git clone <your-repo-url>
cd knot

# Install dependencies:
flutter pub get
```

**Don't have a Git repo yet?** Create one:
1. Go to GitHub.com → Create new repository
2. Follow instructions to push your code
3. Then clone on Mac

---

## Option 3: Manual Copy via Network

### Using Windows File Sharing:

**On Windows:**
1. Right-click the `knot` folder
2. Properties → Sharing → Share
3. Share with your user account
4. Note the network path (e.g., `\\YOUR-PC-NAME\knot`)

**On Mac:**
1. Open Finder
2. Press `Cmd + K` (Connect to Server)
3. Enter: `smb://YOUR-PC-IP-ADDRESS` or `smb://YOUR-PC-NAME`
4. Enter Windows username/password
5. Copy the `knot` folder to your Mac

---

## Option 4: USB Drive / External Drive

1. **On Windows:**
   - Copy the entire `knot` folder to USB drive
   - Make sure to include hidden files (`.git`, `.env`, etc.)

2. **On Mac:**
   - Plug in USB drive
   - Copy `knot` folder to desired location (e.g., `~/Desktop/knot`)

**Important:** Make sure to copy hidden files:
- `.env` (your API keys!)
- `.git` (if using Git)
- Any other hidden config files

---

## Option 5: Cloud Storage (Google Drive, Dropbox)

1. **On Windows:**
   - Upload `knot` folder to Google Drive/Dropbox
   - Wait for upload to complete

2. **On Mac:**
   - Install Google Drive/Dropbox app
   - Download the `knot` folder

---

## Option 6: Zip and Email/Cloud Upload

1. **On Windows:**
   ```powershell
   # Create a zip file (exclude build folders to save space)
   Compress-Archive -Path "C:\Users\emann\OneDrive\Desktop\knot" -DestinationPath "C:\Users\emann\Desktop\knot.zip" -Exclude "build\*","*.lock"
   ```

2. **Upload zip to:**
   - Google Drive
   - OneDrive
   - Dropbox
   - Or email it to yourself

3. **On Mac:**
   - Download the zip
   - Extract to desired location
   - Remove the zip file after extraction

---

## Recommended: OneDrive (Since You're Already Using It)

**Check if OneDrive is syncing:**

**On Windows:**
- Look for OneDrive icon in system tray
- Right-click → Settings → Check sync status
- Make sure Desktop folder is syncing

**On Mac:**
1. Install OneDrive app
2. Sign in with same account
3. Enable Desktop sync
4. Project should appear automatically!

---

## After Transferring: Important Files to Check

Make sure these files are present on Mac:

✅ `.env` - Your API keys (IMPORTANT!)
✅ `pubspec.yaml` - Dependencies
✅ `android/app/google-services.json` - Firebase Android config
✅ `ios/Runner/GoogleService-Info.plist` - Firebase iOS config (if exists)
✅ All source files in `lib/`

**Don't transfer:**
❌ `build/` folder (will be regenerated)
❌ `.dart_tool/` (will be regenerated)
❌ `node_modules/` (if exists, will be regenerated)

---

## Quick Check After Transfer

**On Mac, run:**
```bash
cd /path/to/knot

# Check if project is complete
ls -la

# Install dependencies
flutter pub get

# Check Flutter setup
flutter doctor
```

---

## Which Method Should You Use?

**If OneDrive is already syncing:** Use Option 1 (easiest!)

**If you want version control:** Use Option 2 (Git)

**If OneDrive isn't syncing:** Use Option 3, 4, or 5

**Fastest for one-time transfer:** Option 6 (Zip and upload)
