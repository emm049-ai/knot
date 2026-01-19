# Restart Everything - Step by Step

## Step 1: Start ngrok

Open **Terminal 1** and run:
```bash
ngrok http 8000
```

**Keep this terminal open!** You should see:
```
Forwarding   https://hypabyssal-lissette-curvedly.ngrok-free.dev -> http://localhost:8000
```

Copy the HTTPS URL (it might be different from before).

## Step 2: Start Backend Server

Open **Terminal 2** (new terminal) and run:
```bash
cd C:\Users\emann\OneDrive\Desktop\knot\backend
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

**Keep this terminal open!** You should see:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
```

## Step 3: Update .env with New ngrok URL (if changed)

If ngrok gave you a NEW URL (different from `hypabyssal-lissette-curvedly.ngrok-free.dev`):

1. Open `.env` file
2. Update:
   ```
   LINKEDIN_REDIRECT_URI=https://YOUR-NEW-NGROK-URL.ngrok-free.dev/linkedin-callback
   ```
3. Update LinkedIn Developer Portal:
   - Go to https://www.linkedin.com/developers/apps
   - Select your app → Auth tab
   - Update Redirect URL to: `https://YOUR-NEW-NGROK-URL.ngrok-free.dev/linkedin-callback`
   - Click Update

## Step 4: Start Flutter App

Open **Terminal 3** (new terminal) and run:
```bash
cd C:\Users\emann\OneDrive\Desktop\knot
C:\flutter\flutter\bin\flutter.bat run -d chrome
```

## Step 5: Test

1. In the Flutter app, go to: Import Contacts → LinkedIn
2. Click "Connect LinkedIn Account"
3. Click "Allow" on LinkedIn page
4. Should redirect back to app automatically

## Quick Check Commands

**Check if ngrok is running:**
```bash
curl http://127.0.0.1:4040/api/tunnels
```

**Check if backend is running:**
Open browser: http://localhost:8000
Should see: `{"message": "Knot API", "version": "1.0.0"}`

**Check if backend callback works:**
Open browser: http://localhost:8000/linkedin-callback?code=test
Should redirect

## Troubleshooting

**"Port 8000 already in use":**
- Kill the process: `netstat -ano | findstr :8000` then `taskkill /PID <PID> /F`
- Or use different port and update ngrok

**"ngrok endpoint offline":**
- Make sure ngrok is running in Terminal 1
- Check the URL matches in .env and LinkedIn portal

**"Backend not responding":**
- Make sure backend is running in Terminal 2
- Check for errors in the terminal
