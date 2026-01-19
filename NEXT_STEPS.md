# Next Steps - Getting Your App Running

## ✅ Completed
- [x] Created `.env` file with all API keys
- [x] Package name configured: `com.emanneul.knot`
- [x] All dependencies configured

## 🔄 Current Step: Install Dependencies

Running `flutter pub get` to install all packages...

## 📋 Remaining Setup Steps

### 1. Set Up Supabase Database (REQUIRED)

1. Go to your Supabase Dashboard: https://cznrbjknbvyikgxhyqhg.supabase.co
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the entire contents of `database/schema.sql`
5. Paste into the SQL editor
6. Click **Run** (or press Ctrl+Enter)
7. Verify all tables were created successfully

**What this does:**
- Creates all database tables (users, contacts, notes, etc.)
- Sets up Row Level Security (RLS) policies
- Creates indexes for performance
- Sets up triggers for automatic relationship health calculation

### 2. Test the App

Once dependencies are installed and database is set up:

```bash
flutter run
```

This will:
- Start the app
- Test all API connections
- Show login screen (since no user is logged in)

### 3. Create Your First Account

1. Run the app
2. You'll see the login screen
3. Click "Don't have an account? Sign Up"
4. Enter your email and password
5. Check your email for verification (if email confirmation is enabled in Supabase)
6. Sign in

### 4. Optional: Set Up Firebase (for Push Notifications)

If you want push notifications:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Add Android app with package: `com.emanneul.knot`
3. Download `google-services.json` → place in `android/app/`
4. Add iOS app with bundle ID: `com.emanneul.knot`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### 5. Optional: Set Up LinkedIn Redirect URI

For LinkedIn integration to work:

1. Choose a redirect URL:
   - **Development**: Use ngrok (see `LINKEDIN_QUICK_SETUP.md`)
   - **Production**: Use your domain
2. Update `.env`:
   ```
   LINKEDIN_REDIRECT_URI=https://your-actual-url.com/linkedin-callback
   ```
3. Add the URL to LinkedIn Developer Console → Auth → Redirect URLs

## 🐛 Troubleshooting

### "Supabase connection failed"
- Check your `.env` file has correct `SUPABASE_URL` and `SUPABASE_ANON_KEY`
- Verify Supabase project is active

### "Database table not found"
- Make sure you ran the SQL schema in Supabase
- Check Supabase SQL Editor for any errors

### "Gemini API error"
- Verify `GEMINI_API_KEY` in `.env`
- Check API key is valid and has quota

### "Firebase initialization skipped"
- This is normal if Firebase config files aren't added yet
- App will work without Firebase (just no push notifications)

## 🎉 Once Everything Works

You should be able to:
- ✅ Sign up / Sign in
- ✅ Add contacts (voice, OCR, or manual)
- ✅ View contacts with relationship health
- ✅ Generate follow-up emails
- ✅ See gamification (plant growth, streaks)

Let me know if you encounter any errors!
