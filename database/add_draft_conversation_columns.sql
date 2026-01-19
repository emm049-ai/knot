-- Add columns for draft conversation topics and completion status
-- Run this in Supabase SQL Editor

ALTER TABLE draft_conversations
  ADD COLUMN IF NOT EXISTS topic_name VARCHAR,
  ADD COLUMN IF NOT EXISTS completed BOOLEAN DEFAULT FALSE;
