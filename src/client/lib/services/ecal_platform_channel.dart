/// eCAL Platform Channel - 原生通信接口
/// 通过 MethodChannel 与原生平台通信
/// 
/// 此文件定义了 Flutter 与原生平台（Android/iOS/Windows）之间的通信接口。
/// 原生平台需要实现相应的 eCAL 集成代码。
/// 
/// 当前状态: 接口定义完成，原生实现待添加

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'ecal_protocol.dart';

/// Platform Channel 方法名常量
class EcalMethods {
  // 初始化
  static const String initialize = 'ecal_initialize';
  static const String finalize = 'ecal_finalize';
  
  // 发布/订阅
  static const String publish = 'ecal_publish';
  static const String subscribe = 'ecal_subscribe';
  static const String unsubscribe = 'ecal_unsubscribe';
  
  // 服务
  static const String createServer = 'ecal_create_server';
  static const String createClient = 'ecal_create_client';
  static const String callService = 'ecal_call_service';
  
  // 设备发现
  static const String startDiscovery = 'ecal_start_discovery';
  static const String stopDiscovery = 'ecal_stop_discovery';
  
  // 凭证操作
  static const String getCredential = 'ecal_get_credential';
  static const String storeCredential = 'ecal_store_credential';
  static const String deleteCredential = 'ecal_delete_credential';
  
  // 心跳
  static const String startHeartbeat = 'ecal_start_heartbeat';
  static const String stopHeartbeat = 'ecal_stop_heartbeat';
  
  // 状态
  static const String getState = 'ecal_get_state';
  static const String getStats = 'ecal_get_stats';
}

/// Platform Channel 配置
class EcalPlatformConfig {
  final String appName;
  final String unitName;
  final bool enableMonitoring;
  final int timeoutMs;

  const EcalPlatformConfig({
    this.appName = 'PolyVault',
    this.unitName = 'flutter_client',
    this.enableMonitoring = true,
    this.timeoutMs = 5000,
  });

  Map<String, dynamic> toMap() {
    return {
      'app_name': appName,
      'unit_name': unitName,
      'enable_monitoring': enableMonitoring,
      'timeout_ms': timeoutMs,
    };
  }
}

/// Platform Channel 原生实现状态
enum NativeImplementationStatus {
  notAvailable,   // 原生实现不可用
  available,      // 原生实现可用
  initialized,    // 已初始化
  error,          // 初始化错误
}

/// eCAL Platform Channel 服务
class EcalPlatformChannel {
  static const MethodChannel _channel = MethodChannel('polyvault/ecal');
  static const EventChannel _eventChannel = EventChannel('polyvault/ecal/events');
  
  static final EcalPlatformChannel _instance = EcalPlatformChannel._internal();
  factory EcalPlatformChannel() => _instance;
  EcalPlatformChannel._internal();

  // 状态
  NativeImplementationStatus _status = NativeImplementationStatus.notAvailable;
  EcalPlatformConfig _config = const EcalPlatformConfig();
  String? _deviceId;
  
  // 事件流
  StreamSubscription? _eventSubscription;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _stateController = StreamController<NativeImplementationStatus>.broadcast();
  
  // Getters
  NativeImplementationStatus get status => _status;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<NativeImplementationStatus> get stateChanges => _stateController.stream;
  String? get deviceId => _deviceId;

  /// 检查原生实现是否可用
  Future<bool> isNativeAvailable() async {
    if (!kReleaseMode && (defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS)) {
      debugPrint('[EcalPlatformChannel] Native eCAL not available on this platform');
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>('is_available');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Platform check failed: ${e.message}');
      return false;
    } on MissingPluginException {
      debugPrint('[EcalPlatformChannel] Native plugin not implemented');
      return false;
    }
  }

  /// 初始化原生 eCAL
  Future<bool> initialize(EcalPlatformConfig config) async {
    if (_status == NativeImplementationStatus.initialized) {
      return true;
    }
    
    _config = config;
    
    try {
      _updateStatus(NativeImplementationStatus.available);
      
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.initialize,
        config.toMap(),
      );
      
      if (result == true) {
        _updateStatus(NativeImplementationStatus.initialized);
        _startEventListening();
        _deviceId = await _generateDeviceId();
        debugPrint('[EcalPlatformChannel] Initialized successfully');
        return true;
      } else {
        _updateStatus(NativeImplementationStatus.error);
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Initialize failed: ${e.message}');
      _updateStatus(NativeImplementationStatus.error);
      return false;
    } on MissingPluginException {
      debugPrint('[EcalPlatformChannel] Native plugin not implemented, using fallback');
      _updateStatus(NativeImplementationStatus.notAvailable);
      return false;
    }
  }

  /// 关闭 eCAL
  Future<void> finalize() async {
    if (_status != NativeImplementationStatus.initialized) {
      return;
    }
    
    try {
      await _channel.invokeMethod(EcalMethods.finalize);
      _eventSubscription?.cancel();
      _updateStatus(NativeImplementationStatus.notAvailable);
      debugPrint('[EcalPlatformChannel] Finalized');
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Finalize failed: ${e.message}');
    }
  }

  // ===========================================================================
  // 发布/订阅
  // ===========================================================================

  /// 发布消息
  Future<bool> publish(
    String topic,
    Map<String, dynamic> message, {
    String? targetDevice,
  }) async {
    if (_status != NativeImplementationStatus.initialized) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.publish,
        {
          'topic': topic,
          'message': message,
          'target_device': targetDevice,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Publish failed: ${e.message}');
      return false;
    }
  }

  /// 订阅主题
  Future<bool> subscribe(String topic) async {
    if (_status != NativeImplementationStatus.initialized) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.subscribe,
        {'topic': topic},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Subscribe failed: ${e.message}');
      return false;
    }
  }

  /// 取消订阅
  Future<bool> unsubscribe(String topic) async {
    if (_status != NativeImplementationStatus.initialized) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.unsubscribe,
        {'topic': topic},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Unsubscribe failed: ${e.message}');
      return false;
    }
  }

  // ===========================================================================
  // 设备发现
  // ===========================================================================

  /// 开始设备发现
  Future<bool> startDiscovery({
    Duration interval = const Duration(seconds: 5),
    void Function(DiscoveryMessage)? onDeviceFound,
  }) async {
    if (_status != NativeImplementationStatus.initialized) {
      return false;
    }
    
    try {
      // 订阅发现主题
      await subscribe('polyvault/discovery');
      
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.startDiscovery,
        {'interval_ms': interval.inMilliseconds},
      );
      
      if (result == true && onDeviceFound != null) {
        messages.listen((msg) {
          if (msg['topic'] == 'polyvault/discovery') {
            try {
              final device = DiscoveryMessage.fromJson(
                msg['payload'] as Map<String, dynamic>,
              );
              onDeviceFound(device);
            } catch (e) {
              debugPrint('[EcalPlatformChannel] Parse discovery message failed: $e');
            }
          }
        });
      }
      
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Start discovery failed: ${e.message}');
      return false;
    }
  }

  /// 停止设备发现
  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod(EcalMethods.stopDiscovery);
      await unsubscribe('polyvault/discovery');
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Stop discovery failed: ${e.message}');
    }
  }

  // ===========================================================================
  // 凭证操作 (RPC 风格)
  // ===========================================================================

  /// 获取凭证
  Future<CredentialResponse?> getCredential(CredentialRequest request) async {
    if (_status != NativeImplementationStatus.initialized) {
      return null;
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        EcalMethods.getCredential,
        request.toJson(),
      );
      
      if (result != null) {
        return CredentialResponse.fromJson(
          Map<String, dynamic>.from(result),
        );
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Get credential failed: ${e.message}');
      return null;
    }
  }

  /// 存储凭证
  Future<bool> storeCredential(CredentialStoreRequest request) async {
    if (_status != NativeImplementationStatus.initialized) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.storeCredential,
        request.toJson(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Store credential failed: ${e.message}');
      return false;
    }
  }

  /// 删除凭证
  Future<bool> deleteCredential(String serviceUrl, String sessionId) async {
    if (_status != NativeImplementationStatus.initialized) {
      return false;
    }
    
    try {
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.deleteCredential,
        {
          'service_url': serviceUrl,
          'session_id': sessionId,
        },
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Delete credential failed: ${e.message}');
      return false;
    }
  }

  // ===========================================================================
  // 心跳
  // ===========================================================================

  /// 开始心跳
  Future<bool> startHeartbeat({
    Duration interval = const Duration(seconds: 10),
    void Function(HeartbeatAck)? onAck,
  }) async {
    if (_status != NativeImplementationStatus.initialized) {
      return false;
    }
    
    try {
      // 订阅心跳响应
      if (onAck != null) {
        await subscribe('polyvault/heartbeat_ack');
        messages.listen((msg) {
          if (msg['topic'] == 'polyvault/heartbeat_ack') {
            try {
              final ack = HeartbeatAck.fromJson(
                msg['payload'] as Map<String, dynamic>,
              );
              onAck(ack);
            } catch (e) {
              debugPrint('[EcalPlatformChannel] Parse heartbeat ack failed: $e');
            }
          }
        });
      }
      
      final result = await _channel.invokeMethod<bool>(
        EcalMethods.startHeartbeat,
        {'interval_ms': interval.inMilliseconds},
      );
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Start heartbeat failed: ${e.message}');
      return false;
    }
  }

  /// 停止心跳
  Future<void> stopHeartbeat() async {
    try {
      await _channel.invokeMethod(EcalMethods.stopHeartbeat);
      await unsubscribe('polyvault/heartbeat_ack');
    } on PlatformException catch (e) {
      debugPrint('[EcalPlatformChannel] Stop heartbeat failed: ${e.message}');
    }
  }

  // ===========================================================================
  // 状态查询
  // ===========================================================================

  /// 获取连接状态
  Future<Map<String, dynamic>?> getState() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        EcalMethods.getState,
      );
      return result != null ? Map<String, dynamic>.from(result) : null;
    } on PlatformException {
      return null;
    }
  }

  /// 获取统计信息
  Future<Map<String, dynamic>?> getStats() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        EcalMethods.getStats,
      );
      return result != null ? Map<String, dynamic>.from(result) : null;
    } on PlatformException {
      return null;
    }
  }

  // ===========================================================================
  // 内部方法
  // ===========================================================================

  void _updateStatus(NativeImplementationStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _stateController.add(newStatus);
    }
  }

  void _startEventListening() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          _messageController.add(Map<String, dynamic>.from(event));
        }
      },
      onError: (error) {
        debugPrint('[EcalPlatformChannel] Event stream error: $error');
      },
    );
  }

  Future<String> _generateDeviceId() async {
    try {
      final result = await _channel.invokeMethod<String>('get_device_id');
      return result ?? 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    } on PlatformException {
      return 'flutter_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _messageController.close();
    _stateController.close();
  }
}