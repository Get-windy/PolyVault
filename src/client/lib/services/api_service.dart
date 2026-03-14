import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// API 服务
/// 与 PolyVault 后端 (C++ Agent) 通信
class ApiService {
  static const String _defaultBaseUrl = 'http://localhost:3001';
  String _baseUrl = _defaultBaseUrl;
  String? _authToken;

  /// 设置基础 URL
  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  /// 设置认证 Token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// 获取基础 URL
  String get baseUrl => _baseUrl;

  /// 检查连接状态
  Future<ConnectionStatus> checkConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return ConnectionStatus(
          isConnected: true,
          serverUrl: _baseUrl,
          lastConnected: DateTime.now(),
        );
      } else {
        return ConnectionStatus(
          isConnected: false,
          serverUrl: _baseUrl,
          errorMessage: 'Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      return ConnectionStatus(
        isConnected: false,
        serverUrl: _baseUrl,
        errorMessage: e.toString(),
      );
    }
  }

  /// 连接到服务器
  Future<void> connect(String serverUrl) async {
    setBaseUrl(serverUrl);
    final status = await checkConnection();
    if (!status.isConnected) {
      throw ApiException(status.errorMessage ?? 'Connection failed');
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _authToken = null;
  }

  /// 获取请求头
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  // ==========================================================================
  // 凭证管理 API
  // ==========================================================================

  /// 获取凭证列表
  Future<List<CredentialSummary>> getCredentials() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/credentials'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => CredentialSummary.fromJson(json)).toList();
    } else {
      throw ApiException('Failed to load credentials: ${response.statusCode}');
    }
  }

  /// 获取单个凭证
  Future<Credential> getCredential(String id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/credentials/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Credential.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw ApiException('Credential not found');
    } else {
      throw ApiException('Failed to load credential: ${response.statusCode}');
    }
  }

  /// 添加凭证
  Future<void> addCredential(Credential credential) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/credentials'),
      headers: _headers,
      body: jsonEncode(credential.toJson()),
    );

    if (response.statusCode != 201) {
      throw ApiException('Failed to add credential: ${response.statusCode}');
    }
  }

  /// 更新凭证
  Future<void> updateCredential(Credential credential) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/credentials/${credential.id}'),
      headers: _headers,
      body: jsonEncode(credential.toJson()),
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to update credential: ${response.statusCode}');
    }
  }

  /// 删除凭证
  Future<void> deleteCredential(String id) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/credentials/$id'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw ApiException('Failed to delete credential: ${response.statusCode}');
    }
  }

  // ==========================================================================
  // 设备管理 API
  // ==========================================================================

  /// 获取设备列表
  Future<List<Device>> getDevices() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/devices'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Device.fromJson(json)).toList();
    } else {
      throw ApiException('Failed to load devices: ${response.statusCode}');
    }
  }

  /// 连接设备
  Future<void> connectDevice(DeviceConnectionRequest request) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/devices/connect'),
      headers: _headers,
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 201) {
      throw ApiException('Failed to connect device: ${response.statusCode}');
    }
  }

  /// 断开设备
  Future<void> disconnectDevice(String deviceId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/devices/$deviceId/disconnect'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to disconnect device: ${response.statusCode}');
    }
  }

  /// 信任设备
  Future<void> trustDevice(String deviceId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/devices/$deviceId/trust'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw ApiException('Failed to trust device: ${response.statusCode}');
    }
  }

  // ==========================================================================
  // 存储统计 API
  // ==========================================================================

  /// 获取存储统计
  Future<StorageStats> getStorageStats() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return StorageStats.fromJson(jsonDecode(response.body));
    } else {
      throw ApiException('Failed to load stats: ${response.statusCode}');
    }
  }

  // ==========================================================================
  // 安全 API
  // ==========================================================================

  /// 检查生物识别可用性
  Future<bool> isBiometricAvailable() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/security/biometric'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['available'] as bool? ?? false;
    }
    return false;
  }

  /// 获取安全状态
  Future<Map<String, dynamic>> getSecurityStatus() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/security/status'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw ApiException('Failed to load security status: ${response.statusCode}');
    }
  }

  // ==========================================================================
  // 认证 API
  // ==========================================================================

  /// 用户登录
  Future<UserSession> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final session = UserSession.fromJson(data);
      _authToken = session.token;
      return session;
    } else if (response.statusCode == 401) {
      throw ApiException('Invalid credentials');
    } else {
      throw ApiException('Login failed: ${response.statusCode}');
    }
  }

  /// 用户注册
  Future<UserSession> register(String username, String password, String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final session = UserSession.fromJson(data);
      _authToken = session.token;
      return session;
    } else {
      throw ApiException('Registration failed: ${response.statusCode}');
    }
  }

  /// 登出
  Future<void> logout() async {
    await http.post(
      Uri.parse('$_baseUrl/api/auth/logout'),
      headers: _headers,
    );
    _authToken = null;
  }

  /// 刷新 Token
  Future<UserSession> refreshToken() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/refresh'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final session = UserSession.fromJson(data);
      _authToken = session.token;
      return session;
    } else {
      throw ApiException('Token refresh failed: ${response.statusCode}');
    }
  }
}

/// API 异常
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}