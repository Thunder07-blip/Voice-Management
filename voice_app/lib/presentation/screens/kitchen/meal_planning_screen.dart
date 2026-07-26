import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/utils/meal_calculator.dart';
import '../../../data/local/database.dart';

class MealPlanningScreen extends ConsumerStatefulWidget {
  const MealPlanningScreen({super.key});

  @override
  ConsumerState<MealPlanningScreen> createState() => _MealPlanningScreenState();
}

class _MealPlanningScreenState extends ConsumerState<MealPlanningScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    
    final hasKitchenView = authState.hasPermission('manage_meals') ||
        authState.hasPermission('view_meals');

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Meal Planning',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: AppTheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: hasKitchenView
                ? _KitchenView(date: _selectedDate)
                : _MemberView(date: _selectedDate),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      color: AppTheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: IconButton.filledTonal(
                icon: const Icon(Icons.calendar_month),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ),
            ...List.generate(30, (index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    index == 0 ? 'Today' : (index == 1 ? 'Tomorrow' : DateFormat('MMM d').format(date)),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedDate = date);
                  },
                  selectedColor: AppTheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.onPrimaryContainer : AppTheme.onSurfaceVariant,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Member View – local-state-first editing with atomic Update
// ---------------------------------------------------------------------------

class _MemberView extends ConsumerStatefulWidget {
  final DateTime date;
  
  const _MemberView({required this.date});

  @override
  ConsumerState<_MemberView> createState() => _MemberViewState();
}

class _MemberViewState extends ConsumerState<_MemberView> {
  // Local draft state – null means "not yet initialised from DB"
  bool? _draftBreakfast;
  bool? _draftLunch;
  bool? _draftDinner;

  // Snapshot of the persisted values so we can detect dirty state
  bool _savedBreakfast = true;
  bool _savedLunch = true;
  bool _savedDinner = true;

  bool _isSaving = false;

  // Track which date + plan we last synced from so we reset draft on date change
  String? _lastSyncedPlanId;
  String? _lastSyncedDateStr;

  bool get _hasUnsavedChanges =>
      _draftBreakfast != null &&
      (_draftBreakfast != _savedBreakfast ||
       _draftLunch != _savedLunch ||
       _draftDinner != _savedDinner);

  void _syncFromPlan(MealPlan? plan, String dateStr) {
    final planId = plan?.id;
    if (_lastSyncedDateStr == dateStr && _lastSyncedPlanId == planId) return;

    _savedBreakfast = plan?.breakfast ?? true;
    _savedLunch = plan?.lunch ?? true;
    _savedDinner = plan?.dinner ?? true;

    _draftBreakfast = _savedBreakfast;
    _draftLunch = _savedLunch;
    _draftDinner = _savedDinner;

    _lastSyncedPlanId = planId;
    _lastSyncedDateStr = dateStr;
  }

  Future<void> _saveChanges(WidgetRef ref, String dateStr, String memberId, MealPlan? existingPlan) async {
    if (!_hasUnsavedChanges) return;
    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      final syncEngine = ref.read(syncEngineProvider);

      if (existingPlan != null) {
        final updated = existingPlan.copyWith(
          breakfast: _draftBreakfast!,
          lunch: _draftLunch!,
          dinner: _draftDinner!,
          updatedAt: DateTime.now(),
        );
        await db.update(db.mealPlansTable).replace(updated);
        await syncEngine.queueOperation(
          table: 'meal_plans',
          operation: 'update',
          data: {
            'id': updated.id,
            'memberId': updated.memberId,
            'date': updated.date,
            'breakfast': updated.breakfast,
            'lunch': updated.lunch,
            'dinner': updated.dinner,
            'createdAt': updated.createdAt.toIso8601String(),
            'updatedAt': updated.updatedAt.toIso8601String(),
          },
        );
      } else {
        final mealPlanId = const Uuid().v4();
        final now = DateTime.now();
        await db.into(db.mealPlansTable).insert(
          MealPlansTableCompanion.insert(
            id: mealPlanId,
            memberId: memberId,
            date: dateStr,
            breakfast: drift.Value(_draftBreakfast!),
            lunch: drift.Value(_draftLunch!),
            dinner: drift.Value(_draftDinner!),
            createdAt: now,
            updatedAt: now,
          ),
        );
        await syncEngine.queueOperation(
          table: 'meal_plans',
          operation: 'insert',
          data: {
            'id': mealPlanId,
            'memberId': memberId,
            'date': dateStr,
            'breakfast': _draftBreakfast!,
            'lunch': _draftLunch!,
            'dinner': _draftDinner!,
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
          },
        );
      }

      // After successful save, update saved snapshot so button disables
      _savedBreakfast = _draftBreakfast!;
      _savedLunch = _draftLunch!;
      _savedDinner = _draftDinner!;
      _lastSyncedPlanId = null; // force re-sync on next build
      _lastSyncedDateStr = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal preferences updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final mealPlansAsync = ref.watch(mealPlansStreamProvider);
    final leavesAsync = ref.watch(leavesStreamProvider);

    if (authState.currentMember == null) {
      return const Center(child: Text('Not logged in'));
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(widget.date);

    return mealPlansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (plans) {
        final leaves = leavesAsync.value ?? [];
        final myPlan = plans
            .where((p) => p.memberId == authState.currentMember!.id && p.date == dateStr)
            .firstOrNull;

        // Sync draft from DB only when the date or plan changes
        _syncFromPlan(myPlan, dateStr);

        // Check if on leave
        bool isOnLeave = false;
        for (final leave in leaves) {
          if (leave.memberId == authState.currentMember!.id &&
              (leave.status == 'approved' || leave.status == 'active')) {
            final start = DateTime.parse(leave.startDate);
            final end = leave.endDate != null
                ? DateTime.parse(leave.endDate!)
                : start.add(const Duration(days: 365));

            final checkDay = DateTime(widget.date.year, widget.date.month, widget.date.day);
            final startDay = DateTime(start.year, start.month, start.day);
            final endDay = DateTime(end.year, end.month, end.day);

            if ((checkDay.isAfter(startDay) || checkDay.isAtSameMomentAs(startDay)) &&
                (checkDay.isBefore(endDay) || checkDay.isAtSameMomentAs(endDay))) {
              isOnLeave = true;
              break;
            }
          }
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (_hasUnsavedChanges) {
              final shouldDiscard = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Unsaved Changes'),
                  content: const Text(
                    'You have unsaved meal changes. Refreshing will discard them. Continue?',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard & Refresh')),
                  ],
                ),
              );
              if (shouldDiscard != true) return;
              // Reset draft tracking so _syncFromPlan re-applies from DB
              _lastSyncedPlanId = null;
              _lastSyncedDateStr = null;
            }
            await ref.read(syncEngineProvider).pullRemoteChanges();
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'My Meals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (isOnLeave) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.flight, color: AppTheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'You are on leave for this date. Meals are automatically marked as Not Eating.',
                          style: TextStyle(color: AppTheme.onTertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _MealSelectionCard(
                title: 'Breakfast',
                isEating: _draftBreakfast ?? true,
                isDisabled: isOnLeave,
                onChanged: (val) => setState(() => _draftBreakfast = val),
              ),
              const SizedBox(height: 16),
              _MealSelectionCard(
                title: 'Lunch',
                isEating: _draftLunch ?? true,
                isDisabled: isOnLeave,
                onChanged: (val) => setState(() => _draftLunch = val),
              ),
              const SizedBox(height: 16),
              _MealSelectionCard(
                title: 'Dinner',
                isEating: _draftDinner ?? true,
                isDisabled: isOnLeave,
                onChanged: (val) => setState(() => _draftDinner = val),
              ),
              const SizedBox(height: 24),
              // ── Update Button ──
              FilledButton.icon(
                onPressed: (_hasUnsavedChanges && !_isSaving && !isOnLeave)
                    ? () => _saveChanges(ref, dateStr, authState.currentMember!.id, myPlan)
                    : null,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_isSaving ? 'Updating…' : 'Update'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              if (_hasUnsavedChanges) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'You have unsaved changes',
                    style: TextStyle(
                      color: AppTheme.tertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Meal Selection Card (unchanged – purely presentational)
// ---------------------------------------------------------------------------

class _MealSelectionCard extends StatelessWidget {
  final String title;
  final bool isEating;
  final bool isDisabled;
  final ValueChanged<bool> onChanged;

  const _MealSelectionCard({
    required this.title,
    required this.isEating,
    this.isDisabled = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              ChoiceChip(
                label: const Text('○ Eating'),
                selected: isEating,
                onSelected: isDisabled ? null : (val) {
                  if (val) onChanged(true);
                },
                selectedColor: Colors.green[100],
                labelStyle: TextStyle(color: isEating ? Colors.green[800] : AppTheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              ChoiceChip(
                label: const Text('○ Not Eating'),
                selected: !isEating,
                onSelected: isDisabled ? null : (val) {
                  if (val) onChanged(false);
                },
                selectedColor: Colors.red[100],
                labelStyle: TextStyle(color: !isEating ? Colors.red[800] : AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kitchen View – coordinator / kitchen staff analytics with pull-to-refresh
// ---------------------------------------------------------------------------

class _KitchenView extends ConsumerWidget {
  final DateTime date;

  const _KitchenView({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlansAsync = ref.watch(mealPlansStreamProvider);
    final membersAsync = ref.watch(membersStreamProvider);

    return membersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (members) {
        return mealPlansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (plans) {
            final dateStr = DateFormat('yyyy-MM-dd').format(date);
            final todaysPlans = plans.where((p) => p.date == dateStr).toList();

            final result = MealCalculator.calculateMeals(
              members: members,
              todaysPlans: todaysPlans,
            );

            return RefreshIndicator(
              onRefresh: () => ref.read(syncEngineProvider).pullRemoteChanges(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Kitchen Analytics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _KitchenMealCard(
                    title: 'Breakfast',
                    totalMembers: result.totalMembers,
                    onLeaveMembers: result.onLeaveMembers,
                    notEatingMembers: result.notEatingBreakfastMembers,
                    mealsRequired: result.requiredBreakfast,
                  ),
                  const SizedBox(height: 16),
                  _KitchenMealCard(
                    title: 'Lunch',
                    totalMembers: result.totalMembers,
                    onLeaveMembers: result.onLeaveMembers,
                    notEatingMembers: result.notEatingLunchMembers,
                    mealsRequired: result.requiredLunch,
                  ),
                  const SizedBox(height: 16),
                  _KitchenMealCard(
                    title: 'Dinner',
                    totalMembers: result.totalMembers,
                    onLeaveMembers: result.onLeaveMembers,
                    notEatingMembers: result.notEatingDinnerMembers,
                    mealsRequired: result.requiredDinner,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _KitchenMealCard extends StatelessWidget {
  final String title;
  final int totalMembers;
  final List<dynamic> onLeaveMembers;
  final List<dynamic> notEatingMembers;
  final int mealsRequired;

  const _KitchenMealCard({
    required this.title,
    required this.totalMembers,
    required this.onLeaveMembers,
    required this.notEatingMembers,
    required this.mealsRequired,
  });

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surfaceContainerLowest,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$title Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (onLeaveMembers.isNotEmpty) ...[
                      const Text('On Leave', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      ...onLeaveMembers.map((m) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.flight, color: AppTheme.primary, size: 20),
                        title: Text(m.name ?? 'Unknown'),
                      )),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                    if (notEatingMembers.isNotEmpty) ...[
                      const Text('Not Eating', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      ...notEatingMembers.map((m) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.restaurant_menu, color: Colors.red, size: 20),
                        title: Text(m.name ?? 'Unknown'),
                      )),
                    ],
                    if (onLeaveMembers.isEmpty && notEatingMembers.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('Everyone is eating!'),
                      )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => _showDetails(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Required: $mealsRequired', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _StatRow(label: 'Total Members', value: totalMembers),
              _StatRow(label: 'On Leave', value: onLeaveMembers.length),
              _StatRow(label: 'Not Eating', value: notEatingMembers.length, isRed: true),
              const Divider(),
              _StatRow(label: 'Meals Required', value: mealsRequired, isBold: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int value;
  final bool isRed;
  final bool isBold;

  const _StatRow({
    required this.label, 
    required this.value, 
    this.isRed = false,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
          )),
          Text(value.toString(), style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isRed ? Colors.red[700] : (isBold ? AppTheme.primary : AppTheme.onSurface),
          )),
        ],
      ),
    );
  }
}
