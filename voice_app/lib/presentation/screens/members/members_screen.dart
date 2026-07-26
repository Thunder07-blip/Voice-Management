import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../app_drawer.dart';
import '../auth/members_management_screen.dart';
import 'member_profile_screen.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  final _searchController = TextEditingController();
  bool _isWorkingOnly = false;
  Set<String> _selectedYears = {};
  Set<String> _selectedGroups = {};

  final List<String> _yearOptions = [
    '<1st year',
    '1st year',
    'second year',
    'third year',
    'fourth year',
    '>4th year'
  ];

  final List<String> _groupOptions = [
    'sahadev',
    'nakul',
    'arjun',
    'bhim',
    'yudhistir'
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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);


    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          'Vedic Oasis',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Members',
                        style: theme.textTheme.displayLarge?.copyWith(
                          color: AppTheme.onSurface,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Consumer(
                          builder: (context, ref, _) {
                            final membersAsync = ref.watch(membersStreamProvider);
                            final count = membersAsync.value?.length ?? 0;
                            return Text(
                              '$count Members',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search member...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Filter Chips
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FilterChip(
                          label: const Text('Working ', style: TextStyle(color: AppTheme.onSurface)),
                          selected: _isWorkingOnly,
                          onSelected: (val) {
                            setState(() => _isWorkingOnly = val);
                          },
                          selectedColor: AppTheme.primaryContainer,
                          backgroundColor: AppTheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _isWorkingOnly ? Colors.transparent : AppTheme.outlineVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: Text(
                            _selectedYears.isEmpty ? 'Year ' : 'Year (${_selectedYears.length}) ',
                            style: const TextStyle(color: AppTheme.onSurface),
                          ),
                          backgroundColor: _selectedYears.isNotEmpty ? AppTheme.primaryContainer : AppTheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _selectedYears.isNotEmpty ? Colors.transparent : AppTheme.outlineVariant,
                            ),
                          ),
                          onPressed: _showYearFilterDialog,
                        ),
                        const SizedBox(width: 8),
                        ActionChip(
                          label: Text(
                            _selectedGroups.isEmpty ? 'Group ' : 'Group (${_selectedGroups.length}) ',
                            style: const TextStyle(color: AppTheme.onSurface),
                          ),
                          backgroundColor: _selectedGroups.isNotEmpty ? AppTheme.primaryContainer : AppTheme.surfaceContainerLowest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _selectedGroups.isNotEmpty ? Colors.transparent : AppTheme.outlineVariant,
                            ),
                          ),
                          onPressed: _showGroupFilterDialog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),


          Consumer(
            builder: (context, ref, child) {
              final membersAsync = ref.watch(membersStreamProvider);
              return membersAsync.when(
                data: (members) {
                  final query = _searchController.text.toLowerCase();
                  final filtered = members.where((m) {
                    final matchesSearch = query.isEmpty ||
                        m.name.toLowerCase().contains(query) ||
                        (m.college?.toLowerCase().contains(query) ?? false);
                    final matchesWorking = !_isWorkingOnly || m.memberType.toLowerCase() == 'working';
                    return matchesSearch && matchesWorking;
                  }).toList();

                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.people_outline, size: 64, color: AppTheme.outlineVariant),
                              const SizedBox(height: 16),
                              Text('No Members Found', style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final member = filtered[index];
                          final initials = member.name.trim().isNotEmpty
                              ? member.name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
                              : 'M';
                          final details = member.college != null ? member.college! : 'No Institution Data';
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _MemberCard(
                              memberId: member.id,
                              name: member.name,
                              type: member.memberType,
                              details: details,
                              initials: initials,
                              isPendingSync: false,
                            ),
                          );
                        },
                        childCount: filtered.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => SliverToBoxAdapter(child: Center(child: Text('Error loading members'))),
              );
            },
          ),
          
          // Bottom padding for FAB
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: authState.hasPermission('manage_members') || 
                            ['Project Manager', 'Overall Coordinator'].contains(authState.currentRole?.name)
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: AppTheme.surfaceContainerLowest,
                  builder: (_) => const MemberFormSheet(member: null),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showYearFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter by Year'),
              backgroundColor: AppTheme.surfaceContainerLowest,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _yearOptions.map((year) {
                    return CheckboxListTile(
                      title: Text(year),
                      value: _selectedYears.contains(year),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            _selectedYears.add(year);
                          } else {
                            _selectedYears.remove(year);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGroupFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Filter by Group'),
              backgroundColor: AppTheme.surfaceContainerLowest,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _groupOptions.map((group) {
                    return CheckboxListTile(
                      title: Text(
                        group[0].toUpperCase() + group.substring(1),
                      ),
                      value: _selectedGroups.contains(group),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            _selectedGroups.add(group);
                          } else {
                            _selectedGroups.remove(group);
                          }
                        });
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  final String? memberId;
  final String name;
  final String type;
  final String details;
  final String initials;
  final bool isPendingSync;

  const _MemberCard({
    this.memberId,
    required this.name,
    required this.type,
    required this.details,
    required this.initials,
    this.isPendingSync = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWorking = type.toLowerCase() == 'working';
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MemberProfileScreen(memberId: memberId, name: name)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.surfaceContainer,
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          color: AppTheme.onSurface,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isWorking 
                              ? AppTheme.primaryContainer.withValues(alpha: 0.2)
                              : AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isWorking 
                                ? AppTheme.onPrimaryContainer
                                : AppTheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          details,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
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
            const Icon(
              Icons.chevron_right,
              color: AppTheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}


