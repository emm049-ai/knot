-- Knot App Database Schema (Basic Version - Without pgvector)
-- For Supabase PostgreSQL
-- Use this if pgvector extension is not available

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  bcc_email VARCHAR UNIQUE,
  streak_count INT DEFAULT 0,
  last_interaction_date DATE,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  call_tips_enabled BOOLEAN DEFAULT TRUE,
  call_tips_include_last_interaction BOOLEAN DEFAULT TRUE,
  call_tips_include_advice BOOLEAN DEFAULT TRUE,
  calendar_sync_enabled BOOLEAN DEFAULT FALSE,
  calendar_sync_followups BOOLEAN DEFAULT TRUE,
  calendar_sync_birthdays BOOLEAN DEFAULT TRUE,
  calendar_sync_updates BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Contacts table
CREATE TABLE IF NOT EXISTS contacts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR NOT NULL,
  first_name VARCHAR,
  middle_name VARCHAR,
  last_name VARCHAR,
  suffix VARCHAR,
  preferred_name VARCHAR,
  company VARCHAR,
  job_title VARCHAR,
  linkedin_url VARCHAR,
  email VARCHAR,
  phone VARCHAR,
  first_interaction_context TEXT,
  relationship_nature TEXT,
  relationship_goal TEXT,
  marital_status VARCHAR,
  kids_count INT,
  kids_details TEXT,
  additional_details TEXT,
  avatar_role VARCHAR,
  avatar_skin_tone VARCHAR,
  avatar_outfit VARCHAR,
  avatar_accessory VARCHAR,
  relationship_health INT DEFAULT 100 CHECK (relationship_health >= 0 AND relationship_health <= 100),
  last_contacted_at TIMESTAMP WITH TIME ZONE,
  frequency_preference INT DEFAULT 30, -- Days between contact
  tags TEXT[], -- Array of tags
  avatar_url VARCHAR,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notes table (without vector embedding for now)
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  contact_id UUID NOT NULL REFERENCES contacts(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  input_type VARCHAR NOT NULL CHECK (input_type IN ('voice', 'ocr', 'manual', 'email_bcc')),
  -- embedding column removed - can be added later when pgvector is enabled
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Email interactions table (for BCC tracking)
CREATE TABLE IF NOT EXISTS email_interactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  to_email VARCHAR NOT NULL,
  subject VARCHAR,
  body TEXT,
  received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Calendar events table (for pre-meeting briefs)
CREATE TABLE IF NOT EXISTS calendar_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  contact_id UUID REFERENCES contacts(id) ON DELETE SET NULL,
  event_id VARCHAR, -- Device calendar event ID
  title VARCHAR NOT NULL,
  start_time TIMESTAMP WITH TIME ZONE NOT NULL,
  end_time TIMESTAMP WITH TIME ZONE,
  location VARCHAR,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_contacts_user_id ON contacts(user_id);
CREATE INDEX IF NOT EXISTS idx_contacts_last_contacted ON contacts(last_contacted_at);
CREATE INDEX IF NOT EXISTS idx_notes_contact_id ON notes(contact_id);
-- Vector index removed - can be added later when pgvector is enabled
CREATE INDEX IF NOT EXISTS idx_email_interactions_user_id ON email_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_user_id ON calendar_events(user_id);
CREATE INDEX IF NOT EXISTS idx_calendar_events_start_time ON calendar_events(start_time);

-- Function to update relationship health
CREATE OR REPLACE FUNCTION update_relationship_health()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate health based on days since last contact
  -- Decay rate: 1% per day
  IF NEW.last_contacted_at IS NOT NULL THEN
    NEW.relationship_health := GREATEST(0, 100 - EXTRACT(DAY FROM (NOW() - NEW.last_contacted_at))::INT);
  ELSE
    NEW.relationship_health := 100;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update relationship health
CREATE TRIGGER trigger_update_relationship_health
  BEFORE INSERT OR UPDATE ON contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_relationship_health();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER trigger_update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_contacts_updated_at
  BEFORE UPDATE ON contacts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE contacts ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_events ENABLE ROW LEVEL SECURITY;

-- Users can only see their own data
CREATE POLICY "Users can view own data" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own data" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Contacts policies
CREATE POLICY "Users can view own contacts" ON contacts
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own contacts" ON contacts
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own contacts" ON contacts
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own contacts" ON contacts
  FOR DELETE USING (auth.uid() = user_id);

-- Notes policies
CREATE POLICY "Users can view notes for own contacts" ON notes
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM contacts
      WHERE contacts.id = notes.contact_id
      AND contacts.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert notes for own contacts" ON notes
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM contacts
      WHERE contacts.id = notes.contact_id
      AND contacts.user_id = auth.uid()
    )
  );

-- Email interactions policies
CREATE POLICY "Users can view own email interactions" ON email_interactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own email interactions" ON email_interactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Calendar events policies
CREATE POLICY "Users can view own calendar events" ON calendar_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own calendar events" ON calendar_events
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own calendar events" ON calendar_events
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own calendar events" ON calendar_events
  FOR DELETE USING (auth.uid() = user_id);
