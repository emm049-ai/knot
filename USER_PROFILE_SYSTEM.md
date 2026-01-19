# User Profile & Conversational Drafting System

## Overview
This update adds a comprehensive user profile building system and conversational drafting capabilities to help the app learn about users and provide personalized, refinable drafts.

## Features Implemented

### 1. User Profile Building System
- **Fillable Avatar on Home Page**: A person silhouette that fills up based on profile completeness (0-100%)
- **Phase-Based Profile Building**: 5 phases:
  - Basic Info (name, location, profession)
  - Goals & Aspirations
  - Communication Style
  - Interests & Hobbies
  - Work & Education
- **AI-Generated Personalized Questions**: Questions adapt based on previous answers (e.g., if user mentions sports, asks about specific sports)
- **Voice & Text Input**: Users can answer questions via typing or voice recording (with transcription preview)
- **Skip Questions**: Users can skip questions they don't want to answer
- **Progress Tracking**: Each phase shows completion percentage

### 2. My Profile Page
- Shows what the app knows about the user (AI-generated persona)
- Displays profile completeness for each phase
- Allows users to edit/correct information the app has learned
- Accessible from profile building page or settings

### 3. Conversational Drafting System
- **Iterative Refinement**: Users can refine drafts through conversation
- **Voice & Text Input**: Request changes via typing or voice
- **Change Highlighting**: Shows what was changed in each refinement
- **Conversation History**: Collapsible section showing all refinement steps
- **Change Summary Dropdown**: Quick view of what was changed
- **Like/Dislike Buttons**: Users can provide feedback on drafts

### 4. Learning System
- App learns from user preferences (likes/dislikes)
- Preferences saved to database for future personalization
- Context-aware (knows if draft is for email, LinkedIn, text, etc.)

## Database Migration Required

**IMPORTANT**: You must run the database migration before using these features.

1. Go to your Supabase Dashboard
2. Navigate to SQL Editor
3. Run the contents of `database/migration_user_profile.sql`

This will create:
- New columns in `users` table for profile data
- `user_profile_answers` table for Q&A
- `draft_conversations` table for draft refinement history
- `user_preferences` table for like/dislike tracking

## How to Use

### Building Your Profile
1. Click the avatar silhouette on the home page
2. Select a phase (or continue from current phase)
3. Answer AI-generated questions (type or record voice)
4. Skip questions you don't want to answer
5. Progress fills up the avatar as you complete phases

### Viewing Your Profile
- Click the person icon in the profile building page, or
- Go to Settings → My Profile
- Edit any information the app has learned about you

### Refining Drafts
1. Generate a draft (email, message, etc.) as usual
2. In the draft dialog, use the "Refine Draft" section
3. Type or record your request (e.g., "Make it more casual")
4. See highlighted changes in the updated draft
5. Use like/dislike buttons to provide feedback
6. View conversation history to see all refinements

## Technical Details

### Files Created
- `lib/core/models/user_profile_model.dart` - Data models
- `lib/core/services/user_profile_service.dart` - Profile management
- `lib/core/services/draft_conversation_service.dart` - Draft refinement
- `lib/features/profile/presentation/pages/profile_building_page.dart` - Profile building UI
- `lib/features/profile/presentation/pages/my_profile_page.dart` - Profile view/edit
- `lib/features/profile/presentation/widgets/profile_avatar_widget.dart` - Avatar widget
- `lib/features/drafts/presentation/widgets/conversational_draft_widget.dart` - Draft refinement UI

### Files Modified
- `lib/features/home/presentation/pages/home_page.dart` - Added avatar
- `lib/features/contacts/presentation/pages/contact_detail_page.dart` - Uses conversational drafting
- `lib/core/routing/app_router.dart` - Added new routes
- `lib/core/services/ai_service.dart` - Added public method for text generation

## Next Steps

1. **Run the database migration** (see above)
2. **Test the profile building flow** - Click avatar on home page
3. **Test conversational drafting** - Generate an email and try refining it
4. **Check "My Profile"** - See what the app has learned about you

The app will gradually learn more about each user as they:
- Answer profile questions
- Refine drafts
- Provide likes/dislikes
- Use the app over time

This data will be used to personalize future suggestions, drafts, and advice.
