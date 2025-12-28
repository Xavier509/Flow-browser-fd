-- Supabase migrations: create history, notes, and todos tables

-- History table (per-user navigation & search queries)
CREATE TABLE IF NOT EXISTS public.history (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id text NOT NULL,
  url text NOT NULL,
  query text,
  timestamp timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_history_user_ts ON public.history (user_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_history_query ON public.history (query);

-- Notes table (per-user simple notes)
CREATE TABLE IF NOT EXISTS public.notes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id text NOT NULL,
  text text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notes_user ON public.notes (user_id);

-- Todos table (per-user to-do items)
CREATE TABLE IF NOT EXISTS public.todos (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id text NOT NULL,
  text text NOT NULL,
  done boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_todos_user ON public.todos (user_id);
