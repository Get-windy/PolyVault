/**
 * @file openclaw_client.cpp
 * @brief OpenClaw Agent通信客户端实现
 */

#include "openclaw_client.hpp"
#include "openclaw.pb.h"
#include <iostream>
#include <sstream>
#include <chrono>
#include <cstring>

// 简化的HTTP客户端（实际项目中应使用libcurl或cpp-httplib）
#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <unistd.h>
#endif

namespace polyvault {
namespace agent {

// ============================================================================
// OpenClawClient实现
// ============================================================================

OpenClawClient::OpenClawClient(const OpenClawAgentConfig& config)
    : config_(config) {
    std::cout << "[OpenClawClient] Created for agent: " << config_.agent_id << std::endl;
}

OpenClawClient::~OpenClawClient() {
    disconnect();
}

bool OpenClawClient::connect() {
    if (state_.connected) {
        return true;
    }
    
    std::cout << "[OpenClawClient] Connecting to: " << config_.gateway_url << std::endl;
    
    // 初始化网络（Windows）
#ifdef _WIN32
    WSADATA wsaData;
    if (WSAStartup(MAKEWORD(2, 2), &wsaData) != 0) {
        std::cerr << "[OpenClawClient] WSAStartup failed" << std::endl;
        return false;
    }
#endif
    
    // 执行认证
    if (!authenticate()) {
        std::cerr << "[OpenClawClient] Authentication failed" << std::endl;
        return false;
    }
    
    state_.connected = true;
    running_ = true;
    
    // 启动心跳线程
    heartbeat_thread_ = std::thread(&OpenClawClient::heartbeatLoop, this);
    
    // 启动接收线程
    receive_thread_ = std::thread(&OpenClawClient::receiveLoop, this);
    
    std::cout << "[OpenClawClient] Connected successfully" << std::endl;
    return true;
}

void OpenClawClient::disconnect() {
    if (!state_.connected) {
        return;
    }
    
    running_ = false;
    state_.connected = false;
    
    if (heartbeat_thread_.joinable()) {
        heartbeat_thread_.join();
    }
    
    if (receive_thread_.joinable()) {
        receive_thread_.join();
    }
    
#ifdef _WIN32
    WSACleanup();
#endif
    
    std::cout << "[OpenClawClient] Disconnected" << std::endl;
}

bool OpenClawClient::isConnected() const {
    return state_.connected;
}

bool OpenClawClient::authenticate() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    state_.auth_state = AuthState::AUTHENTICATING;
    
    // 构建认证请求
    std::string auth_body = R"({"agent_id":")" + config_.agent_id + 
                            R"(","api_key":")" + config_.api_key + R"("})";
    
    std::string response = httpPost("/api/v1/agent/auth", auth_body);
    
    if (response.empty()) {
        state_.auth_state = AuthState::AUTH_FAILED;
        return false;
    }
    
    // 解析响应（简化处理）
    // 实际应使用JSON库解析
    if (response.find("\"success\":true") != std::string::npos) {
        state_.auth_state = AuthState::AUTHENTICATED;
        // 提取token（简化）
        size_t pos = response.find("\"token\":\"");
        if (pos != std::string::npos) {
            pos += 9;
            size_t end = response.find("\"", pos);
            if (end != std::string::npos) {
                state_.session_token = response.substr(pos, end - pos);
            }
        }
        std::cout << "[OpenClawClient] Authenticated successfully" << std::endl;
        return true;
    }
    
    state_.auth_state = AuthState::AUTH_FAILED;
    return false;
}

bool OpenClawClient::refreshToken() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (state_.session_token.empty()) {
        return false;
    }
    
    std::string response = httpPost("/api/v1/agent/refresh", 
                                    R"({"token":")" + state_.session_token + R"("})");
    
    if (response.find("\"success\":true") != std::string::npos) {
        std::cout << "[OpenClawClient] Token refreshed" << std::endl;
        return true;
    }
    
    return false;
}

void OpenClawClient::logout() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (!state_.session_token.empty()) {
        httpPost("/api/v1/agent/logout", 
                 R"({"token":")" + state_.session_token + R"("})");
    }
    
    state_.session_token.clear();
    state_.auth_state = AuthState::UNAUTHENTICATED;
    
    std::cout << "[OpenClawClient] Logged out" << std::endl;
}

AuthState OpenClawClient::getAuthState() const {
    return state_.auth_state;
}

std::unique_ptr<openclaw::CredentialResponse> OpenClawClient::requestCredential(
    const openclaw::CredentialRequest& request) {
    
    if (!state_.connected || state_.auth_state != AuthState::AUTHENTICATED) {
        std::cerr << "[OpenClawClient] Not authenticated" << std::endl;
        return nullptr;
    }
    
    // 序列化请求
    std::string request_body;
    if (!request.SerializeToString(&request_body)) {
        std::cerr << "[OpenClawClient] Failed to serialize request" << std::endl;
        return nullptr;
    }
    
    // 发送请求
    std::string response = httpPost("/api/v1/credentials/request", request_body);
    
    if (response.empty()) {
        return nullptr;
    }
    
    // 解析响应
    auto resp = std::make_unique<openclaw::CredentialResponse>();
    if (resp->ParseFromString(response)) {
        state_.messages_sent++;
        state_.messages_received++;
        return resp;
    }
    
    return nullptr;
}

std::unique_ptr<openclaw::AuthorizationResponse> OpenClawClient::requestAuthorization(
    const openclaw::AuthorizationRequest& request) {
    
    if (!state_.connected || state_.auth_state != AuthState::AUTHENTICATED) {
        return nullptr;
    }
    
    std::string request_body;
    if (!request.SerializeToString(&request_body)) {
        return nullptr;
    }
    
    std::string response = httpPost("/api/v1/authorization/request", request_body);
    
    if (response.empty()) {
        return nullptr;
    }
    
    auto resp = std::make_unique<openclaw::AuthorizationResponse>();
    if (resp->ParseFromString(response)) {
        state_.messages_sent++;
        state_.messages_received++;
        return resp;
    }
    
    return nullptr;
}

bool OpenClawClient::reportEvent(const openclaw::Event& event) {
    if (!state_.connected) {
        return false;
    }
    
    std::string event_body;
    if (!event.SerializeToString(&event_body)) {
        return false;
    }
    
    std::string response = httpPost("/api/v1/events", event_body);
    
    if (!response.empty()) {
        state_.messages_sent++;
        
        // 触发回调
        if (event_callback_) {
            event_callback_(event);
        }
        
        return true;
    }
    
    return false;
}

bool OpenClawClient::reportHeartbeat(const openclaw::DeviceHeartbeat& heartbeat) {
    if (!state_.connected) {
        return false;
    }
    
    std::string hb_body;
    if (!heartbeat.SerializeToString(&hb_body)) {
        return false;
    }
    
    std::string response = httpPost("/api/v1/heartbeat", hb_body);
    
    if (!response.empty()) {
        state_.last_heartbeat = bus::Message::currentTimestamp();
        return true;
    }
    
    return false;
}

void OpenClawClient::setDataBus(bus::DataBus* bus) {
    bus_ = bus;
}

bus::DataBus* OpenClawClient::getDataBus() const {
    return bus_;
}

void OpenClawClient::subscribeToCredentials(
    std::function<void(const openclaw::CredentialResponse&)> callback) {
    credential_callback_ = std::move(callback);
}

void OpenClawClient::subscribeToAuthorizations(
    std::function<void(const openclaw::AuthorizationResponse&)> callback) {
    auth_callback_ = std::move(callback);
}

void OpenClawClient::subscribeToEvents(
    std::function<void(const openclaw::Event&)> callback) {
    event_callback_ = std::move(callback);
}

ClientState OpenClawClient::getState() const {
    return state_;
}

bool OpenClawClient::healthCheck() const {
    return state_.connected && state_.auth_state == AuthState::AUTHENTICATED;
}

void OpenClawClient::heartbeatLoop() {
    std::cout << "[OpenClawClient] Heartbeat thread started" << std::endl;
    
    while (running_ && state_.connected) {
        std::this_thread::sleep_for(std::chrono::milliseconds(config_.heartbeat_interval_ms));
        
        if (!running_ || !state_.connected) break;
        
        // 创建心跳消息
        openclaw::DeviceHeartbeat hb;
        hb.set_device_id(config_.agent_id);
        hb.set_timestamp(bus::Message::currentTimestamp());
        (*hb.mutable_status())["state"] = "running";
        (*hb.mutable_status())["messages_sent"] = std::to_string(state_.messages_sent);
        (*hb.mutable_status())["messages_received"] = std::to_string(state_.messages_received);
        
        // 发送心跳
        if (!reportHeartbeat(hb)) {
            std::cerr << "[OpenClawClient] Heartbeat failed" << std::endl;
        }
    }
    
    std::cout << "[OpenClawClient] Heartbeat thread stopped" << std::endl;
}

void OpenClawClient::receiveLoop() {
    std::cout << "[OpenClawClient] Receive thread started" << std::endl;
    
    while (running_ && state_.connected) {
        // 等待消息或超时
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        
        // 这里应该实现WebSocket或长轮询来接收消息
        // 当前简化实现
    }
    
    std::cout << "[OpenClawClient] Receive thread stopped" << std::endl;
}

std::string OpenClawClient::httpPost(const std::string& path, const std::string& body) {
    // 简化的HTTP POST实现
    // 实际项目中应使用libcurl或cpp-httplib
    
    std::string url = buildUrl(path);
    std::cout << "[OpenClawClient] POST " << url << " (body: " << body.size() << " bytes)" << std::endl;
    
    // 模拟响应
    if (path.find("/auth") != std::string::npos) {
        return R"({"success":true,"token":"mock_token_12345","expires_at":)" + 
               std::to_string(bus::Message::currentTimestamp() + 3600000) + "}";
    }
    
    if (path.find("/heartbeat") != std::string::npos) {
        return R"({"success":true})";
    }
    
    if (path.find("/events") != std::string::npos) {
        return R"({"success":true,"event_id":"evt_123"})";
    }
    
    // 凭证请求模拟响应
    if (path.find("/credentials") != std::string::npos) {
        openclaw::CredentialResponse resp;
        resp.set_request_id("req_123");
        resp.set_status(openclaw::AUTH_STATUS_APPROVED);
        resp.set_encrypted_credential("encrypted_data_here");
        resp.set_timestamp(bus::Message::currentTimestamp());
        
        std::string serialized;
        resp.SerializeToString(&serialized);
        return serialized;
    }
    
    return R"({"success":true})";
}

std::string OpenClawClient::httpGet(const std::string& path) {
    std::string url = buildUrl(path);
    std::cout << "[OpenClawClient] GET " << url << std::endl;
    
    return R"({"success":true})";
}

std::string OpenClawClient::buildUrl(const std::string& path) const {
    return config_.gateway_url + path;
}

// ============================================================================
// OpenClawAgentAdapter实现
// ============================================================================

OpenClawAgentAdapter::OpenClawAgentAdapter(const OpenClawAgentConfig& config)
    : config_(config) {
    client_ = std::make_unique<OpenClawClient>(config_);
}

OpenClawAgentAdapter::~OpenClawAgentAdapter() {
    stop();
}

bool OpenClawAgentAdapter::initialize(bus::DataBus* bus) {
    if (!bus) {
        return false;
    }
    
    bus_ = bus;
    client_->setDataBus(bus);
    
    // 注册消息处理器
    bus_->registerHandler(bus::MessageKind::CREDENTIAL_REQUEST, 
        [this](const bus::Message& msg) { handleCredentialRequest(msg); });
    
    bus_->registerHandler(bus::MessageKind::AUTHORIZATION_REQUEST,
        [this](const bus::Message& msg) { handleAuthorizationRequest(msg); });
    
    bus_->registerHandler(bus::MessageKind::EVENT,
        [this](const bus::Message& msg) { handleEvent(msg); });
    
    bus_->registerHandler(bus::MessageKind::DEVICE_HEARTBEAT,
        [this](const bus::Message& msg) { handleHeartbeat(msg); });
    
    std::cout << "[OpenClawAgentAdapter] Initialized" << std::endl;
    return true;
}

bool OpenClawAgentAdapter::start() {
    if (running_) {
        return true;
    }
    
    if (!client_->connect()) {
        std::cerr << "[OpenClawAgentAdapter] Failed to connect" << std::endl;
        return false;
    }
    
    running_ = true;
    std::cout << "[OpenClawAgentAdapter] Started" << std::endl;
    return true;
}

void OpenClawAgentAdapter::stop() {
    if (!running_) {
        return;
    }
    
    running_ = false;
    client_->disconnect();
    
    std::cout << "[OpenClawAgentAdapter] Stopped" << std::endl;
}

bool OpenClawAgentAdapter::isRunning() const {
    return running_;
}

ClientState OpenClawAgentAdapter::getClientState() const {
    return client_->getState();
}

void OpenClawAgentAdapter::handleCredentialRequest(const bus::Message& msg) {
    std::cout << "[OpenClawAgentAdapter] Handling credential request" << std::endl;
    
    // 解析请求
    openclaw::CredentialRequest request;
    if (!request.ParseFromArray(msg.payload.data(), msg.payload.size())) {
        std::cerr << "[OpenClawAgentAdapter] Failed to parse credential request" << std::endl;
        return;
    }
    
    // 转发到OpenClaw
    auto response = client_->requestCredential(request);
    
    if (response) {
        // 构建响应消息
        bus::Message resp_msg;
        resp_msg.kind = bus::MessageKind::CREDENTIAL_RESPONSE;
        resp_msg.topic = "credential/response";
        resp_msg.message_id = msg.message_id;
        resp_msg.target_id = msg.source_id;
        
        std::string serialized;
        if (response->SerializeToString(&serialized)) {
            resp_msg.payload.assign(serialized.begin(), serialized.end());
            bus_->publish(resp_msg.topic, resp_msg);
        }
    }
}

void OpenClawAgentAdapter::handleAuthorizationRequest(const bus::Message& msg) {
    std::cout << "[OpenClawAgentAdapter] Handling authorization request" << std::endl;
    
    openclaw::AuthorizationRequest request;
    if (!request.ParseFromArray(msg.payload.data(), msg.payload.size())) {
        return;
    }
    
    auto response = client_->requestAuthorization(request);
    
    if (response) {
        bus::Message resp_msg;
        resp_msg.kind = bus::MessageKind::AUTHORIZATION_RESPONSE;
        resp_msg.topic = "authorization/response";
        resp_msg.message_id = msg.message_id;
        resp_msg.target_id = msg.source_id;
        
        std::string serialized;
        if (response->SerializeToString(&serialized)) {
            resp_msg.payload.assign(serialized.begin(), serialized.end());
            bus_->publish(resp_msg.topic, resp_msg);
        }
    }
}

void OpenClawAgentAdapter::handleEvent(const bus::Message& msg) {
    openclaw::Event event;
    if (!event.ParseFromArray(msg.payload.data(), msg.payload.size())) {
        return;
    }
    
    client_->reportEvent(event);
}

void OpenClawAgentAdapter::handleHeartbeat(const bus::Message& msg) {
    openclaw::DeviceHeartbeat hb;
    if (!hb.ParseFromArray(msg.payload.data(), msg.payload.size())) {
        return;
    }
    
    client_->reportHeartbeat(hb);
}

} // namespace agent
} // namespace polyvault