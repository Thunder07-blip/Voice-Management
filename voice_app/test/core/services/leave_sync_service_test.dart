import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:voice_app/data/local/database.dart';
import 'package:voice_app/core/services/leave_sync_service.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase database;
  late LeaveSyncService service;
  late Member testMember;
  late LeaveRequest testLeave;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    service = LeaveSyncService(database);

    // Insert dummy member
    await database.into(database.membersTable).insert(
      MembersTableCompanion.insert(
        id: 'mem-123',
        name: 'Test Member',
        currentStatus: const drift.Value('Present'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    );
    
    testMember = await (database.select(database.membersTable)..where((t) => t.id.equals('mem-123'))).getSingle();

    // Insert dummy pending leave
    final startDate = DateTime.now().add(const Duration(days: 1));
    final endDate = DateTime.now().add(const Duration(days: 3));
    
    await database.into(database.leavesTable).insert(
      LeavesTableCompanion.insert(
        id: 'leave-123',
        memberId: testMember.id,
        startDate: startDate.toIso8601String(),
        endDate: drift.Value(endDate.toIso8601String()),
        status: const drift.Value('pending'),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )
    );

    testLeave = await (database.select(database.leavesTable)..where((t) => t.id.equals('leave-123'))).getSingle();
  });

  tearDown(() async {
    await database.close();
  });

  test('activateLeave correctly updates member status and creates meal plans', () async {
    await service.activateLeave(testLeave);

    // Verify member status
    final updatedMember = await (database.select(database.membersTable)..where((t) => t.id.equals('mem-123'))).getSingle();
    expect(updatedMember.currentStatus, 'Away');

    // Verify leave status
    final updatedLeave = await (database.select(database.leavesTable)..where((t) => t.id.equals('leave-123'))).getSingle();
    expect(updatedLeave.status, 'active');

    // Verify meal plans were generated as 'Not Eating' (false)
    final mealPlans = await (database.select(database.mealPlansTable)..where((t) => t.memberId.equals('mem-123'))).get();
    
    // Duration is 3 days (1st, 2nd, 3rd) -> inclusive means 3 records
    expect(mealPlans.length, 3);
    for (final plan in mealPlans) {
      expect(plan.breakfast, false);
      expect(plan.lunch, false);
      expect(plan.dinner, false);
    }
  });

  test('updateExpectedReturn restores meals if returning early', () async {
    // First activate leave (3 days)
    await service.activateLeave(testLeave);

    // New return date is 1 day earlier
    final newReturnDate = DateTime.parse(testLeave.endDate!).subtract(const Duration(days: 1));
    
    await service.updateExpectedReturn(testLeave, newReturnDate);

    final mealPlans = await (database.select(database.mealPlansTable)..where((t) => t.memberId.equals('mem-123'))).get();
    
    // Total plans is still 3, but the last one should now have meals restored to true
    int falseCount = 0;
    int trueCount = 0;
    for (final plan in mealPlans) {
      if (plan.breakfast == true) trueCount++;
      if (plan.breakfast == false) falseCount++;
    }
    
    // First 2 days should be false, 3rd day restored to true
    expect(falseCount, 2);
    expect(trueCount, 1);
  });

  test('confirmReturn marks status Present and restores today onward', () async {
    await service.activateLeave(testLeave);
    
    // Confirm return right away (simulating they came back on the start date)
    await service.confirmReturn(testLeave);

    final updatedMember = await (database.select(database.membersTable)..where((t) => t.id.equals('mem-123'))).getSingle();
    expect(updatedMember.currentStatus, 'Present');

    final updatedLeave = await (database.select(database.leavesTable)..where((t) => t.id.equals('leave-123'))).getSingle();
    expect(updatedLeave.status, 'completed');

    // Meal plans for today and onwards should be restored to true
    final mealPlans = await (database.select(database.mealPlansTable)..where((t) => t.memberId.equals('mem-123'))).get();
    
    for (final plan in mealPlans) {
      expect(plan.breakfast, true);
    }
  });
}
