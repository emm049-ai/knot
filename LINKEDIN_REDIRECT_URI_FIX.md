# LinkedIn Redirect URI Fix

## Problem Identified

The ngrok inspector shows:
```
GET /linkedin-callback HTTP/1.1
```

**No query parameters!** LinkedIn is NOT sending the `code` parameter, which means:
- ❌ Redirect URI mismatch (most likely)
- ❌ LinkedIn rejected the authorization
- ❌ Parameters lost in redirect

## Critical Check: Redirect URI Must Match EXACTLY

LinkedIn is VERY strict about redirect URIs. They must match EXACTLY:

### Step 1: Check Your .env File

Open `.env` and verify:
```
LINKEDIN_REDIRECT_URI=https://hypabyssal-lissette-curvedly.ngrok-free.dev/linkedin-callback
```

**Must be:**
- ✅ HTTPS (not HTTP)
- ✅ Exact domain: `hypabyssal-lissette-curvedly.ngrok-free.dev`
- ✅ Exact path: `/linkedin-callback`
- ✅ No trailing slash
- ✅ No extra parameters

### Step 2: Check LinkedIn Developer Portal

1. Go to: https://www.linkedin.com/developers/apps
2. Select your app (Client ID: `780eyzjkdsv5q9`)
3. Go to **Auth** tab
4. Under **Redirect URLs**, check the list

**The URL must be EXACTLY:**
```
https://hypabyssal-lissette-curvedly.ngrok-free.dev/linkedin-callback
```

**Common mistakes:**
- ❌ `http://` instead of `https://`
- ❌ Trailing slash: `/linkedin-callback/`
- ❌ Different domain
- ❌ Missing `/linkedin-callback` path
- ❌ Extra spaces or characters

### Step 3: Verify What the App is Sending

When you click "Connect LinkedIn Account", the app constructs an OAuth URL. Check:

1. Open browser DevTools (F12)
2. Go to Network tab
3. Click "Connect LinkedIn Account" in the app
4. Look for the request to `linkedin.com/oauth/v2/authorization`
5. Check the `redirect_uri` parameter in that URL

It should be:
```
redirect_uri=https%3A%2F%2Fhypabyssal-lissette-curvedly.ngrok-free.dev%2Flinkedin-callback
```
(URL encoded version of the redirect URI)

### Step 4: Test the Match

The redirect URI in:
- ✅ `.env` file
- ✅ LinkedIn Developer Portal
- ✅ OAuth request URL

**ALL THREE must match EXACTLY!**

## Quick Fix

1. **Copy this EXACT string:**
   ```
   https://hypabyssal-lissette-curvedly.ngrok-free.dev/linkedin-callback
   ```

2. **Paste it into:**
   - Your `.env` file: `LINKEDIN_REDIRECT_URI=...`
   - LinkedIn Developer Portal → Auth → Redirect URLs
   - Make sure there are NO differences

3. **Restart Flutter app** (to reload .env)

4. **Try OAuth again**

## If Still Not Working

Check the OAuth authorization URL that the app generates. It should include:
```
redirect_uri=https%3A%2F%2Fhypabyssal-lissette-curvedly.ngrok-free.dev%2Flinkedin-callback
```

If it's different, that's the problem!
