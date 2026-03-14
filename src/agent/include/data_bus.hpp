/**
 * @file data_bus.hpp
 * @brief PolyVault数据总线 - 消息路由与通信中枢
 * 
 * 功能：
 * - 统一消息路由
 * - 主题订阅管理
 * - 连接状态监控
 * - 消息队列与可靠性保证
 */

#pragma once

#include <string>
#include <memory>
#include <functional>
#include <mutex>
#include <map>
#include <atomic>
#include <queue>
#include <thread>
#include <chrono>
#include <optional>
#include <variant>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <future>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#include <ecal/msg/protobuf/publisher.h>
#include <ecal/msg/protobuf/subscriber.h>
#endif

#include "openclaw.pb.h"

namespace polyvault {
namespace bus {

// ============================================================================
// 前向声明
// ============================================================================

class DataBus;
class Connection;
struct DataBus::PendingResponse;

/**
 * @brief 消息优先级
 */
enum class MessagePriority : uint8_t {
    LOW = 0,
    NORMAL = 1,
    HIGH = 2,
    CRITICAL = 3
};

/**
 * @brief 连接状态
 */
enum class ConnectionState : uint8_t {
    DISCONNECTED = 0,
    CONNECTING = 1,
    CONNECTED = 2,
    ERROR = 3
};

/**
 * @brief 消息类型
 */
enum class MessageKind : uint8_t {
    CREDENTIAL_REQUEST = 1,
    CREDENTIAL_RESPONSE = 2,
    COOKIE_UPLOAD = 3,
    COOKIE_DOWNLOAD = 4,
    DEVICE_REGISTER = 5,
    DEVICE_HEARTBEAT = 6,
    AUTHORIZATION_REQUEST = 7,
    SYNC_REQUEST = 8,
    EVENT = 9,
    CONTROL = 10,
    HEALTH_CHECK = 11
};

/**
 * @brief 通用消息包装器
 */
struct Message {
    std::string message_id;
    MessageKind kind;
    MessagePriority priority;
    std::string source_id;
    std::string target_id;
    std::string topic;
    std::vector<uint8_t> payload;
    uint64_t timestamp;
    uint32_t timeout_ms;
    int retry_count;
    
    Message() 
        : priority(MessagePriority::NORMAL)
        , timestamp(currentTimestamp())
        , timeout_ms(5000)
        , retry_count(0) {}
    
    static uint64_t currentTimestamp() {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
    }
};

/**
 * @brief 消息回调
 */
using MessageCallback = std::function<void(const Message&)>;
using ConnectionCallback = std::function<void(const std::string& connection_id, ConnectionState state)>;

/**
 * @brief 主题订阅者
 */
struct Subscriber {
    std::string subscriber_id;
    MessageCallback callback;
    std::unordered_set<MessageKind> interests;
    bool active = true;
};

/**
 * @brief 连接信息
 */
struct ConnectionInfo {
    std::string connection_id;
    std::string remote_endpoint;
    ConnectionState state;
    uint64_t last_heartbeat;
    uint64_t connect_time;
    uint64_t messages_sent;
    uint64_t messages_received;
    std::map<std::string, std::string> metadata;
};

// ============================================================================
// 数据总线配置
// ============================================================================

/**
 * @brief 数据总线配置
 */
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

// ============================================================================
// 数据总线核心类
// ============================================================================

/**
 * @brief 数据总线 - 消息路由与通信中枢
 * 
 * 提供统一的消息传递机制，支持：
 * - 发布/订阅模式
 * - 请求/响应模式
 * - 主题路由
 * - 连接管理
 */
class DataBus {
public:
    explicit DataBus(const DataBusConfig& config = {});
    ~DataBus();
    
    // 生命周期管理
    bool initialize();
    void start();
    void stop();
    bool isRunning() const { return running_; }
    
    // 发布/订阅
    std::string subscribe(const std::string& topic, MessageCallback callback);
    bool unsubscribe(const std::string& subscriber_id);
    bool publish(const std::string& topic, const Message& message);
    bool publishAsync(const std::string& topic, const Message& message);
    
    // 请求/响应
    std::optional<Message> request(const std::string& target, const Message& request_msg, int timeout_ms = 5000);
    void respond(const std::string& target, const Message& response);
    
    // 注册消息处理器
    void registerHandler(MessageKind kind, MessageCallback callback);
    void unregisterHandler(MessageKind kind);
    
    // 连接管理
    std::string connect(const std::string& endpoint);
    bool disconnect(const std::string& connection_id);
    ConnectionState getConnectionState(const std::string& connection_id) const;
    std::vector<ConnectionInfo> getConnections() const;
    
    // 监控
    void setConnectionCallback(ConnectionCallback callback);
    uint64_t getMessagesSent() const { return messages_sent_; }
    uint64_t getMessagesReceived() const { return messages_received_; }
    uint64_t getQueueSize() const;
    
    // 心跳
    void startHeartbeat();
    void stopHeartbeat();
    
    // eCAL集成
#ifdef USE_ECAL
    void enableEcal(bool enable);
    bool publishEcal(const std::string& topic, const google::protobuf::Message& msg);
    template<typename T>
    bool subscribeEcal(const std::string& topic, std::function<void(const T&)> callback);
#endif

private:
    DataBusConfig config_;
    std::atomic<bool> running_;
    std::atomic<bool> initialized_;
    
    // 线程
    std::vector<std::thread> worker_threads_;
    std::thread heartbeat_thread_;
    std::thread monitor_thread_;
    
    // 订阅者管理
    std::mutex subscribers_mutex_;
    std::unordered_map<std::string, Subscriber> subscribers_;
    std::map<std::string, std::vector<std::string>> topic_to_subscribers_;
    
    // 消息处理器
    std::mutex handlers_mutex_;
    std::map<MessageKind, MessageCallback> handlers_;
    
    // 连接管理
    std::mutex connections_mutex_;
    std::unordered_map<std::string, std::shared_ptr<Connection>> connections_;
    std::unordered_map<std::string, std::string> endpoint_to_connection_;
    
    // 消息队列
    std::mutex queue_mutex_;
    std::queue<Message> message_queue_;
    
    // 统计
    std::atomic<uint64_t> messages_sent_;
    std::atomic<uint64_t> messages_received_;
    std::atomic<uint64_t> message_id_counter_;
    int request_timeout_ms_;
    
    // 请求/响应管理
    struct PendingResponse;
    std::mutex pending_responses_mutex_;
    std::unordered_map<std::string, std::shared_ptr<PendingResponse>> pending_responses_;
    
    // 回调
    ConnectionCallback connection_callback_;
    
    // eCAL
#ifdef USE_ECAL
    bool ecal_enabled_;
    std::mutex ecal_publishers_mutex_;
    std::map<std::string, std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::Event>>> ecal_event_publishers_;
#endif
    
    // 内部方法
    void workerLoop();
    void heartbeatLoop();
    void monitorLoop();
    void processMessage(const Message& msg);
    std::string generateMessageId();
    void notifyConnectionState(const std::string& connection_id, ConnectionState state);
};

// ============================================================================
// 连接类
// ============================================================================

/**
 * @brief 连接封装
 */
class Connection : public std::enable_shared_from_this<Connection> {
public:
    Connection(const std::string& connection_id, const std::string& endpoint);
    
    void setState(ConnectionState state);
    ConnectionState getState() const { return state_; }
    const std::string& getId() const { return connection_id_; }
    const std::string& getEndpoint() const { return endpoint_; }
    
    void updateHeartbeat();
    uint64_t getLastHeartbeat() const { return last_heartbeat_; }
    
    bool send(const Message& msg);
    bool receive(Message& msg);
    
    void setMetadata(const std::string& key, const std::string& value);
    std::optional<std::string> getMetadata(const std::string& key) const;
    
private:
    std::string connection_id_;
    std::string endpoint_;
    ConnectionState state_;
    uint64_t last_heartbeat_;
    uint64_t connect_time_;
    uint64_t messages_sent_;
    uint64_t messages_received_;
    std::map<std::string, std::string> metadata_;
    std::mutex mutex_;
};

// ============================================================================
// 消息构建器
// ============================================================================

/**
 * @brief 消息构建器
 */
class MessageBuilder {
public:
    MessageBuilder& setKind(MessageKind kind) {
        msg_.kind = kind;
        return *this;
    }
    
    MessageBuilder& setPriority(MessagePriority priority) {
        msg_.priority = priority;
        return *this;
    }
    
    MessageBuilder& setSource(const std::string& source_id) {
        msg_.source_id = source_id;
        return *this;
    }
    
    MessageBuilder& setTarget(const std::string& target_id) {
        msg_.target_id = target_id;
        return *this;
    }
    
    MessageBuilder& setTopic(const std::string& topic) {
        msg_.topic = topic;
        return *this;
    }
    
    MessageBuilder& setPayload(const std::vector<uint8_t>& payload) {
        msg_.payload = payload;
        return *this;
    }
    
    MessageBuilder& setTimeout(uint32_t timeout_ms) {
        msg_.timeout_ms = timeout_ms;
        return *this;
    }
    
    Message build() {
        msg_.message_id = generateId();
        msg_.timestamp = Message::currentTimestamp();
        return std::move(msg_);
    }
    
private:
    Message msg_;
    
    std::string generateId() {
        static std::atomic<uint64_t> counter{0};
        return "msg_" + std::to_string(++counter) + "_" + 
               std::to_string(Message::currentTimestamp());
    }
};

// ============================================================================
// Protobuf序列化辅助
// ============================================================================

/**
 * @brief Protobuf消息序列化器
 */
class ProtobufSerializer {
public:
    /**
     * @brief 将Protobuf消息序列化到字节向量
     */
    template<typename T>
    static std::vector<uint8_t> serialize(const T& msg) {
        std::string serialized;
        if (msg.SerializeToString(&serialized)) {
            return std::vector<uint8_t>(serialized.begin(), serialized.end());
        }
        return {};
    }
    
    /**
     * @brief 从字节向量反序列化Protobuf消息
     */
    template<typename T>
    static bool deserialize(const std::vector<uint8_t>& data, T& msg) {
        if (data.empty()) return false;
        std::string serialized(data.begin(), data.end());
        return msg.ParseFromString(serialized);
    }
    
    /**
     * @brief 从Message payload提取CredentialRequest
     */
    static bool extractCredentialRequest(const Message& msg, openclaw::CredentialRequest& request) {
        return deserialize(msg.payload, request);
    }
    
    /**
     * @brief 从Message payload提取CredentialResponse
     */
    static bool extractCredentialResponse(const Message& msg, openclaw::CredentialResponse& response) {
        return deserialize(msg.payload, response);
    }
    
    /**
     * @brief 从Message payload提取Event
     */
    static bool extractEvent(const Message& msg, openclaw::Event& event) {
        return deserialize(msg.payload, event);
    }
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建CredentialRequest消息
 */
Message createCredentialRequest(const std::string& service_url, 
                                const std::string& service_name,
                                int credential_type);

/**
 * @brief 创建CredentialResponse消息
 */
Message createCredentialResponse(const std::string& request_id,
                                bool success,
                                const std::string& encrypted_credential,
                                const std::string& error_message = "");

/**
 * @brief 创建Event消息
 */
Message createEventMessage(const std::string& device_id, 
                          openclaw::EventType event_type,
                          const std::string& message);

/**
 * @brief 创建DeviceHeartbeat消息
 */
Message createHeartbeatMessage(const std::string& device_id,
                              const std::map<std::string, std::string>& status = {});

/**
 * @brief 创建AuthorizationRequest消息
 */
Message createAuthorizationRequest(const std::string& auth_id,
                                   const std::string& service_url,
                                   const std::string& device_id);

} // namespace bus
} // namespace polyvault