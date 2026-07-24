import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/local/database.dart';
import '../../data/sync/sync_engine.dart';
import '../providers/app_providers.dart';

final activityServiceProvider = Provider<ActivityService>((ref) {
  final db = ref.read(databaseProvider);
  final syncEngine = ref.read(syncEngineProvider);
  return ActivityService(db, syncEngine);
});

class ActivityService {
  final AppDatabase _db;
  final SyncEngine _syncEngine;
  final _uuid = const Uuid();

  ActivityService(this._db, this._syncEngine);

  /// Logs a new activity to the local database and queues it for sync.
  /// [content] e.g. "Rahul Patil returned from leave."
  /// [category] e.g. "leave", "task", "member", "notice"
  Future<void> logActivity({
    required String content,
    required String category,
    String? relatedMemberId,
  }) async {
    final activityId = _uuid.v4();
    final now = DateTime.now();

    final companion = ActivitiesTableCompanion.insert(
      id: activityId,
      content: content,
      category: category,
      relatedMemberId: relatedMemberId == null ? const drift.Value.absent() : drift.Value(relatedMemberId),
      createdAt: drift.Value(now),
    );

    // Write locally
    await _db.into(_db.activitiesTable).insert(companion);

    // Queue for cloud sync
    final data = {
      'id': activityId,
      'content': content,
      'category': category,
      'relatedMemberId': relatedMemberId,
      'createdAt': now.toIso8601String(),
    };

    await _syncEngine.queueOperation(
      table: 'activities',
      operation: 'insert',
      data: data,
    );
  }
}
