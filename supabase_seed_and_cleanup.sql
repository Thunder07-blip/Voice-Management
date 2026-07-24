-- ==============================================================================
-- VOICE MANAGER - SEED & CLEANUP SQL SCRIPT FOR SUPABASE
-- Run these queries directly in your Supabase SQL Editor.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. POST / INSERT SEED DATA (Push to Supabase)
-- ------------------------------------------------------------------------------

-- Step A: Insert Roles
INSERT INTO public.roles (id, name, description) VALUES
  ('role-pm-001', 'Project Manager', 'Full system access.'),
  ('role-oc-001', 'Overall Coordinator', 'System access.'),
  ('role-aoc-001', 'Assistant Overall Coordinator', 'System access.')
ON CONFLICT (id) DO NOTHING;

-- Step B: Insert Permissions & Role Permissions
INSERT INTO public.permissions (id, permission_key, description) VALUES
  ('perm-ack-001', 'manage_acknowledgements', 'Can post new acknowledgements on the board')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.role_permissions (role_id, permission_id) VALUES
  ('role-pm-001', 'perm-ack-001'),
  ('role-oc-001', 'perm-ack-001'),
  ('role-aoc-001', 'perm-ack-001')
ON CONFLICT DO NOTHING;

-- Step C: Insert 10 Members
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES
  ('member-001', 'VO-001', '1234', 'HG Radhapad pankaj pr', 'working', 'role-pm-001', 'Present'),
  ('member-002', 'VO-002', '1234', 'Piyush Jagzap', 'working', 'role-oc-001', 'Present'),
  ('member-003', 'VO-003', '1234', 'Sajal Patil', 'working', 'role-aoc-001', 'Present'),
  ('member-004', 'VO-004', '1234', 'Soham Dode', 'working', NULL, 'Present'),
  ('member-005', 'VO-005', '1234', 'Sushant Nikaju', 'working', NULL, 'Present'),
  ('member-006', 'VO-006', '1234', 'Pratik Gadade', 'working', NULL, 'Present'),
  ('member-007', 'VO-007', '1234', 'Mayur Patil', 'working', NULL, 'Present'),
  ('member-008', 'VO-008', '1234', 'Aditya Deshmukh', 'working', NULL, 'Present'),
  ('member-009', 'VO-009', '1234', 'Dinesh Dhanuka', 'working', NULL, 'Present'),
  ('member-010', 'VO-010', '1234', 'Preet', 'working', NULL, 'Present')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  role_id = EXCLUDED.role_id,
  pin_hash = EXCLUDED.pin_hash;


-- ------------------------------------------------------------------------------
-- 2. DELETE SEED DATA / CLEANUP DATA
-- (Uncomment and run the lines below whenever you want to wipe this seed data)
-- ------------------------------------------------------------------------------

/*
DELETE FROM public.members WHERE id IN (
  'member-001', 'member-002', 'member-003', 'member-004', 'member-005',
  'member-006', 'member-007', 'member-008', 'member-009', 'member-010'
);

DELETE FROM public.role_permissions WHERE role_id IN ('role-pm-001', 'role-oc-001', 'role-aoc-001');
DELETE FROM public.roles WHERE id IN ('role-pm-001', 'role-oc-001', 'role-aoc-001');
DELETE FROM public.permissions WHERE id = 'perm-ack-001';
*/
