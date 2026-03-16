/**
 * @file openclaw_client.hpp
 * @brief OpenClaw Agent通信客户端
 */

#pragma once

#include <string>
#include <memory>
#include <functional>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include "data_bus.hpp"

// Forward declarations for protobuf
namespace openclaw {
    class CredentialRequest;
    class CredentialResponse;
    class AuthorizationRequest;
    class AuthorizationResponse;
    class Event;
    class DeviceHeartbeat;
}

namespace polyvault {
namespace agent {

// ============================================================================
// OpenClaw Agent配置
// ============================================================================

struct OpenClawAgentConfig {
    std::string agent_id;              // Agent ID
    std::string agent_name;            // Agent名称
    std::string gateway_url;           // Gateway URL (e.g., "http://localhost:8080")
    std::string api_key;               // API密钥
    int heartbeat_interval_ms = 30000; // 心跳间隔
    int request_timeout_ms = 10000;    // 请求超时
    bool auto_reconnect = true;        // 自动重连
    int max_retries = 3;               // 最大重试次数
    bool enable_tls = true;            // 启用TLS
    std::string ca_cert_path;          // CA证书路径
};

// ============================================================================
// 认证状态
// ============================================================================

enum class AuthState {
    UNAUTHENTICATED,
    AUTHENTICATING,
    AUTHENTICATED,
    AUTH_FAILED,
    TOKEN_EXPIRED
};

// ============================================================================
// OpenClaw客户端状态
// ============================================================================

struct ClientState {
    AuthState auth_state = AuthState::UNAUTHENTICATED;
    std::string session_token;
    uint64_t token_expires_at = 0;
    bool connected = false;
    uint64_t last_heartbeat = 0;
    uint64_t messages_sent = 0;
    uint64_t messages_received = 0;
};

// ============================================================================
// OpenClaw Agent客户端
// ============================================================================

class OpenClawClient {
public:
    explicit OpenClawClient(const OpenClawAgentConfig& config);
    ~OpenClawClient();
    
    // 禁止拷贝
    OpenClawClient(const OpenClawClient&) = delete;
    OpenClawClient& operator=(const OpenClawClient&) = delete;
    
    // 连接管理
    bool connect();
    void disconnect();
    bool isConnected() const;
    
    // 认证
    bool authenticate();
    bool refreshToken();
    void logout();
    AuthState getAuthState() const;
    
    // 凭证请求
    std::unique_ptr<openclaw::CredentialResponse> requestCredential(
        const openclaw::CredentialRequest& request);
    
    // 授权请求
    std::unique_ptr<openclaw::AuthorizationResponse> requestAuthorization(
        const openclaw::AuthorizationRequest& request);
    
    // 事件上报
    bool reportEvent(const openclaw::Event& event);
    bool reportHeartbeat(const openclaw::DeviceHeartbeat& heartbeat);
    
    // 数据总线集成
    void setDataBus(bus::DataBus* bus);
    bus::DataBus* getDataBus() const;
    
    // 消息订阅
    void subscribeToCredentials(std::function<void(const openclaw::CredentialResponse&)> callback);
    void subscribeToAuthorizations(std::function<void(const openclaw::AuthorizationResponse&)> callback);
    void subscribeToEvents(std::function<void(const openclaw::Event&)> callback);
    
    // 状态
    ClientState getState() const;
    
    // 健康检查
    bool healthCheck() const;
    
private:
    // 内部实现
    void heartbeatLoop();
    void receiveLoop();
    bool sendRequest(const std::string& path, const std::string& body, std::string& response);
    bool sendMessage(const bus::Message& msg);
    
    // HTTP客户端方法
    std::string httpPost(const std::string& path, const std::string& body);
    std::string httpGet(const std::string& path);
    
    // REST API端点
    std::string buildUrl(const std::string& path) const;
    
private:
    OpenClawAgentConfig config_;
    bus::DataBus* bus_ = nullptr;
    ClientState state_;
    
    mutable std::mutex mutex_;
    std::thread heartbeat_thread_;
    std::thread receive_thread_;
    std::atomic<bool> running_{false};
    
    // 回调
    std::function<void(const openclaw::CredentialResponse&)> credential_callback_;
    std::function<void(const openclaw::AuthorizationResponse&)> auth_callback_;
    std::function<void(const openclaw::Event&)> event_callback_;
};

// ============================================================================
// OpenClaw Agent适配器
// ============================================================================

class OpenClawAgentAdapter {
public:
    explicit OpenClawAgentAdapter(const OpenClawAgentConfig& config);
    ~OpenClawAgentAdapter();
    
    // 初始化
    bool initialize(bus::DataBus* bus);
    
    // 启动/停止
    bool start();
    void stop();
    
    // 状态
    bool isRunning() const;
    ClientState getClientState() const;
    
private:
    // 消息处理器
    void handleCredentialRequest(const bus::Message& msg);
    void handleAuthorizationRequest(const bus::Message& msg);
    void handleEvent(const bus::Message& msg);
    void handleHeartbeat(const bus::Message& msg);
    
private:
    OpenClawAgentConfig config_;
    std::unique_ptr<OpenClawClient> client_;
    bus::DataBus* bus_ = nullptr;
    std::atomic<bool> running_{false};
    
    std::string credential_sub_id_;
    std::string auth_sub_id_;
    std::string event_sub_id_;
};

} // namespace agent
} // namespace polyvault