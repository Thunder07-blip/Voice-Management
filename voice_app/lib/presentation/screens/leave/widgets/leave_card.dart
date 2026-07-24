import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import '../../../../core/theme/app_theme.dart';
import '../../../../data/local/database.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/services/leave_sync_service.dart';

class LeaveCard extends ConsumerWidget {
  final LeaveRequest leave;
  final bool isCoordinator;

  const LeaveCard({
    super.key,
    required this.leave,
    required this.isCoordinator,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersStreamProvider);
    final memberName = membersAsync.value
            ?.firstWhere((m) => m.id == leave.memberId)
            .name ?? 'Unknown Member';

    final bool isPending = leave.status == 'pending';
    final bool isApproved = leave.status == 'approved';

    // Helper to format the dates elegantly
    String formatLeaveDate(String isoString) {
      try {
        final dt = DateTime.parse(isoString);
        return DateFormat('d MMM • h:mm a').format(dt);
      } catch (_) {
        return isoString;
      }
    }

    return Container(
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
            children: [
              const Icon(Icons.person, size: 18, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  memberName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending 
                      ? const Color(0xFFFFDDB8) 
                      : (isApproved ? AppTheme.primaryContainer : AppTheme.surfaceContainerHigh),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  leave.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPending 
                        ? const Color(0xFF2A1700)
                        : (isApproved ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            leave.reason ?? 'No reason provided',
            style: const TextStyle(fontSize: 15, color: AppTheme.onSurface),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Leaving', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(formatLeaveDate(leave.startDate), style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: AppTheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Returning', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(formatLeaveDate(leave.endDate ?? ''), style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          
          if (isCoordinator && isPending) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateStatus(ref, 'rejected'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _updateStatus(ref, 'approved'),
                    style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _updateStatus(WidgetRef ref, String newStatus) async {
    final syncService = ref.read(leaveSyncServiceProvider);
    final approverId = ref.read(authProvider).currentMember?.id ?? '';

    if (newStatus == 'approved') {
      await syncService.approveLeave(leave, approverId);
    } else if (newStatus == 'rejected') {
      await syncService.rejectLeave(leave, approverId);
    }
  }
}
