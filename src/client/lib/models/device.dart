/// 设备数据模型
/// 表示已连接/注册的设备
class Device {
  final String id;
  final String name;
  final String platform;
  final DeviceStatus status;
  final DateTime lastConnected;
  final String? ipAddress;
  final bool isTrusted;

  const Device({
    required this.id,
    required this.name,
    required this.platform,
    required this.status,
    required this.lastConnected,
    this.ipAddress,
    this.isTrusted = false,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
        id: json['id'] as String,
        name: json['name'] as String,
        platform: json['platform'] as String,
        status: DeviceStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DeviceStatus.offline,
        ),
        lastConnected: DateTime.parse(json['lastConnected'] as String),
        ipAddress: json['ipAddress'] as String?,
        isTrusted: json['isTrusted'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'platform': platform,
        'status': status.name,
        'lastConnected': lastConnected.toIso8601String(),
        'ipAddress': ipAddress,
        'isTrusted': isTrusted,
      };

  Device copyWith({
    String? id,
    String? name,
    String? platform,
    DeviceStatus? status,
    DateTime? lastConnected,
    String? ipAddress,
    bool? isTrusted,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      lastConnected: lastConnected ?? this.lastConnected,
      ipAddress: ipAddress ?? this.ipAddress,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }
}

/// 设备状态枚举
enum DeviceStatus {
  online,
  offline,
  connecting,
  error,
}

/// 设备连接请求
class DeviceConnectionRequest {
  final String deviceName;
  final String platform;
  final String publicKey;

  const DeviceConnectionRequest({
    required this.deviceName,
    required this.platform,
    required this.publicKey,
  });

  factory DeviceConnectionRequest.fromJson(Map<String, dynamic> json) =>
      DeviceConnectionRequest(
        deviceName: json['deviceName'] as String,
        platform: json['platform'] as String,
        publicKey: json['publicKey'] as String,
      );

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'platform': platform,
        'publicKey': publicKey,
      };
}