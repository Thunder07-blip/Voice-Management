import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';

class InchargesScreen extends ConsumerStatefulWidget {
  const InchargesScreen({super.key});

  @override
  ConsumerState<InchargesScreen> createState() => _InchargesScreenState();
}

class _InchargesScreenState extends ConsumerState<InchargesScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(membersStreamProvider);
    final rolesAsync = ref.watch(rolesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Incharges',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading incharges')),
        data: (members) {
          return rolesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading roles')),
            data: (roles) {
              // 1. Filter out members who have NO role (they are not incharges)
              final incharges = members.where((m) => m.roleId != null).toList();

              // 2. Map roleIds to actual Role names
              final rolesMap = {for (var r in roles) r.id: r.name};

              // 3. Search Filter
              final query = _searchController.text.toLowerCase();
              final displayedIncharges = incharges.where((incharge) {
                final roleName = rolesMap[incharge.roleId] ?? 'Unknown Role';
                final nameMatches = incharge.name.toLowerCase().contains(query);
                final roleMatches = roleName.toLowerCase().contains(query);
                return nameMatches || roleMatches;
              }).toList();

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or role...',
                        prefixIcon: Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${displayedIncharges.length} Incharges Found',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: displayedIncharges.isEmpty 
                        ? const Center(child: Text('No incharges found.'))
                        : ListView.separated(
                          itemCount: displayedIncharges.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final incharge = displayedIncharges[index];
                            final roleName = rolesMap[incharge.roleId] ?? 'Unknown Role';
                            
                            // Safe initial extraction
                            final initial = incharge.name.trim().isNotEmpty
                                ? incharge.name.trim()[0].toUpperCase()
                                : 'I';

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceContainerLowest,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: AppTheme.secondaryContainer,
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: AppTheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          incharge.name,
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontSize: 18,
                                            color: AppTheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          roleName,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: AppTheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
