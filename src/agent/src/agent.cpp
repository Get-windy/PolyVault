/**
 * @file agent.cpp
 * @brief PolyVault Agent实现
 */

#include "agent.hpp"
#include "message_handler.hpp"
#include <iostream>
#include <chrono>
#include <thread>

namespace polyvault {

// 前向声明实现类
class Agent::Impl {
public:
    explicit Impl(const AgentConfig& config) 
        : config_(config) {}
    
    ~Impl() {
        stop();
    }
    
    bool initialize() {
#ifdef USE_ECAL
        if (config_.use_ecal) {
            // 初始化eCAL
            eCAL::Initialize(0, nullptr, "PolyVaultAgent");
            
            // 创建订阅者 - 监听凭证请求
            request_subscriber_ = std::make_unique<eCAL::protobuf::CSubscriber<openclaw::CredentialRequest>>(
                "polyvault/credential_request");
            
            // 创建发布者 - 发送凭证响应
            response_publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::CredentialResponse>>(
                "polyvault/credential_response");
            
            // 创建Cookie订阅者
            cookie_subscriber_ = std::make_unique<eCAL::protobuf::CSubscriber<openclaw::CookieUpload>>(
                "polyvault/cookie_upload");
            
            // 创建Cookie响应发布者
            cookie_response_publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::CookieUploadResponse>>(
                "polyvault/cookie_upload_response");
            
            // 创建心跳订阅者
            heartbeat_subscriber_ = std::make_unique<eCAL::protobuf::CSubscriber<openclaw::Heartbeat>>(
                "polyvault/heartbeat");
            
            // 创建心跳响应发布者
            heartbeat_response_publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::HeartbeatResponse>>(
                "polyvault/heartbeat_response");
            
            // 创建配置订阅者
            config_subscriber_ = std::make_unique<eCAL::protobuf::CSubscriber<openclaw::ConfigSync>>(
                "polyvault/config_sync");
            
            // 创建配置响应发布者
            config_response_publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::ConfigSyncResponse>>(
                "polyvault/config_sync_response");
            
            std::cout << "[Agent] eCAL initialized" << std::endl;
            std::cout << "[Agent] Agent ID: " << config_.agent_id << std::endl;
            std::cout << "[Agent] Subscribed topics:" << std::endl;
            std::cout << "[Agent]   - polyvault/credential_request" << std::endl;
            std::cout << "[Agent]   - polyvault/cookie_upload" << std::endl;
            std::cout << "[Agent]   - polyvault/heartbeat" << std::endl;
            std::cout << "[Agent]   - polyvault/config_sync" << std::endl;
            
            return true;
        }
#endif
        
        // 非eCAL模式
        std::cout << "[Agent] Non-eCAL mode initialized" << std::endl;
        std::cout << "[Agent] Agent ID: " << config_.agent_id << std::endl;
        std::cout << "[Agent] Listen port: " << config_.listen_port << std::endl;
        return true;
    }
    
    void start() {
        if (running_) {
            return;
        }
        
        running_ = true;
        
#ifdef USE_ECAL
        if (config_.use_ecal) {
            // 注册凭证请求回调
            if (request_subscriber_) {
                request_subscriber_->AddReceiveCallback(
                    [this](const char* topic_name, const openclaw::CredentialRequest& request) {
                        handleCredentialRequest(request);
                    });
            }
            
            // 注册Cookie上传回调
            if (cookie_subscriber_) {
                cookie_subscriber_->AddReceiveCallback(
                    [this](const char* topic_name, const openclaw::CookieUpload& upload) {
                        handleCookieUpload(upload);
                    });
            }
            
            // 注册心跳回调
            if (heartbeat_subscriber_) {
                heartbeat_subscriber_->AddReceiveCallback(
                    [this](const char* topic_name, const openclaw::Heartbeat& heartbeat) {
                        handleHeartbeat(heartbeat);
                    });
            }
            
            // 注册配置同步回调
            if (config_subscriber_) {
                config_subscriber_->AddReceiveCallback(
                    [this](const char* topic_name, const openclaw::ConfigSync& sync) {
                        handleConfigSync(sync);
                    });
            }
            
            std::cout << "[Agent] Started, listening for messages..." << std::endl;
            
            // 主循环
            while (running_ && eCAL::Ok()) {
                eCAL::Process::SleepMS(100);
            }
        } else
#endif
        {
            // 非eCAL模式的主循环
            std::cout << "[Agent] Started in standalone mode" << std::endl;
            while (running_) {
                std::this_thread::sleep_for(std::chrono::milliseconds(100));
            }
        }
    }
    
    void stop() {
        if (!running_) {
            return;
        }
        
        running_ = false;
        
#ifdef USE_ECAL
        if (config_.use_ecal) {
            request_subscriber_.reset();
            response_publisher_.reset();
            cookie_subscriber_.reset();
            cookie_response_publisher_.reset();
            heartbeat_subscriber_.reset();
            heartbeat_response_publisher_.reset();
            config_subscriber_.reset();
            config_response_publisher_.reset();
            eCAL::Finalize();
            
            std::cout << "[Agent] Stopped" << std::endl;
        }
#endif
    }
    
    void setCredentialCallback(CredentialCallback callback) {
        credential_callback_ = std::move(callback);
    }
    
    void setMessageHandlerManager(MessageHandlerManager* manager) {
        handler_manager_ = manager;
    }
    
    bool isRunning() const { return running_; }

private:
    AgentConfig config_;
    bool running_ = false;
    CredentialCallback credential_callback_;
    MessageHandlerManager* handler_manager_ = nullptr;
    
#ifdef USE_ECAL
    // eCAL订阅者/发布者
    std::unique_ptr<eCAL::protobuf::CSubscriber<openclaw::CredentialRequest>> request_subscriber_;
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::CredentialResponse>> response_publisher_;
    std::unique_ptr<eCAL::protobuf::CSubscriber<openclaw::CookieUpload>> cookie_subscriber_;
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::CookieUploadResponse>> cookie_response_publisher_;
    std::unique_ptr<eCAL::protobuf::CSubscriber<openclaw::Heartbeat>> heartbeat_subscriber_;
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::HeartbeatResponse>> heartbeat_response_publisher_;
    std::unique_ptr<eCAL::protobuf::CSubscriber<openclaw::ConfigSync>> config_subscriber_;
    std::unique_ptr<eCAL::protobuf::CPublisher<openclaw::ConfigSyncResponse>> config_response_publisher_;
#endif
    
    void handleCredentialRequest(const openclaw::CredentialRequest& request) {
        std::cout << "[Agent] Received credential request for: " << request.service_url() << std::endl;
        
        openclaw::CredentialResponse response;
        
        if (handler_manager_) {
            response = handler_manager_->handleCredentialRequest(request);
        } else if (credential_callback_) {
            response = credential_callback_(request);
        } else {
            response.set_session_id(request.session_id());
            response.set_success(false);
            response.set_error_message("No handler registered");
        }
        
#ifdef USE_ECAL
        if (response_publisher_) {
            response_publisher_->Send(response);
            std::cout << "[Agent] Sent credential response for session: " 
                      << response.session_id() << std::endl;
        }
#endif
    }
    
    void handleCookieUpload(const openclaw::CookieUpload& upload) {
        std::cout << "[Agent] Received cookie upload, count: " << upload.cookies_size() << std::endl;
        
        if (handler_manager_) {
            auto response = handler_manager_->handleCookieUpload(upload);
#ifdef USE_ECAL
            if (cookie_response_publisher_) {
                cookie_response_publisher_->Send(response);
                std::cout << "[Agent] Sent cookie upload response" << std::endl;
            }
#endif
        }
    }
    
    void handleHeartbeat(const openclaw::Heartbeat& heartbeat) {
        std::cout << "[Agent] Received heartbeat from: " << heartbeat.agent_id() << std::endl;
        
        if (handler_manager_) {
            auto response = handler_manager_->handleHeartbeat(heartbeat);
#ifdef USE_ECAL
            if (heartbeat_response_publisher_) {
                heartbeat_response_publisher_->Send(response);
            }
#endif
        }
    }
    
    void handleConfigSync(const openclaw::ConfigSync& sync) {
        std::cout << "[Agent] Received config sync, entries: " << sync.entries_size() << std::endl;
        
        if (handler_manager_) {
            auto response = handler_manager_->handleConfigSync(sync);
#ifdef USE_ECAL
            if (config_response_publisher_) {
                config_response_publisher_->Send(response);
            }
#endif
        }
    }
};

// Agent公共接口实现
Agent::Agent(const AgentConfig& config)
    : impl_(std::make_unique<Impl>(config)) {}

Agent::~Agent() = default;

bool Agent::initialize() {
    return impl_->initialize();
}

void Agent::start() {
    impl_->start();
}

void Agent::stop() {
    impl_->stop();
}

void Agent::setCredentialCallback(CredentialCallback callback) {
    impl_->setCredentialCallback(std::move(callback));
}

bool Agent::isRunning() const {
    return impl_->isRunning();
}

void Agent::setMessageHandlerManager(MessageHandlerManager* manager) {
    impl_->setMessageHandlerManager(manager);
}

} // namespace polyvault