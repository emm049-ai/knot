# Troubleshooting: Testers Not Receiving Emails

If testers haven't received emails after distribution, check these:

## ✅ Checklist

### 1. Verify Distribution Was Successful

Check if the distribution actually completed:
- Look at the terminal output after running `.\distribute.bat`
- Should see: "Distribution successful!" or similar
- If you see errors, the distribution didn't complete

### 2. Check Tester Group Exists

**In Firebase Console:**
1. Go to: https://console.firebase.google.com/project/knot-29668/appdistribution
2. Click **"Testers & Groups"**
3. Verify **"Beta Testers"** group exists
4. If it doesn't exist, create it:
   - Click "Create group"
   - Name: "Beta Testers"
   - Click "Create"

### 3. Verify Testers Are Added to Group

**In Firebase Console:**
1. Go to **"Testers & Groups"**
2. Click on **"Beta Testers"** group
3. Check if tester emails are listed
4. **If empty or missing:**
   - Click "Add testers"
   - Enter email addresses
   - Click "Add"

### 4. Check Tester Invitation Status

**Important:** Testers must accept the invitation FIRST before they can receive distribution emails!

1. In Firebase Console → **"Testers & Groups"**
2. Look at each tester's status:
   - ✅ **"Active"** = They accepted, will receive emails
   - ⏳ **"Pending"** = They haven't accepted yet, won't receive emails
   - ❌ **"Expired"** = Invitation expired, need to resend

**If testers are "Pending":**
- They should have received an **invitation email** (different from distribution email)
- They need to click the link in the invitation email first
- Only after accepting can they receive distribution emails

### 5. Check Distribution History

**In Firebase Console:**
1. Go to: https://console.firebase.google.com/project/knot-29668/appdistribution/releases
2. Check if your build appears in the list
3. Click on a release to see:
   - Who it was sent to
   - Who downloaded it
   - Distribution status

### 6. Verify Group Name Matches

The group name in the script is: **"Beta Testers"** (case-sensitive!)

Make sure:
- Group name in Firebase Console exactly matches: `Beta Testers`
- No extra spaces
- Same capitalization

### 7. Check Spam Folder

- Testers should check their spam/junk folder
- Email subject: "You've been invited to test Knot" or similar
- From: Firebase or Google

### 8. Re-send Distribution

If everything looks correct but emails weren't sent:

1. **Re-run the distribution:**
   ```powershell
   .\distribute.bat
   ```

2. **Or manually distribute:**
   ```powershell
   firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk --app 1:548250171926:android:b11829f2d5aa45e4de5337 --groups "Beta Testers" --release-notes "Re-sending build"
   ```

## Common Issues

### Issue: "Group not found" error
**Solution:**
- Create the group in Firebase Console first
- Make sure name matches exactly (case-sensitive)

### Issue: Testers are "Pending"
**Solution:**
- Testers need to accept the invitation email first
- Resend invitations if needed

### Issue: Distribution command failed silently
**Solution:**
- Check terminal output for errors
- Verify Firebase CLI is installed: `firebase --version`
- Verify you're logged in: `firebase login:list`

### Issue: No releases showing in Firebase Console
**Solution:**
- Distribution didn't complete successfully
- Check terminal for error messages
- Try running the distribution command again

## Quick Fix Steps

1. **Verify group exists and has testers:**
   - Firebase Console → App Distribution → Testers & Groups
   - Create "Beta Testers" if missing
   - Add tester emails if missing

2. **Check tester status:**
   - All should be "Active" (not "Pending")

3. **Re-run distribution:**
   ```powershell
   .\distribute.bat
   ```

4. **Check Firebase Console → Releases:**
   - Should see your build listed
   - Click on it to see who it was sent to

## Still Not Working?

1. **Check Firebase Console directly:**
   - Go to: https://console.firebase.google.com/project/knot-29668/appdistribution
   - Manually create a release and assign to testers
   - This will help identify if it's a CLI issue or Firebase issue

2. **Try distributing to individual emails instead of group:**
   ```powershell
   firebase appdistribution:distribute build\app\outputs\flutter-apk\app-debug.apk --app 1:548250171926:android:b11829f2d5aa45e4de5337 --testers "tester1@email.com,tester2@email.com" --release-notes "Test build"
   ```

3. **Check Firebase project permissions:**
   - Make sure your Google account has proper permissions
   - You need "Editor" or "Owner" role
