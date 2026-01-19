# Fix: pgvector Extension Error

## The Problem

You got this error:
```
ERROR: extension "pgvector" is not available
```

## The Solution

**Use the basic schema instead!** I've created `database/schema_basic.sql` which works without pgvector.

## Steps to Fix

1. **In Supabase SQL Editor:**
   - Clear the current query (or open a new tab)
   - Open `database/schema_basic.sql` from your project
   - Copy ALL the contents
   - Paste into Supabase SQL Editor
   - Click "Run"

2. **This will create:**
   - ✅ All tables (users, contacts, notes, etc.)
   - ✅ All indexes
   - ✅ All triggers
   - ✅ All security policies
   - ❌ Vector search (optional - can add later)

## What's Different?

The basic schema:
- ✅ Works immediately (no pgvector needed)
- ✅ Has all core features
- ❌ No vector embedding column in notes (can add later)
- ❌ No vector similarity search (optional feature)

## After Running schema_basic.sql

Your app will work perfectly! You can:
- Sign up and login
- Add contacts
- Use voice/OCR capture
- See relationship health
- Generate follow-up emails
- Everything else!

## Adding Vector Search Later (Optional)

If you want vector search later:
1. Request pgvector from Supabase support
2. Run the SQL in `database/ENABLE_PGVECTOR.md`
3. That's it!

## Quick Action

**Right now:** Just use `schema_basic.sql` instead of `schema.sql`. It will work immediately! 🚀
