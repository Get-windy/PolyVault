/**
 * PolyVault Protobuf Serializer
 * Provides serialization and deserialization for Protobuf messages
 */

#ifndef POLYVAULT_PROTOBUF_SERIALIZER_H
#define POLYVAULT_PROTOBUF_SERIALIZER_H

#include <string>
#include <vector>
#include <memory>
#include <stdexcept>
#include <google/protobuf/message.h>
#include <google/protobuf/util/json_util.h>
#include <google/protobuf/util/type_resolver.h>

namespace polyvault {
namespace serialization {

// Exception for serialization errors
class SerializationException : public std::runtime_error {
public:
    explicit SerializationException(const std::string& msg) 
        : std::runtime_error(msg) {}
};

// Output type for serialization
enum class OutputFormat {
    BINARY,   // Protobuf binary format
    JSON,     // JSON format
    TEXT      // Protobuf text format
};

/**
 * Protobuf Serializer/Deserializer for PolyVault messages
 */
class ProtobufSerializer {
public:
    /**
     * Constructor
     */
    ProtobufSerializer();
    
    /**
     * Destructor
     */
    ~ProtobufSerializer();
    
    /**
     * Serialize a protobuf message to bytes
     * @param message Protobuf message to serialize
     * @return Serialized bytes
     */
    std::vector<uint8_t> serialize(const google::protobuf::Message& message);
    
    /**
     * Serialize a protobuf message to string
     * @param message Protobuf message to serialize
     * @param format Output format
     * @return Serialized string
     */
    std::string serializeToString(const google::protobuf::Message& message, 
                                   OutputFormat format = OutputFormat::BINARY);
    
    /**
     * Deserialize bytes to a protobuf message
     * @param data Serialized bytes
     * @param message Message to populate
     * @return true if successful
     */
    bool deserialize(const std::vector<uint8_t>& data, 
                     google::protobuf::Message* message);
    
    /**
     * Deserialize string to a protobuf message
     * @param data Serialized string
     * @param message Message to populate
     * @param format Input format
     * @return true if successful
     */
    bool deserializeFromString(const std::string& data, 
                              google::protobuf::Message* message,
                              OutputFormat format = OutputFormat::BINARY);
    
    /**
     * Serialize to JSON
     * @param message Protobuf message
     * @return JSON string
     */
    std::string toJson(const google::protobuf::Message& message);
    
    /**
     * Deserialize from JSON
     * @param json JSON string
     * @param message Message to populate
     * @return true if successful
     */
    bool fromJson(const std::string& json, google::protobuf::Message* message);
    
    /**
     * Get the serialized size of a message
     * @param message Protobuf message
     * @return Size in bytes
     */
    size_t getSize(const google::protobuf::Message& message);

private:
    std::unique_ptr<google::protobuf::util::TypeResolver> type_resolver_;
};

// Inline implementations

inline ProtobufSerializer::ProtobufSerializer() {
    // Initialize type resolver for JSON conversion
    type_resolver_ = std::make_unique<google::protobuf::util::TypeResolver>(
        "type.googleapis.com"
    );
}

inline ProtobufSerializer::~ProtobufSerializer() = default;

inline std::vector<uint8_t> ProtobufSerializer::serialize(
    const google::protobuf::Message& message) {
    
    std::vector<uint8_t> buffer(message.ByteSizeLong());
    if (message.SerializeToArray(buffer.data(), static_cast<int>(buffer.size()))) {
        return buffer;
    }
    
    throw SerializationException("Failed to serialize message to binary format");
}

inline std::string ProtobufSerializer::serializeToString(
    const google::protobuf::Message& message, 
    OutputFormat format) {
    
    switch (format) {
        case OutputFormat::BINARY: {
            std::string result;
            message.SerializeToString(&result);
            return result;
        }
        
        case OutputFormat::JSON: {
            return toJson(message);
        }
        
        case OutputFormat::TEXT: {
            std::string result;
            google::protobuf::TextFormat::PrintToString(message, &result);
            return result;
        }
        
        default:
            throw SerializationException("Unknown output format");
    }
}

inline bool ProtobufSerializer::deserialize(
    const std::vector<uint8_t>& data, 
    google::protobuf::Message* message) {
    
    if (!message) {
        return false;
    }
    
    return message->ParseFromArray(data.data(), static_cast<int>(data.size()));
}

inline bool ProtobufSerializer::deserializeFromString(
    const std::string& data, 
    google::protobuf::Message* message,
    OutputFormat format) {
    
    if (!message) {
        return false;
    }
    
    switch (format) {
        case OutputFormat::BINARY:
            return message->ParseFromString(data);
            
        case OutputFormat::JSON:
            return fromJson(data, message);
            
        case OutputFormat::TEXT:
            return google::protobuf::TextFormat::ParseFromString(data, message);
            
        default:
            return false;
    }
}

inline std::string ProtobufSerializer::toJson(
    const google::protobuf::Message& message) {
    
    std::string json_output;
    google::protobuf::util::JsonOptions options;
    options.add_whitespace = true;
    
    auto status = google::protobuf::util::MessageToJsonString(
        message, 
        &json_output, 
        options
    );
    
    if (!status.ok()) {
        throw SerializationException(
            "Failed to convert to JSON: " + status.ToString()
        );
    }
    
    return json_output;
}

inline bool ProtobufSerializer::fromJson(
    const std::string& json, 
    google::protobuf::Message* message) {
    
    if (!message) {
        return false;
    }
    
    auto status = google::protobuf::util::JsonStringToMessage(
        json, 
        message
    );
    
    return status.ok();
}

inline size_t ProtobufSerializer::getSize(
    const google::protobuf::Message& message) {
    
    return static_cast<size_t>(message.ByteSizeLong());
}

// Convenience functions for common operations

/**
 * Create a quick serialized envelope
 */
std::vector<uint8_t> createEnvelope(
    const google::protobuf::Message& payload,
    const std::string& sender_id,
    const std::string& receiver_id);

/**
 * Quick serialization helper
 */
template<typename T>
std::vector<uint8_t> serializeMessage(const T& message) {
    ProtobufSerializer serializer;
    return serializer.serialize(message);
}

/**
 * Quick deserialization helper
 */
template<typename T>
std::unique_ptr<T> deserializeMessage(const std::vector<uint8_t>& data) {
    auto message = std::make_unique<T>();
    ProtobufSerializer serializer;
    
    if (serializer.deserialize(data, message.get())) {
        return message;
    }
    
    return nullptr;
}

/**
 * Quick JSON serialization helper
 */
template<typename T>
std::string serializeToJson(const T& message) {
    ProtobufSerializer serializer;
    return serializer.toJson(message);
}

/**
 * Quick JSON deserialization helper
 */
template<typename T>
std::unique_ptr<T> deserializeFromJson(const std::string& json) {
    auto message = std::make_unique<T>();
    ProtobufSerializer serializer;
    
    if (serializer.fromJson(json, message.get())) {
        return message;
    }
    
    return nullptr;
}

}  // namespace serialization
}  // namespace polyvault

#endif  // POLYVAULT_PROTOBUF_SERIALIZER_H