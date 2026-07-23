import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/database.dart';
import '../remote/api_client.dart';

class SyncEngine {
  final AppDatabase _db;
  final ApiClient _apiClient;
  bool _isSyncing = false;

  SyncEngine(this._db, this._apiClient) {
    // Listen to network changes to trigger sync when coming online
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        syncNow();
      }
    });
  }

  /// Attempts to push all pending outbox operations to the remote server.
  Future<void> syncNow() async {
    if (_isSyncing) return;
    
    // Check network first
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return; // Offline, can't sync
    }

    _isSyncing = true;
    try {
      final pendingOps = await _db.select(_db.outboxOperations).get();
      if (pendingOps.isEmpty) {
        _isSyncing = false;
        return;
      }

      // Format operations for the bulk sync API
      final operationsPayload = pendingOps.map((op) {
        return {
          'id': op.id,
          'table': op.targetTable,
          'operation': op.operation,
          'data': jsonDecode(op.payloadJson),
          'clientTimestamp': op.createdAt.toIso8601String(),
        };
      }).toList();

      // Send to backend
      final response = await _apiClient.syncOutbox(operationsPayload);
      
      // The backend returns results array: { id, success, error }
      final results = response['results'] as List<dynamic>? ?? [];

      // Delete successfully synced operations from outbox
      for (final result in results) {
        if (result['success'] == true) {
          final opId = result['id'] as String;
          await (_db.delete(_db.outboxOperations)
                ..where((tbl) => tbl.id.equals(opId)))
              .go();
        } else {
          print('[SyncEngine] Failed to sync operation ${result['id']}: ${result['error']}');
          // Depending on the error (e.g. conflict, bad request), we might want to flag it or delete it.
          // For now, leave it in the outbox to retry.
        }
      }
    } catch (e) {
      print('[SyncEngine] Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Pushes an operation to the local database outbox and attempts an immediate sync.
  Future<void> queueOperation({
    required String table,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    // 1. Determine a unique ID for the outbox operation (can be data['id'] + timestamp)
    final id = '${data['id']}_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Save to local outbox
    await _db.into(_db.outboxOperations).insert(
          OutboxOperation(
            id: id,
            targetTable: table,
            operation: operation,
            payloadJson: jsonEncode(data),
            createdAt: DateTime.now(),
          ),
        );

    // 3. Attempt immediate sync in background
    syncNow();
  }
}
