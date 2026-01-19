# Setup Codemagic for iOS Builds (No Mac Needed!)

## Why Codemagic?

- ✅ **Built for Flutter** - Works perfectly with Flutter apps
- ✅ **Free tier** - 500 build minutes/month
- ✅ **No Mac needed** - Builds in the cloud
- ✅ **Firebase integration** - Auto-distributes to testers
- ✅ **Easy setup** - Just connect your repo

## Step 1: Create GitHub Repository

**On Windows (PowerShell):**

```powershell
cd C:\Users\emann\OneDrive\Desktop\knot

# Initialize Git (if not already)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit - Ready for iOS builds"

# Create repo on GitHub.com, then:
git remote add origin https://github.com/YOUR-USERNAME/knot.git
git branch -M main
git push -u origin main
```

**Don't have GitHub account?**
1. Go to: https://github.com/signup
2. Create free account
3. Create new repository named "knot"
4. Follow instructions to push code

## Step 2: Sign Up for Codemagic

1. **Go to:** https://codemagic.io/signup
2. **Sign up** with GitHub (easiest)
3. **Authorize** Codemagic to access your repos

## Step 3: Add Your App

1. **In Codemagic dashboard:**
   - Click "Add application"
   - Select "GitHub" (or your Git provider)
   - Find and select your `knot` repository
   - Click "Add application"

2. **Codemagic will detect:**
   - ✅ Flutter project
   - ✅ iOS configuration
   - ✅ `codemagic.yaml` file (we'll create this)

## Step 4: Configure Build Settings

### Option A: Use the YAML file (Recommended)

The `codemagic.yaml` file is already in your project. You just need to:

1. **Get Firebase Service Account:**
   - Go to: https://console.firebase.google.com/project/knot-29668/settings/serviceaccounts/adminsdk
   - Click "Generate new private key"
   - Download the JSON file
   - **Keep this secure!**

2. **Get iOS App ID:**
   - Go to: https://console.firebase.google.com/project/knot-29668/settings/general
   - Find your iOS app (or add it if not done)
   - Copy the App ID (format: `1:548250171926:ios:xxxxx`)

3. **Add to Codemagic:**
   - In Codemagic → Your App → Environment Variables
   - Click "Add variable"
   - Add:
     - **Name:** `FIREBASE_SERVICE_ACCOUNT`
     - **Value:** Paste the entire JSON content from the service account file
     - **Secure:** ✅ (check this box)
   - Add another:
     - **Name:** `IOS_APP_ID`
     - **Value:** Your iOS App ID (e.g., `1:548250171926:ios:xxxxx`)
     - **Secure:** ✅

### Option B: Use Codemagic UI

1. **In Codemagic → Your App:**
   - Click "Start new build"
   - Select "iOS" platform
   - Configure build settings in UI
   - Add environment variables

## Step 5: Configure iOS Signing

**First time setup:**

1. **In Codemagic → Your App → Code signing:**
   - Click "Add certificate"
   - Follow instructions to upload:
     - Distribution certificate
     - Provisioning profile

2. **Or use automatic signing:**
   - Codemagic can handle this for you
   - You'll need to add your Apple Developer account

**For testing (easier):**
- Use automatic code signing
- Codemagic will guide you through it

## Step 6: Build!

1. **Push your code:**
   ```powershell
   git add codemagic.yaml
   git commit -m "Add Codemagic configuration"
   git push
   ```

2. **In Codemagic:**
   - Click "Start new build"
   - Select your workflow
   - Click "Start new build"

3. **Watch it build:**
   - Build runs in cloud (takes ~10-15 minutes)
   - You'll see live logs
   - When done, automatically uploads to Firebase!

## Step 7: Verify Distribution

1. **Check Firebase Console:**
   - https://console.firebase.google.com/project/knot-29668/appdistribution/releases
   - Should see your iOS build

2. **Testers receive email:**
   - iOS testers get download link
   - They can install via Firebase App Distribution app

## Troubleshooting

### "Firebase service account error"
- Make sure JSON is pasted correctly
- Check it's marked as "Secure" variable
- Verify JSON format is valid

### "iOS App ID not found"
- Make sure iOS app is added in Firebase Console
- Copy the exact App ID
- Check for typos

### "Code signing failed"
- Upload certificates manually
- Or use automatic signing (easier for first time)

### "Build failed"
- Check build logs in Codemagic
- Common issues:
  - Missing dependencies
  - Xcode version issues
  - Flutter version mismatch

## Cost

**Free tier:**
- 500 build minutes/month
- Usually enough for 10-20 builds/month

**Paid plans:**
- Start at $75/month for more minutes
- Only needed if you build very frequently

## Benefits

✅ **No Mac needed** - Build from Windows
✅ **Automatic** - Build on every push (optional)
✅ **Firebase integration** - Auto-distribute
✅ **Free tier** - Great for testing
✅ **Professional** - Used by many Flutter developers

## Next Steps

1. ✅ Create GitHub repo
2. ✅ Sign up for Codemagic
3. ✅ Connect repository
4. ✅ Configure environment variables
5. ✅ Build and distribute!

---

**Need help?** Check Codemagic docs: https://docs.codemagic.io/
