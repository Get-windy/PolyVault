/**
 * PolyVault Security Module
 * Provides cryptographic encryption, key storage, and security utilities
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

class SecurityModule {
  constructor(options = {}) {
    this.algorithm = options.algorithm || 'aes-256-gcm';
    this.keyDerivation = options.keyDerivation || {
      method: 'PBKDF2',
      iterations: 100000,
      hash: 'sha256'
    };
    this.saltLength = options.saltLength || 32;
    this.ivLength = options.ivLength || 16;
    this.tagLength = options.tagLength || 16;
    this.secretKey = options.secretKey || null;
  }

  /**
   * Initialize the security module
   * @param {string} masterKey - Master key for encryption (if not provided in constructor)
   */
  async initialize(masterKey = null) {
    try {
      if (masterKey) {
        // Accept both hex string and regular string
        if (masterKey.length === 64 && /^[0-9a-fA-F]+$/.test(masterKey)) {
          this.secretKey = masterKey; // Already hex
        } else {
          // Hash the password to get a 32-byte key
          this.secretKey = crypto.createHash('sha256').update(masterKey).digest('hex');
        }
      } else if (!this.secretKey) {
        // Generate a random master key for development
        this.secretKey = crypto.randomBytes(32).toString('hex');
        console.warn('WARNING: Using auto-generated master key. Provide one in production!');
      }
      
      console.log('SecurityModule initialized successfully');
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Derive a key from password using PBKDF2
   * @param {string} password - Password to derive from
   * @param {Buffer} salt - Salt for key derivation
   * @returns {Buffer} - Derived key
   */
  _deriveKey(password, salt) {
    // Ensure salt is 32 bytes if not provided
    const actualSalt = salt || crypto.randomBytes(32);
    return crypto.pbkdf2Sync(
      password,
      actualSalt,
      this.keyDerivation.iterations,
      32, // 256 bits
      this.keyDerivation.hash
    );
  }

  /**
   * Encrypt data using AES-256-GCM
   * @param {string} plaintext - Data to encrypt
   * @param {string} password - Password (or use master key)
   * @returns {object} - Encrypted data with IV and auth tag
   */
  encrypt(plaintext, password = null) {
    try {
      const key = password 
        ? this._deriveKey(password)
        : Buffer.from(this.secretKey, 'hex');
      
      const iv = crypto.randomBytes(this.ivLength);
      const cipher = crypto.createCipheriv(this.algorithm, key, iv, {
        authTagLength: this.tagLength
      });
      
      let encrypted = cipher.update(plaintext, 'utf8', 'hex');
      encrypted += cipher.final('hex');
      
      const authTag = cipher.getAuthTag();
      
      return {
        success: true,
        ciphertext: encrypted,
        iv: iv.toString('hex'),
        authTag: authTag.toString('hex'),
        algorithm: this.algorithm
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Decrypt data using AES-256-GCM
   * @param {object} encryptedData - Encrypted data object
   * @param {string} password - Password (or use master key)
   * @returns {string} - Decrypted plaintext
   */
  decrypt(encryptedData, password = null) {
    try {
      const { ciphertext, iv, authTag } = encryptedData;
      
      const key = password 
        ? this._deriveKey(password)
        : Buffer.from(this.secretKey, 'hex');
      
      const decipher = crypto.createDecipheriv(
        this.algorithm,
        key,
        Buffer.from(iv, 'hex'),
        { authTagLength: this.tagLength }
      );
      
      decipher.setAuthTag(Buffer.from(authTag, 'hex'));
      
      let decrypted = decipher.update(ciphertext, 'hex', 'utf8');
      decrypted += decipher.final('utf8');
      
      return {
        success: true,
        plaintext: decrypted
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Encrypt private key for secure storage
   * @param {string} privateKey - Private key to encrypt
   * @returns {object} - Encrypted key data
   */
  encryptPrivateKey(privateKey) {
    return this.encrypt(privateKey);
  }

  /**
   * Decrypt private key
   * @param {object} encryptedKey - Encrypted key data
   * @returns {string} - Decrypted private key
   */
  decryptPrivateKey(encryptedKey) {
    return this.decrypt(encryptedKey);
  }

  /**
   * Generate a secure random password
   * @param {number} length - Password length
   * @param {object} options - Password generation options
   * @returns {string} - Generated password
   */
  generateSecurePassword(length = 16, options = {}) {
    const {
      uppercase = true,
      lowercase = true,
      numbers = true,
      symbols = true
    } = options;
    
    let charset = '';
    if (uppercase) charset += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (lowercase) charset += 'abcdefghijklmnopqrstuvwxyz';
    if (numbers) charset += '0123456789';
    if (symbols) charset += '!@#$%^&*()_+-=[]{}|;:,.<>?';
    
    if (charset.length === 0) {
      charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    }
    
    const randomBytes = crypto.randomBytes(length);
    let password = '';
    for (let i = 0; i < length; i++) {
      password += charset[randomBytes[i] % charset.length];
    }
    
    return password;
  }

  /**
   * Hash a password using bcrypt-style hashing
   * @param {string} password - Password to hash
   * @returns {string} - Hashed password
   */
  hashPassword(password) {
    const salt = crypto.randomBytes(16).toString('hex');
    const hash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512').toString('hex');
    return `${salt}:${hash}`;
  }

  /**
   * Verify a password against a hash
   * @param {string} password - Password to verify
   * @param {string} storedHash - Stored hash
   * @returns {boolean} - True if password matches
   */
  verifyPassword(password, storedHash) {
    const [salt, hash] = storedHash.split(':');
    const newHash = crypto.pbkdf2Sync(password, salt, 100000, 64, 'sha512').toString('hex');
    return hash === newHash;
  }

  /**
   * Securely delete sensitive data from memory
   * @param {object} data - Data to wipe
   */
  secureWipe(data) {
    if (typeof data === 'string') {
      // Overwrite string in memory (best effort)
      data = ' '.repeat(data.length);
    } else if (Buffer.isBuffer(data)) {
      // Overwrite buffer
      data.fill(0);
    }
  }

  /**
   * Generate a cryptographic hash
   * @param {string} data - Data to hash
   * @param {string} algorithm - Hash algorithm
   * @returns {string} - Hash in hex
   */
  hash(data, algorithm = 'sha256') {
    return crypto.createHash(algorithm).update(data).digest('hex');
  }

  /**
   * Verify data integrity using HMAC
   * @param {string} data - Data to verify
   * @param {string} hmac - HMAC to verify against
   * @param {string} key - Secret key
   * @returns {boolean} - True if valid
   */
  verifyHMAC(data, hmac, key) {
    const computed = this.createHMAC(data, key);
    return crypto.timingSafeEqual(
      Buffer.from(computed, 'hex'),
      Buffer.from(hmac, 'hex')
    );
  }

  /**
   * Create HMAC signature
   * @param {string} data - Data to sign
   * @param {string} key - Secret key
   * @returns {string} - HMAC signature
   */
  createHMAC(data, key) {
    return crypto.createHmac('sha256', key).update(data).digest('hex');
  }

  /**
   * Cleanup and clear sensitive data
   */
  async cleanup() {
    if (this.secretKey) {
      this.secureWipe(this.secretKey);
    }
    console.log('SecurityModule cleaned up');
    return { success: true };
  }
}

module.exports = SecurityModule;

// Example usage and testing
if (require.main === module) {
  (async () => {
    console.log('=== PolyVault Security Module Test ===\n');
    
    const security = new SecurityModule();
    await security.initialize('test-master-key-12345');
    
    // Test encryption
    console.log('1. Testing encryption/decryption...');
    const plaintext = 'Sensitive private key data here';
    const encrypted = security.encrypt(plaintext);
    console.log('   Encrypted:', encrypted.ciphertext.substring(0, 50) + '...');
    
    const decrypted = security.decrypt(encrypted);
    console.log('   Decrypted:', decrypted.plaintext);
    console.log('   Match:', decrypted.plaintext === plaintext ? '✓' : '✗');
    
    // Test password generation
    console.log('\n2. Testing password generation...');
    const password = security.generateSecurePassword(20);
    console.log('   Generated password:', password);
    console.log('   Length:', password.length);
    
    // Test password hashing
    console.log('\n3. Testing password hashing...');
    const hash = security.hashPassword('testpassword123');
    console.log('   Hash:', hash.substring(0, 50) + '...');
    const verify1 = security.verifyPassword('testpassword123', hash);
    const verify2 = security.verifyPassword('wrongpassword', hash);
    console.log('   Correct password:', verify1 ? '✓' : '✗');
    console.log('   Wrong password:', !verify2 ? '✓' : '✗');
    
    // Test HMAC
    console.log('\n4. Testing HMAC...');
    const hmac = security.createHMAC('test data', 'secret-key');
    const hmacValid = security.verifyHMAC('test data', hmac, 'secret-key');
    const hmacInvalid = security.verifyHMAC('test data', hmac, 'wrong-key');
    console.log('   Valid HMAC:', hmacValid ? '✓' : '✗');
    console.log('   Invalid HMAC:', !hmacInvalid ? '✓' : '✗');
    
    // Test hashing
    console.log('\n5. Testing hashing...');
    const hash256 = security.hash('test data');
    console.log('   SHA-256:', hash256);
    
    await security.cleanup();
    console.log('\n=== All tests completed ===');
  })();
}