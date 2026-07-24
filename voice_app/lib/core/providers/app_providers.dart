import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/local/database.dart';
import '../../data/remote/api_client.dart';
import '../../data/sync/sync_engine.dart';
export '../services/leave_sync_service.dart';
export '../services/update_service.dart';

// ── Core Services ───────────────────────────────────────────────────

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final db = ref.watch(databaseProvider);
  return SyncEngine(db);
});

// ── Database Streams ────────────────────────────────────────────────

// Provides a real-time stream of all members from the local database
final membersStreamProvider = StreamProvider<List<Member>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.membersTable).watch();
});

final leavesStreamProvider = StreamProvider<List<LeaveRequest>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.leavesTable).watch();
});

// Provides a real-time stream of all tasks from the local database
final tasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.tasksTable).watch();
});

// Provides a real-time stream of all notices from the local database
final noticesStreamProvider = StreamProvider<List<Notice>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.noticesTable).watch();
});

// Provides a real-time stream of all meal plans from the local database
final mealPlansStreamProvider = StreamProvider<List<MealPlan>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.mealPlansTable).watch();
});

// Provides a real-time stream of all acknowledgements from the local database
final acknowledgementsStreamProvider = StreamProvider<List<Acknowledgement>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.acknowledgementsTable)
        ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)])
        ..limit(3))
      .watch();
});

// Provides a real-time stream of all health records from the local database
final healthRecordsStreamProvider = StreamProvider<List<HealthRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.healthRecordsTable).watch();
});

// Provides a real-time stream of all roles from the local database
final rolesStreamProvider = StreamProvider<List<Role>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.rolesTable).watch();
});

// Provides a real-time stream of all groups from the local database
final groupsStreamProvider = StreamProvider<List<Group>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.groupsTable).watch();
});

// Provides a real-time stream of all outbox operations (to check sync status)
final outboxStreamProvider = StreamProvider<List<OutboxOperation>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.select(db.outboxOperations).watch();
});

// A helper provider to check if a specific record ID is pending sync
final isPendingSyncProvider = Provider.family<bool, String>((ref, recordId) {
  final outboxOpsAsync = ref.watch(outboxStreamProvider);
  final outboxOps = outboxOpsAsync.when(
    data: (data) => data,
    loading: () => <OutboxOperation>[],
    error: (_, __) => <OutboxOperation>[],
  );
  return outboxOps.any((op) => op.payloadJson.contains(recordId));
});
