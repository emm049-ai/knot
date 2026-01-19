# Check ngrok Request Details

## What to Check in ngrok Inspector

In the ngrok inspector (http://127.0.0.1:4040), for the `/linkedin-callback` request:

1. **Click on the request** (the one showing 400 Bad Request)

2. **Check the "Raw" tab** - This shows the exact HTTP request LinkedIn sent
   - Look for the full URL including query parameters
   - Should look like: `GET /linkedin-callback?code=...&state=... HTTP/1.1`

3. **Check the "Summary" tab** - Shows the request URL
   - Should show the full path with query string

4. **Check "Headers" tab** - Look for:
   - `Referer` header (might show where the request came from)
   - Any LinkedIn-specific headers

## What We're Looking For

If LinkedIn sent the code, you should see in the Raw request:
```
GET /linkedin-callback?code=AQSPQZHzVYoq8fmMadqIVAMUJkEewMuyRmxqji...&state=... HTTP/1.1
```

If you DON'T see `?code=...` in the request, then:
- LinkedIn didn't send it (redirect URI mismatch or other error)
- Or LinkedIn sent an error instead

## Next Steps

1. Check the "Raw" tab in ngrok inspector
2. Tell me what the full request URL looks like
3. If there's no `code` parameter, we need to check LinkedIn app settings
