import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import 'widgets/leave_card.dart';
import 'leave_request_sheet.dart';

class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final leavesAsync = ref.watch(leavesStreamProvider);

    final isCoordinator = authState.hasPermission('manage_members') || 
                          authState.currentRole?.name == 'Project Manager' || 
                          authState.currentRole?.name == 'Overall Coordinator' || 
                          authState.currentRole?.name == 'Assistant Overall Coordinator';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leave Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Approved'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: leavesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading leaves: $err')),
          data: (leaves) {
            final pendingLeaves = leaves.where((l) => l.status == 'pending').toList();
            final approvedLeaves = leaves.where((l) => l.status == 'approved').toList();
            final historyLeaves = leaves.where((l) => l.status == 'rejected' || l.status == 'completed').toList(); // 'completed' implies they returned

            return TabBarView(
              children: [
                _LeaveList(leaves: pendingLeaves, isCoordinator: isCoordinator, emptyMessage: 'No pending leave requests.'),
                _LeaveList(leaves: approvedLeaves, isCoordinator: isCoordinator, emptyMessage: 'No members currently on leave.'),
                _LeaveList(leaves: historyLeaves, isCoordinator: isCoordinator, emptyMessage: 'No leave history found.'),
              ],
            );
          },
        ),
        floatingActionButton: !isCoordinator ? FloatingActionButton.extended(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              backgroundColor: AppTheme.surfaceContainerLowest,
              builder: (_) => const LeaveRequestSheet(),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Request Leave'),
        ) : null,
      ),
    );
  }
}

class _LeaveList extends StatelessWidget {
  final List<dynamic> leaves;
  final bool isCoordinator;
  final String emptyMessage;

  const _LeaveList({
    required this.leaves,
    required this.isCoordinator,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (leaves.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppTheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: leaves.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return LeaveCard(
          leave: leaves[index],
          isCoordinator: isCoordinator,
        );
      },
    );
  }
}
