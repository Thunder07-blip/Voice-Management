import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart';

class CreateNoticeSheet extends ConsumerStatefulWidget {
  final Notice? notice;
  const CreateNoticeSheet({super.key, this.notice});

  @override
  ConsumerState<CreateNoticeSheet> createState() => _CreateNoticeSheetState();
}

class _CreateNoticeSheetState extends ConsumerState<CreateNoticeSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedDepartment;
  
  final _departments = ['General', 'Kitchen', 'Maintenance', 'Events'];

  @override
  void initState() {
    super.initState();
    if (widget.notice != null) {
      _titleController.text = widget.notice!.title;
      _contentController.text = widget.notice!.content;
      _selectedDepartment = widget.notice!.department;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNotice() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    
    if (title.isEmpty || content.isEmpty) return;

    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);
    final currentMember = ref.read(authProvider).currentMember;

    final noticeId = widget.notice?.id ?? const Uuid().v4();
    final isNew = widget.notice == null;
    final now = DateTime.now();

    final data = {
      'id': noticeId,
      'title': title,
      'content': content,
      'postedBy': isNew ? currentMember?.id : widget.notice!.postedBy,
      'department': _selectedDepartment,
      if (isNew) 'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };

    await db.into(db.noticesTable).insertOnConflictUpdate(
      NoticesTableCompanion.insert(
        id: noticeId,
        title: title,
        content: content,
        postedBy: drift.Value(isNew ? currentMember?.id : widget.notice!.postedBy),
        department: drift.Value(_selectedDepartment),
        createdAt: isNew ? now : widget.notice!.createdAt,
        updatedAt: now,
      ),
    );

    await syncEngine.queueOperation(
      table: 'notices',
      operation: isNew ? 'insert' : 'update',
      data: data,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                widget.notice == null ? 'Post Notice' : 'Edit Notice',
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
          
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Notice Title',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _contentController,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: 'Message Content',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<String>(
            value: _selectedDepartment,
            decoration: InputDecoration(
              labelText: 'Department (Optional)',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: [
              const DropdownMenuItem<String>(value: null, child: Text('None (General)')),
              ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(d))),
            ],
            onChanged: (val) => setState(() => _selectedDepartment = val),
          ),
          const SizedBox(height: 24),
          
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
              onPressed: _saveNotice,
              child: Text(
                widget.notice == null ? 'Post Notice' : 'Update Notice',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
