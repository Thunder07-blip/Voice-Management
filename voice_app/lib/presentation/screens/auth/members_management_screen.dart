import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/local/database.dart';

class MembersManagementScreen extends ConsumerStatefulWidget {
  const MembersManagementScreen({super.key});

  @override
  ConsumerState<MembersManagementScreen> createState() => _MembersManagementScreenState();
}

class _MembersManagementScreenState extends ConsumerState<MembersManagementScreen> {
  final _searchController = TextEditingController();

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

  void _showAddMemberDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      builder: (context) => const MemberFormSheet(member: null),
    );
  }

  void _showEditMemberDialog(Member member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      builder: (context) => MemberFormSheet(member: member),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersStreamProvider);
    final rolesAsync = ref.watch(rolesStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Member Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMemberDialog,
          ),
        ],
      ),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (members) {
          final query = _searchController.text.toLowerCase();
          final displayedMembers = members.where((m) {
            return m.name.toLowerCase().contains(query) || 
                   (m.memberId?.toLowerCase().contains(query) ?? false);
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              Expanded(
                child: displayedMembers.isEmpty
                    ? const Center(child: Text('No members found.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayedMembers.length,
                        itemBuilder: (context, index) {
                          final member = displayedMembers[index];
                          
                          // Find role name
                          String roleName = 'No Role';
                          rolesAsync.whenData((roles) {
                            final match = roles.where((r) => r.id == member.roleId).firstOrNull;
                            if (match != null) roleName = match.name;
                          });

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppTheme.outlineVariant),
                            ),
                            color: AppTheme.surfaceContainerLowest,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.surfaceContainer,
                                child: Text(
                                  member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                                  style: const TextStyle(color: AppTheme.onSurface),
                                ),
                              ),
                              title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${member.memberType} • Role: $roleName'),
                              trailing: const Icon(Icons.edit, color: AppTheme.onSurfaceVariant),
                              onTap: () => _showEditMemberDialog(member),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MemberFormSheet extends ConsumerStatefulWidget {
  final Member? member;
  const MemberFormSheet({this.member});

  @override
  ConsumerState<MemberFormSheet> createState() => _MemberFormSheetState();
}

class _MemberFormSheetState extends ConsumerState<MemberFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _collegeController;
  late TextEditingController _memberIdController;
  late TextEditingController _pinController;
  String _memberType = 'student';
  String _currentStatus = 'Present';
  String? _selectedRoleId;
  String? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _collegeController = TextEditingController(text: widget.member?.college ?? '');
    _memberIdController = TextEditingController(text: widget.member?.memberId ?? '');
    _pinController = TextEditingController(text: widget.member?.pinHash ?? '');
    _memberType = widget.member?.memberType ?? 'student';
    _currentStatus = widget.member?.currentStatus ?? 'Present';
    _selectedRoleId = widget.member?.roleId;
    _selectedGroupId = widget.member?.groupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _memberIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _saveMember() async {
    final name = _nameController.text.trim();
    final memberIdInput = _memberIdController.text.trim();
    final pinInput = _pinController.text.trim();
    
    if (name.isEmpty || memberIdInput.isEmpty || pinInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name, Member ID, and PIN are required.')));
      return;
    }
    if (!RegExp(r'^[A-Za-z0-9]{5}$').hasMatch(memberIdInput)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member ID must be exactly 5 letters or numbers.')));
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(pinInput)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be exactly 4 digits.')));
      return;
    }

    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);

    final normalizedMemberId = memberIdInput.toUpperCase();
    final memberId = widget.member?.id ?? normalizedMemberId;
    final isUpdate = widget.member != null;
    final now = DateTime.now();

    final data = {
      'id': memberId,
      'memberId': normalizedMemberId,
      'pinHash': pinInput,
      'name': name,
      'profilePhoto': widget.member?.profilePhoto,
      'memberType': _memberType,
      'college': _collegeController.text.trim(),
      'year': widget.member?.year,
      'roleId': _selectedRoleId,
      'groupId': _selectedGroupId,
      'currentStatus': widget.member?.currentStatus ?? 'Present',
      'createdAt': (widget.member?.createdAt ?? now).toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deletedAt': widget.member?.deletedAt?.toIso8601String(),
    };

    // Local DB Update
    if (isUpdate) {
      await (db.update(db.membersTable)..where((t) => t.id.equals(memberId))).write(
        MembersTableCompanion(
          memberId: drift.Value(normalizedMemberId),
          pinHash: drift.Value(pinInput),
          name: drift.Value(name),
          memberType: drift.Value(_memberType),
          college: drift.Value(data['college'] as String?),
          roleId: drift.Value(_selectedRoleId),
          groupId: drift.Value(_selectedGroupId),
          updatedAt: drift.Value(now),
        ),
      );
    } else {
      await db.into(db.membersTable).insert(
        MembersTableCompanion.insert(
          id: memberId,
          memberId: drift.Value(normalizedMemberId),
          pinHash: drift.Value(pinInput),
          name: name,
          memberType: drift.Value(_memberType),
          college: drift.Value(data['college']),
          roleId: drift.Value(_selectedRoleId),
          groupId: drift.Value(_selectedGroupId),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    await syncEngine.queueOperation(
      table: 'members',
      operation: isUpdate ? 'update' : 'insert',
      data: data,
    );

    if (isUpdate && _currentStatus != widget.member!.currentStatus) {
      final leaveSync = ref.read(leaveSyncServiceProvider);
      final coordinatorId = ref.read(authProvider).currentMember?.id ?? '';
      if (_currentStatus == 'Away') {
        await leaveSync.markMemberAsLeft(memberId, coordinatorId);
      } else {
        await leaveSync.markMemberAsReturned(memberId);
      }
    }

    if (mounted) Navigator.pop(context);
  }

  void _deleteMember() async {
    if (widget.member == null) return;
    final db = ref.read(databaseProvider);
    final syncEngine = ref.read(syncEngineProvider);

    await (db.delete(db.membersTable)..where((t) => t.id.equals(widget.member!.id))).go();
    await syncEngine.queueOperation(
      table: 'members',
      operation: 'delete',
      data: {'id': widget.member!.id},
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final rolesAsync = ref.watch(rolesStreamProvider);
    final groupsAsync = ref.watch(groupsStreamProvider);
    final isUpdate = widget.member != null;
    final authState = ref.watch(authProvider);
    final currentMember = authState.currentMember;

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
                isUpdate ? 'Edit Member' : 'Add Member',
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
                child: TextField(
                  controller: _memberIdController,
                  decoration: InputDecoration(
                    labelText: '5-character Member ID (e.g. VV002)',
                    filled: true,
                    fillColor: AppTheme.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: '4-Digit PIN',
                    filled: true,
                    counterText: '',
                    fillColor: AppTheme.surfaceContainerLowest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
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
          
          if (isUpdate) ...[
            DropdownButtonFormField<String>(
              value: _currentStatus,
              decoration: InputDecoration(
                labelText: 'Current Status',
                filled: true,
                fillColor: AppTheme.surfaceContainerLowest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: 'Present', child: Text('Present')),
                DropdownMenuItem(value: 'Away', child: Text('Away (Left)')),
                DropdownMenuItem(value: 'Sick', child: Text('Sick')),
              ],
              onChanged: (val) => setState(() => _currentStatus = val!),
            ),
            const SizedBox(height: 12),
          ],
          
          // Role Selection
          rolesAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading roles'),
            data: (roles) {
              String? currentRoleName;
              if (currentMember?.roleId != null) {
                currentRoleName = roles.where((r) => r.id == currentMember!.roleId).firstOrNull?.name;
              }

              var availableRoles = roles;
              bool isPM = currentRoleName == 'Project Manager';
              bool isOC = currentRoleName == 'Overall Coordinator';
              bool isAOC = currentRoleName == 'Assistant Overall Coordinator' || currentRoleName == 'Assistant OC';

              if (!isPM && (isOC || isAOC)) {
                final restrictedNames = ['Project Manager', 'Overall Coordinator', 'Assistant Overall Coordinator', 'Assistant OC'];
                availableRoles = roles.where((r) => !restrictedNames.contains(r.name)).toList();
                
                String? editedRoleName = roles.where((r) => r.id == widget.member?.roleId).firstOrNull?.name;
                bool isEditingRestricted = editedRoleName != null && restrictedNames.contains(editedRoleName);
                
                if (isEditingRestricted) {
                   return DropdownButtonFormField<String?>(
                     value: _selectedRoleId,
                     decoration: InputDecoration(
                       labelText: 'Assign Role (Permission Denied)',
                       filled: true,
                       fillColor: AppTheme.surfaceContainerLowest,
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                     ),
                     items: [
                       DropdownMenuItem(value: _selectedRoleId, child: Text(editedRoleName)),
                     ],
                     onChanged: null,
                   );
                }
              }

              return DropdownButtonFormField<String?>(
                value: _selectedRoleId,
                decoration: InputDecoration(
                  labelText: 'Assign Role',
                  filled: true,
                  fillColor: AppTheme.surfaceContainerLowest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('No Role')),
                  ...availableRoles.map((r) => DropdownMenuItem(value: r.id, child: Text(r.name))),
                ],
                onChanged: (val) => setState(() => _selectedRoleId = val),
              );
            },
          ),
          const SizedBox(height: 12),

          // Group Selection
          groupsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => const Text('Error loading groups'),
            data: (groups) => DropdownButtonFormField<String?>(
              value: _selectedGroupId,
              decoration: InputDecoration(
                labelText: 'Assign Group',
                filled: true,
                fillColor: AppTheme.surfaceContainerLowest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('No Group')),
                ...groups.map((g) => DropdownMenuItem(value: g.id, child: Text(g.name))),
              ],
              onChanged: (val) => setState(() => _selectedGroupId = val),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              if (isUpdate) ...[
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.errorContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteMember,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _saveMember,
                    child: Text(
                      isUpdate ? 'Update Member' : 'Add Member',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
