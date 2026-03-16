/**
 * @file p2p_communication.cpp
 * @brief PolyVault P2P通信模块实现
 */

#include "p2p_communication.hpp"
#include <iostream>
#include <sstream>
#include <random>
#include <algorithm>
#include <cstring>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
#else
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <unistd.h>
#endif

namespace polyvault {
namespace p2p {

// ============================================================================
// 构造函数/析构函数
// ============================================================================

P2PCommunication::P2PCommunication(const P2PConfig& config)
    : config_(config)
    , initialized_(false)
    , running_(false)
    , messages_sent_(0)
    , messages_received_(0)
    , bytes_sent_(0)
    , bytes_received_(0)
    , message_id_counter_(0)
{
    if (config_.node_id.empty()) {
        config_.node_id = utils::generateDeviceId();
    }
    
    std::cout << "[P2P] Created with node_id: " << config_.node_id << std::endl;
}

P2PCommunication::~P2PCommunication() {
    shutdown();
}

// ============================================================================
// 生命周期管理
// ============================================================================

bool P2PCommunication::initialize() {
    if (initialized_) {
        return true;
    }
    
    std::cout << "[P2P] Initializing..." << std::endl;
    
#ifdef USE_ECAL
    // 初始化eCAL
    eCAL::Initialize(config_.node_id, "PolyVault P2P", eCAL::Init::All);
    
    // 设置发布者和订阅者
    setupECALPublishers();
    setupECALSubscribers();
    setupECALServices();
    
    std::cout << "[P2P] eCAL initialized successfully" << std::endl;
#else
    std::cout << "[P2P] Running without eCAL (fallback mode)" << std::endl;
#endif
    
    initialized_ = true;
    return true;
}

bool P2PCommunication::start() {
    if (!initialized_) {
        std::cerr << "[P2P] Not initialized" << std::endl;
        return false;
    }
    
    if (running_) {
        return true;
    }
    
    std::cout << "[P2P] Starting..." << std::endl;
    
    running_ = true;
    
    // 启动工作线程
    discovery_thread_ = std::thread(&P2PCommunication::discoveryLoop, this);
    heartbeat_thread_ = std::thread(&P2PCommunication::heartbeatLoop, this);
    receive_thread_ = std::thread(&P2PCommunication::receiveLoop, this);
    
    std::cout << "[P2P] Started successfully" << std::endl;
    return true;
}

void P2PCommunication::stop() {
    if (!running_) {
        return;
    }
    
    std::cout << "[P2P] Stopping..." << std::endl;
    
    running_ = false;
    
    // 等待线程结束
    if (discovery_thread_.joinable()) {
        discovery_thread_.join();
    }
    if (heartbeat_thread_.joinable()) {
        heartbeat_thread_.join();
    }
    if (receive_thread_.joinable()) {
        receive_thread_.join();
    }
    
    // 断开所有连接
    {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        connections_.clear();
    }
    
    std::cout << "[P2P] Stopped" << std::endl;
}

void P2PCommunication::shutdown() {
    stop();
    
#ifdef USE_ECAL
    publisher_.reset();
    subscriber_.reset();
    eCAL::Finalize();
#endif
    
    initialized_ = false;
    std::cout << "[P2P] Shutdown complete" << std::endl;
}

// ============================================================================
// 设备发现
// ============================================================================

void P2PCommunication::startDiscovery() {
    std::cout << "[P2P] Starting device discovery..." << std::endl;
    
#ifdef USE_ECAL
    // eCAL自动发现机制
    // 发布设备信息
    openclaw::P2PEnvelope envelope;
    envelope.set_source_id(config_.node_id);
    envelope.set_message_type("discovery");
    envelope.set_timestamp(currentTimestamp());
    
    auto* discovery = envelope.mutable_discovery();
    discovery->set_device_name(config_.node_name);
    discovery->set_device_type("desktop"); // TODO: 根据平台设置
    discovery->add_capabilities("credential_provider");
    discovery->add_capabilities("data_sync");
    
    if (publisher_) {
        publisher_->Send(envelope);
    }
#endif
}

void P2PCommunication::stopDiscovery() {
    std::cout << "[P2P] Stopping device discovery" << std::endl;
}

std::vector<DeviceInfo> P2PCommunication::getDiscoveredDevices() const {
    std::lock_guard<std::mutex> lock(devices_mutex_);
    
    std::vector<DeviceInfo> result;
    for (const auto& [id, info] : discovered_devices_) {
        result.push_back(info);
    }
    return result;
}

std::optional<DeviceInfo> P2PCommunication::getDeviceInfo(const DeviceId& device_id) const {
    std::lock_guard<std::mutex> lock(devices_mutex_);
    
    auto it = discovered_devices_.find(device_id);
    if (it != discovered_devices_.end()) {
        return it->second;
    }
    return std::nullopt;
}

// ============================================================================
// 连接管理
// ============================================================================

bool P2PCommunication::connectToDevice(const DeviceId& device_id) {
    std::cout << "[P2P] Connecting to device: " << device_id << std::endl;
    
    // 检查是否已连接
    {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        auto it = connections_.find(device_id);
        if (it != connections_.end() && it->second.state == ConnectionState::AUTHENTICATED) {
            std::cout << "[P2P] Already connected to: " << device_id << std::endl;
            return true;
        }
    }
    
    // 获取设备信息
    auto device_info = getDeviceInfo(device_id);
    if (!device_info) {
        std::cerr << "[P2P] Device not found: " << device_id << std::endl;
        return false;
    }
    
    // 创建连接记录
    {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        P2PConnection conn;
        conn.device_id = device_id;
        conn.endpoint = device_info->endpoint;
        conn.state = ConnectionState::CONNECTING;
        conn.established_at = currentTimestamp();
        conn.last_activity = currentTimestamp();
        connections_[device_id] = conn;
    }
    
    // 执行握手
    if (!performHandshake(device_id)) {
        std::cerr << "[P2P] Handshake failed: " << device_id << std::endl;
        {
            std::lock_guard<std::mutex> lock(connections_mutex_);
            connections_.erase(device_id);
        }
        return false;
    }
    
    // 执行认证
    if (!authenticateConnection(device_id)) {
        std::cerr << "[P2P] Authentication failed: " << device_id << std::endl;
        {
            std::lock_guard<std::mutex> lock(connections_mutex_);
            connections_.erase(device_id);
        }
        return false;
    }
    
    // 更新连接状态
    {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        connections_[device_id].state = ConnectionState::AUTHENTICATED;
    }
    
    std::cout << "[P2P] Connected to: " << device_id << std::endl;
    
    // 触发回调
    if (connection_callback_) {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        connection_callback_(connections_[device_id], ConnectionState::AUTHENTICATED);
    }
    
    return true;
}

void P2PCommunication::disconnectFromDevice(const DeviceId& device_id) {
    std::cout << "[P2P] Disconnecting from: " << device_id << std::endl;
    
    // 发送断开消息
    sendMessage(device_id, MessageType::DISCONNECT, {});
    
    // 移除连接
    {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        connections_.erase(device_id);
    }
    
    // 触发回调
    if (connection_callback_) {
        P2PConnection conn;
        conn.device_id = device_id;
        conn.state = ConnectionState::DISCONNECTED;
        connection_callback_(conn, ConnectionState::DISCONNECTED);
    }
}

std::vector<P2PConnection> P2PCommunication::getActiveConnections() const {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    
    std::vector<P2PConnection> result;
    for (const auto& [id, conn] : connections_) {
        if (conn.state == ConnectionState::AUTHENTICATED) {
            result.push_back(conn);
        }
    }
    return result;
}

ConnectionState P2PCommunication::getConnectionState(const DeviceId& device_id) const {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    
    auto it = connections_.find(device_id);
    if (it != connections_.end()) {
        return it->second.state;
    }
    return ConnectionState::DISCONNECTED;
}

// ============================================================================
// 消息发送
// ============================================================================

bool P2PCommunication::sendMessage(const DeviceId& target_id, 
                                    MessageType type,
                                    const std::vector<uint8_t>& payload) {
    P2PMessage msg = createMessage(type, payload);
    msg.header.target_id = target_id;
    
    // 获取会话密钥并加密
    {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        auto it = connections_.find(target_id);
        if (it != connections_.end() && !it->second.session_key.empty()) {
            encryptPayload(msg.payload, it->second.session_key);
            msg.encrypted = true;
        }
    }
    
    // 序列化消息
    std::vector<uint8_t> buffer;
    if (!serializeMessage(msg, buffer)) {
        std::cerr << "[P2P] Failed to serialize message" << std::endl;
        return false;
    }
    
#ifdef USE_ECAL
    // 通过eCAL发送
    openclaw::P2PEnvelope envelope;
    envelope.set_source_id(config_.node_id);
    envelope.set_target_id(target_id);
    envelope.set_message_id(msg.header.message_id);
    envelope.set_timestamp(msg.header.timestamp);
    envelope.set_payload(buffer.data(), buffer.size());
    
    if (publisher_) {
        publisher_->Send(envelope);
    }
#endif
    
    // 更新统计
    {
        std::lock_guard<std::mutex> lock(stats_mutex_);
        messages_sent_++;
        bytes_sent_ += buffer.size();
    }
    
    // 更新连接活动时间
    {
        std::lock_guard<std::mutex> lock(connections_mutex_);
        auto it = connections_.find(target_id);
        if (it != connections_.end()) {
            it->second.last_activity = currentTimestamp();
            it->second.bytes_sent += buffer.size();
        }
    }
    
    return true;
}

std::optional<P2PMessage> P2PCommunication::sendRequest(const DeviceId& target_id,
                                                         MessageType type,
                                                         const std::vector<uint8_t>& payload,
                                                         int timeout_ms) {
    // TODO: 实现请求-响应模式
    // 使用 promise/future 等待响应
    sendMessage(target_id, type, payload);
    return std::nullopt; // 简化实现
}

void P2PCommunication::broadcastMessage(MessageType type, 
                                         const std::vector<uint8_t>& payload) {
    auto connections = getActiveConnections();
    for (const auto& conn : connections) {
        sendMessage(conn.device_id, type, payload);
    }
}

// ============================================================================
// 凭证操作
// ============================================================================

std::optional<openclaw::CredentialResponse> P2PCommunication::requestCredential(
    const DeviceId& target_device,
    const std::string& service_url,
    const std::string& session_id,
    int timeout_ms
) {
    std::cout << "[P2P] Requesting credential for: " << service_url << std::endl;
    
    // 创建凭证请求
    openclaw::CredentialRequest request;
    request.set_service_url(service_url);
    request.set_session_id(session_id);
    request.set_timestamp(currentTimestamp());
    
    // 序列化请求
    std::vector<uint8_t> payload(request.ByteSizeLong());
    request.SerializeToArray(payload.data(), payload.size());
    
    // 发送请求
    auto response = sendRequest(target_device, MessageType::CREDENTIAL_REQUEST, 
                                 payload, timeout_ms);
    
    if (!response) {
        return std::nullopt;
    }
    
    // 解析响应
    openclaw::CredentialResponse cred_response;
    if (cred_response.ParseFromArray(response->payload.data(), 
                                      response->payload.size())) {
        return cred_response;
    }
    
    return std::nullopt;
}

bool P2PCommunication::uploadCookie(const DeviceId& target_device,
                                     const std::string& service_url,
                                     const std::vector<uint8_t>& encrypted_cookie,
                                     const std::string& session_id) {
    openclaw::CookieUpload upload;
    upload.set_service_url(service_url);
    upload.set_encrypted_cookie(encrypted_cookie.data(), encrypted_cookie.size());
    upload.set_session_id(session_id);
    
    std::vector<uint8_t> payload(upload.ByteSizeLong());
    upload.SerializeToArray(payload.data(), payload.size());
    
    return sendMessage(target_device, MessageType::COOKIE_UPLOAD, payload);
}

// ============================================================================
// 回调注册
// ============================================================================

void P2PCommunication::setMessageCallback(MessageCallback callback) {
    message_callback_ = std::move(callback);
}

void P2PCommunication::setDeviceCallback(DeviceCallback callback) {
    device_callback_ = std::move(callback);
}

void P2PCommunication::setConnectionCallback(ConnectionCallback callback) {
    connection_callback_ = std::move(callback);
}

// ============================================================================
// 状态查询
// ============================================================================

DeviceInfo P2PCommunication::getLocalDeviceInfo() const {
    DeviceInfo info;
    info.device_id = config_.node_id;
    info.device_name = config_.node_name;
    info.device_type = "desktop"; // TODO: 根据平台设置
    info.is_online = true;
    info.last_seen = currentTimestamp();
    info.trust_level = 100;
    return info;
}

P2PCommunication::Statistics P2PCommunication::getStatistics() const {
    std::lock_guard<std::mutex> lock(stats_mutex_);
    
    Statistics stats;
    stats.total_messages_sent = messages_sent_;
    stats.total_messages_received = messages_received_;
    stats.total_bytes_sent = bytes_sent_;
    stats.total_bytes_received = bytes_received_;
    
    {
        std::lock_guard<std::mutex> conn_lock(connections_mutex_);
        stats.active_connections = 0;
        for (const auto& [id, conn] : connections_) {
            if (conn.state == ConnectionState::AUTHENTICATED) {
                stats.active_connections++;
            }
        }
    }
    
    {
        std::lock_guard<std::mutex> dev_lock(devices_mutex_);
        stats.discovered_devices = discovered_devices_.size();
    }
    
    return stats;
}

// ============================================================================
// 内部方法
// ============================================================================

void P2PCommunication::discoveryLoop() {
    while (running_) {
        startDiscovery();
        std::this_thread::sleep_for(std::chrono::seconds(10));
    }
}

void P2PCommunication::heartbeatLoop() {
    while (running_) {
        // 发送心跳到所有连接的设备
        auto connections = getActiveConnections();
        for (const auto& conn : connections) {
            sendMessage(conn.device_id, MessageType::HEARTBEAT, {});
        }
        
        std::this_thread::sleep_for(std::chrono::milliseconds(config_.heartbeat_interval_ms));
    }
}

void P2PCommunication::receiveLoop() {
    while (running_) {
#ifdef USE_ECAL
        // eCAL会自动处理接收
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
#else
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
#endif
    }
}

bool P2PCommunication::performHandshake(const DeviceId& device_id) {
    // 发送握手消息
    P2PMessage handshake = createMessage(MessageType::HANDSHAKE, {});
    handshake.header.target_id = device_id;
    
    // TODO: 实现握手协议
    return sendMessage(device_id, MessageType::HANDSHAKE, {});
}

bool P2PCommunication::authenticateConnection(const DeviceId& device_id) {
    // TODO: 实现认证协议
    // 使用公钥签名验证身份
    return true;
}

P2PMessage P2PCommunication::createMessage(MessageType type, 
                                            const std::vector<uint8_t>& payload) {
    P2PMessage msg;
    msg.header.version = 1;
    msg.header.type = type;
    msg.header.flags = 0;
    msg.header.hop_count = 0;
    msg.header.message_id = generateMessageId();
    msg.header.source_id = config_.node_id;
    msg.header.timestamp = currentTimestamp();
    msg.header.payload_size = static_cast<uint32_t>(payload.size());
    msg.payload = payload;
    msg.encrypted = false;
    
    return msg;
}

bool P2PCommunication::serializeMessage(const P2PMessage& msg, 
                                         std::vector<uint8_t>& buffer) {
    // 简化的序列化
    // 实际项目中应使用Protobuf
    buffer.clear();
    
    // 头部
    buffer.push_back(msg.header.version);
    buffer.push_back(static_cast<uint8_t>(msg.header.type));
    buffer.push_back(msg.header.flags);
    buffer.push_back(msg.header.hop_count);
    
    // 消息ID (32 bytes)
    buffer.insert(buffer.end(), msg.header.message_id.begin(), msg.header.message_id.end());
    
    // 源ID (36 bytes)
    buffer.insert(buffer.end(), msg.header.source_id.begin(), msg.header.source_id.end());
    
    // 目标ID (36 bytes)
    buffer.insert(buffer.end(), msg.header.target_id.begin(), msg.header.target_id.end());
    
    // 时间戳 (8 bytes)
    for (int i = 0; i < 8; i++) {
        buffer.push_back(static_cast<uint8_t>((msg.header.timestamp >> (i * 8)) & 0xFF));
    }
    
    // payload大小 (4 bytes)
    for (int i = 0; i < 4; i++) {
        buffer.push_back(static_cast<uint8_t>((msg.header.payload_size >> (i * 8)) & 0xFF));
    }
    
    // payload
    buffer.insert(buffer.end(), msg.payload.begin(), msg.payload.end());
    
    return true;
}

bool P2PCommunication::deserializeMessage(const std::vector<uint8_t>& buffer, 
                                           P2PMessage& msg) {
    if (buffer.size() < 116) { // 最小头部大小
        return false;
    }
    
    size_t offset = 0;
    
    msg.header.version = buffer[offset++];
    msg.header.type = static_cast<MessageType>(buffer[offset++]);
    msg.header.flags = buffer[offset++];
    msg.header.hop_count = buffer[offset++];
    
    // 消息ID
    msg.header.message_id = std::string(buffer.begin() + offset, buffer.begin() + offset + 32);
    offset += 32;
    
    // 源ID
    msg.header.source_id = std::string(buffer.begin() + offset, buffer.begin() + offset + 36);
    offset += 36;
    
    // 目标ID
    msg.header.target_id = std::string(buffer.begin() + offset, buffer.begin() + offset + 36);
    offset += 36;
    
    // 时间戳
    msg.header.timestamp = 0;
    for (int i = 0; i < 8; i++) {
        msg.header.timestamp |= static_cast<uint64_t>(buffer[offset + i]) << (i * 8);
    }
    offset += 8;
    
    // payload大小
    msg.header.payload_size = 0;
    for (int i = 0; i < 4; i++) {
        msg.header.payload_size |= static_cast<uint32_t>(buffer[offset + i]) << (i * 8);
    }
    offset += 4;
    
    // payload
    if (offset + msg.header.payload_size <= buffer.size()) {
        msg.payload.assign(buffer.begin() + offset, buffer.begin() + offset + msg.header.payload_size);
    }
    
    return true;
}

bool P2PCommunication::encryptPayload(std::vector<uint8_t>& payload, 
                                       const std::string& session_key) {
    // TODO: 实现AES-256-GCM加密
    return true;
}

bool P2PCommunication::decryptPayload(std::vector<uint8_t>& payload, 
                                       const std::string& session_key) {
    // TODO: 实现AES-256-GCM解密
    return true;
}

void P2PCommunication::handleMessage(const P2PMessage& msg) {
    // 更新统计
    {
        std::lock_guard<std::mutex> lock(stats_mutex_);
        messages_received_++;
    }
    
    // 根据消息类型处理
    switch (msg.header.type) {
        case MessageType::CREDENTIAL_REQUEST:
            handleCredentialRequest(msg);
            break;
        case MessageType::CREDENTIAL_RESPONSE:
            handleCredentialResponse(msg);
            break;
        case MessageType::HEARTBEAT:
            // 更新连接活动时间
            {
                std::lock_guard<std::mutex> lock(connections_mutex_);
                auto it = connections_.find(msg.header.source_id);
                if (it != connections_.end()) {
                    it->second.last_activity = currentTimestamp();
                }
            }
            break;
        default:
            break;
    }
    
    // 触发回调
    if (message_callback_) {
        message_callback_(msg);
    }
}

void P2PCommunication::handleCredentialRequest(const P2PMessage& msg) {
    // 解析请求
    openclaw::CredentialRequest request;
    if (!request.ParseFromArray(msg.payload.data(), msg.payload.size())) {
        return;
    }
    
    // TODO: 从zk_vault获取凭证
    
    // 创建响应
    openclaw::CredentialResponse response;
    response.set_session_id(request.session_id());
    response.set_success(false);
    response.set_error_message("Not implemented");
    
    // 发送响应
    std::vector<uint8_t> payload(response.ByteSizeLong());
    response.SerializeToArray(payload.data(), payload.size());
    
    sendMessage(msg.header.source_id, MessageType::CREDENTIAL_RESPONSE, payload);
}

void P2PCommunication::handleCredentialResponse(const P2PMessage& msg) {
    // 处理凭证响应
    openclaw::CredentialResponse response;
    if (response.ParseFromArray(msg.payload.data(), msg.payload.size())) {
        std::cout << "[P2P] Received credential response: " 
                  << (response.success() ? "success" : response.error_message()) 
                  << std::endl;
    }
}

MessageId P2PCommunication::generateMessageId() {
    std::lock_guard<std::mutex> lock(id_mutex_);
    
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<uint64_t> dis;
    
    std::stringstream ss;
    ss << std::hex << dis(gen) << dis(gen);
    
    return ss.str();
}

Timestamp P2PCommunication::currentTimestamp() const {
    return static_cast<Timestamp>(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
        ).count()
    );
}

#ifdef USE_ECAL
void P2PCommunication::setupECALPublishers() {
    publisher_ = std::make_unique<eCAL::protobuf::CPublisher<openclaw::P2PEnvelope>>(
        "polyvault_p2p"
    );
}

void P2PCommunication::setupECALSubscribers() {
    subscriber_ = std::make_unique<eCAL::protobuf::CSubscriber<openclaw::P2PEnvelope>>(
        "polyvault_p2p"
    );
    
    // 设置回调
    subscriber_->AddReceiveCallback([this](const char* topic, const openclaw::P2PEnvelope& msg, long long time) {
        if (msg.target_id() == config_.node_id || msg.target_id().empty()) {
            P2PMessage p2p_msg;
            p2p_msg.header.message_id = msg.message_id();
            p2p_msg.header.source_id = msg.source_id();
            p2p_msg.header.target_id = msg.target_id();
            p2p_msg.header.timestamp = msg.timestamp();
            
            const auto& payload = msg.payload();
            p2p_msg.payload.assign(payload.begin(), payload.end());
            
            handleMessage(p2p_msg);
        }
    });
}

void P2PCommunication::setupECALServices() {
    // TODO: 设置eCAL服务
}
#endif

// ============================================================================
// P2PCredentialService
// ============================================================================

P2PCredentialService::P2PCredentialService(P2PCommunication& comm)
    : comm_(comm)
    , running_(false)
{
}

void P2PCredentialService::setCredentialProvider(CredentialProvider provider) {
    credential_provider_ = std::move(provider);
}

void P2PCredentialService::start() {
    running_ = true;
    std::cout << "[P2PCredentialService] Started" << std::endl;
}

void P2PCredentialService::stop() {
    running_ = false;
    std::cout << "[P2PCredentialService] Stopped" << std::endl;
}

void P2PCredentialService::handleCredentialRequest(const P2PMessage& msg) {
    if (!credential_provider_) {
        return;
    }
    
    // 解析请求并调用提供者
    openclaw::CredentialRequest request;
    if (request.ParseFromArray(msg.payload.data(), msg.payload.size())) {
        auto credentials = credential_provider_(request.service_url(), request.session_id());
        
        // 构建响应
        openclaw::CredentialResponse response;
        response.set_session_id(request.session_id());
        
        if (credentials) {
            response.set_success(true);
            // 设置加密的凭证
        } else {
            response.set_success(false);
            response.set_error_message("Credentials not found");
        }
        
        // 发送响应
        std::vector<uint8_t> payload(response.ByteSizeLong());
        response.SerializeToArray(payload.data(), payload.size());
        comm_.sendMessage(msg.header.source_id, MessageType::CREDENTIAL_RESPONSE, payload);
    }
}

// ============================================================================
// 工具函数
// ============================================================================

namespace utils {

std::string generateDeviceId() {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<uint64_t> dis;
    
    std::stringstream ss;
    ss << "dev_" << std::hex << dis(gen) << dis(gen);
    return ss.str();
}

std::vector<std::string> getLocalIPAddresses() {
    std::vector<std::string> addresses;
    
#ifdef _WIN32
    // Windows实现
    char host[256];
    if (gethostname(host, sizeof(host)) == 0) {
        struct hostent* hostent = gethostbyname(host);
        if (hostent) {
            for (int i = 0; hostent->h_addr_list[i] != nullptr; i++) {
                struct in_addr addr;
                addr.s_addr = *(u_long*)hostent->h_addr_list[i];
                addresses.push_back(inet_ntoa(addr));
            }
        }
    }
#else
    // Linux/macOS实现
    struct ifaddrs* ifaddr;
    if (getifaddrs(&ifaddr) == 0) {
        for (struct ifaddrs* ifa = ifaddr; ifa != nullptr; ifa = ifa->ifa_next) {
            if (ifa->ifa_addr && ifa->ifa_addr->sa_family == AF_INET) {
                char addr[INET_ADDRSTRLEN];
                inet_ntop(AF_INET, &((struct sockaddr_in*)ifa->ifa_addr)->sin_addr, addr, INET_ADDRSTRLEN);
                addresses.push_back(addr);
            }
        }
        freeifaddrs(ifaddr);
    }
#endif
    
    return addresses;
}

NATType detectNATType() {
    // 简化的NAT检测
    // 实际实现需要STUN服务器
    return NATType::PORT_RESTRICTED;
}

uint32_t calculateChecksum(const std::vector<uint8_t>& data) {
    uint32_t sum = 0;
    for (uint8_t byte : data) {
        sum += byte;
    }
    return sum & 0xFFFFFFFF;
}

} // namespace utils

} // namespace p2p
} // namespace polyvault