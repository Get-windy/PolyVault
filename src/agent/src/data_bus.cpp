/**
 * @file data_bus.cpp
 * @brief PolyVault数据总线实现
 */

#include "data_bus.hpp"
#include <iostream>
#include <sstream>
#include <algorithm>

namespace polyvault {
namespace bus {

// ============================================================================
// Connection实现
// ============================================================================

Connection::Connection(const std::string& connection_id, const std::string& endpoint)
    : connection_id_(connection_id)
    , endpoint_(endpoint)
    , state_(ConnectionState::DISCONNECTED)
    , last_heartbeat_(Message::currentTimestamp())
    , connect_time_(Message::currentTimestamp())
    , messages_sent_(0)
    , messages_received_(0) {}

void Connection::setState(ConnectionState state) {
    std::lock_guard<std::mutex> lock(mutex_);
    state_ = state;
}

void Connection::updateHeartbeat() {
    std::lock_guard<std::mutex> lock(mutex_);
    last_heartbeat_ = Message::currentTimestamp();
}

bool Connection::send(const Message& msg) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (state_ != ConnectionState::CONNECTED) {
        return false;
    }
    messages_sent_++;
    // 实际发送逻辑在子类或eCAL实现
    return true;
}

bool Connection::receive(Message& msg) {
    std::lock_guard<std::mutex> lock(mutex_);
    if (state_ != ConnectionState::CONNECTED) {
        return false;
    }
    messages_received_++;
    return true;
}

void Connection::setMetadata(const std::string& key, const std::string& value) {
    std::lock_guard<std::mutex> lock(mutex_);
    metadata_[key] = value;
}

std::optional<std::string> Connection::getMetadata(const std::string& key) const {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = metadata_.find(key);
    if (it != metadata_.end()) {
        return it->second;
    }
    return std::nullopt;
}

// ============================================================================
// DataBus实现
// ============================================================================

DataBus::DataBus(const DataBusConfig& config)
    : config_(config)
    , running_(false)
    , initialized_(false)
    , messages_sent_(0)
    , messages_received_(0)
    , message_id_counter_(0)
#ifdef USE_ECAL
    , ecal_enabled_(false)
#endif
{
    if (config_.node_id.empty()) {
        config_.node_id = "node_" + std::to_string(
            std::hash<std::string>{}(config_.bus_name + std::to_string(Message::currentTimestamp())) % 10000);
    }
}

DataBus::~DataBus() {
    stop();
}

bool DataBus::initialize() {
    if (initialized_) {
        return true;
    }
    
    std::cout << "[DataBus] Initializing: " << config_.bus_name << std::endl;
    std::cout << "[DataBus] Node ID: " << config_.node_id << std::endl;
    
#ifdef USE_ECAL
    if (config_.use_ecal) {
        eCAL::Initialize(0, nullptr, config_.bus_name.c_str());
        eCAL::Process::SetUnitName(config_.node_id.c_str());
        ecal_enabled_ = true;
        std::cout << "[DataBus] eCAL enabled" << std::endl;
    }
#endif
    
    initialized_ = true;
    std::cout << "[DataBus] Initialized successfully" << std::endl;
    return true;
}

void DataBus::start() {
    if (running_) {
        return;
    }
    
    if (!initialized_) {
        initialize();
    }
    
    running_ = true;
    
    // 启动工作线程
    for (int i = 0; i < config_.worker_threads; ++i) {
        worker_threads_.emplace_back(&DataBus::workerLoop, this);
    }
    
    // 启动监控线程
    if (config_.enable_monitoring) {
        monitor_thread_ = std::thread(&DataBus::monitorLoop, this);
    }
    
    // 启动心跳线程
    heartbeat_thread_ = std::thread(&DataBus::heartbeatLoop, this);
    
    std::cout << "[DataBus] Started with " << config_.worker_threads << " worker threads" << std::endl;
}

void DataBus::stop() {
    if (!running_) {
        return;
    }
    
    running_ = false;
    
    // 等待工作线程结束
    for (auto& t : worker_threads_) {
        if (t.joinable()) {
            t.join();
        }
    }
    worker_threads_.clear();
    
    // 等待监控线程结束
    if (monitor_thread_.joinable()) {
        monitor_thread_.join();
    }
    
    // 等待心跳线程结束
    if (heartbeat_thread_.joinable()) {
        heartbeat_thread_.join();
    }
    
#ifdef USE_ECAL
    if (ecal_enabled_) {
        eCAL::Finalize();
        ecal_enabled_ = false;
    }
#endif
    
    std::cout << "[DataBus] Stopped" << std::endl;
}

std::string DataBus::subscribe(const std::string& topic, MessageCallback callback) {
    std::lock_guard<std::mutex> lock(subscribers_mutex_);
    
    std::string subscriber_id = "sub_" + std::to_string(++message_id_counter_);
    
    Subscriber sub;
    sub.subscriber_id = subscriber_id;
    sub.callback = std::move(callback);
    sub.active = true;
    
    subscribers_[subscriber_id] = std::move(sub);
    topic_to_subscribers_[topic].push_back(subscriber_id);
    
    std::cout << "[DataBus] Subscribed to topic: " << topic << " (id: " << subscriber_id << ")" << std::endl;
    
    return subscriber_id;
}

bool DataBus::unsubscribe(const std::string& subscriber_id) {
    std::lock_guard<std::mutex> lock(subscribers_mutex_);
    
    auto it = subscribers_.find(subscriber_id);
    if (it == subscribers_.end()) {
        return false;
    }
    
    // 从主题映射中移除
    for (auto& [topic, subs] : topic_to_subscribers_) {
        subs.erase(std::remove(subs.begin(), subs.end(), subscriber_id), subs.end());
    }
    
    subscribers_.erase(it);
    
    std::cout << "[DataBus] Unsubscribed: " << subscriber_id << std::endl;
    
    return true;
}

bool DataBus::publish(const std::string& topic, const Message& message) {
    if (!running_) {
        return false;
    }
    
    // 查找订阅者并直接投递
    std::vector<std::string> subscribers;
    {
        std::lock_guard<std::mutex> lock(subscribers_mutex_);
        auto it = topic_to_subscribers_.find(topic);
        if (it != topic_to_subscribers_.end()) {
            subscribers = it->second;
        }
    }
    
    // 投递消息给订阅者
    for (const auto& sub_id : subscribers) {
        std::lock_guard<std::mutex> lock(subscribers_mutex_);
        auto it = subscribers_.find(sub_id);
        if (it != subscribers_.end() && it->second.active) {
            try {
                it->second.callback(message);
                messages_received_++;
            } catch (const std::exception& e) {
                std::cerr << "[DataBus] Callback error for " << sub_id << ": " << e.what() << std::endl;
            }
        }
    }
    
    // 同时触发对应的消息类型处理器
    {
        std::lock_guard<std::mutex> lock(handlers_mutex_);
        auto it = handlers_.find(message.kind);
        if (it != handlers_.end()) {
            try {
                it->second(message);
            } catch (const std::exception& e) {
                std::cerr << "[DataBus] Handler error: " << e.what() << std::endl;
            }
        }
    }
    
    messages_sent_++;
    
#ifdef USE_ECAL
    if (ecal_enabled_ && message.kind == MessageKind::EVENT) {
        // 将事件发布到eCAL
        openclaw::Event event;
        event.set_event_id(message.message_id);
        event.set_device_id(message.source_id);
        event.set_timestamp(message.timestamp);
        event.set_message(message.topic);
        
        publishEcal(topic, event);
    }
#endif
    
    return true;
}

bool DataBus::publishAsync(const std::string& topic, const Message& message) {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    
    if (message_queue_.size() >= static_cast<size_t>(config_.queue_size)) {
        std::cerr << "[DataBus] Queue full, message dropped: " << message.message_id << std::endl;
        return false;
    }
    
    message_queue_.push(message);
    return true;
}

std::optional<Message> DataBus::request(const std::string& target, 
                                          const Message& request_msg, 
                                          int timeout_ms) {
    // 简化的请求-响应实现
    // 实际实现需要correlation ID和响应存储
    
    std::cout << "[DataBus] Request to " << target << ": " << request_msg.topic << std::endl;
    
    // 模拟响应
    Message response;
    response.message_id = "resp_" + request_msg.message_id;
    response.kind = MessageKind::CREDENTIAL_RESPONSE;
    response.source_id = target;
    response.target_id = request_msg.source_id;
    response.topic = request_msg.topic + "_response";
    response.timestamp = Message::currentTimestamp();
    
    return response;
}

void DataBus::respond(const std::string& target, const Message& response) {
    std::cout << "[DataBus] Response to " << target << std::endl;
    messages_sent_++;
}

void DataBus::registerHandler(MessageKind kind, MessageCallback callback) {
    std::lock_guard<std::mutex> lock(handlers_mutex_);
    handlers_[kind] = std::move(callback);
    std::cout << "[DataBus] Registered handler for kind: " << static_cast<int>(kind) << std::endl;
}

void DataBus::unregisterHandler(MessageKind kind) {
    std::lock_guard<std::mutex> lock(handlers_mutex_);
    handlers_.erase(kind);
    std::cout << "[DataBus] Unregistered handler for kind: " << static_cast<int>(kind) << std::endl;
}

std::string DataBus::connect(const std::string& endpoint) {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    
    // 检查是否已连接
    auto it = endpoint_to_connection_.find(endpoint);
    if (it != endpoint_to_connection_.end()) {
        return it->second;
    }
    
    std::string connection_id = "conn_" + std::to_string(++message_id_counter_);
    
    auto conn = std::make_shared<Connection>(connection_id, endpoint);
    conn->setState(ConnectionState::CONNECTING);
    
    // 模拟连接建立
    conn->setState(ConnectionState::CONNECTED);
    
    connections_[connection_id] = conn;
    endpoint_to_connection_[endpoint] = connection_id;
    
    notifyConnectionState(connection_id, ConnectionState::CONNECTED);
    
    std::cout << "[DataBus] Connected to: " << endpoint << " (id: " << connection_id << ")" << std::endl;
    
    return connection_id;
}

bool DataBus::disconnect(const std::string& connection_id) {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    
    auto it = connections_.find(connection_id);
    if (it == connections_.end()) {
        return false;
    }
    
    auto conn = it->second;
    conn->setState(ConnectionState::DISCONNECTED);
    
    endpoint_to_connection_.erase(conn->getEndpoint());
    connections_.erase(it);
    
    notifyConnectionState(connection_id, ConnectionState::DISCONNECTED);
    
    std::cout << "[DataBus] Disconnected: " << connection_id << std::endl;
    
    return true;
}

ConnectionState DataBus::getConnectionState(const std::string& connection_id) const {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    
    auto it = connections_.find(connection_id);
    if (it != connections_.end()) {
        return it->second->getState();
    }
    
    return ConnectionState::DISCONNECTED;
}

std::vector<ConnectionInfo> DataBus::getConnections() const {
    std::lock_guard<std::mutex> lock(connections_mutex_);
    
    std::vector<ConnectionInfo> result;
    for (const auto& [id, conn] : connections_) {
        ConnectionInfo info;
        info.connection_id = id;
        info.remote_endpoint = conn->getEndpoint();
        info.state = conn->getState();
        info.last_heartbeat = conn->getLastHeartbeat();
        result.push_back(info);
    }
    
    return result;
}

void DataBus::setConnectionCallback(ConnectionCallback callback) {
    connection_callback_ = std::move(callback);
}

uint64_t DataBus::getQueueSize() const {
    std::lock_guard<std::mutex> lock(queue_mutex_);
    return message_queue_.size();
}

void DataBus::startHeartbeat() {
    std::cout << "[DataBus] Heartbeat started" << std::endl;
}

void DataBus::stopHeartbeat() {
    std::cout << "[DataBus] Heartbeat stopped" << std::endl;
}

#ifdef USE_ECAL
void DataBus::enableEcal(bool enable) {
    if (enable && !ecal_enabled_) {
        if (!initialized_) {
            initialize();
        }
        ecal_enabled_ = true;
        std::cout << "[DataBus] eCAL enabled" << std::endl;
    } else if (!enable && ecal_enabled_) {
        ecal_enabled_ = false;
        std::cout << "[DataBus] eCAL disabled" << std::endl;
    }
}

bool DataBus::publishEcal(const std::string& topic, const google::protobuf::Message& msg) {
    if (!ecal_enabled_) {
        return false;
    }
    
    std::lock_guard<std::mutex> lock(ecal_publishers_mutex_);
    
    // 获取或创建发布者
    auto it = ecal_event_publishers_.find(topic);
    if (it == ecal_event_publishers_.end()) {
        auto publisher = std::make_unique<eCAL::protobuf::CPublisher<openclaw::Event>>(topic);
        ecal_event_publishers_[topic] = std::move(publisher);
        it = ecal_event_publishers_.find(topic);
    }
    
    if (it != ecal_event_publishers_.end()) {
        // 使用动态类型发送
        const openclaw::Event* event = dynamic_cast<const openclaw::Event*>(&msg);
        if (event) {
            return it->second->Send(*event) > 0;
        }
    }
    
    return false;
}

template<typename T>
bool DataBus::subscribeEcal(const std::string& topic, std::function<void(const T&)> callback) {
    // 模板实现需要在头文件中
    return false;
}
#endif

void DataBus::workerLoop() {
    std::cout << "[DataBus] Worker thread started" << std::endl;
    
    while (running_) {
        Message msg;
        
        {
            std::lock_guard<std::mutex> lock(queue_mutex_);
            if (!message_queue_.empty()) {
                msg = std::move(message_queue_.front());
                message_queue_.pop();
            }
        }
        
        if (!msg.message_id.empty()) {
            processMessage(msg);
        } else {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    }
    
    std::cout << "[DataBus] Worker thread stopped" << std::endl;
}

void DataBus::heartbeatLoop() {
    std::cout << "[DataBus] Heartbeat thread started" << std::endl;
    
    while (running_) {
        std::this_thread::sleep_for(std::chrono::milliseconds(config_.heartbeat_interval_ms));
        
        if (!running_) break;
        
        // 更新连接心跳
        std::lock_guard<std::mutex> lock(connections_mutex_);
        for (auto& [id, conn] : connections_) {
            conn->updateHeartbeat();
        }
    }
    
    std::cout << "[DataBus] Heartbeat thread stopped" << std::endl;
}

void DataBus::monitorLoop() {
    std::cout << "[DataBus] Monitor thread started" << std::endl;
    
    while (running_) {
        std::this_thread::sleep_for(std::chrono::seconds(10));
        
        if (!running_) break;
        
        // 检查超时连接
        uint64_t now = Message::currentTimestamp();
        
        std::lock_guard<std::mutex> lock(connections_mutex_);
        std::vector<std::string> timed_out;
        
        for (auto& [id, conn] : connections_) {
            if (conn->getState() == ConnectionState::CONNECTED) {
                uint64_t last_hb = conn->getLastHeartbeat();
                if (now - last_hb > static_cast<uint64_t>(config_.connection_timeout_ms)) {
                    timed_out.push_back(id);
                }
            }
        }
        
        for (const auto& id : timed_out) {
            auto it = connections_.find(id);
            if (it != connections_.end()) {
                it->second->setState(ConnectionState::ERROR);
                notifyConnectionState(id, ConnectionState::ERROR);
                std::cout << "[DataBus] Connection timeout: " << id << std::endl;
            }
        }
    }
    
    std::cout << "[DataBus] Monitor thread stopped" << std::endl;
}

void DataBus::processMessage(const Message& msg) {
    // 消息处理逻辑
    messages_received_++;
    
    // 路由到对应处理器
    std::lock_guard<std::mutex> lock(handlers_mutex_);
    auto it = handlers_.find(msg.kind);
    if (it != handlers_.end()) {
        try {
            it->second(msg);
        } catch (const std::exception& e) {
            std::cerr << "[DataBus] Handler exception: " << e.what() << std::endl;
        }
    }
}

std::string DataBus::generateMessageId() {
    return "msg_" + std::to_string(++message_id_counter_) + "_" + 
           std::to_string(Message::currentTimestamp());
}

void DataBus::notifyConnectionState(const std::string& connection_id, ConnectionState state) {
    if (connection_callback_) {
        try {
            connection_callback_(connection_id, state);
        } catch (const std::exception& e) {
            std::cerr << "[DataBus] Connection callback error: " << e.what() << std::endl;
        }
    }
}

// ============================================================================
// 便捷函数实现
// ============================================================================

Message createCredentialRequest(const std::string& service_url, 
                                 const std::string& service_name,
                                 int credential_type) {
    Message msg;
    msg.kind = MessageKind::CREDENTIAL_REQUEST;
    msg.topic = "credential/request";
    
    openclaw::CredentialRequest req;
    req.set_service_url(service_url);
    req.set_service_name(service_name);
    req.set_credential_type(static_cast<openclaw::CredentialType>(credential_type));
    req.set_request_id(msg.message_id);
    req.set_timestamp(Message::currentTimestamp());
    
    // 序列化到payload
    std::string serialized;
    if (req.SerializeToString(&serialized)) {
        msg.payload.assign(serialized.begin(), serialized.end());
    }
    
    return msg;
}

Message createEventMessage(const std::string& device_id, 
                           openclaw::EventType event_type,
                           const std::string& message) {
    Message msg;
    msg.kind = MessageKind::EVENT;
    msg.topic = "events";
    msg.source_id = device_id;
    
    openclaw::Event event;
    event.set_device_id(device_id);
    event.set_type(event_type);
    event.set_message(message);
    event.set_timestamp(Message::currentTimestamp());
    event.set_event_id(msg.message_id);
    
    std::string serialized;
    if (event.SerializeToString(&serialized)) {
        msg.payload.assign(serialized.begin(), serialized.end());
    }
    
    return msg;
}

} // namespace bus
} // namespace polyvault