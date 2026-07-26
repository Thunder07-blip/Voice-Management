import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart';
import '../app_drawer.dart';
import 'tasks_history_screen.dart';
import 'task_detail_screen.dart';
import 'create_task_sheet.dart';
import '../members/member_profile_screen.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Pending',
    'In Progress',
    'Completed',
    'High Priority'
  ];

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

  List<Task> _getFilteredTasks(List<Task> tasks) {
    final query = _searchController.text.toLowerCase();
    return tasks.where((task) {
      // 1. Search matching
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          (task.description?.toLowerCase().contains(query) ?? false);

      // 2. Filter chip matching
      bool matchesFilter = true;
      if (_selectedFilter != 'All') {
        if (_selectedFilter == 'Pending') {
          matchesFilter = task.status == 'pending';
        } else if (_selectedFilter == 'In Progress') {
          matchesFilter = task.status == 'in_progress';
        } else if (_selectedFilter == 'Completed') {
          matchesFilter = task.status == 'completed';
        } else if (_selectedFilter == 'High Priority') {
          matchesFilter = task.priority == 'high';
        }
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Future<void> _saveTask(Task task) async {
    final db = ref.read(databaseProvider);
    await db.update(db.tasksTable).replace(task);
    await ref.read(syncEngineProvider).queueOperation(
      table: 'tasks',
      operation: 'update',
      data: {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'priority': task.priority,
        'status': task.status,
        'dueDate': task.dueDate,
        'createdBy': task.createdBy,
        'assignedTo': task.assignedTo,
        'createdAt': task.createdAt.toIso8601String(),
        'updatedAt': task.updatedAt.toIso8601String(),
        'deletedAt': task.deletedAt?.toIso8601String(),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    // Watch the Drift tasks stream
    final tasksAsync = ref.watch(tasksStreamProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Tasks',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TasksHistoryScreen()),
              );
            },
            tooltip: 'Task History',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                if (authState.currentMember != null) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MemberProfileScreen(
                      name: authState.currentMember!.name,
                      memberId: authState.currentMember!.id,
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
      body: Column(
        children: [
          // Search & Filters Sticky Header
          Container(
            color: AppTheme.background,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 32,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryContainer
                                : AppTheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppTheme.outlineVariant,
                            ),
                            boxShadow:
                                isSelected ? AppTheme.softShadow : null,
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.onPrimaryContainer
                                  : AppTheme.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Task List
          Expanded(
            child: tasksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (allTasks) {
                final baseTasks = allTasks;
                final now = DateTime.now();
                // Filter out tasks older than 30 days
                final activeTasks = baseTasks.where((t) => now.difference(t.createdAt).inDays <= 30).toList();
                final displayedTasks = _getFilteredTasks(activeTasks);

                if (displayedTasks.isEmpty) {
                  return const Center(child: Text('No tasks found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: displayedTasks.length + 1, // +1 for FAB padding
                  itemBuilder: (context, index) {
                    if (index == displayedTasks.length) {
                      return const SizedBox(height: 100); // padding for FAB
                    }
                    
                    final task = displayedTasks[index];
                    // Check outbox to see if this task is pending sync
                    final isPendingSync = ref.watch(isPendingSyncProvider(task.id));

                    final canToggle = authState.hasPermission('manage_tasks') ||
                                      task.assignedTo == authState.currentMember?.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: _TaskListItem(
                          title: task.title,
                          description: task.description ?? '',
                          priority: task.priority,
                          dueDate: task.dueDate != null && task.dueDate!.isNotEmpty 
                              ? DateFormat('MMM d, yyyy').format(DateTime.parse(task.dueDate!)) 
                              : 'No due date',
                          status: task.status,
                          isCompleted: task.status == 'completed',
                          isPendingSync: isPendingSync,
                          canToggle: canToggle,
                          onToggle: canToggle ? () async {
                            final newStatus = task.status == 'completed' ? 'pending' : 'completed';
                            final updated = task.copyWith(
                              status: newStatus,
                              updatedAt: DateTime.now(),
                            );
                            await _saveTask(updated);
                          } : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: authState.hasPermission('manage_tasks')
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  builder: (context) => const CreateTaskSheet(),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final String title;
  final String description;
  final String priority;
  final String dueDate;
  final String status;
  final bool isCompleted;
  final bool isPendingSync;
  final bool canToggle;
  final VoidCallback? onToggle;

  const _TaskListItem({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.status,
    this.isCompleted = false,
    this.isPendingSync = false,
    this.canToggle = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? AppTheme.surfaceContainer
            : AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.transparent
              : AppTheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: isCompleted ? null : AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: IconButton(
              onPressed: onToggle,
              iconSize: 24,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? AppTheme.secondary : Colors.transparent,
                  border: Border.all(
                    color: isCompleted
                        ? Colors.transparent
                        : AppTheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: isCompleted
                    ? const Icon(Icons.check,
                        size: 16, color: AppTheme.onSecondary)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 18,
                              color: isCompleted
                                  ? AppTheme.onSurfaceVariant
                                  : AppTheme.onSurface,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Sync Indicator
                    Icon(
                      isPendingSync ? Icons.cloud_upload : Icons.cloud_done,
                      size: 16,
                      color: isPendingSync ? AppTheme.primary : AppTheme.outlineVariant,
                    ),
                    const SizedBox(width: 8),
                    if (!isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priority == 'High'
                              ? AppTheme.errorContainer
                              : const Color(0xFFFFDDB8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: priority == 'High'
                                ? AppTheme.onErrorContainer
                                : const Color(0xFF2A1700),
                          ),
                        ),
                      ),
                  ],
                ),
                if (description.isNotEmpty && !isCompleted) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (!isCompleted)
                          const Icon(Icons.calendar_today,
                              size: 14, color: AppTheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          isCompleted ? dueDate : 'Due: $dueDate',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.secondaryContainer
                            : AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isCompleted
                              ? AppTheme.onSecondaryContainer
                              : AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
