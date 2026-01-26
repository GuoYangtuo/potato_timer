import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/motivation.dart';
import '../models/goal.dart';

// 条件导入，用于平台判断
import 'api_service_platform_stub.dart'
    if (dart.library.io) 'api_service_platform_io.dart' as platform;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  User? _currentUser;

  String get baseUrl => platform.getBaseUrl();

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    final userJson = prefs.getString('user_info');
    if (userJson != null) {
      _currentUser = User.fromJson(jsonDecode(userJson));
    }
  }

  Future<void> _saveAuth(String token, User user) async {
    _token = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_info', jsonEncode(user.toJson()));
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_info');
  }

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: body['message'] ?? '请求失败',
    );
  }

  // ==================== 认证相关 ====================

  /// 使用阿里云一键登录 token 登录（移动端）
  Future<User> login(String aliAuthToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'token': aliAuthToken}),
    );

    final data = await _handleResponse(response);
    final user = User.fromJson(data['data']['user']);
    await _saveAuth(data['data']['token'], user);
    return user;
  }

  /// 使用手机号直接登录（Web/Desktop 开发模式）
  Future<User> loginWithPhone(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login-phone'),
      headers: _headers,
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );

    final data = await _handleResponse(response);
    final user = User.fromJson(data['data']['user']);
    await _saveAuth(data['data']['token'], user);
    return user;
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/me'),
      headers: _headers,
    );

    final data = await _handleResponse(response);
    _currentUser = User.fromJson(data['data']);
    return _currentUser!;
  }

  Future<void> updateProfile({String? nickname, String? avatarUrl}) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await http.put(
      Uri.parse('$baseUrl/api/auth/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );

    await _handleResponse(response);
    
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        nickname: nickname ?? _currentUser!.nickname,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_info', jsonEncode(_currentUser!.toJson()));
    }
  }

  // ==================== 激励内容相关 ====================

  Future<List<Motivation>> getPublicMotivations({
    String? type,
    String? tag,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) params['type'] = type;
    if (tag != null) params['tag'] = tag;

    final uri = Uri.parse('$baseUrl/api/motivations/public')
        .replace(queryParameters: params);
    
    final response = await http.get(uri, headers: _headers);
    final data = await _handleResponse(response);

    return (data['data'] as List)
        .map((e) => Motivation.fromJson(e))
        .toList();
  }

  Future<List<Motivation>> getMyMotivations({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$baseUrl/api/motivations/my')
        .replace(queryParameters: params);
    
    final response = await http.get(uri, headers: _headers);
    final data = await _handleResponse(response);

    return (data['data'] as List)
        .map((e) => Motivation.fromJson(e))
        .toList();
  }

  Future<Motivation> getMotivation(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/motivations/$id'),
      headers: _headers,
    );

    final data = await _handleResponse(response);
    return Motivation.fromJson(data['data']);
  }

  Future<int> createMotivation({
    String? title,
    String? content,
    required String type,
    bool isPublic = false,
    List<Map<String, dynamic>>? media,
    List<String>? tags,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/motivations'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'content': content,
        'type': type,
        'isPublic': isPublic,
        'media': media,
        'tags': tags,
      }),
    );

    final data = await _handleResponse(response);
    return data['data']['id'];
  }

  Future<void> updateMotivation(int id, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/motivations/$id'),
      headers: _headers,
      body: jsonEncode(updates),
    );

    await _handleResponse(response);
  }

  Future<void> deleteMotivation(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/motivations/$id'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  Future<void> likeMotivation(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/motivations/$id/like'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  Future<void> unlikeMotivation(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/motivations/$id/like'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  Future<void> favoriteMotivation(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/motivations/$id/favorite'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  Future<void> unfavoriteMotivation(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/motivations/$id/favorite'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  Future<List<Motivation>> getFavorites({int page = 1, int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/api/motivations/favorites/list')
        .replace(queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
        });
    
    final response = await http.get(uri, headers: _headers);
    final data = await _handleResponse(response);

    return (data['data'] as List)
        .map((e) => Motivation.fromJson(e))
        .toList();
  }

  // ==================== 目标相关 ====================

  Future<List<Goal>> getMyGoals({String? type, String? status}) async {
    final params = <String, String>{};
    if (type != null) params['type'] = type;
    if (status != null) params['status'] = status;

    final uri = Uri.parse('$baseUrl/api/goals/my')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    
    final response = await http.get(uri, headers: _headers);
    final data = await _handleResponse(response);

    return (data['data'] as List)
        .map((e) => Goal.fromJson(e))
        .toList();
  }

  Future<List<Goal>> getPublicGoals({
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (type != null) params['type'] = type;

    final uri = Uri.parse('$baseUrl/api/goals/public')
        .replace(queryParameters: params);
    
    final response = await http.get(uri, headers: _headers);
    final data = await _handleResponse(response);

    return (data['data'] as List)
        .map((e) => Goal.fromJson(e))
        .toList();
  }

  Future<Goal> getGoal(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/goals/$id'),
      headers: _headers,
    );

    final data = await _handleResponse(response);
    return Goal.fromJson(data['data']);
  }

  Future<int> createGoal({
    required String title,
    String? description,
    required String type,
    bool isPublic = false,
    bool enableTimer = false,
    int durationMinutes = 10,
    String? reminderTime,
    int totalHours = 0,
    String? morningReminderTime,
    String? afternoonReminderTime,
    int sessionDurationMinutes = 240,
    List<int>? motivationIds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/goals'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'description': description,
        'type': type,
        'isPublic': isPublic,
        'enableTimer': enableTimer,
        'durationMinutes': durationMinutes,
        'reminderTime': reminderTime,
        'totalHours': totalHours,
        'morningReminderTime': morningReminderTime,
        'afternoonReminderTime': afternoonReminderTime,
        'sessionDurationMinutes': sessionDurationMinutes,
        'motivationIds': motivationIds,
      }),
    );

    final data = await _handleResponse(response);
    return data['data']['id'];
  }

  Future<void> updateGoal(int id, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/goals/$id'),
      headers: _headers,
      body: jsonEncode(updates),
    );

    await _handleResponse(response);
  }

  Future<void> deleteGoal(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/goals/$id'),
      headers: _headers,
    );

    await _handleResponse(response);
  }

  Future<Map<String, dynamic>> completeGoal(int id, {
    int durationMinutes = 0,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/goals/$id/complete'),
      headers: _headers,
      body: jsonEncode({
        'durationMinutes': durationMinutes,
        'notes': notes,
      }),
    );

    final data = await _handleResponse(response);
    return data['data'];
  }

  Future<Map<String, dynamic>> getGoalMotivations(int goalId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/goals/$goalId/motivations'),
      headers: _headers,
    );

    final data = await _handleResponse(response);
    return data['data'];
  }

  // ==================== 标签相关 ====================

  Future<List<Map<String, dynamic>>> getTags() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/tags'),
      headers: _headers,
    );

    final data = await _handleResponse(response);
    return List<Map<String, dynamic>>.from(data['data']);
  }

  Future<List<Map<String, dynamic>>> getPopularTags({int limit = 20}) async {
    final uri = Uri.parse('$baseUrl/api/tags/popular')
        .replace(queryParameters: {'limit': limit.toString()});
    
    final response = await http.get(uri, headers: _headers);
    final data = await _handleResponse(response);

    return List<Map<String, dynamic>>.from(data['data']);
  }

  // ==================== 文件上传 ====================
  // 注意：文件上传功能仅在支持 dart:io 的平台可用（Android/iOS/Desktop）
  // Web 平台需要使用不同的实现方式

  /// 上传单个文件（使用文件路径）
  /// 仅在支持 dart:io 的平台可用
  Future<Map<String, dynamic>> uploadFileFromPath(String filePath) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/upload/file'),
    );
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = await _handleResponse(response);

    return data['data'];
  }

  /// 上传多个文件（使用文件路径列表）
  /// 仅在支持 dart:io 的平台可用
  Future<List<Map<String, dynamic>>> uploadFilesFromPaths(List<String> filePaths) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/upload/files'),
    );
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    for (final filePath in filePaths) {
      request.files.add(await http.MultipartFile.fromPath('files', filePath));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = await _handleResponse(response);

    return List<Map<String, dynamic>>.from(data['data']);
  }

  /// 上传文件（使用字节数据，跨平台兼容）
  Future<Map<String, dynamic>> uploadFileFromBytes(
    String filename,
    List<int> bytes, {
    String? mimeType,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/upload/file'),
    );
    
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: filename,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = await _handleResponse(response);

    return data['data'];
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException: $statusCode - $message';
}


