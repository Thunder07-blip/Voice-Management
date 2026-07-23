import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../data/local/database.dart';

class CommunityHealthScreen extends ConsumerWidget {
  const CommunityHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final healthRecordsAsync = ref.watch(healthRecordsStreamProvider);
    final membersAsync = ref.watch(membersStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Community Health',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: healthRecordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (records) {
          final activeRecords = records.where((r) => r.status != 'Recovered').toList();
          
          if (activeRecords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.health_and_safety, size: 64, color: AppTheme.primaryContainer),
                  const SizedBox(height: 16),
                  Text(
                    'Everyone is healthy!',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: activeRecords.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final record = activeRecords[index];
              final memberName = membersAsync.maybeWhen(
                data: (members) => members.firstWhereOrNull((m) => m.id == record.memberId)?.name ?? 'Unknown',
                orElse: () => 'Loading...',
              );
              
              return _HealthCard(record: record, memberName: memberName);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppTheme.surfaceContainerLowest,
            builder: (_) => const _ReportHealthIssueSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Report Issue'),
      ),
    );
  }
}

class _HealthCard extends ConsumerWidget {
  final HealthRecord record;
  final String memberName;

  const _HealthCard({required this.record, required this.memberName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🤒', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      record.condition,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text('Actions', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                label: 'Resting',
                isActive: record.status == 'Resting',
                onTap: () => _updateStatus(ref, 'Resting'),
              ),
              _ActionChip(
                label: 'Medicine Given',
                isActive: record.status == 'Medicine Given',
                onTap: () => _updateStatus(ref, 'Medicine Given'),
              ),
              _ActionChip(
                label: 'Hospital Visit',
                isActive: record.status == 'Hospital Visit',
                onTap: () => _updateStatus(ref, 'Hospital Visit'),
              ),
              _ActionChip(
                label: 'Recovered',
                isActive: false,
                isRecover: true,
                onTap: () => _updateStatus(ref, 'Recovered'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateStatus(WidgetRef ref, String newStatus) async {
    final db = ref.read(databaseProvider);
    final updated = record.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    await db.update(db.healthRecordsTable).replace(updated);
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isRecover;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.isActive,
    this.isRecover = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isActive
        ? AppTheme.primaryContainer
        : (isRecover ? Colors.green[100]! : AppTheme.surfaceContainerHighest);
    final Color textColor = isActive
        ? AppTheme.onPrimaryContainer
        : (isRecover ? Colors.green[800]! : AppTheme.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive || isRecover ? Colors.transparent : AppTheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _ReportHealthIssueSheet extends ConsumerStatefulWidget {
  const _ReportHealthIssueSheet();

  @override
  ConsumerState<_ReportHealthIssueSheet> createState() => _ReportHealthIssueSheetState();
}

class _ReportHealthIssueSheetState extends ConsumerState<_ReportHealthIssueSheet> {
  final _conditionController = TextEditingController();
  String? _selectedMemberId;

  void _save() async {
    if (_selectedMemberId == null || _conditionController.text.trim().isEmpty) return;

    final db = ref.read(databaseProvider);
    await db.into(db.healthRecordsTable).insert(
      HealthRecordsTableCompanion.insert(
        id: const Uuid().v4(),
        memberId: _selectedMemberId!,
        condition: _conditionController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersStreamProvider);

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
          Text(
            'Report Health Issue',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          membersAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading members'),
            data: (members) {
              return DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Member', border: OutlineInputBorder()),
                items: members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.name))).toList(),
                onChanged: (val) => setState(() => _selectedMemberId = val),
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _conditionController,
            decoration: const InputDecoration(
              labelText: 'Condition (e.g. Fever, Cold)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save Record'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
