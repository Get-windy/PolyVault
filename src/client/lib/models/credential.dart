/// 凭证数据模型
/// 用于安全存储用户名密码等敏感信息
class Credential {
  final String id;
  final String serviceName;
  final String username;
  final String password;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Credential({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.password,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建凭证
  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
        id: json['id'] as String,
        serviceName: json['serviceName'] as String,
        username: json['username'] as String,
        password: json['password'] as String,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// 转换为 JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'username': username,
        'password': password,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// 复制并修改
  Credential copyWith({
    String? id,
    String? serviceName,
    String? username,
    String? password,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Credential(
      id: id ?? this.id,
      serviceName: serviceName ?? this.serviceName,
      username: username ?? this.username,
      password: password ?? this.password,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Credential(id: $id, serviceName: $serviceName, username: $username)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Credential && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 凭证摘要（列表展示用，不包含密码）
class CredentialSummary {
  final String id;
  final String serviceName;
  final String username;
  final DateTime createdAt;

  const CredentialSummary({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.createdAt,
  });

  factory CredentialSummary.fromJson(Map<String, dynamic> json) => CredentialSummary(
        id: json['id'] as String,
        serviceName: json['serviceName'] as String,
        username: json['username'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'username': username,
        'createdAt': createdAt.toIso8601String(),
      };
}