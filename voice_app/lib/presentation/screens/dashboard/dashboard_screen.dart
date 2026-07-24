import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../members/members_screen.dart';
import '../members/member_profile_screen.dart';
import '../tasks/tasks_screen.dart';
import '../tasks/create_task_sheet.dart';
import '../auth/members_management_screen.dart';
import '../leave/leave_screen.dart';
import '../notices/create_notice_sheet.dart';
import '../incharges/incharges_screen.dart';
import '../app_drawer.dart';
import 'community_health_screen.dart';
import '../kitchen/meal_planning_screen.dart';
import 'create_acknowledgement_sheet.dart';
import 'package:intl/intl.dart';
import 'widgets/status_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    // Watch data streams
    final membersAsync = ref.watch(membersStreamProvider);
    final tasksAsync = ref.watch(tasksStreamProvider);
    final leavesAsync = ref.watch(leavesStreamProvider);

    final membersCount = membersAsync.value?.length ?? 0;
    
    // Compute Active Tasks (Pending or In Progress)
    final activeTasksCount = tasksAsync.value
            ?.where((t) => t.status == 'pending' || t.status == 'in_progress')
            .length ?? 0;

    // Compute On Leave (Approved leaves where today is between start and end date)
    // For MVP simplicity, we'll just check if status is 'approved' for now.
    final onLeaveCount = leavesAsync.value
            ?.where((l) => l.status == 'approved')
            .length ?? 0;

    // Dummy value for sick for now, as it requires a Community Health feature
    const sickCount = 2; 

    final hasAdminPerms = authState.hasPermission('manage_members') || 
                          authState.currentRole?.name == 'Project Manager' || 
                          authState.currentRole?.name == 'Overall Coordinator' || 
                          authState.currentRole?.name == 'Assistant Overall Coordinator';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Vedic Oasis',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                if (authState.currentMember != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MemberProfileScreen(
                      name: authState.currentMember!.name,
                      isSelf: true,
                    ),
                  ));
                }
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryContainer,
                child: Text(
                  authState.currentMember?.name.isNotEmpty == true 
                      ? authState.currentMember!.name[0].toUpperCase() 
                      : 'U',
                  style: TextStyle(
                    color: AppTheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusBanner(),
            // Welcome header
            Text(
              'Dashboard',
              style: theme.textTheme.displayLarge?.copyWith(
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Community overview at a glance',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards — Bento-style grid
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.group,
                    label: 'Members',
                    value: membersCount.toString(),
                    color: AppTheme.primaryContainer,
                    iconColor: AppTheme.onPrimaryContainer,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersScreen())),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.event_busy,
                    label: 'On Leave',
                    value: onLeaveCount.toString(),
                    color: AppTheme.tertiaryContainer,
                    iconColor: AppTheme.onTertiaryContainer,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaveScreen())),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Community Health Card
            _ModuleCard(
              title: 'Community Health',
              subtitle: 'View members needing attention',
              icon: Icons.favorite,
              color: AppTheme.errorContainer,
              iconColor: AppTheme.onErrorContainer,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityHealthScreen())),
            ),
            
            const SizedBox(height: 16),

            // Meal Planning Card
            _ModuleCard(
              title: 'Meal Planning',
              subtitle: 'Update your meals or view kitchen count',
              icon: Icons.restaurant,
              color: AppTheme.secondaryContainer,
              iconColor: AppTheme.onSecondaryContainer,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealPlanningScreen())),
            ),

            const SizedBox(height: 32),

            // Quick Actions
            if (hasAdminPerms) ...[
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.person_add, size: 16, color: AppTheme.onSurfaceVariant),
                    label: const Text('Add Member', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        builder: (_) => const MemberFormSheet(member: null),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.add_task, size: 16, color: AppTheme.onSurfaceVariant),
                    label: const Text('Create Task', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        builder: (_) => const CreateTaskSheet(),
                      );
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.campaign, size: 16, color: AppTheme.onSurfaceVariant),
                    label: const Text('Post Notice', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    backgroundColor: AppTheme.surfaceContainerHigh,
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        builder: (_) => const CreateNoticeSheet(),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Acknowledgement Board
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Acknowledgement Board',
                  style: theme.textTheme.titleLarge,
                ),
                if (authState.hasPermission('manage_acknowledgements') || 
                    ['Project Manager', 'Overall Coordinator', 'Assistant Overall Coordinator'].contains(authState.currentRole?.name))
                  IconButton.filledTonal(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: AppTheme.surfaceContainerLowest,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                        ),
                        builder: (context) => const CreateAcknowledgementSheet(),
                      );
                    },
                    icon: const Icon(Icons.add, size: 20),
                    tooltip: 'Post Acknowledgement',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ref.watch(acknowledgementsStreamProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (acks) {
                if (acks.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Text('No acknowledgements yet.', style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: acks.length,
                  itemBuilder: (context, index) {
                    final ack = acks[index];
                    final membersList = membersAsync.value ?? [];
                    final authorName = membersList.where((m) => m.id == ack.authorId).firstOrNull?.name ?? 'Unknown Member';

                    return InkWell(
                      onTap: () {
                        if (ack.taggedMemberIds.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No members tagged in this acknowledgement.')),
                          );
                          return;
                        }
                        
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(20),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceContainerLowest,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                                  boxShadow: const [BoxShadow(color: Color(0x14855300), blurRadius: 32, offset: Offset(0, 8))],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Header
                                    Container(
                                      height: 96,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFDECD2), // approx primaryContainer/20
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: AppTheme.secondaryContainer,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: AppTheme.surfaceContainerLowest, width: 4),
                                            boxShadow: AppTheme.softShadow,
                                          ),
                                          child: const Icon(Icons.task_alt, color: AppTheme.onSecondaryContainer, size: 28),
                                        ),
                                      ),
                                    ),
                                    // Body
                                    Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Appreciation!',
                                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            'Gratitude for your intentional service.',
                                            style: TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                          
                                          // Details Box
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: AppTheme.surfaceContainerLow,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('SEVA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary, letterSpacing: 0.5)),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.cleaning_services, color: AppTheme.secondary, size: 20),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        ack.content,
                                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppTheme.onSurface),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                const Text('ACKNOWLEDGED MEMBERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant, letterSpacing: 0.5)),
                                                const SizedBox(height: 12),
                                                ...ack.taggedMemberIds.map((id) {
                                                  final name = membersList.where((m) => m.id == id).firstOrNull?.name ?? 'Unknown Member';
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 12),
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                          radius: 16,
                                                          backgroundColor: AppTheme.surfaceContainerHigh,
                                                          child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: AppTheme.onSurface, fontSize: 12, fontWeight: FontWeight.bold)),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(child: Text(name, style: const TextStyle(fontSize: 16, color: AppTheme.onSurface))),
                                                        const Icon(Icons.verified, color: AppTheme.secondary, size: 16),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          
                                          // Action
                                          SizedBox(
                                            width: double.infinity,
                                            height: 56,
                                            child: FilledButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: AppTheme.primaryContainer,
                                                foregroundColor: AppTheme.onPrimaryContainer,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                              ),
                                              child: const Text('Jai Ho!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stars, color: Colors.orange, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ack.content,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'By $authorName',
                                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                              ),
                              Text(
                                DateFormat('MMM d, h:mm a').format(ack.createdAt),
                                style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ));
                  },
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.onSurface,
                    fontSize: 32,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: iconColor, size: 16),
          ],
        ),
      ),
    );
  }
}
