/**
 * @file key_manager.hpp
 * @brief 密钥管理系统
 * 
 * 功能：
 * - 密钥生成
 * - 密钥存储
 * - 密钥轮换
 * - 密钥撤销
 */

#pragma once

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <map>
#include <functional>
#include <optional>
#include <chrono>

namespace polyvault {
namespace security {

// ============================================================================
// 类型定义
// ============================================================================

/**
 * @brief 密钥类型
 */
enum class KeyType : uint8_t {
    SYMMETRIC = 1,      // 对称密钥 (AES)
    ASYMMETRIC = 2,     // 非对称密钥 (RSA/ECC)
    SESSION = 3,        // 会话密钥
    MASTER = 4          // 主密钥
};

/**
 * @brief 密钥算法
 */
enum class KeyAlgorithm : uint8_t {
    AES_256_GCM = 1,
    CHACHA20_POLY1305 = 2,
    RSA_2048 = 3,
    RSA_4096 = 4,
    ECC_P256 = 5,
    ED25519 = 6
};

/**
 * @brief 密钥状态
 */
enum class KeyStatus : uint8_t {
    ACTIVE = 1,
    EXPIRED = 2,
    REVOKED = 3,
    PENDING = 4
};

/**
 * @brief 密钥信息
 */
struct KeyInfo {
    std::string key_id;
    KeyType type;
    KeyAlgorithm algorithm;
    KeyStatus status;
    std::string label;                      // 密钥标签
    uint64_t created_time;
    uint64_t expires_time;
    uint64_t last_used_time;
    std::map<std::string, std::string> metadata;
};

// ============================================================================
// 密钥管理器配置
// ============================================================================

/**
 * @brief 密钥管理器配置
 */
struct KeyManagerConfig {
    std::string key_store_path = "./keys";  // 密钥存储路径
    uint32_t max_key_age_days = 90;         // 最大密钥有效期(天)
    bool enable_key_rotation = true;        // 启用密钥轮换
    uint32_t rotation_interval_days = 30;   // 轮换间隔
    bool allow_key_export = false;          // 允许导出密钥
};

// ============================================================================
// 密钥管理器
// ============================================================================

/**
 * @brief 密钥管理器
 * 
 * 功能：
 * - 生成和管理加密密钥
 * - 密钥存储和检索
 * - 密钥轮换和过期
 * - 审计日志
 */
class KeyManager {
public:
    explicit KeyManager(const KeyManagerConfig& config = {});
    ~KeyManager();
    
    // 生命周期
    bool initialize();
    void shutdown();
    
    // 密钥生成
    std::string generateKey(KeyType type, KeyAlgorithm algo, const std::string& label = "");
    std::string generateSessionKey(const std::string& session_id);
    
    // 密钥检索
    std::optional<std::vector<uint8_t>> getKey(const std::string& key_id);
    std::optional<KeyInfo> getKeyInfo(const std::string& key_id);
    std::vector<KeyInfo> listKeys(KeyType type = KeyType::SYMMETRIC);
    std::vector<KeyInfo> listActiveKeys();
    
    // 密钥操作
    bool deleteKey(const std::string& key_id);
    bool revokeKey(const std::string& key_id, const std::string& reason = "");
    bool rotateKey(const std::string& old_key_id);
    
    // 密钥验证
    bool validateKey(const std::string& key_id);
    bool isKeyExpired(const std::string& key_id);
    bool isKeyActive(const std::string& key_id);
    
    // 密钥导入/导出
    bool importKey(const std::vector<uint8_t>& key_data, 
                   KeyType type, 
                   const std::string& label);
    std::optional<std::vector<uint8_t>> exportKey(const std::string& key_id);
    
    // 会话密钥管理
    std::string createSession(const std::string& user_id);
    bool destroySession(const std::string& session_id);
    bool extendSession(const std::string& session_id, uint32_t extend_seconds);
    
    // 统计
    size_t getKeyCount() const;
    size_t getActiveKeyCount() const;
    
private:
    KeyManagerConfig config_;
    bool initialized_ = false;
    
    // 密钥存储
    std::mutex keys_mutex_;
    std::map<std::string, std::vector<uint8_t>> key_store_;
    std::map<std::string, KeyInfo> key_info_store_;
    
    // 会话管理
    std::mutex sessions_mutex_;
    std::map<std::string, std::string> session_to_key_;
    std::map<std::string, uint64_t> session_expiry_;
    
    // 审计回调
    std::function<void(const std::string&, const std::string&)> audit_callback_;
    
    // 内部方法
    std::vector<uint8_t> generateRandomBytes(size_t count);
    void cleanupExpiredKeys();
    void cleanupExpiredSessions();
    void audit(const std::string& event, const std::string& details);
    std::string generateKeyId();
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建KeyManager实例
 */
std::unique_ptr<KeyManager> createKeyManager(const KeyManagerConfig& config = {});

/**
 * @brief 生成随机密钥
 */
std::vector<uint8_t> generateRandomKey(KeyAlgorithm algo);

/**
 * @brief 验证密钥格式
 */
bool validateKeyFormat(const std::vector<uint8_t>& key_data, KeyType type);

} // namespace security
} // namespace polyvault