-- ==============================================================================
-- VOICE MANAGER - FULL SUPABASE DEPLOYMENT SCHEMA
-- Run this in your Supabase SQL Editor to set up the entire backend.
-- ==============================================================================

-- 1. Create Tables

CREATE TABLE public.roles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.permissions (
    id TEXT PRIMARY KEY,
    permission_key TEXT NOT NULL,
    description TEXT
);

CREATE TABLE public.role_permissions (
    role_id TEXT REFERENCES public.roles(id) ON DELETE CASCADE,
    permission_id TEXT REFERENCES public.permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

CREATE TABLE public.members (
    id TEXT PRIMARY KEY,
    member_id TEXT UNIQUE NOT NULL,
    pin_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    member_type TEXT NOT NULL DEFAULT 'student',
    college TEXT,
    course TEXT,
    contact_number TEXT,
    role_id TEXT REFERENCES public.roles(id) ON DELETE SET NULL,
    current_status TEXT DEFAULT 'Present',
    photo_url TEXT,
    join_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.groups (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    created_by TEXT REFERENCES public.members(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.group_members (
    group_id TEXT REFERENCES public.groups(id) ON DELETE CASCADE,
    member_id TEXT REFERENCES public.members(id) ON DELETE CASCADE,
    PRIMARY KEY (group_id, member_id)
);

CREATE TABLE public.tasks (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    priority TEXT DEFAULT 'medium',
    status TEXT DEFAULT 'pending',
    created_by TEXT REFERENCES public.members(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.task_assignments (
    task_id TEXT REFERENCES public.tasks(id) ON DELETE CASCADE,
    member_id TEXT REFERENCES public.members(id) ON DELETE CASCADE,
    PRIMARY KEY (task_id, member_id)
);

CREATE TABLE public.leaves (
    id TEXT PRIMARY KEY,
    member_id TEXT REFERENCES public.members(id) ON DELETE CASCADE,
    reason TEXT,
    start_date TEXT NOT NULL,
    end_date TEXT,
    status TEXT DEFAULT 'pending',
    approved_by TEXT REFERENCES public.members(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.meal_plans (
    id TEXT PRIMARY KEY,
    member_id TEXT REFERENCES public.members(id) ON DELETE CASCADE,
    date TEXT NOT NULL,
    breakfast BOOLEAN DEFAULT true,
    lunch BOOLEAN DEFAULT true,
    dinner BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.health_records (
    id TEXT PRIMARY KEY,
    member_id TEXT REFERENCES public.members(id) ON DELETE CASCADE,
    condition TEXT NOT NULL,
    status TEXT DEFAULT 'Resting',
    reported_by TEXT REFERENCES public.members(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.activities (
    id TEXT PRIMARY KEY,
    content TEXT NOT NULL,
    category TEXT NOT NULL,
    related_member_id TEXT REFERENCES public.members(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE public.app_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version TEXT NOT NULL,
    build_number INTEGER NOT NULL,
    is_mandatory BOOLEAN NOT NULL DEFAULT false,
    release_notes TEXT,
    download_url TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ==============================================================================
-- 2. Row Level Security (RLS) Policies
-- For internal MVP, we enable RLS but allow authenticated/public reads & writes
-- pending full Supabase Auth migration.
-- ==============================================================================

ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaves ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.health_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- Allow all operations for now (Since the app currently uses PIN auth locally, 
-- Supabase sees the requests as "anon". When you migrate to Supabase Auth, you will restrict these.)
CREATE POLICY "Allow anon everything" ON public.roles FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.permissions FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.role_permissions FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.members FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.groups FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.group_members FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.tasks FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.task_assignments FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.leaves FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.meal_plans FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.health_records FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.activities FOR ALL USING (true);
CREATE POLICY "Allow anon everything" ON public.app_versions FOR ALL USING (true);

-- Enable Realtime for relevant tables
alter publication supabase_realtime add table public.members;
alter publication supabase_realtime add table public.tasks;
alter publication supabase_realtime add table public.task_assignments;
alter publication supabase_realtime add table public.leaves;
alter publication supabase_realtime add table public.meal_plans;
alter publication supabase_realtime add table public.health_records;
alter publication supabase_realtime add table public.activities;
