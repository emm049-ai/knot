# LinkedIn API Setup - Complete Guide

## Your ngrok URL
**Your ngrok URL is:** `https://hypabyssal-lissette-curvedly.ngrok-free.dev`

## Step 1: Update LinkedIn Developer Portal

1. Go to: https://www.linkedin.com/developers/apps
2. Select your app (Client ID: `780eyzjkdsv5q9`)
3. Go to **"Auth"** tab
4. Under **"Redirect URLs"**, add this EXACT URL:
   ```
   https://hypabyssal-lissette-curvedly.ngrok-free.dev/linkedin-callback
   ```
5. Click **"Update"**

## Step 2: Update Your .env File

Open your `.env` file and update the redirect URI:

```env
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
GEMINI_API_KEY=your_gemini_api_key_here
LINKEDIN_CLIENT_ID=your_linkedin_client_id_here
LINKEDIN_CLIENT_SECRET=your_linkedin_client_secret_here
LINKEDIN_REDIRECT_URI=your_redirect_uri_here
```

## Step 3: Set Up Backend Endpoint (if not already done)

Your backend needs to handle the callback at `/linkedin-callback`. Make sure your FastAPI backend is running and accessible via ngrok.

## Step 4: Required LinkedIn Scopes

Make sure your LinkedIn app has these scopes enabled:
- `openid`
- `profile` 
- `email`
- `w_member_social` (for reading profile data)

## Step 5: Test

1. Restart your Flutter app after updating `.env`
2. Try the LinkedIn import again
3. The redirect URI should now match!

## Important Notes

⚠️ **ngrok URLs change** - If you restart ngrok, you'll get a new URL and need to update both LinkedIn and your `.env` file.

💡 **For production**: Replace ngrok URL with your actual domain when deploying.

## Troubleshooting

- **"redirect_uri does not match"**: Make sure the URL in LinkedIn portal matches EXACTLY (including https:// and /linkedin-callback)
- **URL import not auto-filling**: The URL import uses basic extraction. For full profile data, use OAuth instead.
- **OAuth not working**: Make sure your backend is running and accessible via ngrok
