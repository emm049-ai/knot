# Knot App - Development Checklist

## ✅ Completed Features

- [x] Project structure and dependencies
- [x] Database schema (Supabase)
- [x] Authentication (Login/Signup)
- [x] Route guards and navigation
- [x] Core UI components with Knot branding
- [x] Contact management (CRUD)
- [x] Flash Capture (Voice + OCR)
- [x] AI-powered contact extraction
- [x] Relationship health calculation
- [x] Gamification widgets (Plant, Streak)
- [x] Pre-meeting briefs (Calendar integration)
- [x] Follow-up email generation
- [x] Settings page
- [x] Error handling widgets
- [x] LinkedIn service structure

## 🚧 Needs Configuration

### 1. Environment Variables
Create `.env` file with:
- `SUPABASE_URL` - Your Supabase project URL
- `SUPABASE_ANON_KEY` - Your Supabase anon key
- `OPENAI_API_KEY` - Your OpenAI API key
- `PROXYCURL_API_KEY` (optional) - For LinkedIn enrichment

### 2. Supabase Setup
- [ ] Run `database/schema.sql` in Supabase SQL editor
- [ ] Enable Row Level Security (RLS) policies
- [ ] Test authentication flow
- [ ] Verify user table creation on signup

### 3. Firebase (Optional - for push notifications)
- [ ] Create Firebase project
- [ ] Add Android app to Firebase
- [ ] Add iOS app to Firebase
- [ ] Download `google-services.json` (Android)
- [ ] Download `GoogleService-Info.plist` (iOS)
- [ ] Place files in correct directories

### 4. Email Service (for BCC feature)
Choose one:
- [ ] **SendGrid**: Set up Inbound Parse webhook
- [ ] **Mailgun**: Set up Routes
- [ ] Configure domain: `inbound.careercaddie.com`
- [ ] Point webhook to backend: `/webhook/email`

### 5. Backend Setup
- [ ] Install Python dependencies: `pip install -r backend/requirements.txt`
- [ ] Create backend `.env` file
- [ ] Test API endpoints
- [ ] Set up cron jobs (or use Supabase Edge Functions)

### 6. Platform-Specific Setup

#### Android
- [ ] Verify permissions in `AndroidManifest.xml`
- [ ] Test on Android device/emulator
- [ ] Configure share intent handling

#### iOS
- [ ] Verify permissions in `Info.plist`
- [ ] Test on iOS device/simulator
- [ ] Configure share extension
- [ ] Set up App Store Connect (for future release)

## 🔨 Features to Complete

### High Priority
1. **LinkedIn Share Handler**
   - [ ] Implement platform channels for share intents
   - [ ] Test LinkedIn profile import
   - [ ] Handle profile enrichment

2. **BCC Email Processing**
   - [ ] Complete webhook handler in backend
   - [ ] Test email parsing
   - [ ] Update contact last_contacted_at
   - [ ] Log email interactions

3. **Calendar Sync**
   - [ ] Test calendar permission requests
   - [ ] Implement periodic meeting checks
   - [ ] Test pre-meeting brief generation
   - [ ] Configure push notification triggers

### Medium Priority
4. **Streak Tracking**
   - [ ] Implement daily streak calculation
   - [ ] Update streak on contact interactions
   - [ ] Display streak in UI

5. **Vector Search (RAG)**
   - [ ] Generate embeddings for notes
   - [ ] Implement search functionality
   - [ ] Test "Who likes skiing?" queries

6. **Contact Editing**
   - [ ] Add edit contact functionality
   - [ ] Update contact detail page
   - [ ] Handle relationship health updates

### Low Priority
7. **Subscription Management**
   - [ ] Integrate RevenueCat
   - [ ] Set up Standard/Premium tiers
   - [ ] Add paywall UI

8. **Advanced Features**
   - [ ] Contact tags management
   - [ ] Contact filtering and search
   - [ ] Export contacts
   - [ ] Analytics dashboard

## 🐛 Known Issues / TODOs

- [ ] Firebase initialization fails gracefully (handled)
- [ ] LinkedIn share handler needs platform channel implementation
- [ ] BCC email webhook needs backend completion
- [ ] Calendar service needs periodic check implementation
- [ ] Streak calculation needs backend cron job or local logic
- [ ] Contact avatar support (currently using initials)

## 📱 Testing Checklist

- [ ] Test login/signup flow
- [ ] Test contact creation (voice)
- [ ] Test contact creation (OCR)
- [ ] Test contact creation (manual)
- [ ] Test relationship health calculation
- [ ] Test follow-up email generation
- [ ] Test calendar integration
- [ ] Test push notifications
- [ ] Test on both Android and iOS
- [ ] Test error handling and edge cases

## 🚀 Deployment Checklist

- [ ] Set up production Supabase project
- [ ] Configure production environment variables
- [ ] Set up production backend server
- [ ] Configure email service for production
- [ ] Set up app store accounts (Google Play + App Store)
- [ ] Prepare app icons and screenshots
- [ ] Write app store descriptions
- [ ] Set up analytics (optional)
- [ ] Configure crash reporting (optional)
