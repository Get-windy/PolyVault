/**
 * PolyVault Security Module Unit Tests
 */

const assert = require('assert');
const SecurityModule = require('../src/security-module');

describe('SecurityModule', () => {
  let security;
  
  before(async () => {
    security = new SecurityModule();
    await security.initialize('test-master-key-12345');
  });
  
  after(async () => {
    await security.cleanup();
  });
  
  describe('Encryption/Decryption', () => {
    it('should encrypt and decrypt data correctly', () => {
      const plaintext = 'Hello, PolyVault Security!';
      const encrypted = security.encrypt(plaintext);
      
      assert.strictEqual(encrypted.success, true);
      assert.ok(encrypted.ciphertext);
      assert.ok(encrypted.iv);
      assert.ok(encrypted.authTag);
      
      const decrypted = security.decrypt(encrypted);
      assert.strictEqual(decrypted.success, true);
      assert.strictEqual(decrypted.plaintext, plaintext);
    });
    
    it('should encrypt different data to different ciphertext', () => {
      const plaintext1 = 'First message';
      const plaintext2 = 'Second message';
      
      const encrypted1 = security.encrypt(plaintext1);
      const encrypted2 = security.encrypt(plaintext2);
      
      assert.notStrictEqual(encrypted1.ciphertext, encrypted2.ciphertext);
    });
    
    it('should fail decryption with wrong key', () => {
      const plaintext = 'Secret data';
      const encrypted = security.encrypt(plaintext);
      
      const wrongSecurity = new SecurityModule();
      wrongSecurity.secretKey = 'wrong-key-12345678901234567890123';
      
      const decrypted = wrongSecurity.decrypt(encrypted);
      assert.strictEqual(decrypted.success, false);
    });
  });
  
  describe('Password Generation', () => {
    it('should generate password of specified length', () => {
      const password1 = security.generateSecurePassword(16);
      const password2 = security.generateSecurePassword(32);
      const password3 = security.generateSecurePassword(8);
      
      assert.strictEqual(password1.length, 16);
      assert.strictEqual(password2.length, 32);
      assert.strictEqual(password3.length, 8);
    });
    
    it('should generate unique passwords', () => {
      const passwords = new Set();
      for (let i = 0; i < 100; i++) {
        passwords.add(security.generateSecurePassword(16));
      }
      // All passwords should be unique
      assert.ok(passwords.size > 90); // Allow some rare collisions
    });
    
    it('should respect character set options', () => {
      const password = security.generateSecurePassword(20, {
        uppercase: false,
        lowercase: true,
        numbers: false,
        symbols: false
      });
      
      // Should only contain lowercase letters
      assert.ok(/^[a-z]+$/.test(password));
    });
  });
  
  describe('Password Hashing', () => {
    it('should hash and verify password correctly', () => {
      const password = 'testPassword123';
      const hash = security.hashPassword(password);
      
      // Hash should contain salt and hash parts
      assert.ok(hash.includes(':'));
      
      // Verify correct password
      const isValid = security.verifyPassword(password, hash);
      assert.strictEqual(isValid, true);
      
      // Verify wrong password
      const isInvalid = security.verifyPassword('wrongPassword', hash);
      assert.strictEqual(isInvalid, false);
    });
    
    it('should produce different hashes for same password', () => {
      const password = 'testPassword123';
      const hash1 = security.hashPassword(password);
      const hash2 = security.hashPassword(password);
      
      assert.notStrictEqual(hash1, hash2);
    });
  });
  
  describe('HMAC', () => {
    it('should create valid HMAC', () => {
      const data = 'test data';
      const key = 'secret-key';
      const hmac = security.createHMAC(data, key);
      
      assert.ok(hmac);
      assert.strictEqual(hmac.length, 64); // SHA-256 produces 64 hex chars
    });
    
    it('should verify correct HMAC', () => {
      const data = 'test data';
      const key = 'secret-key';
      const hmac = security.createHMAC(data, key);
      
      const isValid = security.verifyHMAC(data, hmac, key);
      assert.strictEqual(isValid, true);
    });
    
    it('should reject invalid HMAC', () => {
      const data = 'test data';
      const key = 'secret-key';
      const hmac = security.createHMAC(data, key);
      
      const isValid = security.verifyHMAC(data, hmac, 'wrong-key');
      assert.strictEqual(isValid, false);
    });
    
    it('should produce different HMACs for different keys', () => {
      const data = 'test data';
      const hmac1 = security.createHMAC(data, 'key1');
      const hmac2 = security.createHMAC(data, 'key2');
      
      assert.notStrictEqual(hmac1, hmac2);
    });
  });
  
  describe('Hashing', () => {
    it('should produce SHA-256 hash', () => {
      const data = 'test data';
      const hash = security.hash(data);
      
      assert.strictEqual(hash.length, 64); // SHA-256 produces 64 hex chars
    });
    
    it('should produce consistent hashes', () => {
      const data = 'test data';
      const hash1 = security.hash(data);
      const hash2 = security.hash(data);
      
      assert.strictEqual(hash1, hash2);
    });
    
    it('should produce different hashes for different data', () => {
      const hash1 = security.hash('data1');
      const hash2 = security.hash('data2');
      
      assert.notStrictEqual(hash1, hash2);
    });
  });
  
  describe('Secure Wipe', () => {
    it('should handle buffer wipe', () => {
      const buffer = Buffer.from('sensitive data');
      security.secureWipe(buffer);
      
      // Buffer should be zeros
      assert.strictEqual(buffer[0], 0);
    });
  });
  
  describe('Error Handling', () => {
    it('should handle decryption of invalid data', () => {
      const invalidData = {
        ciphertext: 'invalid',
        iv: 'invalid',
        authTag: 'invalid'
      };
      
      const result = security.decrypt(invalidData);
      assert.strictEqual(result.success, false);
    });
  });
});

// Run tests if executed directly
if (require.main === module) {
  console.log('Running Security Module Tests...');
}