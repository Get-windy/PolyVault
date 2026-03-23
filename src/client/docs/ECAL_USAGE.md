# Flutter eCAL 通信层使用指南

## 概述

Flutter eCAL 通信层为 PolyVault 客户端提供与 C++ Agent 的通信能力。支持两种通信模式：

1. **REST API 模式** - 通过 HTTP 与 C++ Agent 通信，跨平台兼容
2. **原生 eCAL 模式** - 通过 Platform Channel 调用原生 eCAL，高性能（需要原生实现）

## 快速开始

### 1. 初始化服务

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polyvault/providers/ecal_provider.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取 eCAL 服务
    final ecalService = ref.watch(ecalServiceProvider);
    
    return FutureBuilder(
      future: ecalService.initialize(deviceName: 'MyDevice'),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return HomeScreen();
        } else {
          return LoadingScreen();
        }
      },
    );
  }
}
```

### 2. 设备发现与配对

```dart
// 开始设备发现
final devicesNotifier = ref.read(discoveredDevicesProvider.notifier);
devicesNotifier.startDiscovery();

// 监听发现的设备
final devices = ref.watch(discoveredDevicesProvider);
ListView.builder(
  itemCount: devices.length,
  itemBuilder: (context, index) {
    final device = devices[index];
    return ListTile(
      title: Text(device.deviceName),
      subtitle: Text(device.deviceId),
      onTap: () => ecalService.requestPairing(device.deviceId),
    );
  },
);
```

### 3. 凭证操作

```dart
// 获取凭证
final response = await ecalService.getCredential(
  serviceUrl: 'https://accounts.google.com',
  sessionId: 'session_123',
);

if (response?.success == true) {
  // 解密并使用凭证
  final encryptedData = response!.encryptedCredential;
  // ... 解密逻辑
}

// 存储凭证
final success = await ecalService.storeCredential(
  serviceUrl: 'https://example.com',
  encryptedCredential: encryptedData,
  sessionId: 'session_123',
);

// 列出所有凭证
final credentials = await ecalService.listCredentials('session_123');
```

### 4. Cookie 管理

```dart
// 上传 Cookie
await ecalService.uploadCookie(
  serviceUrl: 'https://example.com',
  encryptedCookie: encryptedCookieData,
  sessionId: 'session_123',
);

// 下载 Cookie
final cookieResponse = await ecalService.downloadCookie(
  serviceUrl: 'https://example.com',
  sessionId: 'session_123',
);
```

### 5. 数据同步

```dart
// 请求同步
final syncResponse = await ecalService.requestSync(
  sinceTimestamp: lastSyncTime,
  dataTypes: ['credentials', 'cookies', 'settings'],
);

if (syncResponse?.success == true) {
  for (final item in syncResponse!.items) {
    // 处理同步项
    print('Sync item: ${item.type} - ${item.key}');
  }
}
```

## Provider 参考

| Provider | 类型 | 说明 |
|----------|------|------|
| `ecalServiceProvider` | `EcalService` | eCAL 服务实例 |
| `ecalConnectionStateProvider` | `EcalConnectionState` | 连接状态 |
| `discoveredDevicesProvider` | `List<DiscoveryMessage>` | 发现的设备列表 |
| `pairingStateProvider` | `PairingState` | 配对状态 |
| `pendingCredentialRequestsProvider` | `List<CredentialRequest>` | 待处理的凭证请求 |
| `localDeviceInfoProvider` | `Map<String, String>` | 本地设备信息 |

## 消息协议

所有消息格式与 C++ Agent 的 Protobuf 定义对齐：

- `CredentialRequest` / `CredentialResponse` - 凭证请求/响应
- `CookieUploadRequest` / `CookieDownloadResponse` - Cookie 操作
- `DiscoveryMessage` / `DiscoveryResponse` - 设备发现
- `HandshakeRequest` / `HandshakeResponse` - 握手
- `Heartbeat` / `HeartbeatAck` - 心跳
- `SyncRequest` / `SyncResponse` - 数据同步

## REST API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/discovery/devices` | GET | 发现设备 |
| `/api/discovery/broadcast` | POST | 广播发现消息 |
| `/api/credentials/get` | POST | 获取凭证 |
| `/api/credentials/store` | POST | 存储凭证 |
| `/api/credentials/delete` | DELETE | 删除凭证 |
| `/api/cookies/upload` | POST | 上传 Cookie |
| `/api/cookies/download` | POST | 下载 Cookie |
| `/api/auth/handshake` | POST | 握手 |
| `/api/auth/authenticate` | POST | 认证 |
| `/api/heartbeat` | POST | 心跳 |
| `/api/sync/request` | POST | 请求同步 |
| `/api/health` | GET | 健康检查 |

## 配置选项

```dart
final config = EcalServiceConfig(
  preferredMode: CommunicationMode.hybrid,  // 通信模式
  restBaseUrl: 'http://localhost:3001',      // REST API 地址
  heartbeatInterval: Duration(seconds: 10), // 心跳间隔
  discoveryInterval: Duration(seconds: 5),  // 发现间隔
  maxRetries: 3,                            // 最大重试次数
);
```

## 原生集成（Android/iOS/Windows）

要启用原生 eCAL 支持，需要：

1. **Android**: 在 `android/app/src/main/kotlin/` 实现 `MethodCallHandler`
2. **iOS**: 在 `ios/Classes/` 实现 `FlutterPlugin`
3. **Windows**: 在 `windows/runner/` 实现 C++ 插件

参考 `ecal_platform_channel.dart` 中的方法名常量实现原生端。

## 文件结构

```
lib/services/
├── ecal_service.dart          # 主服务（统一接口）
├── ecal_protocol.dart         # 消息协议定义
├── ecal_rest_client.dart      # REST API 客户端
├── ecal_platform_channel.dart # Platform Channel 接口
└── ...

lib/providers/
├── ecal_provider.dart         # Riverpod Providers
└── ...
```

## 注意事项

1. **安全**: 所有敏感数据（凭证、Cookie）应先加密再传输
2. **错误处理**: 所有 API 返回 `ApiResponse<T>` 包装，包含成功/失败状态
3. **生命周期**: 服务在应用退出时应调用 `dispose()` 释放资源
4. **重连**: REST 模式下建议实现自动重试逻辑

## 更新日志

### 2026-03-24
- 完整实现 eCAL 通信层
- 支持 REST API 和 Platform Channel 双模式
- 消息协议与 C++ Agent 对齐
- Riverpod Provider 集成