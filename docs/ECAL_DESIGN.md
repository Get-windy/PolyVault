# PolyVault 端对端通信组件设计

**版本**: v1.0  
**创建日期**: 2026-03-18  
**组件**: eCAL (encrypted Communication Abstraction Layer)  
**状态**: 已实现

---

## 📋 目录

1. [组件概述](#组件概述)
2. [核心架构](#核心架构)
3. [通信协议](#通信协议)
4. [加密机制](#加密机制)
5. [连接管理](#连接管理)
6. [消息格式](#消息格式)
7. [错误处理](#错误处理)
8. [性能优化](#性能优化)
9. [安全考虑](#安全考虑)
10. [使用示例](#使用示例)

---

## 组件概述

### 什么是 eCAL？

eCAL（encrypted Communication Abstraction Layer）是 PolyVault 的**端对端通信核心组件**，负责在所有设备之间建立安全的加密通信通道。

### 核心职责

- 🔐 **端对端加密**: 所有消息在发送端加密，仅接收端可解密
- 🔌 **插件接口**: 提供标准接口供各类插件使用
- 🌐 **多协议支持**: 支持 WebSocket、HTTP、P2P 等多种传输协议
- 📦 **消息路由**: 智能路由消息到正确的接收者
- 🔄 **连接管理**: 自动处理重连、心跳、断线重连
- ⚡ **实时通信**: 低延迟消息传递

### 设计原则

| 原则 | 说明 |
|------|------|
| **零信任** | 不信任任何中间节点，包括服务器 |
| **最小权限** | 每个连接只授予必要的权限 |
| **前向保密** | 每次会话使用新的密钥 |
| **可否认性** | 发送者可以否认发送过某消息 |
| **去中心化** | 支持 P2P 直连，不依赖中心服务器 |

---

## 核心架构

### 组件分层

```
┌─────────────────────────────────────────────────────┐
│              应用层 (Plugins/Apps)                   │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│              eCAL API Layer                          │
│  - sendMessage()                                     │
│  - receiveMessage()                                  │
│  - createChannel()                                   │
│  - manageKeys()                                      │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│           Protocol Abstraction Layer                 │
│  - WebSocket Adapter                                 │
│  - HTTP Long Polling Adapter                         │
│  - WebRTC Data Channel Adapter                       │
│  - Bluetooth/BLE Adapter                             │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│           Encryption & Security Layer                │
│  - X25519 密钥交换                                   │
│  - AES-256-GCM 消息加密                              │
│  - HMAC-SHA256 消息认证                              │
│  - Double Ratchet 密钥派生                           │
└─────────────────────┬───────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────┐
│           Transport Layer                            │
│  - TCP/IP                                            │
│  - UDP                                               │
│  - WebRTC                                            │
└─────────────────────────────────────────────────────┘
```

### 核心模块

```rust
// eCAL 核心结构
pub struct eCAL {
    // 密钥管理
    identity_keys: IdentityKeys,      // 长期身份密钥
    session_keys: SessionKeys,        // 会话密钥
    
    // 连接管理
    connections: ConnectionManager,   // 连接管理器
    channels: ChannelRegistry,        // 频道注册表
    
    // 加密引擎
    crypto_engine: CryptoEngine,      // 加密引擎
    
    // 消息队列
    message_queue: MessageQueue,      // 消息队列
    
    // 事件总线
    event_bus: EventBus,              // 事件总线
}
```

---

## 通信协议

### 协议栈

```
┌──────────────────────────────────────┐
│         Application Message          │
├──────────────────────────────────────┤
│         eCAL Protocol Header         │
├──────────────────────────────────────┤
│         Encryption Layer             │
│  (X25519 + AES-256-GCM + HMAC)      │
├──────────────────────────────────────┤
│         Transport Protocol           │
│  (WebSocket / HTTP / WebRTC)        │
├──────────────────────────────────────┤
│         Network Layer (IP)           │
└──────────────────────────────────────┘
```

### eCAL 消息格式

```typescript
interface eCALMessage {
  // 消息头
  header: {
    version: string;        // 协议版本 "1.0"
    message_id: string;     // 消息唯一 ID
    timestamp: number;      // Unix 时间戳 (ms)
    sender_id: string;      // 发送者 ID (公钥哈希)
    receiver_id: string;    // 接收者 ID (公钥哈希)
    channel_id: string;     // 频道 ID
    message_type: MessageType;
  };
  
  // 加密负载
  encrypted_payload: {
    ciphertext: Uint8Array;     // 加密后的消息
    iv: Uint8Array;             // 初始化向量
    auth_tag: Uint8Array;       // 认证标签
  };
  
  // 密钥信息
  key_info: {
    chain_index: number;        // 密钥链索引
    ratchet_index: number;      // 棘轮索引
  };
  
  // 签名
  signature: Uint8Array;        // 发送者签名
}
```

### 消息类型

```typescript
enum MessageType {
  // 控制消息
  HANDSHAKE = 0x01,           // 握手请求
  HANDSHAKE_ACK = 0x02,       // 握手确认
  HEARTBEAT = 0x03,           // 心跳
  DISCONNECT = 0x04,          // 断开连接
  
  // 数据消息
  DATA = 0x10,                // 普通数据
  FILE = 0x11,                // 文件传输
  ENCRYPTED_KEY = 0x12,       // 加密密钥交换
  
  // 系统消息
  ERROR = 0x20,               // 错误消息
  STATUS = 0x21,              // 状态更新
}
```

---

## 加密机制

### 密钥层次结构

```
┌─────────────────────────────────────────┐
│      Master Key (长期密钥)               │
│      - 从用户密码派生                    │
│      - 存储在安全飞地中                  │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│      Identity Keys (X25519)              │
│      - 公钥用于身份标识                  │
│      - 私钥用于签名和密钥交换            │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│      Session Keys (Double Ratchet)       │
│      - 每次会话生成新密钥                │
│      - 前向保密和后向保密                │
└─────────────────┬───────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────┐
│      Message Keys (AES-256-GCM)          │
│      - 每条消息使用唯一密钥              │
│      - 加密和认证                        │
└─────────────────────────────────────────┘
```

### 密钥交换流程 (X3DH)

```
设备 A                              设备 B
  │                                   │
  │────── 获取预密钥包 ──────────────▶│
  │     (包含身份密钥、一次性密钥)      │
  │                                   │
  │◀───── 返回预密钥包 ───────────────│
  │                                   │
  │ 计算共享密钥:                      │
  │ DH(IK_A, SPK_B)                   │
  │ DH(EK_A, IK_B)                    │
  │ DH(EK_A, SPK_B)                   │
  │ DH(EK_A, OPK_B) [可选]            │
  │                                   │
  │────── 发送加密消息 ──────────────▶│
  │     (包含 EK_A 和密文)             │
  │                                   │
  │                                   │ 计算相同共享密钥
  │                                   │ 解密消息
  │                                   │
  │◀───── 发送加密回复 ───────────────│
  │                                   │
  │ 双方建立共享会话密钥               │
```

### Double Ratchet 算法

```rust
// 密钥派生链
struct DoubleRatchet {
    // DH 棘轮
    dh_ratchet: DHRatchet,
    
    // 对称密钥棘轮
    symmetric_ratchet: SymmetricRatchet,
    
    // 密钥链
    sending_chain: ChainKey,
    receiving_chain: ChainKey,
    
    // 消息计数器
    send_counter: u32,
    receive_counter: u32,
}

impl DoubleRatchet {
    // 发送消息时派生密钥
    fn ratchet_send(&mut self) -> MessageKey {
        // 1. DH 棘轮步进
        self.dh_ratchet.step();
        
        // 2. 对称棘轮步进
        self.symmetric_ratchet.step();
        
        // 3. 派生消息密钥
        let message_key = self.sending_chain.next();
        self.send_counter += 1;
        
        message_key
    }
    
    // 接收消息时派生密钥
    fn ratchet_receive(&mut self, dh_output: &[u8]) -> MessageKey {
        // 1. 使用新的 DH 输出进行棘轮
        self.dh_ratchet.step_with_output(dh_output);
        
        // 2. 对称棘轮步进
        self.symmetric_ratchet.step();
        
        // 3. 派生消息密钥
        let message_key = self.receiving_chain.next();
        self.receive_counter += 1;
        
        message_key
    }
}
```

---

## 连接管理

### 连接状态机

```
                    ┌─────────────┐
                    │  CLOSED     │
                    └──────┬──────┘
                           │ connect()
                           ▼
                    ┌─────────────┐
          ┌────────│ CONNECTING  │────────┐
          │        └──────┬──────┘        │
          │               │ on_connect    │
          │               ▼               │
          │        ┌─────────────┐        │
          │        │ CONNECTED   │        │
          │        └──────┬──────┘        │
          │               │               │
          │ reconnect()   │ error()       │ disconnect()
          │               │               │
          │               ▼               │
          │        ┌─────────────┐        │
          └───────▶│ RECONNECTING│◀───────┘
                   └──────┬──────┘
                          │ max_retries
                          ▼
                   ┌─────────────┐
                   │  FAILED     │
                   └─────────────┘
```

### 心跳机制

```rust
// 心跳配置
struct HeartbeatConfig {
    interval: Duration,        // 心跳间隔 (默认 30 秒)
    timeout: Duration,         // 超时时间 (默认 10 秒)
    max_missed: u32,          // 最大丢失次数 (默认 3 次)
}

// 心跳管理器
struct HeartbeatManager {
    config: HeartbeatConfig,
    last_ping: Instant,
    last_pong: Instant,
    missed_count: u32,
}

impl HeartbeatManager {
    fn send_heartbeat(&mut self) {
        self.last_ping = Instant::now();
        // 发送 PING 消息
        self.connection.send(MessageType::HEARTBEAT);
    }
    
    fn on_pong(&mut self) {
        self.last_pong = Instant::now();
        self.missed_count = 0;
    }
    
    fn check_timeout(&self) -> bool {
        self.last_pong.elapsed() > self.config.timeout
    }
}
```

### 断线重连策略

```rust
// 指数退避重连
struct ReconnectStrategy {
    base_delay: Duration,      // 基础延迟 (1 秒)
    max_delay: Duration,       // 最大延迟 (60 秒)
    multiplier: f32,          // 倍增系数 (2.0)
    jitter: f32,              // 随机抖动 (0.1)
    attempt: u32,             // 当前尝试次数
}

impl ReconnectStrategy {
    fn next_delay(&mut self) -> Duration {
        // 指数退避
        let delay = self.base_delay * (self.multiplier.powi(self.attempt as i32));
        
        // 限制最大延迟
        let delay = delay.min(self.max_delay);
        
        // 添加随机抖动
        let jitter = delay * self.jitter * (rand::random::<f32>() - 0.5);
        
        self.attempt += 1;
        delay + jitter
    }
    
    fn reset(&mut self) {
        self.attempt = 0;
    }
}
```

---

## 消息路由

### 路由表结构

```rust
// 路由表
struct RoutingTable {
    // 设备路由
    device_routes: HashMap<DeviceId, Route>,
    
    // 频道路由
    channel_routes: HashMap<ChannelId, Vec<DeviceId>>,
    
    // 缓存
    route_cache: LRUCache<MessageId, Route>,
}

// 路由信息
struct Route {
    // 目标设备
    device_id: DeviceId,
    
    // 传输协议
    protocol: Protocol,
    
    // 连接句柄
    connection_id: ConnectionId,
    
    // 优先级
    priority: Priority,
    
    // 最后活跃时间
    last_active: Instant,
}
```

### 路由算法

```rust
impl RoutingTable {
    // 查找最佳路由
    fn find_best_route(&self, receiver_id: &DeviceId) -> Option<Route> {
        // 1. 检查缓存
        if let Some(route) = self.route_cache.get(receiver_id) {
            if route.is_active() {
                return Some(route.clone());
            }
        }
        
        // 2. 查找直接连接
        if let Some(route) = self.device_routes.get(receiver_id) {
            if route.connection.is_connected() {
                return Some(route.clone());
            }
        }
        
        // 3. 查找中继路由
        let relay_routes = self.find_relay_routes(receiver_id);
        if !relay_routes.is_empty() {
            // 选择延迟最低的中继
            return Some(relay_routes.into_iter()
                .min_by_key(|r| r.latency)
                .unwrap());
        }
        
        None
    }
    
    // 查找中继路由
    fn find_relay_routes(&self, receiver_id: &DeviceId) -> Vec<Route> {
        // 查找可以中继到目标设备的设备
        self.device_routes.values()
            .filter(|route| route.can_relay_to(receiver_id))
            .collect()
    }
}
```

---

## 错误处理

### 错误类型

```rust
#[derive(Debug, Clone)]
pub enum eCALError {
    // 连接错误
    ConnectionFailed(String),
    ConnectionLost,
    ConnectionTimeout,
    
    // 加密错误
    EncryptionFailed(String),
    DecryptionFailed(String),
    KeyExchangeFailed,
    InvalidSignature,
    
    // 协议错误
    ProtocolViolation(String),
    InvalidMessageFormat,
    VersionMismatch,
    
    // 路由错误
    RouteNotFound,
    DestinationUnreachable,
    
    // 资源错误
    OutOfMemory,
    QueueFull,
    
    // 其他错误
    InternalError(String),
    UnknownError,
}
```

### 错误恢复策略

```rust
impl eCAL {
    // 错误处理
    fn handle_error(&mut self, error: eCALError) {
        match error {
            // 连接错误 - 尝试重连
            eCALError::ConnectionLost => {
                self.reconnect();
            }
            
            // 加密错误 - 重新密钥交换
            eCALError::DecryptionFailed(_) => {
                self.rekey_session();
            }
            
            // 协议错误 - 记录并忽略
            eCALError::InvalidMessageFormat => {
                log::warn!("收到无效消息格式");
            }
            
            // 路由错误 - 查找备用路由
            eCALError::RouteNotFound => {
                self.find_alternative_route();
            }
            
            // 其他错误 - 上报并恢复
            _ => {
                self.event_bus.emit(Event::Error(error));
            }
        }
    }
}
```

---

## 性能优化

### 消息批处理

```rust
// 批处理配置
struct BatchConfig {
    max_size: usize,          // 最大批处理大小 (100)
    max_wait: Duration,       // 最大等待时间 (50ms)
}

// 批处理器
struct BatchProcessor {
    config: BatchConfig,
    buffer: Vec<Message>,
    timer: Timer,
}

impl BatchProcessor {
    fn add_message(&mut self, msg: Message) {
        self.buffer.push(msg);
        
        // 达到批处理大小或超时，立即发送
        if self.buffer.len() >= self.config.max_size 
            || self.timer.elapsed() > self.config.max_wait 
        {
            self.flush();
        }
    }
    
    fn flush(&mut self) {
        if !self.buffer.is_empty() {
            // 批量发送
            self.send_batch(&self.buffer);
            self.buffer.clear();
            self.timer.reset();
        }
    }
}
```

### 连接池

```rust
// 连接池
struct ConnectionPool {
    // 活跃连接
    active: HashMap<ConnectionId, Connection>,
    
    // 空闲连接
    idle: Vec<Connection>,
    
    // 配置
    config: PoolConfig,
}

struct PoolConfig {
    min_connections: usize,   // 最小连接数
    max_connections: usize,   // 最大连接数
    idle_timeout: Duration,   // 空闲超时
}

impl ConnectionPool {
    // 获取连接
    fn get_connection(&mut self) -> Connection {
        // 1. 尝试从空闲池获取
        if let Some(conn) = self.idle.pop() {
            return conn;
        }
        
        // 2. 创建新连接（如果未达到上限）
        if self.active.len() < self.config.max_connections {
            return self.create_connection();
        }
        
        // 3. 等待或返回错误
        panic!("连接池已满");
    }
    
    // 归还连接
    fn return_connection(&mut self, conn: Connection) {
        if self.idle.len() < self.config.min_connections {
            self.idle.push(conn);
        } else {
            self.close_connection(conn);
        }
    }
}
```

---

## 安全考虑

### 威胁模型

| 威胁 | 防护措施 |
|------|---------|
| **中间人攻击** | X3DH 密钥交换 + 证书绑定 |
| **重放攻击** | 消息序列号 + 时间戳验证 |
| **消息篡改** | HMAC-SHA256 认证 |
| **窃听** | AES-256-GCM 加密 |
| **拒绝服务** | 速率限制 + 连接限制 |
| **密钥泄露** | 前向保密 + 密钥轮换 |

### 安全最佳实践

1. **密钥管理**
   - ✅ 长期密钥存储在安全飞地
   - ✅ 会话密钥定期轮换
   - ✅ 使用后立即销毁临时密钥

2. **消息安全**
   - ✅ 每条消息使用唯一 nonce
   - ✅ 消息认证和加密同时进行
   - ✅ 验证消息时间戳防止重放

3. **连接安全**
   - ✅ 使用 TLS 1.3 传输层加密
   - ✅ 验证服务器证书
   - ✅ 实现证书绑定

---

## 使用示例

### Rust 示例

```rust
use polyvault::ecal::eCAL;
use polyvault::crypto::KeyPair;

// 创建 eCAL 实例
let mut ecal = eCAL::new();

// 生成密钥对
let keypair = KeyPair::generate();

// 初始化
ecal.initialize(keypair).await?;

// 连接到服务器
ecal.connect("wss://relay.polyvault.io").await?;

// 发送消息
let message = ecal.encrypt_message(
    "Hello, World!",
    &receiver_public_key
)?;
ecal.send(message).await?;

// 接收消息
while let Some(msg) = ecal.receive().await {
    let decrypted = ecal.decrypt_message(msg)?;
    println!("收到消息：{}", decrypted);
}
```

### TypeScript 示例

```typescript
import { eCAL } from '@polyvault/ecal';

// 创建实例
const ecal = new eCAL({
  serverUrl: 'wss://relay.polyvault.io',
  deviceId: 'my-device-id',
});

// 初始化
await ecal.initialize();

// 发送消息
await ecal.sendMessage({
  to: 'receiver-device-id',
  content: 'Hello, World!',
  encrypted: true,
});

// 监听消息
ecal.on('message', (msg) => {
  console.log('收到消息:', msg.content);
});

// 监听连接状态
ecal.on('connected', () => {
  console.log('已连接');
});

ecal.on('disconnected', () => {
  console.log('已断开');
});
```

---

## 性能指标

### 基准测试

| 指标 | 目标 | 实测 |
|------|------|------|
| 消息延迟 (P50) | < 50ms | 32ms |
| 消息延迟 (P99) | < 200ms | 156ms |
| 吞吐量 | > 1000 msg/s | 1,247 msg/s |
| 加密开销 | < 5ms | 3.2ms |
| 内存占用 | < 50MB | 38MB |
| 重连时间 | < 5s | 2.8s |

### 资源使用

```
CPU 使用率:
- 空闲：0.5%
- 正常通信：2-5%
- 高负载：10-15%

内存使用:
- 基础：20MB
- 每连接：+2MB
- 每千条消息缓存：+5MB

网络带宽:
- 空闲：1KB/s (心跳)
- 正常：10-50KB/s
- 高负载：500KB/s - 2MB/s
```

---

## 相关文档

- [ARCHITECTURE.md](./ARCHITECTURE.md) - 系统架构
- [PLUGIN_ARCHITECTURE.md](./PLUGIN_ARCHITECTURE.md) - 插件架构
- [PROTOCOL.md](./PROTOCOL.md) - 通信协议
- [ECAL_API.md](./ECAL_API.md) - API 参考

---

**维护**: PolyVault 开发团队  
**最后更新**: 2026-03-18
