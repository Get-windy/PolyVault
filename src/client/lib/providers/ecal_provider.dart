/// eCAL 服务 Provider
/// 提供全局访问 eCAL 服务的 Riverpod Provider

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ecal_service.dart';
import '../services/ecal_protocol.dart';

/// eCAL 服务配置 Provider
final ecalConfigProvider = Provider<EcalServiceConfig>((ref) {
  return const EcalServiceConfig(
    preferredMode: CommunicationMode.hybrid,
    restBaseUrl: 'http://localhost:3001',
    heartbeatInterval: Duration(seconds: 10),
    discoveryInterval: Duration(seconds: 5),
  );
});

/// eCAL 服务实例 Provider
final ecalServiceProvider = Provider<EcalService>((ref) {
  final config = ref.watch(ecalConfigProvider);
  final service = EcalService(config: config);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 连接状态 Provider
final ecalConnectionStateProvider = StateNotifierProvider<EcalConnectionNotifier, EcalConnectionState>((ref) {
  final service = ref.watch(ecalServiceProvider);
  return EcalConnectionNotifier(service);
});

class EcalConnectionNotifier extends StateNotifier<EcalConnectionState> {
  final EcalService _service;
  
  EcalConnectionNotifier(this._service) : super(_service.connectionState) {
    _service.connectionStateStream.listen((state) {
      state = state;
    });
  }
  
  Future<bool> initialize({String? deviceName}) async {
    return await _service.initialize(deviceName: deviceName);
  }
  
  Future<void> dispose() async {
    await _service.dispose();
  }
}

/// 发现设备列表 Provider
final discoveredDevicesProvider = StateNotifierProvider<DiscoveredDevicesNotifier, List<DiscoveryMessage>>((ref) {
  final service = ref.watch(ecalServiceProvider);
  return DiscoveredDevicesNotifier(service);
});

class DiscoveredDevicesNotifier extends StateNotifier<List<DiscoveryMessage>> {
  final EcalService _service;
  
  DiscoveredDevicesNotifier(this._service) : super([]) {
    _service.deviceDiscovery.listen((device) {
      state = [...state, device];
    });
  }
  
  void startDiscovery() {
    _service.startDeviceDiscovery();
  }
  
  void stopDiscovery() {
    _service.stopDeviceDiscovery();
    state = [];
  }
  
  void clear() {
    state = [];
  }
}

/// 配对状态 Provider
final pairingStateProvider = StateProvider<PairingState>((ref) {
  return PairingState.idle;
});

/// 凭证请求列表 Provider
final pendingCredentialRequestsProvider = StateNotifierProvider<PendingCredentialRequestsNotifier, List<CredentialRequest>>((ref) {
  final service = ref.watch(ecalServiceProvider);
  return PendingCredentialRequestsNotifier(service);
});

class PendingCredentialRequestsNotifier extends StateNotifier<List<CredentialRequest>> {
  final EcalService _service;
  
  PendingCredentialRequestsNotifier(this._service) : super([]) {
    _service.credentialRequests.listen((request) {
      state = [...state, request];
    });
  }
  
  void removeRequest(String requestId) {
    state = state.where((r) => r.sessionId != requestId).toList();
  }
  
  void clear() {
    state = [];
  }
}

/// 本地设备信息 Provider
final localDeviceInfoProvider = Provider<Map<String, String>>((ref) {
  final service = ref.watch(ecalServiceProvider);
  return {
    'deviceId': service.localDeviceId ?? '',
    'deviceName': service.localDeviceName ?? '',
  };
});

/// eCAL 操作扩展
extension EcalServiceOperations on EcalService {
  /// 便捷方法：获取并解密凭证
  Future<Map<String, dynamic>?> getDecryptedCredential({
    required String serviceUrl,
    required String sessionId,
  }) async {
    final response = await getCredential(
      serviceUrl: serviceUrl,
      sessionId: sessionId,
    );
    
    if (response == null || !response.success) {
      return null;
    }
    
    // TODO: 解密凭证
    return {
      'sessionId': response.sessionId,
      'encryptedCredential': response.encryptedCredential,
    };
  }
  
  /// 便捷方法：存储加密凭证
  Future<bool> storeEncryptedCredential({
    required String serviceUrl,
    required String username,
    required String password,
    required String sessionId,
  }) async {
    // TODO: 加密凭证
    final encryptedCredential = Uint8List.fromList(
      utf8.encode('$username:$password'),
    );
    
    return await storeCredential(
      serviceUrl: serviceUrl,
      encryptedCredential: encryptedCredential,
      sessionId: sessionId,
    );
  }
}