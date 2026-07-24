import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';
import '../../data/local/database.dart';
import '../providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'activity_service.dart';

final leaveSyncServiceProvider = Provider<LeaveSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final activityService = ref.read(activityServiceProvider);
  return LeaveSyncService(db, activityService);
});

class LeaveSyncService {
  final AppDatabase _db;
  final ActivityService _activityService;

  LeaveSyncService(this._db, this._activityService);

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

    // 2. Set Leave status to 'active'
    await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          status: const drift.Value('active'),
          updatedAt: drift.Value(DateTime.now()),
        ));

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
      } else {
        // Create new Not Eating entry
        await _db.into(_db.mealPlansTable).insert(
          MealPlansTableCompanion.insert(
            id: const Uuid().v4(),
            memberId: leave.memberId,
            date: dateStr,
            breakfast: const drift.Value(false),
            lunch: const drift.Value(false),
            dinner: const drift.Value(false),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        );
      }
    }

    final name = await _getMemberName(leave.memberId);
    await _activityService.logActivity(
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
        } else {
          await _db.into(_db.mealPlansTable).insert(
            MealPlansTableCompanion.insert(
              id: const Uuid().v4(),
              memberId: leave.memberId,
              date: dateStr,
              breakfast: const drift.Value(false),
              lunch: const drift.Value(false),
              dinner: const drift.Value(false),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          );
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

    // 2. Set Leave status to 'completed'
    await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          status: const drift.Value('completed'),
          updatedAt: drift.Value(DateTime.now()),
        ));

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
        }
      }
    }

    final name = await _getMemberName(leave.memberId);
    await _activityService.logActivity(
      content: "$name returned from leave.",
      category: "leave",
      relatedMemberId: leave.memberId,
    );
  }

  /// Approve leave. If start date is today or earlier, activate it immediately.
  Future<void> approveLeave(LeaveRequest leave, String approverId) async {
    final start = DateTime.parse(leave.startDate);
    final now = DateTime.now();
    
    // Normalize to start of day for comparison
    final startDay = DateTime(start.year, start.month, start.day);
    final today = DateTime(now.year, now.month, now.day);

    if (startDay.isBefore(today) || startDay.isAtSameMomentAs(today)) {
      // Activate immediately
      await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          approvedBy: drift.Value(approverId),
        ));
      await activateLeave(leave);
    } else {
      // Just approve, a cron/login hook will activate it when the day arrives
      await (_db.update(_db.leavesTable)
          ..where((t) => t.id.equals(leave.id)))
        .write(LeavesTableCompanion(
          status: const drift.Value('approved'),
          approvedBy: drift.Value(approverId),
          updatedAt: drift.Value(DateTime.now()),
        ));
    }

    final name = await _getMemberName(leave.memberId);
    await _activityService.logActivity(
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

    final name = await _getMemberName(leave.memberId);
    await _activityService.logActivity(
      content: "$name's leave request was rejected.",
      category: "leave",
      relatedMemberId: leave.memberId,
    );
  }
}
