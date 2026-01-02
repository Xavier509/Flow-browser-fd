## Supabase migrations for history, notes, and todos

Run the SQL migration in `supabase_migrations/001_create_history_notes_todos.sql` on your Supabase project SQL editor to enable server-side storage for per-account history, notes and todos.

If you want bookmarks, tabs and sessions to sync across devices, also run `supabase_migrations/002_create_bookmarks_tabs_sessions.sql` which creates `bookmarks`, `tabs`, and `sessions` tables used by the app.

Example steps:

1. Open your Supabase project.
2. Go to SQL Editor → New Query.
3. Paste the contents of `supabase_migrations/001_create_history_notes_todos.sql` and run.

After creating tables, the app will automatically insert history/notes/todos for authenticated users. The client does basic deduplication when syncing from Supabase.

If you'd like, I can produce alternative migration formats (pgmigrate, supabase CLI) or help you run these in your Supabase project.