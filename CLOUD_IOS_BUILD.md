# Cloud iOS Build for Flutter (Windows → Cloud → iOS)

Since Expo is for React Native (not Flutter), here are the best cloud-based solutions for building Flutter iOS apps from Windows:

## Option 1: Codemagic (Recommended) ⭐⭐⭐

**Best for:** Flutter apps, free tier available, easy setup

### Setup Steps:

1. **Sign up:**
   - Go to: https://codemagic.io/
   - Sign up with GitHub/GitLab/Bitbucket (free)

2. **Connect your repository:**
   - If you don't have Git yet, create a GitHub repo first
   - Connect Codemagic to your repo

3. **Configure build:**
   - Codemagic auto-detects Flutter projects
   - Select iOS platform
   - Configure signing (they guide you through it)

4. **Build and distribute:**
   - Click "Start new build"
   - Codemagic builds in the cloud
   - Automatically uploads to Firebase App Distribution!

**Cost:** Free tier: 500 build minutes/month

**Pros:**
- ✅ Built specifically for Flutter
- ✅ Free tier available
- ✅ Automatic Firebase App Distribution integration
- ✅ No Mac needed
- ✅ Easy setup

**Cons:**
- ❌ Requires Git repository
- ❌ Free tier has limits

---

## Option 2: GitHub Actions + Self-Hosted Runner

**Best for:** If you have a Mac you can leave running

### Setup:

1. **Create GitHub repository** (if you don't have one)
2. **Set up GitHub Actions workflow**
3. **Use a self-hosted Mac runner** (your MacBook)
4. **Build automatically on push**

**Cost:** Free (if using your own Mac)

**Pros:**
- ✅ Free
- ✅ Full control
- ✅ Can automate everything

**Cons:**
- ❌ Mac needs to be running
- ❌ More complex setup

---

## Option 3: AppCircle (Alternative)

**Best for:** Alternative to Codemagic

1. Sign up at: https://appcircle.com/
2. Connect repository
3. Configure Flutter iOS build
4. Build in cloud

**Cost:** Free tier available

---

## Option 4: Bitrise

**Best for:** Professional CI/CD

1. Sign up at: https://www.bitrise.io/
2. Connect repository
3. Use Flutter workflow
4. Build iOS in cloud

**Cost:** Free tier: 200 builds/month

---

## Recommended: Codemagic + Firebase Integration

Here's the complete setup:

### Step 1: Create Git Repository

**On Windows:**
```powershell
cd C:\Users\emann\OneDrive\Desktop\knot

# Initialize Git
git init
git add .
git commit -m "Initial commit"

# Create GitHub repo, then:
git remote add origin https://github.com/YOUR-USERNAME/knot.git
git push -u origin main
```

### Step 2: Set Up Codemagic

1. **Go to:** https://codemagic.io/signup
2. **Sign up** with GitHub
3. **Add app** → Select your `knot` repository
4. **Configure workflow:**

Create `codemagic.yaml` in your project root:

```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    max_build_duration: 120
    instance_type: mac_mini_m1
    environment:
      flutter: stable
      xcode: latest
      cocoapods: default
    scripts:
      - name: Get dependencies
        script: |
          flutter pub get
      - name: Build iOS
        script: |
          flutter build ipa --release
    artifacts:
      - build/ios/ipa/*.ipa
    publishing:
      email:
        recipients:
          - your-email@example.com
      firebase:
        firebase_service_account: $FIREBASE_SERVICE_ACCOUNT
        ios:
          app_id: $IOS_APP_ID
          groups:
            - beta-testers
```

### Step 3: Configure Firebase

1. **Get Firebase Service Account:**
   - Firebase Console → Project Settings → Service Accounts
   - Generate new private key
   - Download JSON file

2. **Add to Codemagic:**
   - Codemagic → Your App → Environment Variables
   - Add `FIREBASE_SERVICE_ACCOUNT` (paste JSON content)
   - Add `IOS_APP_ID` (your iOS app ID from Firebase)

### Step 4: Build!

1. **Push code to GitHub:**
   ```powershell
   git add .
   git commit -m "Add Codemagic config"
   git push
   ```

2. **In Codemagic:**
   - Click "Start new build"
   - Select iOS workflow
   - Build runs in cloud
   - Automatically distributes to Firebase!

---

## Quick Comparison

| Service | Free Tier | Flutter Support | Firebase Integration | Ease of Setup |
|---------|-----------|-----------------|----------------------|---------------|
| **Codemagic** | 500 min/month | ✅ Excellent | ✅ Built-in | ⭐⭐⭐⭐⭐ |
| **AppCircle** | Limited | ✅ Good | ⚠️ Manual | ⭐⭐⭐⭐ |
| **Bitrise** | 200 builds/month | ✅ Good | ⚠️ Manual | ⭐⭐⭐ |
| **GitHub Actions** | Unlimited (public) | ✅ Good | ⚠️ Manual | ⭐⭐⭐ |

---

## My Recommendation

**Use Codemagic** because:
1. ✅ Built specifically for Flutter
2. ✅ Free tier is generous
3. ✅ Direct Firebase App Distribution integration
4. ✅ No Mac needed
5. ✅ Easy setup

**Steps:**
1. Create GitHub repo (if you don't have one)
2. Push your code
3. Sign up for Codemagic
4. Connect repo
5. Configure build
6. Build and distribute!

---

## Alternative: Keep Using Your Mac

If you already have the Mac set up, you can:
- Build manually when needed
- Or set up GitHub Actions with your Mac as a runner
- Or use the scripts we created earlier

---

## Next Steps

1. **Choose:** Codemagic (easiest) or Mac setup (we already prepared)
2. **If Codemagic:** Follow the setup steps above
3. **If Mac:** Follow `QUICK_START_MAC.md`

Would you like me to help you set up Codemagic, or stick with the Mac approach?
