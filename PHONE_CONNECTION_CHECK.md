# Connect Your Android Phone - Step by Step

## Step 1: Enable Developer Options on Your Phone

1. Open **Settings** on your Android phone
2. Go to **About Phone** (or **About Device**)
3. Find **Build Number**
4. **Tap "Build Number" 7 times** until you see: "You are now a developer!"

## Step 2: Enable USB Debugging

1. Go back to **Settings**
2. Find **Developer Options** (usually under System, Advanced, or About)
3. Turn on **Developer Options** toggle (top of screen)
4. Scroll down and enable **USB Debugging**
5. If you see a warning, tap **OK**

## Step 3: Connect Your Phone

1. Connect your phone to your laptop via USB cable
2. On your phone, you should see a popup: **"Allow USB debugging?"**
3. ✅ Check the box: **"Always allow from this computer"**
4. Tap **Allow** or **OK**

## Step 4: Check USB Connection Mode

When you connect, your phone may ask for USB connection mode:
- Select **"File Transfer"** or **"MTP"** (NOT "Charging only")
- This allows data transfer, not just charging

## Step 5: Verify Connection

After completing the above steps, run:

```bash
C:\flutter\flutter\bin\flutter.bat devices
```

Your phone should appear in the list!

## Troubleshooting

### If phone still doesn't appear:

**Try different USB port:**
- Some USB ports are power-only
- Try a different USB port on your laptop

**Check USB cable:**
- Make sure it's a data cable (not charging-only)
- Try a different cable if possible

**Revoke and re-authorize:**
- On phone: Settings → Developer Options → Revoke USB debugging authorizations
- Disconnect and reconnect phone
- Allow USB debugging again

**Check phone screen:**
- Make sure phone is unlocked
- Check for any popups asking for permission

**Install USB drivers (if needed):**
- Samsung: Install Samsung USB drivers
- Other brands: May need manufacturer USB drivers
- Or try: https://developer.android.com/studio/run/win-usb

## Once Connected

When your phone appears in `flutter devices`, you can:

```bash
# Run the app directly on your phone
cd C:\Users\emann\OneDrive\Desktop\knot
C:\flutter\flutter\bin\flutter.bat run
```

This will install and launch the Knot app on your phone!
