# PolyVault

**OpenClaw Remote Authorization Client / OpenClaw 远程授信客户端**

PolyVault is a cross-platform, hardware-secured, decentralized remote authorization system built on **eCAL + zk_vault**. It enables OpenClaw servers to request credentials from user clients in real-time without storing any plaintext sensitive information server-side.

PolyVault 是基于 **eCAL + zk_vault** 的跨平台、硬件级安全、去中心化远程授信系统。它让 OpenClaw 服务器能够实时向用户客户端请求凭证，服务器端不存储任何明文敏感信息。

---

## ✨ Features / 特性

- **Remote Authorization / 远程授信** – When OpenClaw server needs to login to third-party services, it requests credentials from user client in real-time. Server never stores plaintext secrets.  
  **远程授信**：OpenClaw服务器需要登录第三方服务时，实时向用户客户端请求凭证，服务器端不存储任何明文敏感信息。

- **Hardware-Level Security / 硬件级安全** – All credentials are protected by secure hardware (TEE, Secure Enclave, TPM) on the client side.  
  **硬件级安全**：所有凭证在客户端由安全硬件（TEE、Secure Enclave、TPM）保护。

- **Decentralized Communication / 去中心化通信** – Direct P2P encrypted channel between client and OpenClaw via eCAL. No central server dependency.  
  **去中心化通信**：客户端与OpenClaw之间通过eCAL的P2P加密通道直接通信，无需依赖中心服务器。

- **Cross-Platform / 跨平台覆盖** – iOS, Android, Windows, macOS, Linux, and embedded systems.  
  **跨平台覆盖**：支持 iOS、Android、Windows、macOS、Linux 和嵌入式系统。

- **HarmonyOS-Inspired / 鸿蒙优先** – Architecture借鉴 HarmonyOS distributed soft bus and HUKS design principles.  
  **鸿蒙优先**：底层架构借鉴鸿蒙的分布式软总线、HUKS设计理念。

- **Browser Integration / 浏览器集成** – Chrome/Firefox extension for automatic credential autofill.  
  **浏览器集成**：Chrome/Firefox扩展支持自动填充凭证。

---

## 🏗️ Architecture / 架构

### 核心理念

**PolyVault = 端对端通信组件 + 四大插件接口（核心内核）**

**插件化一切**：密码箱和鉴权也是系统插件（权限最高，但可移除）

```
核心内核（不可移除）：
  - 端对端通信组件（eCAL）
  - 四大插件接口（过滤/转换/汇流/分发）

系统插件（权限最高，可移除）：
  - 密码箱（zk_vault）
  - 鉴权（OAuth2）

生态插件（灵活组合）：
  - Agent 端/IoT 端/Flutter 客户端/Web 客户端...
```

### 完整架构图

```
┌─────────────────────────────────────────────────────────┐
│                  PolyVault 主项目                        │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  核心内核（不可移除）                              │ │
│  │  ├─ 端对端通信组件（eCAL）                        │ │
│  │  │   - P2P 加密通信                                │ │
│  │  │   - 设备发现                                   │ │
│  │  │   - 消息路由                                   │ │
│  │  └─ 四大插件接口                                  │ │
│  │      ├─ 过滤器接口（二元决策）                    │ │
│  │      ├─ 转换器接口（A→B）                         │ │
│  │      ├─ 汇流器接口（N→1）                         │ │
│  │      └─ 分发器接口（1→N）                         │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  系统插件（高权限，可移除）                        │ │
│  │  ├─ 密码箱（zk_vault）← 系统插件                 │ │
│  │  │   - AES-256-GCM 加密                           │ │
│  │  │   - 硬件 KMS 集成                               │ │
│  │  └─ 鉴权（OAuth2）← 系统插件                     │ │
│  │      - 身份认证                                   │ │
│  │      - 权限管理                                   │ │
│  └───────────────────────────────────────────────────┘ │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │  plugins/ 文件夹（生态插件）                       │ │
│  │  ├─ agent-client/    (Agent 端插件)               │ │
│  │  ├─ iot-client/      (IoT 端插件)                 │ │
│  │  ├─ flutter-client/  (Flutter 客户端插件)         │ │
│  │  ├─ web-client/      (Web 客户端插件)             │ │
│  │  └─ ...更多插件                                    │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 设计优势

1. **核心最小化** - 只有通信 + 接口（最精简内核）
2. **插件化一切** - 所有功能都是插件（包括密码箱/鉴权）
3. **灵活组合** - 不同场景用不同插件组合
4. **可移除** - 即使密码箱/鉴权也可移除（极端场景）

### 传统架构视图

```
┌─────────────────────────────────────────────┐
│           Frontend (Flutter App)             │
│  Credential Manager · Auth Requests · UI     │
└───────────────────────┬─────────────────────┘
                        │ dart:ffi
┌───────────────────────▼─────────────────────┐
│         Local Agent (C++ / Rust)             │
│  • eCAL Service Server                       │
│  • zk_vault Integration                      │
│  • Native Messaging Host                     │
└───────────────────────┬─────────────────────┘
                        │ eCAL (P2P)
┌───────────────────────▼─────────────────────┐
│            OpenClaw Server                   │
│  • eCAL Service Client                       │
│  • Auth Request Dispatcher                   │
│  • No credential storage                     │
└─────────────────────────────────────────────┘
                        │
┌───────────────────────▼─────────────────────┐
│          Secure Hardware Layer               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │   TEE    │  │ Secure   │  │   TPM    │   │
│  │(Android) │  │Enclave   │  │(Desktop) │   │
│  │          │  │(iOS/mac) │  │          │   │
│  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────┘
```

---

## 🔧 Tech Stack / 技术栈

| Layer / 层级 | Technology / 技术选型 |
|--------------|----------------------|
| **Communication / 通信层** | eCAL (shared memory/UDP/TCP auto-switch) |
| **Security / 安全层** | zk_vault + Native Keystore (Android Keystore, iOS Keychain, TPM) |
| **Client / 客户端** | Flutter + Dart FFI |
| **Local Agent / 本地Agent** | C++ / Rust + eCAL |
| **Browser Extension / 浏览器扩展** | Manifest V3 + Native Messaging |
| **Serialization / 序列化** | Protobuf |

---

## 🧱 Core Components / 核心组件

### 1. eCAL Communication Layer / eCAL通信层
- Auto transport selection (shared memory → UDP → TCP)  
  自动传输选择（共享内存 → UDP → TCP）
- Brokerless architecture, zero-configuration discovery  
  无Broker架构，零配置发现
- High-performance, low-latency P2P communication  
  高性能、低延迟P2P通信

### 2. zk_vault Security Layer / zk_vault安全层
- AES-256-GCM encryption for all credentials  
  所有凭证使用 AES-256-GCM 加密
- Hardware KMS integration (TEE, Secure Enclave, TPM)  
  硬件KMS集成
- Biometric authentication support  
  生物认证支持

### 3. Flutter Client / Flutter客户端
- Cross-platform UI (iOS, Android, Windows, macOS, Linux)  
  跨平台UI
- eCAL C API integration via FFI  
  通过FFI调用eCAL C API
- Secure credential display and management  
  安全凭证展示与管理

### 4. Local Agent / 本地Agent
- Native Messaging host for browser extension  
  浏览器扩展的Native Messaging宿主
- eCAL service server for remote auth requests  
  处理远程授权请求的eCAL服务端
- Platform-native credential storage integration  
  平台原生凭证存储集成

### 5. Browser Extension / 浏览器扩展
- Automatic credential autofill  
  自动凭证填充
- Secure communication with local agent  
  与本地Agent的安全通信
- Chrome and Firefox support  
  支持 Chrome 和 Firefox

---

## 🚀 Quick Start / 快速开始

### Prerequisites / 前置要求
- Rust 1.70+ or C++17 compiler / Rust 1.70+ 或 C++17 编译器
- Flutter 3.x / Flutter 3.x
- eCAL 5.12+ / eCAL 5.12+
- CMake, Ninja / CMake, Ninja

### Build the Local Agent / 构建本地Agent
```bash
cd src/agent
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

### Build the Flutter App / 构建Flutter应用
```bash
cd src/client
flutter pub get
flutter run
```

> Detailed build instructions for each platform can be found in [docs/BUILD.md](docs/BUILD.md).  
> 各平台的详细构建说明请参阅 [docs/BUILD.md](docs/BUILD.md)。

---

## 🧱 Project Structure / 项目结构

```
PolyVault/
├── src/
│   ├── agent/              # C++/Rust local agent / 本地Agent
│   │   ├── CMakeLists.txt
│   │   └── src/
│   ├── client/             # Flutter app / Flutter客户端
│   │   ├── lib/
│   │   └── pubspec.yaml
│   └── proto/              # Protobuf definitions / Protobuf定义
│       └── auth.proto
├── docs/                    # Documentation / 文档
│   ├── TECHNICAL_SPECIFICATION.md
│   └── ARCHITECTURE.md
├── extensions/              # Browser extensions / 浏览器扩展
│   └── chrome/
└── README.md
```

---

## 🔐 Security Model / 安全模型

- **Zero Knowledge** – Server never sees or stores plaintext credentials.  
  **零知识**：服务器从不查看或存储明文凭证。
- **Hardware Isolation** – Master key never leaves secure hardware.  
  **硬件隔离**：主密钥永不离开安全硬件。
- **End-to-End Encryption** – All communication encrypted with forward secrecy.  
  **端到端加密**：所有通信都使用前向保密加密。
- **Biometric Protection** – Require fingerprint/face ID for sensitive operations.  
  **生物认证保护**：敏感操作要求指纹/面容ID验证。
- **Time-Locked Access** – Optional time-based access control.  
  **时间锁访问控制**：可选的基于时间的访问控制。

---

## 📅 Roadmap / 开发路线图

### Phase 1: Foundation / 阶段一：基础通信与安全（1-2个月）
- [x] eCAL environment setup / eCAL环境搭建
- [x] Flutter + zk_vault integration / Flutter集成zk_vault
- [ ] FFI binding for eCAL C API / FFI调用eCAL C API

### Phase 2: Core Authorization / 阶段二：远程授信核心（2-3个月）
- [ ] Protobuf protocol definition / Protobuf协议定义
- [ ] Browser extension development / 浏览器扩展开发
- [ ] Complete auth flow / 完整登录授权流程

### Phase 3: Capability Virtualization / 阶段三：能力虚拟化（2个月）
- [ ] eCAL Service device capability discovery / eCAL Service设备能力发现
- [ ] Cross-device credential sync / 凭证跨设备同步

### Phase 4: Embedded Support / 阶段四：嵌入式支持（2-3个月）
- [ ] eCAL core trimming / eCAL核心裁剪
- [ ] Secure chip integration / 安全芯片集成

### Phase 5: HarmonyOS Native / 阶段五：鸿蒙原生适配（2个月）
- [ ] HUKS integration / HUKS集成
- [ ] Distributed soft bus integration / 分布式软总线集成

---

## 🤝 Contributing / 贡献

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

我们欢迎各种形式的贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解贡献指南。

---

## 📄 License / 许可证

PolyVault is licensed under the **Apache 2.0 License**.  
See [LICENSE](LICENSE) for details.

PolyVault 采用 **Apache 2.0 许可证**。  
详情请参阅 [LICENSE](LICENSE)。

---

## 📬 Contact / 联系方式

- GitHub Issues – for questions and discussions / 用于提问和讨论
- Discord: [OpenClaw Community](https://discord.com/invite/clawd)

---

**PolyVault – Secure authorization, powered by hardware.**  
**PolyVault – 硬件级安全，授权无忧。**