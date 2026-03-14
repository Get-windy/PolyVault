/**
 * @file simple_agent.hpp
 * @brief 简化版Agent - 不依赖Protobuf
 */

#pragma once

#include <string>
#include <memory>
#include <functional>
#include <thread>
#include <atomic>
#include <mutex>
#include <unordered_map>
#include <iostream>
#include <chrono>
#include <optional>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#endif

#include "simple_message.hpp"

namespace polyvault {

/**
 * @brief Agent配置
 */
struct AgentConfig {
    std::string agent_id;
    std::string client_endpoint;
    bool use_ecal = false;
    int listen_port = 5050;
};

/**
 * @brief 消息类型枚举
 */
enum class MessageType : uint8_t {
    CredentialRequest = 1,
    CredentialResponse = 2,
    CookieUpload = 3,
    CookieUploadResponse = 4,
    Heartbeat = 5,
    HeartbeatResponse = 6,
    ConfigSync = 7,
    ConfigSyncResponse = 8
};

/**
 * @brief 简化版Agent
 */
class SimpleAgent {
public:
    explicit SimpleAgent(const AgentConfig& config);
    ~SimpleAgent();
    
    bool initialize();
    void start();
    void stop();
    
    // 设置凭证回调
    using CredentialCallback = std::function<simple::CredentialResponse(const simple::CredentialRequest&)>;
    void setCredentialCallback(CredentialCallback callback) {
        credential_callback_ = std::move(callback);
    }
    
    // 设置心跳回调
    using HeartbeatCallback = std::function<simple::HeartbeatResponse(const simple::Heartbeat&)>;
    void setHeartbeatCallback(HeartbeatCallback callback) {
        heartbeat_callback_ = std::move(callback);
    }
    
    // 设置Cookie上传回调
    using CookieCallback = std::function<simple::CookieUploadResponse(const simple::CookieUpload&)>;
    void setCookieCallback(CookieCallback callback) {
        cookie_callback_ = std::move(callback);
    }
    
    bool isRunning() const { return running_; }
    const std::string& getAgentId() const { return config_.agent_id; }

private:
    AgentConfig config_;
    std::atomic<bool> running_{false};
    std::thread worker_thread_;
    
    CredentialCallback credential_callback_;
    HeartbeatCallback heartbeat_callback_;
    CookieCallback cookie_callback_;
    
    // 凭证存储
    std::mutex credential_mutex_;
    std::unordered_map<std::string, std::string> credentials_;
    
    // Cookie存储
    std::mutex cookie_mutex_;
    std::unordered_map<std::string, simple::Cookie> cookies_;
    
    // 配置存储
    std::mutex config_mutex_;
    std::unordered_map<std::string, std::string> config_entries_;
    
    void runLoop();
    void processMessage(const std::vector<uint8_t>& data);
    
    // 消息处理
    simple::CredentialResponse handleCredentialRequest(const simple::CredentialRequest& req);
    simple::HeartbeatResponse handleHeartbeat(const simple::Heartbeat& hb);
    simple::CookieUploadResponse handleCookieUpload(const simple::CookieUpload& upload);
    simple::ConfigSyncResponse handleConfigSync(const simple::ConfigSync& sync);
};

/**
 * @brief 凭证服务
 */
class SimpleCredentialService {
public:
    std::optional<std::string> getCredential(const std::string& service_url);
    bool storeCredential(const std::string& service_url, const std::string& encrypted_credential);
    bool deleteCredential(const std::string& service_url);
    bool hasCredential(const std::string& service_url);
    
    simple::CredentialResponse handleRequest(const simple::CredentialRequest& request);

private:
    std::mutex mutex_;
    std::unordered_map<std::string, std::string> credentials_;
};

} // namespace polyvault