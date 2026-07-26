-- =============================================================================
-- Voice Manager: complete Supabase schema (new-project bootstrap)
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE public.roles (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.permissions (
  id TEXT PRIMARY KEY,
  permission_key TEXT NOT NULL UNIQUE,
  description TEXT
);

CREATE TABLE public.role_permissions (
  role_id TEXT NOT NULL REFERENCES public.roles(id) ON DELETE CASCADE,
  permission_id TEXT NOT NULL REFERENCES public.permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE public.groups (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.members (
  id VARCHAR(5) PRIMARY KEY CHECK (id ~ '^[A-Za-z0-9]{5}$'),
  member_id VARCHAR(5) NOT NULL UNIQUE CHECK (member_id ~ '^[A-Za-z0-9]{5}$'),
  pin_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  profile_photo TEXT,
  college TEXT,
  year TEXT,
  member_type TEXT NOT NULL DEFAULT 'student',
  current_status TEXT NOT NULL DEFAULT 'Present',
  group_id TEXT REFERENCES public.groups(id) ON DELETE SET NULL,
  role_id TEXT REFERENCES public.roles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE public.tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
  due_date TEXT,
  created_by VARCHAR(5) REFERENCES public.members(id) ON DELETE SET NULL,
  assigned_to VARCHAR(5) REFERENCES public.members(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE TABLE public.notices (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  posted_by VARCHAR(5) REFERENCES public.members(id) ON DELETE SET NULL,
  department TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.leaves (
  id TEXT PRIMARY KEY,
  member_id VARCHAR(5) NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  reason TEXT,
  start_date TEXT NOT NULL,
  end_date TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'active', 'completed')),
  approved_by VARCHAR(5) REFERENCES public.members(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.meal_plans (
  id TEXT PRIMARY KEY,
  member_id VARCHAR(5) NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  date TEXT NOT NULL,
  breakfast BOOLEAN NOT NULL DEFAULT TRUE,
  lunch BOOLEAN NOT NULL DEFAULT TRUE,
  dinner BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.health_records (
  id TEXT PRIMARY KEY,
  member_id VARCHAR(5) NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  condition TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'Resting',
  reported_by VARCHAR(5) REFERENCES public.members(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.acknowledgements (
  id TEXT PRIMARY KEY,
  content TEXT NOT NULL,
  author_id VARCHAR(5) NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  tagged_member_ids TEXT NOT NULL DEFAULT '[]',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content TEXT NOT NULL,
  related_member_id VARCHAR(5) REFERENCES public.members(id) ON DELETE SET NULL,
  category TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.app_versions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  version TEXT NOT NULL,
  build_number INTEGER NOT NULL,
  is_mandatory BOOLEAN NOT NULL DEFAULT FALSE,
  release_notes TEXT,
  download_url TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- The current application uses its own Member ID + PIN session, not Supabase
-- Auth. These policies preserve that compatibility. Replace them with
-- authenticated, role-aware RLS policies before opening the backend to
-- untrusted users.
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.acknowledgements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow anonymous app access" ON public.roles FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.permissions FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.role_permissions FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.groups FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.members FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.tasks FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.notices FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.leaves FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.meal_plans FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.health_records FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.acknowledgements FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.activities FOR ALL USING (TRUE) WITH CHECK (TRUE);
CREATE POLICY "Allow anonymous app access" ON public.app_versions FOR ALL USING (TRUE) WITH CHECK (TRUE);

DO $$
DECLARE
  target_table TEXT;
BEGIN
  FOREACH target_table IN ARRAY ARRAY[
    'roles', 'permissions', 'role_permissions', 'groups', 'members',
    'tasks', 'notices', 'leaves', 'meal_plans', 'health_records',
    'acknowledgements', 'activities'
  ] LOOP
    EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', target_table);
  END LOOP;
END $$;
