import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  final Task task;
  
  const TaskDetailScreen({super.key, required this.task});

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _isUpdating = false;

  Future<void> _toggleStatus() async {
    setState(() => _isUpdating = true);
    try {
      final db = ref.read(databaseProvider);
      final newStatus = widget.task.status == 'completed' ? 'pending' : 'completed';
      final updated = widget.task.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await db.update(db.tasksTable).replace(updated);
      await ref.read(syncEngineProvider).queueOperation(
        table: 'tasks',
        operation: 'update',
        data: {
          'id': updated.id,
          'title': updated.title,
          'description': updated.description,
          'priority': updated.priority,
          'status': updated.status,
          'dueDate': updated.dueDate,
          'createdBy': updated.createdBy,
          'assignedTo': updated.assignedTo,
          'createdAt': updated.createdAt.toIso8601String(),
          'updatedAt': updated.updatedAt.toIso8601String(),
          'deletedAt': updated.deletedAt?.toIso8601String(),
        },
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteTask() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete')
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(databaseProvider);
      await (db.delete(db.tasksTable)..where((t) => t.id.equals(widget.task.id))).go();
      await ref.read(syncEngineProvider).queueOperation(
        table: 'tasks',
        operation: 'delete',
        data: {'id': widget.task.id},
      );
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersList = ref.watch(membersStreamProvider).value ?? [];
    
    final createdByMember = membersList.where((m) => m.id == widget.task.createdBy).firstOrNull;
    final createdByName = createdByMember?.name ?? widget.task.createdBy ?? 'System';
    
    final assignedToMember = membersList.where((m) => m.id == widget.task.assignedTo).firstOrNull;
    final assignedToName = assignedToMember?.name ?? 'Unassigned';

    final authState = ref.watch(authProvider);
    final canManageTask = authState.hasPermission('manage_tasks') ||
                          widget.task.assignedTo == authState.currentMember?.id;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Task Details'),
        backgroundColor: AppTheme.surface,
        actions: [
          if (canManageTask)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              onPressed: _deleteTask,
              tooltip: 'Delete Task',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Hero Section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${widget.task.priority.toUpperCase()} PRIORITY',
                    style: const TextStyle(color: AppTheme.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.task.status == 'completed' ? AppTheme.secondaryContainer : AppTheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.task.status.toUpperCase(),
                    style: TextStyle(
                      color: widget.task.status == 'completed' ? AppTheme.onSecondaryContainer : AppTheme.onSurfaceVariant, 
                      fontSize: 11, 
                      fontWeight: FontWeight.w600
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.task.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Created By: $createdByName',
                  style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Card Container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.3)),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  Text(
                    widget.task.description?.isNotEmpty == true ? widget.task.description! : 'No description provided.',
                    style: const TextStyle(fontSize: 16, color: AppTheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),

                  // Due Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today, color: AppTheme.primary, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Due Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.onSurface)),
                          const SizedBox(height: 4),
                          Text(
                            widget.task.dueDate?.isNotEmpty == true 
                                ? DateFormat('MMM d, yyyy').format(DateTime.parse(widget.task.dueDate!)) 
                                : 'No due date',
                            style: const TextStyle(fontSize: 14, color: AppTheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: AppTheme.outlineVariant, thickness: 0.5),
                  ),

                  // Assigned To
                  const Text('Assigned To', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppTheme.surfaceContainerHigh,
                        child: Text(
                          assignedToName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(assignedToName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.onSurface)),
                            const Text('Member', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            if (canManageTask)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isUpdating ? null : _toggleStatus,
                  icon: _isUpdating 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(widget.task.status == 'completed' ? Icons.undo : Icons.check_circle),
                  label: Text(
                    widget.task.status == 'completed' ? 'Mark as Pending' : 'Mark Completed',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.task.status == 'completed' ? AppTheme.secondary : AppTheme.primaryContainer,
                    foregroundColor: widget.task.status == 'completed' ? AppTheme.onSecondary : AppTheme.onPrimaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
