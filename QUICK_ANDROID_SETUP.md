# Quick Android SDK Setup (For Phone Testing)

## Fastest Way: Install Android SDK Command Line Tools Only

This is faster than installing full Android Studio (~500MB vs ~1GB).

### Step 1: Download Android SDK Command Line Tools

1. Go to: https://developer.android.com/studio#command-tools
2. Download **"Command line tools only"** for Windows
3. File will be named something like: `commandlinetools-win-11076708_latest.zip`

### Step 2: Extract and Setup

1. Create folder: `C:\Android\sdk`
2. Extract the zip file
3. Inside the extracted folder, you'll see a folder like `cmdline-tools`
4. Move `cmdline-tools` folder to: `C:\Android\sdk\cmdline-tools\latest`

**Final structure should be:**
```
C:\Android\sdk\
  └── cmdline-tools\
      └── latest\
          └── bin\
              └── sdkmanager.bat
```

### Step 3: Set Environment Variables

Run these commands in PowerShell (as Administrator):

```powershell
# Set ANDROID_HOME
[System.Environment]::SetEnvironmentVariable('ANDROID_HOME', 'C:\Android\sdk', 'User')

# Add to PATH
$currentPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
$newPath = $currentPath + ";C:\Android\sdk\platform-tools;C:\Android\sdk\cmdline-tools\latest\bin"
[System.Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
```

**Or manually:**
1. Press `Win + R`, type `sysdm.cpl`, press Enter
2. Go to **Advanced** tab → **Environment Variables**
3. Under **User variables**, click **New**:
   - Variable name: `ANDROID_HOME`
   - Variable value: `C:\Android\sdk`
4. Edit **Path** variable, add:
   - `C:\Android\sdk\platform-tools`
   - `C:\Android\sdk\cmdline-tools\latest\bin`

### Step 4: Install Required SDK Components

Open a **NEW** PowerShell window (to load new PATH) and run:

```bash
# Install platform tools and Android SDK
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# Accept all licenses
sdkmanager --licenses
# (Press 'y' for each license)
```

### Step 5: Tell Flutter Where SDK Is

```bash
C:\flutter\flutter\bin\flutter.bat config --android-sdk C:\Android\sdk
```

### Step 6: Verify Setup

```bash
C:\flutter\flutter\bin\flutter.bat doctor
```

You should see: `[√] Android toolchain - develop for Android devices`

### Step 7: Connect Your Phone

1. Enable USB Debugging on your phone (see ENABLE_USB_DEBUGGING.md)
2. Connect via USB
3. Check if detected:
   ```bash
   C:\flutter\flutter\bin\flutter.bat devices
   ```

### Step 8: Run App on Phone

```bash
cd C:\Users\emann\OneDrive\Desktop\knot
C:\flutter\flutter\bin\flutter.bat run
```

Or build APK:
```bash
C:\flutter\flutter\bin\flutter.bat build apk --release
```

## Alternative: Full Android Studio (Easier but Slower)

If the above seems complicated:

1. Download: https://developer.android.com/studio
2. Install (includes everything automatically)
3. Open once to complete setup
4. Run: `C:\flutter\flutter\bin\flutter.bat doctor --android-licenses`
5. Done!

## Time Estimate

- **Command Line Tools:** ~20-30 minutes
- **Full Android Studio:** ~30-60 minutes (mostly download)

Both work the same for building/running apps!
