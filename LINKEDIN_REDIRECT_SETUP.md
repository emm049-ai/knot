# LinkedIn Redirect URL Setup

## The Problem

LinkedIn requires **HTTP or HTTPS** redirect URLs, not custom URL schemes like `knot://linkedin-callback`.

## The Solution

We'll use a two-step process:
1. LinkedIn redirects to your backend (HTTP/HTTPS URL)
2. Backend redirects to your app (using deep link)

## Setup Options

### Option 1: Use Your Backend Server (Recommended)

If you have a backend server running:

1. **Set redirect URL in LinkedIn:**
   ```
   https://yourdomain.com/linkedin-callback
   ```
   Or for development:
   ```
   http://localhost:8080/linkedin-callback
   ```

2. **Backend endpoint is already set up:**
   - The backend has a `/linkedin-callback` endpoint
   - It receives the OAuth code and redirects to `knot://linkedin-callback`
   - Your app handles the deep link

3. **Update .env:**
   ```
   LINKEDIN_REDIRECT_URI=https://yourdomain.com/linkedin-callback
   ```

### Option 2: Use ngrok for Development

For local development without a public server:

1. **Install ngrok:**
   ```bash
   # Download from https://ngrok.com/
   # Or: npm install -g ngrok
   ```

2. **Start your backend:**
   ```bash
   cd backend
   uvicorn main:app --port 8080
   ```

3. **Start ngrok:**
   ```bash
   ngrok http 8080
   ```

4. **Copy the HTTPS URL** (e.g., `https://abc123.ngrok.io`)

5. **Set redirect URL in LinkedIn:**
   ```
   https://abc123.ngrok.io/linkedin-callback
   ```

6. **Update .env:**
   ```
   LINKEDIN_REDIRECT_URI=https://abc123.ngrok.io/linkedin-callback
   ```

### Option 3: Use a Simple Redirect Service

You can use services like:
- **Netlify** (free tier)
- **Vercel** (free tier)
- **GitHub Pages** (free)

Create a simple HTML page that redirects:
```html
<!DOCTYPE html>
<html>
<head>
    <script>
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');
        const state = urlParams.get('state');
        const error = urlParams.get('error');
        
        if (error) {
            window.location.href = `knot://linkedin-callback?error=${error}`;
        } else if (code) {
            window.location.href = `knot://linkedin-callback?code=${code}&state=${state || ''}`;
        }
    </script>
</head>
<body>
    Redirecting to app...
</body>
</html>
```

## Deep Link Configuration

Make sure your app can handle the `knot://` deep link:

### Android
Already configured in `AndroidManifest.xml` with:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="knot"/>
</intent-filter>
```

### iOS
Already configured in `Info.plist` with:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>knot</string>
        </array>
    </dict>
</array>
```

## Testing

1. Start your backend server
2. Configure LinkedIn redirect URL (HTTP/HTTPS)
3. Test OAuth flow
4. Verify deep link opens your app with the code

## Production

For production, use:
```
https://yourdomain.com/linkedin-callback
```

Make sure:
- Your domain has SSL (HTTPS)
- Backend endpoint is accessible
- Deep link handling works on both platforms
