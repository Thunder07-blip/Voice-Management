-- Voice Manager: canonical RBAC, data integrity, and Realtime coverage.
-- Safe for the current production data: it only replaces the four previously
-- seeded role records and their permission mappings. Members are retained.

BEGIN;

-- Every member identity and member foreign key is intentionally five
-- alphanumeric characters (for example VV001). Fill legacy NULL member IDs
-- from the primary key before making the login identifier mandatory.
UPDATE public.members
SET member_id = id
WHERE member_id IS NULL AND id ~ '^[A-Za-z0-9]{5}$';

ALTER TABLE public.members
  ALTER COLUMN member_id SET NOT NULL,
  ALTER COLUMN pin_hash SET NOT NULL;

ALTER TABLE public.members
  DROP CONSTRAINT IF EXISTS members_id_format,
  ADD CONSTRAINT members_id_format CHECK (id ~ '^[A-Za-z0-9]{5}$'),
  DROP CONSTRAINT IF EXISTS members_member_id_format,
  ADD CONSTRAINT members_member_id_format CHECK (member_id ~ '^[A-Za-z0-9]{5}$');

-- Remove only the old, incomplete catalog created by the earlier seed flow.
DELETE FROM public.role_permissions
WHERE role_id IN ('R001', 'role-pm-001', 'role-oc-001', 'role-aoc-001')
   OR permission_id IN ('P001', 'P002', 'P003', 'perm-ack-001');

INSERT INTO public.roles (id, name, description, created_at, updated_at) VALUES
  ('R0001', 'Project Manager', 'Full system administration and daily operations.', NOW(), NOW()),
  ('R0002', 'Overall Coordinator', 'Coordinates members, leaves, tasks, and notices.', NOW(), NOW()),
  ('R0003', 'Assistant Overall Coordinator', 'Supports leave, task, notice, health, and meal operations.', NOW(), NOW()),
  ('R0004', 'Kitchen Incharge', 'Manages kitchen planning and kitchen announcements.', NOW(), NOW()),
  ('R0005', 'Chef', 'Views kitchen meal requirements and attendance.', NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  updated_at = NOW();

UPDATE public.members
SET role_id = 'R0002'
WHERE id = 'VV002' AND role_id = 'R001';

DELETE FROM public.roles
WHERE id IN ('R001', 'role-pm-001', 'role-oc-001', 'role-aoc-001');

DELETE FROM public.permissions
WHERE id IN ('P001', 'P002', 'P003', 'perm-ack-001');

INSERT INTO public.permissions (id, permission_key, description) VALUES
  ('P0001', 'manage_members', 'Create, edit, and remove member profiles.'),
  ('P0002', 'manage_roles', 'Create roles and change role-permission assignments.'),
  ('P0003', 'manage_leaves', 'View and approve or reject every leave request.'),
  ('P0004', 'manage_tasks', 'Create, assign, update, and delete community tasks.'),
  ('P0005', 'post_notices', 'Publish notices to the community.'),
  ('P0006', 'manage_meals', 'Manage meal-planning data and kitchen operations.'),
  ('P0007', 'view_meals', 'View kitchen meal requirements and attendance.'),
  ('P0008', 'manage_health', 'Report and update community-health records.'),
  ('P0009', 'manage_acknowledgements', 'Post and manage acknowledgement-board entries.')
ON CONFLICT (id) DO UPDATE SET
  permission_key = EXCLUDED.permission_key,
  description = EXCLUDED.description;

ALTER TABLE public.permissions
  DROP CONSTRAINT IF EXISTS permissions_permission_key_key,
  ADD CONSTRAINT permissions_permission_key_key UNIQUE (permission_key);

INSERT INTO public.role_permissions (role_id, permission_id) VALUES
  -- Project Manager: full application access.
  ('R0001', 'P0001'), ('R0001', 'P0002'), ('R0001', 'P0003'),
  ('R0001', 'P0004'), ('R0001', 'P0005'), ('R0001', 'P0006'),
  ('R0001', 'P0007'), ('R0001', 'P0008'), ('R0001', 'P0009'),
  -- Overall Coordinator: daily operation access, without role design.
  ('R0002', 'P0001'), ('R0002', 'P0003'), ('R0002', 'P0004'),
  ('R0002', 'P0005'), ('R0002', 'P0006'), ('R0002', 'P0007'),
  ('R0002', 'P0008'), ('R0002', 'P0009'),
  -- Assistant OC: supports operations but cannot manage users or roles.
  ('R0003', 'P0003'), ('R0003', 'P0004'), ('R0003', 'P0005'),
  ('R0003', 'P0007'), ('R0003', 'P0008'), ('R0003', 'P0009'),
  -- Kitchen roles.
  ('R0004', 'P0005'), ('R0004', 'P0006'), ('R0004', 'P0007'),
  ('R0005', 'P0007')
ON CONFLICT DO NOTHING;

-- Keep Realtime subscriptions complete. The DO block makes the script safe to
-- run more than once because Supabase errors when a table is already present.
DO $$
DECLARE
  target_table TEXT;
BEGIN
  FOREACH target_table IN ARRAY ARRAY[
    'roles', 'permissions', 'role_permissions', 'groups', 'members',
    'tasks', 'notices', 'leaves', 'meal_plans', 'health_records',
    'acknowledgements', 'activities'
  ] LOOP
    BEGIN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', target_table);
    EXCEPTION WHEN duplicate_object THEN
      NULL;
    END;
  END LOOP;
END $$;

COMMIT;
