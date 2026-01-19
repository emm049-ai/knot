# How to Start the Backend Server on Port 8000

## Quick Start

### Option 1: Using Python directly (Recommended)

1. Open a **new terminal window**
2. Navigate to the backend directory:
   ```bash
   cd C:\Users\emann\OneDrive\Desktop\knot\backend
   ```
3. Start the server:
   ```bash
   python -m uvicorn main:app --host 0.0.0.0 --port 8000
   ```

You should see output like:
```
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

### Option 2: Using the main.py file directly

```bash
cd C:\Users\emann\OneDrive\Desktop\knot\backend
python main.py
```

## Verify It's Running

Open a browser and go to: http://localhost:8000

You should see:
```json
{"message": "Knot API", "version": "1.0.0"}
```

## Test the LinkedIn Callback Endpoint

Go to: http://localhost:8000/linkedin-callback

You should see a response (even if it's an error about missing parameters, that's fine - it means the server is running).

## Keep It Running

⚠️ **Important**: Keep this terminal window open while testing LinkedIn OAuth!

The server needs to be running for ngrok to forward requests to it.

## Troubleshooting

### "Port 8000 is already in use"
- Another service is using port 8000
- Solution: Kill the process using port 8000, or use a different port:
  ```bash
  python -m uvicorn main:app --host 0.0.0.0 --port 8080
  ```
  Then update ngrok: `ngrok http 8080`

### "Module not found: uvicorn"
- Dependencies not installed
- Solution:
  ```bash
  cd backend
  pip install fastapi uvicorn python-dotenv
  ```

### "Cannot connect to localhost:8000"
- Server not started
- Solution: Make sure you ran the uvicorn command and see the "Uvicorn running" message

## What Should Be Running

For LinkedIn OAuth to work, you need **TWO** things running:

1. ✅ **ngrok** (already running)
   - Command: `ngrok http 8000`
   - URL: `https://hypabyssal-lissette-curvedly.ngrok-free.dev`

2. ⚠️ **Backend Server** (you need to start this)
   - Command: `python -m uvicorn main:app --host 0.0.0.0 --port 8000`
   - URL: `http://localhost:8000`

## Quick Test

Once both are running:
1. Open: http://localhost:8000 (should show API message)
2. Open: https://hypabyssal-lissette-curvedly.ngrok-free.dev (should also show API message)
3. Try LinkedIn OAuth again - it should work!
