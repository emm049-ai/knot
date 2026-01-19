# How to Enable pgvector in Supabase (Optional)

## What is pgvector?

pgvector is an extension that enables vector similarity search in PostgreSQL. It's used for:
- AI-powered note search (e.g., "Who likes skiing?")
- Semantic search across contact notes
- Finding similar contacts based on notes

## Current Status

Your Supabase project doesn't have pgvector enabled. **This is fine!** The app works without it. You just won't have advanced vector search features.

## How to Enable pgvector (If You Want It)

### Option 1: Request from Supabase Support

1. Go to your Supabase Dashboard
2. Click "Support" or open a ticket
3. Request to enable the `pgvector` extension
4. They'll enable it for your project

### Option 2: Use Supabase CLI (Advanced)

If you have Supabase CLI installed:

```bash
supabase db enable-extension pgvector
```

### Option 3: Check if Available in Your Plan

Some Supabase plans include pgvector by default. Check your plan features.

## After Enabling pgvector

Once pgvector is enabled, you can run this to add vector search support:

```sql
-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS "pgvector";

-- Add embedding column to notes table
ALTER TABLE notes ADD COLUMN IF NOT EXISTS embedding vector(1536);

-- Create vector index for similarity search
CREATE INDEX IF NOT EXISTS idx_notes_embedding 
ON notes USING ivfflat (embedding vector_cosine_ops)
WITH (lists = 100);
```

## For Now

**Just use `schema_basic.sql`** - it works perfectly without pgvector. The app will function normally, you just won't have the advanced AI search feature (which is optional anyway).

## Note

The vector search feature is nice-to-have, not essential. All core features work without it:
- ✅ Contact management
- ✅ Voice/OCR capture
- ✅ Relationship health
- ✅ Follow-up emails
- ✅ Pre-meeting briefs
- ✅ Gamification

Vector search is only for advanced note searching, which can be added later.
