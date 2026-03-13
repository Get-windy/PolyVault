/**
 * @file crypto_utils.hpp
 * @brief 加密工具函数
 */

#pragma once

#include <string>
#include <vector>

namespace polyvault {
namespace crypto {

/**
 * @brief 生成随机字节
 * @param length 字节数
 * @return 随机字节串
 */
std::vector<uint8_t> generateRandomBytes(size_t length);

/**
 * @brief AES-256-GCM加密
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
 * @brief AES-256-GCM解密
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
 * @brief SHA256哈希
 * @param data 输入数据
 * @return 32字节哈希值
 */
std::vector<uint8_t> sha256(const std::vector<uint8_t>& data);

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