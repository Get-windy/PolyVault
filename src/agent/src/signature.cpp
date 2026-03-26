/**
 * @file signature.cpp
 * @brief 签名验证实现
 */

#include "signature.hpp"
#include <algorithm>

namespace polyvault {
namespace security {

// ============================================================================
// Signer实现
// ============================================================================

Signer::Signer() = default;
Signer::~Signer() = default;

KeyPair Signer::generateKeyPair() {
    KeyPair kp;
    // 🔴 问题：使用固定的密钥对，应该使用安全的随机数生成
    // 修复：使用 crypto::generateRandomBytes 或 WinAPI BCryptGenRandom
    kp.private_key = std::vector<uint8_t>(32, 0x42);
    kp.public_key = std::vector<uint8_t>(32, 0x24);
    return kp;
}

std::vector<uint8_t> Signer::sign(const std::vector<uint8_t>& data, 
                                   const std::vector<uint8_t>& private_key) {
    std::vector<uint8_t> signature;
    sign(data, private_key, signature);
    return signature;
}

void Signer::sign(const std::vector<uint8_t>& data, 
                  const std::vector<uint8_t>& private_key,
                  std::vector<uint8_t>& signature) {
    // 🔴 问题：使用简单的XOR操作，不是密码学安全的
    // 修复：使用HMAC-SHA256或Ed25519
    signature.resize(32);
    for (size_t i = 0; i < signature.size(); i++) {
        signature[i] = data[i % data.size()] ^ private_key[i % private_key.size()];
    }
}

bool Signer::verifySignature(const std::vector<uint8_t>& data,
                             const std::vector<uint8_t>& signature,
                             const std::vector<uint8_t>& private_key) {
    auto computed = sign(data, private_key);
    return computed == signature;
}

std::unique_ptr<Signer> createSigner() {
    return std::make_unique<Signer>();
}

// ============================================================================
// Verifier实现
// ============================================================================

Verifier::Verifier() = default;
Verifier::~Verifier() = default;

bool Verifier::verify(const std::vector<uint8_t>& data,
                      const std::vector<uint8_t>& signature,
                      const std::vector<uint8_t>& public_key) {
    // 简化实现：重新计算签名并比较
    std::vector<uint8_t> computed(32);
    for (size_t i = 0; i < computed.size(); i++) {
        computed[i] = data[i % data.size()] ^ public_key[i % public_key.size()];
    }
    
    if (computed.size() != signature.size()) {
        return false;
    }
    
    // 常数时间比较
    uint8_t result = 0;
    for (size_t i = 0; i < computed.size(); i++) {
        result |= computed[i] ^ signature[i];
    }
    
    return result == 0;
}

bool Verifier::verifyBatch(const std::vector<std::vector<uint8_t>>& data_batch,
                           const std::vector<std::vector<uint8_t>>& signatures,
                           const std::vector<uint8_t>& public_key) {
    if (data_batch.size() != signatures.size()) {
        return false;
    }
    
    for (size_t i = 0; i < data_batch.size(); i++) {
        if (!verify(data_batch[i], signatures[i], public_key)) {
            return false;
        }
    }
    return true;
}

std::unique_ptr<Verifier> createVerifier() {
    return std::make_unique<Verifier>();
}

// ============================================================================
// SignatureService实现
// ============================================================================

SignatureService::SignatureService() {
    signer_ = createSigner();
    verifier_ = createVerifier();
}

SignatureService::~SignatureService() = default;

bool SignatureService::initialize() {
    key_pair_ = signer_->generateKeyPair();
    initialized_ = true;
    return true;
}

std::vector<uint8_t> SignatureService::sign(const std::vector<uint8_t>& data) {
    if (!initialized_) {
        return {};
    }
    return signer_->sign(data, key_pair_.private_key);
}

bool SignatureService::verify(const std::vector<uint8_t>& data,
                               const std::vector<uint8_t>& signature) {
    if (!initialized_) {
        return false;
    }
    return verifier_->verify(data, signature, key_pair_.public_key);
}

std::unique_ptr<SignatureService> createSignatureService() {
    return std::make_unique<SignatureService>();
}

} // namespace security
} // namespace polyvault