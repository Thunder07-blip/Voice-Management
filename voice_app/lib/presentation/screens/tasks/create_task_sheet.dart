import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart'; // For TasksTableCompanion

class CreateTaskSheet extends ConsumerStatefulWidget {
  final String? preSelectedAssigneeId;
  final String? preSelectedAssigneeName;

  const CreateTaskSheet({
    super.key,
    this.preSelectedAssigneeId,
    this.preSelectedAssigneeName,
  });

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedPriority = 'Medium';
  DateTime? _selectedDate;
  String? _selectedAssigneeId;

  final _priorities = ['Low', 'Medium', 'High'];

  @override
  void initState() {
    super.initState();
    _selectedAssigneeId = widget.preSelectedAssigneeId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTask() async {
    if (_titleController.text.trim().isEmpty) return;

    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);

    final taskId = const Uuid().v4();
    final now = DateTime.now();
    final dueDateStr = _selectedDate?.toIso8601String();

    // 1. Create the data payload for both Drift and Outbox
    final taskData = {
      'id': taskId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'priority': _selectedPriority.toLowerCase(),
      'status': 'pending',
      'dueDate': dueDateStr,
      'assignedTo': _selectedAssigneeId,
      'createdBy': ref.read(authProvider).currentMember?.id,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    // 2. Write locally before adding it to the outbox, avoiding an online
    // Realtime response racing the local insert.
    await db.into(db.tasksTable).insert(
      TasksTableCompanion.insert(
        id: taskId,
        title: taskData['title'] as String,
        description: drift.Value(taskData['description'] as String),
        priority: drift.Value(taskData['priority'] as String),
        status: drift.Value(taskData['status'] as String),
        dueDate: drift.Value(taskData['dueDate'] as String?),
        createdBy: drift.Value(taskData['createdBy'] as String?),
        assignedTo: drift.Value(taskData['assignedTo'] as String?),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await syncEngine.queueOperation(
      table: 'tasks',
      operation: 'insert',
      data: taskData,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersStreamProvider);
    final members = membersAsync.value ?? [];

    // Bottom sheets often get pushed up by the keyboard, 
    // so we wrap in Padding with viewInsets.bottom
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
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
                'New Task',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Title
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Task Title',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Assignee Autocomplete Search
          Autocomplete<Member>(
            initialValue: TextEditingValue(text: widget.preSelectedAssigneeName ?? ''),
            displayStringForOption: (Member option) => option.name,
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return members;
              }
              return members.where((Member member) {
                return member.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (Member selection) {
              setState(() {
                _selectedAssigneeId = selection.id;
              });
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Assign To (Type to search)',
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: const Icon(Icons.search),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 40,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Member option = options.elementAt(index);
                        return ListTile(
                          title: Text(option.name),
                          onTap: () {
                            onSelected(option);
                          },
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Priority & Date Row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _priorities.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedPriority = newValue!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: _selectDate,
                  child: Container(
                    height: 56, // matching text field height
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      border: Border.all(color: AppTheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'Due Date'
                              : '${_selectedDate!.month}/${_selectedDate!.day}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _selectedDate == null 
                                    ? AppTheme.onSurfaceVariant 
                                    : AppTheme.onSurface,
                              ),
                        ),
                        const Icon(Icons.calendar_today, size: 20, color: AppTheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _saveTask,
              child: const Text(
                'Create Task',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
