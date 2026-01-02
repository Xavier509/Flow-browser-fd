-- Supabase migration: create bookmarks, tabs and sessions tables

-- Bookmarks (per-user)
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id text NOT NULL,
  title text,
  url text NOT NULL,
  pinned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks (user_id);

-- Tabs (individual tab state, optional)
CREATE TABLE IF NOT EXISTS public.tabs (
  id text PRIMARY KEY,
  user_id text NOT NULL,
  url text NOT NULL,
  title text,
  workspace text,
  tab_index int,
  history jsonb,
  is_active boolean DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tabs_user ON public.tabs (user_id);

-- Sessions (workspaces & window state)
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id text NOT NULL,
  name text NOT NULL,
  workspaces jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON public.sessions (user_id);
