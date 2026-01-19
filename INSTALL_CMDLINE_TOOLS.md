# Install Android Command Line Tools

## Quick Fix: Install via Android Studio

1. **Open Android Studio**
2. Go to: **Tools → SDK Manager** (or click the SDK Manager icon in the toolbar)
3. Click the **SDK Tools** tab
4. Check **Android SDK Command-line Tools (latest)**
5. Click **Apply** or **OK**
6. Wait for installation to complete

## After Installation

Once installed, run:

```bash
# Accept licenses
C:\flutter\flutter\bin\flutter.bat doctor --android-licenses
# (Press 'y' for each license)

# Check if everything is working
C:\flutter\flutter\bin\flutter.bat doctor

# Check if your phone is detected
C:\flutter\flutter\bin\flutter.bat devices
```

## Alternative: Install via Command Line

If you prefer command line:

1. Download command line tools: https://developer.android.com/studio#command-tools
2. Extract to: `C:\Users\emann\AppData\Local\Android\Sdk\cmdline-tools\latest`
3. Run: `C:\Users\emann\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat "cmdline-tools;latest"`

But the Android Studio method is easier!
