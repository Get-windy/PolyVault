/**
 * @file node_discovery.hpp
 * @brief PolyVault P2P节点发现模块
 * 
 * 功能：
 * - 本地网络自动发现
 * - mDNS/Bonjour支持
 * - 分布式哈希表(DHT)
 * - 节点健康检查
 */

#ifndef POLYVAULT_NODE_DISCOVERY_HPP
#define POLYVAULT_NODE_DISCOVERY_HPP

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <functional>
#include <mutex>
#include <thread>
#include <chrono>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#include <ecal/service/server.h>
#include <ecal/service/client.h>
#endif

namespace polyvault {
namespace discovery {

// ============================================================================
// 类型定义
// ============================================================================

using NodeId = std::string;
using Timestamp = uint64_t;

/**
 * @brief 节点类型
 */
enum class NodeType : uint8_t {
    UNKNOWN = 0,
    PHONE = 1,
    DESKTOP = 2,
    EMBEDDED = 3,
    SERVER = 4
};

/**
 * @brief 节点状态
 */
enum class NodeStatus : uint8_t {
    OFFLINE = 0,
    ONLINE = 1,
    BUSY = 2,
    ERROR = 3
};

/**
 * @brief 节点信息
 */
struct NodeInfo {
    NodeId node_id;
    std::string node_name;
    NodeType type;
    std::string platform;          // android, ios, windows, linux, macos
    std::string version;
    std::string endpoint;          // IP:Port
    std::vector<std::string> capabilities;
    NodeStatus status;
    Timestamp last_seen;
    int trust_level;               // 0-100
    double battery_level;          // 0-100
    std::string network_type;      // wifi, cellular, ethernet
    
    // 元数据
    std::map<std::string, std::string> metadata;
};

/**
 * @brief 发现配置
 */
struct DiscoveryConfig {
    std::string node_id;
    std::string node_name;
    NodeType node_type;
    std::string platform;
    std::string version;
    int discovery_port = 7443;
    int heartbeat_interval_ms = 5000;
    int node_timeout_ms = 30000;
    int max_nodes = 100;
    bool enable_mdns = true;
    bool enable_dht = false;       // 分布式哈希表
    std::string discovery_scope = "polyvault";
    std::vector<std::string> capabilities;
    std::map<std::string, std::string> metadata;
};

/**
 * @brief 发现事件类型
 */
enum class DiscoveryEventType {
    NODE_FOUND,
    NODE_LOST,
    NODE_UPDATED,
    NETWORK_CHANGED
};

/**
 * @brief 发现事件
 */
struct DiscoveryEvent {
    DiscoveryEventType type;
    NodeInfo node;
    Timestamp timestamp;
    std::string reason;
};

// ============================================================================
// 节点发现接口
// ============================================================================

using NodeCallback = std::function<void(const DiscoveryEvent&)>;

class NodeDiscovery {
public:
    explicit NodeDiscovery(const DiscoveryConfig& config);
    ~NodeDiscovery();
    
    // 禁止拷贝
    NodeDiscovery(const NodeDiscovery&) = delete;
    NodeDiscovery& operator=(const NodeDiscovery&) = delete;
    
    // ==================== 生命周期 ====================
    
    /**
     * @brief 初始化发现服务
     */
    bool initialize();
    
    /**
     * @brief 启动发现服务
     */
    bool start();
    
    /**
     * @brief 停止发现服务
     */
    void stop();
    
    /**
     * @brief 关闭并清理资源
     */
    void shutdown();
    
    // ==================== 节点查询 ====================
    
    /**
     * @brief 获取所有已发现节点
     */
    std::vector<NodeInfo> getDiscoveredNodes() const;
    
    /**
     * @brief 获取特定节点信息
     */
    std::optional<NodeInfo> getNode(const NodeId& node_id) const;
    
    /**
     * @brief 按能力查询节点
     */
    std::vector<NodeInfo> getNodesByCapability(const std::string& capability) const;
    
    /**
     * @brief 按类型查询节点
     */
    std::vector<NodeInfo> getNodesByType(NodeType type) const;
    
    /**
     * @brief 获取在线节点数量
     */
    int getOnlineNodeCount() const;
    
    /**
     * @brief 获取本机节点信息
     */
    NodeInfo getLocalNodeInfo() const;
    
    // ==================== 主动发现 ====================
    
    /**
     * @brief 主动发现节点
     */
    void discoverNodes();
    
    /**
     * @brief Ping指定节点
     */
    bool pingNode(const NodeId& node_id);
    
    /**
     * @brief 向特定地址发送发现请求
     */
    bool discoverAtAddress(const std::string& address, int port);
    
    // ==================== 节点管理 ====================
    
    /**
     * @brief 更新本机节点信息
     */
    void updateLocalNodeInfo(const NodeInfo& info);
    
    /**
     * @brief 设置节点信任级别
     */
    void setNodeTrustLevel(const NodeId& node_id, int level);
    
    /**
     * @brief 手动添加节点
     */
    bool addNode(const NodeInfo& node);
    
    /**
     * @brief 移除节点
     */
    bool removeNode(const NodeId& node_id);
    
    // ==================== 回调 ====================
    
    /**
     * @brief 设置节点事件回调
     */
    void setNodeCallback(NodeCallback callback);
    
    // ==================== 状态 ====================
    
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
    
    void broadcastThread();
    void listenThread();
    void heartbeatThread();
    void cleanupThread();
    
    void processDiscoveryMessage(const std::vector<uint8_t>& data, 
                                  const std::string& from_address);
    void sendDiscoveryBroadcast();
    void sendHeartbeat();
    
    void checkNodeTimeouts();
    void updateNodeLastSeen(const NodeId& node_id);
    
    NodeInfo createLocalNodeInfo() const;
    Timestamp currentTimestamp() const;
    
    // 序列化
    bool serializeNodeInfo(const NodeInfo& info, std::vector<uint8_t>& buffer);
    bool deserializeNodeInfo(const std::vector<uint8_t>& buffer, NodeInfo& info);
    
#ifdef USE_ECAL
    void setupECALDiscovery();
    void onECALDiscoveryMessage(const char* topic, const void* data, size_t size);
#endif

private:
    DiscoveryConfig config_;
    bool initialized_;
    bool running_;
    
    // 已发现节点
    mutable std::mutex nodes_mutex_;
    std::map<NodeId, NodeInfo> discovered_nodes_;
    
    // 本机节点信息
    NodeInfo local_node_;
    mutable std::mutex local_node_mutex_;
    
    // 回调
    NodeCallback node_callback_;
    
    // 线程
    std::thread broadcast_thread_;
    std::thread listen_thread_;
    std::thread heartbeat_thread_;
    std::thread cleanup_thread_;
    
    // 统计
    mutable std::mutex stats_mutex_;
    uint64_t broadcasts_sent_;
    uint64_t messages_received_;
    
#ifdef USE_ECAL
    std::unique_ptr<eCAL::CPublisher> discovery_publisher_;
    std::unique_ptr<eCAL::CSubscriber> discovery_subscriber_;
#endif
};

// ============================================================================
// mDNS发现器
// ============================================================================

class MDNSDiscovery {
public:
    explicit MDNSDiscovery(const std::string& service_name = "_polyvault._tcp.local.");
    ~MDNSDiscovery();
    
    /**
     * @brief 启动mDNS广播
     */
    bool startBroadcast(int port);
    
    /**
     * @brief 停止广播
     */
    void stopBroadcast();
    
    /**
     * @brief 开始发现
     */
    bool startDiscovery();
    
    /**
     * @brief 停止发现
     */
    void stopDiscovery();
    
    /**
     * @brief 获取发现的服务
     */
    std::vector<std::pair<std::string, int>> getDiscoveredServices() const;

private:
    std::string service_name_;
    bool broadcasting_;
    bool discovering_;
    
    void* mdns_context_;  // 平台特定的mDNS上下文
};

// ============================================================================
// 分布式哈希表(DHT)发现器
// ============================================================================

class DHTDiscovery {
public:
    struct DHTConfig {
        std::string node_id;
        int port = 6881;
        std::vector<std::string> bootstrap_nodes;
    };
    
    explicit DHTDiscovery(const DHTConfig& config);
    ~DHTDiscovery();
    
    /**
     * @brief 加入DHT网络
     */
    bool join();
    
    /**
     * @brief 离开DHT网络
     */
    void leave();
    
    /**
     * @brief 发布节点信息
     */
    bool announce(const NodeInfo& info);
    
    /**
     * @brief 查找节点
     */
    std::vector<NodeInfo> lookup(const std::string& capability);

private:
    DHTConfig config_;
    bool joined_;
};

// ============================================================================
// 工具函数
// ============================================================================

namespace utils {

/**
 * @brief 获取本机IP地址
 */
std::vector<std::string> getLocalIPAddresses();

/**
 * @brief 检测网络类型
 */
std::string detectNetworkType();

/**
 * @brief 检查端口是否可用
 */
bool isPortAvailable(int port);

/**
 * @brief 生成唯一节点ID
 */
std::string generateNodeId();

} // namespace utils

} // namespace discovery
} // namespace polyvault

#endif // POLYVAULT_NODE_DISCOVERY_HPP