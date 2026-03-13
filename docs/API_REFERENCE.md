# PolyVault API 参考文档

**版本**: v1.0  
**创建时间**: 2026-03-13  
**基于 Protobuf**: openclaw.proto v1.0

---

## 📖 目录

1. [概述](#概述)
2. [Protobuf 消息说明](#protobuf-消息说明)
3. [服务接口说明](#服务接口说明)
4. [使用示例](#使用示例)
5. [错误码](#错误码)
6. [安全说明](#安全说明)

---

## 概述

### API 架构

PolyVault 使用 **Protobuf** 作为接口定义语言，通过 **eCAL** 进行通信。

```
┌──────────────┐      Protobuf/eCAL      ┌──────────────┐
│   客户端     │ ◄─────────────────────► │   服务端     │
│  (Flutter)   │                         │  (OpenClaw)  │
└──────────────┘                         └──────────────┘
```

### 通信模式

| 模式 | 用途 | 示例 |
|------|------|------|
| **发布 - 订阅** | 广播消息、事件通知 | 设备发现、状态更新 |
| **服务 - 客户端** | 请求 - 响应交互 | 凭证请求、Cookie 上传 |

### 数据传输安全

- **传输层**: eCAL 内置加密（UDP/TCP TLS）
- **应用层**: Protobuf 消息使用客户端公钥加密
- **存储层**: zk_vault 硬件级加密（AES-256-GCM）

---

## Protobuf 消息说明

### 1. CredentialRequest（凭证请求）

**用途**: OpenClaw 向客户端请求第三方服务凭证

**定义**:
```protobuf
message CredentialRequest {
    string service_url = 1;      // 目标服务 URL
    string session_id = 2;       // 会话标识符
    uint64 timestamp = 3;        // 请求时间戳（Unix 毫秒）
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| `service_url` | string | 是 | 需要登录的第三方服务 URL | `https://accounts.google.com` |
| `session_id` | string | 是 | 唯一会话标识符（UUID） | `550e8400-e29b-41d4-a716-446655440000` |
| `timestamp` | uint64 | 是 | Unix 时间戳（毫秒） | `1710336000000` |

**使用场景**:
1. OpenClaw 需要访问用户的 Google 账号
2. 发送 `CredentialRequest` 到客户端
3. 客户端返回加密的凭证

---

### 2. CredentialResponse（凭证响应）

**用途**: 客户端返回凭证给 OpenClaw

**定义**:
```protobuf
message CredentialResponse {
    string session_id = 1;           // 对应请求的会话 ID
    bytes encrypted_credential = 2;  // 加密的凭证数据
    bool success = 3;                // 操作是否成功
    string error_message = 4;        // 错误信息（如失败）
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `session_id` | string | 是 | 与请求中的 `session_id` 一致 |
| `encrypted_credential` | bytes | 条件 | 加密的凭证 JSON（成功时必需） |
| `success` | bool | 是 | `true` = 成功，`false` = 失败 |
| `error_message` | string | 条件 | 错误描述（失败时提供） |

**encrypted_credential 格式**:

```json
{
  "service_url": "https://accounts.google.com",
  "username": "user@example.com",
  "password": "encrypted_password",
  "cookies": [
    {
      "name": "SESSIONID",
      "value": "encrypted_cookie_value",
      "domain": ".google.com",
      "expiry": 1710422400000
    }
  ],
  "timestamp": 1710336000000
}
```

**加密方式**:
- 使用 OpenClaw 的公钥加密（RSA-2048 或 ECDSA P-256）
- 客户端持有私钥，服务端无法解密原始数据
- 仅用于传输，服务端直接使用加密数据

---

### 3. CookieUpload（Cookie 上传）

**用途**: 客户端主动上传 Cookie 到 OpenClaw

**定义**:
```protobuf
message CookieUpload {
    string service_url = 1;          // 服务 URL
    bytes encrypted_cookie = 2;      // 加密的 Cookie 数据
    string session_id = 3;           // 会话标识符
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `service_url` | string | 是 | Cookie 所属的服务 URL |
| `encrypted_cookie` | bytes | 是 | 加密的 Cookie JSON |
| `session_id` | string | 是 | 会话标识符（可选，用于跟踪） |

**encrypted_cookie 格式**:

```json
{
  "cookies": [
    {
      "name": "auth_token",
      "value": "encrypted_value",
      "domain": ".example.com",
      "path": "/",
      "secure": true,
      "httpOnly": true,
      "expiry": 1710422400000
    }
  ],
  "timestamp": 1710336000000
}
```

---

### 4. Capability（设备能力）

**用途**: 设备声明自身能力，用于能力虚拟化

**定义**:
```protobuf
message Capability {
    string device_id = 1;                    // 设备唯一标识
    repeated string services = 2;            // 支持的服务列表
    map<string, string> metadata = 3;        // 元数据
}
```

**字段说明**:

| 字段 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| `device_id` | string | 是 | 设备唯一 ID（UUID） | `device-12345` |
| `services` | string[] | 是 | 支持的服务列表 | `["credential_provider", "sensor_data"]` |
| `metadata` | map<string,string> | 否 | 额外元数据 | `{"platform": "android", "version": "1.0"}` |

**预定义服务类型**:

| 服务 | 说明 | 必需能力 |
|------|------|---------|
| `credential_provider` | 提供凭证存储 | zk_vault |
| `sensor_data` | 提供传感器数据 | 加速度计/陀螺仪 |
| `biometric_auth` | 生物认证 | 指纹/面容识别 |
| `secure_storage` | 安全存储 | 硬件加密 |

**metadata 常用字段**:

```protobuf
{
  "platform": "android|ios|windows|macos|linux",
  "platform_version": "13|16|11|13|22.04",
  "app_version": "1.0.0",
  "has_biometric": "true|false",
  "has_secure_element": "true|false"
}
```

---

## 服务接口说明

### CredentialService（凭证服务）

**服务定义**:
```protobuf
service CredentialService {
    // 获取凭证
    rpc GetCredential(CredentialRequest) returns (CredentialResponse);
    
    // 上传 Cookie
    rpc UploadCookie(CookieUpload) returns (CredentialResponse);
}
```

---

### 1. GetCredential（获取凭证）

**接口**: `rpc GetCredential(CredentialRequest) returns (CredentialResponse)`

**调用流程**:

```
OpenClaw                    Client
   │                          │
   │──CredentialRequest──────►│
   │                          │ 1. 验证用户身份
   │                          │ 2. 从 zk_vault 读取凭证
   │                          │ 3. 使用服务端公钥加密
   │◄──CredentialResponse─────│
   │                          │
```

**请求示例** (Dart):

```dart
import 'generated/openclaw.pb.dart';
import 'package:ecal_dart/ecal_dart.dart';

Future<CredentialResponse> getCredential(String serviceUrl) async {
  // 1. 创建请求
  final request = CredentialRequest()
    ..serviceUrl = serviceUrl
    ..sessionId = generateUuid()
    ..timestamp = DateTime.now().millisecondsSinceEpoch;

  // 2. 创建 eCAL 客户端
  final client = EcalClient('CredentialService');
  await client.init();

  // 3. 发送请求
  final response = await client.call(
    method: 'GetCredential',
    request: request,
    timeout: Duration(seconds: 10),
  );

  // 4. 解析响应
  return CredentialResponse.fromBuffer(response);
}
```

**响应示例** (成功):

```protobuf
CredentialResponse {
  session_id: "550e8400-e29b-41d4-a716-446655440000",
  encrypted_credential: <bytes>,
  success: true,
  error_message: ""
}
```

**响应示例** (失败):

```protobuf
CredentialResponse {
  session_id: "550e8400-e29b-41d4-a716-446655440000",
  encrypted_credential: [],
  success: false,
  error_message: "凭证不存在"
}
```

**错误处理**:

| 错误码 | 错误信息 | 原因 | 解决方法 |
|--------|---------|------|---------|
| `AUTH_001` | 用户未认证 | 客户端未登录 | 先完成用户认证 |
| `VAULT_001` | 凭证不存在 | zk_vault 中无此凭证 | 先保存凭证 |
| `VAULT_002` | 生物认证失败 | 指纹/面容验证失败 | 重试或输入密码 |
| `ENCRYPT_001` | 加密失败 | 公钥无效 | 更新服务端公钥 |
| `TIMEOUT` | 请求超时 | 客户端无响应 | 检查网络连接 |

---

### 2. UploadCookie（上传 Cookie）

**接口**: `rpc UploadCookie(CookieUpload) returns (CredentialResponse)`

**调用流程**:

```
Client                      OpenClaw
   │                          │
   │──CookieUpload──────────►│
   │                          │ 1. 验证会话
   │                          │ 2. 存储加密 Cookie
   │                          │ 3. 返回确认
   │◄──CredentialResponse─────│
   │                          │
```

**请求示例** (Dart):

```dart
Future<CredentialResponse> uploadCookie(
  String serviceUrl, 
  List<Cookie> cookies
) async {
  // 1. 创建 Cookie 数据
  final cookieData = {
    'cookies': cookies.map((c) => c.toJson()).toList(),
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };

  // 2. 加密 Cookie
  final encryptedCookie = await encryptWithPublicKey(
    jsonEncode(cookieData),
    serverPublicKey,
  );

  // 3. 创建请求
  final request = CookieUpload()
    ..serviceUrl = serviceUrl
    ..encryptedCookie = encryptedCookie
    ..sessionId = generateUuid();

  // 4. 发送请求
  final client = EcalClient('CredentialService');
  await client.init();

  final response = await client.call(
    method: 'UploadCookie',
    request: request,
  );

  return CredentialResponse.fromBuffer(response);
}
```

**响应示例**:

```protobuf
CredentialResponse {
  session_id: "550e8400-e29b-41d4-a716-446655440000",
  encrypted_credential: [],
  success: true,
  error_message: ""
}
```

---

## 使用示例

### 场景 1: 完整的登录授权流程

```dart
import 'package:polyvault/polyvault.dart';

class LoginFlow {
  final PolyVault _vault = PolyVault();

  // 1. 初始化
  Future<void> initialize() async {
    await _vault.initialize();
    await _vault.connectToOpenClaw();
  }

  // 2. 响应凭证请求
  Future<void> handleCredentialRequest(String serviceUrl) async {
    try {
      // 从 zk_vault 读取凭证
      final credential = await _vault.getCredential(serviceUrl);
      
      if (credential == null) {
        // 凭证不存在，提示用户输入
        final newCredential = await promptUserForCredential(serviceUrl);
        await _vault.saveCredential(serviceUrl, newCredential);
      }

      // 自动返回凭证给 OpenClaw
      await _vault.respondToOpenClaw(serviceUrl, credential);
      
      print('✅ 凭证已提供');
    } catch (e) {
      print('❌ 错误：$e');
    }
  }

  // 3. 上传新 Cookie
  Future<void> uploadCookies(String serviceUrl, List<Cookie> cookies) async {
    await _vault.uploadCookies(serviceUrl, cookies);
    print('✅ Cookie 已上传');
  }
}
```

---

### 场景 2: 设备能力发现

```dart
// 声明设备能力
final capability = Capability()
  ..deviceId = getDeviceId()
  ..services.addAll([
    'credential_provider',
    'biometric_auth',
  ])
  ..metadata['platform'] = 'android'
  ..metadata['platform_version'] = '13'
  ..metadata['has_biometric'] = 'true';

// 发布能力声明
final publisher = EcalPublisher('device_capability');
await publisher.send(capability.writeToBuffer());

// 订阅其他设备能力
final subscriber = EcalSubscriber('device_capability');
subscriber.onMessage = (data) {
  final cap = Capability.fromBuffer(data);
  print('发现设备：${cap.deviceId}');
  print('支持服务：${cap.services}');
};
```

---

### 场景 3: 跨设备凭证同步

```dart
// 设备 A：发布凭证更新
Future<void> syncCredential(String serviceUrl, Credential cred) async {
  final publisher = EcalPublisher('credential_sync');
  
  final syncData = CredentialSync()
    ..serviceUrl = serviceUrl
    ..encryptedCredential = await encrypt(cred)
    ..timestamp = DateTime.now().millisecondsSinceEpoch;
  
  await publisher.send(syncData.writeToBuffer());
}

// 设备 B：接收并存储
subscriber.onMessage = (data) async {
  final sync = CredentialSync.fromBuffer(data);
  
  // 验证来源
  if (await verifyDevice(sync.deviceId)) {
    // 存储到本地 zk_vault
    await vault.saveCredential(
      sync.serviceUrl,
      await decrypt(sync.encryptedCredential),
    );
  }
};
```

---

## 错误码

### 认证错误 (AUTH_XXX)

| 错误码 | 错误信息 | HTTP 状态 | 说明 |
|--------|---------|----------|------|
| `AUTH_001` | 用户未认证 | 401 | 客户端未完成用户认证 |
| `AUTH_002` | 会话过期 | 401 | 会话 ID 已过期 |
| `AUTH_003` | 权限不足 | 403 | 用户无权限访问此凭证 |

### 保险库错误 (VAULT_XXX)

| 错误码 | 错误信息 | HTTP 状态 | 说明 |
|--------|---------|----------|------|
| `VAULT_001` | 凭证不存在 | 404 | zk_vault 中无此凭证 |
| `VAULT_002` | 生物认证失败 | 401 | 指纹/面容验证失败 |
| `VAULT_003` | 保险库锁定 | 423 | zk_vault 被锁定，需解锁 |
| `VAULT_004` | 存储失败 | 500 | 写入 zk_vault 失败 |

### 加密错误 (ENCRYPT_XXX)

| 错误码 | 错误信息 | HTTP 状态 | 说明 |
|--------|---------|----------|------|
| `ENCRYPT_001` | 加密失败 | 500 | 数据加密失败 |
| `ENCRYPT_002` | 解密失败 | 500 | 数据解密失败 |
| `ENCRYPT_003` | 公钥无效 | 400 | 服务端公钥格式错误 |
| `ENCRYPT_004` | 私钥丢失 | 500 | 客户端私钥不存在 |

### 通信错误 (COMM_XXX)

| 错误码 | 错误信息 | HTTP 状态 | 说明 |
|--------|---------|----------|------|
| `COMM_001` | 连接超时 | 408 | eCAL 连接超时 |
| `COMM_002` | 设备不可达 | 404 | 目标设备离线 |
| `COMM_003` | 消息格式错误 | 400 | Protobuf 解析失败 |
| `COMM_004` | 服务未注册 | 404 | eCAL 服务不存在 |

### 系统错误 (SYS_XXX)

| 错误码 | 错误信息 | HTTP 状态 | 说明 |
|--------|---------|----------|------|
| `SYS_001` | 内部错误 | 500 | 系统内部错误 |
| `SYS_002` | 服务不可用 | 503 | 服务暂时不可用 |
| `SYS_003` | 版本不兼容 | 400 | Protobuf 版本不兼容 |

---

## 安全说明

### 1. 数据加密

**传输加密**:
- eCAL 内置 TLS 1.3 加密
- 自动证书验证
- 前向保密（PFS）

**应用加密**:
```dart
// 使用服务端公钥加密
final encrypted = await encryptWithPublicKey(
  plaintext,
  serverPublicKey,
  algorithm: 'RSA-OAEP',  // 或 ECDSA P-256
);

// 仅服务端私钥可解密
```

**存储加密**:
```dart
// zk_vault 使用硬件级加密
await vault.write(
  key: 'credential',
  value: sensitiveData,
  encryption: Encryption.AES_256_GCM,
);
```

---

### 2. 密钥管理

**密钥层次**:
```
根密钥 (硬件保护)
  └─> 派生密钥 1 (凭证加密)
  └─> 派生密钥 2 (通信加密)
  └─> 派生密钥 3 (本地存储)
```

**密钥轮换**:
- 每 90 天自动轮换
- 用户更换设备时强制轮换
- 检测到泄露时立即轮换

---

### 3. 访问控制

**生物认证**:
```dart
// 访问敏感凭证前验证生物特征
final authenticated = await BiometricAuth.authenticate(
  reason: '访问凭证需要验证身份',
);

if (authenticated) {
  final credential = await vault.read(key: 'sensitive');
}
```

**权限分级**:
| 凭证类型 | 访问要求 |
|---------|---------|
| 普通凭证 | 已登录即可 |
| 敏感凭证 | 需要生物认证 |
| 关键凭证 | 生物认证 + 二次确认 |

---

### 4. 审计日志

**记录内容**:
```dart
// 所有 API 调用都会记录
await auditLog.log(
  action: 'GET_CREDENTIAL',
  serviceUrl: serviceUrl,
  timestamp: DateTime.now(),
  success: true,
  deviceId: getDeviceId(),
);
```

**日志保护**:
- 日志加密存储
- 仅用户可访问
- 自动清理（90 天）

---

### 5. 安全最佳实践

✅ **推荐做法**:
- 始终使用最新版本的 Protobuf
- 定期轮换密钥
- 启用生物认证
- 监控异常访问

❌ **禁止做法**:
- 不要在代码中硬编码密钥
- 不要将凭证明文存储
- 不要在日志中记录敏感信息
- 不要禁用加密

---

## 📞 技术支持

**文档**: https://docs.polyvault.io  
**GitHub**: https://github.com/PolyVault/polyvault  
**邮件**: dev@polyvault.io  

---

**文档维护**: PolyVault 开发团队  
**版本**: v1.0  
**最后更新**: 2026-03-13  
**反馈邮箱**: docs@polyvault.io
