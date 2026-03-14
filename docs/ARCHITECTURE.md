# PolyVault 系统架构文档

**版本**: v3.0  
**最后更新**: 2026-03-14  
**状态**: 开发中  
**基于技术**: eCAL + zk_vault + Protobuf + 多客户端架构

---

## 📖 目录

1. [架构概览](#架构概览)
2. [多客户端架构设计](#多客户端架构设计)
3. [权限配置架构](#权限配置架构)
4. [安全验证流程](#安全验证流程)
5. [核心组件](#核心组件)
6. [eCAL 通信模块](#ecal-通信模块)
7. [技术选型](#技术选型)

---

## 架构概览

### 完整架构图

```
┌─────────────────────────────────────────────────────────────────┐
│                      用户设备层                                  │
├───────────────────┬───────────────────┬─────────────────────────┤
│ 手机客户端        │ 电脑客户端        │ 浏览器扩展              │
│ Flutter + eCAL    │ Flutter + eCAL    │ Manifest V3             │
│ + zk_vault        │ + zk_vault        │ + Native Messaging      │
└─────────┬─────────┴─────────┬─────────┴──────────┬──────────────┘
          │                   │                    │
          └───────────────────┼────────────────────┘
                              │
┌─────────────────────────────▼─────────────────────────────┐
│                   通信层 - eCAL                            │
│  ┌─────────────────────────────────────────────────────┐  │
│  │ 自动传输选择：共享内存 | UDP | TCP                    │  │
│  │ 零配置设备发现 | Protobuf 序列化 | P2P 加密           │  │
│  └─────────────────────────────────────────────────────┘  │
└─────────────────────────────┬─────────────────────────────┘
                              │
┌─────────────────────────────▼─────────────────────────────┐
│                  OpenClaw 服务器                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐   │
│  │ OpenClaw 核心 │  │ PolyVault   │  │ 浏览器扩展      │   │
│  │             │  │ Agent       │  │ (Native Msg)   │   │
│  └─────────────┘  └─────────────┘  └─────────────────┘   │
└───────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────▼─────────────────────────────┐
│                   安全层 - zk_vault                        │
│  ┌─────────────┬─────────────┬─────────────┬───────────┐ │
│  │ Android     │ iOS         │ Windows     │ macOS     │ │
│  │ Keystore    │ Keychain    │ CNG/TPM     │ Keychain  │ │
│  │ StrongBox   │ SecureEnclave│            │           │ │
│  └─────────────┴─────────────┴─────────────┴───────────┘ │
└───────────────────────────────────────────────────────────┘
```

---

## 多客户端架构设计

### 1. 多客户端场景

PolyVault 支持**多种客户端形态**同时存在，协同工作：

```
┌─────────────────────────────────────────────────────────┐
│              多客户端协同场景                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  场景 1: 手机 + 电脑 + 平板                              │
│  ┌────────┐  ┌────────┐  ┌────────┐                    │
│  │  手机  │  │  电脑  │  │  平板  │                    │
│  │PolyVault│  │PolyVault│  │PolyVault│                   │
│  └───┬────┘  └───┬────┘  └───┬────┘                    │
│      │           │           │                          │
│      └───────────┼───────────┘                          │
│                  │                                      │
│          eCAL 软总线（自动同步）                         │
│                                                         │
│  场景 2: 手机 + 浏览器扩展                               │
│  ┌────────┐  ┌────────────┐                            │
│  │  手机  │  │  浏览器    │                            │
│  │PolyVault│  │  扩展      │                            │
│  └───┬────┘  └────┬───────┘                            │
│      │            │                                     │
│      │      Native Messaging                            │
│      │            │                                     │
│      └──────┬─────┘                                     │
│             │                                           │
│       Local Agent                                       │
│                                                         │
│  场景 3: 多用户共享设备                                  │
│  ┌─────────────────────────────────┐                    │
│  │         平板电脑                 │                    │
│  │  ┌────────┐  ┌────────┐        │                    │
│  │  │ 用户 A │  │ 用户 B │        │                    │
│  │  │PolyVault│  │PolyVault│       │                    │
│  │  └────────┘  └────────┘        │                    │
│  └─────────────────────────────────┘                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2. 多客户端架构

```
┌─────────────────────────────────────────────────────────┐
│                  多客户端架构                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────┐       │
│  │          客户端协调层                        │       │
│  │  ┌───────────┐  ┌───────────┐              │       │
│  │  │设备发现   │  │状态同步   │              │       │
│  │  │服务       │  │服务       │              │       │
│  │  └───────────┘  └───────────┘              │       │
│  └─────────────────────────────────────────────┘       │
│                     │                                   │
│  ┌─────────────────┼─────────────────┐                 │
│  │                 │                 │                 │
│  ▼                 ▼                 ▼                 │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐            │
│  │ 手机      │ │ 电脑      │ │ 平板      │            │
│  │ Client    │ │ Client    │ │ Client    │            │
│  └───────────┘ └───────────┘ └───────────┘            │
│                                                         │
│  特性：                                                 │
│  • 自动设备发现（eCAL 广播）                            │
│  • 状态实时同步（发布 - 订阅）                          │
│  • 主设备选举（基于能力和电量）                         │
│  • 凭证安全同步（端到端加密）                           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3. 客户端类型

#### 3.1 手机客户端

**平台**: Android, iOS, HarmonyOS

**特点**:
- ✅ 便携，随时可用
- ✅ 生物认证（指纹/面容）
- ✅ 硬件安全模块（TEE/Secure Enclave）
- ✅ 常在线，适合作为主设备

**职责**:
- 凭证存储和管理
- 授权请求响应
- 设备发现和同步
- 即时消息收发

---

#### 3.2 电脑客户端

**平台**: Windows, macOS, Linux

**特点**:
- ✅ 大屏，操作方便
- ✅ 性能强，适合复杂操作
- ✅ TPM 安全芯片（Windows）
- ✅ 常连接电源

**职责**:
- 凭证管理（批量操作）
- 配置管理
- 数据备份和恢复
- 跨设备同步协调

---

#### 3.3 平板客户端

**平台**: iPadOS, Android Tablet, HarmonyOS Tablet

**特点**:
- ✅ 中等屏幕
- ✅ 便携 + 性能平衡
- ✅ 适合作为家庭中枢

**职责**:
- 家庭设备协调
- 共享凭证管理
- 访客临时授权

---

#### 3.4 浏览器扩展

**平台**: Chrome, Firefox, Edge

**特点**:
- ✅ 无缝集成浏览器
- ✅ 自动检测登录表单
- ✅ 自动填充凭证

**职责**:
- 检测登录表单
- 请求本地 Agent 获取凭证
- 自动填充表单
- Cookie 管理

---

### 4. 多客户端同步机制

#### 4.1 设备发现

```dart
// 每个客户端启动时广播自己的存在
final publisher = EcalPublisher('device_discovery');

final discovery = DeviceDiscovery()
  ..deviceId = await getDeviceId()
  ..deviceName = await getDeviceName()
  ..deviceType = DeviceType.MOBILE
  ..capabilities.addAll(['credential_provider', 'biometric_auth'])
  ..timestamp = DateTime.now().millisecondsSinceEpoch;

await publisher.send(discovery.writeToBuffer());

// 订阅其他设备的发现广播
final subscriber = EcalSubscriber('device_discovery');
subscriber.onMessage = (data) {
  final discovery = DeviceDiscovery.fromBuffer(data);
  print('发现设备：${discovery.deviceName} (${discovery.deviceType})');
  _registerDevice(discovery);
};
```

---

#### 4.2 状态同步

```dart
// 发布状态更新
final statusPublisher = EcalPublisher('client_status');

final status = ClientStatus()
  ..deviceId = await getDeviceId()
  ..isOnline = true
  ..batteryLevel = 85
  ..permissionLevel = PermissionLevel.LEVEL_ENHANCED
  ..activeServices = ['credential_provider']
  ..timestamp = DateTime.now().millisecondsSinceEpoch;

await statusPublisher.send(status.writeToBuffer());

// 订阅状态更新
final statusSubscriber = EcalSubscriber('client_status');
statusSubscriber.onMessage = (data) {
  final status = ClientStatus.fromBuffer(data);
  _updateDeviceStatus(status);
};
```

---

#### 4.3 主设备选举

```dart
/// 基于能力和电量选举主设备
Future<void> electPrimaryDevice() async {
  final devices = await getDiscoveredDevices();
  
  // 评分标准
  int calculateScore(Device device) {
    int score = 0;
    
    // 能力评分
    if (device.hasBiometric) score += 30;
    if (device.hasSecureElement) score += 30;
    if (device.services.contains('credential_provider')) score += 20;
    
    // 电量评分
    score += (device.batteryLevel / 10).round();
    
    // 在线时长评分
    score += (device.uptimeMinutes / 10).round();
    
    return score;
  }
  
  // 选举最高分设备为主设备
  final primary = devices.reduce((a, b) {
    return calculateScore(a) > calculateScore(b) ? a : b;
  });
  
  print('主设备：${primary.deviceName} (得分：${calculateScore(primary)})');
  _setPrimaryDevice(primary);
}
```

---

#### 4.4 凭证同步

```dart
/// 安全同步凭证到所有设备
Future<void> syncCredentialsToDevice() async {
  final devices = await getTrustedDevices();
  
  for (final device in devices) {
    if (device.deviceId == await getDeviceId()) continue;
    
    // 加密凭证
    final encryptedCredential = await encryptWithDeviceKey(
      credential,
      device.publicKey,
    );
    
    // 发送同步请求
    final syncRequest = CredentialSyncRequest()
      ..sourceDeviceId = await getDeviceId()
      ..targetDeviceId = device.deviceId
      ..encryptedCredential = encryptedCredential
      ..timestamp = DateTime.now().millisecondsSinceEpoch;
    
    final client = EcalClient('SyncService');
    await client.init();
    
    final response = await client.call(
      method: 'SyncCredential',
      request: syncRequest,
    );
    
    print('已同步凭证到 ${device.deviceName}');
  }
}
```

---

## 权限配置架构

### 1. 权限配置架构图

```
┌─────────────────────────────────────────────────────────┐
│                  权限配置架构                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────┐       │
│  │          权限配置管理中心                    │       │
│  │  ┌───────────┐  ┌───────────┐              │       │
│  │  │权限级别   │  │Agent 白名单│              │       │
│  │  │配置       │  │管理       │              │       │
│  │  └───────────┘  └───────────┘              │       │
│  │  ┌───────────┐  ┌───────────┐              │       │
│  │  │K 宝验证    │  │安全策略   │              │       │
│  │  │流程       │  │配置       │              │       │
│  │  └───────────┘  └───────────┘              │       │
│  └─────────────────────────────────────────────┘       │
│                     │                                   │
│  ┌─────────────────┼─────────────────┐                 │
│  │                 │                 │                 │
│  ▼                 ▼                 ▼                 │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐            │
│  │ L1 普通   │ │ L2 增强   │ │ L3 最高   │            │
│  │ 权限      │ │ 权限      │ │ 权限      │            │
│  └───────────┘ └───────────┘ └───────────┘            │
│                                                         │
│  特性：                                                 │
│  • 三级权限体系（L1/L2/L3）                             │
│  • 渐进式认证（登录 → 生物 → K 宝 + 生物）               │
│  • Agent 白名单管理（证书验证）                         │
│  • 权限过期自动降级                                     │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2. 三级权限体系

```
┌─────────────────────────────────────────┐
│          权限级别金字塔                  │
│              ┌─────┐                    │
│              │ L3  │ 最高级别           │
│              │     │ K 宝 + 生物         │
│              └─────┘                    │
│           ┌─────────┐                   │
│           │  L2     │ 增强级别          │
│           │         │ 生物认证          │
│           └─────────┘                   │
│        ┌─────────────┐                  │
│        │    L1       │ 普通级别         │
│        │             │ 已登录           │
│        └─────────────┘                  │
└─────────────────────────────────────────┘
```

**详细说明**:

| 级别 | 名称 | 认证要求 | 有效期 | 权限范围 |
|------|------|---------|--------|---------|
| **L1** | 普通级别 | 已登录 | 永久 | 基本凭证访问 |
| **L2** | 增强级别 | 生物认证 | 30 分钟 | 敏感凭证访问 |
| **L3** | 最高级别 | K 宝 + 生物 | 5 分钟 | 完全控制 |

---

### 3. Agent 白名单架构

```
┌─────────────────────────────────────────────────────────┐
│                  Agent 白名单架构                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────┐       │
│  │          白名单管理                          │       │
│  │  ┌───────────────────────────────────┐     │       │
│  │  │ 可信 Agent 列表                    │     │       │
│  │  │ ┌───────────┐ ┌───────────┐      │     │       │
│  │  │ │ Agent A   │ │ Agent B   │ ...  │     │       │
│  │  │ │ 证书验证  │ │ 证书验证  │      │     │       │
│  │  │ │ 服务授权  │ │ 服务授权  │      │     │       │
│  │  │ └───────────┘ └───────────┘      │     │       │
│  │  └───────────────────────────────────┘     │       │
│  └─────────────────────────────────────────────┘       │
│                                                         │
│  添加流程：                                             │
│  1. 获取 Agent 证书                                     │
│  2. 验证证书合法性                                      │
│  3. 配置允许的服务                                      │
│  4. 生物认证确认                                        │
│  5. 添加到白名单                                        │
│                                                         │
│  验证流程：                                             │
│  1. Agent 发起请求                                      │
│  2. 检查是否在白名单                                    │
│  3. 验证请求的服务是否授权                              │
│  4. 执行请求或拒绝                                      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

### 4. 权限配置 API

#### 4.1 设置权限级别

```protobuf
service PermissionService {
    rpc SetPermissionLevel(PermissionLevelRequest) 
        returns (PermissionLevelResponse);
}

message PermissionLevelRequest {
    string device_id = 1;
    PermissionLevel level = 2;
    bytes biometric_verification = 3;
    uint64 timestamp = 4;
}

enum PermissionLevel {
    LEVEL_UNSPECIFIED = 0;
    LEVEL_NORMAL = 1;      // L1
    LEVEL_ENHANCED = 2;    // L2
    LEVEL_MAXIMUM = 3;     // L3
}
```

#### 4.2 管理 Agent 白名单

```protobuf
service PermissionService {
    rpc AddAgentToWhitelist(AddAgentWhitelistRequest) 
        returns (AddAgentWhitelistResponse);
    
    rpc RemoveAgentFromWhitelist(RemoveAgentWhitelistRequest) 
        returns (RemoveAgentWhitelistResponse);
    
    rpc GetWhitelist(GetWhitelistRequest) 
        returns (GetWhitelistResponse);
}

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

## 安全验证流程

### 1. 完整安全验证流程图

```
┌─────────────────────────────────────────────────────────┐
│              安全验证流程                                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  操作请求                                                │
│      │                                                  │
│      ▼                                                  │
│  ┌─────────────────┐                                    │
│  │ 检查权限级别    │                                    │
│  └────────┬────────┘                                    │
│           │                                             │
│     ┌─────┴─────┐                                       │
│     │           │                                       │
│     ▼           ▼                                       │
│  L1 权限     L2/L3 权限                                 │
│     │           │                                       │
│     │           ▼                                       │
│     │     ┌─────────────┐                              │
│     │     │ 生物认证    │                              │
│     │     └──────┬──────┘                              │
│     │            │                                     │
│     │      ┌─────┴─────┐                              │
│     │      │           │                              │
│     │      ▼           ▼                              │
│     │   L2 通过    L3 需要 K 宝                        │
│     │                 │                                │
│     │                 ▼                                │
│     │         ┌─────────────┐                         │
│     │         │ K 宝验证     │                         │
│     │         └──────┬──────┘                         │
│     │                │                                 │
│     │                ▼                                 │
│     │         ┌─────────────┐                         │
│     │         │ 双重认证通过 │                         │
│     │         └──────┬──────┘                         │
│     │                │                                 │
│     └────────────────┼────────────────┐               │
│                      │                │               │
│                      ▼                ▼               │
│               ┌────────────┐  ┌────────────┐         │
│               │ 验证成功   │  │ 验证失败   │         │
│               │ 执行操作   │  │ 拒绝操作   │         │
│               └────────────┘  └────────────┘         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2. K 宝验证详细流程

```
┌─────────────────────────────────────────────────────────┐
│              K 宝验证流程                                │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. 检测 K 宝连接                                        │
│     ┌─────────────────────┐                            │
│     │ KBaoDetectRequest   │                            │
│     └──────────┬──────────┘                            │
│                │                                       │
│                ▼                                       │
│     ┌─────────────────────┐                            │
│     │ 检查 USB/NFC/蓝牙   │                            │
│     └──────────┬──────────┘                            │
│                │                                       │
│                ▼                                       │
│     ┌─────────────────────┐                            │
│     │ KBaoDetectResponse  │                            │
│     │ - is_connected      │                            │
│     │ - kbao_id           │                            │
│     │ - kbao_type         │                            │
│     │ - battery_level     │                            │
│     └─────────────────────┘                            │
│                                                         │
│  2. 读取 K 宝证书                                         │
│     ┌─────────────────────┐                            │
│     │ 读取证书链          │                            │
│     │ 验证签名            │                            │
│     │ 检查有效期          │                            │
│     └──────────┬──────────┘                            │
│                │                                       │
│                ▼                                       │
│     ┌─────────────────────┐                            │
│     │ 证书验证结果        │                            │
│     └─────────────────────┘                            │
│                                                         │
│  3. 生成动态令牌                                         │
│     ┌─────────────────────┐                            │
│     │ 基于时间 + 操作类型  │                            │
│     │ 生成一次性令牌      │                            │
│     └──────────┬──────────┘                            │
│                │                                       │
│                ▼                                       │
│     ┌─────────────────────┐                            │
│     │ 显示令牌给用户      │                            │
│     │ （可选输入确认）    │                            │
│     └─────────────────────┘                            │
│                                                         │
│  4. 生物特征验证                                         │
│     ┌─────────────────────┐                            │
│     │ 指纹/面容识别       │                            │
│     └──────────┬──────────┘                            │
│                │                                       │
│                ▼                                       │
│     ┌─────────────────────┐                            │
│     │ 生物认证结果        │                            │
│     └─────────────────────┘                            │
│                                                         │
│  5. 双重认证通过                                         │
│     ┌─────────────────────┐                            │
│     │ K 宝签名 + 生物特征   │                            │
│     │ 生成授权令牌        │                            │
│     └──────────┬──────────┘                            │
│                │                                       │
│                ▼                                       │
│     ┌─────────────────────┐                            │
│     │ KBaoAuthorizeResponse│                           │
│     │ - authorized: true  │                            │
│     │ - authorization_token│                           │
│     │ - expiry_timestamp  │                            │
│     └─────────────────────┘                            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 核心组件

（保持原有核心组件内容，此处省略）

---

## eCAL 通信模块

（保持原有 eCAL 内容，此处省略）

---

## 技术选型

### 核心技术栈

| 组件 | 技术 | 版本 | 说明 |
|------|------|------|------|
| **通信层** | eCAL | 5.x | 高性能分布式通信 |
| **安全层** | zk_vault | 1.x | Flutter 硬件安全存储 |
| **协议定义** | Protobuf | 3.x | 接口定义语言 |
| **客户端 UI** | Flutter | 3.x | 跨平台 UI 框架 |
| **Agent** | C++ | C++17 | 高性能后端服务 |
| **权限管理** | 自研 | 1.0 | 三级权限体系 |
| **K 宝集成** | 自研 | 1.0 | 硬件安全验证 |

### 平台支持

| 平台 | 最低版本 | 安全模块 | 状态 |
|------|---------|---------|------|
| **Android** | API 21 | Keystore + StrongBox | ✅ 稳定 |
| **iOS** | iOS 11 | Secure Enclave | ✅ 稳定 |
| **Windows** | 10 | CNG + TPM | ✅ 稳定 |
| **macOS** | 10.14 | Keychain | ✅ 稳定 |
| **Linux** | Ubuntu 20.04 | libsecret | ✅ 稳定 |
| **鸿蒙** | HarmonyOS 3.0 | HUKS | ⏳ 规划中 |

---

**文档维护**: PolyVault 开发组  
**版本**: v3.0  
**最后更新**: 2026-03-14  
**反馈邮箱**: dev@polyvault.io
