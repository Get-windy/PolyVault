import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';

/// API 服务 Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// 连接状态 Provider
final connectionStatusProvider = StateNotifierProvider<ConnectionStatusNotifier, ConnectionStatus>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ConnectionStatusNotifier(apiService);
});

class ConnectionStatusNotifier extends StateNotifier<ConnectionStatus> {
  final ApiService _apiService;

  ConnectionStatusNotifier(this._apiService) : super(ConnectionStatus.disconnected());

  Future<void> checkConnection() async {
    try {
      final status = await _apiService.checkConnection();
      state = status;
    } catch (e) {
      state = ConnectionStatus(
        isConnected: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> connect(String serverUrl) async {
    try {
      await _apiService.connect(serverUrl);
      state = ConnectionStatus(
        isConnected: true,
        serverUrl: serverUrl,
        lastConnected: DateTime.now(),
      );
    } catch (e) {
      state = ConnectionStatus(
        isConnected: false,
        serverUrl: serverUrl,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    await _apiService.disconnect();
    state = ConnectionStatus.disconnected();
  }
}

/// 凭证列表 Provider
final credentialListProvider = StateNotifierProvider<CredentialListNotifier, AsyncValue<List<CredentialSummary>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CredentialListNotifier(apiService);
});

class CredentialListNotifier extends StateNotifier<AsyncValue<List<CredentialSummary>>> {
  final ApiService _apiService;

  CredentialListNotifier(this._apiService) : super(const AsyncValue.loading());

  Future<void> loadCredentials() async {
    state = const AsyncValue.loading();
    try {
      final credentials = await _apiService.getCredentials();
      state = AsyncValue.data(credentials);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCredential(Credential credential) async {
    try {
      await _apiService.addCredential(credential);
      await loadCredentials();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteCredential(String id) async {
    try {
      await _apiService.deleteCredential(id);
      await loadCredentials();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 设备列表 Provider
final deviceListProvider = StateNotifierProvider<DeviceListNotifier, AsyncValue<List<Device>>>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DeviceListNotifier(apiService);
});

class DeviceListNotifier extends StateNotifier<AsyncValue<List<Device>>> {
  final ApiService _apiService;

  DeviceListNotifier(this._apiService) : super(const AsyncValue.loading());

  Future<void> loadDevices() async {
    state = const AsyncValue.loading();
    try {
      final devices = await _apiService.getDevices();
      state = AsyncValue.data(devices);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> connectDevice(DeviceConnectionRequest request) async {
    try {
      await _apiService.connectDevice(request);
      await loadDevices();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> disconnectDevice(String deviceId) async {
    try {
      await _apiService.disconnectDevice(deviceId);
      await loadDevices();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> trustDevice(String deviceId) async {
    try {
      await _apiService.trustDevice(deviceId);
      await loadDevices();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 存储统计 Provider
final storageStatsProvider = FutureProvider<StorageStats>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getStorageStats();
});

/// 当前选中的凭证 Provider
final selectedCredentialProvider = StateProvider<Credential?>((ref) => null);

/// 生物识别可用性 Provider
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.isBiometricAvailable();
});