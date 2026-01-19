# Enable USB Debugging on Your Android Phone

## Step-by-Step Instructions

### 1. Enable Developer Options

1. Open **Settings** on your phone
2. Go to **About Phone** (or **About Device**)
3. Find **Build Number**
4. **Tap "Build Number" 7 times** (you'll see a message like "You are now a developer!")

### 2. Enable USB Debugging

1. Go back to **Settings**
2. Find **Developer Options** (usually under System or Advanced)
3. Turn on **Developer Options** toggle
4. Scroll down and enable **USB Debugging**
5. If prompted, tap **OK** or **Allow**

### 3. Connect Your Phone

1. Connect your phone to your computer via USB cable
2. On your phone, you may see a popup: **"Allow USB debugging?"**
3. Check **"Always allow from this computer"**
4. Tap **Allow** or **OK**

### 4. Verify Connection

After enabling USB debugging, run this command on your computer:
```bash
C:\flutter\flutter\bin\flutter.bat devices
```

Your phone should appear in the list!

## Troubleshooting

### If phone still doesn't appear:

**Check USB Connection Mode:**
- When you connect, your phone may ask for USB mode
- Select **"File Transfer"** or **"MTP"** (not "Charging only")

**Install USB Drivers (if needed):**
- For Samsung: Install Samsung USB drivers
- For other brands: Install Android USB drivers from manufacturer
- Or use: https://developer.android.com/studio/run/win-usb

**Try Different USB Port:**
- Some USB ports don't support data transfer
- Try a different USB port on your computer

**Check ADB Connection:**
```bash
# Check if ADB sees the device
adb devices
```

If you see "unauthorized", check your phone for the USB debugging permission popup.

## Once Connected

After your phone appears in `flutter devices`, you can run:

```bash
C:\flutter\flutter\bin\flutter.bat run
```

This will install and run the app directly on your phone!
