import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import 'roles_management_screen.dart';
import 'members_management_screen.dart';

class AdministrationScreen extends ConsumerStatefulWidget {
  const AdministrationScreen({super.key});

  @override
  ConsumerState<AdministrationScreen> createState() => _AdministrationScreenState();
}

class _AdministrationScreenState extends ConsumerState<AdministrationScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!authState.isAdminMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Administration')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Administration'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (authState.hasPermission('ADD_MEMBER') || authState.hasPermission('EDIT_MEMBER'))
            _AdminCard(
              title: 'Member Management',
              icon: Icons.group,
              description: 'Add, edit, or remove members, assign groups and roles.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MembersManagementScreen()),
                );
              },
            ),
          const SizedBox(height: 16),
          if (authState.hasPermission('ROLE_MANAGEMENT'))
            _AdminCard(
              title: 'Role Management',
              icon: Icons.shield,
              description: 'Create and configure roles and their permissions.',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RolesManagementScreen()),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String description;
  final VoidCallback onTap;

  const _AdminCard({
    required this.title,
    required this.icon,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
