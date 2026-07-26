import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart' as drift;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/device_notification_service.dart';
import '../local/database.dart';
import '../remote/supabase_config.dart';

/// Keeps the local Drift database in step with Supabase.
///
/// Writes are queued locally first, then sent when a connection is available.
/// Reads are reconciled on startup and after each successful flush, while
/// Realtime keeps already-running phones up to date without a refresh.
class SyncEngine {
  SyncEngine(this._db) {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (results) {
        if (!results.contains(ConnectivityResult.none)) {
          unawaited(syncNow());
        }
      },
    );
  }

  final AppDatabase _db;
  final List<RealtimeChannel> _channels = [];
  late final StreamSubscription<List<ConnectivityResult>>
      _connectivitySubscription;
  bool _isSyncing = false;

  static const _remoteTables = <String>[
    'roles',
    'permissions',
    'role_permissions',
    'groups',
    'members',
    'tasks',
    'notices',
    'leaves',
    'meal_plans',
    'health_records',
    'acknowledgements',
    'activities',
  ];

  SupabaseClient get _supabase => SupabaseConfig.client;

  /// Opens one Realtime channel per shared table and performs the first pull.
  /// Calling this more than once is harmless.
  Future<void> startRealtimeSync() async {
    if (_channels.isNotEmpty) return;

    for (final table in _remoteTables) {
      final channel = _supabase
          .channel('voice_manager_$table')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: table,
            callback: (payload) => unawaited(_handleRealtimeChange(table, payload)),
          )
          .subscribe();
      _channels.add(channel);
    }

    await pullRemoteChanges();
  }

  Future<void> _handleRealtimeChange(
    String table,
    PostgresChangePayload payload,
  ) async {
    if (payload.eventType == PostgresChangeEvent.delete) {
      await _deleteLocalRecord(table, payload.oldRecord);
      return;
    }

    if (payload.newRecord.isEmpty ||
        (payload.eventType != PostgresChangeEvent.insert &&
            payload.eventType != PostgresChangeEvent.update)) {
      return;
    }

    await _upsertLocalRecord(table, payload.newRecord);

    if (table == 'leaves' &&
        payload.eventType == PostgresChangeEvent.insert &&
        _string(payload.newRecord, 'status') == 'pending') {
      await _createLeaveRequestAlert(payload.newRecord);
    }
  }

  String? _string(Map<String, dynamic> record, String snakeKey,
      [String? camelKey]) {
    final value = record[snakeKey] ??
        (camelKey == null ? null : record[camelKey]);
    return value?.toString();
  }

  DateTime _timestamp(Map<String, dynamic> record, String key) {
    return DateTime.tryParse(_string(record, key) ?? '') ?? DateTime.now();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((item) => item.toString()).toList();
    if (value is String && value.isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded.map((item) => item.toString()).toList();
      } catch (_) {
        // Older data may not be JSON. Treat it as an empty tag list.
      }
    }
    return const [];
  }

  Future<bool> _hasPendingOperation(String table, String id) async {
    final operations = await ( _db.select(_db.outboxOperations)
          ..where((entry) => entry.targetTable.equals(table)))
        .get();
    return operations.any((entry) => entry.payloadJson.contains('"id":"$id"'));
  }

  Future<void> _upsertLocalRecord(
    String table,
    Map<String, dynamic> record,
  ) async {
    final id = _string(record, 'id');
    if (table != 'role_permissions' && id == null) return;
    if (id != null && await _hasPendingOperation(table, id)) return;

    try {
      switch (table) {
        case 'roles':
          await _db.into(_db.rolesTable).insertOnConflictUpdate(
                RolesTableCompanion.insert(
                  id: id!,
                  name: _string(record, 'name') ?? '',
                  description: drift.Value(_string(record, 'description')),
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                ),
              );
          break;
        case 'permissions':
          await _db.into(_db.permissionsTable).insertOnConflictUpdate(
                PermissionsTableCompanion.insert(
                  id: id!,
                  permissionKey: _string(record, 'permission_key', 'permissionKey') ?? '',
                  description: drift.Value(_string(record, 'description')),
                ),
              );
          break;
        case 'role_permissions':
          final roleId = _string(record, 'role_id', 'roleId');
          final permissionId = _string(record, 'permission_id', 'permissionId');
          if (roleId != null && permissionId != null) {
            await _db.into(_db.rolePermissionsTable).insertOnConflictUpdate(
                  RolePermissionsTableCompanion.insert(
                    roleId: roleId,
                    permissionId: permissionId,
                  ),
                );
          }
          break;
        case 'groups':
          await _db.into(_db.groupsTable).insertOnConflictUpdate(
                GroupsTableCompanion.insert(
                  id: id!,
                  name: _string(record, 'name') ?? '',
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                ),
              );
          break;
        case 'members':
          await _db.into(_db.membersTable).insertOnConflictUpdate(
                MembersTableCompanion.insert(
                  id: id!,
                  memberId: drift.Value(_string(record, 'member_id', 'memberId')),
                  pinHash: drift.Value(_string(record, 'pin_hash', 'pinHash')),
                  name: _string(record, 'name') ?? '',
                  profilePhoto: drift.Value(_string(record, 'profile_photo', 'profilePhoto')),
                  college: drift.Value(_string(record, 'college')),
                  year: drift.Value(_string(record, 'year')),
                  memberType: drift.Value(_string(record, 'member_type', 'memberType') ?? 'student'),
                  currentStatus: drift.Value(_string(record, 'current_status', 'currentStatus') ?? 'Present'),
                  groupId: drift.Value(_string(record, 'group_id', 'groupId')),
                  roleId: drift.Value(_string(record, 'role_id', 'roleId')),
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                  deletedAt: drift.Value(
                    DateTime.tryParse(_string(record, 'deleted_at', 'deletedAt') ?? ''),
                  ),
                ),
              );
          break;
        case 'tasks':
          await _db.into(_db.tasksTable).insertOnConflictUpdate(
                TasksTableCompanion.insert(
                  id: id!,
                  title: _string(record, 'title') ?? '',
                  description: drift.Value(_string(record, 'description')),
                  priority: drift.Value(_string(record, 'priority') ?? 'medium'),
                  status: drift.Value(_string(record, 'status') ?? 'pending'),
                  dueDate: drift.Value(_string(record, 'due_date', 'dueDate')),
                  createdBy: drift.Value(_string(record, 'created_by', 'createdBy')),
                  assignedTo: drift.Value(_string(record, 'assigned_to', 'assignedTo')),
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                  deletedAt: drift.Value(
                    DateTime.tryParse(_string(record, 'deleted_at', 'deletedAt') ?? ''),
                  ),
                ),
              );
          break;
        case 'notices':
          await _db.into(_db.noticesTable).insertOnConflictUpdate(
                NoticesTableCompanion.insert(
                  id: id!,
                  title: _string(record, 'title') ?? '',
                  content: _string(record, 'content') ?? '',
                  postedBy: drift.Value(_string(record, 'posted_by', 'postedBy')),
                  department: drift.Value(_string(record, 'department')),
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                ),
              );
          break;
        case 'leaves':
          await _db.into(_db.leavesTable).insertOnConflictUpdate(
                LeavesTableCompanion.insert(
                  id: id!,
                  memberId: _string(record, 'member_id', 'memberId') ?? '',
                  reason: drift.Value(_string(record, 'reason')),
                  startDate: _string(record, 'start_date', 'startDate') ?? '',
                  endDate: drift.Value(_string(record, 'end_date', 'endDate')),
                  status: drift.Value(_string(record, 'status') ?? 'pending'),
                  approvedBy: drift.Value(_string(record, 'approved_by', 'approvedBy')),
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                ),
              );
          break;
        case 'meal_plans':
          await _db.into(_db.mealPlansTable).insertOnConflictUpdate(
                MealPlansTableCompanion.insert(
                  id: id!,
                  memberId: _string(record, 'member_id', 'memberId') ?? '',
                  date: _string(record, 'date') ?? '',
                  breakfast: drift.Value(record['breakfast'] as bool? ?? true),
                  lunch: drift.Value(record['lunch'] as bool? ?? true),
                  dinner: drift.Value(record['dinner'] as bool? ?? true),
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                ),
              );
          break;
        case 'health_records':
          await _db.into(_db.healthRecordsTable).insertOnConflictUpdate(
                HealthRecordsTableCompanion.insert(
                  id: id!,
                  memberId: _string(record, 'member_id', 'memberId') ?? '',
                  condition: _string(record, 'condition') ?? '',
                  status: drift.Value(_string(record, 'status') ?? 'Resting'),
                  reportedBy: drift.Value(_string(record, 'reported_by', 'reportedBy')),
                  createdAt: _timestamp(record, 'created_at'),
                  updatedAt: _timestamp(record, 'updated_at'),
                ),
              );
          break;
        case 'acknowledgements':
          await _db.into(_db.acknowledgementsTable).insertOnConflictUpdate(
                AcknowledgementsTableCompanion.insert(
                  id: id!,
                  content: _string(record, 'content') ?? '',
                  authorId: _string(record, 'author_id', 'authorId') ?? '',
                  taggedMemberIds: drift.Value(
                    _stringList(record['tagged_member_ids'] ?? record['taggedMemberIds']),
                  ),
                  createdAt: _timestamp(record, 'created_at'),
                ),
              );
          break;
        case 'activities':
          await _db.into(_db.activitiesTable).insertOnConflictUpdate(
                ActivitiesTableCompanion.insert(
                  id: id!,
                  content: _string(record, 'content') ?? '',
                  category: _string(record, 'category') ?? '',
                  relatedMemberId: drift.Value(
                    _string(record, 'related_member_id', 'relatedMemberId'),
                  ),
                  createdAt: drift.Value(_timestamp(record, 'created_at')),
                ),
              );
          break;
      }
    } catch (error) {
      // A malformed remote row must not stop remaining tables from syncing.
      // It remains visible in the Supabase logs for correction.
      print('[SyncEngine] Unable to apply $table record: $error');
    }
  }

  Future<void> _deleteLocalRecord(
    String table,
    Map<String, dynamic> record,
  ) async {
    final id = _string(record, 'id');
    if (id != null && await _hasPendingOperation(table, id)) return;

    switch (table) {
      case 'roles':
        await (_db.delete(_db.rolesTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'permissions':
        await (_db.delete(_db.permissionsTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'groups':
        await (_db.delete(_db.groupsTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'members':
        await (_db.delete(_db.membersTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'tasks':
        await (_db.delete(_db.tasksTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'notices':
        await (_db.delete(_db.noticesTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'leaves':
        await (_db.delete(_db.leavesTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'meal_plans':
        await (_db.delete(_db.mealPlansTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'health_records':
        await (_db.delete(_db.healthRecordsTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'acknowledgements':
        await (_db.delete(_db.acknowledgementsTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'activities':
        await (_db.delete(_db.activitiesTable)..where((row) => row.id.equals(id!))).go();
        break;
      case 'role_permissions':
        final roleId = _string(record, 'role_id', 'roleId');
        final permissionId = _string(record, 'permission_id', 'permissionId');
        if (roleId != null && permissionId != null) {
          await (_db.delete(_db.rolePermissionsTable)..where(
            (row) => row.roleId.equals(roleId) & row.permissionId.equals(permissionId),
          )).go();
        }
        break;
    }
  }

  Future<void> _createLeaveRequestAlert(Map<String, dynamic> record) async {
    final leaveId = _string(record, 'id');
    final requesterId = _string(record, 'member_id');
    if (leaveId == null || requesterId == null || !await _canManageLeaves(requesterId)) {
      return;
    }

    final requester = await (_db.select(_db.membersTable)
          ..where((member) => member.id.equals(requesterId)))
        .getSingleOrNull();
    final body = '${requester?.name ?? 'A member'} requested leave.';
    final notification = NotificationsTableCompanion.insert(
      id: 'leave_$leaveId',
      type: 'leave_request',
      title: 'New leave request',
      body: body,
      relatedId: drift.Value(leaveId),
      createdAt: DateTime.now(),
    );
    await _db.into(_db.notificationsTable).insert(
          notification,
          mode: drift.InsertMode.insertOrIgnore,
        );
    await DeviceNotificationService.showLeaveRequest(body);
  }

  Future<bool> _canManageLeaves(String requesterId) async {
    final preferences = await SharedPreferences.getInstance();
    final memberId = preferences.getString('memberId');
    if (memberId == null) return false;

    final currentMember = await (_db.select(_db.membersTable)
          ..where((member) => member.memberId.equals(memberId)))
        .getSingleOrNull();
    if (currentMember == null || currentMember.id == requesterId || currentMember.roleId == null) {
      return false;
    }

    final assignments = await (_db.select(_db.rolePermissionsTable)
          ..where((assignment) => assignment.roleId.equals(currentMember.roleId!)))
        .get();
    if (assignments.isEmpty) return false;
    final permissionIds = assignments.map((item) => item.permissionId).toList();
    final permission = await (_db.select(_db.permissionsTable)
          ..where((item) => item.id.isIn(permissionIds) & item.permissionKey.equals('manage_leaves')))
        .getSingleOrNull();
    return permission != null;
  }

  /// Pull every shared table, then remove rows that were deleted while this
  /// phone was offline. A table with unsent local work is never reconciled,
  /// preventing an offline edit from being lost.
  Future<void> pullRemoteChanges() async {
    for (final table in _remoteTables) {
      try {
        final response = await _supabase.from(table).select();
        final records = (response as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();
        if (table == 'meal_plans') {
          print('[SyncEngine] Pulled ${records.length} meal_plans from Supabase');
          for (final r in records) {
            print('[SyncEngine]   meal_plan: id=${r['id']}, member=${r['member_id']}, date=${r['date']}, B=${r['breakfast']}, L=${r['lunch']}, D=${r['dinner']}');
          }
        }
        for (final record in records) {
          await _upsertLocalRecord(table, record);
        }
        await _reconcileDeletedRecords(table, records);
      } catch (error) {
        print('[SyncEngine] Unable to pull $table: $error');
      }
    }
  }

  Future<void> _reconcileDeletedRecords(
    String table,
    List<Map<String, dynamic>> remoteRecords,
  ) async {
    final hasPending = await (_db.select(_db.outboxOperations)
          ..where((entry) => entry.targetTable.equals(table)))
        .get()
        .then((entries) => entries.isNotEmpty);
    if (hasPending) return;

    if (table == 'role_permissions') {
      final remoteKeys = remoteRecords
          .map((record) => '${_string(record, 'role_id')}|${_string(record, 'permission_id')}')
          .toSet();
      final local = await _db.select(_db.rolePermissionsTable).get();
      for (final item in local) {
        if (!remoteKeys.contains('${item.roleId}|${item.permissionId}')) {
          await (_db.delete(_db.rolePermissionsTable)..where(
            (row) => row.roleId.equals(item.roleId) & row.permissionId.equals(item.permissionId),
          )).go();
        }
      }
      return;
    }

    final remoteIds = remoteRecords
        .map((record) => _string(record, 'id'))
        .whereType<String>()
        .toSet();
    switch (table) {
      case 'roles':
        await (_db.delete(_db.rolesTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'permissions':
        await (_db.delete(_db.permissionsTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'groups':
        await (_db.delete(_db.groupsTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'members':
        await (_db.delete(_db.membersTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'tasks':
        await (_db.delete(_db.tasksTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'notices':
        await (_db.delete(_db.noticesTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'leaves':
        await (_db.delete(_db.leavesTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'meal_plans':
        await (_db.delete(_db.mealPlansTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'health_records':
        await (_db.delete(_db.healthRecordsTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'acknowledgements':
        await (_db.delete(_db.acknowledgementsTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
      case 'activities':
        await (_db.delete(_db.activitiesTable)..where((row) => row.id.isNotIn(remoteIds))).go();
        break;
    }
  }

  Future<void> syncNow() async {
    if (_isSyncing) return;
    final connection = await Connectivity().checkConnectivity();
    if (connection.contains(ConnectivityResult.none)) return;

    _isSyncing = true;
    try {
      final operations = await _db.select(_db.outboxOperations).get();
      for (final operation in operations) {
        final data = Map<String, dynamic>.from(jsonDecode(operation.payloadJson) as Map);
        if (_hasInvalidMemberId(operation.targetTable, data)) {
          await _removeOutboxOperation(operation.id);
          print('[SyncEngine] Discarded invalid legacy operation ${operation.id}');
          continue;
        }

        try {
          final payload = _toSnakeCase(data);
          if (operation.targetTable == 'meal_plans') {
            print('[SyncEngine] Pushing meal_plan to Supabase: $payload');
          }
          if (operation.operation == 'delete') {
            await _deleteRemote(operation.targetTable, payload);
          } else {
            await _supabase.from(operation.targetTable).upsert(payload);
          }
          await _removeOutboxOperation(operation.id);
          if (operation.targetTable == 'meal_plans') {
            print('[SyncEngine] meal_plan pushed successfully');
          }
        } catch (error) {
          // Keep transient failures in the outbox; they will retry when the
          // network changes or the user opens the app again.
          print('[SyncEngine] Failed ${operation.targetTable}/${operation.id}: $error');
        }
      }
      await pullRemoteChanges();
    } finally {
      _isSyncing = false;
    }
  }

  Map<String, dynamic> _toSnakeCase(Map<String, dynamic> data) {
    return data.map((key, value) {
      final snake = key.replaceAllMapped(
        RegExp(r'[A-Z]'),
        (match) => '_${match.group(0)!.toLowerCase()}',
      );
      return MapEntry(snake, value is DateTime ? value.toIso8601String() : value);
    });
  }

  Future<void> _deleteRemote(String table, Map<String, dynamic> payload) async {
    if (table == 'role_permissions') {
      await _supabase
          .from(table)
          .delete()
          .eq('role_id', payload['role_id'])
          .eq('permission_id', payload['permission_id']);
      return;
    }
    await _supabase.from(table).delete().eq('id', payload['id']);
  }

  bool _hasInvalidMemberId(String table, Map<String, dynamic> data) {
    const memberScopedTables = <String>{
      'members',
      'tasks',
      'notices',
      'leaves',
      'meal_plans',
      'health_records',
      'acknowledgements',
      'activities',
    };
    if (!memberScopedTables.contains(table)) return false;
    final fields = <dynamic>[
      if (table == 'members') data['id'],
      if (table == 'members') data['memberId'] ?? data['member_id'],
      data['createdBy'] ?? data['created_by'],
      data['assignedTo'] ?? data['assigned_to'],
      data['postedBy'] ?? data['posted_by'],
      data['memberId'] ?? data['member_id'],
      data['approvedBy'] ?? data['approved_by'],
      data['reportedBy'] ?? data['reported_by'],
      data['authorId'] ?? data['author_id'],
      data['relatedMemberId'] ?? data['related_member_id'],
    ].whereType<String>();
    return fields.any((value) => value.isNotEmpty && value.length != 5);
  }

  Future<void> _removeOutboxOperation(String id) {
    return (_db.delete(_db.outboxOperations)..where((entry) => entry.id.equals(id))).go();
  }

  /// Queue after the local write. The short deferred flush lets the caller
  /// finish its Drift transaction first, so its own Realtime event cannot race
  /// ahead and overwrite the local row.
  Future<void> queueOperation({
    required String table,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    final id = '${data['id'] ?? '$table-$operation'}_${DateTime.now().microsecondsSinceEpoch}';
    await _db.into(_db.outboxOperations).insert(
          OutboxOperationsCompanion.insert(
            id: id,
            targetTable: table,
            operation: operation,
            payloadJson: jsonEncode(data),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
    unawaited(Future<void>.delayed(const Duration(milliseconds: 250), syncNow));
  }

  void dispose() {
    _connectivitySubscription.cancel();
    for (final channel in _channels) {
      unawaited(_supabase.removeChannel(channel));
    }
    _channels.clear();
  }
}
