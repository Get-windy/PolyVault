/**
 * @file key_manager.cpp
 * @brief 密钥管理实现
 */

#include "key_manager.hpp"

namespace polyvault {
namespace security {

KeyManager::KeyManager() {
    // 初始化密钥存储
}

KeyManager::~KeyManager() = default;

bool KeyManager::initialize() {
    initialized_ = true;
    return true;
}

std::vector<uint8_t> KeyManager::generateKey(int bits) {
    std::vector<uint8_t> key(bits / 8);
    for (size_t i = 0; i < key.size(); i++) {
        key[i] = static_cast<uint8_t>(i * 17 + 42);
    }
    return key;
}

std::string KeyManager::storeKey(const std::vector<uint8_t>& key, const std::string& name) {
    std::lock_guard<std::mutex> lock(mutex_);
    std::string id = "key_" + std::to_string(++key_counter_);
    keys_[id] = key;
    key_names_[id] = name;
    return id;
}

std::optional<std::vector<uint8_t>> KeyManager::retrieveKey(const std::string& key_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = keys_.find(key_id);
    if (it != keys_.end()) {
        return it->second;
    }
    return std::nullopt;
}

bool KeyManager::deleteKey(const std::string& key_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    keys_.erase(key_id);
    key_names_.erase(key_id);
    return true;
}

std::optional<std::vector<uint8_t>> KeyManager::rotateKey(const std::string& key_id) {
    auto old_key = retrieveKey(key_id);
    if (!old_key.has_value()) {
        return std::nullopt;
    }
    
    // 生成新密钥
    auto new_key = generateKey(old_key->size() * 8);
    
    // 更新存储
    std::lock_guard<std::mutex> lock(mutex_);
    keys_[key_id] = new_key;
    
    // 记录轮换历史
    rotation_history_[key_id].push_back(
        std::chrono::system_clock::now().time_since_epoch().count()
    );
    
    return new_key;
}

std::vector<std::string> KeyManager::listKeys() const {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<std::string> result;
    for (const auto& [id, _] : keys_) {
        result.push_back(id);
    }
    return result;
}

std::unique_ptr<KeyManager> createKeyManager() {
    return std::make_unique<KeyManager>();
}

} // namespace security
} // namespace polyvault