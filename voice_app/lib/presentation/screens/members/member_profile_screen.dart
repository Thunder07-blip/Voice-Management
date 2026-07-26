import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart';
import '../auth/members_management_screen.dart';
import '../tasks/create_task_sheet.dart';
import 'self_edit_profile_sheet.dart';

class MemberProfileScreen extends ConsumerWidget {
  final String name;
  final String? memberId; // Made optional so mock members don't break
  final bool isSelf;

  const MemberProfileScreen({
    super.key, 
    required this.name,
    this.memberId,
    this.isSelf = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersList = ref.watch(membersStreamProvider).value ?? [];
    final groupsList = ref.watch(groupsStreamProvider).value ?? [];
    final authState = ref.watch(authProvider);

    Member? actualMember;
    if (memberId != null) {
      actualMember = membersList.where((m) => m.id == memberId).firstOrNull;
    }

    String displayName = actualMember?.name ?? name;
    String displayCollege = actualMember?.college ?? 'N/A';
    String displayMemberType = (actualMember?.memberType ?? 'Student');
    if (displayMemberType.isEmpty) displayMemberType = 'Student';
    displayMemberType = displayMemberType[0].toUpperCase() + displayMemberType.substring(1);
    
    String displayYear = actualMember?.year ?? 'N/A';
    String currentStatus = actualMember?.currentStatus ?? 'Present';

    String displayGroupName = 'None';
    if (actualMember?.groupId != null) {
      final group = groupsList.where((g) => g.id == actualMember!.groupId).firstOrNull;
      if (group != null) displayGroupName = group.name;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vedic Oasis',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // Header Section
            Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surface, width: 4),
                        boxShadow: AppTheme.softShadow,
                        color: AppTheme.surfaceContainer,
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(fontSize: 48, color: AppTheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -8,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppTheme.surface, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school, size: 14, color: AppTheme.onSecondary),
                            const SizedBox(width: 4),
                            Text(
                              displayMemberType,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.onSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: AppTheme.onSurface,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$displayYear • $displayGroupName',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: currentStatus == 'Present' ? AppTheme.secondary : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        currentStatus,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Information Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Member Details',
                    style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailItem(label: 'INSTITUTION', value: displayCollege),
                            const SizedBox(height: 16),
                            _DetailItem(label: 'MEMBER TYPE', value: displayMemberType),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DetailItem(label: 'YEAR', value: displayYear),
                            const SizedBox(height: 16),
                            _DetailItem(label: 'GROUP', value: displayGroupName),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Assigned Tasks
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assigned Tasks', style: theme.textTheme.titleLarge),
                if (memberId != null)
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All',
                      style: theme.textTheme.labelLarge?.copyWith(color: AppTheme.primary),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (memberId == null)
              const Text('No active assigned tasks.', style: TextStyle(color: AppTheme.onSurfaceVariant))
            else
              ref.watch(tasksStreamProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading tasks: $err')),
                data: (tasks) {
                  final memberTasks = tasks.where((t) => t.assignedTo == memberId).take(2).toList();
                  if (memberTasks.isEmpty) {
                    return const Text('No active assigned tasks.', style: TextStyle(color: AppTheme.onSurfaceVariant));
                  }
                  return Row(
                    children: memberTasks.map((task) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _TaskCard(
                            title: task.title,
                            priority: task.priority,
                            dueDate: task.dueDate != null ? DateFormat('MMM d').format(DateTime.parse(task.dueDate!)) : 'No Date',
                            status: task.status,
                            icon: task.status == 'Completed' ? Icons.check_circle : Icons.pending_actions,
                            iconColor: task.status == 'Completed' ? AppTheme.secondary : AppTheme.onSurfaceVariant,
                            isCompleted: task.status == 'Completed',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            const SizedBox(height: 24),

            // Acknowledgements Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acknowledgements',
                    style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.onSurface),
                  ),
                  const SizedBox(height: 24),
                  if (memberId == null)
                    const Text('No acknowledgements yet.', style: TextStyle(color: AppTheme.onSurfaceVariant))
                  else
                    ref.watch(acknowledgementsStreamProvider).when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Text('Error: $err'),
                      data: (acks) {
                        final memberAcks = acks.where((a) => a.taggedMemberIds.contains(memberId)).toList();
                        
                        if (memberAcks.isEmpty) {
                          return const Text('No acknowledgements yet.', style: TextStyle(color: AppTheme.onSurfaceVariant));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: memberAcks.length,
                          itemBuilder: (context, index) {
                            final ack = memberAcks[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.stars, color: Colors.orange, size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ack.content,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          DateFormat('MMM d, yyyy - h:mm a').format(ack.createdAt),
                                          style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Bottom Actions
            if (isSelf && actualMember != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: AppTheme.surfaceContainerLowest,
                      builder: (_) => SelfEditProfileSheet(member: actualMember!),
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              )
            else if (!isSelf && actualMember != null)
              Column(
                children: [
                  if (authState.hasPermission('manage_tasks'))
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: AppTheme.surfaceContainerLowest,
                            builder: (_) => CreateTaskSheet(
                              preSelectedAssigneeId: actualMember!.id,
                              preSelectedAssigneeName: actualMember!.name,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_task),
                        label: const Text('Assign Task'),
                      ),
                    ),
                  if (authState.hasPermission('manage_members')) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            backgroundColor: AppTheme.surfaceContainerLowest,
                            builder: (_) => MemberFormSheet(member: actualMember!),
                          );
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit Member'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;

  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurface,
              ),
        ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final String title;
  final String priority;
  final String dueDate;
  final String status;
  final IconData icon;
  final Color iconColor;
  final bool isCompleted;

  const _TaskCard({
    required this.title,
    required this.priority,
    required this.dueDate,
    required this.status,
    required this.icon,
    required this.iconColor,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 176,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.surfaceVariant : AppTheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted ? AppTheme.onSurfaceVariant : AppTheme.onErrorContainer,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            runSpacing: 4,
            spacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Due: $dueDate',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.secondaryContainer : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: isCompleted ? AppTheme.onSecondaryContainer : AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTimelineItem extends StatelessWidget {
  final IconData icon;
  final String content;
  final String time;
  final bool isFirst;
  final bool isLast;

  const _ActivityTimelineItem({
    required this.icon,
    required this.content,
    required this.time,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isFirst ? AppTheme.primaryContainer : AppTheme.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surfaceContainerLowest, width: 2),
              ),
              child: Icon(
                icon,
                size: 14,
                color: isFirst ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 48,
                color: AppTheme.surfaceVariant,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(content, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
