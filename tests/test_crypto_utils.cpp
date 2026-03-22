/**
 * @file test_crypto_utils.cpp
 * @brief AES-GCM 加密模块测试
 * 
 * 编译命令 (Windows):
 * cl /std:c++17 /I"../src/agent/include" test_crypto_utils.cpp ../src/agent/src/crypto_utils.cpp /link bcrypt.lib
 */

#include "crypto_utils.hpp"
#include <iostream>
#include <cassert>
#include <vector>
#include <string>

using namespace polyvault::crypto;

void test_random_bytes() {
    std::cout << "Testing generateRandomBytes..." << std::endl;
    
    // 测试生成随机字节
    auto bytes1 = generateRandomBytes(32);
    assert(bytes1.size() == 32);
    
    auto bytes2 = generateRandomBytes(32);
    assert(bytes2.size() == 32);
    
    // 两次生成的随机字节应该不同
    bool different = false;
    for (size_t i = 0; i < 32; ++i) {
        if (bytes1[i] != bytes2[i]) {
            different = true;
            break;
        }
    }
    assert(different);
    
    // 测试缓冲区版本
    uint8_t buffer[16];
    generateRandomBytes(16, buffer);
    
    std::cout << "  ✓ generateRandomBytes passed" << std::endl;
}

void test_sha256() {
    std::cout << "Testing SHA256..." << std::endl;
    
    // 测试空字符串
    auto hash1 = sha256(std::string(""));
    assert(hash1.size() == 32);
    
    // 测试 "abc"
    std::string abc = "abc";
    auto hash2 = sha256(std::vector<uint8_t>(abc.begin(), abc.end()));
    assert(hash2.size() == 32);
    
    // 相同输入应该产生相同哈希
    auto hash3 = sha256(std::string("abc"));
    assert(hash2 == hash3);
    
    // 不同输入应该产生不同哈希
    auto hash4 = sha256(std::string("abcd"));
    assert(hash2 != hash4);
    
    std::cout << "  ✓ SHA256 passed" << std::endl;
}

void test_aes_gcm_encryption() {
    std::cout << "Testing AES-GCM encryption..." << std::endl;
    
    // 生成32字节密钥
    auto key = generateRandomBytes(32);
    
    // 测试数据
    std::string plaintext_str = "Hello, PolyVault! This is a secret message.";
    std::vector<uint8_t> plaintext(plaintext_str.begin(), plaintext_str.end());
    
    // 加密（自动生成IV）
    auto ciphertext = encryptAesGcm(plaintext, key);
    
    // 密文应该比明文长（12字节IV + 16字节认证标签）
    assert(ciphertext.size() == 12 + plaintext.size() + 16);
    
    std::cout << "  ✓ AES-GCM encryption passed" << std::endl;
}

void test_aes_gcm_decryption() {
    std::cout << "Testing AES-GCM decryption..." << std::endl;
    
    // 生成32字节密钥
    auto key = generateRandomBytes(32);
    
    // 测试数据
    std::string plaintext_str = "Hello, PolyVault! This is a secret message.";
    std::vector<uint8_t> plaintext(plaintext_str.begin(), plaintext_str.end());
    
    // 加密
    auto ciphertext = encryptAesGcm(plaintext, key);
    
    // 解密
    auto decrypted = decryptAesGcm(ciphertext, key);
    assert(decrypted.has_value());
    assert(decrypted.value() == plaintext);
    
    // 验证解密后的内容
    std::string decrypted_str(decrypted->begin(), decrypted->end());
    assert(decrypted_str == plaintext_str);
    
    std::cout << "  ✓ AES-GCM decryption passed" << std::endl;
}

void test_aes_gcm_wrong_key() {
    std::cout << "Testing AES-GCM with wrong key..." << std::endl;
    
    // 生成两个不同的密钥
    auto key1 = generateRandomBytes(32);
    auto key2 = generateRandomBytes(32);
    
    // 确保密钥不同
    while (key1 == key2) {
        key2 = generateRandomBytes(32);
    }
    
    // 测试数据
    std::string plaintext_str = "Secret message";
    std::vector<uint8_t> plaintext(plaintext_str.begin(), plaintext_str.end());
    
    // 使用key1加密
    auto ciphertext = encryptAesGcm(plaintext, key1);
    
    // 使用key2解密应该失败
    auto decrypted = decryptAesGcm(ciphertext, key2);
    assert(!decrypted.has_value());
    
    std::cout << "  ✓ Wrong key detection passed" << std::endl;
}

void test_aes_gcm_tampered_ciphertext() {
    std::cout << "Testing AES-GCM with tampered ciphertext..." << std::endl;
    
    // 生成密钥
    auto key = generateRandomBytes(32);
    
    // 测试数据
    std::string plaintext_str = "Original message";
    std::vector<uint8_t> plaintext(plaintext_str.begin(), plaintext_str.end());
    
    // 加密
    auto ciphertext = encryptAesGcm(plaintext, key);
    
    // 篡改密文
    auto tampered = ciphertext;
    tampered[20] ^= 0xFF; // 修改一个字节
    
    // 解密篡改后的密文应该失败
    auto decrypted = decryptAesGcm(tampered, key);
    assert(!decrypted.has_value());
    
    std::cout << "  ✓ Tampered ciphertext detection passed" << std::endl;
}

void test_pbkdf2() {
    std::cout << "Testing PBKDF2-SHA256..." << std::endl;
    
    std::string password = "my_secret_password";
    auto salt = generateRandomBytes(16);
    
    // 派生密钥
    auto key1 = pbkdf2_sha256(password, salt, 10000, 32);
    assert(key1.size() == 32);
    
    // 相同参数应该产生相同密钥
    auto key2 = pbkdf2_sha256(password, salt, 10000, 32);
    assert(key1 == key2);
    
    // 不同密码应该产生不同密钥
    auto key3 = pbkdf2_sha256("different_password", salt, 10000, 32);
    assert(key1 != key3);
    
    // 不同盐应该产生不同密钥
    auto salt2 = generateRandomBytes(16);
    auto key4 = pbkdf2_sha256(password, salt2, 10000, 32);
    assert(key1 != key4);
    
    std::cout << "  ✓ PBKDF2-SHA256 passed" << std::endl;
}

void test_base64() {
    std::cout << "Testing Base64..." << std::endl;
    
    // 测试编码/解码
    std::vector<uint8_t> data = {'H', 'e', 'l', 'l', 'o'};
    
    auto encoded = base64Encode(data);
    auto decoded = base64Decode(encoded);
    
    assert(decoded == data);
    
    // 测试空数据
    auto empty_encoded = base64Encode({});
    assert(empty_encoded.empty());
    
    std::cout << "  ✓ Base64 passed" << std::endl;
}

void test_full_workflow() {
    std::cout << "Testing full encryption workflow..." << std::endl;
    
    // 模拟真实使用场景
    std::string master_password = "user_master_password";
    auto salt = generateRandomBytes(16);
    
    // 从密码派生密钥
    auto key = pbkdf2_sha256(master_password, salt, 100000, 32);
    
    // 存储凭证
    std::string service = "https://example.com";
    std::string username = "user123";
    std::string password = "secret_password_123";
    
    std::string credential_data = username + ":" + password;
    std::vector<uint8_t> plaintext(credential_data.begin(), credential_data.end());
    
    // 加密
    auto encrypted = encryptAesGcm(plaintext, key);
    
    // 存储（这里只打印信息）
    std::cout << "  Service: " << service << std::endl;
    std::cout << "  Encrypted size: " << encrypted.size() << " bytes" << std::endl;
    
    // 解密
    auto decrypted = decryptAesGcm(encrypted, key);
    assert(decrypted.has_value());
    
    std::string decrypted_str(decrypted->begin(), decrypted->end());
    assert(decrypted_str == credential_data);
    
    std::cout << "  ✓ Full workflow passed" << std::endl;
}

int main() {
    std::cout << "========================================" << std::endl;
    std::cout << "PolyVault Crypto Utils Test Suite" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << std::endl;
    
    try {
        test_random_bytes();
        test_sha256();
        test_aes_gcm_encryption();
        test_aes_gcm_decryption();
        test_aes_gcm_wrong_key();
        test_aes_gcm_tampered_ciphertext();
        test_pbkdf2();
        test_base64();
        test_full_workflow();
        
        std::cout << std::endl;
        std::cout << "========================================" << std::endl;
        std::cout << "✓ All tests passed!" << std::endl;
        std::cout << "========================================" << std::endl;
        
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "Test failed with error: " << e.what() << std::endl;
        return 1;
    }
}