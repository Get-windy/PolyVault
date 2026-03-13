# PolyVault Flutter 前端开发理解文档

**作者**: team-member  
**创建时间**: 2026-03-13  
**版本**: v1.0

---

## 1. 项目概述

### 1.1 什么是 PolyVault

PolyVault 是一个**远程授信客户端**，核心目标是让 OpenClaw 服务器在需要登录第三方服务时，能够实时向用户的客户端请求凭证，而**服务器端不存储任何明文敏感信息**。

### 1.2 核心技术栈

| 层级 | 技术 | 作用 |
|------|------|------|
| **通信层** | eCAL (enhanced Communication Abstraction Layer) | P2P 加密通信，自动选择最优传输路径 |
| **安全层** | zk_vault | 硬件级安全存储（AES-256-GCM） |
| **序列化** | Protobuf | 接口定义语言，跨语言通信 |
| **UI框架** | Flutter | 跨平台客户端（Android/iOS/Windows/macOS/Linux） |

### 1.3 核心架构

```
┌─────────────────────────────────────────────────────────────┐
│                      用户设备层 (Flutter App)                │
├─────────────────────────────────────────────────────────────┤
│  UI层: Flutter Widgets (Material 3)                          │
│  状态管理: Riverpod                                          │
│  路由: go_router                                             │
├─────────────────────────────────────────────────────────────┤
│  业务层: Services                                            │
│  - SecureStorageService (zk_vault封装)                       │
│  - EcalCommunicationService (eCAL通信)                       │
│  - CredentialManager (凭证管理)                              │
├─────────────────────────────────────────────────────────────┤
│  数据层: Models + Protobuf                                   │
│  - Credential (凭证模型)                                     │
│  - Protobuf 生成的 Dart 代码                                 │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ eCAL P2P 加密通道
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  OpenClaw 服务器                             │
│  - 浏览器扩展 (Manifest V3)                                  │
│  - 本地 Agent (C++/Rust)                                     │
│  - OpenClaw 核心                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 核心概念理解

### 2.1 远程授信流程

```
1. 浏览器扩展检测到需要登录 (如 Google)
2. 通过 Native Messaging 向本地 Agent 请求凭证
3. 本地 Agent 通过 eCAL 向 Flutter 客户端发送 CredentialRequest
4. 客户端弹出授权提示（生物识别验证）
5. 用户批准后，zk_vault 解密凭证（在 Secure Enclave/Keystore 内）
6. 客户端通过 eCAL 返回加密凭证
7. 本地 Agent 解密凭证（内存中）
8. 浏览器扩展自动填写表单
9. 登录成功后，Cookie 加密存储到客户端
10. 本地 Agent 立即清除内存中的明文凭证
```

### 2.2 安全模型

#### 2.2.1 三层加密

| 层级 | 加密方式 | 密钥位置 | 说明 |
|------|---------|---------|------|
| **传输层** | eCAL TLS 1.3 | 自动协商 | P2P 加密通信 |
| **应用层** | RSA-2048 / ECDSA P-256 | 服务端公钥 | 客户端用服务端公钥加密，服务端私钥解密 |
| **存储层** | AES-256-GCM | 硬件安全模块 | zk_vault 使用 Keystore/Secure Enclave |

#### 2.2.2 密钥层次

```
根密钥 (硬件保护，永不离开安全区域)
  ├─> 派生密钥 1: 凭证加密
  ├─> 派生密钥 2: 通信加密
  └─> 派生密钥 3: 本地存储
```

### 2.3 通信模式

#### 2.3.1 发布-订阅模式 (Pub-Sub)

用于广播消息、事件通知：
- 设备发现
- 状态更新
- 能力声明

```dart
// 发布设备能力
final publisher = EcalPublisher('device_capability');
await publisher.send(capability.writeToBuffer());

// 订阅其他设备
final subscriber = EcalSubscriber('device_capability');
subscriber.onMessage = (data) {
  final cap = Capability.fromBuffer(data);
  print('发现设备: ${cap.deviceId}');
};
```

#### 2.3.2 服务-客户端模式 (Service-Client)

用于请求-响应交互：
- 凭证请求/响应
- Cookie 上传

```dart
// 服务端定义
service CredentialService {
  rpc GetCredential(CredentialRequest) returns (CredentialResponse);
  rpc UploadCookie(CookieUpload) returns (CredentialResponse);
}
```

---

## 3. API 接口理解

### 3.1 核心消息类型

#### 3.1.1 CredentialRequest (凭证请求)

```protobuf
message CredentialRequest {
    string service_url = 1;      // 目标服务 URL
    string session_id = 2;       // 会话标识符 (UUID)
    uint64 timestamp = 3;        // Unix 时间戳（毫秒）
}
```

**前端处理流程**:
1. 监听 `CredentialRequest` 消息
2. 验证 `session_id` 和 `timestamp`（防重放攻击）
3. 从 zk_vault 读取对应 `service_url` 的凭证
4. 用户授权（生物识别）
5. 使用服务端公钥加密凭证
6. 返回 `CredentialResponse`

#### 3.1.2 CredentialResponse (凭证响应)

```protobuf
message CredentialResponse {
    string session_id = 1;           // 对应请求的会话 ID
    bytes encrypted_credential = 2;  // 加密的凭证数据
    bool success = 3;                // 操作是否成功
    string error_message = 4;        // 错误信息
}
```

**encrypted_credential 解密后的 JSON 结构**:
```json
{
  "service_url": "https://accounts.google.com",
  "username": "user@example.com",
  "password": "[加密后的密码]",
  "cookies": [
    {
      "name": "SESSIONID",
      "value": "encrypted_value",
      "domain": ".google.com",
      "expiry": 1710422400000
    }
  ],
  "timestamp": 1710336000000
}
```

#### 3.1.3 CookieUpload (Cookie 上传)

```protobuf
message CookieUpload {
    string service_url = 1;          // 服务 URL
    bytes encrypted_cookie = 2;      // 加密的 Cookie 数据
    string session_id = 3;           // 会话标识符
}
```

**使用场景**: 登录成功后，客户端主动上传 Cookie 供后续使用。

#### 3.1.4 Capability (设备能力)

```protobuf
message Capability {
    string device_id = 1;                    // 设备唯一标识
    repeated string services = 2;            // 支持的服务列表
    map<string, string> metadata = 3;        // 元数据
}
```

**预定义服务类型**:
- `credential_provider`: 提供凭证存储
- `sensor_data`: 提供传感器数据
- `biometric_auth`: 生物认证
- `secure_storage`: 安全存储

### 3.2 错误码体系

| 类别 | 错误码 | 说明 | 前端处理 |
|------|--------|------|---------|
| **认证错误** | AUTH_001 | 用户未认证 | 跳转登录页 |
| | AUTH_002 | 会话过期 | 重新认证 |
| | AUTH_003 | 权限不足 | 提示权限不足 |
| **保险库错误** | VAULT_001 | 凭证不存在 | 提示用户添加凭证 |
| | VAULT_002 | 生物认证失败 | 重试或输入密码 |
| | VAULT_003 | 保险库锁定 | 提示解锁 |
| **加密错误** | ENCRYPT_001 | 加密失败 | 重试或报错 |
| **通信错误** | COMM_001 | 连接超时 | 检查网络 |
| | COMM_002 | 设备不可达 | 提示设备离线 |

---

## 4. 开发环境理解

### 4.1 必需依赖

```yaml
# pubspec.yaml
dependencies:
  # 核心安全存储
  zk_vault: ^0.1.3
  
  # 状态管理
  flutter_riverpod: ^2.4.0
  
  # 路由
  go_router: ^12.0.0
  
  # Protobuf
  protobuf: ^3.1.0
  
  # eCAL Dart 绑定 (待实现 FFI)
  # ecal_dart: ^1.0.0
```

### 4.2 平台配置要点

#### Android

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
<uses-feature android:name="android.hardware.strongbox_keystore" android:required="false" />
```

**minSdkVersion**: 23+ (Android 6.0)

#### iOS

```plist
<!-- Info.plist -->
<key>NSFaceIDUsageDescription</key>
<string>需要使用面容ID来保护您的凭证安全</string>
```

**注意**: Secure Enclave 仅在真机上可用，模拟器不支持。

### 4.3 Protobuf 编译流程

```bash
# 1. 安装 protoc
# Windows: choco install protobuf
# macOS: brew install protobuf

# 2. 安装 Dart 插件
dart pub global activate protoc_plugin

# 3. 编译 proto 文件
protoc --dart_out=lib/generated -Iprotos protos/*.proto

# 4. 或使用 build_runner
dart run build_runner build
```

---

## 5. 前端实现规划

### 5.1 目录结构建议

```
lib/
├── main.dart                      # 应用入口
├── app.dart                       # MaterialApp 配置
├── router.dart                    # go_router 路由配置
├── providers/                     # Riverpod Providers
│   ├── auth_provider.dart         # 认证状态
│   ├── credentials_provider.dart  # 凭证列表状态
│   └── connection_provider.dart   # eCAL 连接状态
├── services/                      # 业务服务
│   ├── secure_storage_service.dart    # zk_vault 封装
│   ├── ecal_service.dart              # eCAL 通信
│   ├── credential_manager.dart        # 凭证管理
│   └── encryption_service.dart        # 加密服务
├── models/                        # 数据模型
│   ├── credential.dart            # 凭证模型
│   └── device.dart                # 设备模型
├── screens/                       # 页面
│   ├── home_screen.dart           # 主页（设备状态）
│   ├── credentials_screen.dart    # 凭证管理
│   ├── credential_detail_screen.dart  # 凭证详情
│   ├── add_credential_screen.dart     # 添加凭证
│   ├── settings_screen.dart       # 设置
│   └── auth_screen.dart           # 认证/登录
├── widgets/                       # 可复用组件
│   ├── credential_card.dart       # 凭证卡片
│   ├── device_status_card.dart    # 设备状态卡片
│   ├── security_status_card.dart  # 安全状态卡片
│   ├── biometric_prompt.dart      # 生物识别提示
│   └── connection_status.dart     # 连接状态指示器
└── generated/                     # Protobuf 生成代码
    └── openclaw.pb.dart
```

### 5.2 关键服务设计

#### 5.2.1 SecureStorageService

已实现的 `SecureStorageService` 已覆盖基本功能：
- `saveCredential()`: 保存凭证到 zk_vault
- `getCredential()`: 读取凭证（支持生物识别）
- `deleteCredential()`: 删除凭证
- `getCredentialList()`: 获取凭证列表（不含敏感信息）

**需要扩展的功能**:
```dart
// 扩展 SecureStorageService
class SecureStorageService {
  // ... 现有方法
  
  /// 导出加密凭证（用于跨设备同步）
  Future<String> exportCredential(String credentialId);
  
  /// 导入加密凭证
  Future<void> importCredential(String encryptedData);
  
  /// 批量删除
  Future<void> deleteCredentials(List<String> ids);
  
  /// 搜索凭证
  Future<List<CredentialSummary>> searchCredentials(String query);
}
```

#### 5.2.2 EcalService (待实现)

```dart
/// eCAL 通信服务
class EcalService {
  final _credentialRequestController = StreamController<CredentialRequest>();
  
  /// 凭证请求流
  Stream<CredentialRequest> get credentialRequests => 
      _credentialRequestController.stream;
  
  /// 初始化 eCAL
  Future<void> initialize();
  
  /// 发布设备能力
  Future<void> publishCapability(Capability capability);
  
  /// 响应凭证请求
  Future<void> respondToCredentialRequest(
    String sessionId,
    Credential credential,
  );
  
  /// 上传 Cookie
  Future<void> uploadCookie(String serviceUrl, List<Cookie> cookies);
  
  /// 关闭连接
  Future<void> dispose();
}
```

### 5.3 UI 设计要点

#### 5.3.1 主页 (HomeScreen)

**功能模块**:
1. **设备状态卡片**: 显示连接状态、设备名称、平台
2. **安全状态卡片**: 生物识别可用性、硬件安全、加密级别
3. **统计卡片**: 已存凭证数、上次备份时间
4. **快速操作**: 添加凭证、同步设备

#### 5.3.2 凭证管理页 (CredentialsScreen)

**功能模块**:
1. **凭证列表**: 服务名称、用户名、创建时间
2. **搜索栏**: 按服务名称搜索
3. **添加按钮**: 打开添加凭证对话框
4. **凭证详情**: 点击展开，显示完整信息（需生物识别）
5. **删除功能**: 滑动删除或菜单删除

#### 5.3.3 授权提示 (重要)

当收到 `CredentialRequest` 时，需要显示授权对话框：

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('OpenClaw 请求凭证'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('服务: $serviceName'),
        Text('URL: $serviceUrl'),
        SizedBox(height: 16),
        Text('请验证身份以提供凭证'),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => denyRequest(),
        child: Text('拒绝'),
      ),
      FilledButton(
        onPressed: () => approveWithBiometric(),
        child: Text('授权（指纹验证）'),
      ),
    ],
  ),
);
```

---

## 6. 开发优先级建议

### 6.1 阶段一：基础功能 (已完成 ✅)

- ✅ Flutter 项目结构
- ✅ zk_vault 集成
- ✅ 基础 UI（主页、凭证管理）
- ✅ Android/iOS 权限配置

### 6.2 阶段二：核心通信 (进行中 🔄)

- 🔄 eCAL FFI 绑定（Dart 调用 C++）
- 🔄 Protobuf 生成代码集成
- 🔄 凭证请求/响应流程
- 🔄 设备能力发现

### 6.3 阶段三：高级功能 (待开始 ⏳)

- ⏳ 跨设备凭证同步
- ⏳ 备份恢复功能
- ⏳ 审计日志
- ⏳ 多语言支持

---

## 7. 技术难点与解决方案

### 7.1 eCAL FFI 绑定

**难点**: Flutter Dart 需要调用 eCAL C++ API

**解决方案**:
1. 使用 `dart:ffi` 创建 Dart 到 C 的绑定
2. 编写 C 包装层，暴露简化接口
3. 使用 `ffigen` 自动生成绑定代码

```dart
// FFI 示例
import 'dart:ffi';
import 'dart:io';

final DynamicLibrary ecalLib = Platform.isAndroid
    ? DynamicLibrary.open('libecal.so')
    : DynamicLibrary.open('ecal.dll');

final initializeEcal = ecalLib.lookupFunction<
    Void Function(),
    void Function()
>('ecal_initialize');
```

### 7.2 生物识别与后台处理

**难点**: 收到凭证请求时，App 可能在后台

**解决方案**:
1. 使用 `flutter_local_notifications` 显示通知
2. 用户点击通知后打开 App 进行授权
3. 或使用 Android/iOS 的 CallKit/ConnectionService（类似来电界面）

### 7.3 跨平台密钥管理

**难点**: 不同平台的 Keystore/Keychain API 不同

**解决方案**:
- zk_vault 已封装平台差异
- 统一使用 `ZkVault` API
- 平台特定代码在 zk_vault 内部处理

---

## 8. 与后端/Agent 协作

### 8.1 与 C++ Agent 的协作

- **Agent 职责**: eCAL 通信、Native Messaging、浏览器扩展通信
- **Flutter 职责**: UI、凭证存储、用户授权
- **通信方式**: eCAL P2P（同一设备使用共享内存）

### 8.2 Protobuf 版本管理

- 所有团队使用同一 `.proto` 文件
- 提交时同步更新 `protos/` 目录
- CI/CD 自动生成各语言代码

---

## 9. 参考资料

### 9.1 官方文档

- **eCAL**: https://eclipse-ecal.github.io/ecal/
- **Flutter**: https://docs.flutter.dev/
- **zk_vault**: https://pub.dev/packages/zk_vault
- **Protobuf**: https://protobuf.dev/

### 9.2 项目文档

- `docs/ARCHITECTURE.md` - 架构设计
- `docs/API_REFERENCE.md` - API 参考
- `docs/DEVELOPMENT_SETUP.md` - 环境搭建

---

## 10. 总结

### 10.1 核心理解

1. **安全第一**: 所有敏感操作都在硬件安全模块内完成
2. **用户授权**: 任何凭证提供都需要用户明确授权
3. **去中心化**: 客户端与 OpenClaw 直接通信，无中心服务器
4. **跨平台**: Flutter + eCAL 实现真正的跨平台支持

### 10.2 下一步行动

1. 等待 eCAL FFI 绑定完成
2. 集成 Protobuf 生成代码
3. 实现完整的凭证请求/响应流程
4. 添加设备能力发现功能

---

**文档维护**: team-member  
**最后更新**: 2026-03-13  
**状态**: 初稿完成，待团队评审