/**
 * @file secure_credential_store.cpp
 * @brief 安全凭证存储实现 - 修复P0安全漏洞
 * 
 * 安全修复:
 * - SEC-001: AES-256-GCM加密存储
 * - SEC-002: 内存安全清理
 */

#include "credential_service.hpp"
#include "crypto_utils.hpp"
#include <iostream>
#include <chrono>
#include <memory>
#include <cstring>

namespace polyvault {

// 安全凭证存储
class SecureCredentialStore {
private:
    std::unordered_map<std::string, std::vector<uint8_t>> encrypted_store_;
    std::vector<uint8_t> master_key_;
    std::mutex mutex_;
    
    // 单例
    static SecureCredentialStore* instance_;
    static std::once_flag init_flag_;
    
    SecureCredentialStore() {
        // 生成随机主密钥（实际应从zk_vault或硬件安全模块获取）
        master_key_ = crypto::generateRandomBytes(32);
    }
    
public:
    ~SecureCredentialStore() {
        // 析构时安全清理
        secureWipe();
    }
    
    static SecureCredentialStore& getInstance() {
        std::call_once(init_flag_, []() {
            instance_ = new SecureCredentialStore();
        });
        return *instance_;
    }
    
    // 安全内存清理 - 修复SEC-002
    void secureWipe() {
        std::lock_guard<std::mutex> lock(mutex_);
        
        // 清理所有加密数据
        for (auto& pair : encrypted_store_) {
            std::memset(pair.second.data(), 0, pair.second.size());
        }
        encrypted_store_.clear();
        
        // 清理主密钥
        if (!master_key_.empty()) {
            std::memset(master_key_.data(), 0, master_key_.size());
            master_key_.clear();
        }
    }
    
    // 加密存储凭证 - 修复SEC-001
    bool storeCredential(const std::string& service_url, 
                         const std::string& plaintext) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        try {
            // 生成随机IV
            std::vector<uint8_t> iv = crypto::generateRandomBytes(12);
            
            // AES-256-GCM加密
            std::vector<uint8_t> plaintext_bytes(plaintext.begin(), plaintext.end());
            std::vector<uint8_t> encrypted = crypto::encryptAesGcm(
                plaintext_bytes, master_key_, iv);
            
            // 拼接 IV + 密文
            std::vector<uint8_t> stored;
            stored.reserve(iv.size() + encrypted.size());
            stored.insert(stored.end(), iv.begin(), iv.end());
            stored.insert(stored.end(), encrypted.begin(), encrypted.end());
            
            encrypted_store_[service_url] = std::move(stored);
            
            // 安全清理明文
            std::memset(plaintext_bytes.data(), 0, plaintext_bytes.size());
            
            std::cout << "[SecureCredentialStore] Encrypted credential stored for: " 
                      << service_url << std::endl;
            return true;
            
        } catch (const std::exception& e) {
            std::cerr << "[SecureCredentialStore] Encryption failed: " << e.what() << std::endl;
            return false;
        }
    }
    
    // 解密获取凭证
    std::optional<std::string> getCredential(const std::string& service_url) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        auto it = encrypted_store_.find(service_url);
        if (it == encrypted_store_.end()) {
            return std::nullopt;
        }
        
        try {
            const auto& stored = it->second;
            
            // 提取IV（前12字节）
            std::vector<uint8_t> iv(stored.begin(), stored.begin() + 12);
            
            // 提取密文（剩余部分）
            std::vector<uint8_t> ciphertext(stored.begin() + 12, stored.end());
            
            // 解密
            std::vector<uint8_t> decrypted = crypto::decryptAesGcm(
                ciphertext, master_key_, iv);
            
            std::string result(decrypted.begin(), decrypted.end());
            
            // 安全清理解密数据
            std::memset(decrypted.data(), 0, decrypted.size());
            
            return result;
            
        } catch (const std::exception& e) {
            std::cerr << "[SecureCredentialStore] Decryption failed: " << e.what() << std::endl;
            return std::nullopt;
        }
    }
    
    bool deleteCredential(const std::string& service_url) {
        std::lock_guard<std::mutex> lock(mutex_);
        
        auto it = encrypted_store_.find(service_url);
        if (it != encrypted_store_.end()) {
            // 安全清理后再删除
            std::memset(it->second.data(), 0, it->second.size());
            encrypted_store_.erase(it);
            return true;
        }
        return false;
    }
    
    bool hasCredential(const std::string& service_url) {
        std::lock_guard<std::mutex> lock(mutex_);
        return encrypted_store_.find(service_url) != encrypted_store_.end();
    }
};

// 静态初始化
SecureCredentialStore* SecureCredentialStore::instance_ = nullptr;
std::once_flag SecureCredentialStore::init_flag_;

// 修改CredentialService使用安全存储
std::optional<std::string> CredentialService::getCredential(const std::string& service_url) {
    return SecureCredentialStore::getInstance().getCredential(service_url);
}

bool CredentialService::storeCredential(const std::string& service_url, 
                                        const std::string& encrypted_credential) {
    // 加密后存储
    return SecureCredentialStore::getInstance().storeCredential(service_url, encrypted_credential);
}

bool CredentialService::deleteCredential(const std::string& service_url) {
    return SecureCredentialStore::getInstance().deleteCredential(service_url);
}

bool CredentialService::hasCredential(const std::string& service_url) {
    return SecureCredentialStore::getInstance().hasCredential(service_url);
}

} // namespace polyvault