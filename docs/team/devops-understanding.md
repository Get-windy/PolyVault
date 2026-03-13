# DevOps工程师对PolyVault的理解

> 阅读时间: 2026-03-13 23:38
> 文档版本: 1.0

---

## 一、项目核心认知

### 1.1 项目定位
**PolyVault = 远程授信客户端**

核心场景：OpenClaw服务器需要登录第三方服务时，**实时向用户设备请求凭证**，服务器端**不存储任何明文敏感信息**。

### 1.2 设计理念（借鉴鸿蒙）

| 鸿蒙理念 | PolyVault实现 | DevOps关注点 |
|---------|--------------|-------------|
| 分布式软总线 | eCAL自动选择最优传输 | 无需配置中心节点 |
| HUKS硬件安全 | zk_vault + 平台Keystore | 安全配置依赖平台 |
| 能力虚拟化 | Protobuf定义服务 | 服务发现自动化 |
| 分布式数据 | 跨设备同步 | 数据一致性 |

---

## 二、技术栈理解

### 2.1 通信层：eCAL

**为什么选eCAL？**
- **brokerless架构**：无中心节点，P2P直连
- **自动传输选择**：本地共享内存(1-20GB/s)，远程UDP/TCP
- **零配置发现**：设备自动发现，运维无负担

**eCAL部署要求**：
```
# Windows: 安装包
https://ecal.io/download/

# Linux: APT源
sudo add-apt-repository ppa:ecal/ecal-latest
sudo apt-get install ecal

# macOS: Homebrew（实验）
brew install ecal
```

### 2.2 安全层：zk_vault

**平台安全机制对照**：

| 平台 | 安全机制 | 最低版本 | 运维注意 |
|------|---------|---------|---------|
| Android | Keystore + StrongBox | API 21 | API 28+才有StrongBox |
| iOS | Secure Enclave + Keychain | iOS 11+ | 需配置FaceID权限 |
| Windows | CNG + TPM | - | TPM 2.0最佳 |
| macOS | Keychain + Secure Enclave | - | Apple Silicon最佳 |
| Linux | libsecret + TPM | - | 可选TPM增强 |
| 鸿蒙 | HUKS | - | TEE/安全芯片 |

### 2.3 序列化：Protobuf

**已定义的服务**：
- `CredentialService` - 凭证服务（客户端提供）
- `DeviceService` - 设备管理服务
- `AuthorizationService` - 授权服务（Agent提供）
- `SyncService` - 同步服务

---

## 三、部署架构理解

### 3.1 组件拓扑

```
┌─────────────────────────────────────────────────────────┐
│                      用户环境                           │
│  ┌─────────────────┐  ┌─────────────────────────────┐  │
│  │ 手机客户端       │  │ 电脑客户端                   │  │
│  │ Flutter+zk_vault│  │ Flutter+zk_vault            │  │
│  │ eCAL C API      │  │ eCAL C API                  │  │
│  └────────┬────────┘  └─────────────┬───────────────┘  │
│           │                         │                   │
│           └────────────┬────────────┘                   │
│                        │ eCAL P2P                       │
│  ┌─────────────────────▼─────────────────────────────┐ │
│  │              本地Agent (C++)                       │ │
│  │  - Native Messaging Server                        │ │
│  │  - 凭证加解密（内存中）                            │ │
│  └─────────────────────┬─────────────────────────────┘ │
│                        │ stdio                         │
│  ┌─────────────────────▼─────────────────────────────┐ │
│  │              浏览器扩展 (Manifest V3)              │ │
│  │  - 检测登录需求                                    │ │
│  │  - 自动填表                                        │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### 3.2 运维关键点

| 组件 | 部署方式 | 运维关注 |
|------|---------|---------|
| **Flutter客户端** | 应用商店/安装包 | 版本管理、自动更新 |
| **本地Agent** | 后台服务 | 开机自启、日志轮转 |
| **浏览器扩展** | Chrome Web Store | 版本兼容性 |
| **Native Messaging Host** | 注册表配置 | 路径正确性 |

---

## 四、构建与打包策略

### 4.1 C++ Agent构建

```bash
# CMake标准流程
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DUSE_ECAL=ON
cmake --build . --config Release
```

**依赖项**：
- CMake 3.16+
- Protobuf
- eCAL (可选)
- C++17编译器

### 4.2 Flutter客户端打包

```bash
# Android
flutter build apk --release
flutter build appbundle --release  # Play Store

# iOS
flutter build ios --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release

# Linux
flutter build linux --release
```

### 4.3 CI/CD建议

```yaml
# .github/workflows/build.yml (概念)
stages:
  - build-agent
  - build-flutter
  - package

build-agent:
  - Windows: MSVC + vcpkg
  - Linux: GCC + apt
  - macOS: Clang + brew

build-flutter:
  - flutter pub get
  - flutter build <platform>

package:
  - Windows: NSIS安装包
  - Linux: .deb + .rpm
  - macOS: .dmg
```

---

## 五、安全配置要点

### 5.1 Native Messaging Host注册

**Windows**:
```
路径: HKCU\Software\Google\Chrome\NativeMessagingHosts\com.openclaw.agent
或: %LOCALAPPDATA%\Google\Chrome\User Data\NativeMessagingHosts\com.openclaw.agent.json
```

**配置文件**:
```json
{
  "name": "com.openclaw.agent",
  "description": "OpenClaw Native Messaging Agent",
  "path": "C:\\Program Files\\OpenClaw\\agent.exe",
  "type": "stdio",
  "allowed_origins": ["chrome-extension://<EXTENSION_ID>/"]
}
```

### 5.2 凭证安全流转

```
1. 客户端存储: zk_vault加密（硬件保护）
2. 传输: 端到端加密（客户端公钥）
3. Agent内存: 明文仅存在于内存，用后立即清零
4. 浏览器扩展: 仅接收明文凭证用于填表
```

**安全原则**：
- ✅ 凭证永不在磁盘明文存储
- ✅ 密钥永不在应用层暴露
- ✅ Agent内存最小化持有时间
- ✅ 端到端加密传输

---

## 六、监控与运维

### 6.1 Agent健康检查

```cpp
// 建议实现健康检查接口
// GET http://localhost:<PORT>/health
{
  "status": "ok",
  "ecal_connected": true,
  "devices_online": 2,
  "version": "0.1.0"
}
```

### 6.2 日志配置

```
日志路径: %APPDATA%\OpenClaw\logs\agent.log
日志级别: INFO (生产) / DEBUG (开发)
日志轮转: 按日轮转，保留7天
```

### 6.3 关键监控指标

| 指标 | 说明 | 告警阈值 |
|------|------|---------|
| `ecal_connected` | eCAL连接状态 | 断开告警 |
| `devices_online` | 在线设备数 | =0告警 |
| `credential_requests` | 凭证请求次数 | 异常频率告警 |
| `auth_failures` | 授权失败次数 | >5次/分钟告警 |
| `memory_usage` | Agent内存占用 | >100MB告警 |

---

## 七、开发路线图理解

### 阶段一：基础通信与安全 (当前)
**目标**：搭建eCAL环境，实现基本存储

**DevOps任务**：
- [x] protoc安装配置
- [x] C++ Agent项目骨架
- [ ] eCAL集成测试
- [ ] Flutter项目CI配置

### 阶段二：远程授信核心
**目标**：完整登录授权流程

**DevOps任务**：
- [ ] 浏览器扩展打包流程
- [ ] Native Messaging注册脚本
- [ ] Windows安装包制作

### 阶段三：能力虚拟化
**目标**：设备发现与同步

**DevOps任务**：
- [ ] 多设备测试环境
- [ ] 同步服务部署

### 阶段四：嵌入式支持
**目标**：安全芯片集成

### 阶段五：鸿蒙原生适配
**目标**：HUKS + 分布式软总线

---

## 八、疑问与讨论点

### 8.1 待确认的技术问题

1. **eCAL跨公网通信**
   - 文档提到TCP模式，但NAT穿透如何实现？
   - 是否需要STUN/TURN服务器？

2. **多客户端冲突**
   - 手机+电脑同时在线时，请求发给哪个？
   - 是否需要优先级策略？

3. **离线场景**
   - 所有设备离线时，OpenClaw如何处理？
   - 是否需要"紧急凭证"机制？

### 8.2 运维相关建议

1. **建议增加配置文件**
   ```ini
   # openclaw-agent.ini
   [general]
   log_level = info
   log_path = %APPDATA%/OpenClaw/logs

   [ecal]
   tcp_enabled = true
   discovery_timeout = 30

   [security]
   require_biometric = true
   session_timeout = 300
   ```

2. **建议增加CLI管理工具**
   ```bash
   openclaw-agent status
   openclaw-agent devices
   openclaw-agent logs --tail 100
   ```

---

## 九、我的角色定位

作为DevOps工程师，我主要负责：

1. **构建系统**：CMake配置、CI/CD流水线
2. **打包发布**：各平台安装包制作
3. **部署脚本**：安装、升级、卸载脚本
4. **监控告警**：Agent健康检查、日志分析
5. **安全配置**：Native Messaging注册、权限配置

---

*文档创建: 2026-03-13*
*作者: devops-engineer*