import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart';

class CreateAcknowledgementSheet extends ConsumerStatefulWidget {
  const CreateAcknowledgementSheet({super.key});

  @override
  ConsumerState<CreateAcknowledgementSheet> createState() => _CreateAcknowledgementSheetState();
}

class _CreateAcknowledgementSheetState extends ConsumerState<CreateAcknowledgementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final Set<String> _selectedMemberIds = {};
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final authState = ref.read(authProvider);

      if (authState.currentMember == null) throw Exception('Not logged in');

      // Add the new acknowledgement
      await db.into(db.acknowledgementsTable).insert(
        AcknowledgementsTableCompanion.insert(
          id: const Uuid().v4(),
          content: _contentController.text,
          authorId: authState.currentMember!.id,
          taggedMemberIds: drift.Value(_selectedMemberIds.toList()),
          createdAt: DateTime.now(),
        ),
      );

      // Enforce the 3 entries rule: if there are more than 3, delete the oldest
      final allAcks = await (db.select(db.acknowledgementsTable)
            ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]))
          .get();

      if (allAcks.length > 3) {
        final toDelete = allAcks.skip(3).map((a) => a.id).toList();
        await (db.delete(db.acknowledgementsTable)
              ..where((t) => t.id.isIn(toDelete)))
            .go();
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersStreamProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Add Acknowledgement',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Appreciation Message',
                border: OutlineInputBorder(),
                hintText: 'e.g. Great job organizing the event!',
              ),
              maxLines: 3,
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Tag Members (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: membersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (members) {
                  if (members.isEmpty) return const Center(child: Text('No members found.'));
                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isSelected = _selectedMemberIds.contains(member.id);
                      return CheckboxListTile(
                        title: Text(member.name),
                        subtitle: member.memberId != null ? Text(member.memberId!) : null,
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedMemberIds.add(member.id);
                            } else {
                              _selectedMemberIds.remove(member.id);
                            }
                          });
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Post Acknowledgement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
