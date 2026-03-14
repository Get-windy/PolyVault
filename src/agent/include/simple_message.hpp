/**
 * @file simple_message.hpp
 * @brief 简化消息格式 - 不依赖Protobuf
 */

#pragma once

#include <string>
#include <vector>
#include <cstdint>
#include <cstring>
#include <map>
#include <sstream>

namespace polyvault {
namespace simple {

/**
 * @brief 简单二进制序列化器
 */
class BinaryWriter {
public:
    void writeUint32(uint32_t value) {
        // Varint编码
        while (value >= 0x80) {
            buffer_.push_back(static_cast<uint8_t>(value | 0x80));
            value >>= 7;
        }
        buffer_.push_back(static_cast<uint8_t>(value));
    }
    
    void writeUint64(uint64_t value) {
        while (value >= 0x80) {
            buffer_.push_back(static_cast<uint8_t>(value | 0x80));
            value >>= 7;
        }
        buffer_.push_back(static_cast<uint8_t>(value));
    }
    
    void writeString(const std::string& value) {
        writeUint32(static_cast<uint32_t>(value.size()));
        buffer_.insert(buffer_.end(), value.begin(), value.end());
    }
    
    void writeBytes(const std::vector<uint8_t>& value) {
        writeUint32(static_cast<uint32_t>(value.size()));
        buffer_.insert(buffer_.end(), value.begin(), value.end());
    }
    
    void writeBool(bool value) {
        buffer_.push_back(value ? 1 : 0);
    }
    
    const std::vector<uint8_t>& data() const { return buffer_; }
    std::vector<uint8_t>&& take() { return std::move(buffer_); }
    
    void clear() { buffer_.clear(); }

private:
    std::vector<uint8_t> buffer_;
};

/**
 * @brief 简单二进制反序列化器
 */
class BinaryReader {
public:
    explicit BinaryReader(const uint8_t* data, size_t size)
        : data_(data), size_(size), pos_(0) {}
    
    explicit BinaryReader(const std::vector<uint8_t>& data)
        : data_(data.data()), size_(data.size()), pos_(0) {}
    
    bool readUint32(uint32_t& value) {
        if (pos_ >= size_) return false;
        value = 0;
        int shift = 0;
        while (pos_ < size_) {
            uint8_t b = data_[pos_++];
            value |= static_cast<uint32_t>(b & 0x7F) << shift;
            if ((b & 0x80) == 0) break;
            shift += 7;
        }
        return true;
    }
    
    bool readUint64(uint64_t& value) {
        if (pos_ >= size_) return false;
        value = 0;
        int shift = 0;
        while (pos_ < size_) {
            uint8_t b = data_[pos_++];
            value |= static_cast<uint64_t>(b & 0x7F) << shift;
            if ((b & 0x80) == 0) break;
            shift += 7;
        }
        return true;
    }
    
    bool readString(std::string& value) {
        uint32_t size;
        if (!readUint32(size)) return false;
        if (pos_ + size > size_) return false;
        value.assign(reinterpret_cast<const char*>(data_ + pos_), size);
        pos_ += size;
        return true;
    }
    
    bool readBytes(std::vector<uint8_t>& value) {
        uint32_t size;
        if (!readUint32(size)) return false;
        if (pos_ + size > size_) return false;
        value.assign(data_ + pos_, data_ + pos_ + size);
        pos_ += size;
        return true;
    }
    
    bool readBool(bool& value) {
        if (pos_ >= size_) return false;
        value = data_[pos_++] != 0;
        return true;
    }
    
    size_t remaining() const { return size_ - pos_; }
    bool atEnd() const { return pos_ >= size_; }

private:
    const uint8_t* data_;
    size_t size_;
    size_t pos_;
};

/**
 * @brief 凭证请求消息
 */
struct CredentialRequest {
    std::string session_id;
    std::string service_url;
    int32_t credential_type = 0;
    std::string requester_id;
    int64_t timestamp = 0;
    int32_t timeout_ms = 5000;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeString(service_url);
        w.writeUint32(static_cast<uint32_t>(credential_type));
        w.writeString(requester_id);
        w.writeUint64(static_cast<uint64_t>(timestamp));
        w.writeUint32(static_cast<uint32_t>(timeout_ms));
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        return r.readString(session_id) &&
               r.readString(service_url) &&
               r.readUint32(reinterpret_cast<uint32_t&>(credential_type)) &&
               r.readString(requester_id) &&
               r.readUint64(reinterpret_cast<uint64_t&>(timestamp)) &&
               r.readUint32(reinterpret_cast<uint32_t&>(timeout_ms));
    }
};

/**
 * @brief 凭证响应消息
 */
struct CredentialResponse {
    std::string session_id;
    bool success = false;
    std::string encrypted_credential;
    std::string error_message;
    int32_t error_code = 0;
    int64_t timestamp = 0;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeBool(success);
        w.writeString(encrypted_credential);
        w.writeString(error_message);
        w.writeUint32(static_cast<uint32_t>(error_code));
        w.writeUint64(static_cast<uint64_t>(timestamp));
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        return r.readString(session_id) &&
               r.readBool(success) &&
               r.readString(encrypted_credential) &&
               r.readString(error_message) &&
               r.readUint32(reinterpret_cast<uint32_t&>(error_code)) &&
               r.readUint64(reinterpret_cast<uint64_t&>(timestamp));
    }
};

/**
 * @brief 心跳消息
 */
struct Heartbeat {
    std::string session_id;
    std::string agent_id;
    int64_t timestamp = 0;
    int32_t status = 0;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeString(agent_id);
        w.writeUint64(static_cast<uint64_t>(timestamp));
        w.writeUint32(static_cast<uint32_t>(status));
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        return r.readString(session_id) &&
               r.readString(agent_id) &&
               r.readUint64(reinterpret_cast<uint64_t&>(timestamp)) &&
               r.readUint32(reinterpret_cast<uint32_t&>(status));
    }
};

/**
 * @brief 心跳响应
 */
struct HeartbeatResponse {
    std::string session_id;
    std::string agent_id;
    int64_t timestamp = 0;
    int64_t server_time = 0;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeString(agent_id);
        w.writeUint64(static_cast<uint64_t>(timestamp));
        w.writeUint64(static_cast<uint64_t>(server_time));
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        return r.readString(session_id) &&
               r.readString(agent_id) &&
               r.readUint64(reinterpret_cast<uint64_t&>(timestamp)) &&
               r.readUint64(reinterpret_cast<uint64_t&>(server_time));
    }
};

/**
 * @brief Cookie数据
 */
struct Cookie {
    std::string name;
    std::string value;
    std::string domain;
    std::string path;
    int64_t expires = 0;
    bool secure = false;
    bool http_only = false;
    
    void serialize(BinaryWriter& w) const {
        w.writeString(name);
        w.writeString(value);
        w.writeString(domain);
        w.writeString(path);
        w.writeUint64(static_cast<uint64_t>(expires));
        w.writeBool(secure);
        w.writeBool(http_only);
    }
    
    bool deserialize(BinaryReader& r) {
        return r.readString(name) &&
               r.readString(value) &&
               r.readString(domain) &&
               r.readString(path) &&
               r.readUint64(reinterpret_cast<uint64_t&>(expires)) &&
               r.readBool(secure) &&
               r.readBool(http_only);
    }
};

/**
 * @brief Cookie上传消息
 */
struct CookieUpload {
    std::string session_id;
    std::vector<Cookie> cookies;
    std::string source_url;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeUint32(static_cast<uint32_t>(cookies.size()));
        for (const auto& c : cookies) {
            c.serialize(w);
        }
        w.writeString(source_url);
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        if (!r.readString(session_id)) return false;
        uint32_t count;
        if (!r.readUint32(count)) return false;
        cookies.resize(count);
        for (auto& c : cookies) {
            if (!c.deserialize(r)) return false;
        }
        return r.readString(source_url);
    }
};

/**
 * @brief Cookie上传响应
 */
struct CookieUploadResponse {
    std::string session_id;
    bool success = false;
    int32_t cookies_stored = 0;
    std::string error_message;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeBool(success);
        w.writeUint32(static_cast<uint32_t>(cookies_stored));
        w.writeString(error_message);
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        return r.readString(session_id) &&
               r.readBool(success) &&
               r.readUint32(reinterpret_cast<uint32_t&>(cookies_stored)) &&
               r.readString(error_message);
    }
};

/**
 * @brief 配置同步消息
 */
struct ConfigSync {
    std::string session_id;
    std::map<std::string, std::string> entries;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeUint32(static_cast<uint32_t>(entries.size()));
        for (const auto& [k, v] : entries) {
            w.writeString(k);
            w.writeString(v);
        }
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        if (!r.readString(session_id)) return false;
        uint32_t count;
        if (!r.readUint32(count)) return false;
        for (uint32_t i = 0; i < count; ++i) {
            std::string k, v;
            if (!r.readString(k) || !r.readString(v)) return false;
            entries[k] = v;
        }
        return true;
    }
};

/**
 * @brief 配置同步响应
 */
struct ConfigSyncResponse {
    std::string session_id;
    bool success = false;
    int32_t entries_synced = 0;
    std::string error_message;
    
    std::vector<uint8_t> serialize() const {
        BinaryWriter w;
        w.writeString(session_id);
        w.writeBool(success);
        w.writeUint32(static_cast<uint32_t>(entries_synced));
        w.writeString(error_message);
        return w.take();
    }
    
    bool deserialize(const std::vector<uint8_t>& data) {
        BinaryReader r(data);
        return r.readString(session_id) &&
               r.readBool(success) &&
               r.readUint32(reinterpret_cast<uint32_t&>(entries_synced)) &&
               r.readString(error_message);
    }
};

} // namespace simple
} // namespace polyvault