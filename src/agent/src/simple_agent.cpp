/**
 * @file simple_agent.cpp
 * @brief 简化版Agent实现
 */

#include "simple_agent.hpp"
#include <iostream>
#include <optional>

namespace polyvault {

// ==================== SimpleCredentialService ====================

std::optional<std::string> SimpleCredentialService::getCredential(const std::string& service_url) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = credentials_.find(service_url);
    if (it != credentials_.end()) {
        return it->second;
    }
    return std::nullopt;
}

bool SimpleCredentialService::storeCredential(const std::string& service_url, 
                                               const std::string& encrypted_credential) {
    std::lock_guard<std::mutex> lock(mutex_);
    credentials_[service_url] = encrypted_credential;
    std::cout << "[CredentialService] Stored credential for: " << service_url << std::endl;
    return true;
}

bool SimpleCredentialService::deleteCredential(const std::string& service_url) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = credentials_.find(service_url);
    if (it != credentials_.end()) {
        credentials_.erase(it);
        return true;
    }
    return false;
}

bool SimpleCredentialService::hasCredential(const std::string& service_url) {
    std::lock_guard<std::mutex> lock(mutex_);
    return credentials_.find(service_url) != credentials_.end();
}

simple::CredentialResponse SimpleCredentialService::handleRequest(const simple::CredentialRequest& request) {
    simple::CredentialResponse response;
    response.session_id = request.session_id;
    response.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    
    auto cred = getCredential(request.service_url);
    if (cred) {
        response.success = true;
        response.encrypted_credential = *cred;
        std::cout << "[CredentialService] Found credential for: " << request.service_url << std::endl;
    } else {
        response.success = false;
        response.error_message = "Credential not found for: " + request.service_url;
        response.error_code = 404;
        std::cout << "[CredentialService] No credential for: " << request.service_url << std::endl;
    }
    
    return response;
}

// ==================== SimpleAgent ====================

SimpleAgent::SimpleAgent(const AgentConfig& config) : config_(config) {}

SimpleAgent::~SimpleAgent() {
    stop();
}

bool SimpleAgent::initialize() {
    std::cout << "[Agent] Initializing..." << std::endl;
    std::cout << "[Agent] Agent ID: " << config_.agent_id << std::endl;
    std::cout << "[Agent] Listen port: " << config_.listen_port << std::endl;
    
#ifdef USE_ECAL
    if (config_.use_ecal) {
        eCAL::Initialize(0, nullptr, "PolyVaultAgent");
        std::cout << "[Agent] eCAL initialized" << std::endl;
    }
#endif
    
    return true;
}

void SimpleAgent::start() {
    if (running_) return;
    
    running_ = true;
    worker_thread_ = std::thread(&SimpleAgent::runLoop, this);
    
    std::cout << "[Agent] Started, listening for messages..." << std::endl;
}

void SimpleAgent::stop() {
    if (!running_) return;
    
    running_ = false;
    
    if (worker_thread_.joinable()) {
        worker_thread_.join();
    }
    
#ifdef USE_ECAL
    if (config_.use_ecal) {
        eCAL::Finalize();
    }
#endif
    
    std::cout << "[Agent] Stopped" << std::endl;
}

void SimpleAgent::runLoop() {
    while (running_) {
        // 主循环 - 在实际实现中会监听网络/eCAL
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
}

simple::CredentialResponse SimpleAgent::handleCredentialRequest(const simple::CredentialRequest& req) {
    std::cout << "[Agent] Handling credential request for: " << req.service_url << std::endl;
    
    if (credential_callback_) {
        return credential_callback_(req);
    }
    
    // 默认处理
    simple::CredentialResponse resp;
    resp.session_id = req.session_id;
    resp.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    
    std::lock_guard<std::mutex> lock(credential_mutex_);
    auto it = credentials_.find(req.service_url);
    if (it != credentials_.end()) {
        resp.success = true;
        resp.encrypted_credential = it->second;
    } else {
        resp.success = false;
        resp.error_message = "Credential not found";
        resp.error_code = 404;
    }
    
    return resp;
}

simple::HeartbeatResponse SimpleAgent::handleHeartbeat(const simple::Heartbeat& hb) {
    std::cout << "[Agent] Received heartbeat from: " << hb.agent_id << std::endl;
    
    if (heartbeat_callback_) {
        return heartbeat_callback_(hb);
    }
    
    simple::HeartbeatResponse resp;
    resp.session_id = hb.session_id;
    resp.agent_id = hb.agent_id;
    resp.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    resp.server_time = resp.timestamp;
    
    return resp;
}

simple::CookieUploadResponse SimpleAgent::handleCookieUpload(const simple::CookieUpload& upload) {
    std::cout << "[Agent] Received cookie upload, count: " << upload.cookies.size() << std::endl;
    
    if (cookie_callback_) {
        return cookie_callback_(upload);
    }
    
    // 默认处理 - 存储cookie
    std::lock_guard<std::mutex> lock(cookie_mutex_);
    for (const auto& cookie : upload.cookies) {
        std::string key = cookie.domain + ":" + cookie.name;
        cookies_[key] = cookie;
    }
    
    simple::CookieUploadResponse resp;
    resp.session_id = upload.session_id;
    resp.success = true;
    resp.cookies_stored = static_cast<int32_t>(upload.cookies.size());
    
    return resp;
}

simple::ConfigSyncResponse SimpleAgent::handleConfigSync(const simple::ConfigSync& sync) {
    std::cout << "[Agent] Received config sync, entries: " << sync.entries.size() << std::endl;
    
    // 存储配置
    std::lock_guard<std::mutex> lock(config_mutex_);
    for (const auto& [k, v] : sync.entries) {
        config_entries_[k] = v;
    }
    
    simple::ConfigSyncResponse resp;
    resp.session_id = sync.session_id;
    resp.success = true;
    resp.entries_synced = static_cast<int32_t>(sync.entries.size());
    
    return resp;
}

} // namespace polyvault