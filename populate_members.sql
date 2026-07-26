BEGIN;
-- Wipe out old data
TRUNCATE TABLE public.members CASCADE;
TRUNCATE TABLE public.roles CASCADE;
TRUNCATE TABLE public.permissions CASCADE;

-- Create roles
INSERT INTO public.roles (id, name, description) VALUES ('R001', 'Overall Coordinator', 'System access.');
INSERT INTO public.roles (id, name, description) VALUES ('R002', 'Project Manager', 'Project access.');
INSERT INTO public.roles (id, name, description) VALUES ('R003', 'Assistant OC', 'Read access.');
INSERT INTO public.roles (id, name, description) VALUES ('R004', 'Kitchen Incharge', 'Kitchen access.');
INSERT INTO public.roles (id, name, description) VALUES ('R005', 'Chef', 'Chef access.');

-- Create permissions
INSERT INTO public.permissions (id, permission_key, description) VALUES ('P001', 'manage_members', 'Can manage members');
INSERT INTO public.permissions (id, permission_key, description) VALUES ('P002', 'manage_leaves', 'Can manage leaves');
INSERT INTO public.permissions (id, permission_key, description) VALUES ('P003', 'manage_tasks', 'Can manage tasks');
INSERT INTO public.permissions (id, permission_key, description) VALUES ('P004', 'post_notices', 'Can post notices');
INSERT INTO public.permissions (id, permission_key, description) VALUES ('P005', 'manage_meals', 'Can manage meals');
INSERT INTO public.permissions (id, permission_key, description) VALUES ('P006', 'view_meals', 'Can view meals');

-- Assign permissions to OC (R001)
INSERT INTO public.role_permissions (role_id, permission_id) VALUES ('R001', 'P001'), ('R001', 'P002'), ('R001', 'P003'), ('R001', 'P004');
-- Assign permissions to PM (R002)
INSERT INTO public.role_permissions (role_id, permission_id) VALUES ('R002', 'P002'), ('R002', 'P003'), ('R002', 'P004');
-- Assign permissions to AOC (R003)
INSERT INTO public.role_permissions (role_id, permission_id) VALUES ('R003', 'P003');
-- Assign permissions to Kitchen Incharge (R004)
INSERT INTO public.role_permissions (role_id, permission_id) VALUES ('R004', 'P004'), ('R004', 'P005'), ('R004', 'P006');
-- Assign permissions to Chef (R005)
INSERT INTO public.role_permissions (role_id, permission_id) VALUES ('R005', 'P006');

-- Insert Members
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV001', 'VV001', '3291', 'Rishikesh PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV002', 'VV002', '5582', 'Kabir PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV003', 'VV003', '6626', 'Sachin PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV004', 'VV004', '4031', 'Lawkush PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV005', 'VV005', '5046', 'Suraj Nawale PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV006', 'VV006', '5582', 'Vrindavan PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV007', 'VV007', '9768', 'Abhay PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV008', 'VV008', '7996', 'Navnath PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV009', 'VV009', '7581', 'Sarvesh PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV010', 'VV010', '4389', 'Prathamesh B PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV011', 'VV011', '5826', 'Sumrit PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV012', 'VV012', '4849', 'Shyamal PR', 'student', 'R005', 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV013', 'VV013', '2748', 'Jay PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV014', 'VV014', '2744', 'Bhagyesh PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV015', 'VV015', '7817', 'Atharva PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV016', 'VV016', '9072', 'Sushant PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV017', 'VV017', '5444', 'Soham PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV018', 'VV018', '5925', 'Deven PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV019', 'VV019', '4889', 'Prem PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV020', 'VV020', '5262', 'Sajal PR', 'student', 'R003', 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV021', 'VV021', '9550', 'Shreyash PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV022', 'VV022', '4384', 'Pratik PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV023', 'VV023', '2272', 'Dinesh PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV024', 'VV024', '8210', 'HG Sharanagati PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV025', 'VV025', '9773', 'HG Sadhana Priya PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV026', 'VV026', '2844', 'Piyush PR', 'student', 'R001', 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV027', 'VV027', '4645', 'HG Suryakant Prem PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV028', 'VV028', '5514', 'Swaroop PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV029', 'VV029', '4427', 'Om PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV030', 'VV030', '7400', 'Tushar PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV031', 'VV031', '8178', 'Yashraj PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV032', 'VV032', '9655', 'Aditya PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV033', 'VV033', '5763', 'Mayur PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV034', 'VV034', '7260', 'Rahul PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV035', 'VV035', '3274', 'Yuvraj PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV036', 'VV036', '5343', 'Rushikesh S PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV037', 'VV037', '7656', 'Omkar PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV038', 'VV038', '3728', 'Preet PR', 'student', NULL, 'Present');
INSERT INTO public.members (id, member_id, pin_hash, name, member_type, role_id, current_status) VALUES ('VV039', 'VV039', '7124', 'HG Radhapad Pankaj PR', 'student', 'R002', 'Present');
COMMIT;