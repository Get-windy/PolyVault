# PolyVault C++ eCAL 通信层 API 文档

## 概述

PolyVault Agent 使用 eCAL (Enterprise Communication Abstraction Layer) 实现跨进程通信。本文档介绍数据总线、eCAL通信层和Protobuf消息的API使用方法。

## 目录

1. [快速开始](#快速开始)
2. [数据总线 (Data Bus)](#数据总线-data-bus)
3. [eCAL通信层](#ecal通信层)
4. [Protobuf消息](#protobuf消息)
5. [示例代码](#示例代码)
6. [编译指南](#编译指南)

---

## 快速开始

### 基本使用流程

```cpp
#include "data_bus.hpp"
#include "ecal_communication.hpp"

using namespace polyvault::bus;
using namespace polyvault::ecal;

// 1. 配置数据总线
DataBusConfig config;
config.bus_name = "PolyVaultBus";
config.node_id = "agent_001";
config.use_ecal = true;

// 2. 创建并初始化
DataBus bus(config);
bus.initialize();
bus.start();

// 3. 订阅消息
bus.subscribe("credential/request", [](const Message& msg) {
    std::cout << "Received: " << msg.topic << std::endl;
});

// 4. 发布消息
Message msg;
msg.topic = "credential/request";
bus.publish("credential/request", msg);

// 5. 清理
bus.stop();
```

---

## 数据总线 (Data Bus)

### DataBusConfig - 配置结构

```cpp
struct DataBusConfig {
    std::string bus_name = "PolyVaultBus";      // 总线名称
    std::string node_id;                         // 本节点ID
    bool use_ecal = false;                       // 是否使用eCAL
    bool enable_monitoring = true;               // 启用监控
    int worker_threads = 2;                      // 工作线程数
    int queue_size = 1000;                       // 队列大小
    int heartbeat_interval_ms = 30000;           // 心跳间隔
    int connection_timeout_ms = 60000;           // 连接超时
    int max_retries = 3;                         // 最大重试次数
};
```

### DataBus - 核心类

#### 生命周期

```cpp
// 构造函数
explicit DataBus(const DataBusConfig& config = {});

// 初始化（必须先调用）
bool initialize();

// 启动（创建工作线程）
void start();

// 停止
void stop();

// 检查运行状态
bool isRunning() const;
```

#### 发布/订阅

```cpp
// 订阅主题，返回订阅者ID
std::string subscribe(const std::string& topic, MessageCallback callback);

// 取消订阅
bool unsubscribe(const std::string& subscriber_id);

// 发布消息（同步）
bool publish(const std::string& topic, const Message& message);

// 发布消息（异步，加入队列）
bool publishAsync(const std::string& topic, const Message& message);
```

#### 请求/响应

```cpp
// 发送请求并等待响应
std::optional<Message> request(const std::string& target, 
                                const Message& request_msg, 
                                int timeout_ms = 5000);

// 发送响应
void respond(const std::string& target, const Message& response);
```

#### 消息处理器

```cpp
// 注册消息类型处理器
void registerHandler(MessageKind kind, MessageCallback callback);

// 注销消息类型处理器
void unregisterHandler(MessageKind kind);
```

#### 连接管理

```cpp
// 连接到端点
std::string connect(const std::string& endpoint);

// 断开连接
bool disconnect(const std::string& connection_id);

// 获取连接状态
ConnectionState getConnectionState(const std::string& connection_id) const;

// 获取所有连接
std::vector<ConnectionInfo> getConnections() const;
```

#### 监控

```cpp
// 设置连接状态回调
void setConnectionCallback(ConnectionCallback callback);

// 获取统计
uint64_t getMessagesSent() const;
uint64_t getMessagesReceived() const;
uint64_t getQueueSize() const;

// 心跳控制
void startHeartbeat();
void stopHeartbeat();
```

---

## Message - 消息结构

### 消息字段

```cpp
struct Message {
    std::string message_id;           // 消息唯一ID
    MessageKind kind;                 // 消息类型
    MessagePriority priority;         // 优先级
    std::string source_id;            // 源ID
    std::string target_id;            // 目标ID
    std::string topic;                // 主题
    std::vector<uint8_t> payload;     // 载荷（Protobuf序列化数据）
    uint64_t timestamp;               // 时间戳
    uint32_t timeout_ms;              // 超时时间
    int retry_count;                  // 重试次数
};
```

### MessageKind - 消息类型枚举

```cpp
enum class MessageKind : uint8_t {
    CREDENTIAL_REQUEST = 1,      // 凭证请求
    CREDENTIAL_RESPONSE = 2,     // 凭证响应
    COOKIE_UPLOAD = 3,           // Cookie上传
    COOKIE_DOWNLOAD = 4,         // Cookie下载
    DEVICE_REGISTER = 5,         // 设备注册
    DEVICE_HEARTBEAT = 6,        // 设备心跳
    AUTHORIZATION_REQUEST = 7,   // 授权请求
    SYNC_REQUEST = 8,           // 同步请求
    EVENT = 9,                   // 事件
    CONTROL = 10,                // 控制消息
    HEALTH_CHECK = 11            // 健康检查
};
```

### MessagePriority - 消息优先级

```cpp
enum class MessagePriority : uint8_t {
    LOW = 0,       // 低优先级
    NORMAL = 1,   // 正常优先级
    HIGH = 2,     // 高优先级
    CRITICAL = 3  // 紧急优先级
};
```

### ConnectionState - 连接状态

```cpp
enum class ConnectionState : uint8_t {
    DISCONNECTED = 0,  // 未连接
    CONNECTING = 1,    // 连接中
    CONNECTED = 2,      // 已连接
    ERROR = 3          // 错误
};
```

---

## MessageBuilder - 消息构建器

```cpp
// 创建CredentialRequest消息
auto msg = MessageBuilder()
    .setKind(MessageKind::CREDENTIAL_REQUEST)
    .setPriority(MessagePriority::HIGH)
    .setSource("client_001")
    .setTarget("agent_001")
    .setTopic("credential/request")
    .setPayload(payload_data)
    .setTimeout(5000)
    .build();
```

---

## ProtobufSerializer - Protobuf序列化

```cpp
using namespace polyvault::bus;

// 序列化Protobuf消息到字节向量
std::vector<uint8_t> bytes = ProtobufSerializer::serialize(protobuf_msg);

// 从字节向量反序列化
ProtobufSerializer::deserialize(bytes, protobuf_msg);

// 从Message payload提取特定类型
openclaw::CredentialRequest req;
ProtobufSerializer::extractCredentialRequest(msg, req);

openclaw::Event event;
ProtobufSerializer::extractEvent(msg, event);
```

---

## 便捷函数

### createCredentialRequest

```cpp
// 创建凭证请求消息
Message createCredentialRequest(const std::string& service_url,
                                const std::string& service_name,
                                int credential_type);
```

### createCredentialResponse

```cpp
// 创建凭证响应消息
Message createCredentialResponse(const std::string& request_id,
                                 bool success,
                                 const std::string& encrypted_credential,
                                 const std::string& error_message = "");
```

### createEventMessage

```cpp
// 创建事件消息
Message createEventMessage(const std::string& device_id,
                           openclaw::EventType event_type,
                           const std::string& message);
```

### createHeartbeatMessage

```cpp
// 创建心跳消息
Message createHeartbeatMessage(const std::string& device_id,
                                const std::map<std::string, std::string>& status = {});
```

---

## eCAL通信层

### EcalInitializer - eCAL初始化器

```cpp
using namespace polyvault::ecal;

// 获取单例
EcalInitializer& init = EcalInitializer::instance();

// 初始化
EcalConfig config;
config.app_name = "PolyVault";
config.unit_name = "agent";
config.enable_monitoring = true;
config.timeout_ms = 5000;

init.initialize(config);

// 检查状态
if (init.isInitialized()) {
    std::cout << "eCAL initialized" << std::endl;
}

// 关闭
init.finalize();
```

### 发布者

#### CredentialResponsePublisher

```cpp
CredentialResponsePublisher publisher("polyvault/credential_response");

openclaw::CredentialResponse response;
response.set_request_id("req_001");
response.set_status(openclaw::AUTH_STATUS_APPROVED);

publisher.publish(response);
```

#### CookieUploadPublisher

```cpp
CookieUploadPublisher publisher("polyvault/cookie_upload");

openclaw::CookieUploadRequest request;
request.set_request_id("cookie_001");
request.set_service_url("https://example.com");

publisher.publish(request);
```

#### EventPublisher

```cpp
EventPublisher publisher("polyvault/events");

publisher.publishEvent(openclaw::EVENT_DEVICE_CONNECTED, 
                       "device_001", 
                       "Device connected");
```

### 订阅者

#### CredentialRequestSubscriber

```cpp
CredentialRequestSubscriber subscriber("polyvault/credential_request");

subscriber.setCallback([](const openclaw::CredentialRequest& request) {
    std::cout << "Service: " << request.service_url() << std::endl;
    
    openclaw::CredentialResponse response;
    response.set_request_id(request.request_id());
    response.set_status(openclaw::AUTH_STATUS_APPROVED);
    // ...
    return response;
});
```

### RPC服务

#### CredentialServer (服务端)

```cpp
CredentialServer server("polyvault_credential_service");

server.setCredentialCallback([](const openclaw::CredentialRequest& request) {
    openclaw::CredentialResponse response;
    response.set_request_id(request.request_id());
    response.set_status(openclaw::AUTH_STATUS_APPROVED);
    response.set_encrypted_credential("encrypted_token");
    return response;
});

server.setCookieCallback([](const openclaw::CookieDownloadRequest& request) {
    openclaw::CookieDownloadResponse response;
    response.set_success(true);
    return response;
});

// 保持运行
while (running) {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
}
```

#### CredentialClient (客户端)

```cpp
CredentialClient client("polyvault_credential_service");

// 请求凭证
openclaw::CredentialRequest request;
request.set_request_id("req_001");
request.set_service_url("https://github.com");
request.set_service_name("GitHub");

openclaw::CredentialResponse response;
bool success = client.getCredential(request, response, 5000);

if (success) {
    std::cout << "Status: " << response.status() << std::endl;
}

// 下载Cookie
openclaw::CookieDownloadRequest cookie_req;
cookie_req.set_service_url("https://example.com");
cookie_req.set_device_id("device_001");

openclaw::CookieDownloadResponse cookie_resp;
client.downloadCookie(cookie_req, cookie_resp, 5000);
```

---

## 示例代码

### 示例1: 简单的发布/订阅

```cpp
#include "data_bus.hpp"
#include <iostream>

using namespace polyvault::bus;

int main() {
    DataBus bus;
    bus.initialize();
    bus.start();
    
    // 订阅
    bus.subscribe("test/topic", [](const Message& msg) {
        std::cout << "Received: " << msg.topic << std::endl;
    });
    
    // 发布
    Message msg;
    msg.topic = "test/topic";
    bus.publish("test/topic", msg);
    
    std::this_thread::sleep_for(std::chrono::seconds(1));
    bus.stop();
    
    return 0;
}
```

### 示例2: RPC调用

```cpp
// 服务端
void runServer() {
    CredentialServer server("my_service");
    
    server.setCredentialCallback([](const openclaw::CredentialRequest& req) {
        openclaw::CredentialResponse resp;
        resp.set_request_id(req.request_id());
        resp.set_status(openclaw::AUTH_STATUS_APPROVED);
        resp.set_encrypted_credential("TOKEN_DATA");
        return resp;
    });
    
    while (running) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

// 客户端
void runClient() {
    CredentialClient client("my_service");
    
    openclaw::CredentialRequest req;
    req.set_request_id("req_001");
    req.set_service_url("https://example.com");
    
    openclaw::CredentialResponse resp;
    if (client.getCredential(req, resp, 5000)) {
        std::cout << "Got response: " << resp.status() << std::endl;
    }
}
```

### 示例3: 消息类型处理

```cpp
// 注册多种消息类型处理器
bus.registerHandler(MessageKind::CREDENTIAL_REQUEST, 
    [](const Message& msg) {
        openclaw::CredentialRequest req;
        if (ProtobufSerializer::extractCredentialRequest(msg, req)) {
            std::cout << "Credential request for: " << req.service_url() << std::endl;
        }
    });

bus.registerHandler(MessageKind::EVENT,
    [](const Message& msg) {
        openclaw::Event event;
        if (ProtobufSerializer::extractEvent(msg, event)) {
            std::cout << "Event: " << event.message() << std::endl;
        }
    });
```

---

## 编译指南

### CMake配置

```bash
# 进入构建目录
cd src/agent/build

# 配置（启用eCAL）
cmake .. -DUSE_ECAL=ON -DBUILD_TESTS=ON

# 或禁用eCAL（简化模式）
cmake .. -DUSE_ECAL=OFF -DBUILD_TESTS=ON

# 编译
cmake --build . --config Release
```

### 依赖项

- C++17 编译器
- CMake 3.16+
- Protobuf 3+
- eCAL (可选，用于跨进程通信)

### 测试

```bash
# 运行数据总线测试
./test_data_bus

# 运行eCAL集成测试
./test_ecal_integration test      # 运行所有测试
./test_ecal_integration server     # 运行服务端
./test_ecal_integration client     # 运行客户端
./test_ecal_integration pubsub     # 测试发布/订阅
./test_ecal_integration rpc        # 测试RPC
```

---

## 故障排除

### eCAL未初始化

```
[ERROR] Failed to initialize eCAL
```

**解决方案**: 确保eCAL已正确安装，或者使用 `-DUSE_ECAL=OFF` 编译

### 连接超时

```
[Client] Request failed: timeout or error
```

**解决方案**: 
1. 检查服务端是否运行
2. 增加超时时间: `client.getCredential(req, resp, 10000)`
3. 检查防火墙设置

### 消息队列满

```
[DataBus] Queue full, message dropped
```

**解决方案**: 
1. 增加队列大小: `config.queue_size = 2000`
2. 检查消费者是否正常工作

---

## 版本信息

- **版本**: 0.1.0
- **日期**: 2026-03-14
- **依赖**: C++17, Protobuf, eCAL (可选)