/// eCAL REST 客户端 - 与 C++ Agent 的 HTTP 通信
/// 通过 REST API 与 PolyVault Agent 通信

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'ecal_protocol.dart';

/// REST 客户端配置
class EcalRestClientConfig {
  final String baseUrl;
  final Duration timeout;
  final Map<String, String> defaultHeaders;
  final bool enableLogging;
  final int maxRetries;
  final Duration retryDelay;

  const EcalRestClientConfig({
    this.baseUrl = 'http://localhost:3001',
    this.timeout = const Duration(seconds: 30),
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.enableLogging = true,
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
}

/// API 响应包装
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? errorCode;
  final int? statusCode;

  ApiResponse.success(this.data, {this.statusCode})
      : success = true,
        errorMessage = null,
        errorCode = null;

  ApiResponse.error(this.errorMessage, {this.errorCode, this.statusCode})
      : success = false,
        data = null;

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    if (json['success'] as bool? ?? false) {
      return ApiResponse.success(fromJsonT(json), statusCode: 200);
    } else {
      return ApiResponse.error(
        json['error_message'] as String? ?? 'Unknown error',
        errorCode: json['error_code'] as int?,
        statusCode: json['status_code'] as int?,
      );
    }
  }
}

/// eCAL REST 客户端
class EcalRestClient {
  final EcalRestClientConfig config;
  final http.Client _httpClient;
  
  String? _authToken;
  String? _deviceId;
  
  final _eventController = StreamController<Event>.broadcast();
  
  Stream<Event> get events => _eventController.stream;

  EcalRestClient({
    this.config = const EcalRestClientConfig(),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// 设置认证令牌
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// 设置设备ID
  void setDeviceId(String deviceId) {
    _deviceId = deviceId;
  }

  /// 获取默认请求头
  Map<String, String> _getHeaders() {
    final headers = Map<String, String>.from(config.defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (_deviceId != null) {
      headers['X-Device-Id'] = _deviceId!;
    }
    return headers;
  }

  // ===========================================================================
  // 通用请求方法
  // ===========================================================================

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    final uri = Uri.parse('${config.baseUrl}$path').replace(queryParameters: query);
    
    final headers = _getHeaders();
    http.Response response;
    
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient
              .get(uri, headers: headers)
              .timeout(config.timeout);
          break;
        case 'POST':
          response = await _httpClient
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(config.timeout);
          break;
        case 'PUT':
          response = await _httpClient
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(config.timeout);
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(uri, headers: headers, body: jsonEncode(body))
              .timeout(config.timeout);
          break;
        default:
          return ApiResponse.error('Unsupported method: $method');
      }
      
      _log('$method $path -> ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (fromJson != null) {
          return ApiResponse.success(fromJson(json));
        } else {
          return ApiResponse.success(json as T);
        }
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        return ApiResponse.error(
          json?['error'] as String? ?? 'HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on TimeoutException {
      return ApiResponse.error('Request timeout', errorCode: -1);
    } on SocketException {
      return ApiResponse.error('Network error', errorCode: -2);
    } catch (e) {
      _log('Request error: $e');
      return ApiResponse.error(e.toString(), errorCode: -3);
    }
  }

  void _log(String message) {
    if (config.enableLogging) {
      print('[EcalRestClient] $message');
    }
  }

  // ===========================================================================
  // 设备发现 API
  // ===========================================================================

  /// 发现设备
  Future<ApiResponse<List<DiscoveryMessage>>> discoverDevices({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final response = await _request<List<dynamic>>(
      'GET',
      '/api/discovery/devices',
      query: {'timeout': timeout.inSeconds.toString()},
    );
    
    if (response.success && response.data != null) {
      final devices = (response.data as List<dynamic>)
          .map((e) => DiscoveryMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResponse.success(devices);
    }
    
    return ApiResponse.error(response.errorMessage ?? 'Discovery failed');
  }

  /// 广播发现消息
  Future<ApiResponse<bool>> broadcastDiscovery(DiscoveryMessage message) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/api/discovery/broadcast',
      body: message.toJson(),
    );
    
    return ApiResponse.success(response.success);
  }

  /// 响应发现请求
  Future<ApiResponse<DiscoveryResponse>> respondDiscovery(
    String deviceId,
    bool accept,
  ) async {
    return _request<DiscoveryResponse>(
      'POST',
      '/api/discovery/respond',
      body: {
        'device_id': deviceId,
        'accept': accept,
      },
      fromJson: (json) => DiscoveryResponse.fromJson(json),
    );
  }

  // ===========================================================================
  // 凭证操作 API
  // ===========================================================================

  /// 获取凭证
  Future<ApiResponse<CredentialResponse>> getCredential(
    CredentialRequest request,
  ) async {
    return _request<CredentialResponse>(
      'POST',
      '/api/credentials/get',
      body: request.toJson(),
      fromJson: (json) => CredentialResponse.fromJson(json),
    );
  }

  /// 存储凭证
  Future<ApiResponse<CredentialResponse>> storeCredential(
    CredentialStoreRequest request,
  ) async {
    return _request<CredentialResponse>(
      'POST',
      '/api/credentials/store',
      body: request.toJson(),
      fromJson: (json) => CredentialResponse.fromJson(json),
    );
  }

  /// 删除凭证
  Future<ApiResponse<bool>> deleteCredential(
    String serviceUrl,
    String sessionId,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      'DELETE',
      '/api/credentials/delete',
      body: {
        'service_url': serviceUrl,
        'session_id': sessionId,
      },
    );
    
    return ApiResponse.success(response.success);
  }

  /// 列出所有凭证
  Future<ApiResponse<List<Map<String, dynamic>>>> listCredentials(
    String sessionId,
  ) async {
    final response = await _request<List<dynamic>>(
      'GET',
      '/api/credentials/list',
      query: {'session_id': sessionId},
    );
    
    if (response.success && response.data != null) {
      final credentials = response.data!
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return ApiResponse.success(credentials);
    }
    
    return ApiResponse.error(response.errorMessage ?? 'List failed');
  }

  // ===========================================================================
  // Cookie 操作 API
  // ===========================================================================

  /// 上传 Cookie
  Future<ApiResponse<bool>> uploadCookie(CookieUploadRequest request) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/api/cookies/upload',
      body: request.toJson(),
    );
    
    return ApiResponse.success(response.success);
  }

  /// 下载 Cookie
  Future<ApiResponse<CookieDownloadResponse>> downloadCookie(
    CookieDownloadRequest request,
  ) async {
    return _request<CookieDownloadResponse>(
      'POST',
      '/api/cookies/download',
      body: request.toJson(),
      fromJson: (json) => CookieDownloadResponse.fromJson(json),
    );
  }

  /// 清除 Cookie
  Future<ApiResponse<bool>> clearCookies(
    String serviceUrl,
    String sessionId,
  ) async {
    final response = await _request<Map<String, dynamic>>(
      'DELETE',
      '/api/cookies/clear',
      body: {
        'service_url': serviceUrl,
        'session_id': sessionId,
      },
    );
    
    return ApiResponse.success(response.success);
  }

  // ===========================================================================
  // 认证 API
  // ===========================================================================

  /// 执行握手
  Future<ApiResponse<HandshakeResponse>> handshake(HandshakeRequest request) async {
    return _request<HandshakeResponse>(
      'POST',
      '/api/auth/handshake',
      body: request.toJson(),
      fromJson: (json) => HandshakeResponse.fromJson(json),
    );
  }

  /// 认证
  Future<ApiResponse<AuthenticationResponse>> authenticate(
    AuthenticationRequest request,
  ) async {
    return _request<AuthenticationResponse>(
      'POST',
      '/api/auth/authenticate',
      body: request.toJson(),
      fromJson: (json) => AuthenticationResponse.fromJson(json),
    );
  }

  /// 检查认证状态
  Future<ApiResponse<bool>> checkAuth() async {
    final response = await _request<Map<String, dynamic>>(
      'GET',
      '/api/auth/check',
    );
    
    return ApiResponse.success(response.success);
  }

  /// 注销
  Future<ApiResponse<bool>> logout() async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/api/auth/logout',
    );
    
    _authToken = null;
    return ApiResponse.success(response.success);
  }

  // ===========================================================================
  // 心跳 API
  // ===========================================================================

  /// 发送心跳
  Future<ApiResponse<HeartbeatAck>> sendHeartbeat(Heartbeat heartbeat) async {
    return _request<HeartbeatAck>(
      'POST',
      '/api/heartbeat',
      body: heartbeat.toJson(),
      fromJson: (json) => HeartbeatAck.fromJson(json),
    );
  }

  // ===========================================================================
  // 同步 API
  // ===========================================================================

  /// 请求同步
  Future<ApiResponse<SyncResponse>> requestSync(SyncRequest request) async {
    return _request<SyncResponse>(
      'POST',
      '/api/sync/request',
      body: request.toJson(),
      fromJson: (json) => SyncResponse.fromJson(json),
    );
  }

  /// 推送更新
  Future<ApiResponse<bool>> pushUpdate(SyncItem item) async {
    final response = await _request<Map<String, dynamic>>(
      'POST',
      '/api/sync/push',
      body: item.toJson(),
    );
    
    return ApiResponse.success(response.success);
  }

  // ===========================================================================
  // 设备管理 API
  // ===========================================================================

  /// 获取已配对设备列表
  Future<ApiResponse<List<Map<String, dynamic>>>> getPairedDevices() async {
    final response = await _request<List<dynamic>>(
      'GET',
      '/api/devices/paired',
    );
    
    if (response.success && response.data != null) {
      final devices = response.data!
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return ApiResponse.success(devices);
    }
    
    return ApiResponse.error(response.errorMessage ?? 'Failed to get devices');
  }

  /// 取消配对
  Future<ApiResponse<bool>> unpairDevice(String deviceId) async {
    final response = await _request<Map<String, dynamic>>(
      'DELETE',
      '/api/devices/unpair',
      body: {'device_id': deviceId},
    );
    
    return ApiResponse.success(response.success);
  }

  // ===========================================================================
  // 健康检查
  // ===========================================================================

  /// 检查服务状态
  Future<ApiResponse<Map<String, dynamic>>> healthCheck() async {
    return _request<Map<String, dynamic>>(
      'GET',
      '/api/health',
    );
  }

  /// 获取服务信息
  Future<ApiResponse<Map<String, dynamic>>> getServiceInfo() async {
    return _request<Map<String, dynamic>>(
      'GET',
      '/api/info',
    );
  }

  // ===========================================================================
  // 资源清理
  // ===========================================================================

  void dispose() {
    _eventController.close();
    _httpClient.close();
  }
}