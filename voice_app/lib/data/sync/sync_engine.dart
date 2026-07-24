import 'dart:convert';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../local/database.dart';
import '../remote/supabase_config.dart';

class SyncEngine {
  final AppDatabase _db;
  bool _isSyncing = false;
  final List<RealtimeChannel> _channels = [];

  SyncEngine(this._db) {
    // Listen to network changes to trigger sync when coming online
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        syncNow();
      }
    });
  }

  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Subscribe to Supabase Realtime changes on key tables.
  /// When a remote change happens, it gets written to local Drift DB.
  void startRealtimeSync() {
    final tablesToSync = [
      'members', 'tasks', 'notices', 'leaves', 'roles',
      'groups', 'permissions', 'role_permissions',
      'meal_plans', 'health_records', 'acknowledgements',
    ];

    for (final table in tablesToSync) {
      final channel = _supabase
          .channel('realtime_$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) {
              _handleRealtimeChange(table, payload);
            },
          )
          .subscribe();
      _channels.add(channel);
    }
  }

  void _handleRealtimeChange(String table, PostgresChangePayload payload) {
    // For now, just log realtime events.
    // In production, you'd upsert/delete from local Drift DB here.
    print('[SyncEngine] Realtime event on $table: ${payload.eventType}');
  }

  /// Attempts to push all pending outbox operations to Supabase.
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

      for (final op in pendingOps) {
        try {
          final data = jsonDecode(op.payloadJson) as Map<String, dynamic>;
          final table = op.targetTable;
          final operation = op.operation;

          if (operation == 'delete') {
            await _supabase.from(table).delete().eq('id', data['id'] ?? '');
          } else {
            // upsert handles both insert and update
            await _supabase.from(table).upsert(data);
          }

          // Successfully synced — remove from outbox
          await (_db.delete(_db.outboxOperations)
                ..where((tbl) => tbl.id.equals(op.id)))
              .go();
          
          print('[SyncEngine] ✅ Synced ${op.operation} on $table');
        } catch (e) {
          print('[SyncEngine] ❌ Failed to sync operation ${op.id}: $e');
          // Leave in outbox to retry later
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
    final id = '${data['id']}_${DateTime.now().millisecondsSinceEpoch}';

    await _db.into(_db.outboxOperations).insert(
          OutboxOperation(
            id: id,
            targetTable: table,
            operation: operation,
            payloadJson: jsonEncode(data),
            createdAt: DateTime.now(),
          ),
        );

    // Attempt immediate sync in background
    syncNow();
  }

  /// Clean up realtime subscriptions
  void dispose() {
    for (final channel in _channels) {
      _supabase.removeChannel(channel);
    }
    _channels.clear();
  }
}
