/**
 * @file zk_vault.hpp
 * @brief Zero-Knowledge Vault - 安全凭证存储
 * 
 * 功能：
 * - 零知识加密存储
 * - 密钥派生
 * - 安全会话管理
 */

#pragma once

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <functional>
#include <optional>
#include <chrono>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#endif

namespace polyvault {
namespace security {

// ============================================================================
// 配置
// ============================================================================

/**
 * @brief ZK Vault配置
 */
struct ZkVaultConfig {
    std::string vault_path = "./vault";          // 保险库路径
    std::string master_password;                  // 主密码
    uint32_t key_iterations = 100000;            // PBKDF2迭代次数
    uint32_t salt_length = 32;                   // 盐长度
    uint32_t key_length = 32;                    // 密钥长度
    bool auto_lock = true;                       // 自动锁定
    uint32_t auto_lock_timeout_ms = 300000;      // 自动锁定超时(5分钟)
};

// ============================================================================
// 加密项
// ============================================================================

/**
 * @brief 加密项元数据
 */
struct EncryptedItem {
    std::string item_id;
    std::string service_url;
    std::string encrypted_data;                  // 加密后的数据
    std::string nonce;                           // 随机数
    std::string tag;                             // 认证标签
    uint64_t created_time;
    uint64_t last_access_time;
    std::vector<uint8_t> encrypted_key;          // 加密的密钥
};

// ============================================================================
// ZK Vault主类
// ============================================================================

/**
 * @brief Zero-Knowledge Vault
 * 
 * 特性：
 * - 主密码本地派生密钥，不传输
 * - 每个条目独立加密
 * - 零知识证明支持
 */
class ZkVault {
public:
    explicit ZkVault(const ZkVaultConfig& config = {});
    ~ZkVault();
    
    // 生命周期
    bool initialize();
    bool unlock(const std::string& master_password);
    void lock();
    bool isUnlocked() const { return unlocked_; }
    
    // 凭证管理
    bool storeCredential(const std::string& service_url, 
                        const std::string& username,
                        const std::string& password);
    
    std::optional<std::string> getCredential(const std::string& service_url);
    
    bool deleteCredential(const std::string& service_url);
    
    std::vector<std::string> listServices();
    
    // 密钥管理
    std::vector<uint8_t> deriveKey(const std::string& password, 
                                   const std::vector<uint8_t>& salt);
    
    std::vector<uint8_t> generateSalt();
    
    // 自动锁定
    void resetAutoLockTimer();
    void setAutoLockCallback(std::function<void()> callback);
    
    // 安全审计
    void setAuditCallback(std::function<void(const std::string& event, 
                                              const std::string& details)> callback);
    
private:
    ZkVaultConfig config_;
    bool initialized_ = false;
    bool unlocked_ = false;
    
    // 密钥材料
    std::vector<uint8_t> master_key_;            // 派生后的主密钥
    std::vector<uint8_t> salt_;                  // 主盐
    
    // 加密项存储
    std::mutex items_mutex_;
    std::vector<EncryptedItem> items_;
    
    // 自动锁定
    std::thread auto_lock_thread_;
    std::atomic<bool> auto_lock_running_{false};
    std::function<void()> auto_lock_callback_;
    
    // 审计
    std::function<void(const std::string&, const std::string&)> audit_callback_;
    
    // 内部方法
    bool loadVault();
    bool saveVault();
    std::vector<uint8_t> encrypt(const std::vector<uint8_t>& plaintext,
                                 const std::vector<uint8_t>& key);
    std::optional<std::vector<uint8_t>> decrypt(const std::vector<uint8_t>& ciphertext,
                                                 const std::vector<uint8_t>& key);
    void autoLockLoop();
    void audit(const std::string& event, const std::string& details);
    std::string generateItemId();
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建Vault实例
 */
std::unique_ptr<ZkVault> createVault(const ZkVaultConfig& config = {});

/**
 * @brief 快速验证密码
 */
bool verifyPassword(const std::string& password, 
                   const std::string& hash,
                   const std::string& salt);

} // namespace security
} // namespace polyvault