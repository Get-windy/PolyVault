/**
 * @file agent.hpp
 * @brief PolyVault Agent主模块头文件
 */

#pragma once

#include <string>
#include <memory>
#include <atomic>
#include "data_bus.hpp"
#include "plugin_interface.hpp"
#include "openclaw_client.hpp"

namespace polyvault {
namespace agent {

// ============================================================================
// Agent配置
// ============================================================================

struct AgentConfig {
    std::string agent_id;
    std::string agent_name;
    std::string version = "1.0.0";
    
    // 数据总线配置
    bus::DataBusConfig bus_config;
    
    // OpenClaw配置
    OpenClawAgentConfig openclaw_config;
    
    // 插件目录
    std::string plugin_dir = "./plugins";
    
    // 日志级别: debug, info, warn, error
    std::string log_level = "info";
    
    // 性能监控
    bool enable_monitoring = true;
    int metrics_interval_ms = 60000;
};

// ============================================================================
// Agent状态
// ============================================================================

enum class AgentState {
    UNINITIALIZED,
    INITIALIZING,
    RUNNING,
    STOPPING,
    STOPPED,
    ERROR
};

// ============================================================================
// Agent指标
// ============================================================================

struct AgentMetrics {
    uint64_t messages_processed = 0;
    uint64_t messages_sent = 0;
    uint64_t messages_received = 0;
    uint64_t errors = 0;
    double cpu_usage_percent = 0.0;
    double memory_usage_mb = 0.0;
    uint64_t uptime_ms = 0;
};

// ============================================================================
// PolyVault Agent
// ============================================================================

class PolyVaultAgent {
public:
    explicit PolyVaultAgent(const AgentConfig& config);
    ~PolyVaultAgent();
    
    // 禁止拷贝
    PolyVaultAgent(const PolyVaultAgent&) = delete;
    PolyVaultAgent& operator=(const PolyVaultAgent&) = delete;
    
    // 生命周期
    bool initialize();
    bool start();
    void stop();
    
    // 状态
    AgentState getState() const;
    AgentMetrics getMetrics() const;
    
    // 数据总线
    bus::DataBus* getDataBus();
    
    // 插件管理
    bool loadPlugin(const std::string& path);
    bool unloadPlugin(const std::string& plugin_id);
    std::vector<plugin::PluginMetadata> getLoadedPlugins() const;
    
    // 消息处理
    void sendMessage(const bus::Message& msg);
    void broadcastEvent(const std::string& event_type, const std::string& data);
    
    // OpenClaw集成
    bool connectToOpenClaw();
    void disconnectFromOpenClaw();
    bool isOpenClawConnected() const;
    
    // 健康检查
    bool healthCheck() const;
    
private:
    // 内部方法
    void metricsLoop();
    void processMessage(const bus::Message& msg);
    void handleCredentialRequest(const bus::Message& msg);
    void handleCredentialResponse(const bus::Message& msg);
    void handleEvent(const bus::Message& msg);
    void handleError(const std::string& error);
    
private:
    AgentConfig config_;
    std::atomic<AgentState> state_{AgentState::UNINITIALIZED};
    
    std::unique_ptr<bus::DataBus> bus_;
    std::unique_ptr<OpenClawAgentAdapter> openclaw_adapter_;
    
    // 插件管理
    std::map<std::string, std::unique_ptr<plugin::IPlugin>> plugins_;
    mutable std::mutex plugins_mutex_;
    
    // 指标
    std::atomic<uint64_t> start_time_{0};
    AgentMetrics metrics_;
    mutable std::mutex metrics_mutex_;
    
    // 线程
    std::thread metrics_thread_;
    std::atomic<bool> running_{false};
};

// ============================================================================
// Agent工厂
// ============================================================================

class AgentFactory {
public:
    static std::unique_ptr<PolyVaultAgent> create(const AgentConfig& config);
    static std::unique_ptr<PolyVaultAgent> createFromConfigFile(const std::string& path);
};

} // namespace agent
} // namespace polyvault