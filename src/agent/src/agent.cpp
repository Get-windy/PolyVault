/**
 * @file agent.cpp
 * @brief PolyVault Agent主模块实现
 */

#include "agent.hpp"
#include <iostream>
#include <chrono>
#include <fstream>

namespace polyvault {
namespace agent {

// ============================================================================
// PolyVaultAgent实现
// ============================================================================

PolyVaultAgent::PolyVaultAgent(const AgentConfig& config)
    : config_(config) {
    std::cout << "[Agent] Creating PolyVault Agent: " << config_.agent_id << std::endl;
}

PolyVaultAgent::~PolyVaultAgent() {
    stop();
}

bool PolyVaultAgent::initialize() {
    if (state_ != AgentState::UNINITIALIZED) {
        return state_ == AgentState::RUNNING;
    }
    
    state_ = AgentState::INITIALIZING;
    std::cout << "[Agent] Initializing..." << std::endl;
    
    // 创建数据总线
    bus_ = std::make_unique<bus::DataBus>(config_.bus_config);
    
    if (!bus_->initialize()) {
        std::cerr << "[Agent] Failed to initialize data bus" << std::endl;
        state_ = AgentState::ERROR;
        return false;
    }
    
    // 注册消息处理器
    bus_->registerHandler(bus::MessageKind::CREDENTIAL_REQUEST,
        [this](const bus::Message& msg) { handleCredentialRequest(msg); });
    
    bus_->registerHandler(bus::MessageKind::CREDENTIAL_RESPONSE,
        [this](const bus::Message& msg) { handleCredentialResponse(msg); });
    
    bus_->registerHandler(bus::MessageKind::EVENT,
        [this](const bus::Message& msg) { handleEvent(msg); });
    
    // 创建OpenClaw适配器
    openclaw_adapter_ = std::make_unique<OpenClawAgentAdapter>(config_.openclaw_config);
    
    if (!openclaw_adapter_->initialize(bus_.get())) {
        std::cerr << "[Agent] Failed to initialize OpenClaw adapter" << std::endl;
        // 不阻断初始化，可以离线运行
    }
    
    start_time_ = bus::Message::currentTimestamp();
    
    std::cout << "[Agent] Initialized successfully" << std::endl;
    return true;
}

bool PolyVaultAgent::start() {
    if (state_ == AgentState::RUNNING) {
        return true;
    }
    
    if (state_ != AgentState::INITIALIZING && state_ != AgentState::STOPPED) {
        if (!initialize()) {
            return false;
        }
    }
    
    std::cout << "[Agent] Starting..." << std::endl;
    
    // 启动数据总线
    bus_->start();
    
    // 启动OpenClaw连接
    if (openclaw_adapter_) {
        openclaw_adapter_->start();
    }
    
    running_ = true;
    state_ = AgentState::RUNNING;
    
    // 启动指标线程
    if (config_.enable_monitoring) {
        metrics_thread_ = std::thread(&PolyVaultAgent::metricsLoop, this);
    }
    
    std::cout << "[Agent] Started successfully" << std::endl;
    std::cout << "[Agent] Agent ID: " << config_.agent_id << std::endl;
    std::cout << "[Agent] Version: " << config_.version << std::endl;
    
    return true;
}

void PolyVaultAgent::stop() {
    if (state_ != AgentState::RUNNING) {
        return;
    }
    
    state_ = AgentState::STOPPING;
    std::cout << "[Agent] Stopping..." << std::endl;
    
    running_ = false;
    
    // 停止OpenClaw连接
    if (openclaw_adapter_) {
        openclaw_adapter_->stop();
    }
    
    // 停止数据总线
    if (bus_) {
        bus_->stop();
    }
    
    // 停止指标线程
    if (metrics_thread_.joinable()) {
        metrics_thread_.join();
    }
    
    // 卸载所有插件
    {
        std::lock_guard<std::mutex> lock(plugins_mutex_);
        plugins_.clear();
    }
    
    state_ = AgentState::STOPPED;
    std::cout << "[Agent] Stopped" << std::endl;
}

AgentState PolyVaultAgent::getState() const {
    return state_;
}

AgentMetrics PolyVaultAgent::getMetrics() const {
    std::lock_guard<std::mutex> lock(metrics_mutex_);
    
    AgentMetrics m = metrics_;
    m.uptime_ms = bus::Message::currentTimestamp() - start_time_;
    
    if (bus_) {
        m.messages_sent = bus_->getMessagesSent();
        m.messages_received = bus_->getMessagesReceived();
    }
    
    return m;
}

bus::DataBus* PolyVaultAgent::getDataBus() {
    return bus_.get();
}

bool PolyVaultAgent::loadPlugin(const std::string& path) {
    // 简化实现：从路径提取插件类型和ID
    // 实际应动态加载共享库
    
    std::cout << "[Agent] Loading plugin from: " << path << std::endl;
    
    // 模拟加载
    std::string plugin_id = "plugin_" + std::to_string(plugins_.size() + 1);
    
    // 创建插件实例（示例）
    // auto plugin = plugin::PluginFactory::create(type, id);
    
    std::cout << "[Agent] Plugin loaded: " << plugin_id << std::endl;
    return true;
}

bool PolyVaultAgent::unloadPlugin(const std::string& plugin_id) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end()) {
        return false;
    }
    
    it->second->stop();
    plugins_.erase(it);
    
    std::cout << "[Agent] Plugin unloaded: " << plugin_id << std::endl;
    return true;
}

std::vector<plugin::PluginMetadata> PolyVaultAgent::getLoadedPlugins() const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    std::vector<plugin::PluginMetadata> result;
    for (const auto& [id, plugin] : plugins_) {
        result.push_back(plugin->getMetadata());
    }
    return result;
}

void PolyVaultAgent::sendMessage(const bus::Message& msg) {
    if (bus_ && state_ == AgentState::RUNNING) {
        bus_->publish(msg.topic, msg);
        metrics_.messages_sent++;
    }
}

void PolyVaultAgent::broadcastEvent(const std::string& event_type, const std::string& data) {
    bus::Message msg;
    msg.kind = bus::MessageKind::EVENT;
    msg.topic = "events/" + event_type;
    msg.source_id = config_.agent_id;
    msg.payload.assign(data.begin(), data.end());
    
    sendMessage(msg);
}

bool PolyVaultAgent::connectToOpenClaw() {
    if (openclaw_adapter_) {
        return openclaw_adapter_->start();
    }
    return false;
}

void PolyVaultAgent::disconnectFromOpenClaw() {
    if (openclaw_adapter_) {
        openclaw_adapter_->stop();
    }
}

bool PolyVaultAgent::isOpenClawConnected() const {
    return openclaw_adapter_ && openclaw_adapter_->isRunning();
}

bool PolyVaultAgent::healthCheck() const {
    return state_ == AgentState::RUNNING && 
           bus_ && 
           bus_->isRunning();
}

void PolyVaultAgent::metricsLoop() {
    std::cout << "[Agent] Metrics thread started" << std::endl;
    
    while (running_) {
        std::this_thread::sleep_for(std::chrono::milliseconds(config_.metrics_interval_ms));
        
        if (!running_) break;
        
        auto m = getMetrics();
        
        std::cout << "[Agent] Metrics:" << std::endl;
        std::cout << "  - Messages sent: " << m.messages_sent << std::endl;
        std::cout << "  - Messages received: " << m.messages_received << std::endl;
        std::cout << "  - Uptime: " << (m.uptime_ms / 1000) << "s" << std::endl;
        std::cout << "  - Plugins loaded: " << plugins_.size() << std::endl;
        
        // 发布指标事件
        broadcastEvent("metrics", std::to_string(m.messages_processed));
    }
    
    std::cout << "[Agent] Metrics thread stopped" << std::endl;
}

void PolyVaultAgent::processMessage(const bus::Message& msg) {
    metrics_.messages_processed++;
}

void PolyVaultAgent::handleCredentialRequest(const bus::Message& msg) {
    std::cout << "[Agent] Handling credential request" << std::endl;
    metrics_.messages_processed++;
    
    // 转发到OpenClaw或本地处理
    if (openclaw_adapter_) {
        // 已在adapter中处理
    }
}

void PolyVaultAgent::handleCredentialResponse(const bus::Message& msg) {
    std::cout << "[Agent] Received credential response" << std::endl;
    metrics_.messages_processed++;
}

void PolyVaultAgent::handleEvent(const bus::Message& msg) {
    metrics_.messages_processed++;
    
    // 分发给插件
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    for (auto& [id, plugin] : plugins_) {
        if (plugin->getState() == plugin::PluginState::RUNNING) {
            plugin->process(msg);
        }
    }
}

void PolyVaultAgent::handleError(const std::string& error) {
    std::cerr << "[Agent] Error: " << error << std::endl;
    metrics_.errors++;
}

// ============================================================================
// AgentFactory实现
// ============================================================================

std::unique_ptr<PolyVaultAgent> AgentFactory::create(const AgentConfig& config) {
    return std::make_unique<PolyVaultAgent>(config);
}

std::unique_ptr<PolyVaultAgent> AgentFactory::createFromConfigFile(const std::string& path) {
    // 读取配置文件（简化实现）
    // 实际应使用JSON/YAML库
    
    AgentConfig config;
    config.agent_id = "polyvault_agent";
    config.agent_name = "PolyVault Agent";
    config.bus_config.node_id = config.agent_id;
    config.bus_config.bus_name = "polyvault_bus";
    config.openclaw_config.agent_id = config.agent_id;
    config.openclaw_config.gateway_url = "http://localhost:8080";
    
    std::cout << "[AgentFactory] Created agent from config: " << path << std::endl;
    
    return create(config);
}

} // namespace agent
} // namespace polyvault