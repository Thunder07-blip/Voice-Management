import 'package:dio/dio.dart';

class ApiClient {
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator → localhost
  
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (log) => print('[API] $log'),
    ));
  }

  // ── Members ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getMembers({
    String? search,
    String? memberType,
    String? groupId,
  }) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (memberType != null) params['member_type'] = memberType;
    if (groupId != null) params['group_id'] = groupId;

    final response = await _dio.get('/members', queryParameters: params);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> getMember(String id) async {
    final response = await _dio.get('/members/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createMember(Map<String, dynamic> data) async {
    final response = await _dio.post('/members', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMember(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/members/$id', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> deleteMember(String id) async {
    await _dio.delete('/members/$id');
  }

  // ── Tasks ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
    String? priority,
    String? sort,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (sort != null) params['sort'] = sort;

    final response = await _dio.get('/tasks', queryParameters: params);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    final response = await _dio.get('/tasks/$id');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _dio.post('/tasks', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTask(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/tasks/$id', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Groups ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getGroups() async {
    final response = await _dio.get('/groups');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // ── Roles ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getRoles() async {
    final response = await _dio.get('/roles');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  // ── Notices ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getNotices() async {
    final response = await _dio.get('/notices');
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> createNotice(Map<String, dynamic> data) async {
    final response = await _dio.post('/notices', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Leaves ──────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getLeaves({String? memberId}) async {
    final params = <String, String>{};
    if (memberId != null) params['member_id'] = memberId;

    final response = await _dio.get('/leaves', queryParameters: params);
    return List<Map<String, dynamic>>.from(response.data['data']);
  }

  Future<Map<String, dynamic>> createLeave(Map<String, dynamic> data) async {
    final response = await _dio.post('/leaves', data: data);
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Sync ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> syncOutbox(
      List<Map<String, dynamic>> operations) async {
    final response =
        await _dio.post('/sync', data: {'operations': operations});
    return response.data['data'] as Map<String, dynamic>;
  }
}
