# Knot - Tie the knot on your network

A mobile application that helps students and job seekers manage their professional network through intelligent data capture, AI-powered follow-ups, and gamified relationship management.

## Features

- **Flash Capture**: Quickly add contacts via voice, OCR scanning, or LinkedIn import
- **Smart BCC**: Automatic email tracking through BCC integration
- **Pre-Game Briefs**: AI-generated reminders before meetings
- **Gamification**: Relationship health tracking with visual plant growth

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Python FastAPI (separate repo)
- **Database**: Supabase (PostgreSQL)
- **AI**: Google Gemini 1.5 Flash
- **Voice**: Google Speech-to-Text API
- **OCR**: Google ML Kit

## Quick Start

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Set up your API keys:**
   - Create a `.env` file in the root directory
   - Add your keys (see `KEYS_SETUP.md` for details):
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     GEMINI_API_KEY=your_gemini_api_key
     ```

3. **Set up Supabase database:**
   - Run `database/schema.sql` in your Supabase SQL editor
   - See `SETUP.md` for detailed instructions

4. **Run the app:**
   ```bash
   flutter run
   ```

## Configuration

### Required
- ✅ Supabase account and keys
- ✅ Gemini API key

### Optional
- 🔔 Firebase (for push notifications) - see `FIREBASE_SETUP.md`
- 🔗 LinkedIn OAuth (for LinkedIn integration) - see `LINKEDIN_SETUP.md`
- 🎤 Google Speech-to-Text API key (for voice transcription)

## Documentation

- `SETUP.md` - Complete setup guide
- `KEYS_SETUP.md` - How to configure API keys
- `FIREBASE_SETUP.md` - Firebase configuration
- `LINKEDIN_SETUP.md` - LinkedIn API setup
- `PROJECT_STRUCTURE.md` - Code organization
- `DEVELOPMENT_CHECKLIST.md` - Development tasks

## Branding

- **App Name**: Knot
- **Tagline**: Tie the knot on your network
- **Primary Color**: Electric Indigo (#4F46E5)
- **Secondary Color**: Growth Green (#10B981)
- **Accent Color**: Alert Coral (#F43F5E)
- **Background**: Off-White (#F9FAFB)

## License

Private - All rights reserved
