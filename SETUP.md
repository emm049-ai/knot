# Knot App - Setup Guide

## Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Supabase account
- OpenAI API key
- Firebase account (for push notifications)

## Initial Setup

### 1. Clone and Install Dependencies

```bash
flutter pub get
```

### 2. Configure Environment Variables

Create a `.env` file in the root directory:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
OPENAI_API_KEY=your_openai_api_key
```

### 3. Set Up Supabase Database

1. Create a new Supabase project
2. Run the SQL schema from `database/schema.sql` in the Supabase SQL editor
3. Configure Row Level Security (RLS) policies as defined in the schema

### 4. Configure Firebase (Optional - for push notifications)

1. Create a Firebase project
2. Add Android and iOS apps to your Firebase project
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place them in:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

### 5. Set Up Email Service (for BCC feature)

Choose either SendGrid or Mailgun:

#### SendGrid Setup:
1. Create SendGrid account
2. Set up Inbound Parse webhook
3. Point webhook to your backend: `https://your-backend.com/webhook/email`
4. Configure domain: `inbound.careercaddie.com` (or your custom domain)

#### Mailgun Setup:
1. Create Mailgun account
2. Set up Routes to forward emails to your backend
3. Configure domain: `inbound.careercaddie.com` (or your custom domain)

### 6. Backend Setup

1. Navigate to `backend/` directory
2. Install Python dependencies:
```bash
pip install -r requirements.txt
```
3. Create `.env` file with your API keys
4. Run the server:
```bash
uvicorn main:app --reload
```

### 7. Run the App

```bash
flutter run
```

## Features Implementation Status

✅ **Completed:**
- Project structure and dependencies
- Database schema
- Core UI components with Knot branding
- Flash Capture (Voice, OCR)
- Contact management
- Relationship health calculation
- Pre-meeting briefs (calendar integration)
- Gamification widgets

🚧 **In Progress:**
- Smart BCC email integration (backend structure ready)
- LinkedIn import via share sheet
- Streak tracking
- Push notifications

## Branding

- **App Name:** Knot
- **Tagline:** Tie the knot on your network
- **Primary Color:** Electric Indigo (#4F46E5)
- **Secondary Color:** Growth Green (#10B981)
- **Accent Color:** Alert Coral (#F43F5E)
- **Background:** Off-White (#F9FAFB)

## Next Steps

1. Implement authentication flow
2. Complete BCC email webhook processing
3. Add LinkedIn profile enrichment
4. Set up cron jobs for relationship health updates
5. Implement push notification triggers
6. Add subscription management (RevenueCat)
