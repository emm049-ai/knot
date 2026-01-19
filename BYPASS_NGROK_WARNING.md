# Bypass ngrok Browser Warning

## Problem
ngrok free tier shows a warning page that blocks the OAuth redirect flow.

## Solution Applied

1. **Restarted ngrok with `--host-header=rewrite` flag**
   - This helps with some redirect issues
   - Command: `ngrok http 8000 --host-header=rewrite`

2. **Added ngrok skip header to backend**
   - Backend now sends `ngrok-skip-browser-warning: true` header
   - This tells ngrok to skip the warning page

## Alternative Solutions

### Option 1: Click "Visit Site" Button
- On the ngrok warning page, click the blue "Visit Site" button
- This should proceed to the backend

### Option 2: Use ngrok Config File
Create `ngrok.yml` in your home directory:
```yaml
version: "2"
authtoken: YOUR_NGROK_AUTH_TOKEN
tunnels:
  knot:
    proto: http
    addr: 8000
    inspect: true
    bind_tls: true
    request_header:
      add:
        - "ngrok-skip-browser-warning: true"
```

Then run: `ngrok start knot`

### Option 3: Upgrade ngrok (Paid)
- Paid ngrok accounts don't show the warning page
- Free tier always shows it once per session

## Current Setup

- ✅ ngrok restarted with `--host-header=rewrite`
- ✅ Backend configured to send skip header
- ⚠️ You may still see the warning once, but clicking "Visit Site" should work

## Test Again

1. Try the LinkedIn OAuth flow again
2. If you see the warning page, click "Visit Site"
3. Should proceed to the redirect page
4. Then redirect to your Flutter app

## If Still Stuck

The warning page should only appear once. After clicking "Visit Site", subsequent requests should bypass it. If it keeps appearing, the backend restart might be needed.
