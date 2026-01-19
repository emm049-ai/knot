# How to Run ngrok for LinkedIn OAuth

## Quick Start

### Step 1: Install ngrok (if not installed)

1. Go to https://ngrok.com/download
2. Download ngrok for Windows
3. Extract the `ngrok.exe` file
4. Add ngrok to your PATH, OR use the full path when running it

### Step 2: Start Your Backend Server

Open a terminal and run:
```bash
cd backend
python -m uvicorn main:app --reload --port 8000
```

Or if you don't have the backend set up yet, you can use a simple HTTP server:
```bash
# Option: Use Python's built-in server (if backend isn't ready)
python -m http.server 8000
```

### Step 3: Start ngrok

Open a **NEW terminal window** and run:

```bash
ngrok http 8000
```

**OR** if ngrok is not in your PATH:
```bash
C:\path\to\ngrok.exe http 8000
```

### Step 4: Get Your ngrok URL

After starting ngrok, you'll see output like:
```
Forwarding   https://abc123xyz.ngrok-free.dev -> http://localhost:8000
```

Copy the **HTTPS URL** (the one starting with `https://`)

### Step 5: Update Your Configuration

1. **Update `.env` file**:
   ```
   LINKEDIN_REDIRECT_URI=https://abc123xyz.ngrok-free.dev/linkedin-callback
   ```
   (Replace `abc123xyz` with your actual ngrok URL)

2. **Update LinkedIn Developer Portal**:
   - Go to https://www.linkedin.com/developers/apps
   - Select your app
   - Go to **Auth** tab
   - Under **Redirect URLs**, add:
     ```
     https://abc123xyz.ngrok-free.dev/linkedin-callback
     ```
   - Click **Update**

### Step 6: Keep ngrok Running

⚠️ **Important**: Keep the ngrok terminal window open while testing LinkedIn OAuth!

If you close ngrok or it stops, you'll need to:
1. Restart ngrok
2. Get the new URL (it might be different)
3. Update both `.env` and LinkedIn Developer Portal with the new URL

## Troubleshooting

### "ngrok is not recognized"
- ngrok is not in your PATH
- Solution: Use the full path to ngrok.exe, or add it to PATH

### "Port 8000 is already in use"
- Another service is using port 8000
- Solution: Use a different port (e.g., 8080) and update ngrok command:
  ```bash
  ngrok http 8080
  ```

### "ngrok endpoint is offline"
- ngrok stopped running
- Solution: Restart ngrok in a terminal window

### ngrok URL keeps changing
- Free ngrok accounts get new URLs each time
- Solution: 
  - Keep ngrok running (don't restart it)
  - Or upgrade to ngrok paid plan for static URLs
  - Or use a static domain for production

## Alternative: Use ngrok Web Interface

When ngrok is running, you can also:
1. Open http://localhost:4040 in your browser
2. See the ngrok dashboard with your URL
3. View request logs and inspect traffic

## For Production

For production, you should:
- Use a real domain (not ngrok)
- Set up proper HTTPS
- Update `LINKEDIN_REDIRECT_URI` to your production domain
