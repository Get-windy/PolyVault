/**
 * @file crypto_utils.hpp
 * @brief 加密工具函数
 * 
 * 安全实现：
 * - AES-256-GCM 加密/解密
 * - SHA256 哈希
 * - PBKDF2 密钥派生
 * - 密码学安全随机数生成
 */

#pragma once

#include <string>
#include <vector>
#include <optional>
#include <cstdint>

namespace polyvault {
namespace crypto {

// ==================== 随机数生成 ====================

/**
 * @brief 生成随机字节
 * @param length 字节数
 * @return 随机字节串
 */
std::vector<uint8_t> generateRandomBytes(size_t length);

/**
 * @brief 生成随机字节（写入现有缓冲区）
 * @param length 字节数
 * @param buffer 目标缓冲区指针
 */
void generateRandomBytes(size_t length, uint8_t* buffer);

// ==================== AES-256-GCM 加密 ====================

/**
 * @brief AES-256-GCM加密（指定IV）
 * @param plaintext 明文
 * @param key 32字节密钥
 * @param iv 12字节初始化向量
 * @return 密文（包含认证标签）
 */
std::vector<uint8_t> encryptAesGcm(
    const std::vector<uint8_t>& plaintext,
    const std::vector<uint8_t>& key,
    const std::vector<uint8_t>& iv);

/**
 * @brief AES-256-GCM加密（自动生成IV）
 * @param plaintext 明文
 * @param key 32字节密钥
 * @return 密文（前12字节为IV，后跟密文+认证标签）
 */
std::vector<uint8_t> encryptAesGcm(
    const std::vector<uint8_t>& plaintext,
    const std::vector<uint8_t>& key);

/**
 * @brief AES-256-GCM加密别名（自动生成IV）
 */
inline std::vector<uint8_t> encrypt_aes_gcm(
    const std::vector<uint8_t>& plaintext,
    const std::vector<uint8_t>& key) {
    return encryptAesGcm(plaintext, key);
}

// ==================== AES-256-GCM 解密 ====================

/**
 * @brief AES-256-GCM解密（指定IV）
 * @param ciphertext 密文（包含认证标签）
 * @param key 32字节密钥
 * @param iv 12字节初始化向量
 * @return 明文（失败返回空）
 */
std::vector<uint8_t> decryptAesGcm(
    const std::vector<uint8_t>& ciphertext,
    const std::vector<uint8_t>& key,
    const std::vector<uint8_t>& iv);

/**
 * @brief AES-256-GCM解密（IV在密文前）
 * @param ciphertext 密文（前12字节为IV）
 * @param key 32字节密钥
 * @return 明文（失败返回nullopt）
 */
std::optional<std::vector<uint8_t>> decryptAesGcm(
    const std::vector<uint8_t>& ciphertext,
    const std::vector<uint8_t>& key);

/**
 * @brief AES-256-GCM解密别名（IV在密文前）
 */
inline std::optional<std::vector<uint8_t>> decrypt_aes_gcm(
    const std::vector<uint8_t>& ciphertext,
    const std::vector<uint8_t>& key) {
    return decryptAesGcm(ciphertext, key);
}

// ==================== SHA256 哈希 ====================

/**
 * @brief SHA256哈希
 * @param data 输入数据
 * @return 32字节哈希值
 */
std::vector<uint8_t> sha256(const std::vector<uint8_t>& data);

/**
 * @brief SHA256哈希（字符串版本）
 * @param data 输入字符串
 * @return 32字节哈希值
 */
std::vector<uint8_t> sha256(const std::string& data);

// ==================== PBKDF2 密钥派生 ====================

/**
 * @brief PBKDF2-SHA256密钥派生
 * @param password 密码
 * @param salt 盐值
 * @param iterations 迭代次数（推荐100000+）
 * @param key_length 派生密钥长度
 * @return 派生密钥
 */
std::vector<uint8_t> pbkdf2_sha256(
    const std::string& password,
    const std::vector<uint8_t>& salt,
    int iterations,
    size_t key_length);

// ==================== Base64 编码 ====================

/**
 * @brief Base64编码
 */
std::string base64Encode(const std::vector<uint8_t>& data);

/**
 * @brief Base64解码
 */
std::vector<uint8_t> base64Decode(const std::string& encoded);

} // namespace crypto
} // namespace polyvault