/**
 * @file agent.cpp
 * @brief PolyVault Agent实现
 */

#include "agent.hpp"
#include <iostream>
#include <chrono>

namespace polyvault {

Agent::Agent(const AgentConfig& config)
    : config_(config) {
}

Agent::~Agent() {
    stop();
}

bool Agent::initialize() {
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
        
        // 创建Cookie上传发布者
        cookie_publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::CookieUpload>>(
            "polyvault/cookie_upload");
        
        std::cout << "[Agent] eCAL initialized" << std::endl;
        std::cout << "[Agent] Agent ID: " << config_.agent_id << std::endl;
        
        return true;
    }
#endif
    
    // 非eCAL模式（TODO: 实现TCP/UDP通信）
    std::cout << "[Agent] Non-eCAL mode not yet implemented" << std::endl;
    return false;
}

void Agent::start() {
    if (running_) {
        return;
    }
    
    running_ = true;
    
#ifdef USE_ECAL
    if (config_.use_ecal && request_subscriber_) {
        // 注册回调
        request_subscriber_->AddReceiveCallback(
            [this](const char* topic_name, const openclaw::CredentialRequest& request) {
                this->handleCredentialRequest(request);
            });
        
        std::cout << "[Agent] Started, listening for credential requests..." << std::endl;
        
        // 主循环
        while (running_ && eCAL::Ok()) {
            eCAL::Process::SleepMS(100);
        }
    }
#endif
}

void Agent::stop() {
    if (!running_) {
        return;
    }
    
    running_ = false;
    
#ifdef USE_ECAL
    if (config_.use_ecal) {
        request_subscriber_.reset();
        response_publisher_.reset();
        cookie_publisher_.reset();
        eCAL::Finalize();
        
        std::cout << "[Agent] Stopped" << std::endl;
    }
#endif
}

void Agent::setCredentialCallback(CredentialCallback callback) {
    credential_callback_ = std::move(callback);
}

#ifdef USE_ECAL
void Agent::handleCredentialRequest(const openclaw::CredentialRequest& request) {
    std::cout << "[Agent] Received credential request for: " << request.service_url() << std::endl;
    
    openclaw::CredentialResponse response;
    response.set_session_id(request.session_id());
    
    if (credential_callback_) {
        // 调用用户回调处理请求
        response = credential_callback_(request);
    } else {
        // 没有注册回调，返回错误
        response.set_success(false);
        response.set_error_message("No credential callback registered");
    }
    
    // 发送响应
    if (response_publisher_) {
        response_publisher_->Send(response);
        std::cout << "[Agent] Sent response for session: " << response.session_id() << std::endl;
    }
}
#endif

} // namespace polyvault