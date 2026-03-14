# PolyVault 开发指南

**版本**: v1.0  
**创建时间**: 2026-03-14  
**适用对象**: 新加入 PolyVault 项目的开发者

---

## 📖 目录

1. [快速开始](#快速开始)
2. [开发环境搭建](#开发环境搭建)
3. [项目结构](#项目结构)
4. [核心概念](#核心概念)
5. [开发流程](#开发流程)
6. [调试技巧](#调试技巧)
7. [常见问题](#常见问题)
8. [参考资源](#参考资源)

---

## 快速开始

### 5 分钟上手

```bash
# 1. 克隆项目
git clone https://github.com/PolyVault/polyvault.git
cd polyvault

# 2. 安装依赖
flutter pub get

# 3. 配置 eCAL
# Windows: 运行 eCAL installer
# Linux: sudo apt install libecal

# 4. 运行示例
flutter run
```

### 前置要求

| 工具 | 版本 | 说明 |
|------|------|------|
| Flutter | 3.x | 跨平台 UI 框架 |
| Dart | 3.x | 编程语言 |
| eCAL | 5.x | 通信中间件 |
| Protobuf | 3.x | 接口定义 |
| zk_vault | 1.x | 安全存储 |

---

## 开发环境搭建

### 1. Flutter 环境

**Windows**:
```powershell
# 下载 Flutter SDK
flutter doctor -v

# 安装 Android Studio
# 安装 VS Code + Flutter 插件
```

**macOS**:
```bash
brew install --cask flutter
flutter doctor -v
```

**Linux**:
```bash
sudo snap install flutter --classic
flutter doctor -v
```

### 2. eCAL 安装

**Windows**:
1. 下载 eCAL installer: https://github.com/eclipse-ecal/ecal/releases
2. 运行 installer，选择默认选项
3. 验证安装：`ecalversion`

**Linux (Ubuntu)**:
```bash
sudo add-apt-repository ppa:ecal/ecal-5
sudo apt update
sudo apt install libecal libecal-dev
```

**macOS**:
```bash
brew install ecal
```

### 3. Protobuf 配置

```yaml
# pubspec.yaml
dependencies:
  protobuf: ^3.1.0
  fixnum: ^1.1.0

dev_dependencies:
  build_runner: ^2.4.0
  protoc_builder: ^0.5.0
```

**生成 Dart 代码**:
```bash
# 编译 .proto 文件
protoc --dart_out=lib/generated \
  -Iproto \
  proto/openclaw.proto
```

### 4. zk_vault 配置

```yaml
# pubspec.yaml
dependencies:
  zk_vault: ^1.0.0
  flutter_secure_storage: ^9.0.0
```

**平台特定配置**:

**Android** (`android/app/build.gradle`):
```gradle
android {
    defaultConfig {
        minSdkVersion 23  // 必需
    }
}
```

**iOS** (`ios/Podfile`):
```ruby
platform :ios, '12.0'  // 必需
```

---

## 项目结构

```
polyvault/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # App 配置
│   │
│   ├── generated/                   # Protobuf 生成代码
│   │   ├── openclaw.pb.dart         # Protobuf 消息
│   │   └── openclaw.pbenum.dart     # 枚举定义
│   │
│   ├── services/                    # 服务层
│   │   ├── ecal_service.dart        # eCAL 通信服务
│   │   ├── credential_service.dart  # 凭证服务
│   │   └── vault_service.dart       # 保险库服务
│   │
│   ├── models/                      # 数据模型
│   │   ├── credential.dart          # 凭证模型
│   │   └── device_capability.dart   # 设备能力模型
│   │
│   ├── screens/                     # UI 界面
│   │   ├── home_screen.dart         # 主界面
│   │   ├── credential_screen.dart   # 凭证管理
│   │   └── settings_screen.dart     # 设置界面
│   │
│   ├── widgets/                     # UI 组件
│   │   ├── connection_status.dart   # 连接状态指示器
│   │   └── credential_card.dart     # 凭证卡片
│   │
│   └── utils/                       # 工具类
│       ├── crypto_utils.dart        # 加密工具
│       └── logger.dart              # 日志工具
│
├── proto/                           # Protobuf 定义
│   └── openclaw.proto
│
├── android/                         # Android 特定代码
├── ios/                             # iOS 特定代码
├── windows/                         # Windows 特定代码
├── macos/                           # macOS 特定代码
├── linux/                           # Linux 特定代码
│
├── docs/                            # 文档
│   ├── API_REFERENCE.md             # API 文档
│   ├── ARCHITECTURE.md              # 架构文档
│   ├── DEVELOPMENT_GUIDE.md         # 本文档
│   └── TESTING.md                   # 测试指南
│
└── test/                            # 测试代码
    ├── unit/                        # 单元测试
    ├── widget/                      # Widget 测试
    └── integration/                 # 集成测试
```

---

## 核心概念

### 1. eCAL 通信

**什么是 eCAL?**
eCAL (enhanced Communication Abstraction Layer) 是一个高性能通信中间件，专为分布式系统设计。

**核心特性**:
- **自动传输选择**: 本地用共享内存，网络用 UDP/TCP
- **零配置发现**: 设备自动发现，无需手动配置
- **brokerless**: 无中心节点，P2P 直接通信
- **跨平台**: Windows/Linux/macOS/Android/iOS

**基本用法**:
```dart
import 'package:ecal_dart/ecal_dart.dart';

// 发布消息
final publisher = EcalPublisher('topic_name');
await publisher.send('Hello World');

// 订阅消息
final subscriber = EcalSubscriber('topic_name');
subscriber.onMessage = (data) {
  print('收到：$data');
};

// 服务调用
final server = EcalService('service_name');
server.addMethod('method_name', (request) async {
  return 'Response';
});

// 客户端调用
final client = EcalClient('service_name');
final response = await client.call(method: 'method_name');
```

### 2. Protobuf 消息

**什么是 Protobuf?**
Protocol Buffers 是 Google 开发的接口定义语言，用于结构化数据序列化。

**基本语法**:
```protobuf
// openclaw.proto
syntax = "proto3";

message CredentialRequest {
    string service_url = 1;      // 目标服务 URL
    string session_id = 2;       // 会话 ID
    uint64 timestamp = 3;        // 时间戳
}

message CredentialResponse {
    string session_id = 1;
    bytes encrypted_credential = 2;
    bool success = 3;
    string error_message = 4;
}

service CredentialService {
    rpc GetCredential(CredentialRequest) returns (CredentialResponse);
    rpc UploadCookie(CookieUpload) returns (CredentialResponse);
}
```

**生成 Dart 代码**:
```bash
protoc --dart_out=lib/generated -Iproto proto/openclaw.proto
```

**使用生成的代码**:
```dart
import 'generated/openclaw.pb.dart';

// 创建消息
final request = CredentialRequest()
  ..serviceUrl = 'https://example.com'
  ..sessionId = 'uuid-123'
  ..timestamp = DateTime.now().millisecondsSinceEpoch;

// 序列化
final bytes = request.writeToBuffer();

// 反序列化
final parsed = CredentialRequest.fromBuffer(bytes);
```

### 3. zk_vault 安全存储

**什么是 zk_vault?**
zk_vault 是一个零知识安全存储库，使用硬件级加密保护敏感数据。

**核心特性**:
- AES-256-GCM 加密
- 硬件 KMS 集成 (Keystore/Keychain/TPM)
- 生物认证支持
- 内存安全（密钥用后立即清零）

**基本用法**:
```dart
import 'package:zk_vault/zk_vault.dart';

// 初始化
final vault = ZkVault();
await vault.initialize();

// 写入数据
await vault.write(
  key: 'credential',
  value: 'sensitive_data',
  requireAuth: true,  // 需要生物认证
);

// 读取数据
final data = await vault.read(
  key: 'credential',
  requireAuth: true,
);

// 删除数据
await vault.delete(key: 'credential');
```

### 4. 设备能力虚拟化

**概念**:
设备通过声明自身能力，实现能力共享和虚拟化。

**能力类型**:
| 能力 | 说明 | 使用场景 |
|------|------|---------|
| `credential_provider` | 提供凭证存储 | 远程授信 |
| `biometric_auth` | 生物认证 | 身份验证 |
| `secure_storage` | 安全存储 | 敏感数据 |
| `sensor_data` | 传感器数据 | 设备状态 |

**声明能力**:
```dart
final capability = Capability()
  ..deviceId = getDeviceId()
  ..services.addAll(['credential_provider', 'biometric_auth'])
  ..metadata['platform'] = 'android'
  ..metadata['has_biometric'] = 'true';

// 发布能力声明
final publisher = EcalPublisher('device_capability');
await publisher.send(capability.writeToBuffer());
```

---

## 开发流程

### 1. 功能开发流程

```
1. 需求分析
   ↓
2. 设计 Protobuf 接口
   ↓
3. 生成 Dart 代码
   ↓
4. 实现业务逻辑
   ↓
5. 编写单元测试
   ↓
6. 集成测试
   ↓
7. 代码审查
   ↓
8. 合并到主分支
```

### 2. 添加新 API

**步骤 1**: 修改 `.proto` 文件
```protobuf
// proto/openclaw.proto
message NewFeatureRequest {
    string param1 = 1;
    int32 param2 = 2;
}

message NewFeatureResponse {
    bool success = 1;
    string result = 2;
}

service NewFeatureService {
    rpc DoSomething(NewFeatureRequest) returns (NewFeatureResponse);
}
```

**步骤 2**: 生成代码
```bash
protoc --dart_out=lib/generated -Iproto proto/openclaw.proto
```

**步骤 3**: 实现服务
```dart
class NewFeatureService {
  final EcalService _server;

  NewFeatureService() : _server = EcalService('NewFeatureService');

  Future<void> initialize() async {
    await _server.init();
    _server.addMethod('DoSomething', _handleDoSomething);
  }

  Future<NewFeatureResponse> _handleDoSomething(
    NewFeatureRequest request
  ) async {
    // 业务逻辑
    final result = await _processRequest(request);
    
    return NewFeatureResponse()
      ..success = true
      ..result = result;
  }
}
```

**步骤 4**: 编写测试
```dart
test('NewFeatureService should process request', () async {
  final service = NewFeatureService();
  await service.initialize();

  final request = NewFeatureRequest()
    ..param1 = 'test'
    ..param2 = 42;

  final response = await service._handleDoSomething(request);
  
  expect(response.success, true);
  expect(response.result, isNotEmpty);
});
```

### 3. 调试流程

**步骤 1**: 启用日志
```dart
import 'package:polyvault/utils/logger.dart';

Logger.level = LogLevel.debug;  // 设置日志级别
```

**步骤 2**: 查看 eCAL 监控
```bash
# Windows: 运行 eCAL Monitor
# Linux: ecal_monitor
```

**步骤 3**: 使用 Flutter DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

---

## 调试技巧

### 1. eCAL 调试

**查看消息流**:
```dart
// 启用 eCAL 日志
EcalLogger.level = LogLevel.debug;

// 订阅所有消息
final monitor = EcalSubscriber('*');
monitor.onMessage = (data) {
  print('收到消息：$data');
};
```

**常见问题**:
| 问题 | 原因 | 解决方法 |
|------|------|---------|
| 设备不可见 | eCAL 未启动 | 检查 eCAL 服务状态 |
| 消息丢失 | 网络问题 | 检查防火墙设置 |
| 序列化失败 | Protobuf 版本不匹配 | 统一 Protobuf 版本 |

### 2. zk_vault 调试

**查看存储状态**:
```dart
// 列出所有键（不显示值）
final keys = await vault.listKeys();
print('存储的键：$keys');

// 检查密钥是否存在
final exists = await vault.exists(key: 'credential');
print('密钥存在：$exists');
```

**常见问题**:
| 问题 | 原因 | 解决方法 |
|------|------|---------|
| 生物认证失败 | 设备不支持 | 使用密码回退 |
| 存储失败 | 空间不足 | 清理旧数据 |
| 解密失败 | 密钥轮换 | 重新保存凭证 |

### 3. Flutter 调试

**性能分析**:
```bash
flutter run --profile
# 然后使用 DevTools 分析性能
```

**内存分析**:
```bash
flutter run --profile
# DevTools -> Memory -> Take snapshot
```

---

## 常见问题

### Q1: eCAL 连接失败怎么办？

**检查清单**:
1. ✅ eCAL 服务是否运行
2. ✅ 防火墙是否阻止
3. ✅ 主题名称是否一致
4. ✅ Protobuf 版本是否匹配

**解决方法**:
```bash
# Windows: 检查服务
Get-Service eCAL

# Linux: 检查进程
ps aux | grep ecal

# 重启 eCAL
ecalhost stop
ecalhost start
```

### Q2: zk_vault 无法存储数据？

**检查清单**:
1. ✅ 是否已初始化
2. ✅ 是否有存储权限
3. ✅ 设备是否支持硬件加密
4. ✅ 存储空间是否充足

**解决方法**:
```dart
// 检查设备支持
final supported = await ZkVault.isSupported();
if (!supported) {
  // 使用备用方案
  await FlutterSecureStorage().write(...);
}
```

### Q3: Protobuf 代码生成失败？

**检查清单**:
1. ✅ protoc 是否安装
2. ✅ dart-protoc-plugin 是否安装
3. ✅ .proto 文件语法是否正确
4. ✅ 输出目录是否存在

**解决方法**:
```bash
# 安装 protoc
brew install protobuf  # macOS
sudo apt install protobuf-compiler  # Linux

# 安装 Dart 插件
dart pub global activate protoc_plugin

# 重新生成
protoc --dart_out=lib/generated -Iproto proto/*.proto
```

### Q4: 跨平台编译失败？

**检查清单**:
1. ✅ 各平台 SDK 是否安装
2. ✅ 最低版本要求是否满足
3. ✅ 依赖是否支持目标平台
4. ✅ 平台特定配置是否正确

**解决方法**:
```yaml
# pubspec.yaml
# 检查依赖的平台支持
dependencies:
  zk_vault: ^1.0.0  # ✅ 支持所有平台
  some_plugin: ^1.0.0  # ❌ 可能不支持某些平台
```

---

## 参考资源

### 官方文档

- [Flutter 文档](https://docs.flutter.dev/)
- [eCAL 文档](https://eclipse-ecal.github.io/ecal/)
- [Protobuf 文档](https://protobuf.dev/)
- [zk_vault 文档](https://pub.dev/packages/zk_vault)

### 代码示例

- [PolyVault 示例代码](https://github.com/PolyVault/polyvault-examples)
- [eCAL Dart 示例](https://github.com/eclipse-ecal/ecal-dart)
- [Flutter 安全存储示例](https://github.com/mogol/flutter_secure_storage)

### 社区资源

- [PolyVault Discord](https://discord.gg/polyvault)
- [Flutter 社区](https://flutter.dev/community)
- [Stack Overflow - PolyVault](https://stackoverflow.com/questions/tagged/polyvault)

### 开发工具

- [VS Code + Flutter 插件](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter)
- [Android Studio](https://developer.android.com/studio)
- [Flutter DevTools](https://docs.flutter.dev/development/tools/devtools/overview)

---

## 下一步

完成本指南后，你可以：

1. ✅ 开始开发第一个功能
2. ✅ 阅读 [API_REFERENCE.md](./API_REFERENCE.md) 了解详细接口
3. ✅ 阅读 [ARCHITECTURE.md](./ARCHITECTURE.md) 了解整体架构
4. ✅ 阅读 [TESTING.md](./TESTING.md) 了解测试方法
5. ✅ 参与 [CONTRIBUTING.md](./CONTRIBUTING.md) 贡献代码

---

**文档维护**: PolyVault 开发团队  
**版本**: v1.0  
**创建时间**: 2026-03-14  
**反馈邮箱**: docs@polyvault.io
