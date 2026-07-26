import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import 'widgets/leave_card.dart';
import 'leave_request_sheet.dart';

import '../../../core/services/leave_sync_service.dart';

class LeaveScreen extends ConsumerStatefulWidget {
  const LeaveScreen({super.key});

  @override
  ConsumerState<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends ConsumerState<LeaveScreen> {
  @override
  void initState() {
    super.initState();
    // Run the check quietly when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(leaveSyncServiceProvider).checkAndActivateUpcomingLeaves();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final leavesAsync = ref.watch(leavesStreamProvider);

    final isCoordinator = authState.hasPermission('manage_leaves');

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leave Management'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Upcoming'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: leavesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading leaves: $err')),
          data: (leaves) {
            final pendingLeaves = leaves.where((l) => l.status == 'pending').toList();
            final upcomingLeaves = leaves.where((l) => l.status == 'approved').toList();
            final activeLeaves = leaves.where((l) => l.status == 'active').toList();
            final historyLeaves = leaves.where((l) => l.status == 'rejected' || l.status == 'completed').toList();

            return TabBarView(
              children: [
                _LeaveList(leaves: pendingLeaves, isCoordinator: isCoordinator, emptyMessage: 'No pending leave requests.'),
                _LeaveList(leaves: upcomingLeaves, isCoordinator: isCoordinator, emptyMessage: 'No upcoming leaves.'),
                _LeaveList(leaves: activeLeaves, isCoordinator: isCoordinator, emptyMessage: 'No members currently active on leave.'),
                _LeaveList(leaves: historyLeaves, isCoordinator: isCoordinator, emptyMessage: 'No leave history found.'),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
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
        ),
      ),
    );
  }
}

class _LeaveList extends ConsumerWidget {
  final List<dynamic> leaves;
  final bool isCoordinator;
  final String emptyMessage;

  const _LeaveList({
    required this.leaves,
    required this.isCoordinator,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (leaves.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref.read(leaveSyncServiceProvider).checkAndActivateUpcomingLeaves();
          await ref.read(syncEngineProvider).pullRemoteChanges();
        },
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(leaveSyncServiceProvider).checkAndActivateUpcomingLeaves();
        await ref.read(syncEngineProvider).pullRemoteChanges();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: leaves.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return LeaveCard(
            leave: leaves[index],
            isCoordinator: isCoordinator,
          );
        },
      ),
    );
  }
}
