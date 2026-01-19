-- Migration: User Profile System
-- Adds tables and columns for user profile building, conversational drafting, and learning system

-- Add profile completeness columns to users table
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS profile_completeness JSONB DEFAULT '{"basic_info": 0, "goals": 0, "communication_style": 0, "interests": 0, "work_education": 0}'::jsonb,
  ADD COLUMN IF NOT EXISTS current_profile_phase VARCHAR DEFAULT 'basic_info',
  ADD COLUMN IF NOT EXISTS profile_persona JSONB DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS last_question_date TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS total_questions_answered INTEGER DEFAULT 0;

-- User profile questions and answers table
CREATE TABLE IF NOT EXISTS user_profile_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phase VARCHAR NOT NULL CHECK (phase IN ('basic_info', 'goals', 'communication_style', 'interests', 'work_education')),
  question TEXT NOT NULL,
  answer TEXT,
  answer_type VARCHAR CHECK (answer_type IN ('text', 'voice')),
  skipped BOOLEAN DEFAULT FALSE,
  answer_later BOOLEAN DEFAULT FALSE, -- If true, question will reappear next week
  question_set VARCHAR DEFAULT 'initial', -- 'initial' or 'weekly_YYYY-MM-DD'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Draft conversations table (for iterative refinement)
CREATE TABLE IF NOT EXISTS draft_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  context VARCHAR NOT NULL CHECK (context IN ('email', 'linkedin', 'text', 'pre_meeting', 'search')),
  topic_name VARCHAR, -- Auto-generated topic name (e.g., "Email to Abbie")
  initial_draft TEXT NOT NULL,
  current_draft TEXT NOT NULL,
  conversation_history JSONB DEFAULT '[]'::jsonb, -- Array of {role: 'user'|'assistant', content: string, changes: string[]}
  completed BOOLEAN DEFAULT FALSE, -- Whether conversation is completed
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User preferences table (for learning from likes/dislikes)
CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_type VARCHAR NOT NULL CHECK (item_type IN ('draft', 'suggestion', 'advice')),
  item_id UUID, -- Reference to draft_conversations.id or other relevant IDs
  preference VARCHAR NOT NULL CHECK (preference IN ('like', 'dislike')),
  context TEXT, -- Additional context about why (from conversation)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_profile_answers_user_id ON user_profile_answers(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profile_answers_phase ON user_profile_answers(phase);
CREATE INDEX IF NOT EXISTS idx_draft_conversations_user_id ON draft_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_draft_conversations_contact_id ON draft_conversations(contact_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_item_type ON user_preferences(item_type);

-- RLS Policies
ALTER TABLE user_profile_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE draft_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- User profile answers policies
CREATE POLICY "Users can view own profile answers" ON user_profile_answers
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile answers" ON user_profile_answers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own profile answers" ON user_profile_answers
  FOR UPDATE USING (auth.uid() = user_id);

-- Draft conversations policies
CREATE POLICY "Users can view own draft conversations" ON draft_conversations
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own draft conversations" ON draft_conversations
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own draft conversations" ON draft_conversations
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own draft conversations" ON draft_conversations
  FOR DELETE USING (auth.uid() = user_id);

-- User preferences policies
CREATE POLICY "Users can view own preferences" ON user_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON user_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Trigger for updated_at on new tables
CREATE TRIGGER trigger_update_user_profile_answers_updated_at
  BEFORE UPDATE ON user_profile_answers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_draft_conversations_updated_at
  BEFORE UPDATE ON draft_conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
