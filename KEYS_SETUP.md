# Setting Up Your API Keys

## From Your Keys.docx File

Please extract the following keys from your `Keys.docx` file and add them to a `.env` file in the root directory:

### Required Keys

1. **Supabase Keys**
   ```
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

2. **Gemini API Key**
   ```
   GEMINI_API_KEY=your_gemini_api_key_here
   ```

### Optional Keys (for later setup)

3. **LinkedIn OAuth** (if setting up LinkedIn integration)
   ```
   LINKEDIN_CLIENT_ID=your_linkedin_client_id
   LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret
   LINKEDIN_REDIRECT_URI=https://yourdomain.com/linkedin-callback
   ```
   **Note**: LinkedIn requires HTTP/HTTPS URLs. See `LINKEDIN_REDIRECT_SETUP.md` for setup options.

4. **Firebase** (if setting up push notifications)
   - You'll need to download `google-services.json` and `GoogleService-Info.plist` from Firebase Console
   - See `FIREBASE_SETUP.md` for details

## Creating the .env File

1. Create a file named `.env` in the root directory (same level as `pubspec.yaml`)
2. Copy the keys from your `Keys.docx` file
3. Format should be:
   ```
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
   GEMINI_API_KEY=AIzaSy...
   ```

## Important Notes

- **Never commit the `.env` file to git** (it's already in `.gitignore`)
- Keep your keys secure and private
- The `.env` file is loaded automatically when the app starts

## Testing Your Keys

After setting up the `.env` file, you can test by running:
```bash
flutter run
```

If keys are missing or invalid, you'll see error messages in the console.
