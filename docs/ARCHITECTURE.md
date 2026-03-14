# PolyVault 系统架构文档

**版本**: v2.0  
**最后更新**: 2026-03-14  
**状态**: 开发中  
**基于技术**: eCAL + zk_vault + Protobuf

---

## 📖 目录

1. [架构概览](#架构概览)
2. [核心组件](#核心组件)
3. [eCAL 通信模块](#ecal-通信模块)
4. [安全架构](#安全架构)
5. [数据流](#数据流)
6. [部署架构](#部署架构)
7. [技术选型](#技术选型)

---

## 架构概览

### 整体架构图

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

### 架构原则

| 原则 | 说明 |
|------|------|
| **本地优先** | 所有凭证默认本地存储，无云端依赖 |
| **硬件安全** | 使用各平台硬件安全模块（TEE/Secure Enclave/TPM） |
| **去中心化通信** | eCAL P2P 通信，无需中心服务器 |
| **跨平台覆盖** | 支持手机、电脑、浏览器、嵌入式设备 |
| **零知识证明** | 服务端无法访问用户明文凭证 |

---

## 核心组件

### 1. PolyVault Agent（C++）

**位置**: `src/agent/`

**职责**:
- eCAL 通信服务
- 凭证请求处理
- 与 OpenClaw 集成

**核心文件**:

```
src/agent/
├── src/
│   ├── main.cpp                  # 程序入口
│   ├── agent.cpp                 # Agent 核心逻辑
│   ├── agent.hpp                 # Agent 头文件
│   ├── credential_service.cpp    # 凭证服务
│   ├── credential_service.hpp    # 凭证服务头文件
│   ├── crypto_utils.cpp          # 加密工具
│   ├── crypto_utils.hpp          # 加密工具头文件
│   └── test_ecal_communication.cpp # eCAL 通信测试
├── include/                      # 公共头文件
├── generated/                    # Protobuf 生成代码
└── CMakeLists.txt                # 构建配置
```

**技术栈**:
- C++17
- eCAL 5.x
- Protobuf 3.x
- OpenSSL / libsodium

---

### 2. Flutter 客户端

**位置**: `src/client/`

**职责**:
- 用户界面
- 凭证存储（zk_vault）
- eCAL 通信

**核心目录**:

```
src/client/
├── lib/
│   ├── main.dart                 # 应用入口
│   ├── models/                   # 数据模型
│   │   ├── credential.dart       # 凭证模型
│   │   └── device.dart           # 设备模型
│   ├── services/                 # 服务层
│   │   ├── ecal_service.dart     # eCAL 通信服务
│   │   ├── vault_service.dart    # zk_vault 封装
│   │   └── auth_service.dart     # 认证服务
│   ├── providers/                # 状态管理
│   │   ├── credential_provider.dart
│   │   └── device_provider.dart
│   ├── screens/                  # 页面
│   │   ├── home_screen.dart
│   │   ├── credential_list_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/                  # 组件
│       ├── credential_card.dart
│       └── device_status.dart
├── android/                      # Android 平台
├── ios/                          # iOS 平台
├── windows/                      # Windows 平台
├── macos/                        # macOS 平台
└── linux/                        # Linux 平台
```

**技术栈**:
- Flutter 3.x
- Dart 3.x
- zk_vault
- eCAL Dart FFI

---

### 3. 浏览器扩展

**位置**: `src/extension/`

**职责**:
- 检测登录表单
- 与本地 Agent 通信
- 自动填充凭证

**技术栈**:
- Manifest V3
- JavaScript/TypeScript
- Native Messaging API

---

## eCAL 通信模块

### 什么是 eCAL？

**eCAL (enhanced Communication Abstraction Layer)** 是由 Continental 开源的高性能通信中间件，专为分布式系统设计。

**官网**: https://continental.github.io/ecal/

### eCAL 的核心特性

| 特性 | 说明 | 与 PolyVault 的契合点 |
|------|------|---------------------|
| **自动传输选择** | 本地通信用共享内存（1-20 GB/s），网络通信自动用 UDP/TCP | 设备在同一局域网用共享内存超低延迟，跨公网自动切换 TCP |
| **brokerless 架构** | 无中心节点，设备间直接 P2P 通信 | 完全去中心化，符合 PolyVault 设计理念 |
| **跨平台支持** | Windows/Linux（稳定）、macOS（实验）、支持 ARM | 覆盖所有目标平台 |
| **多语言绑定** | C++/C 核心，支持 Python、C#、Rust、Go、Dart（FFI） | Flutter 可通过 C API 调用 |
| **零配置发现** | 设备自动发现，无需手动配置 | 用户体验极佳 |
| **协议无关** | 支持 Protobuf、Cap'n Proto、FlatBuffers | 使用 Protobuf 定义通信协议 |

### eCAL 的通信模式

#### 1. 发布 - 订阅（Publish-Subscribe）

**用途**: 广播消息、事件通知

**示例场景**:
- 设备发现广播
- 状态更新通知
- 凭证变更通知

**代码示例**（C++）:

```cpp
#include <ecal/ecal.h>
#include <ecal/ecal_publisher.h>

// 定义主题
const char* TOPIC_CREDENTIAL_REQUEST = "polyvault.credential.request";

// 创建发布者
eCAL::CPublisher publisher(TOPIC_CREDENTIAL_REQUEST);

// 发送消息
std::string message = "Credential request data...";
publisher.Send(message.c_str(), message.size());
```

**代码示例**（Dart）:

```dart
import 'package:ffi/ffi.dart';
import 'dart:ffi';

// eCAL C API FFI 绑定
typedef EcalPublisherCreate = IntPtr Function(CharPtr topic_name);
typedef EcalPublisherSend = Int32 Function(IntPtr publisher, Pointer<Utf8> data, Int32 size);

// 创建发布者
final topic = "polyvault.credential.request".toNativeUtf8();
final publisher = ecalPublisherCreate(topic);

// 发送消息
final message = "Credential request data...".toNativeUtf8();
ecalPublisherSend(publisher, message, message.length);
```

#### 2. 服务 - 客户端（Service-Client）

**用途**: 请求 - 响应交互

**示例场景**:
- 凭证请求与响应
- 设备能力查询
- 认证授权

**代码示例**（C++）:

```cpp
#include <ecal/ecal_service_server.h>

// 定义服务
const char* SERVICE_CREDENTIAL = "polyvault.credential.service";

// 创建服务服务器
eCAL::CServiceServer server(SERVICE_CREDENTIAL);

// 注册回调
server.AddMethodCallback("GetCredential", 
  [](const eCAL::ServiceMethod& method, 
     const std::string& request, 
     std::string& response) -> int {
    // 处理凭证请求
    CredentialResponse cred_response = handleCredentialRequest(request);
    response = cred_response.SerializeAsString();
    return 0; // 成功
  });
```

### eCAL 在 PolyVault 中的应用

#### 1. 设备发现

```
┌──────────────┐
│  客户端 A    │ ──[eCAL 广播]──►  所有设备
│ (手机)       │
└──────────────┘

┌──────────────┐
│  客户端 B    │ ◄──[接收广播]──  发现客户端 A
│ (电脑)       │
└──────────────┘
```

**实现**:
- 每个客户端启动时广播自己的存在
- 广播包含设备 ID、设备类型、支持的服务
- 其他客户端接收并记录

#### 2. 凭证请求流程

```
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│  浏览器扩展  │      │  Local Agent │      │  Flutter     │
│              │      │  (C++)       │      │  Client      │
└──────┬───────┘      └──────┬───────┘      └──────┬───────┘
       │                     │                      │
       │ 1. 检测登录表单     │                      │
       │────────────────────►│                      │
       │                     │                      │
       │                     │ 2. eCAL 服务调用      │
       │                     │ [GetCredential]      │
       │                     │─────────────────────►│
       │                     │                      │
       │                     │                      │ 3. zk_vault 解密
       │                     │                      │ (硬件安全模块)
       │                     │                      │
       │                     │ 4. 返回加密凭证      │
       │                     │◄─────────────────────│
       │                     │                      │
       │ 5. 返回凭证         │                      │
       │◄────────────────────│                      │
       │                     │                      │
       │ 6. 自动填充表单     │                      │
       │                     │                      │
```

#### 3. eCAL 消息定义（Protobuf）

```protobuf
syntax = "proto3";

package polyvault;

// 凭证请求
message CredentialRequest {
    string service_url = 1;      // 目标服务 URL
    string session_id = 2;       // 会话标识符
    uint64 timestamp = 3;        // 请求时间戳
}

// 凭证响应
message CredentialResponse {
    string session_id = 1;           // 对应请求的会话 ID
    bytes encrypted_credential = 2;  // 加密的凭证数据
    bool success = 3;                // 操作是否成功
    string error_message = 4;        // 错误信息
}

// 设备发现广播
message DeviceDiscovery {
    string device_id = 1;            // 设备唯一标识
    string device_name = 2;          // 设备名称
    string device_type = 3;          // 设备类型（mobile/desktop/embedded）
    repeated string services = 4;    // 支持的服务列表
    uint64 timestamp = 5;            // 广播时间戳
}
```

### eCAL 配置

#### CMakeLists.txt（C++ Agent）

```cmake
cmake_minimum_required(VERSION 3.14)
project(PolyVaultAgent)

set(CMAKE_CXX_STANDARD 17)

# 查找 eCAL
find_package(eCAL REQUIRED)

# 查找 Protobuf
find_package(Protobuf REQUIRED)

# 包含目录
include_directories(
    ${eCAL_INCLUDE_DIRS}
    ${Protobuf_INCLUDE_DIRS}
    include/
)

# 源文件
set(SOURCES
    src/main.cpp
    src/agent.cpp
    src/credential_service.cpp
    src/crypto_utils.cpp
)

# 可执行文件
add_executable(polyvault-agent ${SOURCES})

# 链接库
target_link_libraries(polyvault-agent
    ${eCAL_LIBRARIES}
    ${Protobuf_LIBRARIES}
    OpenSSL::SSL
    OpenSSL::Crypto
)

# 包含 eCAL 配置
include(${eCAL_CMAKE_DIR}/eCALConfig.cmake)
```

#### pubspec.yaml（Flutter 客户端）

```yaml
name: polyvault_client
description: PolyVault Flutter Client with eCAL integration

dependencies:
  flutter:
    sdk: flutter
  ffi: ^2.0.0
  protobuf: ^2.1.0
  zk_vault: ^1.0.0

dev_dependencies:
  ffigen: ^8.0.0  # 生成 FFI 绑定

ffigen:
  name: EcalBindings
  description: eCAL C API FFI bindings
  output: 'lib/generated/ecal_bindings.dart'
  headers:
    entry-points:
      - '/usr/include/ecal/ecal.h'
```

### eCAL 性能优化

#### 1. 共享内存通信（本地）

当客户端和 Agent 在同一设备上时，eCAL 自动使用共享内存：

- **带宽**: 1-20 GB/s
- **延迟**: < 10 μs
- **零拷贝**: 数据直接映射到内存

#### 2. UDP 组播（局域网）

当设备在同一局域网时，使用 UDP 组播：

- **带宽**: 100-1000 Mbps
- **延迟**: < 1 ms
- **自动发现**: 零配置

#### 3. TCP（广域网）

跨公网通信时，使用 TCP：

- **带宽**: 取决于网络
- **延迟**: 取决于网络
- **TLS 加密**: 传输层安全

---

## 安全架构

### 1. 硬件安全集成

#### Android Keystore + StrongBox

```dart
import 'package:zk_vault/zk_vault.dart';

final vault = ZkVault(
  android: AndroidConfig(
    useStrongBox: true,  // API 28+ 使用独立安全芯片
    biometricRequired: true,
  ),
);

// 存储凭证
await vault.write(
  key: 'google.com',
  value: encryptedCredential,
);

// 读取凭证（需要生物认证）
final credential = await vault.read(
  key: 'google.com',
  biometricPrompt: '验证身份以读取凭证',
);
```

#### iOS Secure Enclave

```dart
final vault = ZkVault(
  ios: IOSConfig(
    useSecureEnclave: true,
    accessControl: BiometryCurrentSet,
  ),
);
```

#### Windows CNG + TPM

```cpp
#include <bcrypt.h>
#include <ncrypt.h>

// 使用 TPM 保护密钥
NCRYPT_KEY_HANDLE hKey;
NCryptOpenStorageProvider(&hProvider, MS_PLATFORM_KEY_STORAGE_PROVIDER, 0);
NCryptCreateKey(hProvider, &hKey, L"RSA", 2048, 0, NCRYPT_MACHINE_KEY_FLAG);
```

### 2. 数据加密流程

```
明文凭证
    │
    ▼
┌─────────────────┐
│ JSON 序列化     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ AES-256-GCM     │ ← 密钥来自 zk_vault
│ (硬件加速)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Protobuf 封装   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ eCAL 传输       │ ← TLS 加密
└────────┬────────┘
         │
         ▼
加密凭证（服务端接收）
```

### 3. 密钥管理

```
用户密码/生物特征
    │
    ▼
┌─────────────────┐
│ 密钥派生函数    │
│ (Argon2id)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 主密钥 (Master  │
│ Key)            │
└────────┬────────┘
         │
    ┌────┴────┬────────────┐
    │         │            │
    ▼         ▼            ▼
┌───────┐ ┌───────┐  ┌─────────┐
│ 凭证  │ │ 配置  │  │ 备份    │
│ 密钥  │ │ 密钥  │  │ 密钥    │
└───────┘ └───────┘  └─────────┘
```

---

## 数据流

### 完整登录流程

```
1. 用户访问第三方服务（如 Google）
   │
   ▼
2. 浏览器扩展检测到登录表单
   │
   ▼
3. 扩展通过 Native Messaging 通知本地 Agent
   │
   ▼
4. Agent 通过 eCAL 发送凭证请求到客户端
   │
   ▼
5. 客户端弹出授权提示（显示服务 URL）
   │
   ▼
6. 用户确认并生物认证
   │
   ▼
7. zk_vault 解密凭证（在安全硬件内）
   │
   ▼
8. 客户端通过 eCAL 返回加密凭证
   │
   ▼
9. Agent 解密凭证（仅在内存中）
   │
   ▼
10. Agent 返回凭证给浏览器扩展
    │
    ▼
11. 扩展自动填充表单并提交
    │
    ▼
12. 登录成功，Cookie 加密存储到客户端
    │
    ▼
13. Agent 清除内存中的明文凭证
```

---

## 部署架构

### 开发环境

```
┌─────────────────────────────────────────┐
│  开发机器                               │
│  ┌─────────────┐  ┌─────────────┐      │
│  │  Flutter    │  │  C++ Agent  │      │
│  │  Client     │  │  (eCAL)     │      │
│  │  (Debug)    │  │  (Debug)    │      │
│  └─────────────┘  └─────────────┘      │
│         │                │              │
│         └────────┬───────┘              │
│                  │                      │
│          ┌───────▼───────┐              │
│          │   eCAL Loop   │              │
│          │   (本地通信)  │              │
│          └───────────────┘              │
└─────────────────────────────────────────┘
```

### 生产环境

```
┌─────────────────────────────────────────┐
│  用户设备（手机/电脑）                   │
│  ┌─────────────┐  ┌─────────────┐      │
│  │  Flutter    │  │  C++ Agent  │      │
│  │  Client     │  │  (eCAL)     │      │
│  │  (Release)  │  │  (Release)  │      │
│  └─────────────┘  └─────────────┘      │
│         │                │              │
│         └────────┬───────┘              │
│                  │                      │
│          ┌───────▼───────┐              │
│          │   eCAL        │              │
│          │   (共享内存)  │              │
│          └───────────────┘              │
└─────────────────────────────────────────┘
         │
         │ eCAL TCP（跨设备）
         ▼
┌─────────────────────────────────────────┐
│  其他设备（平板/备用机）                 │
│  ┌─────────────┐                        │
│  │  Flutter    │                        │
│  │  Client     │                        │
│  └─────────────┘                        │
└─────────────────────────────────────────┘
```

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
| **加密库** | OpenSSL | 3.x | 加密算法实现 |

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

## 下一步

### 高优先级（本周）
- [ ] 完成 eCAL Dart FFI 绑定
- [ ] 测试共享内存通信性能
- [ ] 编写 eCAL 配置文档

### 中优先级（本月）
- [ ] 实现设备发现功能
- [ ] 完成凭证请求/响应流程
- [ ] 添加 eCAL 监控和日志

### 低优先级（下月）
- [ ] 鸿蒙 HUKS 适配
- [ ] 嵌入式设备支持
- [ ] 多设备同步机制

---

**文档维护**: PolyVault 开发组  
**反馈邮箱**: dev@polyvault.io  
**最后更新**: 2026-03-14
