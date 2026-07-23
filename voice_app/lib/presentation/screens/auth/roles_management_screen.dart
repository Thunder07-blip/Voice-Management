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
  void _showCreateRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => const _CreateRoleDialog(),
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
            onPressed: _showCreateRoleDialog,
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      // Delete Role logic (Offline outbox sync)
                      final db = ref.read(databaseProvider);
                      final syncEngine = ref.read(syncEngineProvider);
                      
                      await syncEngine.queueOperation(
                        table: 'roles',
                        operation: 'delete',
                        data: {'id': role.id},
                      );
                      await db.rolesTable.deleteWhere((t) => t.id.equals(role.id));
                    },
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

class _CreateRoleDialog extends ConsumerStatefulWidget {
  const _CreateRoleDialog();

  @override
  ConsumerState<_CreateRoleDialog> createState() => _CreateRoleDialogState();
}

class _CreateRoleDialogState extends ConsumerState<_CreateRoleDialog> {
  final _nameController = TextEditingController();

  final List<String> _availablePermissions = [
    'CREATE_TASKS',
    'UPDATE_TASKS',
    'DELETE_TASKS',
    'POST_NOTICES',
    'DELETE_NOTICES',
  ];

  final Set<String> _selectedPermissions = {};

  void _saveRole() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);
    final roleId = const Uuid().v4();

    // Insert Role
    final roleData = {
      'id': roleId,
      'name': name,
    };

    await syncEngine.queueOperation(
      table: 'roles',
      operation: 'insert',
      data: roleData,
    );

    await db.into(db.rolesTable).insert(
      RolesTableCompanion.insert(
        id: roleId,
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Insert Permissions
    for (final perm in _selectedPermissions) {
      // In a robust system, we would lookup the actual permission ID from PermissionsTable.
      // For MVP, we can insert or use the permission string itself as the ID since it acts like an ENUM.
      // But the schema specifies permissionId. Let's create it if it doesn't exist.
      
      final permId = const Uuid().v4();
      await db.into(db.permissionsTable).insert(
        PermissionsTableCompanion.insert(
          id: permId,
          permissionKey: perm,
        ),
        mode: drift.InsertMode.insertOrIgnore,
      );
      
      await db.into(db.rolePermissionsTable).insert(
        RolePermissionsTableCompanion.insert(
          roleId: roleId,
          permissionId: permId,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Role'),
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
