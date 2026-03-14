/**
 * @file signature.hpp
 * @brief 签名验证模块
 * 
 * 功能：
 * - 数字签名
 * - 签名验证
 * - 证书管理
 * - 时间戳验证
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

#ifdef USE_ECAL
#include <ecal/ecal.h>
#endif

namespace polyvault {
namespace security {

// ============================================================================
// 类型定义
// ============================================================================

/**
 * @brief 签名算法
 */
enum class SignatureAlgorithm : uint8_t {
    RSA_SHA256 = 1,
    RSA_SHA512 = 2,
    ECDSA_P256 = 3,
    ECDSA_P384 = 4,
    ED25519 = 5,
    HMAC_SHA256 = 6,
    HMAC_SHA512 = 7
};

/**
 * @brief 签名结果
 */
struct SignatureResult {
    bool success;
    std::string error_message;
    std::vector<uint8_t> signature;
    uint64_t timestamp;
    std::string signer_id;
};

/**
 * @brief 验证结果
 */
struct VerificationResult {
    bool valid;
    std::string error_message;
    bool expired;
    bool revoked;
    uint64_t timestamp;
    std::string signer_id;
    std::map<std::string, std::string> metadata;
};

// ============================================================================
// 签名器/验证器配置
// ============================================================================

/**
 * @brief 签名器配置
 */
struct SignerConfig {
    std::string private_key_path;            // 私钥路径
    std::string certificate_path;            // 证书路径
    SignatureAlgorithm algorithm = SignatureAlgorithm::ED25519;
    bool auto_rotate = true;               // 自动轮换密钥
    uint32_t validity_days = 365;           // 有效期
};

// ============================================================================
// 签名器
// ============================================================================

/**
 * @brief 数字签名器
 */
class Signer {
public:
    explicit Signer(const SignerConfig& config);
    ~Signer();
    
    // 初始化
    bool initialize();
    
    // 签名操作
    SignatureResult sign(const std::vector<uint8_t>& data);
    SignatureResult sign(const std::string& data);
    
    // 获取信息
    std::string getSignerId() const { return signer_id_; }
    SignatureAlgorithm getAlgorithm() const { return config_.algorithm; }
    bool isInitialized() const { return initialized_; }
    
private:
    SignerConfig config_;
    bool initialized_ = false;
    std::string signer_id_;
    std::vector<uint8_t> private_key_;
    
    // 审计
    std::function<void(const std::string&, const std::string&)> audit_callback_;
    
    // 内部方法
    bool loadPrivateKey();
    std::vector<uint8_t> computeHash(const std::vector<uint8_t>& data);
    void audit(const std::string& event, const std::string& details);
};

// ============================================================================
// 验证器
// ============================================================================

/**
 * @brief 签名验证器
 */
class Verifier {
public:
    Verifier();
    ~Verifier();
    
    // 初始化
    bool initialize();
    
    // 验证操作
    VerificationResult verify(const std::vector<uint8_t>& data,
                            const std::vector<uint8_t>& signature,
                            const std::string& signer_id);
    
    VerificationResult verify(const std::string& data,
                            const std::string& signature_b64,
                            const std::string& signer_id);
    
    // 证书管理
    bool addTrustedCertificate(const std::string& cert_id,
                               const std::vector<uint8_t>& public_key,
                               const std::string& name);
    
    bool removeCertificate(const std::string& cert_id);
    
    bool isCertificateTrusted(const std::string& cert_id);
    
    // 吊销检查
    void addToRevocationList(const std::string& cert_id);
    bool isRevoked(const std::string& cert_id);
    
    // 批量验证
    std::vector<VerificationResult> verifyBatch(
        const std::vector<std::tuple<std::vector<uint8_t>, std::vector<uint8_t>, std::string>>& items);
    
private:
    bool initialized_ = false;
    
    // 受信任证书
    std::mutex cert_mutex_;
    std::map<std::string, std::vector<uint8_t>> trusted_certs_;
    std::map<std::string, std::string> cert_names_;
    
    // 吊销列表
    std::mutex revocation_mutex_;
    std::set<std::string> revocation_list_;
    
    // 审计
    std::function<void(const std::string&, const std::string&)> audit_callback_;
    
    // 内部方法
    bool loadSystemCertificates();
    std::vector<uint8_t> computeHash(const std::vector<uint8_t>& data);
    void audit(const std::string& event, const std::string& details);
};

// ============================================================================
// 签名服务
// ============================================================================

/**
 * @brief 签名服务（统一接口）
 */
class SignatureService {
public:
    SignatureService();
    ~SignatureService();
    
    // 初始化
    bool initialize();
    
    // 创建签名
    SignatureResult signData(const std::string& key_id, 
                            const std::vector<uint8_t>& data);
    
    // 验证签名
    VerificationResult verifyData(const std::vector<uint8_t>& data,
                                 const std::vector<uint8_t>& signature,
                                 const std::string& signer_id);
    
    // 批量操作
    std::vector<VerificationResult> verifyDataBatch(
        const std::vector<std::tuple<std::vector<uint8_t>, 
                                     std::vector<uint8_t>, 
                                     std::string>>& items);
    
    // 密钥注册
    bool registerSigner(const std::string& key_id, 
                        const std::vector<uint8_t>& private_key,
                        const SignerConfig& config);
    
    // 时间戳服务
    uint64_t getTrustedTimestamp();
    
private:
    bool initialized_ = false;
    
    // 签名器管理
    std::mutex signers_mutex_;
    std::map<std::string, std::unique_ptr<Signer>> signers_;
    
    // 验证器
    std::unique_ptr<Verifier> verifier_;
    
    // 审计
    std::function<void(const std::string&, const std::string&)> audit_callback_;
    
    // 内部方法
    void audit(const std::string& event, const std::string& details);
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建Signer实例
 */
std::unique_ptr<Signer> createSigner(const SignerConfig& config);

/**
 * @brief 创建Verifier实例
 */
std::unique_ptr<Verifier> createVerifier();

/**
 * @brief Base64编码签名
 */
std::string signatureToBase64(const std::vector<uint8_t>& signature);

/**
 * @brief Base64解码签名
 */
std::optional<std::vector<uint8_t>> signatureFromBase64(const std::string& b64);

/**
 * @brief 计算数据哈希
 */
std::vector<uint8_t> computeDataHash(const std::vector<uint8_t>& data, 
                                      SignatureAlgorithm algo);

} // namespace security
} // namespace polyvault