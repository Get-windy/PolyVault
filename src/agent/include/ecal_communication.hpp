/**
 * @file ecal_communication.hpp
 * @brief eCAL通信模块 - 发布者/订阅者封装
 * 
 * 功能：
 * - eCAL初始化管理
 * - Protobuf消息发布/订阅
 * - 跨进程通信支持
 */

#pragma once

#include <string>
#include <memory>
#include <functional>
#include <mutex>
#include <map>
#include <atomic>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#include <ecal/msg/protobuf/publisher.h>
#include <ecal/msg/protobuf/subscriber.h>
#include <ecal/msg/protobuf/server.h>
#include <ecal/msg/protobuf/client.h>
#endif

#include "openclaw.pb.h"

namespace polyvault {
namespace ecal {

/**
 * @brief eCAL通信配置
 */
struct EcalConfig {
    std::string app_name = "PolyVault";     // 应用名称
    std::string unit_name = "agent";        // 单元名称
    bool enable_monitoring = true;          // 启用监控
    int timeout_ms = 5000;                  // 超时时间
};

/**
 * @brief eCAL初始化器 - 管理eCAL生命周期
 */
class EcalInitializer {
public:
    static EcalInitializer& instance() {
        static EcalInitializer inst;
        return inst;
    }
    
    bool initialize(const EcalConfig& config = {}) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (initialized_) {
            ref_count_++;
            return true;
        }
        
#ifdef USE_ECAL
        // 设置eCAL配置
        eCAL::Initialize(0, nullptr, config.app_name.c_str());
        
        // 设置单元名称
        eCAL::Process::SetUnitName(config.unit_name);
        
        // 启用监控
        if (config.enable_monitoring) {
            eCAL::Monitoring::EnableProfiling(eCAL::eCAL_pb_monitoring_rich);
        }
        
        initialized_ = true;
        ref_count_ = 1;
        
        std::cout << "[eCAL] Initialized: " << config.app_name << std::endl;
        return true;
#else
        std::cerr << "[eCAL] eCAL not available, compiled without USE_ECAL" << std::endl;
        return false;
#endif
    }
    
    void finalize() {
        std::lock_guard<std::mutex> lock(mutex_);
        
        if (!initialized_) return;
        
        ref_count_--;
        if (ref_count_ <= 0) {
#ifdef USE_ECAL
            eCAL::Finalize();
            initialized_ = false;
            std::cout << "[eCAL] Finalized" << std::endl;
#endif
        }
    }
    
    bool isInitialized() const { return initialized_; }
    
private:
    EcalInitializer() = default;
    ~EcalInitializer() { finalize(); }
    
    std::mutex mutex_;
    bool initialized_ = false;
    int ref_count_ = 0;
};

// ============================================================================
// 消息类型定义
// ============================================================================

/**
 * @brief 凭证请求回调
 */
using CredentialRequestCallback = std::function<openclaw::CredentialResponse(
    const openclaw::CredentialRequest&)>;

/**
 * @brief Cookie请求回调
 */
using CookieRequestCallback = std::function<openclaw::CookieDownloadResponse(
    const openclaw::CookieDownloadRequest&)>;

/**
 * @brief 授权请求回调
 */
using AuthRequestCallback = std::function<openclaw::AuthorizationResponse(
    const openclaw::AuthorizationRequest&)>;

// ============================================================================
// eCAL发布者封装
// ============================================================================

/**
 * @brief 凭证响应发布者
 */
class CredentialResponsePublisher {
public:
    explicit CredentialResponsePublisher(const std::string& topic = "polyvault/credential_response")
        : topic_(topic) {
#ifdef USE_ECAL
        EcalInitializer::instance().initialize();
        publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::CredentialResponse>>(topic_);
        std::cout << "[eCAL] Publisher created: " << topic_ << std::endl;
#endif
    }
    
    ~CredentialResponsePublisher() {
#ifdef USE_ECAL
        publisher_.reset();
        EcalInitializer::instance().finalize();
#endif
    }
    
    bool publish(const openclaw::CredentialResponse& response) {
#ifdef USE_ECAL
        if (publisher_) {
            auto sent = publisher_->Send(response);
            return sent > 0;
        }
#endif
        return false;
    }
    
    const std::string& topic() const { return topic_; }
    
private:
    std::string topic_;
#ifdef USE_ECAL
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::CredentialResponse>> publisher_;
#endif
};

/**
 * @brief Cookie上传发布者
 */
class CookieUploadPublisher {
public:
    explicit CookieUploadPublisher(const std::string& topic = "polyvault/cookie_upload")
        : topic_(topic) {
#ifdef USE_ECAL
        EcalInitializer::instance().initialize();
        publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::CookieUploadRequest>>(topic_);
#endif
    }
    
    ~CookieUploadPublisher() {
#ifdef USE_ECAL
        publisher_.reset();
        EcalInitializer::instance().finalize();
#endif
    }
    
    bool publish(const openclaw::CookieUploadRequest& request) {
#ifdef USE_ECAL
        if (publisher_) {
            return publisher_->Send(request) > 0;
        }
#endif
        return false;
    }
    
private:
    std::string topic_;
#ifdef USE_ECAL
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::CookieUploadRequest>> publisher_;
#endif
};

/**
 * @brief 事件发布者 - 用于通知
 */
class EventPublisher {
public:
    explicit EventPublisher(const std::string& topic = "polyvault/events")
        : topic_(topic) {
#ifdef USE_ECAL
        EcalInitializer::instance().initialize();
        publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::Event>>(topic_);
#endif
    }
    
    ~EventPublisher() {
#ifdef USE_ECAL
        publisher_.reset();
        EcalInitializer::instance().finalize();
#endif
    }
    
    bool publishEvent(openclaw::EventType type, const std::string& deviceId, 
                      const std::string& message) {
#ifdef USE_ECAL
        if (publisher_) {
            openclaw::Event event;
            event.set_event_id(generateEventId());
            event.set_type(type);
            event.set_device_id(deviceId);
            event.set_timestamp(currentTimestamp());
            event.set_message(message);
            
            return publisher_->Send(event) > 0;
        }
#endif
        return false;
    }
    
private:
    std::string topic_;
#ifdef USE_ECAL
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::Event>> publisher_;
#endif
    
    std::string generateEventId() {
        static std::atomic<uint64_t> counter{0};
        return "evt_" + std::to_string(++counter);
    }
    
    uint64_t currentTimestamp() {
        return std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
    }
};

// ============================================================================
// eCAL订阅者封装
// ============================================================================

/**
 * @brief 凭证请求订阅者
 */
class CredentialRequestSubscriber {
public:
    explicit CredentialRequestSubscriber(const std::string& topic = "polyvault/credential_request")
        : topic_(topic) {
#ifdef USE_ECAL
        EcalInitializer::instance().initialize();
        subscriber_ = std::make_unique<eCAL::protobuf::CSubscriber<openclaw::CredentialRequest>>(topic_);
        std::cout << "[eCAL] Subscriber created: " << topic_ << std::endl;
#endif
    }
    
    ~CredentialRequestSubscriber() {
#ifdef USE_ECAL
        subscriber_.reset();
        EcalInitializer::instance().finalize();
#endif
    }
    
    void setCallback(CredentialRequestCallback callback) {
#ifdef USE_ECAL
        callback_ = std::move(callback);
        if (subscriber_ && callback_) {
            subscriber_->AddReceiveCallback(
                [this](const char* topic, const openclaw::CredentialRequest& request) {
                    if (callback_) {
                        auto response = callback_(request);
                        // 可以在这里添加发布响应的逻辑
                    }
                });
        }
#endif
    }
    
private:
    std::string topic_;
    CredentialRequestCallback callback_;
#ifdef USE_ECAL
    std::unique_ptr<eCAL::protobuf::CSubscriber<openclaw::CredentialRequest>> subscriber_;
#endif
};

/**
 * @brief Cookie下载请求订阅者
 */
class CookieRequestSubscriber {
public:
    explicit CookieRequestSubscriber(const std::string& topic = "polyvault/cookie_download")
        : topic_(topic) {
#ifdef USE_ECAL
        EcalInitializer::instance().initialize();
        subscriber_ = std::make_unique<eCAL::protobuf::CSubscriber<openclaw::CookieDownloadRequest>>(topic_);
#endif
    }
    
    ~CookieRequestSubscriber() {
#ifdef USE_ECAL
        subscriber_.reset();
        EcalInitializer::instance().finalize();
#endif
    }
    
    void setCallback(CookieRequestCallback callback) {
#ifdef USE_ECAL
        callback_ = std::move(callback);
        if (subscriber_ && callback_) {
            subscriber_->AddReceiveCallback(
                [this](const char* topic, const openclaw::CookieDownloadRequest& request) {
                    if (callback_) {
                        callback_(request);
                    }
                });
        }
#endif
    }
    
private:
    std::string topic_;
    CookieRequestCallback callback_;
#ifdef USE_ECAL
    std::unique_ptr<eCAL::protobuf::CSubscriber<openclaw::CookieDownloadRequest>> subscriber_;
#endif
};

// ============================================================================
// eCAL服务端封装 (RPC风格)
// ============================================================================

#ifdef USE_ECAL
/**
 * @brief 凭证服务实现
 */
class CredentialServiceImpl : public openclaw::CredentialService {
public:
    void GetCredential(const openclaw::CredentialRequest& request,
                       openclaw::CredentialResponse& response) override {
        if (credential_callback_) {
            response = credential_callback_(request);
        } else {
            response.set_success(false);
            response.set_error_message("No callback registered");
        }
    }
    
    void StoreCredential(const openclaw::CredentialStoreRequest& request,
                         openclaw::CredentialStoreResponse& response) override {
        // TODO: 实现存储逻辑
        response.set_success(true);
    }
    
    void DeleteCredential(const openclaw::CredentialDeleteRequest& request,
                          openclaw::CredentialDeleteResponse& response) override {
        // TODO: 实现删除逻辑
        response.set_success(true);
    }
    
    void UploadCookie(const openclaw::CookieUploadRequest& request,
                      openclaw::CookieUploadResponse& response) override {
        // TODO: 实现Cookie上传逻辑
        response.set_success(true);
    }
    
    void DownloadCookie(const openclaw::CookieDownloadRequest& request,
                        openclaw::CookieDownloadResponse& response) override {
        if (cookie_callback_) {
            response = cookie_callback_(request);
        } else {
            response.set_success(false);
            response.set_error_message("No callback registered");
        }
    }
    
    void setCredentialCallback(CredentialRequestCallback cb) {
        credential_callback_ = std::move(cb);
    }
    
    void setCookieCallback(CookieRequestCallback cb) {
        cookie_callback_ = std::move(cb);
    }
    
private:
    CredentialRequestCallback credential_callback_;
    CookieRequestCallback cookie_callback_;
};
#endif

/**
 * @brief eCAL凭证服务端
 */
class CredentialServer {
public:
    explicit CredentialServer(const std::string& service_name = "polyvault_credential_service") {
#ifdef USE_ECAL
        EcalInitializer::instance().initialize();
        service_impl_ = std::make_unique<CredentialServiceImpl>();
        server_ = std::make_unique<eCAL::protobuf::CServer<openclaw::CredentialService>>(
            service_name, service_impl_.get());
        std::cout << "[eCAL] Server created: " << service_name << std::endl;
#endif
    }
    
    ~CredentialServer() {
#ifdef USE_ECAL
        server_.reset();
        service_impl_.reset();
        EcalInitializer::instance().finalize();
#endif
    }
    
    void setCredentialCallback(CredentialRequestCallback callback) {
#ifdef USE_ECAL
        if (service_impl_) {
            service_impl_->setCredentialCallback(std::move(callback));
        }
#endif
    }
    
    void setCookieCallback(CookieRequestCallback callback) {
#ifdef USE_ECAL
        if (service_impl_) {
            service_impl_->setCookieCallback(std::move(callback));
        }
#endif
    }
    
private:
#ifdef USE_ECAL
    std::unique_ptr<CredentialServiceImpl> service_impl_;
    std::unique_ptr<eCAL::protobuf::CServer<openclaw::CredentialService>> server_;
#endif
};

// ============================================================================
// eCAL客户端封装
// ============================================================================

/**
 * @brief 凭证服务客户端
 */
class CredentialClient {
public:
    explicit CredentialClient(const std::string& service_name = "polyvault_credential_service")
        : service_name_(service_name) {
#ifdef USE_ECAL
        EcalInitializer::instance().initialize();
        client_ = std::make_unique<eCAL::protobuf::CClient<openclaw::CredentialService>>(service_name);
        std::cout << "[eCAL] Client created: " << service_name << std::endl;
#endif
    }
    
    ~CredentialClient() {
#ifdef USE_ECAL
        client_.reset();
        EcalInitializer::instance().finalize();
#endif
    }
    
    bool getCredential(const openclaw::CredentialRequest& request,
                       openclaw::CredentialResponse& response,
                       int timeout_ms = 5000) {
#ifdef USE_ECAL
        if (client_) {
            return client_->Call("GetCredential", request, response, timeout_ms);
        }
#endif
        return false;
    }
    
    bool storeCredential(const openclaw::CredentialStoreRequest& request,
                         openclaw::CredentialStoreResponse& response,
                         int timeout_ms = 5000) {
#ifdef USE_ECAL
        if (client_) {
            return client_->Call("StoreCredential", request, response, timeout_ms);
        }
#endif
        return false;
    }
    
    bool uploadCookie(const openclaw::CookieUploadRequest& request,
                      openclaw::CookieUploadResponse& response,
                      int timeout_ms = 5000) {
#ifdef USE_ECAL
        if (client_) {
            return client_->Call("UploadCookie", request, response, timeout_ms);
        }
#endif
        return false;
    }
    
    bool downloadCookie(const openclaw::CookieDownloadRequest& request,
                        openclaw::CookieDownloadResponse& response,
                        int timeout_ms = 5000) {
#ifdef USE_ECAL
        if (client_) {
            return client_->Call("DownloadCookie", request, response, timeout_ms);
        }
#endif
        return false;
    }
    
private:
    std::string service_name_;
#ifdef USE_ECAL
    std::unique_ptr<eCAL::protobuf::CClient<openclaw::CredentialService>> client_;
#endif
};

} // namespace ecal
} // namespace polyvault