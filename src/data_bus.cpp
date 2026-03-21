/**
 * PolyVault eCAL Communication Layer - data_bus.cpp
 * Implements eCAL-based pub/sub communication for secure data exchange
 */

#include <ecal/ecal.h>
#include <ecal/msg/string/subscriber.h>
#include <ecal/msg/string/publisher.h>
#include <iostream>
#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <map>
#include <functional>

// Crypto headers for secure communication
#include "crypto_utils.h"

namespace polyvault {
namespace comm {

// Message types for eCAL communication
enum class MessageType : int {
    KEY_EXCHANGE = 1,
    SIGNATURE_REQUEST = 2,
    SIGNATURE_RESPONSE = 3,
    VERIFICATION_REQUEST = 4,
    VERIFICATION_RESPONSE = 5,
    HEARTBEAT = 6,
    CONFIG_SYNC = 7,
    KEY_ROTATION = 8
};

// Secure message wrapper
struct SecureMessage {
    MessageType type;
    std::string sender_id;
    std::string receiver_id;
    std::vector<uint8_t> encrypted_payload;
    std::vector<uint8_t> signature;
    uint64_t timestamp;
    uint32_t sequence_num;
    
    SecureMessage() : type(MessageType::HEARTBEAT), timestamp(0), sequence_num(0) {}
};

// Data bus configuration
struct DataBusConfig {
    std::string node_name;
    std::string network_interface;
    uint16_t port;
    bool enable_encryption;
    uint32_t max_message_size;
    uint32_t timeout_ms;
    
    DataBusConfig() 
        : node_name("PolyVault Node")
        , network_interface("")
        , port(0)  // Let eCAL choose
        , enable_encryption(true)
        , max_message_size(1024 * 1024)  // 1MB
        , timeout_ms(5000)  // 5 seconds
    {}
};

/**
 * eCAL Data Bus Implementation
 * Provides secure pub/sub communication between PolyVault nodes
 */
class DataBus {
public:
    /**
     * Constructor
     * @param config Data bus configuration
     */
    explicit DataBus(const DataBusConfig& config);
    
    /**
     * Destructor - cleanup resources
     */
    ~DataBus();
    
    /**
     * Initialize the data bus
     * @return true if initialization successful
     */
    bool initialize();
    
    /**
     * Start the data bus
     * @return true if started successfully
     */
    bool start();
    
    /**
     * Stop the data bus
     */
    void stop();
    
    /**
     * Publish a message to a specific topic
     * @param topic Topic name
     * @param message Message to publish
     * @return true if publish successful
     */
    bool publish(const std::string& topic, const SecureMessage& message);
    
    /**
     * Subscribe to a topic
     * @param topic Topic name
     * @param callback Callback function for received messages
     * @return true if subscription successful
     */
    bool subscribe(const std::string& topic, 
                   std::function<void(const SecureMessage&)> callback);
    
    /**
     * Unsubscribe from a topic
     * @param topic Topic name
     */
    void unsubscribe(const std::string& topic);
    
    /**
     * Send a secure message to a specific receiver
     * @param receiver_id Receiver node ID
     * @param message Message to send
     * @return true if send successful
     */
    bool sendTo(const std::string& receiver_id, const SecureMessage& message);
    
    /**
     * Process callbacks (call periodically in main loop)
     */
    void processCallbacks();
    
    /**
     * Get connection status
     * @return true if connected
     */
    bool isConnected() const { return is_connected_; }
    
    /**
     * Get node ID
     * @return Node ID string
     */
    std::string getNodeId() const { return node_id_; }
    
private:
    DataBusConfig config_;
    bool is_initialized_;
    bool is_running_;
    bool is_connected_;
    std::string node_id_;
    uint32_t sequence_number_;
    std::mutex mutex_;
    
    // eCAL components
    std::unique_ptr<eCAL::string::Publisher> key_exchange_pub_;
    std::unique_ptr<eCAL::string::Subscriber> key_exchange_sub_;
    std::unique_ptr<eCAL::string::Publisher> signature_pub_;
    std::unique_ptr<eCAL::string::Subscriber> signature_sub_;
    
    // Subscriptions map
    std::map<std::string, std::function<void(const SecureMessage&)>> subscribers_;
    std::map<std::string, std::unique_ptr<eCAL::string::Subscriber>> topic_subscribers_;
    
    // Crypto utilities
    std::unique_ptr<CryptoUtils> crypto_;
    
    // Message serialization/deserialization
    std::vector<uint8_t> serializeMessage(const SecureMessage& msg);
    bool deserializeMessage(const std::vector<uint8_t>& data, SecureMessage& msg);
    
    // Generate unique node ID
    std::string generateNodeId();
    
    // Handle incoming messages
    void onKeyExchangeReceived(const std::string& topic, const std::string& msg);
    void onSignatureReceived(const std::string& topic, const std::string& msg);
    void onGenericMessage(const std::string& topic, const std::string& msg);
};

/**
 * DataBus Implementation
 */

DataBus::DataBus(const DataBusConfig& config)
    : config_(config)
    , is_initialized_(false)
    , is_running_(false)
    , is_connected_(false)
    , node_id_(generateNodeId())
    , sequence_number_(0)
    , crypto_(std::make_unique<CryptoUtils>())
{
}

DataBus::~DataBus() {
    stop();
}

bool DataBus::initialize() {
    if (is_initialized_) {
        std::cerr << "DataBus already initialized" << std::endl;
        return true;
    }
    
    // Initialize eCAL
    if (!eCAL::Initialize()) {
        std::cerr << "Failed to initialize eCAL" << std::endl;
        return false;
    }
    
    // Set process information
    eCAL::Process::SetNodeName(config_.node_name.c_str());
    
    // Initialize crypto
    if (!crypto_->initialize()) {
        std::cerr << "Failed to initialize crypto" << std::endl;
        eCAL::Finalize();
        return false;
    }
    
    is_initialized_ = true;
    std::cout << "DataBus initialized with node ID: " << node_id_ << std::endl;
    
    return true;
}

bool DataBus::start() {
    if (!is_initialized_) {
        std::cerr << "DataBus not initialized" << std::endl;
        return false;
    }
    
    if (is_running_) {
        std::cerr << "DataBus already running" << std::endl;
        return true;
    }
    
    // Create publishers
    key_exchange_pub_ = std::make_unique<eCAL::string::Publisher>("polyvault_key_exchange");
    signature_pub_ = std::make_unique<eCAL::string::Publisher>("polyvault_signatures");
    
    // Create subscribers with callbacks
    key_exchange_sub_ = std::make_unique<eCAL::string::Subscriber>("polyvault_key_exchange");
    signature_sub_ = std::make_unique<eCAL::string::Subscriber>("polyvault_signatures");
    
    // Register callbacks
    key_exchange_sub_->AddReceiveCallback(
        [this](const std::string& topic, const std::string& msg) {
            onKeyExchangeReceived(topic, msg);
        }
    );
    
    signature_sub_->AddReceiveCallback(
        [this](const std::string& topic, const std::string& msg) {
            onSignatureReceived(topic, msg);
        }
    );
    
    is_running_ = true;
    is_connected_ = true;
    
    std::cout << "DataBus started successfully" << std::endl;
    return true;
}

void DataBus::stop() {
    if (!is_running_) {
        return;
    }
    
    // Unsubscribe from all topics
    for (auto& [topic, _] : topic_subscribers_) {
        unsubscribe(topic);
    }
    
    // Cleanup eCAL
    key_exchange_pub_.reset();
    key_exchange_sub_.reset();
    signature_pub_.reset();
    signature_sub_.reset();
    
    is_running_ = false;
    is_connected_ = false;
    
    std::cout << "DataBus stopped" << std::endl;
}

bool DataBus::publish(const std::string& topic, const SecureMessage& message) {
    if (!is_running_) {
        std::cerr << "DataBus not running" << std::endl;
        return false;
    }
    
    try {
        auto data = serializeMessage(message);
        std::string msg(data.begin(), data.end());
        
        // Get appropriate publisher
        eCAL::string::Publisher* pub = nullptr;
        
        if (topic == "polyvault_key_exchange") {
            pub = key_exchange_pub_.get();
        } else if (topic == "polyvault_signatures") {
            pub = signature_pub_.get();
        }
        
        if (pub) {
            return pub->Send(msg);
        }
        
        // Create dynamic publisher for other topics
        auto dynamic_pub = std::make_unique<eCAL::string::Publisher>(topic);
        bool result = dynamic_pub->Send(msg);
        
        return result;
    }
    catch (const std::exception& e) {
        std::cerr << "Publish error: " << e.what() << std::endl;
        return false;
    }
}

bool DataBus::subscribe(const std::string& topic, 
                        std::function<void(const SecureMessage&)> callback) {
    if (!is_running_) {
        std::cerr << "DataBus not running" << std::endl;
        return false;
    }
    
    std::lock_guard<std::mutex> lock(mutex_);
    
    // Store callback
    subscribers_[topic] = callback;
    
    // Create subscriber if not exists
    if (topic_subscribers_.find(topic) == topic_subscribers_.end()) {
        auto sub = std::make_unique<eCAL::string::Subscriber>(topic);
        
        sub->AddReceiveCallback(
            [this, topic](const std::string& t, const std::string& msg) {
                onGenericMessage(t, msg);
            }
        );
        
        topic_subscribers_[topic] = std::move(sub);
    }
    
    std::cout << "Subscribed to topic: " << topic << std::endl;
    return true;
}

void DataBus::unsubscribe(const std::string& topic) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    subscribers_.erase(topic);
    topic_subscribers_.erase(topic);
    
    std::cout << "Unsubscribed from topic: " << topic << std::endl;
}

bool DataBus::sendTo(const std::string& receiver_id, const SecureMessage& message) {
    std::string topic = "polyvault_" + receiver_id;
    return publish(topic, message);
}

void DataBus::processCallbacks() {
    // eCAL handles callback processing internally
    // This method can be used for additional processing if needed
}

std::string DataBus::generateNodeId() {
    // Generate unique node ID based on hostname, process ID, and timestamp
    std::string host = eCAL::Process::GetHostName();
    int pid = eCAL::Process::GetProcessID();
    uint64_t ts = eCAL::Time::GetMicroSeconds();
    
    char buffer[256];
    snprintf(buffer, sizeof(buffer), "%s_%d_%llu", host.c_str(), pid, 
             static_cast<unsigned long long>(ts));
    
    return std::string(buffer);
}

std::vector<uint8_t> DataBus::serializeMessage(const SecureMessage& msg) {
    // Simple serialization (in production, use protobuf or similar)
    std::vector<uint8_t> data;
    
    // Type (4 bytes)
    uint32_t type_val = static_cast<uint32_t>(msg.type);
    data.insert(data.end(), reinterpret_cast<uint8_t*>(&type_val), 
                reinterpret_cast<uint8_t*>(&type_val) + 4);
    
    // Sender ID length + content
    uint32_t sender_len = msg.sender_id.size();
    data.insert(data.end(), reinterpret_cast<uint8_t*>(&sender_len),
                reinterpret_cast<uint8_t*>(&sender_len) + 4);
    data.insert(data.end(), msg.sender_id.begin(), msg.sender_id.end());
    
    // Receiver ID length + content
    uint32_t receiver_len = msg.receiver_id.size();
    data.insert(data.end(), reinterpret_cast<uint8_t*>(&receiver_len),
                reinterpret_cast<uint8_t*>(&receiver_len) + 4);
    data.insert(data.end(), msg.receiver_id.begin(), msg.receiver_id.end());
    
    // Encrypted payload length + content
    uint32_t payload_len = msg.encrypted_payload.size();
    data.insert(data.end(), reinterpret_cast<uint8_t*>(&payload_len),
                reinterpret_cast<uint8_t*>(&payload_len) + 4);
    data.insert(data.end(), msg.encrypted_payload.begin(), msg.encrypted_payload.end());
    
    // Signature length + content
    uint32_t sig_len = msg.signature.size();
    data.insert(data.end(), reinterpret_cast<uint8_t*>(&sig_len),
                reinterpret_cast<uint8_t*>(&sig_len) + 4);
    data.insert(data.end(), msg.signature.begin(), msg.signature.end());
    
    // Timestamp (8 bytes)
    data.insert(data.end(), reinterpret_cast<uint8_t*>(&msg.timestamp),
                reinterpret_cast<uint8_t*>(&msg.timestamp) + 8);
    
    // Sequence number (4 bytes)
    data.insert(data.end(), reinterpret_cast<uint8_t*>(&msg.sequence_num),
                reinterpret_cast<uint8_t*>(&msg.sequence_num) + 4);
    
    return data;
}

bool DataBus::deserializeMessage(const std::vector<uint8_t>& data, SecureMessage& msg) {
    if (data.size() < 24) {  // Minimum size check
        return false;
    }
    
    size_t offset = 0;
    
    // Type
    uint32_t type_val;
    std::copy(data.begin() + offset, data.begin() + offset + 4, 
              reinterpret_cast<uint8_t*>(&type_val));
    msg.type = static_cast<MessageType>(type_val);
    offset += 4;
    
    // Sender ID
    uint32_t sender_len;
    std::copy(data.begin() + offset, data.begin() + offset + 4,
              reinterpret_cast<uint8_t*>(&sender_len));
    offset += 4;
    msg.sender_id.assign(data.begin() + offset, data.begin() + offset + sender_len);
    offset += sender_len;
    
    // Receiver ID
    uint32_t receiver_len;
    std::copy(data.begin() + offset, data.begin() + offset + 4,
              reinterpret_cast<uint8_t*>(&receiver_len));
    offset += 4;
    msg.receiver_id.assign(data.begin() + offset, data.begin() + offset + receiver_len);
    offset += receiver_len;
    
    // Encrypted payload
    uint32_t payload_len;
    std::copy(data.begin() + offset, data.begin() + offset + 4,
              reinterpret_cast<uint8_t*>(&payload_len));
    offset += 4;
    msg.encrypted_payload.assign(data.begin() + offset, data.begin() + offset + payload_len);
    offset += payload_len;
    
    // Signature
    uint32_t sig_len;
    std::copy(data.begin() + offset, data.begin() + offset + 4,
              reinterpret_cast<uint8_t*>(&sig_len));
    offset += 4;
    msg.signature.assign(data.begin() + offset, data.begin() + offset + sig_len);
    offset += sig_len;
    
    // Timestamp
    std::copy(data.begin() + offset, data.begin() + offset + 8,
              reinterpret_cast<uint8_t*>(&msg.timestamp));
    offset += 8;
    
    // Sequence number
    std::copy(data.begin() + offset, data.begin() + offset + 4,
              reinterpret_cast<uint8_t*>(&msg.sequence_num));
    
    return true;
}

void DataBus::onKeyExchangeReceived(const std::string& topic, const std::string& msg) {
    try {
        std::vector<uint8_t> data(msg.begin(), msg.end());
        SecureMessage message;
        
        if (deserializeMessage(data, message)) {
            // Check for registered callback
            auto it = subscribers_.find(topic);
            if (it != subscribers_.end()) {
                it->second(message);
            }
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Error processing key exchange message: " << e.what() << std::endl;
    }
}

void DataBus::onSignatureReceived(const std::string& topic, const std::string& msg) {
    try {
        std::vector<uint8_t> data(msg.begin(), msg.end());
        SecureMessage message;
        
        if (deserializeMessage(data, message)) {
            auto it = subscribers_.find(topic);
            if (it != subscribers_.end()) {
                it->second(message);
            }
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Error processing signature message: " << e.what() << std::endl;
    }
}

void DataBus::onGenericMessage(const std::string& topic, const std::string& msg) {
    try {
        std::vector<uint8_t> data(msg.begin(), msg.end());
        SecureMessage message;
        
        if (deserializeMessage(data, message)) {
            auto it = subscribers_.find(topic);
            if (it != subscribers_.end()) {
                it->second(message);
            }
        }
    }
    catch (const std::exception& e) {
        std::cerr << "Error processing generic message: " << e.what() << std::endl;
    }
}

// Factory function for creating DataBus instances
std::unique_ptr<DataBus> createDataBus(const DataBusConfig& config) {
    return std::make_unique<DataBus>(config);
}

}  // namespace comm
}  // namespace polyvault

// Example usage
#ifdef DATA_BUS_TEST
int main() {
    // Create configuration
    polyvault::comm::DataBusConfig config;
    config.node_name = "PolyVault Test Node";
    config.enable_encryption = true;
    
    // Create and initialize data bus
    auto data_bus = polyvault::comm::createDataBus(config);
    
    if (!data_bus->initialize()) {
        std::cerr << "Failed to initialize DataBus" << std::endl;
        return 1;
    }
    
    if (!data_bus->start()) {
        std::cerr << "Failed to start DataBus" << std::endl;
        return 1;
    }
    
    // Subscribe to topics
    data_bus->subscribe("polyvault_key_exchange", [](const auto& msg) {
        std::cout << "Received key exchange message from: " << msg.sender_id << std::endl;
    });
    
    data_bus->subscribe("polyvault_signatures", [](const auto& msg) {
        std::cout << "Received signature message from: " << msg.sender_id << std::endl;
    });
    
    // Publish a test message
    polyvault::comm::SecureMessage msg;
    msg.type = polyvault::comm::MessageType::HEARTBEAT;
    msg.sender_id = data_bus->getNodeId();
    msg.timestamp = eCAL::Time::GetMicroSeconds();
    msg.sequence_num = 1;
    
    data_bus->publish("polyvault_key_exchange", msg);
    
    // Process callbacks
    data_bus->processCallbacks();
    
    // Wait for messages
    std::this_thread::sleep_for(std::chrono::seconds(5));
    
    // Cleanup
    data_bus->stop();
    
    return 0;
}
#endif  // DATA_BUS_TEST