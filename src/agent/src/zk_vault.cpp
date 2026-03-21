/**
 * @file zk_vault.cpp
 * @brief ZK Vault实现
 */

#include "zk_vault.hpp"
#include "crypto_utils.hpp"
#include <iostream>
#include <fstream>
#include <sstream>
#include <algorithm>

// Windows crypto headers
#ifdef _WIN32
#include <windows.h>
#include <wincrypt.h>
#pragma comment(lib, "advapi32.lib")
#endif

namespace polyvault {
namespace security {

// ============================================================================
// ZkVault实现
// ============================================================================

ZkVault::ZkVault(const ZkVaultConfig& config) : config_(config) {}

ZkVault::~ZkVault() {
    lock();
    if (auto_lock_thread_.joinable()) {
        auto_lock_running_ = false;
        auto_lock_thread_.join();
    }
}

bool ZkVault::initialize() {
    if (initialized_) {
        return true;
    }
    
    std::cout << "[ZkVault] Initializing..." << std::endl;
    
    // 生成盐（如果是首次）
    if (salt_.empty()) {
        salt_ = generateSalt();
    }
    
    // 加载已有保险库
    if (!loadVault()) {
        std::cout << "[ZkVault] New vault created" << std::endl;
    }
    
    // 启动自动锁定线程
    if (config_.auto_lock) {
        auto_lock_running_ = true;
        auto_lock_thread_ = std::thread(&ZkVault::autoLockLoop, this);
    }
    
    initialized_ = true;
    std::cout << "[ZkVault] Initialized successfully" << std::endl;
    return true;
}

bool ZkVault::unlock(const std::string& master_password) {
    if (unlocked_) {
        return true;
    }
    
    std::cout << "[ZkVault] Unlocking vault..." << std::endl;
    
    // 派生密钥
    master_key_ = deriveKey(master_password, salt_);
    
    // 尝试解密一个已知项来验证密码
    // 简化实现：检查派生密钥是否有效
    if (master_key_.empty()) {
        std::cerr << "[ZkVault] Failed to derive key" << std::endl;
        return false;
    }
    
    unlocked_ = true;
    resetAutoLockTimer();
    audit("VAULT_UNLOCK", "Vault unlocked successfully");
    
    std::cout << "[ZkVault] Unlocked" << std::endl;
    return true;
}

void ZkVault::lock() {
    if (!unlocked_) {
        return;
    }
    
    std::cout << "[ZkVault] Locking vault..." << std::endl;
    
    // 清除密钥材料
    std::fill(master_key_.begin(), master_key_.end(), 0);
    master_key_.clear();
    
    unlocked_ = false;
    audit("VAULT_LOCK", "Vault locked");
    
    if (auto_lock_callback_) {
        auto_lock_callback_();
    }
}

bool ZkVault::storeCredential(const std::string& service_url,
                             const std::string& username,
                             const std::string& password) {
    if (!unlocked_) {
        std::cerr << "[ZkVault] Vault is locked" << std::endl;
        return false;
    }
    
    // 构建明文数据
    std::string plain_data = username + "\x00" + password;
    std::vector<uint8_t> plain_vec(plain_data.begin(), plain_data.end());
    
    // 加密
    auto encrypted = encrypt(plain_vec, master_key_);
    if (encrypted.empty()) {
        std::cerr << "[ZkVault] Encryption failed" << std::endl;
        return false;
    }
    
    // 生成随机nonce
    std::vector<uint8_t> nonce = generateSalt();
    
    // 创建加密项
    EncryptedItem item;
    item.item_id = generateItemId();
    item.service_url = service_url;
    item.encrypted_data = std::string(encrypted.begin(), encrypted.end());
    item.nonce = std::string(nonce.begin(), nonce.end());
    item.created_time = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    item.last_access_time = item.created_time;
    
    // 存储
    std::lock_guard<std::mutex> lock(items_mutex_);
    items_.push_back(item);
    
    // 保存到磁盘
    saveVault();
    
    audit("CREDENTIAL_STORE", "Stored credential for: " + service_url);
    std::cout << "[ZkVault] Stored credential for: " << service_url << std::endl;
    
    return true;
}

std::optional<std::string> ZkVault::getCredential(const std::string& service_url) {
    if (!unlocked_) {
        std::cerr << "[ZkVault] Vault is locked" << std::endl;
        return std::nullopt;
    }
    
    resetAutoLockTimer();
    
    std::lock_guard<std::mutex> lock(items_mutex_);
    
    for (auto& item : items_) {
        if (item.service_url == service_url) {
            // 解密
            std::vector<uint8_t> cipher_vec(item.encrypted_data.begin(), 
                                            item.encrypted_data.end());
            auto decrypted = decrypt(cipher_vec, master_key_);
            
            if (!decrypted.has_value()) {
                std::cerr << "[ZkVault] Decryption failed" << std::endl;
                return std::nullopt;
            }
            
            // 解析username和password
            std::string plain_str(decrypted->begin(), decrypted->end());
            size_t null_pos = plain_str.find('\x00');
            
            if (null_pos != std::string::npos) {
                std::string username = plain_str.substr(0, null_pos);
                std::string password = plain_str.substr(null_pos + 1);
                
                item.last_access_time = std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::system_clock::now().time_since_epoch()).count();
                
                audit("CREDENTIAL_ACCESS", "Accessed credential for: " + service_url);
                
                // 返回格式: username:password
                return username + ":" + password;
            }
        }
    }
    
    return std::nullopt;
}

bool ZkVault::deleteCredential(const std::string& service_url) {
    if (!unlocked_) {
        return false;
    }
    
    std::lock_guard<std::mutex> lock(items_mutex_);
    
    auto it = std::find_if(items_.begin(), items_.end(),
        [&service_url](const EncryptedItem& item) {
            return item.service_url == service_url;
        });
    
    if (it != items_.end()) {
        items_.erase(it);
        saveVault();
        audit("CREDENTIAL_DELETE", "Deleted credential for: " + service_url);
        return true;
    }
    
    return false;
}

std::vector<std::string> ZkVault::listServices() {
    std::lock_guard<std::mutex> lock(items_mutex_);
    
    std::vector<std::string> services;
    for (const auto& item : items_) {
        services.push_back(item.service_url);
    }
    
    return services;
}

std::vector<uint8_t> ZkVault::deriveKey(const std::string& password, 
                                         const std::vector<uint8_t>& salt) {
    // 使用PBKDF2派生密钥
    return crypto::pbkdf2_sha256(password, salt, config_.key_iterations, 
                                  config_.key_length);
}

std::vector<uint8_t> ZkVault::generateSalt() {
    std::vector<uint8_t> salt(config_.salt_length);
    
#ifdef _WIN32
    HCRYPTPROV hProv = 0;
    if (CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_AES, 0)) {
        if (!CryptGenRandom(hProv, config_.salt_length, salt.data())) {
            // CR-003: 检查返回值
            throw std::runtime_error("CryptGenRandom failed");
        }
        CryptReleaseContext(hProv, 0);
    } else {
        throw std::runtime_error("CryptAcquireContext failed");
    }
#else
    // 使用安全的随机数生成
    crypto::generateRandomBytes(salt.size(), salt.data());
#endif
    
    return salt;
}

void ZkVault::resetAutoLockTimer() {
    // 重置自动锁定计时器
}

void ZkVault::setAutoLockCallback(std::function<void()> callback) {
    auto_lock_callback_ = std::move(callback);
}

void ZkVault::setAuditCallback(
    std::function<void(const std::string&, const std::string&)> callback) {
    audit_callback_ = std::move(callback);
}

bool ZkVault::loadVault() {
    // 简化实现：检查文件是否存在
    std::ifstream file(config_.vault_path + "/vault.dat", std::ios::binary);
    return file.good();
}

bool ZkVault::saveVault() {
    // 简化实现：保存到文件
    std::ofstream file(config_.vault_path + "/vault.dat", std::ios::binary);
    
    if (!file.good()) {
        return false;
    }
    
    // 保存盐
    uint32_t salt_len = static_cast<uint32_t>(salt_.size());
    file.write(reinterpret_cast<const char*>(&salt_len), sizeof(salt_len));
    file.write(reinterpret_cast<const char*>(salt_.data()), salt_len);
    
    // 保存项数量
    uint32_t item_count = static_cast<uint32_t>(items_.size());
    file.write(reinterpret_cast<const char*>(&item_count), sizeof(item_count));
    
    return true;
}

std::vector<uint8_t> ZkVault::encrypt(const std::vector<uint8_t>& plaintext,
                                      const std::vector<uint8_t>& key) {
    // 使用AES-GCM加密
    return crypto::encrypt_aes_gcm(plaintext, key);
}

std::optional<std::vector<uint8_t>> ZkVault::decrypt(const std::vector<uint8_t>& ciphertext,
                                                      const std::vector<uint8_t>& key) {
    return crypto::decrypt_aes_gcm(ciphertext, key);
}

void ZkVault::autoLockLoop() {
    while (auto_lock_running_) {
        std::this_thread::sleep_for(std::chrono::seconds(30));
        
        if (unlocked_ && config_.auto_lock) {
            // 检查是否超时
            // 简化实现
        }
    }
}

void ZkVault::audit(const std::string& event, const std::string& details) {
    if (audit_callback_) {
        audit_callback_(event, details);
    }
    
    // 同时输出到控制台
    std::cout << "[AUDIT] " << event << ": " << details << std::endl;
}

std::string ZkVault::generateItemId() {
    static uint64_t counter = 0;
    auto now = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    return "item_" + std::to_string(now) + "_" + std::to_string(++counter);
}

// ============================================================================
// 便捷函数
// ============================================================================

std::unique_ptr<ZkVault> createVault(const ZkVaultConfig& config) {
    return std::make_unique<ZkVault>(config);
}

bool verifyPassword(const std::string& password, 
                    const std::string& hash,
                    const std::string& salt) {
    // 简化实现
    return false;
}

} // namespace security
} // namespace polyvault