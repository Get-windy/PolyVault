/**
 * @file test_crypto_utils.cpp
 * @brief 加密工具单元测试
 */

#include "crypto_utils.hpp"
#include <iostream>
#include <cassert>
#include <cstring>

using namespace polyvault::crypto;

// ==================== 测试辅助函数 ====================

void printHex(const std::vector<uint8_t>& data, const std::string& label) {
    std::cout << label << " (" << data.size() << " bytes): ";
    for (uint8_t byte : data) {
        printf("%02x", byte);
    }
    std::cout << std::endl;
}

bool vectorsEqual(const std::vector<uint8_t>& a, const std::vector<uint8_t>& b) {
    if (a.size() != b.size()) return false;
    return std::memcmp(a.data(), b.data(), a.size()) == 0;
}

// ==================== 测试用例 ====================

void testRandomBytes() {
    std::cout << "\n=== Test: Random Bytes ===" << std::endl;
    
    auto random1 = generateRandomBytes(32);
    auto random2 = generateRandomBytes(32);
    
    assert(random1.size() == 32);
    assert(random2.size() == 32);
    assert(!vectorsEqual(random1, random2)); // 两次生成应该不同
    
    printHex(random1, "Random 1");
    printHex(random2, "Random 2");
    
    std::cout << "✓ Random bytes test passed" << std::endl;
}

void testAesGcmEncryption() {
    std::cout << "\n=== Test: AES-256-GCM Encryption ===" << std::endl;
    
    // 准备测试数据
    std::string plaintext = "Hello, PolyVault! This is a secret message.";
    std::vector<uint8_t> plaintextVec(plaintext.begin(), plaintext.end());
    
    // 生成 32 字节密钥和 12 字节 IV
    auto key = generateRandomBytes(32);
    auto iv = generateRandomBytes(12);
    
    printHex(plaintextVec, "Plaintext");
    printHex(key, "Key");
    printHex(iv, "IV");
    
    // 加密
    auto ciphertext = encryptAesGcm(plaintextVec, key, iv);
    printHex(ciphertext, "Ciphertext");
    
    assert(ciphertext.size() > plaintextVec.size()); // 密文应该更长（包含认证标签）
    
    std::cout << "✓ Encryption test passed" << std::endl;
}

void testAesGcmDecryption() {
    std::cout << "\n=== Test: AES-256-GCM Decryption ===" << std::endl;
    
    // 准备测试数据
    std::string originalText = "Test message for encryption and decryption.";
    std::vector<uint8_t> original(originalText.begin(), originalText.end());
    
    auto key = generateRandomBytes(32);
    auto iv = generateRandomBytes(12);
    
    // 加密
    auto ciphertext = encryptAesGcm(original, key, iv);
    std::cout << "Encrypted successfully" << std::endl;
    
    // 解密
    auto decrypted = decryptAesGcm(ciphertext, key, iv);
    std::cout << "Decrypted successfully" << std::endl;
    
    // 验证
    assert(vectorsEqual(original, decrypted));
    std::string decryptedText(decrypted.begin(), decrypted.end());
    std::cout << "Decrypted text: " << decryptedText << std::endl;
    
    assert(decryptedText == originalText);
    
    std::cout << "✓ Decryption test passed" << std::endl;
}

void testSha256() {
    std::cout << "\n=== Test: SHA256 ===" << std::endl;
    
    std::string input = "The quick brown fox jumps over the lazy dog";
    std::vector<uint8_t> inputData(input.begin(), input.end());
    
    auto hash = sha256(inputData);
    
    assert(hash.size() == 32); // SHA256 输出 32 字节
    
    printHex(hash, "SHA256 hash");
    
    // 验证确定性（相同输入产生相同输出）
    auto hash2 = sha256(inputData);
    assert(vectorsEqual(hash, hash2));
    
    // 验证不同输入产生不同输出
    std::string input2 = "The quick brown fox jumps over the lazy dog.";
    std::vector<uint8_t> inputData2(input2.begin(), input2.end());
    auto hash3 = sha256(inputData2);
    assert(!vectorsEqual(hash, hash3));
    
    std::cout << "✓ SHA256 test passed" << std::endl;
}

void testBase64() {
    std::cout << "\n=== Test: Base64 Encoding/Decoding ===" << std::endl;
    
    std::string original = "Hello, World!";
    std::vector<uint8_t> originalVec(original.begin(), original.end());
    
    // 编码
    auto encoded = base64Encode(originalVec);
    std::cout << "Encoded: " << encoded << std::endl;
    
    // 解码
    auto decoded = base64Decode(encoded);
    
    // 验证
    assert(vectorsEqual(originalVec, decoded));
    std::string decodedStr(decoded.begin(), decoded.end());
    assert(decodedStr == original);
    
    std::cout << "✓ Base64 test passed" << std::endl;
}

void testAuthenticationTag() {
    std::cout << "\n=== Test: Authentication Tag Verification ===" << std::endl;
    
    std::string message = "Secret message";
    std::vector<uint8_t> messageVec(message.begin(), message.end());
    
    auto key = generateRandomBytes(32);
    auto iv = generateRandomBytes(12);
    
    // 加密
    auto ciphertext = encryptAesGcm(messageVec, key, iv);
    
    // 篡改密文
    ciphertext[0] ^= 0xFF;
    
    // 尝试解密（应该失败）
    try {
        auto decrypted = decryptAesGcm(ciphertext, key, iv);
        std::cerr << "✗ Authentication tag verification FAILED - should have thrown!" << std::endl;
        assert(false);
    } catch (const CryptoException& e) {
        std::cout << "✓ Correctly detected tampering: " << e.what() << std::endl;
    }
    
    std::cout << "✓ Authentication tag test passed" << std::endl;
}

void testWrongKey() {
    std::cout << "\n=== Test: Wrong Key Detection ===" << std::endl;
    
    std::string message = "Test message";
    std::vector<uint8_t> messageVec(message.begin(), message.end());
    
    auto key1 = generateRandomBytes(32);
    auto key2 = generateRandomBytes(32); // 不同的密钥
    auto iv = generateRandomBytes(12);
    
    // 用 key1 加密
    auto ciphertext = encryptAesGcm(messageVec, key1, iv);
    
    // 用 key2 解密（应该失败）
    try {
        auto decrypted = decryptAesGcm(ciphertext, key2, iv);
        std::cerr << "✗ Wrong key detection FAILED - should have thrown!" << std::endl;
        assert(false);
    } catch (const CryptoException& e) {
        std::cout << "✓ Correctly detected wrong key: " << e.what() << std::endl;
    }
    
    std::cout << "✓ Wrong key test passed" << std::endl;
}

// ==================== 主函数 ====================

int main() {
    std::cout << "======================================" << std::endl;
    std::cout << "PolyVault Crypto Utils Unit Tests" << std::endl;
    std::cout << "======================================" << std::endl;
    
    try {
        testRandomBytes();
        testAesGcmEncryption();
        testAesGcmDecryption();
        testSha256();
        testBase64();
        testAuthenticationTag();
        testWrongKey();
        
        std::cout << "\n======================================" << std::endl;
        std::cout << "✓ ALL TESTS PASSED" << std::endl;
        std::cout << "======================================" << std::endl;
        
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "\n======================================" << std::endl;
        std::cerr << "✗ TEST FAILED: " << e.what() << std::endl;
        std::cerr << "======================================" << std::endl;
        
        return 1;
    }
}
