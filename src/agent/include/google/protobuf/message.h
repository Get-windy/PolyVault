// Minimal Protobuf Runtime Header Compatibility Layer
// This provides minimal definitions needed for generated protobuf code
// Full protobuf library should be linked in production

#pragma once

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <cstdint>
#include <cstring>
#include <stdexcept>

namespace google {
namespace protobuf {

// Forward declarations
class Message;
class MessageLite;
class Arena;

// Field types
enum WireType {
    WIRETYPE_VARINT = 0,
    WIRETYPE_FIXED64 = 1,
    WIRETYPE_LENGTH_DELIMITED = 2,
    WIRETYPE_START_GROUP = 3,
    WIRETYPE_END_GROUP = 4,
    WIRETYPE_FIXED32 = 5,
};

// Base class for all messages
class MessageLite {
public:
    MessageLite() = default;
    virtual ~MessageLite() = default;
    
    virtual size_t ByteSizeLong() const = 0;
    virtual bool SerializeToArray(void* data, size_t size) const = 0;
    virtual bool ParseFromArray(const void* data, size_t size) = 0;
    
    size_t ByteSize() const { return ByteSizeLong(); }
    
    bool SerializeToString(std::string* output) const {
        output->resize(ByteSizeLong());
        return SerializeToArray(&(*output)[0], output->size());
    }
    
    bool ParseFromString(const std::string& input) {
        return ParseFromArray(input.data(), input.size());
    }
    
    virtual void Clear() = 0;
    virtual bool IsInitialized() const { return true; }
};

// Message base class with reflection support
class Message : public MessageLite {
public:
    Message() = default;
    virtual ~Message() = default;
    
    virtual const char* GetTypeName() const = 0;
    virtual Message* New() const = 0;
};

// Arena for memory management
class Arena {
public:
    Arena() = default;
    ~Arena() = default;
    
    template<typename T>
    T* CreateMessage() {
        return new T();
    }
};

// Internal utilities
namespace internal {

inline uint32_t WireFormatLiteMakeTag(int field_number, WireType type) {
    return (static_cast<uint32_t>(field_number) << 3) | static_cast<uint32_t>(type);
}

inline void WireFormatLiteWriteTag(int field_number, WireType type, 
                                    std::vector<uint8_t>* output) {
    uint32_t tag = WireFormatLiteMakeTag(field_number, type);
    while (tag >= 0x80) {
        output->push_back(static_cast<uint8_t>(tag | 0x80));
        tag >>= 7;
    }
    output->push_back(static_cast<uint8_t>(tag));
}

inline size_t WireFormatLiteTagSize(int field_number, WireType type) {
    size_t result = 1;
    uint32_t tag = WireFormatLiteMakeTag(field_number, type);
    while (tag >= 0x80) {
        ++result;
        tag >>= 7;
    }
    return result;
}

} // namespace internal

// io utilities
namespace io {

class CodedInputStream {
public:
    explicit CodedInputStream(const uint8_t* data, size_t size)
        : data_(data), size_(size), pos_(0) {}
    
    bool ReadVarint32(uint32_t* value) {
        if (pos_ >= size_) return false;
        uint32_t result = 0;
        int shift = 0;
        while (pos_ < size_) {
            uint8_t b = data_[pos_++];
            result |= static_cast<uint32_t>(b & 0x7F) << shift;
            if ((b & 0x80) == 0) break;
            shift += 7;
        }
        *value = result;
        return true;
    }
    
    bool ReadString(std::string* value, size_t size) {
        if (pos_ + size > size_) return false;
        value->assign(reinterpret_cast<const char*>(data_ + pos_), size);
        pos_ += size;
        return true;
    }
    
    bool Skip(size_t count) {
        if (pos_ + count > size_) return false;
        pos_ += count;
        return true;
    }
    
    size_t CurrentPosition() const { return pos_; }
    size_t BytesUntilLimit() const { return size_ - pos_; }

private:
    const uint8_t* data_;
    size_t size_;
    size_t pos_;
};

class CodedOutputStream {
public:
    explicit CodedOutputStream(uint8_t* data, size_t size)
        : data_(data), size_(size), pos_(0) {}
    
    void WriteVarint32(uint32_t value) {
        while (value >= 0x80) {
            data_[pos_++] = static_cast<uint8_t>(value | 0x80);
            value >>= 7;
        }
        data_[pos_++] = static_cast<uint8_t>(value);
    }
    
    void WriteString(const std::string& value) {
        WriteVarint32(static_cast<uint32_t>(value.size()));
        std::memcpy(data_ + pos_, value.data(), value.size());
        pos_ += value.size();
    }
    
    void WriteRaw(const void* data, size_t size) {
        std::memcpy(data_ + pos_, data, size);
        pos_ += size;
    }
    
    size_t CurrentPosition() const { return pos_; }

private:
    uint8_t* data_;
    size_t size_;
    size_t pos_;
};

} // namespace io

// Reflection stubs
namespace reflection {
    
class FieldDescriptor {
public:
    int number() const { return 0; }
};

class Descriptor {
public:
    const FieldDescriptor* FindFieldByName(const std::string&) const { return nullptr; }
};

} // namespace reflection

} // namespace protobuf
} // namespace google

// Version stub
#define GOOGLE_PROTOBUF_VERSION 5010000

// Runtime version stub
inline int ProtobufRuntimeVersion() { return GOOGLE_PROTOBUF_VERSION; }