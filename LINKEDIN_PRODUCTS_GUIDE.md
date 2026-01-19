# LinkedIn API Products - What You Need

## ✅ Required Product (Request This First)

### Sign In with LinkedIn using OpenID Connect
- **Tier**: Standard Tier
- **Company Required**: ❌ No (usually available to individual developers)
- **What it does**: 
  - Enables OAuth authentication
  - Provides basic profile data (name, email, profile picture)
  - Allows users to connect their LinkedIn account
- **Use case**: "I'm building a networking app for students. Users need to authenticate with LinkedIn to import their own profile and connect with their network."
- **Status**: ✅ Request this one - it's sufficient for the core app functionality

## ⏭️ Optional Products (Skip for Now)

### Member Data Portability API (3rd Party)
- **Tier**: Default Tier
- **Company Required**: ✅ Yes (requires legal company name)
- **What it does**: Allows bulk import of LinkedIn contacts
- **Why skip**: 
  - Requires a registered company with legal name
  - Not essential - users can manually import contacts
  - You can request this later when you have a company
- **Alternative**: Users can use the OAuth flow to import their own profile, then manually add contacts

## 🎯 What This Means for Your App

### With Just "Sign In with LinkedIn using OpenID Connect":
✅ Users can:
- Connect their LinkedIn account via OAuth
- Import their own profile information
- The app will extract basic info from LinkedIn URLs (using AI fallback)

❌ Users cannot:
- Bulk import all LinkedIn contacts automatically
- Access other users' full profiles without OAuth

### Workaround for Contact Import:
1. **OAuth Import**: Users connect LinkedIn → import their own profile
2. **URL Import**: Users paste LinkedIn URLs → AI extracts basic info
3. **Manual Entry**: Users fill in details manually (always available)
4. **Phone Contacts**: Import from device contacts (already implemented)
5. **Business Cards**: OCR scan (already implemented)
6. **Written Notes**: OCR scan (already implemented)

## 📝 Request Process

1. Go to your LinkedIn app → **Products** tab
2. Find **"Sign In with LinkedIn using OpenID Connect"**
3. Click **"Request access"**
4. Fill out the form:
   - **Use case**: "Building a networking app for university students and job seekers. Users authenticate with LinkedIn to import their profile and network information."
   - **Description**: "Knot is a mobile app that helps students and job seekers manage their professional network. Users need to connect their LinkedIn account to import their profile and facilitate networking."
5. Submit and wait for approval (usually 1-7 days)

## ⚠️ Important Notes

- **You don't need a company** for "Sign In with LinkedIn using OpenID Connect"
- **Member Data Portability API** can be requested later when you have a registered company
- The app works perfectly fine without bulk contact import
- Users can still import contacts through other methods (phone, business cards, manual entry)

## 🚀 Next Steps

1. ✅ Request "Sign In with LinkedIn using OpenID Connect"
2. ⏸️ Skip "Member Data Portability API" for now
3. Wait for approval
4. Once approved, test the OAuth flow
5. Consider requesting additional APIs later if needed (when you have a company)
