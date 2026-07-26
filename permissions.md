# Voice Manager permissions

The application uses role-based access control (RBAC). A member receives the permissions assigned to their `role_id`; a member without a role is a Standard Member and has no elevated permission.

## Role Hierarchy
The application follows a strict management hierarchy:

1. **Project Manager (PM)**
2. **Overall Coordinator (OC)**
3. **Assistant Overall Coordinator (AOC)**
4. **Kitchen Incharge**
5. **Chef**
6. **Member**

### Hierarchy Rules
- **PM, OC, and AOC** all have ALL functional permissions in the system.
- **Project Manager (PM)** has absolute authority over role assignment. A PM can assign ANY role to ANY user.
- **Overall Coordinator (OC)** and **Assistant Overall Coordinator (AOC)** can assign roles to normal members, but **cannot edit or assign** the PM, OC, or AOC roles. They will not even see these roles in the assignment dropdown. 

## Permission Assignments (Current State)

### Project Manager
- `manage_members`
- `manage_leaves`
- `manage_tasks`
- `manage_meals`
- `view_meals`
- `manage_notices`
- `manage_roles`
- `manage_acknowledgements`

### Overall Coordinator
- `manage_members`
- `manage_leaves`
- `manage_tasks`
- `manage_meals`
- `view_meals`
- `manage_notices`
- `manage_roles`
- `manage_acknowledgements`

### Assistant Overall Coordinator (AOC)
- `manage_members`
- `manage_leaves`
- `manage_tasks`
- `manage_meals`
- `view_meals`
- `manage_notices`
- `manage_roles`
- `manage_acknowledgements`

| ID | Role | Intended access |
| --- | --- | --- |
| `R0004` | Kitchen Incharge | Manages meal planning and kitchen notices. |
| `R0005` | Chef | Views kitchen meal requirements only. |
| _(no role)_ | Standard Member | Uses their own profile, meals, tasks, and leave requests only. |

## Permission keys

| ID | Permission key | Allows |
| --- | --- | --- |
| `P0001` | `manage_members` | Create, edit, and remove members. |
| `P0002` | `manage_roles` | Create roles and change role-permission assignments. |
| `P0003` | `manage_leaves` | View all leave requests and approve or reject them. |
| `P0004` | `manage_tasks` | Create, assign, update, and remove community tasks. |
| `P0005` | `post_notices` | Publish community notices. |
| `P0006` | `manage_meals` | Manage meal planning and kitchen operations. |
| `P0007` | `view_meals` | View kitchen meal requirements and attendance. |
| `P0008` | `manage_health` | Report and update health records. |
| `P0009` | `manage_acknowledgements` | Post and manage acknowledgements. |

## Role matrix

| Permission | PM | OC | AOC | Kitchen Incharge | Chef | Standard Member |
| --- | :---: | :---: | :---: | :---: | :---: | :---: |
| `manage_members` | ✓ | ✓ | — | — | — | — |
| `manage_roles` | ✓ | — | — | — | — | — |
| `manage_leaves` | ✓ | ✓ | ✓ | — | — | — |
| `manage_tasks` | ✓ | ✓ | ✓ | — | — | — |
| `post_notices` | ✓ | ✓ | ✓ | ✓ | — | — |
| `manage_meals` | ✓ | ✓ | — | ✓ | — | — |
| `view_meals` | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| `manage_health` | ✓ | ✓ | ✓ | — | — | — |
| `manage_acknowledgements` | ✓ | ✓ | ✓ | — | — | — |

## Enforcement and synchronization

- Supabase is the shared source of truth. Phones pull roles, permissions, and role assignments before auto-login, then stay current through Realtime.
- The local Drift database is an offline cache. Each edit is written locally first, queued in the outbox, and sent when connectivity returns.
- Realtime changes never overwrite a row that has pending local work. After a successful sync, the app reconciles deletions that occurred while the phone was offline.
- The interface uses the keys above for button visibility and actions. For example, only `manage_leaves` can approve or reject leave; only `post_notices` can publish a notice.
- A pending leave request creates a coordinator-only in-app alert and an Android system notification on currently connected coordinator devices. The notification is local to each phone, so its read state is private.

## Important backend note

The current app uses Member ID + PIN rather than Supabase Auth. The existing anonymous Supabase policy remains compatible with this login design, but it cannot provide server-enforced per-user authorization by itself. Do not treat the mobile UI permission checks as protection against a user calling Supabase directly. Moving to Supabase Auth and role-aware RLS is required before exposing the app to untrusted users.
