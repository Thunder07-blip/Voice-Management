import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/local/database.dart';

class RolesManagementScreen extends ConsumerStatefulWidget {
  const RolesManagementScreen({super.key});

  @override
  ConsumerState<RolesManagementScreen> createState() => _RolesManagementScreenState();
}

class _RolesManagementScreenState extends ConsumerState<RolesManagementScreen> {
  void _showRoleDialog({Role? role}) {
    showDialog(
      context: context,
      builder: (context) => _RoleDialog(role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesStreamProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Role Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showRoleDialog(),
          ),
        ],
      ),
      body: rolesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (roles) {
          if (roles.isEmpty) {
            return const Center(child: Text('No roles created yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: roles.length,
            itemBuilder: (context, index) {
              final role = roles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.outlineVariant),
                ),
                color: AppTheme.surfaceContainerLowest,
                child: ListTile(
                  title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(role.description ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showRoleDialog(role: role),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Delete Role logic (Offline outbox sync)
                          final db = ref.read(databaseProvider);
                          final syncEngine = ref.read(syncEngineProvider);
                          
                          await (db.delete(db.rolesTable)..where((t) => t.id.equals(role.id))).go();
                          await syncEngine.queueOperation(
                            table: 'roles',
                            operation: 'delete',
                            data: {'id': role.id},
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RoleDialog extends ConsumerStatefulWidget {
  final Role? role;
  const _RoleDialog({this.role});

  @override
  ConsumerState<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends ConsumerState<_RoleDialog> {
  final _nameController = TextEditingController();

  final List<String> _availablePermissions = [
    'manage_members',
    'manage_roles',
    'manage_leaves',
    'manage_tasks',
    'manage_notices',
    'manage_meals',
    'view_meals',
    'manage_health',
    'manage_acknowledgements',
  ];

  final Set<String> _selectedPermissions = {};

  @override
  void initState() {
    super.initState();
    if (widget.role != null) {
      _nameController.text = widget.role!.name;
      _loadExistingPermissions();
    }
  }

  Future<void> _loadExistingPermissions() async {
    final db = ref.read(databaseProvider);
    final rolePerms = await (db.select(db.rolePermissionsTable)..where((t) => t.roleId.equals(widget.role!.id))).get();
    final allPerms = await db.select(db.permissionsTable).get();
    
    setState(() {
      for (final rp in rolePerms) {
        final p = allPerms.where((p) => p.id == rp.permissionId).firstOrNull;
        if (p != null) {
          _selectedPermissions.add(p.permissionKey);
        }
      }
    });
  }

  void _saveRole() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);
    final roleId = widget.role?.id ?? const Uuid().v4();
    final isNew = widget.role == null;
    final now = DateTime.now();

    // Upsert Role
    final roleData = {
      'id': roleId,
      'name': name,
      'description': null,
      if (isNew) 'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    await db.into(db.rolesTable).insertOnConflictUpdate(
      RolesTableCompanion.insert(
        id: roleId,
        name: name,
        createdAt: isNew ? now : widget.role!.createdAt,
        updatedAt: now,
      ),
    );
    await syncEngine.queueOperation(
      table: 'roles',
      operation: isNew ? 'insert' : 'update',
      data: roleData,
    );

    // Delete existing permissions for this role if editing
    if (!isNew) {
      await (db.delete(db.rolePermissionsTable)..where((t) => t.roleId.equals(roleId))).go();
      // In a real robust sync we would compute a diff. For now we can queue a delete via REST or just queue inserts and rely on backend resolving.
      // Easiest is to queue a delete for all role permissions for this role, but SyncEngine outbox expects exact ID deletes. 
      // We will assume backend handles upsert merging gracefully.
    }

    // Insert Permissions
    for (final perm in _selectedPermissions) {
      final existing = await (db.select(db.permissionsTable)
            ..where((item) => item.permissionKey.equals(perm)))
          .getSingleOrNull();
      final permId = existing?.id ?? const Uuid().v4();
      if (existing == null) {
        await db.into(db.permissionsTable).insert(
          PermissionsTableCompanion.insert(
            id: permId,
            permissionKey: perm,
          ),
        );
        await syncEngine.queueOperation(
          table: 'permissions',
          operation: 'insert',
          data: {'id': permId, 'permissionKey': perm, 'description': null},
        );
      }
      
      await db.into(db.rolePermissionsTable).insert(
        RolePermissionsTableCompanion.insert(
          roleId: roleId,
          permissionId: permId,
        ),
      );
      await syncEngine.queueOperation(
        table: 'role_permissions',
        operation: 'insert',
        data: {'roleId': roleId, 'permissionId': permId},
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.role == null ? 'Create New Role' : 'Edit Role'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Role Name (e.g. Kitchen Incharge)'),
            ),
            const SizedBox(height: 16),
            const Text('Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: _availablePermissions.map((perm) {
                  final isSelected = _selectedPermissions.contains(perm);
                  return CheckboxListTile(
                    title: Text(perm.replaceAll('_', ' ')),
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedPermissions.add(perm);
                        } else {
                          _selectedPermissions.remove(perm);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saveRole,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
