import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Replaces the old Dio-based ApiClient.
/// Talks directly to Supabase REST API (auto-generated PostgREST).
class ApiClient {
  SupabaseClient get _supabase => SupabaseConfig.client;

  // ── Members ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMembers({
    String? search,
    String? memberType,
    String? groupId,
  }) async {
    var query = _supabase.from('members').select();
    if (memberType != null) query = query.eq('member_type', memberType);
    if (groupId != null) query = query.eq('group_id', groupId);
    
    final data = await query;
    
    if (search != null && search.isNotEmpty) {
      final s = search.toLowerCase();
      return data.where((m) => 
        (m['name'] as String? ?? '').toLowerCase().contains(s)
      ).toList();
    }
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getMember(String id) async {
    final data = await _supabase.from('members').select().eq('id', id).single();
    return data;
  }

  Future<Map<String, dynamic>> createMember(Map<String, dynamic> data) async {
    final result = await _supabase.from('members').insert(data).select().single();
    return result;
  }

  Future<Map<String, dynamic>> updateMember(String id, Map<String, dynamic> data) async {
    final result = await _supabase.from('members').update(data).eq('id', id).select().single();
    return result;
  }

  Future<void> deleteMember(String id) async {
    await _supabase.from('members').delete().eq('id', id);
  }

  // ── Tasks ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
    String? priority,
    String? sort,
  }) async {
    var query = _supabase.from('tasks').select();
    if (status != null) query = query.eq('status', status);
    if (priority != null) query = query.eq('priority', priority);
    
    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    final data = await _supabase.from('tasks').select().eq('id', id).single();
    return data;
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final result = await _supabase.from('tasks').insert(data).select().single();
    return result;
  }

  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> data) async {
    final result = await _supabase.from('tasks').update(data).eq('id', id).select().single();
    return result;
  }

  // ── Groups ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGroups() async {
    final data = await _supabase.from('groups').select();
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Roles ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRoles() async {
    final data = await _supabase.from('roles').select();
    return List<Map<String, dynamic>>.from(data);
  }

  // ── Notices ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotices() async {
    final data = await _supabase.from('notices').select();
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createNotice(Map<String, dynamic> data) async {
    final result = await _supabase.from('notices').insert(data).select().single();
    return result;
  }

  // ── Leaves ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeaves({String? memberId}) async {
    var query = _supabase.from('leaves').select();
    if (memberId != null) query = query.eq('member_id', memberId);
    
    final data = await query;
    return List<Map<String, dynamic>>.from(data);
  }

  Future<Map<String, dynamic>> createLeave(Map<String, dynamic> data) async {
    final result = await _supabase.from('leaves').insert(data).select().single();
    return result;
  }

  // ── Sync (Bulk Upsert) ──────────────────────────────────────────

  /// Processes outbox operations by upserting directly to Supabase tables.
  Future<Map<String, dynamic>> syncOutbox(List<Map<String, dynamic>> operations) async {
    final results = <Map<String, dynamic>>[];

    for (final op in operations) {
      final table = op['table'] as String;
      final operation = op['operation'] as String;
      final data = op['data'] as Map<String, dynamic>;
      final id = op['id'] as String;

      try {
        if (operation == 'delete') {
          await _supabase.from(table).delete().eq('id', data['id'] ?? '');
        } else {
          // upsert handles both insert and update
          await _supabase.from(table).upsert(data);
        }
        results.add({'id': id, 'success': true});
      } catch (e) {
        results.add({'id': id, 'success': false, 'error': e.toString()});
      }
    }

    return {'results': results};
  }
}
