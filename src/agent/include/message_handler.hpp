/**
 * @file message_handler.hpp
 * @brief 消息处理器模块 - 处理各类Protobuf消息
 * 
 * 功能：
 * - 凭证请求处理
 * - Cookie上传处理
 * - 配置同步处理
 * - 心跳响应处理
 */

#pragma once

#include <string>
#include <memory>
#include <functional>
#include <chrono>
#include <unordered_map>
#include <mutex>

#include "openclaw.pb.h"
#include "credential_service.hpp"
#include "crypto_utils.hpp"

namespace polyvault {

/**
 * @brief 消息处理器配置
 */
struct HandlerConfig {
    int request_timeout_ms = 5000;      // 请求超时
    bool auto_respond_heartbeat = true; // 自动响应心跳
    int heartbeat_interval_ms = 1000;   // 心跳间隔
};

/**
 * @brief 处理结果
 */
struct HandlerResult {
    bool success = false;
    std::string error_message;
    int error_code = 0;
};

/**
 * @brief 消息处理器基类
 */
class MessageHandler {
public:
    virtual ~MessageHandler() = default;
    virtual std::string name() const = 0;
};

/**
 * @brief 凭证请求处理器
 */
class CredentialHandler : public MessageHandler {
public:
    explicit CredentialHandler(CredentialService& cred_service)
        : cred_service_(cred_service) {}
    
    std::string name() const override { return "CredentialHandler"; }
    
    HandlerResult handleRequest(const openclaw::CredentialRequest& request,
                                openclaw::CredentialResponse& response) {
        HandlerResult result;
        
        // 验证请求
        if (request.session_id().empty()) {
            result.error_message = "Empty session_id";
            result.error_code = 400;
            return result;
        }
        
        if (request.service_url().empty()) {
            result.error_message = "Empty service_url";
            result.error_code = 400;
            return result;
        }
        
        // 处理请求
        response = cred_service_.handleRequest(request);
        result.success = response.success();
        
        if (!result.success) {
            result.error_message = response.error_message();
            result.error_code = 404;
        }
        
        return result;
    }

private:
    CredentialService& cred_service_;
};

/**
 * @brief Cookie上传处理器
 */
class CookieHandler : public MessageHandler {
public:
    std::string name() const override { return "CookieHandler"; }
    
    HandlerResult handleUpload(const openclaw::CookieUpload& upload,
                               openclaw::CookieUploadResponse& response) {
        HandlerResult result;
        
        // 验证请求
        if (upload.session_id().empty()) {
            result.error_message = "Empty session_id";
            result.error_code = 400;
            return result;
        }
        
        if (upload.cookies().empty()) {
            result.error_message = "Empty cookies";
            result.error_code = 400;
            return result;
        }
        
        // 存储Cookie
        std::lock_guard<std::mutex> lock(cookie_mutex_);
        for (const auto& cookie : upload.cookies()) {
            CookieData data;
            data.name = cookie.name();
            data.value = cookie.value();
            data.domain = cookie.domain();
            data.path = cookie.path();
            data.expires = cookie.expires();
            data.secure = cookie.secure();
            data.http_only = cookie.http_only();
            
            std::string key = cookie.domain() + ":" + cookie.name();
            cookies_[key] = data;
        }
        
        response.set_session_id(upload.session_id());
        response.set_success(true);
        response.set_cookies_stored(upload.cookies_size());
        
        result.success = true;
        std::cout << "[CookieHandler] Stored " << upload.cookies_size() 
                  << " cookies for session: " << upload.session_id() << std::endl;
        
        return result;
    }
    
    // 获取Cookie
    std::optional<std::vector<CookieData>> getCookies(const std::string& domain) {
        std::lock_guard<std::mutex> lock(cookie_mutex_);
        std::vector<CookieData> result;
        
        for (const auto& [key, cookie] : cookies_) {
            if (cookie.domain == domain || 
                cookie.domain.find(domain) != std::string::npos) {
                result.push_back(cookie);
            }
        }
        
        if (result.empty()) {
            return std::nullopt;
        }
        return result;
    }

private:
    struct CookieData {
        std::string name;
        std::string value;
        std::string domain;
        std::string path;
        int64_t expires = 0;
        bool secure = false;
        bool http_only = false;
    };
    
    std::mutex cookie_mutex_;
    std::unordered_map<std::string, CookieData> cookies_;
};

/**
 * @brief 配置同步处理器
 */
class ConfigHandler : public MessageHandler {
public:
    std::string name() const override { return "ConfigHandler"; }
    
    HandlerResult handleSync(const openclaw::ConfigSync& sync,
                             openclaw::ConfigSyncResponse& response) {
        HandlerResult result;
        
        // 更新配置
        std::lock_guard<std::mutex> lock(config_mutex_);
        
        for (const auto& entry : sync.entries()) {
            config_[entry.key()] = entry.value();
        }
        
        response.set_session_id(sync.session_id());
        response.set_success(true);
        response.set_entries_synced(sync.entries_size());
        
        result.success = true;
        std::cout << "[ConfigHandler] Synced " << sync.entries_size() 
                  << " config entries" << std::endl;
        
        return result;
    }
    
    // 获取配置
    std::optional<std::string> getConfig(const std::string& key) {
        std::lock_guard<std::mutex> lock(config_mutex_);
        auto it = config_.find(key);
        if (it != config_.end()) {
            return it->second;
        }
        return std::nullopt;
    }
    
    // 设置配置
    void setConfig(const std::string& key, const std::string& value) {
        std::lock_guard<std::mutex> lock(config_mutex_);
        config_[key] = value;
    }

private:
    std::mutex config_mutex_;
    std::unordered_map<std::string, std::string> config_;
};

/**
 * @brief 心跳处理器
 */
class HeartbeatHandler : public MessageHandler {
public:
    std::string name() const override { return "HeartbeatHandler"; }
    
    HandlerResult handleHeartbeat(const openclaw::Heartbeat& heartbeat,
                                  openclaw::HeartbeatResponse& response) {
        HandlerResult result;
        
        // 更新心跳时间
        last_heartbeat_ = std::chrono::steady_clock::now();
        
        response.set_session_id(heartbeat.session_id());
        response.set_agent_id(heartbeat.agent_id());
        response.set_timestamp(currentTimestamp());
        response.set_server_time(std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
        
        result.success = true;
        
        return result;
    }
    
    // 检查心跳是否活跃
    bool isAlive(int64_t timeout_ms = 30000) const {
        auto now = std::chrono::steady_clock::now();
        auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
            now - last_heartbeat_).count();
        return elapsed < timeout_ms;
    }

private:
    std::chrono::steady_clock::time_point last_heartbeat_;
    
    int64_t currentTimestamp() const {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
    }
};

/**
 * @brief 消息处理器管理器
 */
class MessageHandlerManager {
public:
    MessageHandlerManager(CredentialService& cred_service)
        : credential_handler_(cred_service) {}
    
    // 处理凭证请求
    openclaw::CredentialResponse handleCredentialRequest(
        const openclaw::CredentialRequest& request) {
        openclaw::CredentialResponse response;
        credential_handler_.handleRequest(request, response);
        return response;
    }
    
    // 处理Cookie上传
    openclaw::CookieUploadResponse handleCookieUpload(
        const openclaw::CookieUpload& upload) {
        openclaw::CookieUploadResponse response;
        cookie_handler_.handleUpload(upload, response);
        return response;
    }
    
    // 处理配置同步
    openclaw::ConfigSyncResponse handleConfigSync(
        const openclaw::ConfigSync& sync) {
        openclaw::ConfigSyncResponse response;
        config_handler_.handleSync(sync, response);
        return response;
    }
    
    // 处理心跳
    openclaw::HeartbeatResponse handleHeartbeat(
        const openclaw::Heartbeat& heartbeat) {
        openclaw::HeartbeatResponse response;
        heartbeat_handler_.handleHeartbeat(heartbeat, response);
        return response;
    }
    
    // 获取各处理器
    CredentialHandler& credentialHandler() { return credential_handler_; }
    CookieHandler& cookieHandler() { return cookie_handler_; }
    ConfigHandler& configHandler() { return config_handler_; }
    HeartbeatHandler& heartbeatHandler() { return heartbeat_handler_; }

private:
    CredentialHandler credential_handler_;
    CookieHandler cookie_handler_;
    ConfigHandler config_handler_;
    HeartbeatHandler heartbeat_handler_;
};

} // namespace polyvault