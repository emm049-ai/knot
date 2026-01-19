# LinkedIn Quick Setup Guide

## Current Configuration

- **Client ID**: `780eyzjkdsv5q9` ✅
- **Client Secret**: Added to `.env` ✅
- **Redirect URI**: `https://yourdomain.com/linkedin-callback` ⚠️ **Needs Update**

## Step 1: Choose Your Redirect URL

### For Development (Easiest - Use ngrok):

1. **Install ngrok**:
   - Download from https://ngrok.com/
   - Or: `npm install -g ngrok`

2. **Start your backend**:
   ```bash
   cd backend
   uvicorn main:app --port 8080
   ```

3. **Start ngrok** (in new terminal):
   ```bash
   ngrok http 8080
   ```

4. **Copy the HTTPS URL** (looks like: `https://abc123.ngrok.io`)

5. **Update `.env`**:
   ```
   LINKEDIN_REDIRECT_URI=https://abc123.ngrok.io/linkedin-callback
   ```

### For Production:

Use your actual domain:
```
LINKEDIN_REDIRECT_URI=https://yourdomain.com/linkedin-callback
```

## Step 2: Add Redirect URL to LinkedIn

1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Select your app (Client ID: `780eyzjkdsv5q9`)
3. Go to **Auth** tab
4. Under **Redirect URLs**, click **Add redirect URL**
5. Add your redirect URL:
   - Development: `https://your-ngrok-url.ngrok.io/linkedin-callback`
   - Production: `https://yourdomain.com/linkedin-callback`
6. Click **Update**

## Step 3: Verify

The redirect flow works like this:
1. User clicks "Connect LinkedIn" in app
2. LinkedIn redirects to: `https://yourdomain.com/linkedin-callback?code=...`
3. Your backend (`/linkedin-callback` endpoint) receives it
4. Backend redirects to: `knot://linkedin-callback?code=...`
5. App opens and handles the OAuth code

## Testing

1. Make sure backend is running
2. Update `.env` with correct redirect URI
3. Add redirect URI to LinkedIn Developer Console
4. Test OAuth flow in the app

## Troubleshooting

**"Invalid redirect URI" error:**
- Make sure the URL in `.env` exactly matches the one in LinkedIn Developer Console
- URLs are case-sensitive
- Must be HTTPS (or HTTP for localhost)

**"Redirect URI mismatch" error:**
- The redirect URI in the OAuth request must exactly match one in LinkedIn Console
- Check for trailing slashes
- Check for `http://` vs `https://`
