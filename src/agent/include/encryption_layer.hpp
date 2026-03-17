/**
 * @file encryption_layer.hpp
 * @brief PolyVault 加密通信层
 * 
 * 功能：
 * - 端到端加密 (E2EE)
 * - 密钥交换 (ECDH)
 * - 消息签名验证
 * - 前向安全
 */

#ifndef POLYVAULT_ENCRYPTION_LAYER_HPP
#define POLYVAULT_ENCRYPTION_LAYER_HPP

#include <string>
#include <vector>
#include <memory>
#include <optional>
#include <array>
#include <mutex>

// ============================================================================
// 加密常量
// ============================================================================

namespace crypto {

constexpr size_t KEY_SIZE = 32;           // AES-256
constexpr size_t NONCE_SIZE = 12;         // GCM nonce
constexpr size_t TAG_SIZE = 16;           // GCM auth tag
constexpr size_t PUBLIC_KEY_SIZE = 32;    // X25519 public key
constexpr size_t PRIVATE_KEY_SIZE = 32;   // X25519 private key
constexpr size_t SIGNATURE_SIZE = 64;     // Ed25519 signature

} // namespace crypto

// ============================================================================
// 密钥类型
// ============================================================================

using PublicKey = std::array<uint8_t, crypto::PUBLIC_KEY_SIZE>;
using PrivateKey = std::array<uint8_t, crypto::PRIVATE_KEY_SIZE>;
using SharedSecret = std::array<uint8_t, crypto::KEY_SIZE>;
using Nonce = std::array<uint8_t, crypto::NONCE_SIZE>;
using Signature = std::array<uint8_t, crypto::SIGNATURE_SIZE>;
using EncryptedData = std::vector<uint8_t>;

// ============================================================================
// 密钥对
// ============================================================================

struct KeyPair {
    PublicKey public_key;
    PrivateKey private_key;
    
    /**
     * @brief 生成新密钥对
     */
    static KeyPair generate();
    
    /**
     * @brief 从PEM格式导入
     */
    static std::optional<KeyPair> fromPEM(const std::string& pem);
    
    /**
     * @brief 导出为PEM格式
     */
    std::string toPEM() const;
};

// ============================================================================
// 加密上下文
// ============================================================================

struct EncryptionContext {
    std::string session_id;
    SharedSecret session_key;
    Nonce send_nonce;
    Nonce receive_nonce;
    uint64_t send_counter;
    uint64_t receive_counter;
    Timestamp created_at;
    Timestamp expires_at;
};

// ============================================================================
// 加密消息格式
// ============================================================================

struct EncryptedMessage {
    uint8_t version;
    Nonce nonce;
    EncryptedData ciphertext;      // 包含 GCM tag
    Signature signature;            // 可选：消息签名
    
    /**
     * @brief 序列化
     */
    std::vector<uint8_t> serialize() const;
    
    /**
     * @brief 反序列化
     */
    static std::optional<EncryptedMessage> deserialize(const std::vector<uint8_t>& data);
};

// ============================================================================
// 加密层接口
// ============================================================================

class EncryptionLayer {
public:
    EncryptionLayer();
    ~EncryptionLayer();
    
    // 禁止拷贝
    EncryptionLayer(const EncryptionLayer&) = delete;
    EncryptionLayer& operator=(const EncryptionLayer&) = delete;
    
    // ==================== 密钥管理 ====================
    
    /**
     * @brief 生成身份密钥对
     */
    void generateIdentityKeyPair();
    
    /**
     * @brief 获取公钥
     */
    PublicKey getPublicKey() const;
    
    /**
     * @brief 导出公钥 (Base64)
     */
    std::string exportPublicKeyBase64() const;
    
    /**
     * @brief 导入公钥 (Base64)
     */
    static std::optional<PublicKey> importPublicKeyBase64(const std::string& base64);
    
    // ==================== 密钥交换 ====================
    
    /**
     * @brief 生成临时密钥对 (用于密钥交换)
     */
    KeyPair generateEphemeralKeyPair();
    
    /**
     * @brief 计算共享密钥 (ECDH)
     */
    SharedSecret computeSharedSecret(
        const PrivateKey& our_private,
        const PublicKey& their_public
    );
    
    /**
     * @brief 执行密钥交换握手
     */
    std::optional<SharedSecret> performKeyExchange(
        const PublicKey& their_public_key
    );
    
    // ==================== 会话管理 ====================
    
    /**
     * @brief 创建加密会话
     */
    std::string createSession(const std::string& peer_id, const SharedSecret& secret);
    
    /**
     * @brief 获取会话
     */
    std::optional<EncryptionContext> getSession(const std::string& session_id) const;
    
    /**
     * @brief 销毁会话
     */
    void destroySession(const std::string& session_id);
    
    /**
     * @brief 轮换会话密钥 (前向安全)
     */
    bool rotateSessionKey(const std::string& session_id);
    
    // ==================== 加密/解密 ====================
    
    /**
     * @brief 加密数据
     */
    std::optional<EncryptedMessage> encrypt(
        const std::string& session_id,
        const std::vector<uint8_t>& plaintext
    );
    
    /**
     * @brief 解密数据
     */
    std::optional<std::vector<uint8_t>> decrypt(
        const std::string& session_id,
        const EncryptedMessage& message
    );
    
    /**
     * @brief 加密字符串
     */
    std::optional<EncryptedMessage> encryptString(
        const std::string& session_id,
        const std::string& plaintext
    );
    
    /**
     * @brief 解密为字符串
     */
    std::optional<std::string> decryptToString(
        const std::string& session_id,
        const EncryptedMessage& message
    );
    
    // ==================== 签名 ====================
    
    /**
     * @brief 签名数据
     */
    Signature sign(const std::vector<uint8_t>& data) const;
    
    /**
     * @brief 验证签名
     */
    bool verify(
        const std::vector<uint8_t>& data,
        const Signature& signature,
        const PublicKey& signer_public_key
    ) const;
    
    /**
     * @brief 签名消息
     */
    void signMessage(EncryptedMessage& message);
    
    /**
     * @brief 验证消息签名
     */
    bool verifyMessage(
        const EncryptedMessage& message,
        const PublicKey& signer_public_key
    ) const;
    
    // ==================== 工具 ====================
    
    /**
     * @brief 生成随机nonce
     */
    Nonce generateNonce() const;
    
    /**
     * @brief 派生密钥 (HKDF)
     */
    std::vector<uint8_t> deriveKey(
        const std::vector<uint8_t>& input_key_material,
        const std::string& info,
        size_t output_length = crypto::KEY_SIZE
    ) const;
    
    /**
     * @brief 计算哈希 (SHA-256)
     */
    std::array<uint8_t, 32> hash(const std::vector<uint8_t>& data) const;
    
    /**
     * @brief 安全擦除内存
     */
    static void secureWipe(std::vector<uint8_t>& data);
    static void secureWipe(uint8_t* data, size_t size);

private:
    // 身份密钥对
    KeyPair identity_keypair_;
    mutable std::mutex identity_mutex_;
    
    // 会话映射
    std::map<std::string, EncryptionContext> sessions_;
    mutable std::mutex sessions_mutex_;
    
    // 加密后端 (可选的平台特定实现)
    void* crypto_backend_;
    
    // 内部方法
    Nonce incrementNonce(const Nonce& nonce) const;
    bool encryptAESGCM(
        const std::vector<uint8_t>& plaintext,
        const SharedSecret& key,
        const Nonce& nonce,
        std::vector<uint8_t>& ciphertext
    );
    bool decryptAESGCM(
        const std::vector<uint8_t>& ciphertext,
        const SharedSecret& key,
        const Nonce& nonce,
        std::vector<uint8_t>& plaintext
    );
};

// ============================================================================
// TLS/SSL 包装器
// ============================================================================

class TLSSocket {
public:
    TLSSocket();
    ~TLSSocket();
    
    /**
     * @brief 连接到服务器
     */
    bool connect(const std::string& host, int port);
    
    /**
     * @brief 接受连接 (服务端)
     */
    bool accept(int server_socket);
    
    /**
     * @brief 发送数据
     */
    ssize_t send(const std::vector<uint8_t>& data);
    
    /**
     * @brief 接收数据
     */
    ssize_t receive(std::vector<uint8_t>& buffer, size_t max_size);
    
    /**
     * @brief 关闭连接
     */
    void close();
    
    /**
     * @brief 验证对端证书
     */
    bool verifyPeer() const;
    
    /**
     * @brief 获取对端证书指纹
     */
    std::string getPeerCertificateFingerprint() const;

private:
    void* ssl_ctx_;
    void* ssl_;
    int socket_;
};

// ============================================================================
// 端到端加密通道
// ============================================================================

class E2EEChannel {
public:
    struct ChannelConfig {
        bool require_signature;
        bool enable_forward_secrecy;
        int key_rotation_interval_ms;
        int session_timeout_ms;
    };
    
    E2EEChannel(const ChannelConfig& config);
    ~E2EEChannel();
    
    /**
     * @brief 初始化通道 (发起方)
     */
    std::vector<uint8_t> initiateHandshake();
    
    /**
     * @brief 处理握手消息
     */
    std::optional<std::vector<uint8_t>> processHandshake(
        const std::vector<uint8_t>& message
    );
    
    /**
     * @brief 检查握手是否完成
     */
    bool isHandshakeComplete() const;
    
    /**
     * @brief 发送加密消息
     */
    std::optional<EncryptedMessage> sendMessage(
        const std::vector<uint8_t>& data
    );
    
    /**
     * @brief 接收并解密消息
     */
    std::optional<std::vector<uint8_t>> receiveMessage(
        const EncryptedMessage& message
    );
    
    /**
     * @brief 关闭通道
     */
    void close();

private:
    ChannelConfig config_;
    EncryptionLayer encryption_;
    
    enum class State {
        INIT,
        HANDSHAKE_SENT,
        HANDSHAKE_RECEIVED,
        ESTABLISHED,
        CLOSED
    } state_;
    
    PublicKey peer_public_key_;
    std::string session_id_;
};

// ============================================================================
// 导出
// ============================================================================

using Timestamp = uint64_t;

} // namespace polyvault

#endif // POLYVAULT_ENCRYPTION_LAYER_HPP