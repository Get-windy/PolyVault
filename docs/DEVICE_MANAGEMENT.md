# PolyVault 设备管理指南

**版本**: v1.0  
**创建时间**: 2026-03-14  
**适用对象**: 开发者、系统管理员

---

## 📖 目录

1. [设备管理概述](#设备管理概述)
2. [设备能力声明](#设备能力声明)
3. [设备发现与注册](#设备发现与注册)
4. [设备间通信](#设备间通信)
5. [设备同步](#设备同步)
6. [设备安全](#设备安全)
7. [设备管理 API](#设备管理-api)
8. [使用示例](#使用示例)
9. [故障排查](#故障排查)

---

## 设备管理概述

### 什么是设备管理？

PolyVault 的设备管理功能允许多个设备之间安全地共享凭证、同步数据，同时保持硬件级安全保护。

### 核心特性

| 特性 | 说明 |
|------|------|
| **设备发现** | 自动发现同一网络下的其他设备 |
| **能力声明** | 设备声明自身支持的能力 |
| **P2P 通信** | 设备间直接通信，无需中心服务器 |
| **凭证同步** | 加密凭证跨设备同步 |
| **安全认证** | 设备间双向认证 |

### 支持的设备类型

| 设备类型 | 能力 | 平台 |
|---------|------|------|
| **手机客户端** | 完整功能 | iOS/Android |
| **电脑客户端** | 完整功能 | Windows/macOS/Linux |
| **浏览器扩展** | 凭证填充 | Chrome/Firefox/Edge |
| **嵌入式设备** | 基础功能 | ESP32/树莓派 |

---

## 设备能力声明

### 能力类型

PolyVault 使用 Protobuf 定义设备能力：

```protobuf
message Capability {
    string device_id = 1;                    // 设备唯一标识
    repeated string services = 2;            // 支持的服务列表
    map<string, string> metadata = 3;        // 元数据
}
```

### 预定义服务

| 服务 | 说明 | 必需能力 |
|------|------|---------|
| `credential_provider` | 提供凭证存储 | zk_vault |
| `biometric_auth` | 生物认证 | 指纹/面容识别 |
| `secure_storage` | 安全存储 | 硬件加密 |
| `device_sync` | 设备同步 | 网络通信 |

### 元数据字段

```protobuf
{
  "platform": "android|ios|windows|macos|linux",
  "platform_version": "13|16|11|13|22.04",
  "app_version": "1.0.0",
  "has_biometric": "true|false",
  "has_secure_element": "true|false",
  "last_seen": "1710336000000"
}
```

### 声明设备能力

**Dart 示例**:

```dart
import 'package:polyvault/polyvault.dart';

// 创建能力声明
final capability = Capability()
  ..deviceId = await getDeviceId()
  ..services.addAll([
    'credential_provider',
    'biometric_auth',
    'device_sync',
  ])
  ..metadata['platform'] = 'android'
  ..metadata['platform_version'] = '13'
  ..metadata['has_biometric'] = 'true'
  ..metadata['has_secure_element'] = 'true'
  ..metadata['app_version'] = '1.0.0';

// 发布能力声明
final publisher = EcalPublisher('device_capability');
await publisher.send(capability.writeToBuffer());

print('✅ 设备能力已声明');
```

---

## 设备发现与注册

### 设备发现机制

PolyVault 使用 eCAL 的设备发现功能：

1. **本地网络发现**: 通过 UDP 广播
2. **零配置**: 无需手动配置
3. **自动更新**: 设备状态变化自动通知

### 发现流程

```
1. 设备启动
   ↓
2. 发布能力声明
   ↓
3. 订阅其他设备声明
   ↓
4. 发现新设备
   ↓
5. 建立安全连接
   ↓
6. 同步凭证（可选）
```

### 设备注册

**Dart 示例**:

```dart
class DeviceManager {
  final Map<String, Capability> _devices = {};
  final EcalSubscriber _subscriber;

  DeviceManager() : _subscriber = EcalSubscriber('device_capability');

  Future<void> initialize() async {
    // 订阅设备能力更新
    _subscriber.onMessage = (data) {
      final capability = Capability.fromBuffer(data);
      _devices[capability.deviceId] = capability;
      
      print('发现设备：${capability.deviceId}');
      print('支持服务：${capability.services}');
    };

    // 发布自身能力
    await publishCapability();
  }

  List<Capability> getAvailableDevices() {
    return _devices.values.toList();
  }

  bool isDeviceAvailable(String deviceId) {
    return _devices.containsKey(deviceId);
  }
}
```

---

## 设备间通信

### 通信模式

#### 1. 发布 - 订阅模式

用于广播消息：

```dart
// 发布消息
final publisher = EcalPublisher('credential_sync');
await publisher.send(data);

// 订阅消息
final subscriber = EcalSubscriber('credential_sync');
subscriber.onMessage = (data) {
  print('收到同步数据');
};
```

#### 2. 服务 - 客户端模式

用于请求 - 响应：

```dart
// 服务端
final server = EcalService('credential_service');
server.addMethod('GetCredential', (request) async {
  final cred = await getCredential(request.serviceUrl);
  return cred;
});

// 客户端
final client = EcalClient('credential_service');
final response = await client.call(
  method: 'GetCredential',
  request: request,
);
```

### 通信安全

**加密方式**:
- eCAL 内置 TLS 1.3
- Protobuf 消息使用设备公钥加密
- 双向证书验证

**认证流程**:
```
设备 A                      设备 B
   │                          │
   │────Hello (含证书)───────►│
   │                          │ 验证证书
   │◄────Hello (含证书)───────│
   │ 验证证书                 │
   │                          │
   │────加密通道建立─────────►│
```

---

## 设备同步

### 同步策略

#### 1. 实时同步

适用于凭证变更：

```dart
// 凭证更新时立即同步
Future<void> syncCredential(Credential cred) async {
  final publisher = EcalPublisher('credential_update');
  
  final syncData = CredentialSync()
    ..credentialId = cred.id
    ..encryptedData = await encrypt(cred)
    ..timestamp = DateTime.now().millisecondsSinceEpoch;
  
  await publisher.send(syncData.writeToBuffer());
}
```

#### 2. 定期同步

适用于状态同步：

```dart
// 每 5 分钟同步一次
Timer.periodic(Duration(minutes: 5), (timer) async {
  await syncDeviceStatus();
});
```

#### 3. 增量同步

仅同步变更数据：

```dart
// 只同步上次同步后的变更
final changes = await getChangesSince(lastSyncTime);
await syncChanges(changes);
```

### 冲突解决

**策略**: 最后写入获胜 (Last Write Wins)

```dart
if (localUpdateTimestamp > remoteUpdateTimestamp) {
  // 使用本地数据
  await keepLocal(localData);
} else {
  // 使用远程数据
  await applyRemote(remoteData);
}
```

---

## 设备安全

### 设备认证

#### 1. 设备配对

首次连接需要配对：

```dart
// 生成配对码
final pairingCode = generatePairingCode(); // 6 位数字
print('配对码：$pairingCode');

// 在两个设备上输入相同的配对码
final verified = await verifyPairingCode(pairingCode);
if (verified) {
  print('✅ 配对成功');
}
```

#### 2. 证书交换

配对后交换设备证书：

```dart
// 生成设备密钥对
final keyPair = await generateKeyPair();

// 交换公钥
await exchangePublicKey(otherDeviceId, keyPair.publicKey);

// 保存对方公钥
await saveTrustedDevice(otherDeviceId, keyPair.publicKey);
```

### 信任管理

#### 信任设备列表

```dart
class TrustManager {
  final Map<String, DeviceInfo> _trustedDevices = {};

  // 添加信任设备
  Future<void> addTrustedDevice(String deviceId, DeviceInfo info) async {
    _trustedDevices[deviceId] = info;
    await saveToSecureStorage();
  }

  // 移除信任设备
  Future<void> removeTrustedDevice(String deviceId) async {
    _trustedDevices.remove(deviceId);
    await saveToSecureStorage();
  }

  // 检查是否信任
  bool isTrusted(String deviceId) {
    return _trustedDevices.containsKey(deviceId);
  }

  // 获取所有信任设备
  List<DeviceInfo> getTrustedDevices() {
    return _trustedDevices.values.toList();
  }
}
```

### 安全撤销

设备丢失或被盗时：

```dart
// 撤销设备信任
await revokeDevice(lostDeviceId);

// 通知其他设备
await broadcastRevoke(lostDeviceId);

// 重新加密所有凭证
await reencryptAllCredentials();
```

---

## 设备管理 API

### REST API

#### 获取设备列表

```http
GET /api/devices
Authorization: Bearer <token>
```

**响应**:

```json
{
  "success": true,
  "data": [
    {
      "device_id": "device-123",
      "name": "iPhone 15",
      "platform": "ios",
      "last_seen": "2026-03-14T12:00:00Z",
      "status": "online"
    }
  ]
}
```

#### 添加设备

```http
POST /api/devices
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "新设备",
  "pairing_code": "123456"
}
```

#### 移除设备

```http
DELETE /api/devices/:deviceId
Authorization: Bearer <token>
```

### eCAL API

#### 发布设备能力

```dart
final publisher = EcalPublisher('device_capability');
await publisher.send(capability.writeToBuffer());
```

#### 订阅设备更新

```dart
final subscriber = EcalSubscriber('device_update');
subscriber.onMessage = (data) {
  final update = DeviceUpdate.fromBuffer(data);
  print('设备 ${update.deviceId} 状态更新');
};
```

---

## 使用示例

### 示例 1: 多设备凭证同步

```dart
class CredentialSyncManager {
  final EcalPublisher _publisher;
  final EcalSubscriber _subscriber;

  CredentialSyncManager()
    : _publisher = EcalPublisher('credential_sync'),
      _subscriber = EcalSubscriber('credential_sync');

  Future<void> initialize() async {
    _subscriber.onMessage = _handleSync;
  }

  // 同步凭证到其他设备
  Future<void> syncCredential(Credential cred) async {
    final syncData = CredentialSync()
      ..credentialId = cred.id
      ..encryptedData = await encrypt(cred)
      ..timestamp = DateTime.now().millisecondsSinceEpoch
      ..sourceDevice = await getDeviceId();

    await _publisher.send(syncData.writeToBuffer());
    print('✅ 凭证已同步');
  }

  // 处理接收到的同步
  Future<void> _handleSync(ByteBuffer data) async {
    final sync = CredentialSync.fromBuffer(data);

    // 忽略自己发送的
    if (sync.sourceDevice == await getDeviceId()) {
      return;
    }

    // 验证来源设备
    if (!await verifyDevice(sync.sourceDevice)) {
      print('❌ 未信任设备，忽略同步');
      return;
    }

    // 解密并存储
    final cred = await decrypt(sync.encryptedData);
    await vault.saveCredential(cred);
    print('✅ 凭证已同步到本地');
  }
}
```

### 示例 2: 设备管理界面

```dart
class DeviceManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设备管理')),
      body: FutureBuilder<List<DeviceInfo>>(
        future: getTrustedDevices(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          final devices = snapshot.data!;

          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                leading: Icon(getPlatformIcon(device.platform)),
                title: Text(device.name),
                subtitle: Text('${device.platform} - 最后活跃：${device.lastSeen}'),
                trailing: Switch(
                  value: device.isActive,
                  onChanged: (value) => toggleDevice(device.id, value),
                ),
                onTap: () => showDeviceDetails(device),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addNewDevice(),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

---

## 故障排查

### 常见问题

#### Q1: 设备无法发现其他设备

**检查清单**:
1. ✅ 确认设备在同一网络
2. ✅ 检查防火墙设置
3. ✅ 确认 eCAL 服务运行
4. ✅ 检查网络权限

**解决方法**:
```bash
# Windows: 检查防火墙
netsh advfirewall firewall show rule name=all | findstr eCAL

# Linux: 检查防火墙
sudo ufw status

# 重启 eCAL 服务
ecalhost restart
```

#### Q2: 设备同步失败

**检查清单**:
1. ✅ 确认设备已配对
2. ✅ 检查网络连接
3. ✅ 验证设备证书
4. ✅ 检查存储空间

**解决方法**:
```dart
// 重新配对设备
await removeDevice(deviceId);
await addDevice(deviceId, pairingCode);

// 清除同步缓存
await clearSyncCache();

// 手动触发同步
await forceSync();
```

#### Q3: 设备认证失败

**可能原因**:
- 证书过期
- 设备时间不同步
- 网络中间人攻击

**解决方法**:
```dart
// 更新设备证书
await refreshDeviceCertificate();

// 同步设备时间
await syncDeviceTime();

// 重新建立信任
await reestablishTrust(deviceId);
```

---

## 最佳实践

### 设备命名

- 使用有意义的名称：`iPhone 15 - 张三`
- 包含设备类型：`Desktop - Office`
- 避免敏感信息：不要包含密码

### 安全建议

✅ **推荐**:
- 定期审查信任设备列表
- 移除不再使用的设备
- 启用生物认证
- 定期备份

❌ **避免**:
- 在公共网络配对设备
- 信任未知设备
- 禁用安全认证
- 忽略安全警告

### 性能优化

- 使用增量同步
- 批量处理设备更新
- 缓存设备信息
- 限制同步频率

---

## 参考资源

- [eCAL 文档](https://eclipse-ecal.github.io/ecal/)
- [Protobuf 规范](https://protobuf.dev/)
- [zk_vault 文档](https://pub.dev/packages/zk_vault)

---

**文档维护**: PolyVault 开发团队  
**版本**: v1.0  
**创建时间**: 2026-03-14  
**反馈邮箱**: docs@polyvault.io
