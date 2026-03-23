/// eCAL 服务 - Flutter 与 C++ Agent 的统一通信层
/// 
/// 支持两种通信模式：
/// 1. 原生 eCAL (通过 Platform Channel) - 高性能，需要原生实现
/// 2. REST API - 跨平台兼容，通过 HTTP 与 C++ Agent 通信
/// 
/// 自动选择最佳通信模式

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'ecal_protocol.dart';
import 'ecal_rest_client.dart';
import 'ecal_platform_channel.dart';

/// 通信模式
enum CommunicationMode {
  native,     // 原生 eCAL (Platform Channel)
  rest,       // REST API
  hybrid,     // 混合模式 (REST + 原生事件)
}

/// eCAL 连接状态
enum EcalConnectionState {
  disconnected,
  initializing,
  connected,
  error,
}

/// 配对状态
enum PairingState {
  idle,
  discovering,
  requesting,
  confirming,
  completed,
  failed,
  timeout,
}

/// 服务配置
class EcalServiceConfig {
  final CommunicationMode preferredMode;
  final String restBaseUrl;
  final EcalPlatformConfig platformConfig;
  final Duration heartbeatInterval;
  final Duration discoveryInterval;
  final int maxRetries;

  const EcalServiceConfig({
    this.preferredMode = CommunicationMode.hybrid,
    this.restBaseUrl = 'http://localhost:3001',
    this.platformConfig = const EcalPlatformConfig(),
    this.heartbeatInterval = const Duration(seconds: 10),
    this.discoveryInterval = const Duration(seconds: 5),
    this.maxRetries = 3,
  });
}

/// eCAL 服务 - 统一通信接口
class EcalService with ChangeNotifier {
  static EcalService? _instance;
  
  /// 获取单例实例
  static EcalService get instance {
    _instance ??= EcalService._();
    return _instance!;
  }
  
  /// 创建新实例（用于测试）
  factory EcalService({EcalServiceConfig? config}) {
    _instance = EcalService._(config);
    return _instance!;
  }
  
  EcalService._([EcalServiceConfig? config]) : _config = config ?? const EcalServiceConfig();

  // 配置
  final EcalServiceConfig _config;
  
  // 通信组件
  late final EcalRestClient _restClient;
  late final EcalPlatformChannel _platformChannel;
  
  // 状态
  CommunicationMode _activeMode = CommunicationMode.rest;
  EcalConnectionState _connectionState = EcalConnectionState.disconnected;
  PairingState _pairingState = PairingState.idle;
  
  String? _localDeviceId;
  String? _localDeviceName;
  
  // 设备和请求缓存
  final Map<String, DiscoveryMessage> _discoveredDevices = {};
  final Map<String, CredentialRequest> _pendingCredentialRequests = {};
  
  // 流控制器
  final _connectionStateController = StreamController<EcalConnectionState>.broadcast();
  final _deviceDiscoveryController = StreamController<DiscoveryMessage>.broadcast();
  final _credentialRequestController = StreamController<CredentialRequest>.broadcast();
  final _eventController = StreamController<Event>.broadcast();
  
  // 定时器
  Timer? _heartbeatTimer;
  Timer? _discoveryTimer;
  int _heartbeatSequence = 0;

  // ===========================================================================
  // Getters
  // ===========================================================================

  EcalConnectionState get connectionState => _connectionState;
  PairingState get pairingState => _pairingState;
  CommunicationMode get activeMode => _activeMode;
  String? get localDeviceId => _localDeviceId;
  String? get localDeviceName => _localDeviceName;
  List<DiscoveryMessage> get discoveredDevices => _discoveredDevices.values.toList();
  
  // 流
  Stream<EcalConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<DiscoveryMessage> get deviceDiscovery => _deviceDiscoveryController.stream;
  Stream<CredentialRequest> get credentialRequests => _credentialRequestController.stream;
  Stream<Event> get events => _eventController.stream;

  // ===========================================================================
  // 初始化
  // ===========================================================================

  /// 初始化服务
  Future<bool> initialize({String? deviceName}) async {
    if (_connectionState == EcalConnectionState.connected) {
      return true;
    }

    _updateConnectionState(EcalConnectionState.initializing);
    
    try {
      // 生成设备信息
      _localDeviceId = _generateDeviceId();
      _localDeviceName = deviceName ?? 'PolyVault-${_localDeviceId!.substring(0, 8)}';
      
      // 初始化 REST 客户端
      _restClient = EcalRestClient(
        config: EcalRestClientConfig(baseUrl: _config.restBaseUrl),
      );
      _restClient.setDeviceId(_localDeviceId!);
      
      // 尝试初始化原生 eCAL
      final nativeAvailable = await _tryInitializeNative();
      
      if (nativeAvailable) {
        _activeMode = _config.preferredMode == CommunicationMode.rest
            ? CommunicationMode.hybrid
            : _config.preferredMode;
        debugPrint('[EcalService] Native eCAL available, mode: $_activeMode');
      } else {
        _activeMode = CommunicationMode.rest;
        debugPrint('[EcalService] Using REST API mode');
      }
      
      // 测试连接
      final healthCheck = await _restClient.healthCheck();
      if (!healthCheck.success) {
        debugPrint('[EcalService] REST health check failed: ${healthCheck.errorMessage}');
        // 继续尝试，可能 Agent 未运行
      }
      
      // 启动心跳
      _startHeartbeat();
      
      _updateConnectionState(EcalConnectionState.connected);
      debugPrint('[EcalService] Initialized successfully');
      return true;
      
    } catch (e) {
      debugPrint('[EcalService] Initialization failed: $e');
      _updateConnectionState(EcalConnectionState.error);
      return false;
    }
  }

  Future<bool> _tryInitializeNative() async {
    if (!await _platformChannel.isNativeAvailable()) {
      return false;
    }
    
    return await _platformChannel.initialize(_config.platformConfig);
  }

  /// 关闭服务
  Future<void> dispose() async {
    _heartbeatTimer?.cancel();
    _discoveryTimer?.cancel();
    
    await _platformChannel.finalize();
    _restClient.dispose();
    
    await _connectionStateController.close();
    await _deviceDiscoveryController.close();
    await _credentialRequestController.close();
    await _eventController.close();
    
    _updateConnectionState(EcalConnectionState.disconnected);
  }

  // ===========================================================================
  // 设备发现与配对
  // ===========================================================================

  /// 开始设备发现
  Future<void> startDeviceDiscovery() async {
    if (_connectionState != EcalConnectionState.connected) {
      return;
    }

    _updatePairingState(PairingState.discovering);
    
    // 使用原生发现或 REST 发现
    if (_activeMode == CommunicationMode.native || _activeMode == CommunicationMode.hybrid) {
      await _platformChannel.startDiscovery(
        interval: _config.discoveryInterval,
        onDeviceFound: _handleDiscoveredDevice,
      );
    }
    
    // 也使用 REST 发现
    _discoveryTimer = Timer.periodic(_config.discoveryInterval, (_) async {
      await _broadcastDiscovery();
    });
    
    // 立即发送一次
    await _broadcastDiscovery();
  }

  /// 停止设备发现
  void stopDeviceDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _platformChannel.stopDiscovery();
    _updatePairingState(PairingState.idle);
  }

  Future<void> _broadcastDiscovery() async {
    final message = DiscoveryMessage(
      deviceId: _localDeviceId!,
      deviceName: _localDeviceName!,
      deviceType: DeviceType.phone,
      capabilities: ['credential_store', 'cookie_manager', 'sync'],
    );
    
    await _restClient.broadcastDiscovery(message);
  }

  void _handleDiscoveredDevice(DiscoveryMessage device) {
    _discoveredDevices[device.deviceId] = device;
    _deviceDiscoveryController.add(device);
    notifyListeners();
  }

  /// 请求配对
  Future<bool> requestPairing(String deviceId) async {
    if (_connectionState != EcalConnectionState.connected) {
      return false;
    }

    _updatePairingState(PairingState.requesting);

    final response = await _restClient.respondDiscovery(deviceId, true);
    
    if (response.success && response.data?.accept == true) {
      _updatePairingState(PairingState.completed);
      return true;
    } else {
      _updatePairingState(PairingState.failed);
      return false;
    }
  }

  // ===========================================================================
  // 凭证操作
  // ===========================================================================

  /// 获取凭证
  Future<CredentialResponse?> getCredential({
    required String serviceUrl,
    required String sessionId,
    String? purpose,
    Map<String, String>? context,
  }) async {
    if (_connectionState != EcalConnectionState.connected) {
      return CredentialResponse(
        sessionId: sessionId,
        success: false,
        errorMessage: 'Not connected',
      );
    }

    final request = CredentialRequest(
      serviceUrl: serviceUrl,
      sessionId: sessionId,
      purpose: purpose,
      context: context,
    );

    // 优先使用原生
    if (_activeMode == CommunicationMode.native) {
      final response = await _platformChannel.getCredential(request);
      if (response != null) return response;
    }

    // 回退到 REST
    final response = await _restClient.getCredential(request);
    return response.data;
  }

  /// 存储凭证
  Future<bool> storeCredential({
    required String serviceUrl,
    required Uint8List encryptedCredential,
    required String sessionId,
    int? expiresAt,
  }) async {
    if (_connectionState != EcalConnectionState.connected) {
      return false;
    }

    final request = CredentialStoreRequest(
      serviceUrl: serviceUrl,
      encryptedCredential: encryptedCredential,
      sessionId: sessionId,
      expiresAt: expiresAt,
    );

    // 优先使用原生
    if (_activeMode == CommunicationMode.native) {
      final success = await _platformChannel.storeCredential(request);
      if (success) return true;
    }

    // 回退到 REST
    final response = await _restClient.storeCredential(request);
    return response.success;
  }

  /// 删除凭证
  Future<bool> deleteCredential({
    required String serviceUrl,
    required String sessionId,
  }) async {
    if (_connectionState != EcalConnectionState.connected) {
      return false;
    }

    // 优先使用原生
    if (_activeMode == CommunicationMode.native) {
      final success = await _platformChannel.deleteCredential(serviceUrl, sessionId);
      if (success) return true;
    }

    // 回退到 REST
    final response = await _restClient.deleteCredential(serviceUrl, sessionId);
    return response.success;
  }

  /// 列出凭证
  Future<List<Map<String, dynamic>>> listCredentials(String sessionId) async {
    if (_connectionState != EcalConnectionState.connected) {
      return [];
    }

    final response = await _restClient.listCredentials(sessionId);
    return response.data ?? [];
  }

  // ===========================================================================
  // Cookie 操作
  // ===========================================================================

  /// 上传 Cookie
  Future<bool> uploadCookie({
    required String serviceUrl,
    required Uint8List encryptedCookie,
    required String sessionId,
    int? expiresAt,
  }) async {
    if (_connectionState != EcalConnectionState.connected) {
      return false;
    }

    final request = CookieUploadRequest(
      serviceUrl: serviceUrl,
      encryptedCookie: encryptedCookie,
      sessionId: sessionId,
      expiresAt: expiresAt,
    );

    final response = await _restClient.uploadCookie(request);
    return response.success;
  }

  /// 下载 Cookie
  Future<CookieDownloadResponse?> downloadCookie({
    required String serviceUrl,
    required String sessionId,
  }) async {
    if (_connectionState != EcalConnectionState.connected) {
      return null;
    }

    final request = CookieDownloadRequest(
      serviceUrl: serviceUrl,
      sessionId: sessionId,
    );

    final response = await _restClient.downloadCookie(request);
    return response.data;
  }

  // ===========================================================================
  // 认证
  // ===========================================================================

  /// 执行握手
  Future<HandshakeResponse?> handshake({
    required Uint8List publicKey,
    required Uint8List challenge,
  }) async {
    if (_localDeviceId == null) return null;

    final request = HandshakeRequest(
      deviceId: _localDeviceId!,
      publicKey: publicKey,
      challenge: challenge,
    );

    final response = await _restClient.handshake(request);
    return response.data;
  }

  /// 认证
  Future<AuthenticationResponse?> authenticate({
    required Uint8List signedToken,
  }) async {
    if (_localDeviceId == null) return null;

    final request = AuthenticationRequest(
      deviceId: _localDeviceId!,
      signedToken: signedToken,
    );

    final response = await _restClient.authenticate(request);
    return response.data;
  }

  /// 检查认证状态
  Future<bool> checkAuth() async {
    final response = await _restClient.checkAuth();
    return response.success;
  }

  /// 注销
  Future<bool> logout() async {
    final response = await _restClient.logout();
    return response.success;
  }

  // ===========================================================================
  // 同步
  // ===========================================================================

  /// 请求同步
  Future<SyncResponse?> requestSync({
    required int sinceTimestamp,
    List<String> dataTypes = const ['credentials', 'cookies', 'settings'],
  }) async {
    if (_connectionState != EcalConnectionState.connected) {
      return null;
    }

    final request = SyncRequest(
      syncId: _generateMessageId(),
      sinceTimestamp: sinceTimestamp,
      dataTypes: dataTypes,
    );

    final response = await _restClient.requestSync(request);
    return response.data;
  }

  /// 推送更新
  Future<bool> pushUpdate(SyncItem item) async {
    if (_connectionState != EcalConnectionState.connected) {
      return false;
    }

    final response = await _restClient.pushUpdate(item);
    return response.success;
  }

  // ===========================================================================
  // 心跳
  // ===========================================================================

  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_config.heartbeatInterval, (_) async {
      if (_connectionState != EcalConnectionState.connected || _localDeviceId == null) {
        return;
      }

      _heartbeatSequence++;
      
      final heartbeat = Heartbeat(
        deviceId: _localDeviceId!,
        sequence: _heartbeatSequence,
        status: DeviceStatus(
          online: true,
          batteryLevel: 100.0, // TODO: 获取实际电量
        ),
      );

      // 尝试原生心跳
      if (_activeMode == CommunicationMode.native || _activeMode == CommunicationMode.hybrid) {
        await _platformChannel.startHeartbeat(
          interval: _config.heartbeatInterval,
        );
      }

      // REST 心跳
      await _restClient.sendHeartbeat(heartbeat);
    });
  }

  // ===========================================================================
  // 设备管理
  // ===========================================================================

  /// 获取已配对设备
  Future<List<Map<String, dynamic>>> getPairedDevices() async {
    final response = await _restClient.getPairedDevices();
    return response.data ?? [];
  }

  /// 取消配对
  Future<bool> unpairDevice(String deviceId) async {
    final response = await _restClient.unpairDevice(deviceId);
    return response.success;
  }

  // ===========================================================================
  // 内部方法
  // ===========================================================================

  void _updateConnectionState(EcalConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      _connectionStateController.add(newState);
      notifyListeners();
    }
  }

  void _updatePairingState(PairingState newState) {
    if (_pairingState != newState) {
      _pairingState = newState;
      notifyListeners();
    }
  }

  String _generateDeviceId() {
    return 'flutter_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode.toRadixString(16)}';
  }

  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().hashCode.toRadixString(16)}';
  }

  /// 发送事件
  void _sendEvent(EventType type, String message, {Map<String, dynamic>? data}) {
    final event = Event(
      eventId: _generateMessageId(),
      type: type,
      deviceId: _localDeviceId ?? 'unknown',
      message: message,
      data: data,
    );
    _eventController.add(event);
  }
}