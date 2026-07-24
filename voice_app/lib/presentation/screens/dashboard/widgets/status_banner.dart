import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/leave_sync_service.dart';
import '../../leave/leave_request_sheet.dart'; // Just using the sheet or a custom one for update

class StatusBanner extends ConsumerWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final memberId = authState.currentMember?.id;

    if (memberId == null) return const SizedBox.shrink();

    // Watch the current member to get real-time currentStatus
    final membersAsync = ref.watch(membersStreamProvider);
    final memberList = membersAsync.value ?? [];
    final currentMemberData = memberList.where((m) => m.id == memberId).firstOrNull;
    
    if (currentMemberData == null) return const SizedBox.shrink();

    final isAway = currentMemberData.currentStatus == 'Away';

    if (!isAway) {
      return Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceContainerHigh),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              'Status: Present',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }

    // If away, fetch their active leave to show expected return
    final leavesAsync = ref.watch(leavesStreamProvider);
    final activeLeave = leavesAsync.value?.where((l) => l.memberId == memberId && l.status == 'active').firstOrNull;

    String returnText = 'Unknown';
    if (activeLeave?.endDate != null) {
      try {
        final date = DateTime.parse(activeLeave!.endDate!);
        returnText = DateFormat('MMM d, yyyy h:mm a').format(date);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.tertiary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_takeoff, color: AppTheme.onTertiaryContainer),
              const SizedBox(width: 12),
              Text(
                'Status: Away on Leave',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Expected Return: $returnText',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onTertiaryContainer,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    if (activeLeave != null) {
                      _showUpdateReturnSheet(context, ref, activeLeave);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.surface.withOpacity(0.5),
                    foregroundColor: AppTheme.onTertiaryContainer,
                  ),
                  child: const Text('Update Return'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    if (activeLeave != null) {
                      final syncService = ref.read(leaveSyncServiceProvider);
                      await syncService.confirmReturn(activeLeave);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Welcome back! Meal planning is open.')),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.tertiary,
                    foregroundColor: AppTheme.onTertiary,
                  ),
                  child: const Text('I Have Returned'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUpdateReturnSheet(BuildContext context, WidgetRef ref, dynamic activeLeave) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      builder: (ctx) => _UpdateReturnSheet(activeLeave: activeLeave),
    );
  }
}

class _UpdateReturnSheet extends ConsumerStatefulWidget {
  final dynamic activeLeave;
  const _UpdateReturnSheet({required this.activeLeave});

  @override
  ConsumerState<_UpdateReturnSheet> createState() => _UpdateReturnSheetState();
}

class _UpdateReturnSheetState extends ConsumerState<_UpdateReturnSheet> {
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.activeLeave.endDate != null) {
      try {
        final date = DateTime.parse(widget.activeLeave.endDate!);
        _returnDate = date;
        _returnTime = TimeOfDay.fromDateTime(date);
      } catch (_) {}
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _returnDate = picked);
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _returnTime = picked);
  }

  void _submit() async {
    if (_returnDate == null || _returnTime == null) return;
    setState(() => _isLoading = true);

    final returnDateTime = DateTime(
      _returnDate!.year, _returnDate!.month, _returnDate!.day,
      _returnTime!.hour, _returnTime!.minute,
    );

    final syncService = ref.read(leaveSyncServiceProvider);
    await syncService.updateExpectedReturn(widget.activeLeave, returnDateTime);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Update Return Date',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('New Expected Return', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_returnDate == null ? 'Date' : dateFormat.format(_returnDate!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _selectTime,
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_returnTime == null ? 'Time' : _returnTime!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Update & Recalculate Meals'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
