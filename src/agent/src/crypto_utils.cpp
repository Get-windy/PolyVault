/**
 * @file crypto_utils.cpp
 * @brief 加密工具实现（使用 Windows CNG）
 * 
 * 安全实现：
 * - AES-256-GCM 加密/解密
 * - SHA256 哈希
 * - 密码学安全随机数生成
 */

#include "crypto_utils.hpp"
#include <iostream>
#include <stdexcept>
#include <windows.h>
#include <bcrypt.h>
#include <ntstatus.h>
#pragma comment(lib, "bcrypt.lib")

namespace polyvault {
namespace crypto {

// ==================== 错误处理 ====================

class CryptoException : public std::runtime_error {
public:
    explicit CryptoException(const std::string& msg, NTSTATUS status)
        : std::runtime_error(msg + " (NTSTATUS: 0x" + 
            std::to_string(status) + ")"),
          status_(status) {}
    
    NTSTATUS status() const { return status_; }
    
private:
    NTSTATUS status_;
};

#define CHECK_STATUS(expr, msg) \
    do { \
        NTSTATUS status = (expr); \
        if (status != STATUS_SUCCESS) { \
            throw CryptoException(msg, status); \
        } \
    } while(0)

// ==================== 随机数生成 ====================

std::vector<uint8_t> generateRandomBytes(size_t length) {
    std::vector<uint8_t> bytes(length);
    
    // 使用 Windows CNG 生成密码学安全随机数
    CHECK_STATUS(
        BCryptGenRandom(
            nullptr,
            bytes.data(),
            static_cast<ULONG>(length),
            BCRYPT_USE_SYSTEM_PREFERRED_RNG
        ),
        "BCryptGenRandom failed"
    );
    
    return bytes;
}

// ==================== AES-256-GCM 加密 ====================

std::vector<uint8_t> encryptAesGcm(
    const std::vector<uint8_t>& plaintext,
    const std::vector<uint8_t>& key,
    const std::vector<uint8_t>& iv) {
    
    // 验证参数
    if (key.size() != 32) {
        throw std::invalid_argument("AES-256 requires a 32-byte key");
    }
    if (iv.size() != 12) {
        throw std::invalid_argument("GCM mode requires a 12-byte IV");
    }
    
    BCRYPT_KEY_HANDLE hKey = nullptr;
    BCRYPT_ALG_HANDLE hAlg = nullptr;
    
    try {
        // 打开 AES 算法提供程序
        CHECK_STATUS(
            BCryptOpenAlgorithmProvider(
                &hAlg,
                BCRYPT_AES_ALGORITHM,
                nullptr,
                BCRYPT_PROV_DISPATCH
            ),
            "BCryptOpenAlgorithmProvider failed"
        );
        
        // 设置链模式为 GCM
        CHECK_STATUS(
            BCryptSetProperty(
                hAlg,
                BCRYPT_CHAINING_MODE,
                reinterpret_cast<PUCHAR>(const_cast<LPWSTR>(BCRYPT_CHAIN_MODE_GCM)),
                sizeof(BCRYPT_CHAIN_MODE_GCM),
                0
            ),
            "BCryptSetProperty failed"
        );
        
        // 导入密钥
        CHECK_STATUS(
            BCryptImportKey(
                hAlg,
                nullptr,
                BCRYPT_KEY_DATA_BLOB,
                &hKey,
                nullptr,
                0,
                const_cast<PUCHAR>(key.data()),
                static_cast<ULONG>(key.size()),
                0
            ),
            "BCryptImportKey failed"
        );
        
        // 计算密文大小
        ULONG ciphertextLen = 0;
        CHECK_STATUS(
            BCryptEncrypt(
                hKey,
                const_cast<PUCHAR>(plaintext.data()),
                static_cast<ULONG>(plaintext.size()),
                nullptr,
                const_cast<PUCHAR>(iv.data()),
                static_cast<ULONG>(iv.size()),
                nullptr,
                0,
                &ciphertextLen,
                0
            ),
            "BCryptEncrypt (size query) failed"
        );
        
        // 分配输出缓冲区（密文 + 16 字节认证标签）
        std::vector<uint8_t> output(ciphertextLen + 16);
        
        // 执行加密
        ULONG resultLen = 0;
        CHECK_STATUS(
            BCryptEncrypt(
                hKey,
                const_cast<PUCHAR>(plaintext.data()),
                static_cast<ULONG>(plaintext.size()),
                nullptr,
                const_cast<PUCHAR>(iv.data()),
                static_cast<ULONG>(iv.size()),
                output.data(),
                static_cast<ULONG>(output.size()),
                &resultLen,
                0
            ),
            "BCryptEncrypt failed"
        );
        
        // 清理
        BCryptDestroyKey(hKey);
        BCryptCloseAlgorithmProvider(hAlg, 0);
        
        output.resize(resultLen);
        return output;
        
    } catch (...) {
        if (hKey) BCryptDestroyKey(hKey);
        if (hAlg) BCryptCloseAlgorithmProvider(hAlg, 0);
        throw;
    }
}

// ==================== AES-256-GCM 解密 ====================

std::vector<uint8_t> decryptAesGcm(
    const std::vector<uint8_t>& ciphertext,
    const std::vector<uint8_t>& key,
    const std::vector<uint8_t>& iv) {
    
    // 验证参数
    if (key.size() != 32) {
        throw std::invalid_argument("AES-256 requires a 32-byte key");
    }
    if (iv.size() != 12) {
        throw std::invalid_argument("GCM mode requires a 12-byte IV");
    }
    if (ciphertext.empty()) {
        throw std::invalid_argument("Ciphertext is empty");
    }
    
    BCRYPT_KEY_HANDLE hKey = nullptr;
    BCRYPT_ALG_HANDLE hAlg = nullptr;
    
    try {
        // 打开 AES 算法提供程序
        CHECK_STATUS(
            BCryptOpenAlgorithmProvider(
                &hAlg,
                BCRYPT_AES_ALGORITHM,
                nullptr,
                BCRYPT_PROV_DISPATCH
            ),
            "BCryptOpenAlgorithmProvider failed"
        );
        
        // 设置链模式为 GCM
        CHECK_STATUS(
            BCryptSetProperty(
                hAlg,
                BCRYPT_CHAINING_MODE,
                reinterpret_cast<PUCHAR>(const_cast<LPWSTR>(BCRYPT_CHAIN_MODE_GCM)),
                sizeof(BCRYPT_CHAIN_MODE_GCM),
                0
            ),
            "BCryptSetProperty failed"
        );
        
        // 导入密钥
        CHECK_STATUS(
            BCryptImportKey(
                hAlg,
                nullptr,
                BCRYPT_KEY_DATA_BLOB,
                &hKey,
                nullptr,
                0,
                const_cast<PUCHAR>(key.data()),
                static_cast<ULONG>(key.size()),
                0
            ),
            "BCryptImportKey failed"
        );
        
        // 计算明文大小
        ULONG plaintextLen = 0;
        CHECK_STATUS(
            BCryptDecrypt(
                hKey,
                const_cast<PUCHAR>(ciphertext.data()),
                static_cast<ULONG>(ciphertext.size()),
                nullptr,
                const_cast<PUCHAR>(iv.data()),
                static_cast<ULONG>(iv.size()),
                nullptr,
                0,
                &plaintextLen,
                0
            ),
            "BCryptDecrypt (size query) failed"
        );
        
        // 分配输出缓冲区
        std::vector<uint8_t> output(plaintextLen);
        
        // 执行解密
        ULONG resultLen = 0;
        NTSTATUS status = BCryptDecrypt(
            hKey,
            const_cast<PUCHAR>(ciphertext.data()),
            static_cast<ULONG>(ciphertext.size()),
            nullptr,
            const_cast<PUCHAR>(iv.data()),
            static_cast<ULONG>(iv.size()),
            output.data(),
            static_cast<ULONG>(output.size()),
            &resultLen,
            0
        );
        
        if (status == STATUS_AUTH_TAG_MISMATCH) {
            throw CryptoException("Authentication tag verification failed", status);
        }
        CHECK_STATUS(status, "BCryptDecrypt failed");
        
        // 清理
        BCryptDestroyKey(hKey);
        BCryptCloseAlgorithmProvider(hAlg, 0);
        
        output.resize(resultLen);
        return output;
        
    } catch (...) {
        if (hKey) BCryptDestroyKey(hKey);
        if (hAlg) BCryptCloseAlgorithmProvider(hAlg, 0);
        throw;
    }
}

// ==================== SHA256 哈希 ====================

std::vector<uint8_t> sha256(const std::vector<uint8_t>& data) {
    BCRYPT_ALG_HANDLE hAlg = nullptr;
    BCRYPT_HASH_HANDLE hHash = nullptr;
    
    try {
        // 打开 SHA256 算法提供程序
        CHECK_STATUS(
            BCryptOpenAlgorithmProvider(
                &hAlg,
                BCRYPT_SHA256_ALGORITHM,
                nullptr,
                0
            ),
            "BCryptOpenAlgorithmProvider failed"
        );
        
        // 获取哈希对象大小
        DWORD hashObjLen = 0;
        DWORD hashLen = 0;
        ULONG resultLen = 0;
        
        CHECK_STATUS(
            BCryptGetProperty(
                hAlg,
                BCRYPT_OBJECT_LENGTH,
                reinterpret_cast<PUCHAR>(&hashObjLen),
                sizeof(hashObjLen),
                &resultLen,
                0
            ),
            "BCryptGetProperty (object length) failed"
        );
        
        CHECK_STATUS(
            BCryptGetProperty(
                hAlg,
                BCRYPT_HASH_LENGTH,
                reinterpret_cast<PUCHAR>(&hashLen),
                sizeof(hashLen),
                &resultLen,
                0
            ),
            "BCryptGetProperty (hash length) failed"
        );
        
        // 创建哈希对象
        std::vector<uint8_t> hashObj(hashObjLen);
        
        CHECK_STATUS(
            BCryptCreateHash(
                hAlg,
                &hHash,
                hashObj.data(),
                static_cast<ULONG>(hashObj.size()),
                nullptr,
                0,
                0
            ),
            "BCryptCreateHash failed"
        );
        
        // 哈希数据
        CHECK_STATUS(
            BCryptHashData(
                hHash,
                const_cast<PUCHAR>(data.data()),
                static_cast<ULONG>(data.size()),
                0
            ),
            "BCryptHashData failed"
        );
        
        // 获取哈希值
        std::vector<uint8_t> hash(hashLen);
        
        CHECK_STATUS(
            BCryptFinishHash(
                hHash,
                hash.data(),
                static_cast<ULONG>(hash.size()),
                0
            ),
            "BCryptFinishHash failed"
        );
        
        // 清理
        BCryptDestroyHash(hHash);
        BCryptCloseAlgorithmProvider(hAlg, 0);
        
        return hash;
        
    } catch (...) {
        if (hHash) BCryptDestroyHash(hHash);
        if (hAlg) BCryptCloseAlgorithmProvider(hAlg, 0);
        throw;
    }
}

// ==================== Base64 编码 ====================

std::string base64Encode(const std::vector<uint8_t>& data) {
    static const char* chars = 
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    std::string result;
    result.reserve(((data.size() + 2) / 3) * 4);
    
    for (size_t i = 0; i < data.size(); i += 3) {
        uint32_t n = (data[i] << 16);
        if (i + 1 < data.size()) n |= (data[i + 1] << 8);
        if (i + 2 < data.size()) n |= data[i + 2];
        
        result.push_back(chars[(n >> 18) & 0x3F]);
        result.push_back(chars[(n >> 12) & 0x3F]);
        result.push_back((i + 1 < data.size()) ? chars[(n >> 6) & 0x3F] : '=');
        result.push_back((i + 2 < data.size()) ? chars[n & 0x3F] : '=');
    }
    
    return result;
}

// ==================== Base64 解码 ====================

std::vector<uint8_t> base64Decode(const std::string& encoded) {
    static const int table[256] = {
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,
        52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,
        -1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,
        15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,
        -1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
        41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
        -1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,
    };
    
    std::vector<uint8_t> result;
    result.reserve((encoded.size() / 4) * 3);
    
    int buffer = 0;
    int bits = 0;
    
    for (char c : encoded) {
        if (c == '=') break;
        int val = table[static_cast<uint8_t>(c)];
        if (val == -1) continue;
        
        buffer = (buffer << 6) | val;
        bits += 6;
        
        if (bits >= 8) {
            bits -= 8;
            result.push_back(static_cast<uint8_t>((buffer >> bits) & 0xFF));
        }
    }
    
    return result;
}

} // namespace crypto
} // namespace polyvault
