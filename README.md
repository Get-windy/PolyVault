# PolyVault - OpenClaw远程多源授信客户端

基于 eCAL + zk_vault 的跨平台、硬件级安全、去中心化远程授信系统。

## 核心目标

- **远程授信**：OpenClaw服务器需要登录第三方服务时，实时向用户客户端请求凭证，服务器端不存储任何明文敏感信息
- **硬件级安全**：所有凭证在客户端由安全硬件（TEE/Secure Enclave/TPM）保护
- **去中心化通信**：客户端与OpenClaw之间通过eCAL的P2P加密通道直接通信
- **跨平台覆盖**：iOS/Android/Windows/macOS/Linux/嵌入式
- **鸿蒙优先**：底层架构借鉴鸿蒙的分布式软总线、HUKS设计

## 技术栈

| 层级 | 技术选型 |
|------|----------|
| 通信层 | **eCAL** (共享内存/UDP/TCP自动切换) |
| 安全层 | **zk_vault** + 各平台原生Keystore |
| 客户端 | **Flutter** + Dart FFI |
| 本地Agent | **C++/Rust** + eCAL |
| 浏览器扩展 | **Manifest V3** + Native Messaging |
| 序列化 | **Protobuf** |

## 核心组件

1. **eCAL通信层** - 自动传输选择、brokerless架构、零配置发现
2. **zk_vault安全层** - AES-256-GCM加密、硬件KMS集成、生物认证
3. **Flutter客户端** - 跨平台UI + eCAL C API调用
4. **本地Agent** - Native Messaging + eCAL服务端
5. **浏览器扩展** - 自动填充凭证

## 开发路线图

### 阶段一：基础通信与安全（1-2个月）
- 搭建eCAL环境
- Flutter集成zk_vault
- FFI调用eCAL C API

### 阶段二：远程授信核心（2-3个月）
- Protobuf协议定义
- 浏览器扩展开发
- 完整登录授权流程

### 阶段三：能力虚拟化与分布式数据（2个月）
- eCAL Service设备能力发现
- 凭证跨设备同步

### 阶段四：嵌入式支持（2-3个月）
- eCAL核心裁剪
- 安全芯片集成

### 阶段五：鸿蒙原生适配（2个月）
- HUKS和分布式软总线集成

---

*创建时间: 2026-03-13*
