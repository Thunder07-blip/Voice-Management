import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/auth_provider.dart';
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
    
    // Check if user is Kitchen Incharge, Project Manager, or OC
    final hasKitchenView = authState.hasPermission('manage_kitchen') ||
        ['Project Manager', 'Overall Coordinator', 'Kitchen Incharge']
            .contains(authState.currentRole?.name);

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

class _MemberView extends ConsumerWidget {
  final DateTime date;
  
  const _MemberView({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final mealPlansAsync = ref.watch(mealPlansStreamProvider);
    
    if (authState.currentMember == null) {
      return const Center(child: Text('Not logged in'));
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    
    final leavesAsync = ref.watch(leavesStreamProvider);
    
    return mealPlansAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (plans) {
        final leaves = leavesAsync.value ?? [];
        // Find existing plan or use defaults
        final myPlan = plans.where(
          (p) => p.memberId == authState.currentMember!.id && p.date == dateStr
        ).firstOrNull;

        // Check if date is under an approved or active leave
        bool isOnLeave = false;
        for (final leave in leaves) {
          if (leave.memberId == authState.currentMember!.id && (leave.status == 'approved' || leave.status == 'active')) {
            final start = DateTime.parse(leave.startDate);
            // End date could be null, if so assume it's ongoing or at least today
            final end = leave.endDate != null ? DateTime.parse(leave.endDate!) : start.add(const Duration(days: 365));
            
            // Normalize to day
            final checkDay = DateTime(date.year, date.month, date.day);
            final startDay = DateTime(start.year, start.month, start.day);
            final endDay = DateTime(end.year, end.month, end.day);

            if ((checkDay.isAfter(startDay) || checkDay.isAtSameMomentAs(startDay)) && 
                (checkDay.isBefore(endDay) || checkDay.isAtSameMomentAs(endDay))) {
              isOnLeave = true;
              break;
            }
          }
        }

        final breakfast = myPlan?.breakfast ?? true;
        final lunch = myPlan?.lunch ?? true;
        final dinner = myPlan?.dinner ?? true;

        return ListView(
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
              isEating: breakfast,
              isDisabled: isOnLeave,
              onChanged: (val) => _updateMeal(ref, dateStr, authState.currentMember!.id, myPlan, breakfast: val),
            ),
            const SizedBox(height: 16),
            _MealSelectionCard(
              title: 'Lunch',
              isEating: lunch,
              isDisabled: isOnLeave,
              onChanged: (val) => _updateMeal(ref, dateStr, authState.currentMember!.id, myPlan, lunch: val),
            ),
            const SizedBox(height: 16),
            _MealSelectionCard(
              title: 'Dinner',
              isEating: dinner,
              isDisabled: isOnLeave,
              onChanged: (val) => _updateMeal(ref, dateStr, authState.currentMember!.id, myPlan, dinner: val),
            ),
          ],
        );
      },
    );
  }

  void _updateMeal(
    WidgetRef ref, 
    String dateStr, 
    String memberId,
    MealPlan? existingPlan,
    {bool? breakfast, bool? lunch, bool? dinner}
  ) async {
    final db = ref.read(databaseProvider);
    
    if (existingPlan != null) {
      final updated = existingPlan.copyWith(
        breakfast: breakfast ?? existingPlan.breakfast,
        lunch: lunch ?? existingPlan.lunch,
        dinner: dinner ?? existingPlan.dinner,
        updatedAt: DateTime.now(),
      );
      await db.update(db.mealPlansTable).replace(updated);
    } else {
      await db.into(db.mealPlansTable).insert(
        MealPlansTableCompanion.insert(
          id: const Uuid().v4(),
          memberId: memberId,
          date: dateStr,
          breakfast: drift.Value(breakfast ?? true),
          lunch: drift.Value(lunch ?? true),
          dinner: drift.Value(dinner ?? true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}

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

            // Calculate Meals Required = (Present Members) - (Present Members who selected Not Eating)
            // Or simpler: Count all Present Members who have NOT selected "Not Eating"
            
            int reqBreakfast = 0;
            int reqLunch = 0;
            int reqDinner = 0;

            for (final member in members) {
              if (member.currentStatus == 'Present') {
                final plan = todaysPlans.where((p) => p.memberId == member.id).firstOrNull;
                if (plan?.breakfast ?? true) reqBreakfast++;
                if (plan?.lunch ?? true) reqLunch++;
                if (plan?.dinner ?? true) reqDinner++;
              }
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Kitchen Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _KitchenMealCard(
                  title: 'Breakfast',
                  totalMembers: totalMembers,
                  onLeave: onLeave,
                  notEating: notEatingBreakfast,
                  mealsRequired: reqBreakfast,
                ),
                const SizedBox(height: 16),
                _KitchenMealCard(
                  title: 'Lunch',
                  totalMembers: totalMembers,
                  onLeave: onLeave,
                  notEating: notEatingLunch,
                  mealsRequired: reqLunch,
                ),
                const SizedBox(height: 16),
                _KitchenMealCard(
                  title: 'Dinner',
                  totalMembers: totalMembers,
                  onLeave: onLeave,
                  notEating: notEatingDinner,
                  mealsRequired: reqDinner,
                ),
              ],
            );
          }
        );
      },
    );
  }
}

class _KitchenMealCard extends StatelessWidget {
  final String title;
  final int totalMembers;
  final int onLeave;
  final int notEating;
  final int mealsRequired;

  const _KitchenMealCard({
    required this.title,
    required this.totalMembers,
    required this.onLeave,
    required this.notEating,
    required this.mealsRequired,
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
          _StatRow(label: 'On Leave', value: onLeave),
          _StatRow(label: 'Not Eating', value: notEating, isRed: true),
          const Divider(),
          _StatRow(label: 'Meals Required', value: mealsRequired, isBold: true),
        ],
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
