import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 认证状态
class AuthState {
  final bool isAuthenticated;
  final String? userId;
  final String? userName;
  final DateTime? authenticatedAt;
  final bool biometricEnabled;

  const AuthState({
    this.isAuthenticated = false,
    this.userId,
    this.userName,
    this.authenticatedAt,
    this.biometricEnabled = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? userName,
    DateTime? authenticatedAt,
    bool? biometricEnabled,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      authenticatedAt: authenticatedAt ?? this.authenticatedAt,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }

  factory AuthState.unauthenticated() => const AuthState();

  factory AuthState.authenticated({
    required String userId,
    String? userName,
    bool biometricEnabled = false,
  }) {
    return AuthState(
      isAuthenticated: true,
      userId: userId,
      userName: userName,
      authenticatedAt: DateTime.now(),
      biometricEnabled: biometricEnabled,
    );
  }
}

/// 认证状态 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated());

  /// 使用 PIN 码登录
  Future<bool> loginWithPin(String pin) async {
    // TODO: 实现 PIN 验证逻辑
    // 这里应该与安全存储服务验证 PIN
    
    // 模拟验证
    if (pin.length >= 4) {
      state = AuthState.authenticated(
        userId: 'local_user',
        userName: '用户',
      );
      return true;
    }
    return false;
  }

  /// 使用生物识别登录
  Future<bool> loginWithBiometric() async {
    // TODO: 调用生物识别验证
    // 这里应该调用 SecureStorageService.authenticateWithBiometric()
    
    // 模拟成功验证
    state = AuthState.authenticated(
      userId: 'local_user',
      userName: '用户',
      biometricEnabled: true,
    );
    return true;
  }

  /// 登出
  Future<void> logout() async {
    state = AuthState.unauthenticated();
  }

  /// 启用/禁用生物识别
  void setBiometricEnabled(bool enabled) {
    state = state.copyWith(biometricEnabled: enabled);
  }

  /// 检查是否需要重新认证（会话超时）
  bool needsReauth(Duration timeout) {
    if (!state.isAuthenticated) return true;
    if (state.authenticatedAt == null) return true;
    
    return DateTime.now().difference(state.authenticatedAt!) > timeout;
  }

  /// 刷新会话时间
  void refreshSession() {
    if (state.isAuthenticated) {
      state = state.copyWith(authenticatedAt: DateTime.now());
    }
  }
}

/// 认证 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// PIN 状态 Provider
final pinStatusProvider = StateProvider<bool>((ref) => false);

/// 生物识别可用性 Provider
final biometricAvailabilityProvider = FutureProvider<bool>((ref) async {
  // TODO: 实际检查生物识别可用性
  // 应该调用 SecureStorageService.isBiometricAvailable()
  return true;
});