# Quick Start Guide

## ✅ You've Completed:
- Created `.env` file with all API keys
- Package name configured

## 🚀 Next Steps

### Step 1: Install Flutter Dependencies

**Option A: If Flutter is in your PATH:**
```bash
cd c:\Users\emann\OneDrive\Desktop\knot
flutter pub get
```

**Option B: If Flutter is not in PATH:**
1. Find your Flutter installation (usually `C:\flutter\bin\flutter.bat` or similar)
2. Run:
```bash
cd c:\Users\emann\OneDrive\Desktop\knot
C:\path\to\flutter\bin\flutter.bat pub get
```

**Option C: Use your IDE:**
- If using VS Code: Open the project, it should auto-detect and prompt to install dependencies
- If using Android Studio: Open the project, click "Pub get" when prompted

### Step 2: Set Up Supabase Database (CRITICAL)

1. **Go to Supabase Dashboard:**
   - URL: https://cznrbjknbvyikgxhyqhg.supabase.co
   - Or go to: https://app.supabase.com and select your project

2. **Open SQL Editor:**
   - Click "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Run the Schema:**
   - Open `database/schema.sql` in your project
   - Copy ALL the contents (all 187 lines)
   - Paste into Supabase SQL Editor
   - Click "Run" (or press Ctrl+Enter)

4. **Verify Success:**
   - You should see "Success. No rows returned"
   - Check the "Table Editor" to see if tables were created:
     - `users`
     - `contacts`
     - `notes`
     - `email_interactions`
     - `calendar_events`

### Step 3: Test the App

```bash
flutter run
```

Or use your IDE's run button.

**Expected behavior:**
- App starts
- Shows login screen (since no user is logged in)
- No errors in console

### Step 4: Create Your First Account

1. On the login screen, click "Don't have an account? Sign Up"
2. Enter:
   - Email: your email
   - Password: (at least 6 characters)
3. Click "Sign Up"
4. Check your email for verification (if enabled in Supabase)
5. Sign in

### Step 5: Test Core Features

Once logged in, try:
- ✅ Click "Add Contact" button
- ✅ Try voice recording (tap mic icon)
- ✅ Try OCR scanning (tap camera icon)
- ✅ Add a contact manually
- ✅ View contacts list
- ✅ See relationship health indicators

## 🔧 Troubleshooting

### "Flutter not found"
- Add Flutter to your PATH, or use the full path to `flutter.bat`
- Or use your IDE (VS Code/Android Studio) which handles this automatically

### "Supabase connection error"
- Double-check `.env` file has correct keys
- Verify Supabase project is active
- Check internet connection

### "Table doesn't exist" error
- Make sure you ran the SQL schema in Supabase
- Check Supabase SQL Editor for any error messages
- Verify RLS policies were created

### "Gemini API error"
- Check `GEMINI_API_KEY` in `.env`
- Verify the key is valid
- Check API quota/limits

## 📝 Optional Setup (Can Do Later)

### Firebase (for Push Notifications)
- See `FIREBASE_SETUP.md`
- App works without it (just no push notifications)

### LinkedIn OAuth
- See `LINKEDIN_QUICK_SETUP.md`
- App works without it (just can't import LinkedIn profiles)

## 🎯 Priority Order

1. **Install dependencies** (`flutter pub get`)
2. **Run Supabase schema** (SQL Editor)
3. **Test app** (`flutter run`)
4. **Create account and test features**
5. **Set up Firebase** (optional)
6. **Set up LinkedIn** (optional)

## 💡 Pro Tip

If you're using VS Code:
1. Install "Flutter" extension
2. Open the project folder
3. VS Code will detect Flutter and prompt to install dependencies
4. Use F5 to run the app

Let me know when you've completed Step 2 (Supabase schema) and we can test the app!
