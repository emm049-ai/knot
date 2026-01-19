# Knot App - Project Structure

## Overview

Knot is a Flutter mobile application that helps students and job seekers manage their professional network through intelligent data capture, AI-powered follow-ups, and gamified relationship management.

## Directory Structure

```
knot/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── models/                        # Data models
│   │   │   ├── contact_model.dart
│   │   │   └── note_model.dart
│   │   ├── routing/                       # Navigation
│   │   │   └── app_router.dart
│   │   ├── services/                      # Business logic
│   │   │   ├── supabase_service.dart      # Database operations
│   │   │   ├── ai_service.dart            # OpenAI integration
│   │   │   ├── ocr_service.dart           # Google ML Kit OCR
│   │   │   ├── voice_service.dart         # Audio recording
│   │   │   ├── calendar_service.dart      # Calendar integration
│   │   │   ├── notification_service.dart  # Push notifications
│   │   │   └── gamification_service.dart  # Streaks & health
│   │   ├── theme/                         # App theming
│   │   │   └── app_theme.dart
│   │   └── utils/                         # Utilities
│   │       └── relationship_health_calculator.dart
│   └── features/
│       ├── home/                          # Home screen
│       │   └── presentation/
│       │       ├── pages/
│       │       │   └── home_page.dart
│       │       └── widgets/
│       │           └── quick_stats_widget.dart
│       ├── contacts/                     # Contact management
│       │   └── presentation/
│       │       ├── pages/
│       │       │   ├── contacts_list_page.dart
│       │       │   └── contact_detail_page.dart
│       │       └── widgets/
│       │           └── contact_card.dart
│       ├── capture/                      # Flash Capture feature
│       │   └── presentation/
│       │       └── pages/
│       │           └── capture_page.dart
│       ├── gamification/                 # Gamification features
│       │   └── presentation/
│       │       └── widgets/
│       │           ├── relationship_plant_widget.dart
│       │           └── streak_widget.dart
│       └── settings/                     # Settings screen
│           └── presentation/
│               └── pages/
│                   └── settings_page.dart
├── backend/                              # FastAPI backend
│   ├── main.py                           # API server
│   ├── requirements.txt
│   └── README.md
├── database/
│   └── schema.sql                        # Supabase schema
├── android/                              # Android configuration
│   └── app/src/main/
│       └── AndroidManifest.xml
├── ios/                                  # iOS configuration
│   └── Runner/
│       └── Info.plist
├── pubspec.yaml                          # Flutter dependencies
├── README.md
├── SETUP.md                              # Setup instructions
└── .env.example                          # Environment variables template
```

## Key Features

### 1. Flash Capture
- **Voice Recording**: Record voice notes, transcribe with Whisper, extract contact info with GPT-4o-mini
- **OCR Scanning**: Scan business cards and handwritten notes using Google ML Kit
- **LinkedIn Import**: Share LinkedIn profiles to app (via share sheet)

### 2. Smart BCC Email Integration
- Each user gets a unique BCC email address
- Emails BCC'd to this address are automatically tracked
- Updates contact's `last_contacted_at` timestamp
- Logs email interactions

### 3. Pre-Game Briefs
- Syncs with device calendar
- Checks for upcoming meetings (30 min before)
- Matches calendar events with contacts
- Generates AI-powered meeting briefs
- Sends push notifications

### 4. Gamification
- **Relationship Health**: 0-100% based on days since last contact (1% decay per day)
- **Visual Plant Growth**: 🌺 Blooming (80-100%), 🌿 Healthy (50-79%), 🍂 Wilting (25-49%), 💀 Dead (0-24%)
- **Streak Tracking**: Daily interaction streaks
- **Needs Attention**: Highlights contacts with health < 50%

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Python FastAPI
- **Database**: Supabase (PostgreSQL with pgvector)
- **AI**: OpenAI GPT-4o-mini + Whisper
- **OCR**: Google ML Kit
- **Notifications**: Firebase Cloud Messaging
- **Calendar**: device_calendar plugin
- **Payments**: RevenueCat (ready for integration)

## Color Palette

- **Primary**: Electric Indigo (#4F46E5)
- **Secondary**: Growth Green (#10B981)
- **Accent**: Alert Coral (#F43F5E)
- **Background**: Off-White (#F9FAFB)

## Next Development Steps

1. **Authentication**: Implement login/signup flow
2. **LinkedIn Enrichment**: Integrate Proxycurl/Nubela API
3. **Email Webhook**: Complete BCC email processing
4. **Cron Jobs**: Set up scheduled tasks for health updates
5. **Push Notifications**: Configure FCM triggers
6. **Vector Search**: Implement RAG for note search
7. **Subscription**: Add RevenueCat integration
