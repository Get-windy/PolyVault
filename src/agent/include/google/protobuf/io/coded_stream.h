// Protobuf IO Utilities
#pragma once

#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

namespace google {
namespace protobuf {
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
    
    bool ReadVarint64(uint64_t* value) {
        if (pos_ >= size_) return false;
        uint64_t result = 0;
        int shift = 0;
        while (pos_ < size_) {
            uint8_t b = data_[pos_++];
            result |= static_cast<uint64_t>(b & 0x7F) << shift;
            if ((b & 0x80) == 0) break;
            shift += 7;
        }
        *value = result;
        return true;
    }
    
    bool ReadLittleEndian32(uint32_t* value) {
        if (pos_ + 4 > size_) return false;
        std::memcpy(value, data_ + pos_, 4);
        pos_ += 4;
        return true;
    }
    
    bool ReadLittleEndian64(uint64_t* value) {
        if (pos_ + 8 > size_) return false;
        std::memcpy(value, data_ + pos_, 8);
        pos_ += 8;
        return true;
    }
    
    bool ReadString(std::string* value, size_t size) {
        if (pos_ + size > size_) return false;
        value->assign(reinterpret_cast<const char*>(data_ + pos_), size);
        pos_ += size;
        return true;
    }
    
    bool ReadRaw(void* data, size_t size) {
        if (pos_ + size > size_) return false;
        std::memcpy(data, data_ + pos_, size);
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
    const uint8_t* CurrentPointer() const { return data_ + pos_; }

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
    
    void WriteVarint64(uint64_t value) {
        while (value >= 0x80) {
            data_[pos_++] = static_cast<uint8_t>(value | 0x80);
            value >>= 7;
        }
        data_[pos_++] = static_cast<uint8_t>(value);
    }
    
    void WriteLittleEndian32(uint32_t value) {
        std::memcpy(data_ + pos_, &value, 4);
        pos_ += 4;
    }
    
    void WriteLittleEndian64(uint64_t value) {
        std::memcpy(data_ + pos_, &value, 8);
        pos_ += 8;
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
    uint8_t* CurrentPointer() { return data_ + pos_; }

private:
    uint8_t* data_;
    size_t size_;
    size_t pos_;
};

} // namespace io
} // namespace protobuf
} // namespace google