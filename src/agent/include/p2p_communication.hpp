/**
 * @file p2p_communication.hpp
 * @brief PolyVault P2P通信模块 - 基于eCAL实现
 * 
 * 功能：
 * - 设备发现与连接管理
 * - 端到端加密通信
 * - 消息路由与转发
 * - NAT穿透支持
 */

#ifndef POLYVAULT_P2P_COMMUNICATION_HPP
#define POLYVAULT_P2P_COMMUNICATION_HPP

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <functional>
#include <mutex>
#include <thread>
#include <chrono>
#include <optional>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#include <ecal/msg/protobuf/publisher.h>
#include <ecal/msg/protobuf/subscriber.h>
#include <ecal/service/server.h>
#include <ecal/service/client.h>
#endif

#include "openclaw.pb.h"

namespace polyvault {
namespace p2p {

// ============================================================================
// 类型定义
// ============================================================================

using DeviceId = std::string;
using MessageId = std::string;
using Timestamp = uint64_t;

/**
 * @brief 设备信息
 */
struct DeviceInfo {
    DeviceId device_id;
    std::string device_name;
    std::string device_type;      // "phone", "desktop", "embedded"
    std::string platform;          // "android", "ios", "windows", "linux", "macos"
    std::string version;
    std::vector<std::string> capabilities;
    std::string endpoint;          // IP:Port
    bool is_online;
    Timestamp last_seen;
    int trust_level;               // 0-100
};

/**
 * @brief P2P消息类型
 */
enum class MessageType : uint8_t {
    HANDSHAKE = 0,
    HANDSHAKE_ACK = 1,
    DISCOVERY = 2,
    DISCOVERY_RESPONSE = 3,
    DATA = 4,
    DATA_ACK = 5,
    CREDENTIAL_REQUEST = 10,
    CREDENTIAL_RESPONSE = 11,
    COOKIE_UPLOAD = 12,
    HEARTBEAT = 20,
    HEARTBEAT_ACK = 21,
    DISCONNECT = 30,
    ERROR = 255
};

/**
 * @brief P2P消息头
 */
struct P2PMessageHeader {
    uint8_t version;
    MessageType type;
    uint8_t flags;
    uint8_t hop_count;
    MessageId message_id;
    DeviceId source_id;
    DeviceId target_id;
    Timestamp timestamp;
    uint32_t payload_size;
};

/**
 * @brief P2P消息
 */
struct P2PMessage {
    P2PMessageHeader header;
    std::vector<uint8_t> payload;
    
    // 加密相关
    bool encrypted;
    std::vector<uint8_t> nonce;
    std::vector<uint8_t> signature;
};

/**
 * @brief 连接状态
 */
enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    AUTHENTICATING,
    AUTHENTICATED,
    ERROR
};

/**
 * @brief P2P连接
 */
struct P2PConnection {
    DeviceId device_id;
    std::string endpoint;
    ConnectionState state;
    Timestamp established_at;
    Timestamp last_activity;
    uint64_t bytes_sent;
    uint64_t bytes_received;
    std::string session_key;  // 加密会话密钥
};

/**
 * @brief P2P配置
 */
struct P2PConfig {
    std::string node_id;
    std::string node_name;
    int discovery_port = 7443;
    int data_port = 7444;
    int heartbeat_interval_ms = 5000;
    int connection_timeout_ms = 10000;
    int max_connections = 50;
    bool enable_encryption = true;
    bool enable_compression = true;
    std::string discovery_scope = "polyvault";
};

// ============================================================================
// 消息回调类型
// ============================================================================

using MessageCallback = std::function<void(const P2PMessage&)>;
using DeviceCallback = std::function<void(const DeviceInfo&, bool online)>;
using ConnectionCallback = std::function<void(const P2PConnection&, ConnectionState)>;

// ============================================================================
// P2P通信核心类
// ============================================================================

class P2PCommunication {
public:
    explicit P2PCommunication(const P2PConfig& config);
    ~P2PCommunication();
    
    // 禁止拷贝
    P2PCommunication(const P2PCommunication&) = delete;
    P2PCommunication& operator=(const P2PCommunication&) = delete;
    
    // ==================== 生命周期管理 ====================
    
    /**
     * @brief 初始化P2P通信
     */
    bool initialize();
    
    /**
     * @brief 启动P2P服务
     */
    bool start();
    
    /**
     * @brief 停止P2P服务
     */
    void stop();
    
    /**
     * @brief 关闭并清理资源
     */
    void shutdown();
    
    // ==================== 设备发现 ====================
    
    /**
     * @brief 开始设备发现
     */
    void startDiscovery();
    
    /**
     * @brief 停止设备发现
     */
    void stopDiscovery();
    
    /**
     * @brief 获取已发现的设备列表
     */
    std::vector<DeviceInfo> getDiscoveredDevices() const;
    
    /**
     * @brief 获取特定设备信息
     */
    std::optional<DeviceInfo> getDeviceInfo(const DeviceId& device_id) const;
    
    // ==================== 连接管理 ====================
    
    /**
     * @brief 连接到指定设备
     */
    bool connectToDevice(const DeviceId& device_id);
    
    /**
     * @brief 断开与设备的连接
     */
    void disconnectFromDevice(const DeviceId& device_id);
    
    /**
     * @brief 获取所有活动连接
     */
    std::vector<P2PConnection> getActiveConnections() const;
    
    /**
     * @brief 检查与设备的连接状态
     */
    ConnectionState getConnectionState(const DeviceId& device_id) const;
    
    // ==================== 消息发送 ====================
    
    /**
     * @brief 发送消息到指定设备
     */
    bool sendMessage(const DeviceId& target_id, MessageType type, 
                     const std::vector<uint8_t>& payload);
    
    /**
     * @brief 发送消息并等待响应
     */
    std::optional<P2PMessage> sendRequest(const DeviceId& target_id, 
                                           MessageType type,
                                           const std::vector<uint8_t>& payload,
                                           int timeout_ms = 5000);
    
    /**
     * @brief 广播消息到所有连接的设备
     */
    void broadcastMessage(MessageType type, const std::vector<uint8_t>& payload);
    
    // ==================== 凭证操作 ====================
    
    /**
     * @brief 请求凭证
     */
    std::optional<openclaw::CredentialResponse> requestCredential(
        const DeviceId& target_device,
        const std::string& service_url,
        const std::string& session_id,
        int timeout_ms = 30000
    );
    
    /**
     * @brief 上传Cookie
     */
    bool uploadCookie(
        const DeviceId& target_device,
        const std::string& service_url,
        const std::vector<uint8_t>& encrypted_cookie,
        const std::string& session_id
    );
    
    // ==================== 回调注册 ====================
    
    /**
     * @brief 注册消息回调
     */
    void setMessageCallback(MessageCallback callback);
    
    /**
     * @brief 注册设备状态回调
     */
    void setDeviceCallback(DeviceCallback callback);
    
    /**
     * @brief 注册连接状态回调
     */
    void setConnectionCallback(ConnectionCallback callback);
    
    // ==================== 状态查询 ====================
    
    /**
     * @brief 获取本机设备信息
     */
    DeviceInfo getLocalDeviceInfo() const;
    
    /**
     * @brief 获取统计信息
     */
    struct Statistics {
        uint64_t total_messages_sent;
        uint64_t total_messages_received;
        uint64_t total_bytes_sent;
        uint64_t total_bytes_received;
        int active_connections;
        int discovered_devices;
    };
    Statistics getStatistics() const;
    
    /**
     * @brief 检查是否已初始化
     */
    bool isInitialized() const { return initialized_; }
    
    /**
     * @brief 检查是否正在运行
     */
    bool isRunning() const { return running_; }

private:
    // ==================== 内部方法 ====================
    
    void discoveryLoop();
    void heartbeatLoop();
    void receiveLoop();
    
    bool performHandshake(const DeviceId& device_id);
    bool authenticateConnection(const DeviceId& device_id);
    
    P2PMessage createMessage(MessageType type, const std::vector<uint8_t>& payload);
    bool serializeMessage(const P2PMessage& msg, std::vector<uint8_t>& buffer);
    bool deserializeMessage(const std::vector<uint8_t>& buffer, P2PMessage& msg);
    
    bool encryptPayload(std::vector<uint8_t>& payload, const std::string& session_key);
    bool decryptPayload(std::vector<uint8_t>& payload, const std::string& session_key);
    
    void handleMessage(const P2PMessage& msg);
    void handleCredentialRequest(const P2PMessage& msg);
    void handleCredentialResponse(const P2PMessage& msg);
    
    MessageId generateMessageId();
    Timestamp currentTimestamp() const;
    
#ifdef USE_ECAL
    // eCAL相关
    void setupECALPublishers();
    void setupECALSubscribers();
    void setupECALServices();
    
    void onECALMessage(const char* topic, const void* data, size_t size);
#endif

private:
    P2PConfig config_;
    bool initialized_;
    bool running_;
    
    // 设备管理
    mutable std::mutex devices_mutex_;
    std::map<DeviceId, DeviceInfo> discovered_devices_;
    
    // 连接管理
    mutable std::mutex connections_mutex_;
    std::map<DeviceId, P2PConnection> connections_;
    
    // 回调
    MessageCallback message_callback_;
    DeviceCallback device_callback_;
    ConnectionCallback connection_callback_;
    
    // 线程
    std::thread discovery_thread_;
    std::thread heartbeat_thread_;
    std::thread receive_thread_;
    
    // 统计
    mutable std::mutex stats_mutex_;
    uint64_t messages_sent_;
    uint64_t messages_received_;
    uint64_t bytes_sent_;
    uint64_t bytes_received_;
    
    // 消息ID计数器
    mutable std::mutex id_mutex_;
    uint64_t message_id_counter_;
    
#ifdef USE_ECAL
    // eCAL组件
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::P2PEnvelope>> publisher_;
    std::unique_ptr<eCAL::protobuf::CSubscriber<openclaw::P2PEnvelope>> subscriber_;
#endif
};

// ============================================================================
// P2P服务端（用于接收凭证请求）
// ============================================================================

class P2PCredentialService {
public:
    explicit P2PCredentialService(P2PCommunication& comm);
    ~P2PCredentialService() = default;
    
    /**
     * @brief 设置凭证提供回调
     */
    using CredentialProvider = std::function<std::optional<std::map<std::string, std::string>>(
        const std::string& service_url,
        const std::string& session_id
    )>;
    
    void setCredentialProvider(CredentialProvider provider);
    
    /**
     * @brief 启动服务
     */
    void start();
    
    /**
     * @brief 停止服务
     */
    void stop();

private:
    void handleCredentialRequest(const P2PMessage& msg);
    
    P2PCommunication& comm_;
    CredentialProvider credential_provider_;
    bool running_;
};

// ============================================================================
// 工具函数
// ============================================================================

namespace utils {

/**
 * @brief 生成设备ID
 */
std::string generateDeviceId();

/**
 * @brief 获取本机IP地址
 */
std::vector<std::string> getLocalIPAddresses();

/**
 * @brief 检查NAT类型
 */
enum class NATType {
    NONE,           // 公网IP
    FULL_CONE,      // 完全锥形NAT
    RESTRICTED,     // 限制锥形NAT
    PORT_RESTRICTED,// 端口限制锥形NAT
    SYMMETRIC       // 对称NAT
};
NATType detectNATType();

/**
 * @brief 计算消息校验和
 */
uint32_t calculateChecksum(const std::vector<uint8_t>& data);

} // namespace utils

} // namespace p2p
} // namespace polyvault

#endif // POLYVAULT_P2P_COMMUNICATION_HPP