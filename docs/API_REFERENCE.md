# PolyVault API 参考文档

**版本**: v2.0  
**创建时间**: 2026-03-13  
**最后更新**: 2026-03-14  
**基于 Protobuf**: openclaw.proto v2.0

---

## 📖 目录

1. [概述](#概述)
2. [客户端权限配置 API](#客户端权限配置-api)
3. [K 宝验证流程](#k-宝验证流程)
4. [权限级别说明](#权限级别说明)
5. [Protobuf 消息说明](#protobuf-消息说明)
6. [服务接口说明](#服务接口说明)
7. [使用示例](#使用示例)
8. [错误码](#错误码)
9. [安全说明](#安全说明)

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
| **服务 - 客户端** | 请求 - 响应交互 | 凭证请求、权限配置 |

### 数据传输安全

- **传输层**: eCAL 内置加密（UDP/TCP TLS）
- **应用层**: Protobuf 消息使用客户端公钥加密
- **存储层**: zk_vault 硬件级加密（AES-256-GCM）

---

## 客户端权限配置 API

### 1. 权限配置架构

```
┌─────────────────────────────────────────┐
│          客户端权限管理系统              │
├─────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐      │
│  │  权限级别   │  │  Agent 白名单 │      │
│  │  配置       │  │  管理       │      │
│  └─────────────┘  └─────────────┘      │
│  ┌─────────────┐  ┌─────────────┐      │
│  │  K 宝验证    │  │  安全策略   │      │
│  │  流程       │  │  配置       │      │
│  └─────────────┘  └─────────────┘      │
└─────────────────────────────────────────┘
```

### 2. 权限配置 API

#### 2.1 设置权限级别

**接口**: `rpc SetPermissionLevel(PermissionLevelRequest) returns (PermissionLevelResponse)`

**用途**: 配置客户端的权限级别（普通/增强/最高）

**请求定义**:
```protobuf
message PermissionLevelRequest {
    string device_id = 1;              // 设备 ID
    PermissionLevel level = 2;         // 权限级别
    bytes biometric_verification = 3;  // 生物认证数据
    uint64 timestamp = 4;              // 时间戳
}

enum PermissionLevel {
    LEVEL_UNSPECIFIED = 0;
    LEVEL_NORMAL = 1;                  // 普通级别
    LEVEL_ENHANCED = 2;                // 增强级别
    LEVEL_MAXIMUM = 3;                 // 最高级别
}
```

**响应定义**:
```protobuf
message PermissionLevelResponse {
    string device_id = 1;              // 设备 ID
    PermissionLevel level = 2;         // 当前权限级别
    bool success = 3;                  // 操作是否成功
    string error_message = 4;          // 错误信息
    uint64 expiry_timestamp = 5;       // 权限过期时间
}
```

**调用流程**:

```
客户端                      OpenClaw Agent
   │                          │
   │──PermissionLevelRequest─►│
   │                          │ 1. 验证生物认证
   │                          │ 2. 检查设备合法性
   │                          │ 3. 更新权限配置
   │◄──PermissionLevelResponse─│
   │                          │
```

**请求示例** (Dart):

```dart
import 'package:polyvault/polyvault.dart';

Future<void> setPermissionLevel(PermissionLevel level) async {
  // 1. 生物认证
  final biometricData = await BiometricAuth.authenticate(
    reason: '设置权限级别需要验证身份',
  );

  // 2. 创建请求
  final request = PermissionLevelRequest()
    ..deviceId = await getDeviceId()
    ..level = level
    ..biometricVerification = biometricData
    ..timestamp = DateTime.now().millisecondsSinceEpoch;

  // 3. 发送请求
  final client = EcalClient('PermissionService');
  await client.init();

  final response = await client.call(
    method: 'SetPermissionLevel',
    request: request,
  );

  // 4. 处理响应
  final result = PermissionLevelResponse.fromBuffer(response);
  if (result.success) {
    print('✅ 权限级别已设置为：${result.level}');
    print('过期时间：${DateTime.fromMillisecondsSinceEpoch(result.expiryTimestamp)}');
  } else {
    print('❌ 设置失败：${result.errorMessage}');
  }
}
```

**响应示例** (成功):

```protobuf
PermissionLevelResponse {
  device_id: "device-12345",
  level: LEVEL_ENHANCED,
  success: true,
  error_message: "",
  expiry_timestamp: 1710422400000
}
```

---

#### 2.2 获取权限级别

**接口**: `rpc GetPermissionLevel(GetPermissionLevelRequest) returns (PermissionLevelResponse)`

**用途**: 查询当前设备的权限级别

**请求定义**:
```protobuf
message GetPermissionLevelRequest {
    string device_id = 1;    // 设备 ID
    uint64 timestamp = 2;    // 时间戳
}
```

**调用示例**:

```dart
Future<PermissionLevel> getPermissionLevel() async {
  final request = GetPermissionLevelRequest()
    ..deviceId = await getDeviceId()
    ..timestamp = DateTime.now().millisecondsSinceEpoch;

  final client = EcalClient('PermissionService');
  await client.init();

  final response = await client.call(
    method: 'GetPermissionLevel',
    request: request,
  );

  final result = PermissionLevelResponse.fromBuffer(response);
  return result.level;
}
```

---

### 3. Agent 白名单配置 API

#### 3.1 添加 Agent 到白名单

**接口**: `rpc AddAgentToWhitelist(AddAgentWhitelistRequest) returns (AddAgentWhitelistResponse)`

**用途**: 添加可信 Agent 到白名单

**请求定义**:
```protobuf
message AddAgentWhitelistRequest {
    string device_id = 1;              // 设备 ID
    string agent_id = 2;               // Agent ID
    bytes agent_certificate = 3;       // Agent 证书
    repeated string allowed_services = 4; // 允许的服务列表
    bytes biometric_verification = 5;  // 生物认证数据
    uint64 timestamp = 6;              // 时间戳
}

message AddAgentWhitelistResponse {
    string device_id = 1;              // 设备 ID
    string agent_id = 2;               // Agent ID
    bool success = 3;                  // 操作是否成功
    string error_message = 4;          // 错误信息
    uint64 expiry_timestamp = 5;       // 白名单过期时间
}
```

**allowed_services 说明**:

| 服务 | 说明 |
|------|------|
| `credential_provider` | 允许请求凭证 |
| `cookie_storage` | 允许存储 Cookie |
| `biometric_auth` | 允许触发生物认证 |
| `device_discovery` | 允许设备发现 |
| `remote_control` | 允许远程控制 |

**调用流程**:

```
客户端                      OpenClaw Agent
   │                          │
   │──AddAgentWhitelistRequest─►│
   │                          │ 1. 验证 Agent 证书
   │                          │ 2. 验证生物认证
   │                          │ 3. 添加到白名单
   │◄──AddAgentWhitelistResponse─│
   │                          │
```

**请求示例** (Dart):

```dart
Future<void> addAgentToWhitelist(String agentId, List<String> allowedServices) async {
  // 1. 获取 Agent 证书
  final agentCert = await fetchAgentCertificate(agentId);

  // 2. 生物认证
  final biometricData = await BiometricAuth.authenticate(
    reason: '添加 Agent 到白名单需要验证身份',
  );

  // 3. 创建请求
  final request = AddAgentWhitelistRequest()
    ..deviceId = await getDeviceId()
    ..agentId = agentId
    ..agentCertificate = agentCert
    ..allowedServices.addAll(allowedServices)
    ..biometricVerification = biometricData
    ..timestamp = DateTime.now().millisecondsSinceEpoch;

  // 4. 发送请求
  final client = EcalClient('PermissionService');
  await client.init();

  final response = await client.call(
    method: 'AddAgentToWhitelist',
    request: request,
  );

  // 5. 处理响应
  final result = AddAgentWhitelistResponse.fromBuffer(response);
  if (result.success) {
    print('✅ Agent $agentId 已添加到白名单');
  } else {
    print('❌ 添加失败：${result.errorMessage}');
  }
}
```

---

#### 3.2 从白名单移除 Agent

**接口**: `rpc RemoveAgentFromWhitelist(RemoveAgentWhitelistRequest) returns (RemoveAgentWhitelistResponse)`

**用途**: 从白名单移除 Agent

**请求定义**:
```protobuf
message RemoveAgentWhitelistRequest {
    string device_id = 1;              // 设备 ID
    string agent_id = 2;               // Agent ID
    bytes biometric_verification = 3;  // 生物认证数据
    uint64 timestamp = 4;              // 时间戳
}
```

---

#### 3.3 查询白名单列表

**接口**: `rpc GetWhitelist(GetWhitelistRequest) returns (GetWhitelistResponse)`

**用途**: 查询当前设备的 Agent 白名单

**响应定义**:
```protobuf
message GetWhitelistResponse {
    string device_id = 1;                      // 设备 ID
    repeated WhitelistEntry entries = 2;       // 白名单条目
    uint64 last_updated = 3;                   // 最后更新时间
}

message WhitelistEntry {
    string agent_id = 1;                       // Agent ID
    string agent_name = 2;                     // Agent 名称
    repeated string allowed_services = 3;      // 允许的服务
    uint64 added_timestamp = 4;                // 添加时间
    uint64 expiry_timestamp = 5;               // 过期时间
    bool is_active = 6;                        // 是否激活
}
```

---

## K 宝验证流程

### 1. K 宝验证架构

**K 宝** = 硬件级安全验证模块（类似银行 U 盾）

```
┌─────────────────────────────────────────┐
│          K 宝验证流程                    │
├─────────────────────────────────────────┤
│  1. 插入 K 宝（USB/NFC/蓝牙）            │
│  2. 读取 K 宝证书                        │
│  3. 验证 K 宝合法性                      │
│  4. 生成动态令牌                         │
│  5. 双重认证（K 宝 + 生物特征）          │
│  6. 授权通过                             │
└─────────────────────────────────────────┘
```

### 2. K 宝验证 API

#### 2.1 K 宝连接检测

**接口**: `rpc DetectK宝(K宝 DetectRequest) returns (K宝 DetectResponse)`

**用途**: 检测 K 宝是否已连接

**请求定义**:
```protobuf
message KBaoDetectRequest {
    string device_id = 1;        // 设备 ID
    uint64 timestamp = 2;        // 时间戳
}

message KBaoDetectResponse {
    bool is_connected = 1;       // 是否已连接
    string kbao_id = 2;          // K 宝 ID
    string kbao_type = 3;        // K 宝类型（USB/NFC/蓝牙）
    uint64 battery_level = 4;    // 电量（仅蓝牙）
    bool is_valid = 5;           // 是否合法
}
```

**调用示例** (Dart):

```dart
Future<bool> detectKBao() async {
  final request = KBaoDetectRequest()
    ..deviceId = await getDeviceId()
    ..timestamp = DateTime.now().millisecondsSinceEpoch;

  final client = EcalClient('KBaoService');
  await client.init();

  final response = await client.call(
    method: 'DetectKBao',
    request: request,
  );

  final result = KBaoDetectResponse.fromBuffer(response);
  
  if (result.isConnected) {
    print('✅ K 宝已连接：${result.kbaoId} (${result.kbaoType})');
    if (result.kbaoType == 'BLUETOOTH') {
      print('电量：${result.batteryLevel}%');
    }
  } else {
    print('❌ K 宝未连接');
  }
  
  return result.isConnected;
}
```

---

#### 2.2 K 宝验证流程

**完整流程**:

```
1. 检测 K 宝连接
   │
   ▼
2. 读取 K 宝证书
   │
   ▼
3. 验证证书合法性
   │
   ▼
4. 生成动态令牌
   │
   ▼
5. 用户输入令牌（可选）
   │
   ▼
6. 生物特征验证
   │
   ▼
7. 双重认证通过
   │
   ▼
8. 授权操作
```

**代码实现**:

```dart
import 'package:polyvault/kbao_service.dart';

class KBaoVerification {
  final KBaoService _kbaoService = KBaoService();

  /// 完整的 K 宝验证流程
  Future<bool> verifyKBao(String operationType) async {
    try {
      // 1. 检测 K 宝连接
      final isConnected = await _kbaoService.detect();
      if (!isConnected) {
        throw Exception('K 宝未连接，请插入 K 宝或开启蓝牙');
      }

      // 2. 读取 K 宝证书
      final certificate = await _kbaoService.readCertificate();

      // 3. 验证证书合法性
      final isValid = await _verifyCertificate(certificate);
      if (!isValid) {
        throw Exception('K 宝证书无效');
      }

      // 4. 生成动态令牌
      final token = await _kbaoService.generateToken(operationType);

      // 5. 显示令牌给用户（可选）
      if (token.requiresUserInput) {
        final userInput = await _showTokenInput(token.value);
        if (userInput != token.value) {
          throw Exception('令牌输入错误');
        }
      }

      // 6. 生物特征验证
      final biometricVerified = await _verifyBiometric();
      if (!biometricVerified) {
        throw Exception('生物特征验证失败');
      }

      // 7. 双重认证通过
      print('✅ K 宝验证通过，双重认证完成');
      return true;

    } catch (e) {
      print('❌ K 宝验证失败：$e');
      return false;
    }
  }

  Future<bool> _verifyCertificate(bytes certificate) async {
    // 验证证书链
    // 检查证书有效期
    // 验证签名
    return true;
  }

  Future<bool> _verifyBiometric() async {
    return await BiometricAuth.authenticate(
      reason: 'K 宝验证需要生物特征确认',
    );
  }

  Future<String> _showTokenInput(String token) async {
    // 显示令牌输入对话框
    // 返回用户输入
    return '';
  }
}
```

---

#### 2.3 K 宝授权操作

**接口**: `rpc KBaoAuthorize(KBaoAuthorizeRequest) returns (KBaoAuthorizeResponse)`

**用途**: 使用 K 宝授权敏感操作

**请求定义**:
```protobuf
message KBaoAuthorizeRequest {
    string device_id = 1;              // 设备 ID
    string kbao_id = 2;                // K 宝 ID
    string operation_type = 3;         // 操作类型
    bytes kbao_signature = 4;          // K 宝签名
    bytes biometric_verification = 5;  // 生物认证数据
    uint64 timestamp = 6;              // 时间戳
}

message KBaoAuthorizeResponse {
    string device_id = 1;              // 设备 ID
    string kbao_id = 2;                // K 宝 ID
    bool authorized = 3;               // 是否授权
    string authorization_token = 4;    // 授权令牌
    uint64 expiry_timestamp = 5;       // 令牌过期时间
    string error_message = 6;          // 错误信息
}
```

**operation_type 说明**:

| 操作类型 | 说明 | 安全级别 |
|---------|------|---------|
| `CREDENTIAL_ACCESS` | 访问凭证 | 高 |
| `WHITELIST_MODIFY` | 修改白名单 | 高 |
| `PERMISSION_CHANGE` | 修改权限 | 最高 |
| `DATA_EXPORT` | 导出数据 | 高 |
| `DEVICE_RESET` | 重置设备 | 最高 |

---

## 权限级别说明

### 1. 权限级别定义

PolyVault 支持三级权限体系：

```
┌─────────────────────────────────────────┐
│          权限级别金字塔                  │
├─────────────────────────────────────────┤
│              ┌─────┐                    │
│              │  L3 │  最高级别          │
│              └─────┘                    │
│           ┌─────────┐                   │
│           │   L2    │  增强级别         │
│           └─────────┘                   │
│        ┌─────────────┐                  │
│        │     L1      │  普通级别        │
│        └─────────────┘                  │
└─────────────────────────────────────────┘
```

### 2. 各级权限详细说明

#### L1 - 普通级别 (LEVEL_NORMAL)

**适用场景**: 日常使用，基本凭证访问

**权限范围**:
- ✅ 查看已保存的凭证列表
- ✅ 自动填充普通凭证
- ✅ 接收消息通知
- ✅ 设备发现

**安全要求**:
- 已登录即可
- 无需额外认证

**限制**:
- ❌ 无法访问敏感凭证
- ❌ 无法修改权限配置
- ❌ 无法管理白名单

**默认设置**: 新设备默认权限级别

---

#### L2 - 增强级别 (LEVEL_ENHANCED)

**适用场景**: 需要访问敏感凭证或中等风险操作

**权限范围**:
- ✅ 包含 L1 所有权限
- ✅ 访问敏感凭证（需要生物认证）
- ✅ 添加/移除普通白名单 Agent
- ✅ 接收远程控制请求
- ✅ 跨设备同步

**安全要求**:
- 生物认证（指纹/面容）
- 设备已信任

**限制**:
- ❌ 无法修改自身权限级别
- ❌ 无法管理最高权限白名单
- ❌ 无法导出全部数据

**升级方式**: 生物认证后可临时升级到 L2

---

#### L3 - 最高级别 (LEVEL_MAXIMUM)

**适用适用**: 高风险操作，完全控制

**权限范围**:
- ✅ 包含 L2 所有权限
- ✅ 访问所有凭证（包括关键凭证）
- ✅ 修改权限级别配置
- ✅ 管理完整白名单
- ✅ 导出/备份全部数据
- ✅ 设备重置
- ✅ K 宝验证操作

**安全要求**:
- **双重认证**: K 宝 + 生物特征
- 设备必须已信任
- 操作需要明确确认

**有效期**: 
- 默认 5 分钟
- 可配置（1-30 分钟）
- 超时自动降级到 L1

**升级方式**: K 宝验证 + 生物特征双重认证

---

### 3. 权限级别对比表

| 功能 | L1 普通 | L2 增强 | L3 最高 |
|------|:------:|:------:|:------:|
| 查看凭证列表 | ✅ | ✅ | ✅ |
| 自动填充普通凭证 | ✅ | ✅ | ✅ |
| 访问敏感凭证 | ❌ | ✅ (生物) | ✅ (双重) |
| 访问关键凭证 | ❌ | ❌ | ✅ |
| 添加白名单 Agent | ❌ | ✅ (普通) | ✅ (全部) |
| 修改权限配置 | ❌ | ❌ | ✅ |
| 导出数据 | ❌ | ❌ | ✅ |
| 远程控制 | ❌ | ✅ | ✅ |
| 跨设备同步 | ❌ | ✅ | ✅ |
| 设备重置 | ❌ | ❌ | ✅ |
| **认证要求** | 登录 | 生物 | K 宝 + 生物 |

---

### 4. 权限级别转换流程

```
┌─────────────┐
│   L1 普通   │
└──────┬──────┘
       │
       │ 生物认证
       ▼
┌─────────────┐
│   L2 增强   │
└──────┬──────┘
       │
       │ K 宝验证 + 生物特征
       ▼
┌─────────────┐
│   L3 最高   │
└──────┬──────┘
       │
       │ 超时（5 分钟）
       │ 或主动降级
       ▼
┌─────────────┐
│   L1 普通   │
└─────────────┘
```

---

### 5. 权限级别 API 使用示例

```dart
import 'package:polyvault/polyvault.dart';

class PermissionManager {
  final PolyVault _vault = PolyVault();

  /// 获取当前权限级别
  Future<PermissionLevel> getCurrentLevel() async {
    final request = GetPermissionLevelRequest()
      ..deviceId = await _vault.getDeviceId()
      ..timestamp = DateTime.now().millisecondsSinceEpoch;

    final response = await _vault.callPermissionService(
      method: 'GetPermissionLevel',
      request: request,
    );

    return PermissionLevelResponse.fromBuffer(response).level;
  }

  /// 升级到 L2（增强级别）
  Future<bool> upgradeToL2() async {
    // 1. 生物认证
    final biometricData = await BiometricAuth.authenticate(
      reason: '升级到增强级别需要验证身份',
    );

    // 2. 发送升级请求
    final request = PermissionLevelRequest()
      ..deviceId = await _vault.getDeviceId()
      ..level = PermissionLevel.LEVEL_ENHANCED
      ..biometricVerification = biometricData
      ..timestamp = DateTime.now().millisecondsSinceEpoch;

    final response = await _vault.callPermissionService(
      method: 'SetPermissionLevel',
      request: request,
    );

    final result = PermissionLevelResponse.fromBuffer(response);
    return result.success;
  }

  /// 升级到 L3（最高级别）
  Future<bool> upgradeToL3() async {
    // 1. K 宝验证
    final kbaoVerified = await _verifyKBao();
    if (!kbaoVerified) {
      return false;
    }

    // 2. 生物特征验证
    final biometricData = await BiometricAuth.authenticate(
      reason: '升级到最高级别需要双重认证',
    );

    // 3. 发送升级请求
    final request = PermissionLevelRequest()
      ..deviceId = await _vault.getDeviceId()
      ..level = PermissionLevel.LEVEL_MAXIMUM
      ..biometricVerification = biometricData
      ..timestamp = DateTime.now().millisecondsSinceEpoch;

    final response = await _vault.callPermissionService(
      method: 'SetPermissionLevel',
      request: request,
    );

    final result = PermissionLevelResponse.fromBuffer(response);
    
    if (result.success) {
      print('✅ 已升级到最高级别，有效期 5 分钟');
      print('过期时间：${DateTime.fromMillisecondsSinceEpoch(result.expiryTimestamp)}');
    }

    return result.success;
  }

  Future<bool> _verifyKBao() async {
    // K 宝验证逻辑
    return true;
  }
}
```

---

## Protobuf 消息说明

（保持原有内容，新增权限相关消息）

### 权限管理消息

#### PermissionLevelRequest

**用途**: 设置权限级别

**定义**:
```protobuf
message PermissionLevelRequest {
    string device_id = 1;
    PermissionLevel level = 2;
    bytes biometric_verification = 3;
    uint64 timestamp = 4;
}
```

#### PermissionLevelResponse

**用途**: 权限级别响应

**定义**:
```protobuf
message PermissionLevelResponse {
    string device_id = 1;
    PermissionLevel level = 2;
    bool success = 3;
    string error_message = 4;
    uint64 expiry_timestamp = 5;
}
```

#### AddAgentWhitelistRequest

**用途**: 添加 Agent 到白名单

**定义**:
```protobuf
message AddAgentWhitelistRequest {
    string device_id = 1;
    string agent_id = 2;
    bytes agent_certificate = 3;
    repeated string allowed_services = 4;
    bytes biometric_verification = 5;
    uint64 timestamp = 6;
}
```

---

## 服务接口说明

### PermissionService（权限服务）

**服务定义**:
```protobuf
service PermissionService {
    // 设置权限级别
    rpc SetPermissionLevel(PermissionLevelRequest) returns (PermissionLevelResponse);
    
    // 获取权限级别
    rpc GetPermissionLevel(GetPermissionLevelRequest) returns (PermissionLevelResponse);
    
    // 添加 Agent 到白名单
    rpc AddAgentToWhitelist(AddAgentWhitelistRequest) returns (AddAgentWhitelistResponse);
    
    // 从白名单移除 Agent
    rpc RemoveAgentFromWhitelist(RemoveAgentWhitelistRequest) returns (RemoveAgentWhitelistResponse);
    
    // 获取白名单列表
    rpc GetWhitelist(GetWhitelistRequest) returns (GetWhitelistResponse);
}
```

### KBaoService（K 宝服务）

**服务定义**:
```protobuf
service KBaoService {
    // 检测 K 宝连接
    rpc DetectKBao(KBaoDetectRequest) returns (KBaoDetectResponse);
    
    // K 宝验证
    rpc VerifyKBao(KBaoVerifyRequest) returns (KBaoVerifyResponse);
    
    // K 宝授权
    rpc KBaoAuthorize(KBaoAuthorizeRequest) returns (KBaoAuthorizeResponse);
}
```

---

## 错误码

### 权限错误 (PERM_XXX)

| 错误码 | 错误信息 | HTTP 状态 | 说明 |
|--------|---------|----------|------|
| `PERM_001` | 权限不足 | 403 | 当前权限级别不足以执行操作 |
| `PERM_002` | 权限已过期 | 401 | 权限级别已过期，需重新认证 |
| `PERM_003` | 认证失败 | 401 | 生物认证或 K 宝验证失败 |
| `PERM_004` | 白名单不存在 | 404 | Agent 不在白名单中 |
| `PERM_005` | 白名单已满 | 400 | 白名单条目已达上限 |

### K 宝错误 (KBAO_XXX)

| 错误码 | 错误信息 | HTTP 状态 | 说明 |
|--------|---------|----------|------|
| `KBAO_001` | K 宝未连接 | 400 | 未检测到 K 宝设备 |
| `KBAO_002` | K 宝证书无效 | 401 | K 宝证书验证失败 |
| `KBAO_003` | K 宝电量低 | 400 | 蓝牙 K 宝电量低于 10% |
| `KBAO_004` | K 宝签名失败 | 500 | K 宝签名生成失败 |
| `KBAO_005` | K 宝超时 | 408 | K 宝操作超时 |

---

## 安全说明

### 1. 权限安全

**权限隔离**:
- L1/L2/L3 三级权限严格隔离
- 低级别无法访问高级别资源
- 权限升级需要相应认证

**权限过期**:
- L2 权限：默认 30 分钟
- L3 权限：默认 5 分钟
- 过期自动降级到 L1

**权限审计**:
```dart
// 所有权限操作都会记录
await auditLog.log(
  action: 'PERMISSION_CHANGE',
  oldLevel: PermissionLevel.LEVEL_NORMAL,
  newLevel: PermissionLevel.LEVEL_ENHANCED,
  timestamp: DateTime.now(),
  deviceId: getDeviceId(),
);
```

---

### 2. K 宝安全

**双重认证**:
- K 宝（物理设备）+ 生物特征（用户身份）
- 两者缺一不可

**动态令牌**:
- 每次操作生成不同令牌
- 令牌一次性使用
- 防止重放攻击

**证书验证**:
- 验证 K 宝证书链
- 检查证书有效期
- 验证签名合法性

---

### 3. 白名单安全

**证书验证**:
- 所有 Agent 必须提供证书
- 验证证书签名
- 检查证书有效期

**服务隔离**:
- 白名单可指定允许的服务
- Agent 只能访问授权服务
- 防止越权访问

**定期审查**:
```dart
// 建议每月审查白名单
Future<void> reviewWhitelist() async {
  final whitelist = await getWhitelist();
  
  for (final entry in whitelist.entries) {
    if (entry.isExpired) {
      await removeAgentFromWhitelist(entry.agentId);
      print('已移除过期 Agent: ${entry.agentId}');
    }
  }
}
```

---

**文档维护**: PolyVault 开发团队  
**版本**: v2.0  
**最后更新**: 2026-03-14  
**反馈邮箱**: docs@polyvault.io
