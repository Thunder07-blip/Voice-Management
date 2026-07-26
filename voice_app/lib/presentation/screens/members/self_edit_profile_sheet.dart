import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/local/database.dart';

class SelfEditProfileSheet extends ConsumerStatefulWidget {
  final Member member;

  const SelfEditProfileSheet({super.key, required this.member});

  @override
  ConsumerState<SelfEditProfileSheet> createState() => _SelfEditProfileSheetState();
}

class _SelfEditProfileSheetState extends ConsumerState<SelfEditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _collegeController;
  late String _memberType;
  late String? _year;

  final List<String> _years = [
    'Freshman (1st)',
    'Sophomore (2nd)',
    'Junior (3rd)',
    'Senior (4th)',
    'Super Senior (5th)',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _collegeController = TextEditingController(text: widget.member.college ?? '');
    _memberType = widget.member.memberType;
    _year = widget.member.year;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required.')));
      return;
    }

    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);
    final now = DateTime.now();

    final data = {
      'id': widget.member.id,
      'memberId': widget.member.memberId,
      'pinHash': widget.member.pinHash,
      'name': name,
      'profilePhoto': widget.member.profilePhoto,
      'memberType': _memberType,
      'college': _collegeController.text.trim(),
      'year': _year,
      'roleId': widget.member.roleId,
      'groupId': widget.member.groupId,
      'currentStatus': widget.member.currentStatus,
      'createdAt': widget.member.createdAt.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deletedAt': widget.member.deletedAt?.toIso8601String(),
    };

    await (db.update(db.membersTable)..where((t) => t.id.equals(widget.member.id))).write(
      MembersTableCompanion(
        name: drift.Value(name),
        memberType: drift.Value(_memberType),
        college: drift.Value(_collegeController.text.trim()),
        year: drift.Value(_year),
        updatedAt: drift.Value(now),
      ),
    );

    await syncEngine.queueOperation(
      table: 'members',
      operation: 'update',
      data: data,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.')));
    }
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
                'Edit Profile',
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
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _memberType,
                  decoration: InputDecoration(
                    labelText: 'Type',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'student', child: Text('Student')),
                    DropdownMenuItem(value: 'working', child: Text('Working')),
                  ],
                  onChanged: (val) => setState(() => _memberType = val!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _collegeController,
                  decoration: InputDecoration(
                    labelText: 'College/Company',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String?>(
            value: _year,
            decoration: InputDecoration(
              labelText: 'Year of Study (if applicable)',
              filled: true,
              fillColor: AppTheme.surfaceContainerLowest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Not Applicable')),
              ..._years.map((y) => DropdownMenuItem(value: y, child: Text(y))),
            ],
            onChanged: (val) => setState(() => _year = val),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _saveProfile,
              child: const Text(
                'Save Changes',
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
