import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../data/local/database.dart';
import '../../data/sync/sync_engine.dart';
import '../providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_service.dart';

final leaveSyncServiceProvider = Provider<LeaveSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final activityService = ref.read(activityServiceProvider);
  final syncEngine = ref.read(syncEngineProvider);
  return LeaveSyncService(db, activityService, syncEngine);
});

class LeaveSyncService {
  final AppDatabase _db;
  final ActivityService? _activityService;
  final SyncEngine? _syncEngine;

  /// [activityService] and [syncEngine] are optional for isolated database
  /// tests. The application provider supplies both, so production changes are
  /// always added to the shared outbox.
  LeaveSyncService(this._db, [this._activityService, this._syncEngine]);

  Future<void> _queueMember(String memberId) async {
    final member = await (_db.select(_db.membersTable)
          ..where((row) => row.id.equals(memberId)))
        .getSingleOrNull();
    if (member == null) return;
    if (_syncEngine == null) return;
    await _syncEngine.queueOperation(
      table: 'members',
      operation: 'update',
      data: {
        'id': member.id,
        'memberId': member.memberId,
        'pinHash': member.pinHash,
        'name': member.name,
        'profilePhoto': member.profilePhoto,
        'college': member.college,
        'year': member.year,
        'memberType': member.memberType,
        'currentStatus': member.currentStatus,
        'groupId': member.groupId,
        'roleId': member.roleId,
        'createdAt': member.createdAt.toIso8601String(),
        'updatedAt': member.updatedAt.toIso8601String(),
        'deletedAt': member.deletedAt?.toIso8601String(),
      },
    );
  }

  Future<void> _queueLeave(String leaveId) async {
    final leave = await (_db.select(_db.leavesTable)
          ..where((row) => row.id.equals(leaveId)))
        .getSingleOrNull();
    if (leave == null) return;
    if (_syncEngine == null) return;
    await _syncEngine.queueOperation(
      table: 'leaves',
      operation: 'update',
      data: {
        'id': leave.id,
        'memberId': leave.memberId,
        'reason': leave.reason,
        'startDate': leave.startDate,
        'endDate': leave.endDate,
        'status': leave.status,
        'approvedBy': leave.approvedBy,
        'createdAt': leave.createdAt.toIso8601String(),
        'updatedAt': leave.updatedAt.toIso8601String(),
      },
    );
  }

  Future<void> _queueMealPlan(String mealPlanId) async {
    final plan = await (_db.select(_db.mealPlansTable)
          ..where((row) => row.id.equals(mealPlanId)))
        .getSingleOrNull();
    if (plan == null) return;
    if (_syncEngine == null) return;
    await _syncEngine.queueOperation(
      table: 'meal_plans',
      operation: 'update',
      data: {
        'id': plan.id,
        'memberId': plan.memberId,
        'date': plan.date,
        'breakfast': plan.breakfast,
        'lunch': plan.lunch,
        'dinner': plan.dinner,
        'createdAt': plan.createdAt.toIso8601String(),
        'updatedAt': plan.updatedAt.toIso8601String(),
      },
    );
  }

  Future<String> _getMemberName(String memberId) async {
    final member = await (_db.select(_db.membersTable)..where((t) => t.id.equals(memberId))).getSingleOrNull();
    return member?.name ?? 'A member';
  }

  /// Helper to get a list of dates between start and end (inclusive)
  List<DateTime> _getDatesInRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    // Normalize to midnight
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }
    return dates;
  }

  /// Helper to format date as YYYY-MM-DD
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Rule 1: Activate Leave
  /// Mark member as 'Away' and auto-generate 'Not Eating' meal plans
  Future<void> activateLeave(LeaveRequest leave) async {
    // 1. Update Member Status
    await (_db.update(_db.membersTable)
          ..where((t) => t.id.equals(leave.memberId)))
        .write(const MembersTableCompanion(currentStatus: drift.Value('Away')));
    await _queueMember(leave.memberId);

    // 2. Set Leave status to 'active'
    await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          status: const drift.Value('active'),
          updatedAt: drift.Value(DateTime.now()),
        ));
    await _queueLeave(leave.id);

    // 3. Auto-generate Not Eating meal plans
    final start = DateTime.parse(leave.startDate);
    final end = leave.endDate != null ? DateTime.parse(leave.endDate!) : start.add(const Duration(days: 1));
    
    final dates = _getDatesInRange(start, end);

    for (final date in dates) {
      final dateStr = _formatDate(date);
      
      // Check if meal plan exists
      final existing = await (_db.select(_db.mealPlansTable)
            ..where((t) => t.memberId.equals(leave.memberId) & t.date.equals(dateStr)))
          .getSingleOrNull();

      if (existing != null) {
        // Update existing to Not Eating
        await (_db.update(_db.mealPlansTable)
              ..where((t) => t.id.equals(existing.id)))
            .write(const MealPlansTableCompanion(
              breakfast: drift.Value(false),
              lunch: drift.Value(false),
              dinner: drift.Value(false),
            ));
        await _queueMealPlan(existing.id);
      } else {
        // Create new Not Eating entry
        final mealPlanId = const Uuid().v4();
        await _db.into(_db.mealPlansTable).insert(
          MealPlansTableCompanion.insert(
            id: mealPlanId,
            memberId: leave.memberId,
            date: dateStr,
            breakfast: const drift.Value(false),
            lunch: const drift.Value(false),
            dinner: const drift.Value(false),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        );
        await _queueMealPlan(mealPlanId);
      }
    }

    final name = await _getMemberName(leave.memberId);
    await _activityService?.logActivity(
      content: "$name started leave.",
      category: "leave",
      relatedMemberId: leave.memberId,
    );
  }

  /// Rule 2: Update Expected Return
  /// Adjust future meal plans based on the new return date
  Future<void> updateExpectedReturn(LeaveRequest leave, DateTime newReturnDate) async {
    final oldReturnStr = leave.endDate;
    if (oldReturnStr == null) return;

    final oldReturn = DateTime.parse(oldReturnStr);
    
    // Update the leave record
    await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          endDate: drift.Value(newReturnDate.toIso8601String()),
          updatedAt: drift.Value(DateTime.now()),
        ));
    await _queueLeave(leave.id);

    // If new return is earlier, we need to restore default 'Eating' (true) for the days in between
    if (newReturnDate.isBefore(oldReturn)) {
      // The days from (newReturnDate + 1 day) to oldReturn should be restored to true
      final restoreStart = newReturnDate.add(const Duration(days: 1));
      final datesToRestore = _getDatesInRange(restoreStart, oldReturn);

      for (final date in datesToRestore) {
        final dateStr = _formatDate(date);
        // Only update if they exist (were previously marked false)
        await (_db.update(_db.mealPlansTable)
              ..where((t) => t.memberId.equals(leave.memberId) & t.date.equals(dateStr)))
            .write(const MealPlansTableCompanion(
              breakfast: drift.Value(true),
              lunch: drift.Value(true),
              dinner: drift.Value(true),
            ));
        final existing = await (_db.select(_db.mealPlansTable)
              ..where((row) => row.memberId.equals(leave.memberId) & row.date.equals(dateStr)))
            .getSingleOrNull();
        if (existing != null) await _queueMealPlan(existing.id);
      }
    } else if (newReturnDate.isAfter(oldReturn)) {
      // If extended, mark new days as Not Eating
      final extraStart = oldReturn.add(const Duration(days: 1));
      final datesToMark = _getDatesInRange(extraStart, newReturnDate);

      for (final date in datesToMark) {
        final dateStr = _formatDate(date);
        final existing = await (_db.select(_db.mealPlansTable)
              ..where((t) => t.memberId.equals(leave.memberId) & t.date.equals(dateStr)))
            .getSingleOrNull();

        if (existing != null) {
          await (_db.update(_db.mealPlansTable)
                ..where((t) => t.id.equals(existing.id)))
              .write(const MealPlansTableCompanion(
                breakfast: drift.Value(false),
                lunch: drift.Value(false),
                dinner: drift.Value(false),
              ));
          await _queueMealPlan(existing.id);
        } else {
          final mealPlanId = const Uuid().v4();
          await _db.into(_db.mealPlansTable).insert(
            MealPlansTableCompanion.insert(
              id: mealPlanId,
              memberId: leave.memberId,
              date: dateStr,
              breakfast: const drift.Value(false),
              lunch: const drift.Value(false),
              dinner: const drift.Value(false),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          );
          await _queueMealPlan(mealPlanId);
        }
      }
    }
  }

  /// Rule 4 & 5: Confirm Return
  /// Mark member as 'Present', complete leave, and restore meal planning from today onward.
  Future<void> confirmReturn(LeaveRequest leave) async {
    // 1. Update Member Status
    await (_db.update(_db.membersTable)
          ..where((t) => t.id.equals(leave.memberId)))
        .write(const MembersTableCompanion(currentStatus: drift.Value('Present')));
    await _queueMember(leave.memberId);

    // 2. Set Leave status to 'completed'
    await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          status: const drift.Value('completed'),
          updatedAt: drift.Value(DateTime.now()),
        ));
    await _queueLeave(leave.id);

    // 3. Reopen meal planning from today onward (up to old expected return date)
    if (leave.endDate != null) {
      final oldReturn = DateTime.parse(leave.endDate!);
      final today = DateTime.now();

      if (oldReturn.isAfter(today) || oldReturn.isAtSameMomentAs(DateTime(today.year, today.month, today.day))) {
        final datesToRestore = _getDatesInRange(today, oldReturn);
        
        for (final date in datesToRestore) {
          final dateStr = _formatDate(date);
          // Restore default (Eating) so member can re-plan
          await (_db.update(_db.mealPlansTable)
                ..where((t) => t.memberId.equals(leave.memberId) & t.date.equals(dateStr)))
              .write(const MealPlansTableCompanion(
                breakfast: drift.Value(true),
                lunch: drift.Value(true),
                dinner: drift.Value(true),
              ));
          final existing = await (_db.select(_db.mealPlansTable)
                ..where((row) => row.memberId.equals(leave.memberId) & row.date.equals(dateStr)))
              .getSingleOrNull();
          if (existing != null) await _queueMealPlan(existing.id);
        }
      }
    }

    final name = await _getMemberName(leave.memberId);
    await _activityService?.logActivity(
      content: "$name returned from leave.",
      category: "leave",
      relatedMemberId: leave.memberId,
    );
  }

  /// Automatically activate any approved leaves whose start time has passed.
  Future<void> checkAndActivateUpcomingLeaves() async {
    final now = DateTime.now();
    final approvedLeaves = await (_db.select(_db.leavesTable)
          ..where((t) => t.status.equals('approved')))
        .get();

    for (final leave in approvedLeaves) {
      try {
        final start = DateTime.parse(leave.startDate);
        if (start.isBefore(now) || start.isAtSameMomentAs(now)) {
          await activateLeave(leave);
        }
      } catch (e) {
        // Invalid date format, skip
      }
    }
  }

  /// Approve leave. If start date has passed, activate it immediately.
  Future<void> approveLeave(LeaveRequest leave, String approverId) async {
    final start = DateTime.parse(leave.startDate);
    final now = DateTime.now();

    if (start.isBefore(now) || start.isAtSameMomentAs(now)) {
      // Activate immediately
      await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          approvedBy: drift.Value(approverId),
        ));
      await _queueLeave(leave.id);
      await activateLeave(leave);
    } else {
      // Just approve, a cron/login hook will activate it when the time arrives
      await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          status: const drift.Value('approved'),
          approvedBy: drift.Value(approverId),
          updatedAt: drift.Value(DateTime.now()),
        ));
      await _queueLeave(leave.id);
    }

    final name = await _getMemberName(leave.memberId);
    await _activityService?.logActivity(
      content: "$name's leave request was approved.",
      category: "leave",
      relatedMemberId: leave.memberId,
    );
  }

  /// Reject leave
  Future<void> rejectLeave(LeaveRequest leave, String approverId) async {
    await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          status: const drift.Value('rejected'),
          approvedBy: drift.Value(approverId),
          updatedAt: drift.Value(DateTime.now()),
        ));
    await _queueLeave(leave.id);

    final name = await _getMemberName(leave.memberId);
    await _activityService?.logActivity(
      content: "$name's leave request was rejected.",
      category: "leave",
      relatedMemberId: leave.memberId,
    );
  }

  /// Forced Leave: Mark member as Left without permission
  Future<void> markMemberAsLeft(String memberId, String coordinatorId) async {
    final leaveId = const Uuid().v4();
    final now = DateTime.now();
    
    // Insert new active leave
    final leave = LeaveRequest(
      id: leaveId,
      memberId: memberId,
      reason: 'Left without permission (Marked by Coordinator)',
      startDate: now.toIso8601String(),
      endDate: null,
      status: 'active',
      approvedBy: coordinatorId,
      createdAt: now,
      updatedAt: now,
    );
    
    await _db.into(_db.leavesTable).insert(leave);
    await _queueLeave(leaveId);
    
    // activateLeave will update member status to 'Away' and log activity
    await activateLeave(leave);
  }

  /// Forced Leave Return: Mark member as Returned
  Future<void> markMemberAsReturned(String memberId) async {
    final activeLeave = await (_db.select(_db.leavesTable)
          ..where((t) => t.memberId.equals(memberId) & t.status.equals('active')))
        .getSingleOrNull();

    if (activeLeave != null) {
      await (_db.update(_db.leavesTable)
            ..where((t) => t.id.equals(activeLeave.id)))
          .write(LeavesTableCompanion(
            endDate: drift.Value(DateTime.now().toIso8601String()),
          ));
      
      final updatedLeave = await (_db.select(_db.leavesTable)..where((t) => t.id.equals(activeLeave.id))).getSingle();
      await confirmReturn(updatedLeave);
    } else {
      // If no active leave, just set status back to Present
      await (_db.update(_db.membersTable)..where((t) => t.id.equals(memberId)))
          .write(const MembersTableCompanion(currentStatus: drift.Value('Present')));
      await _queueMember(memberId);
    }
  }
}
