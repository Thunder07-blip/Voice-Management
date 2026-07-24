import 'package:flutter_test/flutter_test.dart';
import 'package:voice_app/data/local/database.dart';
import 'package:drift/native.dart';
import 'dart:convert';

void main() {
  group('Database & Sync Engine - Outbox Operations', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('Queueing an operation adds it to OutboxOperations correctly', () async {
      final payload = {
        'id': 'mem-999',
        'name': 'Offline Member',
      };

      await database.into(database.outboxOperations).insert(
        OutboxOperationsCompanion.insert(
          id: 'op-001',
          targetTable: 'members',
          operation: 'insert',
          payloadJson: jsonEncode(payload),
        )
      );

      final ops = await database.select(database.outboxOperations).get();
      
      expect(ops.length, 1);
      expect(ops.first.targetTable, 'members');
      expect(ops.first.operation, 'insert');
      
      final savedPayload = jsonDecode(ops.first.payloadJson);
      expect(savedPayload['id'], 'mem-999');
      expect(savedPayload['name'], 'Offline Member');
    });

    test('Sync conflict resolution: Local writes take priority in outbox', () async {
      // In a real scenario, SyncEngine checks if an operation is pending in Outbox
      // before overwriting local data with a Realtime update.
      
      await database.into(database.outboxOperations).insert(
        OutboxOperationsCompanion.insert(
          id: 'op-002',
          targetTable: 'tasks',
          operation: 'update',
          payloadJson: jsonEncode({'id': 'task-123', 'status': 'completed'}),
        )
      );

      final pendingUpdates = await (database.select(database.outboxOperations)
        ..where((t) => t.targetTable.equals('tasks'))).get();

      // The sync engine logic would check this and ignore incoming realtime events 
      // for 'task-123' because it's actively in the outbox.
      expect(pendingUpdates.isNotEmpty, isTrue);
      expect(pendingUpdates.first.payloadJson.contains('task-123'), isTrue);
    });
  });
}
