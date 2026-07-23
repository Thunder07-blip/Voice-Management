import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart';

class CreateNoticeSheet extends ConsumerStatefulWidget {
  const CreateNoticeSheet({super.key});

  @override
  ConsumerState<CreateNoticeSheet> createState() => _CreateNoticeSheetState();
}

class _CreateNoticeSheetState extends ConsumerState<CreateNoticeSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _selectedDepartment;
  
  final _departments = ['General', 'Kitchen', 'Maintenance', 'Events'];

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

    final noticeId = const Uuid().v4();
    final now = DateTime.now();

    final data = {
      'id': noticeId,
      'title': title,
      'content': content,
      'postedBy': currentMember?.id,
      'department': _selectedDepartment,
    };

    await syncEngine.queueOperation(
      table: 'notices',
      operation: 'insert',
      data: data,
    );

    await db.into(db.noticesTable).insert(
      NoticesTableCompanion.insert(
        id: noticeId,
        title: title,
        content: content,
        postedBy: drift.Value(currentMember?.id),
        department: drift.Value(_selectedDepartment),
        createdAt: now,
        updatedAt: now,
      ),
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
                'Post Notice',
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
              child: const Text(
                'Post Notice',
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
