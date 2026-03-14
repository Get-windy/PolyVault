/// 存储统计模型
/// 用于显示存储使用情况
class StorageStats {
  final int totalCredentials;
  final DateTime? lastBackup;

  const StorageStats({
    required this.totalCredentials,
    this.lastBackup,
  });

  factory StorageStats.fromJson(Map<String, dynamic> json) => StorageStats(
        totalCredentials: json['totalCredentials'] as int? ?? 0,
        lastBackup: json['lastBackup'] != null
            ? DateTime.parse(json['lastBackup'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'totalCredentials': totalCredentials,
        'lastBackup': lastBackup?.toIso8601String(),
      };
}

/// 连接状态模型
class ConnectionStatus {
  final bool isConnected;
  final String? serverUrl;
  final String? errorMessage;
  final DateTime? lastConnected;

  const ConnectionStatus({
    required this.isConnected,
    this.serverUrl,
    this.errorMessage,
    this.lastConnected,
  });

  factory ConnectionStatus.disconnected() => const ConnectionStatus(
        isConnected: false,
      );

  factory ConnectionStatus.fromJson(Map<String, dynamic> json) =>
      ConnectionStatus(
        isConnected: json['isConnected'] as bool,
        serverUrl: json['serverUrl'] as String?,
        errorMessage: json['errorMessage'] as String?,
        lastConnected: json['lastConnected'] != null
            ? DateTime.parse(json['lastConnected'] as String)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'isConnected': isConnected,
        'serverUrl': serverUrl,
        'errorMessage': errorMessage,
        'lastConnected': lastConnected?.toIso8601String(),
      };
}

/// API 响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;

  const ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
  });

  factory ApiResponse.success(T data, {String? message}) => ApiResponse(
        success: true,
        data: data,
        message: message,
      );

  factory ApiResponse.error(String error) => ApiResponse(
        success: false,
        error: error,
      );
}

/// 用户会话模型
class UserSession {
  final String token;
  final String userId;
  final DateTime expiresAt;

  const UserSession({
    required this.token,
    required this.userId,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
        token: json['token'] as String,
        userId: json['userId'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'token': token,
        'userId': userId,
        'expiresAt': expiresAt.toIso8601String(),
      };
}