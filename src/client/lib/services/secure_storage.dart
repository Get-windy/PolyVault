import 'dart:convert';
import 'package:zk_vault/zk_vault.dart';

/// 凭证数据模型
class Credential {
  final String id;
  final String serviceName;
  final String username;
  final String password;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Credential({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.password,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'serviceName': serviceName,
        'username': username,
        'password': password,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
        id: json['id'],
        serviceName: json['serviceName'],
        username: json['username'],
        password: json['password'],
        notes: json['notes'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

/// 安全存储服务
/// 使用zk_vault实现硬件级安全存储
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final ZkVault _vault = ZkVault();
  bool _isInitialized = false;

  /// 初始化安全存储
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _vault.initialize(
        serviceName: 'polyvault_credentials',
        enableBiometric: true,
        requireBiometric: false,
      );
      _isInitialized = true;
    } catch (e) {
      throw SecureStorageException('初始化安全存储失败: $e');
    }
  }

  /// 保存凭证
  /// 
  /// [serviceName] - 服务名称（如 "GitHub", "AWS"）
  /// [username] - 用户名
  /// [password] - 密码（将被加密存储）
  /// [notes] - 可选备注
  Future<void> saveCredential({
    required String serviceName,
    required String username,
    required String password,
    String? notes,
  }) async {
    await _ensureInitialized();

    try {
      final credential = Credential(
        id: '${serviceName}_${username}_${DateTime.now().millisecondsSinceEpoch}',
        serviceName: serviceName,
        username: username,
        password: password,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 加密存储凭证
      final encryptedData = await _vault.encrypt(
        utf8.encode(jsonEncode(credential.toJson())),
      );

      // 存储到安全存储
      await _vault.store(
        key: credential.id,
        value: base64Encode(encryptedData),
      );

      // 更新凭证列表索引
      await _updateCredentialIndex(credential.id);
    } catch (e) {
      throw SecureStorageException('保存凭证失败: $e');
    }
  }

  /// 获取凭证
  /// 
  /// [credentialId] - 凭证ID
  /// [requireBiometric] - 是否需要生物识别验证
  Future<Credential?> getCredential(
    String credentialId, {
    bool requireBiometric = false,
  }) async {
    await _ensureInitialized();

    try {
      // 从安全存储读取
      final encryptedBase64 = await _vault.retrieve(
        key: credentialId,
        requireBiometric: requireBiometric,
      );

      if (encryptedBase64 == null) return null;

      // 解密凭证
      final decryptedData = await _vault.decrypt(
        base64Decode(encryptedBase64),
        requireBiometric: requireBiometric,
      );

      final json = jsonDecode(utf8.decode(decryptedData));
      return Credential.fromJson(json);
    } catch (e) {
      throw SecureStorageException('获取凭证失败: $e');
    }
  }

  /// 更新凭证
  /// 
  /// [id] - 凭证ID
  /// [serviceName] - 服务名称
  /// [username] - 用户名
  /// [password] - 密码
  /// [notes] - 可选备注
  Future<void> updateCredential({
    required String id,
    required String serviceName,
    required String username,
    required String password,
    String? notes,
  }) async {
    await _ensureInitialized();

    try {
      // 获取原始凭证以保留创建时间
      final existingCredential = await getCredential(id);
      final createdAt = existingCredential?.createdAt ?? DateTime.now();

      final updatedCredential = Credential(
        id: id,
        serviceName: serviceName,
        username: username,
        password: password,
        notes: notes,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

      // 加密存储凭证
      final encryptedData = await _vault.encrypt(
        utf8.encode(jsonEncode(updatedCredential.toJson())),
      );

      // 存储到安全存储
      await _vault.store(
        key: id,
        value: base64Encode(encryptedData),
      );
    } catch (e) {
      throw SecureStorageException('更新凭证失败: $e');
    }
  }

  /// 删除凭证
  Future<void> deleteCredential(String credentialId) async {
    await _ensureInitialized();

    try {
      await _vault.delete(key: credentialId);
      await _removeFromCredentialIndex(credentialId);
    } catch (e) {
      throw SecureStorageException('删除凭证失败: $e');
    }
  }

  /// 获取所有凭证列表（不包含敏感信息）
  Future<List<CredentialSummary>> getCredentialList() async {
    await _ensureInitialized();

    try {
      final indexJson = await _vault.retrieve(key: '_credential_index');
      if (indexJson == null) return [];

      final List<String> ids = jsonDecode(indexJson);
      final List<CredentialSummary> summaries = [];

      for (final id in ids) {
        final credential = await getCredential(id, requireBiometric: false);
        if (credential != null) {
          summaries.add(CredentialSummary(
            id: credential.id,
            serviceName: credential.serviceName,
            username: credential.username,
            createdAt: credential.createdAt,
          ));
        }
      }

      return summaries;
    } catch (e) {
      throw SecureStorageException('获取凭证列表失败: $e');
    }
  }

  /// 检查生物识别可用性
  Future<bool> isBiometricAvailable() async {
    await _ensureInitialized();
    return await _vault.isBiometricAvailable();
  }

  /// 使用生物识别验证访问凭证
  /// 返回验证是否成功
  Future<bool> authenticateWithBiometric({
    String reason = '需要验证身份以访问凭证',
  }) async {
    await _ensureInitialized();
    
    try {
      return await _vault.authenticate(reason: reason);
    } catch (e) {
      throw SecureStorageException('生物识别验证失败: $e');
    }
  }

  /// 安全获取凭证（带生物识别验证）
  /// 如果生物识别不可用，会直接返回凭证
  Future<Credential?> getCredentialSecure(String credentialId) async {
    await _ensureInitialized();

    // 检查生物识别是否可用
    final biometricAvailable = await isBiometricAvailable();
    
    if (biometricAvailable) {
      // 尝试生物识别验证
      final authenticated = await authenticateWithBiometric(
        reason: '验证身份以访问 ${credentialId.split('_').first} 凭证',
      );
      
      if (!authenticated) {
        throw SecureStorageException('生物识别验证失败');
      }
    }

    return getCredential(credentialId, requireBiometric: false);
  }

  /// 检查是否需要生物识别验证
  Future<bool> shouldRequireBiometric() async {
    await _ensureInitialized();
    
    final available = await isBiometricAvailable();
    if (!available) return false;
    
    // 检查用户设置（从安全存储读取偏好）
    final setting = await _vault.retrieve(key: '_biometric_required');
    return setting == 'true';
  }

  /// 设置是否需要生物识别验证
  Future<void> setBiometricRequired(bool required) async {
    await _ensureInitialized();
    await _vault.store(
      key: '_biometric_required',
      value: required ? 'true' : 'false',
    );
  }

  /// 获取存储统计信息
  Future<StorageStats> getStorageStats() async {
    await _ensureInitialized();

    try {
      final credentials = await getCredentialList();
      return StorageStats(
        totalCredentials: credentials.length,
        lastBackup: null, // TODO: 实现备份功能
      );
    } catch (e) {
      throw SecureStorageException('获取存储统计失败: $e');
    }
  }

  /// 确保已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 更新凭证索引
  Future<void> _updateCredentialIndex(String credentialId) async {
    final indexJson = await _vault.retrieve(key: '_credential_index');
    List<String> ids = [];
    
    if (indexJson != null) {
      ids = List<String>.from(jsonDecode(indexJson));
    }
    
    if (!ids.contains(credentialId)) {
      ids.add(credentialId);
      await _vault.store(
        key: '_credential_index',
        value: jsonEncode(ids),
      );
    }
  }

  /// 从索引中移除
  Future<void> _removeFromCredentialIndex(String credentialId) async {
    final indexJson = await _vault.retrieve(key: '_credential_index');
    if (indexJson == null) return;

    List<String> ids = List<String>.from(jsonDecode(indexJson));
    ids.remove(credentialId);
    
    await _vault.store(
      key: '_credential_index',
      value: jsonEncode(ids),
    );
  }
}

/// 凭证摘要（列表展示用，不包含密码）
class CredentialSummary {
  final String id;
  final String serviceName;
  final String username;
  final DateTime createdAt;

  CredentialSummary({
    required this.id,
    required this.serviceName,
    required this.username,
    required this.createdAt,
  });
}

/// 存储统计
class StorageStats {
  final int totalCredentials;
  final DateTime? lastBackup;

  StorageStats({
    required this.totalCredentials,
    this.lastBackup,
  });
}

/// 安全存储异常
class SecureStorageException implements Exception {
  final String message;
  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
