-- Fix User Creation Issue
-- This script fixes the Row Level Security (RLS) issue preventing user creation

-- Option 1: Create a function that automatically creates user records
-- This runs as the service role, bypassing RLS
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, bcc_email, streak_count)
  VALUES (
    NEW.id,
    NEW.id || '@inbound.careercaddie.com',
    0
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically create user record on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- Option 2: Update RLS policies to allow users to insert their own record
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can insert their own record" ON public.users;
DROP POLICY IF EXISTS "Users can view their own record" ON public.users;
DROP POLICY IF EXISTS "Users can update their own record" ON public.users;

-- Create RLS policies that allow users to manage their own record
CREATE POLICY "Users can insert their own record"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view their own record"
  ON public.users
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own record"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = id);

-- Ensure RLS is enabled
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Note: The trigger approach (Option 1) is preferred as it automatically
-- creates the user record when they sign up, so you don't need to call
-- ensureUserExists manually.
