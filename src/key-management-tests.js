/**
 * PolyVault Key Management System Tests
 * Comprehensive test suite for key generation, storage, and usage
 */

const assert = require('assert');
const fs = require('fs').promises;
const path = require('path');
const KeyManager = require('./key-management-system');

// Test configuration
const testStoragePath = path.join(__dirname, '..', 'test-keys-temp');

describe('PolyVault Key Management System Tests', function() {
  let keyManager;

  before(async function() {
    // Create a temporary storage path for tests
    await fs.mkdir(testStoragePath, { recursive: true });
    
    // Initialize key manager for tests
    keyManager = new KeyManager({
      storagePath: testStoragePath
    });

    console.log('Setting up key manager test environment...');
    const initResult = await keyManager.initialize();
    assert.strictEqual(initResult.success, true, 'Key manager should initialize successfully');
  });

  after(async function() {
    // Clean up test files
    try {
      const files = await fs.readdir(testStoragePath);
      for (const file of files) {
        await fs.unlink(path.join(testStoragePath, file));
      }
      await fs.rmdir(testStoragePath);
    } catch (error) {
      console.warn('Could not clean up test files:', error.message);
    }
    
    // Cleanup key manager
    if (keyManager) {
      await keyManager.cleanup();
    }
    
    console.log('Key manager test environment cleaned up.');
  });

  describe('Key Generation Tests', function() {
    it('should generate RSA keys', async function() {
      const result = await keyManager.generateKey({
        algorithm: 'rsa',
        purpose: 'encryption',
        label: 'test-rsa-key',
        exportable: true,
        strength: 2048
      });
      
      assert.strictEqual(result.success, true, 'RSA key generation should succeed');
      assert.ok(result.keyId, 'Should return a key ID');
      assert.ok(result.publicKey, 'Should return a public key');
      assert.ok(result.metadata, 'Should return metadata');
      assert.strictEqual(result.metadata.algorithm, 'rsa', 'Algorithm should be RSA');
      assert.strictEqual(result.metadata.purpose, 'encryption', 'Purpose should be encryption');
    });

    it('should generate Ed25519 keys', async function() {
      const result = await keyManager.generateKey({
        algorithm: 'ed25519',
        purpose: 'signing',
        label: 'test-ed25519-key',
        exportable: true
      });
      
      assert.strictEqual(result.success, true, 'Ed25519 key generation should succeed');
      assert.ok(result.keyId, 'Should return a key ID');
      assert.strictEqual(result.metadata.algorithm, 'ed25519', 'Algorithm should be Ed25519');
      assert.strictEqual(result.metadata.purpose, 'signing', 'Purpose should be signing');
    });

    it('should generate ECDSA keys', async function() {
      const result = await keyManager.generateKey({
        algorithm: 'ec',
        purpose: 'authentication',
        label: 'test-ecdsa-key',
        exportable: true,
        strength: 256
      });
      
      assert.strictEqual(result.success, true, 'ECDSA key generation should succeed');
      assert.ok(result.keyId, 'Should return a key ID');
      assert.strictEqual(result.metadata.algorithm, 'ec', 'Algorithm should be EC');
      assert.strictEqual(result.metadata.purpose, 'authentication', 'Purpose should be authentication');
    });

    it('should handle unsupported algorithms', async function() {
      const result = await keyManager.generateKey({
        algorithm: 'unsupported-algo',
        purpose: 'testing',
        exportable: true
      });
      
      assert.strictEqual(result.success, false, 'Should fail with unsupported algorithm');
      assert.ok(result.error, 'Should return an error message');
      assert.ok(result.error.includes('Unsupported'), 'Error should mention unsupported algorithm');
    });
  });

  describe('Key Storage Tests', function() {
    let testKeyId;

    before(async function() {
      const result = await keyManager.generateKey({
        algorithm: 'ed25519',
        purpose: 'test-storage',
        label: 'storage-test-key',
        exportable: true
      });
      assert.strictEqual(result.success, true, 'Test key should be generated');
      testKeyId = result.keyId;
    });

    it('should store keys in filesystem', async function() {
      // Check that key file exists
      const keyFilePath = path.join(testStoragePath, `${testKeyId}.key`);
      const metaFilePath = path.join(testStoragePath, `${testKeyId}.key.meta`);
      
      const keyExists = await fileExists(keyFilePath);
      const metaExists = await fileExists(metaFilePath);
      
      assert.strictEqual(keyExists, true, 'Key file should exist');
      assert.strictEqual(metaExists, true, 'Metadata file should exist');
    });

    it('should load stored keys', async function() {
      // Clear in-memory cache to force reload from storage
      keyManager.keys.clear();
      
      const result = await keyManager.getKey(testKeyId);
      assert.strictEqual(result.success, true, 'Should be able to load stored key');
      assert.ok(result.key, 'Should return key object');
      assert.strictEqual(result.key.metadata.id, testKeyId, 'Loaded key should have correct ID');
    });

    it('should handle missing keys', async function() {
      const result = await keyManager.getKey('non-existent-key-id');
      assert.strictEqual(result.success, false, 'Should fail to load non-existent key');
      assert.ok(result.error, 'Should return an error');
    });
  });

  describe('Key Encryption Tests (AES-256-GCM)', function() {
    it('should encrypt private keys using AES-256-GCM', async function() {
      const result = await keyManager.generateKey({
        algorithm: 'ed25519',
        purpose: 'encryption-test',
        label: 'aes-encryption-test',
        exportable: false // This will trigger encryption
      });
      
      assert.strictEqual(result.success, true, 'Key generation should succeed');
      
      // Load the key and verify it can be retrieved
      const loadedKey = await keyManager.getKey(result.keyId);
      assert.strictEqual(loadedKey.success, true, 'Should be able to load encrypted key');
    });
  });

  describe('Key Usage Tests', function() {
    let signingKeyId;

    before(async function() {
      const result = await keyManager.generateKey({
        algorithm: 'ed25519',
        purpose: 'signing',
        label: 'test-signing-key',
        exportable: true
      });
      assert.strictEqual(result.success, true, 'Signing key should be generated');
      signingKeyId = result.keyId;
    });

    it('should sign data with signing key', async function() {
      const testData = { message: 'Test message for signing', timestamp: Date.now() };
      
      const result = await keyManager.useKey(signingKeyId, 'sign', testData);
      assert.strictEqual(result.success, true, 'Signing operation should succeed');
      assert.ok(result.result, 'Should return a result');
      assert.strictEqual(result.result.success, true, 'Internal signing should succeed');
      assert.ok(result.result.signature, 'Should return a signature');
    });

    it('should not allow invalid operations for key purpose', async function() {
      const testData = { message: 'Test message', timestamp: Date.now() };
      
      // Try to encrypt with a signing-purpose key (should fail)
      const result = await keyManager.useKey(signingKeyId, 'encrypt', testData);
      assert.strictEqual(result.success, false, 'Should not allow encrypt operation on signing key');
    });
  });

  describe('Statistics and Information Tests', function() {
    let statsKeyId;

    before(async function() {
      const result = await keyManager.generateKey({
        algorithm: 'ed25519',
        purpose: 'stats-test',
        label: 'statistics-key',
        exportable: true
      });
      assert.strictEqual(result.success, true, 'Statistics test key should be generated');
      statsKeyId = result.keyId;

      // Use the key a few times to increment counters
      for (let i = 0; i < 3; i++) {
        await keyManager.useKey(statsKeyId, 'sign', { test: i });
      }
    });

    it('should provide key statistics', async function() {
      const result = await keyManager.getKeyStats(statsKeyId);
      assert.strictEqual(result.success, true, 'Should get key stats successfully');
      assert.ok(result.stats, 'Should return stats object');
      assert.strictEqual(result.stats.id, statsKeyId, 'Should have correct key ID');
      assert.strictEqual(result.stats.usageCount, 3, 'Should track usage count');
      assert.ok(result.stats.createdAt, 'Should have creation time');
      assert.ok(result.stats.lastAccessed, 'Should have last access time');
      assert.ok(result.stats.age > 0, 'Should calculate key age');
    });

    it('should list all keys', async function() {
      const result = keyManager.getAllKeys();
      assert.strictEqual(result.success, true, 'Should get all keys successfully');
      assert.ok(Array.isArray(result.keys), 'Should return array of keys');
      assert.ok(result.count > 0, 'Should have at least one key');
      assert.strictEqual(result.count, result.keys.length, 'Count should match array length');
    });
  });

  describe('Security and Validation Tests', function() {
    it('should validate key purposes', function() {
      // Test valid combinations
      assert.strictEqual(keyManager._isOperationAllowed('sign', 'signing'), true, 'Sign should be allowed for signing purpose');
      assert.strictEqual(keyManager._isOperationAllowed('verify', 'signing'), true, 'Verify should be allowed for signing purpose');
      assert.strictEqual(keyManager._isOperationAllowed('encrypt', 'encryption'), true, 'Encrypt should be allowed for encryption purpose');
      assert.strictEqual(keyManager._isOperationAllowed('sign', 'general'), true, 'Sign should be allowed for general purpose');
      
      // Test invalid combinations
      assert.strictEqual(keyManager._isOperationAllowed('encrypt', 'signing'), false, 'Encrypt should not be allowed for signing purpose');
      assert.strictEqual(keyManager._isOperationAllowed('sign', 'exchange'), false, 'Sign should not be allowed for exchange purpose');
    });

    it('should handle edge cases gracefully', async function() {
      // Test with invalid inputs
      const result1 = await keyManager.generateKey(null);
      assert.strictEqual(result1.success, false, 'Should handle null params');
      
      const result2 = await keyManager.generateKey(undefined);
      assert.strictEqual(result2.success, false, 'Should handle undefined params');
      
      const result3 = await keyManager.useKey(null, 'sign', {});
      assert.strictEqual(result3.success, false, 'Should handle null key ID');
      
      const result4 = await keyManager.useKey('valid-id', null, {});
      assert.strictEqual(result4.success, false, 'Should handle null operation');
    });
  });
});

// Helper function to check if a file exists
async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch (error) {
    return false;
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  console.log('PolyVault Key Management System Tests');
  console.log('=====================================');
  console.log('Note: This is a test specification. To run the actual tests, use a testing framework like Mocha:');
  console.log('  npx mocha key-management-tests.js');
  console.log('');
  console.log('The test suite includes:');
  console.log('  - Key generation tests for various algorithms');
  console.log('  - Key storage and retrieval tests');
  console.log('  - AES-256-GCM encryption tests');
  console.log('  - Key usage and operation tests');
  console.log('  - Statistics and information retrieval tests');
  console.log('  - Security and validation tests');
}