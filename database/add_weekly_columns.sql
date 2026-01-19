-- Add columns for weekly question system
-- Run this in Supabase SQL Editor

-- Add new columns to users table
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS last_question_date TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS total_questions_answered INTEGER DEFAULT 0;

-- Add new columns to user_profile_answers table
ALTER TABLE user_profile_answers
  ADD COLUMN IF NOT EXISTS answer_later BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS question_set VARCHAR DEFAULT 'initial';
