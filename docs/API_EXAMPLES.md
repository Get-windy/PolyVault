# PolyVault API 使用示例集

**版本**: v1.0  
**创建时间**: 2026-03-21  
**最后更新**: 2026-03-21  
**适用版本**: PolyVault v0.2.0+

---

## 📖 目录

1. [快速开始](#快速开始)
2. [凭证管理示例](#凭证管理示例)
3. [权限管理示例](#权限管理示例)
4. [Agent 白名单示例](#agent-白名单示例)
5. [K 宝验证示例](#k-宝验证示例)
6. [设备管理示例](#设备管理示例)
7. [eCAL 通信示例](#ecal-通信示例)
8. [错误处理示例](#错误处理示例)
9. [多语言示例](#多语言示例)

---

## 快速开始

### 环境准备

```yaml
# pubspec.yaml
dependencies:
  polyvault:
    path: ../polyvault_flutter
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.1.0
```

### 初始化客户端

```dart
import 'package:polyvault/polyvault.dart';

class PolyVaultService {
  late final EcalClient _client;
  late final SecureStorage _storage;
  
  Future<void> initialize() async {
    // 1. 初始化安全存储
    _storage = SecureStorage();
    await _storage.init();
    
    // 2. 初始化 eCAL 客户端
    _client = EcalClient('PolyVaultClient');
    await _client.init();
    
    // 3. 设置消息处理器
    _setupMessageHandlers();
    
    print('✅ PolyVault 初始化完成');
  }
  
  void _setupMessageHandlers() {
    _client.onMessage('credential_request', _handleCredentialRequest);
    _client.onMessage('sync_status', _handleSyncStatus);
  }
}
```

---

## 凭证管理示例

### 示例 1: 添加凭证

```dart
/// 添加新的凭证
Future<Credential> addCredential({
  required String title,
  required String username,
  required String password,
  required String service,
  String? url,
  String? notes,
}) async {
  // 1. 验证用户身份
  final authenticated = await _requireAuthentication();
  if (!authenticated) {
    throw PolyVaultException('认证失败');
  }
  
  // 2. 创建凭证对象
  final credential = Credential(
    id: _generateId(),
    title: title,
    username: username,
    password: password,
    service: service,
    url: url,
    notes: notes,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  // 3. 加密敏感数据
  final encryptedCredential = await _encryptCredential(credential);
  
  // 4. 存储到本地
  await _storage.save(credential.id, encryptedCredential);
  
  // 5. 同步到其他设备
  await _syncCredential(credential);
  
  return credential;
}

// 使用示例
void main() async {
  final service = PolyVaultService();
  await service.initialize();
  
  final credential = await service.addCredential(
    title: 'GitHub',
    username: 'developer',
    password: 'secure_password_123',
    service: 'github.com',
    url: 'https://github.com',
  );
  
  print('✅ 凭证已创建: ${credential.id}');
}
```

### 示例 2: 检索凭证

```dart
/// 检索凭证（支持模糊搜索）
Future<List<Credential>> searchCredentials(String query) async {
  final allCredentials = await _storage.getAll();
  
  if (query.isEmpty) {
    return allCredentials;
  }
  
  // 模糊搜索
  return allCredentials.where((cred) {
    final searchText = '${cred.title} ${cred.username} ${cred.service}'.toLowerCase();
    return searchText.contains(query.toLowerCase());
  }).toList();
}

/// 获取单个凭证（需要身份验证）
Future<Credential?> getCredential(String id) async {
  // 1. 检查权限
  final level = await _client.getPermissionLevel();
  if (level == PermissionLevel.normal) {
    throw PolyVaultException('权限不足，需要增强或最高权限');
  }
  
  // 2. 解密凭证
  final encrypted = await _storage.get(id);
  if (encrypted == null) return null;
  
  return await _decryptCredential(encrypted);
}
```

### 示例 3: 自动填充

```dart
/// 自动填充服务
class AutoFillService {
  final PolyVaultService _polyvault;
  
  AutoFillService(this._polyvault);
  
  /// 获取匹配的凭证
  Future<List<Credential>> getMatchingCredentials(String domain) async {
    final credentials = await _polyvault.searchCredentials(domain);
    
    return credentials.where((cred) {
      // 匹配域名
      if (cred.url != null) {
        final credDomain = Uri.parse(cred.url!).host;
        return credDomain == domain || credDomain.endsWith('.$domain');
      }
      // 匹配服务名
      return cred.service.toLowerCase() == domain.toLowerCase();
    }).toList();
  }
  
  /// 自动填充（需要用户确认）
  Future<void> autoFill(String credentialId) async {
    final credential = await _polyvault.getCredential(credentialId);
    if (credential == null) return;
    
    // 复制到剪贴板
    await Clipboard.setData(ClipboardData(text: credential.password));
    
    // 记录使用日志
    await _logUsage(credentialId, 'auto_fill');
    
    print('✅ 密码已复制到剪贴板');
  }
}
```

---

## 权限管理示例

### 示例 4: 设置权限级别

```dart
/// 权限管理器
class PermissionManager {
  final EcalClient _client;
  
  PermissionManager(this._client);
  
  /// 提升权限级别
  Future<bool> elevatePermission(PermissionLevel targetLevel) async {
    // 1. 获取当前权限
    final current = await _client.getPermissionLevel();
    
    // 2. 检查是否需要验证
    if (targetLevel.index > current.index) {
      // 需要生物认证
      final biometricData = await _requestBiometric();
      if (biometricData == null) {
        return false;
      }
      
      // 3. 发送权限请求
      final request = PermissionLevelRequest()
        ..deviceId = await getDeviceId()
        ..level = targetLevel
        ..biometricVerification = biometricData
        ..timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final response = await _client.call(
        method: 'SetPermissionLevel',
        request: request,
      );
      
      return response.success;
    }
    
    return true;
  }
  
  /// 执行需要高权限的操作
  Future<T> withElevatedPermission<T>(
    PermissionLevel requiredLevel,
    Future<T> Function() action,
  ) async {
    // 1. 提升权限
    final elevated = await elevatePermission(requiredLevel);
    if (!elevated) {
      throw PolyVaultException('权限提升失败');
    }
    
    try {
      // 2. 执行操作
      return await action();
    } finally {
      // 3. 自动降级
      await _client.setPermissionLevel(PermissionLevel.normal);
    }
  }
}

// 使用示例
void main() async {
  final manager = PermissionManager(client);
  
  // 执行需要增强权限的操作
  await manager.withElevatedPermission(
    PermissionLevel.enhanced,
    () async {
      final credential = await getCredential('sensitive_id');
      return credential;
    },
  );
}
```

### 示例 5: 权限过期处理

```dart
/// 权限过期监控
class PermissionMonitor {
  final EcalClient _client;
  Timer? _timer;
  
  PermissionMonitor(this._client);
  
  void startMonitoring() {
    _timer = Timer.periodic(Duration(minutes: 1), (_) async {
      final level = await _client.getPermissionLevel();
      final expiry = await _client.getPermissionExpiry();
      
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        // 权限已过期
        await _handlePermissionExpired(level);
      } else if (expiry != null) {
        // 即将过期（5分钟内）
        final remaining = expiry.difference(DateTime.now());
        if (remaining.inMinutes <= 5) {
          _showExpiryWarning(remaining);
        }
      }
    });
  }
  
  Future<void> _handlePermissionExpired(PermissionLevel level) async {
    print('⚠️ 权限已过期: $level → normal');
    
    // 通知 UI 更新
    EventBus.emit(PermissionExpiredEvent(level));
  }
  
  void _showExpiryWarning(Duration remaining) {
    print('⚠️ 权限将在 ${remaining.inMinutes} 分钟后过期');
  }
  
  void stopMonitoring() {
    _timer?.cancel();
  }
}
```

---

## Agent 白名单示例

### 示例 6: 管理白名单

```dart
/// Agent 白名单管理器
class AgentWhitelistManager {
  final EcalClient _client;
  
  AgentWhitelistManager(this._client);
  
  /// 添加 Agent 到白名单
  Future<bool> addAgent({
    required String agentId,
    required String certificate,
    required List<String> allowedServices,
  }) async {
    // 1. 验证用户身份
    final biometricData = await BiometricAuth.authenticate(
      reason: '添加 Agent 需要验证身份',
    );
    if (biometricData == null) return false;
    
    // 2. 创建请求
    final request = AddAgentWhitelistRequest()
      ..deviceId = await getDeviceId()
      ..agentId = agentId
      ..agentCertificate = certificate.codeUnits
      ..allowedServices.addAll(allowedServices)
      ..biometricVerification = biometricData
      ..timestamp = DateTime.now().millisecondsSinceEpoch;
    
    // 3. 发送请求
    final response = await _client.call(
      method: 'AddAgentToWhitelist',
      request: request,
    );
    
    if (response.success) {
      print('✅ Agent 已添加到白名单');
      print('过期时间: ${response.expiryTimestamp}');
      return true;
    } else {
      print('❌ 添加失败: ${response.errorMessage}');
      return false;
    }
  }
  
  /// 移除 Agent
  Future<bool> removeAgent(String agentId) async {
    final request = RemoveAgentWhitelistRequest()
      ..deviceId = await getDeviceId()
      ..agentId = agentId
      ..timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final response = await _client.call(
      method: 'RemoveAgentFromWhitelist',
      request: request,
    );
    
    return response.success;
  }
  
  /// 获取白名单列表
  Future<List<WhitelistedAgent>> getWhitelist() async {
    final request = GetWhitelistRequest()
      ..deviceId = await getDeviceId();
    
    final response = await _client.call(
      method: 'GetWhitelist',
      request: request,
    );
    
    return response.agents;
  }
}

// 使用示例
void main() async {
  final manager = AgentWhitelistManager(client);
  
  // 添加可信 Agent
  await manager.addAgent(
    agentId: 'agent_openclaw_001',
    certificate: 'MIIBIjANBg...',
    allowedServices: [
      'credential_provider',
      'cookie_storage',
    ],
  );
  
  // 查看白名单
  final whitelist = await manager.getWhitelist();
  print('白名单 Agent 数量: ${whitelist.length}');
}
```

---

## K 宝验证示例

### 示例 7: K 宝验证流程

```dart
/// K 宝验证服务
class KeyTokenService {
  final EcalClient _client;
  
  KeyTokenService(this._client);
  
  /// 执行 K 宝验证
  Future<bool> verifyKeyToken(KeyTokenType type) async {
    // 1. 检测 K 宝类型
    final detected = await _detectKeyToken(type);
    if (!detected) {
      throw PolyVaultException('未检测到 K 宝');
    }
    
    // 2. 发起验证请求
    final request = KeyTokenVerificationRequest()
      ..deviceId = await getDeviceId()
      ..tokenType = type
      ..timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final response = await _client.call(
      method: 'StartKeyTokenVerification',
      request: request,
    );
    
    // 3. 处理验证流程
    switch (type) {
      case KeyTokenType.usb:
        return await _handleUsbVerification(response.challenge);
      case KeyTokenType.nfc:
        return await _handleNfcVerification(response.challenge);
      case KeyTokenType.bluetooth:
        return await _handleBluetoothVerification(response.challenge);
    }
  }
  
  Future<bool> _handleUsbVerification(Uint8List challenge) async {
    print('请在 K 宝上确认操作...');
    
    // 等待用户物理确认
    final signature = await _waitForUsbResponse(challenge);
    
    // 验证签名
    final verifyRequest = KeyTokenSignatureRequest()
      ..deviceId = await getDeviceId()
      ..signature = signature;
    
    final response = await _client.call(
      method: 'VerifyKeyTokenSignature',
      request: verifyRequest,
    );
    
    return response.success;
  }
  
  Future<bool> _handleNfcVerification(Uint8List challenge) async {
    print('请将 K 宝靠近手机 NFC 区域...');
    
    // NFC 通信
    final nfcResponse = await NfcManager.instance.transceive(challenge);
    
    final verifyRequest = KeyTokenSignatureRequest()
      ..deviceId = await getDeviceId()
      ..signature = nfcResponse;
    
    final response = await _client.call(
      method: 'VerifyKeyTokenSignature',
      request: verifyRequest,
    );
    
    return response.success;
  }
}
```

---

## 设备管理示例

### 示例 8: 多设备同步

```dart
/// 设备同步服务
class DeviceSyncService {
  final EcalClient _client;
  final SecureStorage _storage;
  
  DeviceSyncService(this._client, this._storage);
  
  /// 同步凭证到所有设备
  Future<void> syncCredentials() async {
    // 1. 获取本地凭证
    final localCredentials = await _storage.getAll();
    final localVersion = await _storage.getVersion();
    
    // 2. 请求远程版本
    final request = SyncRequest()
      ..deviceId = await getDeviceId()
      ..localVersion = localVersion;
    
    final response = await _client.call(
      method: 'SyncCredentials',
      request: request,
    );
    
    // 3. 处理同步冲突
    if (response.needsMerge) {
      await _handleMerge(response.serverCredentials, localCredentials);
    } else if (response.serverVersion > localVersion) {
      // 服务器版本更新，拉取更新
      await _pullUpdates(response.serverCredentials);
    } else {
      // 本地版本更新，推送更新
      await _pushUpdates(localCredentials);
    }
  }
  
  Future<void> _handleMerge(
    List<Credential> serverCreds,
    List<Credential> localCreds,
  ) async {
    // 使用 last-write-wins 策略
    final merged = <String, Credential>{};
    
    for (final cred in [...serverCreds, ...localCreds]) {
      final existing = merged[cred.id];
      if (existing == null || cred.updatedAt.isAfter(existing.updatedAt)) {
        merged[cred.id] = cred;
      }
    }
    
    // 保存合并结果
    await _storage.saveAll(merged.values.toList());
    
    // 推送合并结果到服务器
    await _pushUpdates(merged.values.toList());
  }
}
```

---

## eCAL 通信示例

### 示例 9: 发布订阅模式

```dart
/// eCAL 发布订阅示例
class EcalPubSubExample {
  late final EcalPublisher _publisher;
  late final EcalSubscriber _subscriber;
  
  Future<void> setup() async {
    // 创建发布者
    _publisher = EcalPublisher('credential_updates');
    await _publisher.init();
    
    // 创建订阅者
    _subscriber = EcalSubscriber('credential_updates');
    await _subscriber.init();
    
    // 设置消息回调
    _subscriber.onMessage((topic, data) {
      final update = CredentialUpdate.fromBuffer(data);
      print('📢 收到凭证更新: ${update.credentialId}');
      _handleUpdate(update);
    });
  }
  
  /// 发布凭证更新
  Future<void> publishUpdate(Credential credential) async {
    final update = CredentialUpdate()
      ..credentialId = credential.id
      ..action = UpdateAction.modified
      ..timestamp = DateTime.now().millisecondsSinceEpoch;
    
    await _publisher.send(update.writeToBuffer());
    print('✅ 已发布凭证更新: ${credential.id}');
  }
  
  void _handleUpdate(CredentialUpdate update) {
    // 处理凭证更新
    switch (update.action) {
      case UpdateAction.created:
        // 新建凭证
        break;
      case UpdateAction.modified:
        // 修改凭证
        break;
      case UpdateAction.deleted:
        // 删除凭证
        break;
    }
  }
}
```

### 示例 10: 客户端-服务器模式

```dart
/// eCAL 客户端-服务器示例
class EcalClientServerExample {
  late final EcalServer _server;
  
  Future<void> startServer() async {
    _server = EcalServer('CredentialService');
    await _server.init();
    
    // 注册服务方法
    _server.registerMethod('GetCredential', _handleGetCredential);
    _server.registerMethod('AddCredential', _handleAddCredential);
    _server.registerMethod('DeleteCredential', _handleDeleteCredential);
    
    print('✅ eCAL 服务已启动');
  }
  
  Future<Uint8List> _handleGetCredential(Uint8List requestData) async {
    final request = GetCredentialRequest.fromBuffer(requestData);
    
    // 验证权限
    if (!await _checkPermission(request.deviceId)) {
      return ErrorResponse()
        ..code = ErrorCode.permissionDenied
        ..message = '权限不足'
        .writeToBuffer();
    }
    
    // 获取凭证
    final credential = await _storage.get(request.credentialId);
    if (credential == null) {
      return ErrorResponse()
        ..code = ErrorCode.notFound
        ..message = '凭证不存在'
        .writeToBuffer();
    }
    
    return GetCredentialResponse()
      ..credential = credential
      .writeToBuffer();
  }
}
```

---

## 错误处理示例

### 示例 11: 完整错误处理

```dart
/// 带完整错误处理的 API 调用
class SafeApiCaller {
  final EcalClient _client;
  final Logger _logger = Logger('SafeApiCaller');
  
  SafeApiCaller(this._client);
  
  Future<T?> callWithRetry<T>({
    required String method,
    required Uint8List request,
    required T Function(Uint8List) parser,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        
        final response = await _client.call(
          method: method,
          request: request,
        ).timeout(Duration(seconds: 10));
        
        // 检查错误响应
        if (_isErrorResponse(response)) {
          final error = ErrorResponse.fromBuffer(response);
          throw PolyVaultApiException(error.code, error.message);
        }
        
        return parser(response);
        
      } on TimeoutException {
        _logger.warning('请求超时，重试 $attempts/$maxRetries');
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay * attempts);
        }
      } on PolyVaultApiException catch (e) {
        _logger.error('API 错误: ${e.code} - ${e.message}');
        
        // 权限错误需要特殊处理
        if (e.code == ErrorCode.permissionDenied) {
          await _requestPermission();
          if (attempts < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          }
        }
        
        rethrow;
      } on SocketException catch (e) {
        _logger.error('网络错误: $e');
        if (attempts < maxRetries) {
          await Future.delayed(retryDelay * attempts);
        }
      } catch (e) {
        _logger.error('未知错误: $e');
        rethrow;
      }
    }
    
    _logger.error('重试 $maxRetries 次后仍失败');
    return null;
  }
  
  bool _isErrorResponse(Uint8List data) {
    // 检查响应是否为错误类型
    try {
      final response = ErrorResponse.fromBuffer(data);
      return response.code != ErrorCode.success;
    } catch (_) {
      return false;
    }
  }
}
```

---

## 多语言示例

### Python 客户端示例

```python
# polyvault_client.py
import time
from polyvault import EcalClient, Credential, PermissionLevel

class PolyVaultPythonClient:
    def __init__(self):
        self.client = EcalClient('PythonClient')
        
    def initialize(self):
        self.client.initialize()
        print('✅ PolyVault Python 客户端已初始化')
    
    def get_credential(self, credential_id: str) -> Credential:
        request = {
            'device_id': self._get_device_id(),
            'credential_id': credential_id,
            'timestamp': int(time.time() * 1000)
        }
        
        response = self.client.call('GetCredential', request)
        
        if response['success']:
            return Credential.from_dict(response['credential'])
        else:
            raise Exception(response['error_message'])
    
    def set_permission_level(self, level: PermissionLevel) -> bool:
        request = {
            'device_id': self._get_device_id(),
            'level': level.value,
            'timestamp': int(time.time() * 1000)
        }
        
        response = self.client.call('SetPermissionLevel', request)
        return response['success']

# 使用示例
if __name__ == '__main__':
    client = PolyVaultPythonClient()
    client.initialize()
    
    # 获取凭证
    try:
        credential = client.get_credential('cred_123')
        print(f'用户名: {credential.username}')
    except Exception as e:
        print(f'错误: {e}')
```

### Rust FFI 示例

```rust
// src/ffi/polyvault_ffi.rs
use polyvault::{EcalClient, Credential, PermissionLevel};
use std::ffi::{CStr, CString};
use std::os::raw::c_char;

/// 创建 eCAL 客户端
#[no_mangle]
pub extern "C" fn polyvault_client_create() -> *mut EcalClient {
    let client = EcalClient::new("RustClient");
    Box::into_raw(Box::new(client))
}

/// 获取凭证
#[no_mangle]
pub extern "C" fn polyvault_get_credential(
    client: *mut EcalClient,
    credential_id: *const c_char,
) -> *mut c_char {
    let client = unsafe { &mut *client };
    let id = unsafe { CStr::from_ptr(credential_id) }
        .to_str()
        .unwrap();
    
    match client.get_credential(id) {
        Ok(cred) => {
            let json = serde_json::to_string(&cred).unwrap();
            CString::new(json).unwrap().into_raw()
        }
        Err(e) => {
            let error = format!("{{\"error\": \"{}\"}}", e);
            CString::new(error).unwrap().into_raw()
        }
    }
}

/// 设置权限级别
#[no_mangle]
pub extern "C" fn polyvault_set_permission(
    client: *mut EcalClient,
    level: i32,
) -> bool {
    let client = unsafe { &mut *client };
    let level = match level {
        1 => PermissionLevel::Normal,
        2 => PermissionLevel::Enhanced,
        3 => PermissionLevel::Maximum,
        _ => return false,
    };
    
    client.set_permission_level(level).is_ok()
}

/// 释放客户端
#[no_mangle]
pub extern "C" fn polyvault_client_free(client: *mut EcalClient) {
    unsafe {
        drop(Box::from_raw(client));
    }
}
```

---

## 最佳实践

### 1. 始终验证用户身份

```dart
// ✅ 正确
Future<Credential> getCredential(String id) async {
  if (!await _isAuthenticated()) {
    throw PolyVaultException('请先登录');
  }
  return await _fetchCredential(id);
}

// ❌ 错误
Future<Credential> getCredential(String id) async {
  return await _fetchCredential(id); // 未验证身份
}
```

### 2. 使用合适的权限级别

```dart
// ✅ 正确
await permissionManager.withElevatedPermission(
  PermissionLevel.enhanced,
  () => sensitiveOperation(),
);

// ❌ 错误
await sensitiveOperation(); // 未检查权限
```

### 3. 正确处理错误

```dart
// ✅ 正确
try {
  final credential = await getCredential(id);
} on PolyVaultApiException catch (e) {
  switch (e.code) {
    case ErrorCode.permissionDenied:
      await requestPermission();
      break;
    case ErrorCode.notFound:
      showNotFoundMessage();
      break;
    default:
      showError(e.message);
  }
}

// ❌ 错误
try {
  final credential = await getCredential(id);
} catch (e) {
  print('错误: $e'); // 信息不足
}
```

### 4. 及时清理资源

```dart
// ✅ 正确
class CredentialService {
  EcalClient? _client;
  
  Future<void> initialize() async {
    _client = EcalClient('CredentialService');
    await _client!.init();
  }
  
  void dispose() {
    _client?.close();
    _client = null;
  }
}

// ❌ 错误
// 未实现 dispose 方法，资源泄漏
```

---

**最后更新**: 2026-03-21  
**版本**: v1.0  
**维护者**: PolyVault 开发团队