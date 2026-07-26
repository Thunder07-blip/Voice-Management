import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/local/database.dart';

class LeaveRequestSheet extends ConsumerStatefulWidget {
  const LeaveRequestSheet({super.key});

  @override
  ConsumerState<LeaveRequestSheet> createState() => _LeaveRequestSheetState();
}

class _LeaveRequestSheetState extends ConsumerState<LeaveRequestSheet> {
  final _reasonController = TextEditingController();
  
  DateTime? _leaveDate;
  TimeOfDay? _leaveTime;
  
  DateTime? _returnDate;
  TimeOfDay? _returnTime;

  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isLeaving) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isLeaving) _leaveDate = picked;
        else _returnDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isLeaving) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isLeaving) _leaveTime = picked;
        else _returnTime = picked;
      });
    }
  }

  void _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _errorText = 'Please provide a reason');
      return;
    }
    if (_leaveDate == null || _leaveTime == null || _returnDate == null || _returnTime == null) {
      setState(() => _errorText = 'Please complete all date and time fields');
      return;
    }

    final leaveDateTime = DateTime(
      _leaveDate!.year, _leaveDate!.month, _leaveDate!.day,
      _leaveTime!.hour, _leaveTime!.minute,
    );
    final returnDateTime = DateTime(
      _returnDate!.year, _returnDate!.month, _returnDate!.day,
      _returnTime!.hour, _returnTime!.minute,
    );

    if (returnDateTime.isBefore(leaveDateTime)) {
      setState(() => _errorText = 'Returning time must be after leaving time');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final member = ref.read(authProvider).currentMember;
    if (member == null) {
      setState(() { _errorText = 'Authentication error. Please log in again.'; _isLoading = false; });
      return;
    }

    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);
    
    final leaveId = const Uuid().v4();
    final now = DateTime.now();

    final leaveData = {
      'id': leaveId,
      'member_id': member.id,
      'reason': _reasonController.text.trim(),
      'start_date': leaveDateTime.toIso8601String(),
      'end_date': returnDateTime.toIso8601String(),
      'status': 'pending',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    // Insert locally for immediate UI update
    await db.into(db.leavesTable).insert(
      LeavesTableCompanion.insert(
        id: leaveId,
        memberId: member.id,
        reason: drift.Value(_reasonController.text.trim()),
        startDate: leaveDateTime.toIso8601String(),
        endDate: drift.Value(returnDateTime.toIso8601String()),
        status: const drift.Value('pending'),
        createdAt: now,
        updatedAt: now,
      )
    );

    // Queue only after the local write has completed. This makes the insert
    // safe when an online Realtime event returns immediately.
    await syncEngine.queueOperation(
      table: 'leaves',
      operation: 'insert',
      data: leaveData,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request submitted')));
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
                'Request Leave',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_errorText != null) ...[
            Text(_errorText!, style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _reasonController,
            decoration: InputDecoration(
              labelText: 'Reason (e.g., Going Home)',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),

          const Text('Leaving', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _selectDate(true),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_leaveDate == null ? 'Date' : dateFormat.format(_leaveDate!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _selectTime(true),
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_leaveTime == null ? 'Time' : _leaveTime!.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Returning', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _selectDate(false),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_returnDate == null ? 'Date' : dateFormat.format(_returnDate!)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _selectTime(false),
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
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
