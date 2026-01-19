# Fix Contact Import/Add Issue

## Problem
You're getting errors when trying to add or import contacts:
- `new row violates row-level security policy for table "users"`
- `insert or update on table "contacts" violates foreign key constraint`

## Root Cause
The `users` table has Row Level Security (RLS) enabled, but **there's no INSERT policy** allowing users to create their own record.

## Solution

### Option 1: Run SQL Fix in Supabase (Recommended)

1. Go to your Supabase Dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to **SQL Editor**
4. Run this SQL:

```sql
-- Add INSERT policy for users table
CREATE POLICY "Users can insert own data" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);
```

This allows users to insert their own record in the `users` table.

### Option 2: Use Database Trigger (Better Long-term Solution)

Run this in Supabase SQL Editor to automatically create user records on signup:

```sql
-- Function to automatically create user record on signup
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

-- Create trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

This automatically creates a user record whenever someone signs up, so you don't need to call `ensureUserExists` manually.

## After Running the Fix

1. **Restart the app** on your phone
2. Try adding a contact again
3. It should work now!

## Quick Fix (If you can't access Supabase Dashboard)

If you can't access the Supabase dashboard right now, I can also update the code to handle this better, but the database fix is the proper solution.
