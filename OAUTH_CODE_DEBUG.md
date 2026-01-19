# OAuth Code Not Received - Debugging

## Problem
Backend is receiving the callback but the `code` parameter is missing from the URL.

## Possible Causes

1. **LinkedIn redirected with an error instead of code**
   - Check if there's an `error` parameter in the URL
   - LinkedIn might have denied the authorization

2. **URL parameters being stripped**
   - ngrok or browser might be removing query parameters
   - Check the full URL in the address bar

3. **LinkedIn OAuth configuration issue**
   - Redirect URI mismatch
   - Missing scopes
   - App not approved

## What I Added

1. **Better error page** - Shows all query parameters for debugging
2. **Logging** - Backend now logs all received parameters
3. **Debug info** - Error page shows full URL and all parameters

## Next Steps

1. **Check the error page** - It will show:
   - All query parameters received
   - Full URL
   - Error/state parameters if present

2. **Check backend logs** - Look at the terminal where backend is running
   - Should show: "LinkedIn callback received. Query params: ..."

3. **Check the actual URL** - Look at browser address bar when you see the error
   - Should have `?code=...` or `?error=...`

## Common Issues

### If you see `error` parameter:
- LinkedIn denied the authorization
- Check LinkedIn app settings
- Make sure redirect URI matches exactly

### If no parameters at all:
- URL might be getting stripped
- Try accessing the callback URL directly with a test code
- Check ngrok configuration

### If code is there but backend doesn't see it:
- Check backend logs
- Verify the request is reaching the backend
- Check for URL encoding issues

## Test the Callback

Try accessing this URL directly (replace YOUR_CODE with actual code):
```
http://localhost:8000/linkedin-callback?code=YOUR_CODE&state=test
```

Should redirect to Flutter app with the code.

## Check Backend Logs

The backend terminal should show:
```
INFO: LinkedIn callback received. Query params: {'code': '...', 'state': '...'}
INFO: Code: ..., State: ..., Error: None, Is Web: True
```

If you don't see the code in the logs, LinkedIn isn't sending it.
