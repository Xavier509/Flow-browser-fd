can you make the long press not have to be so long, so it works on shorter holds. also make it so teh animation are smooth when movnig a tab so that tabs move aside for it and they can position it exactly when they want. also with the new window, i meant a new window/ opening of the app, not a workspace. then the tabs still dont update isntantly so fix that along with making teh tabs cache so you can switch between tabs seamlessly and getting the rigth pages and content instantly, and not eh page you were on bewfore the new one

# Next Update: Supabase schema for sync (tabs, sessions, bookmarks)

Supabase SQL schemas and instructions to enable cross-device tabs/sessions, bookmarks, devices, and email verification.

Run the SQL below in the Supabase SQL editor (or `psql`) for your project. It creates the tables, row-level security (RLS) policies, and helper functions used by the app.

-- IMPORTANT:
-- Ensure Supabase Auth email confirmations are enabled in the Supabase dashboard:
-- Authentication → Settings → Email → Confirm email: Enabled


-- 1) Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- 2) Profiles table (mirrors auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  username text,
  created_at timestamptz DEFAULT now()
);


-- 3) Bookmarks
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users (id) ON DELETE CASCADE,
  url text NOT NULL,
  title text,
  favicon text,
  workspace text,
  metadata jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS bookmarks_user_idx ON public.bookmarks (user_id);


-- 4) Tabs (individual tab state)
CREATE TABLE IF NOT EXISTS public.tabs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users (id) ON DELETE CASCADE,
  workspace text,
  tab_index integer,
  url text,
  title text,
  history jsonb DEFAULT '[]'::jsonb,
  is_active boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tabs_user_idx ON public.tabs (user_id);


-- 5) Sessions (saved workspace collections / sync state)
CREATE TABLE IF NOT EXISTS public.sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users (id) ON DELETE CASCADE,
  name text,
  workspaces jsonb,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS sessions_user_idx ON public.sessions (user_id);


-- 6) Devices (optional: register devices for multi-device awareness)
CREATE TABLE IF NOT EXISTS public.devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users (id) ON DELETE CASCADE,
  device_name text,
  last_seen timestamptz DEFAULT now(),
  metadata jsonb DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS devices_user_idx ON public.devices (user_id);


-- 7) Row Level Security (RLS) Policies

-- Profiles RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select_insert_update_delete"
  ON public.profiles FOR ALL
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Bookmarks RLS
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bookmarks_select_insert_update_delete"
  ON public.bookmarks FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Tabs RLS
ALTER TABLE public.tabs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tabs_select_insert_update_delete"
  ON public.tabs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Sessions RLS
ALTER TABLE public.sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sessions_select_insert_update_delete"
  ON public.sessions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Devices RLS
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "devices_select_insert_update_delete"
  ON public.devices FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- 8) Helper function: upsert session by name
CREATE OR REPLACE FUNCTION public.upsert_session(
  p_user uuid,
  p_name text,
  p_workspaces jsonb
)
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  v_id uuid;
BEGIN
  SELECT id INTO v_id
  FROM public.sessions
  WHERE user_id = p_user
  AND name = p_name
  LIMIT 1;

  IF FOUND THEN
    UPDATE public.sessions
    SET workspaces = p_workspaces,
        updated_at = now()
    WHERE id = v_id;
    RETURN v_id;
  ELSE
    INSERT INTO public.sessions (user_id, name, workspaces)
    VALUES (p_user, p_name, p_workspaces)
    RETURNING id INTO v_id;
    RETURN v_id;
  END IF;
END;
$$;

