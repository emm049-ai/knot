# LinkedIn API Setup Guide

## Official LinkedIn API Integration

To use LinkedIn's official APIs, you need to:

### 1. Create a LinkedIn App

1. Go to [LinkedIn Developers](https://www.linkedin.com/developers/)
2. Click "Create app"
3. Fill in:
   - **App name**: Knot
   - **LinkedIn Page**: (optional, can create one)
   - **Privacy Policy URL**: Your privacy policy URL
   - **App logo**: Upload Knot logo
   - **App usage**: Select appropriate category

### 2. Configure OAuth Settings

1. In your app settings → **Auth** tab
2. Add **Redirect URLs** (LinkedIn requires HTTP/HTTPS URLs):
   - For development: `http://localhost:8080/linkedin-callback` or use ngrok: `https://your-ngrok-url.ngrok.io/linkedin-callback`
   - For production: `https://yourdomain.com/linkedin-callback`
   - **Important**: LinkedIn does NOT accept custom URL schemes like `knot://`
3. Note your:
   - **Client ID**
   - **Client Secret**

### 3. Request API Products

LinkedIn requires you to request access to specific API products:

1. Go to **Products** tab in your LinkedIn app
2. **Required**: Request access to:
   - **Sign In with LinkedIn using OpenID Connect** (Standard Tier)
     - This is the ESSENTIAL product you need
     - Usually doesn't require a registered company
     - Provides basic profile info (name, email, profile picture)
     - Enables OAuth authentication

3. **Optional** (can skip if you don't have a registered company):
   - **Member Data Portability API** - Requires legal company name (skip for now)
   - **Marketing Developer Platform** - Usually requires business verification
   - **Profile API** - May require partnership

**Note**: 
- **For individual developers/students**: Start with just "Sign In with LinkedIn using OpenID Connect"
- This is sufficient for the core functionality (importing contacts via OAuth)
- You can always request additional APIs later when you have a company
- LinkedIn's API access approval can take a few days to weeks

### 4. Add to .env File

```
LINKEDIN_CLIENT_ID=your_client_id_here
LINKEDIN_CLIENT_SECRET=your_client_secret_here
LINKEDIN_REDIRECT_URI=https://yourdomain.com/linkedin-callback
```

**Note**: The redirect URI must be HTTP or HTTPS. For development, you can:
- Use `http://localhost:8080/linkedin-callback` (if testing on web)
- Use ngrok to create a public HTTPS URL: `https://your-ngrok-url.ngrok.io/linkedin-callback`
- Set up a simple backend endpoint that handles the callback

### 5. Scopes Needed

The app requests these scopes:
- `openid` - Basic authentication
- `profile` - Profile information
- `email` - Email address
- `w_member_social` - Read member profile data

### 6. Limitations

**Important**: LinkedIn's official API has limitations:
- You can only access profiles of users who have authorized your app
- You cannot scrape or access arbitrary profiles
- Profile data access requires the user to be in your network or have granted explicit permission
- Some features require LinkedIn partnership

### 7. Alternative Approach

Since LinkedIn API access is restricted, the app includes a fallback:
- If OAuth is not configured or fails, it extracts basic info from the LinkedIn URL
- Users can manually add contact details
- The LinkedIn URL is stored for reference

### 8. Testing

1. Test OAuth flow in development
2. Ensure redirect URI matches exactly
3. Test with different LinkedIn profiles
4. Handle cases where API access is denied

## Current Implementation

The app handles three scenarios:
1. **Full OAuth**: If configured, attempts to get profile via API
2. **Basic extraction**: Extracts name from URL if API fails
3. **Manual entry**: User can fill in details manually
