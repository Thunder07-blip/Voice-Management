import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../app_drawer.dart';
import 'create_notice_sheet.dart';

class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    final hasAdminPerms = authState.hasPermission('manage_notices') || 
                          authState.currentRole?.name == 'Project Manager' || 
                          authState.currentRole?.name == 'Overall Coordinator' || 
                          authState.currentRole?.name == 'Assistant Overall Coordinator';

    final noticesAsync = ref.watch(noticesStreamProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Notices',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: noticesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (notices) {
          if (notices.isEmpty) {
            return Center(
              child: Text(
                'No notices posted yet.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final notice = notices[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (notice.department != null && notice.department!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              notice.department!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onPrimaryContainer,
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        Text(
                          DateFormat('MMM d, yyyy').format(notice.createdAt),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    if (notice.department != null && notice.department!.isNotEmpty)
                      const SizedBox(height: 12),
                    Text(
                      notice.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notice.content,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: hasAdminPerms ? FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: AppTheme.surfaceContainerLowest,
            builder: (_) => const CreateNoticeSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Notice'),
      ) : null,
    );
  }
}
