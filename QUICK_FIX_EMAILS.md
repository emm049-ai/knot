# Quick Fix: Testers Not Receiving Emails

## Most Common Issue: Tester Group Setup

**90% of the time, this is the problem:**

### Step 1: Create Tester Group in Firebase Console

1. **Go to:** https://console.firebase.google.com/project/knot-29668/appdistribution
2. **Click:** "Testers & Groups" (left sidebar)
3. **Click:** "Create group" button
4. **Name:** `Beta Testers` (exactly this, case-sensitive)
5. **Click:** "Create"

### Step 2: Add Tester Emails

1. **Click on** "Beta Testers" group
2. **Click:** "Add testers" button
3. **Enter email addresses** (one per line or comma-separated)
4. **Click:** "Add"

### Step 3: Testers Must Accept Invitation

**Important:** Testers will receive TWO types of emails:

1. **Invitation Email** (first time only)
   - Subject: "You've been invited to test Knot"
   - They MUST click the link and accept
   - Until they accept, they won't receive distribution emails

2. **Distribution Email** (each time you distribute)
   - Subject: "New build available for Knot"
   - Contains download link
   - Only sent to testers who accepted the invitation

### Step 4: Check Tester Status

In Firebase Console → Testers & Groups → Beta Testers:
- ✅ **"Active"** = Will receive emails
- ⏳ **"Pending"** = Need to accept invitation first
- ❌ **"Expired"** = Need to resend invitation

### Step 5: Re-Distribute

After setting up the group and testers:

```powershell
.\distribute.bat
```

Or use the fix script:
```powershell
.\fix_distribution.bat
```

## Verify Distribution Worked

1. **Check Firebase Console:**
   - Go to: https://console.firebase.google.com/project/knot-29668/appdistribution/releases
   - You should see your build listed
   - Click on it to see who it was sent to

2. **Check Terminal Output:**
   - Should see: "Distribution successful!" or similar
   - If you see errors, the distribution failed

## Still Not Working?

### Option 1: Distribute to Individual Emails (Bypass Group)

```powershell
firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk --project knot-29668 --app 1:548250171926:android:b11829f2d5aa45e4de5337 --testers "email1@example.com,email2@example.com" --release-notes "Test build"
```

### Option 2: Check Firebase Console Manually

1. Go to Firebase Console → App Distribution → Releases
2. Click "Distribute release" (if available)
3. Upload APK manually
4. Assign to testers
5. This helps identify if it's a CLI issue

### Option 3: Verify Everything

Run this to check:
```powershell
firebase appdistribution:groups:list --project knot-29668
```

Should show your "Beta Testers" group.

## Summary

**Most likely issue:** The "Beta Testers" group doesn't exist or has no testers.

**Quick fix:**
1. Create group in Firebase Console
2. Add tester emails
3. Wait for testers to accept invitations (they get an email)
4. Re-run `.\distribute.bat`
