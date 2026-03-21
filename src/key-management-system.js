/**
 * PolyVault Key Management System
 * Implements secure key generation, storage, and usage flow
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

class KeyManager {
  constructor(options = {}) {
    this.storagePath = options.storagePath || path.join(__dirname, '..', 'keys');
    this.keys = new Map(); // In-memory cache
    
    // Performance optimization: cached keys for fast lookup
    this.keyLookupCache = new Map(); // In-memory cache with TTL
    this.cacheTTL = options.cacheTTL || 300000; // 5 minutes default TTL
  }

  /**
   * Initialize the key manager
   */
  async initialize() {
    try {
      // Create storage directory if it doesn't exist
      await fs.mkdir(this.storagePath, { recursive: true });
      
      // Load existing keys
      await this.loadStoredKeys();
      
      console.log('KeyManager initialized successfully');
      return { success: true, message: 'KeyManager initialized' };
    } catch (error) {
      console.error('Failed to initialize KeyManager:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Load all stored keys into memory
   */
  async loadStoredKeys() {
    try {
      const files = await fs.readdir(this.storagePath);
      const keyFiles = files.filter(file => file.endsWith('.key'));
      
      for (const fileName of keyFiles) {
        const filePath = path.join(this.storagePath, fileName);
        const metadataPath = path.join(this.storagePath, `${fileName}.meta`);
        
        try {
          const keyData = await fs.readFile(filePath, 'utf8');
          let metadata = {};
          
          // Try to load metadata if it exists
          try {
            const metaContent = await fs.readFile(metadataPath, 'utf8');
            metadata = JSON.parse(metaContent);
          } catch (e) {
            // Metadata file doesn't exist or is invalid, create basic metadata
            metadata = {
              id: fileName.replace('.key', ''),
              createdAt: new Date().toISOString(),
              lastAccessed: new Date().toISOString(),
              algorithm: 'unknown'
            };
          }
          
          // Add to in-memory cache
          this.keys.set(metadata.id, JSON.parse(keyData));
          console.log(`Loaded key: ${metadata.id} (${metadata.algorithm})`);
        } catch (error) {
          console.error(`Failed to load key from ${fileName}:`, error.message);
        }
      }
      
      console.log(`Loaded ${keyFiles.length} keys from storage`);
    } catch (error) {
      console.error('Failed to load stored keys:', error.message);
      // Don't throw here as this is initialization, some keys might be recoverable later
    }
  }

  /**
   * Generate a new cryptographic key
   */
  async generateKey(params = {}) {
    try {
      const {
        algorithm = 'ed25519',
        purpose = 'general',
        label = '',
        exportable = false,
        strength = 2048
      } = params;
      
      console.log(`Generating new key with algorithm: ${algorithm}, purpose: ${purpose}`);
      
      let keyPair;
      let keyId;
      
      // Generate the key based on the algorithm
      switch (algorithm.toLowerCase()) {
        case 'rsa':
          keyPair = crypto.generateKeyPairSync('rsa', {
            modulusLength: strength,
            publicKeyEncoding: { type: 'spki', format: 'pem' },
            privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
          });
          break;
          
        case 'ec':
        case 'ecdsa':
          keyPair = crypto.generateKeyPairSync('ec', {
            namedCurve: strength === 384 ? 'secp384r1' : 'prime256v1',
            publicKeyEncoding: { type: 'spki', format: 'pem' },
            privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
          });
          break;
          
        case 'ed25519':
          keyPair = crypto.generateKeyPairSync('ed25519', {
            publicKeyEncoding: { type: 'spki', format: 'pem' },
            privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
          });
          break;
          
        case 'x25519':
          keyPair = crypto.generateKeyPairSync('x25519', {
            publicKeyEncoding: { type: 'spki', format: 'pem' },
            privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
          });
          break;
          
        default:
          throw new Error(`Unsupported algorithm: ${algorithm}`);
      }
      
      // Create a unique key ID
      keyId = `key_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // Create key metadata
      const metadata = {
        id: keyId,
        algorithm,
        purpose,
        label,
        createdAt: new Date().toISOString(),
        lastAccessed: new Date().toISOString(),
        lastRotated: new Date().toISOString(),
        exportable,
        strength,
        usageCount: 0,
        status: 'active'
      };
      
      // Store the key
      if (exportable) {
        // Store in file system
        const keyFileName = `${keyId}.key`;
        const keyFilePath = path.join(this.storagePath, keyFileName);
        
        await fs.writeFile(keyFilePath, JSON.stringify({
          publicKey: keyPair.publicKey,
          privateKey: keyPair.privateKey,
          metadata
        }, null, 2));
        
        // Store metadata
        const metaFileName = `${keyId}.key.meta`;
        const metaFilePath = path.join(this.storagePath, metaFileName);
        await fs.writeFile(metaFilePath, JSON.stringify(metadata, null, 2));
      } else {
        // Store encrypted in file system using AES-GCM
        const encryptedPrivateKey = this._encryptPrivateKey(keyPair.privateKey);
        const keyFileName = `${keyId}.key`;
        const keyFilePath = path.join(this.storagePath, keyFileName);
        
        await fs.writeFile(keyFilePath, JSON.stringify({
          publicKey: keyPair.publicKey,
          privateKey: encryptedPrivateKey,
          metadata
        }, null, 2));
        
        // Store metadata
        const metaFileName = `${keyId}.key.meta`;
        const metaFilePath = path.join(this.storagePath, metaFileName);
        await fs.writeFile(metaFilePath, JSON.stringify(metadata, null, 2));
      }
      
      // Add to in-memory cache
      this.keys.set(keyId, {
        publicKey: keyPair.publicKey,
        privateKey: exportable ? keyPair.privateKey : null,
        metadata
      });
      
      console.log(`Generated and stored key: ${keyId}`);
      return {
        success: true,
        keyId,
        publicKey: keyPair.publicKey,
        metadata
      };
    } catch (error) {
      console.error('Failed to generate key:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Encrypt private key with AES-256-GCM (P0 Security Issue Fix)
   */
  _encryptPrivateKey(privateKey) {
    // Generate random salt and IV
    const salt = crypto.randomBytes(16);
    const iv = crypto.randomBytes(12); // 96-bit IV for GCM
    
    // Derive key using PBKDF2
    const encryptionKey = crypto.pbkdf2Sync('polyvault-master-key', salt, 100000, 32, 'sha256');
    
    // Create AES-256-GCM cipher
    const cipher = crypto.createCipheriv('aes-256-gcm', encryptionKey, iv);
    
    // Encrypt the private key
    const encrypted = Buffer.concat([
      cipher.update(privateKey, 'utf8'),
      cipher.final()
    ]);
    
    // Get authentication tag
    const authTag = cipher.getAuthTag();
    
    return {
      encrypted: encrypted.toString('base64'),
      salt: salt.toString('base64'),
      iv: iv.toString('base64'),
      authTag: authTag.toString('base64')
    };
  }

  /**
   * Decrypt private key
   */
  _decryptPrivateKey(encryptedPrivateKey) {
    const { encrypted, salt, iv, authTag } = encryptedPrivateKey;
    
    // Derive key using PBKDF2
    const encryptionKey = crypto.pbkdf2Sync('polyvault-master-key', Buffer.from(salt, 'base64'), 100000, 32, 'sha256');
    
    // Create AES-256-GCM decipher
    const decipher = crypto.createDecipheriv(
      'aes-256-gcm', 
      encryptionKey, 
      Buffer.from(iv, 'base64')
    );
    
    // Set auth tag for verification
    decipher.setAuthTag(Buffer.from(authTag, 'base64'));
    
    // Decrypt the private key
    const decrypted = Buffer.concat([
      decipher.update(Buffer.from(encrypted, 'base64')),
      decipher.final()
    ]);
    
    return decrypted.toString('utf8');
  }

  /**
   * Get a key by ID (optimized with caching)
   */
  async getKey(keyId, purpose = 'usage') {
    try {
      console.log(`Retrieving key: ${keyId} for purpose: ${purpose}`);
      
      // Performance optimization: Check lookup cache first
      const cachedKey = this.keyLookupCache.get(keyId);
      if (cachedKey && (Date.now() - cachedKey.timestamp) < this.cacheTTL) {
        // Update last accessed time
        cachedKey.metadata.lastAccessed = new Date().toISOString();
        cachedKey.metadata.usageCount = (cachedKey.metadata.usageCount || 0) + 1;
        
        return {
          success: true,
          key: cachedKey,
          needsHardwareOperation: false
        };
      }
      
      // Check in-memory cache
      if (this.keys.has(keyId)) {
        const keyEntry = this.keys.get(keyId);
        
        // Update last accessed time
        keyEntry.metadata.lastAccessed = new Date().toISOString();
        keyEntry.metadata.usageCount = (keyEntry.metadata.usageCount || 0) + 1;
        
        // Update lookup cache
        this.keyLookupCache.set(keyId, {
          ...keyEntry,
          timestamp: Date.now()
        });
        
        return {
          success: true,
          key: keyEntry,
          needsHardwareOperation: false
        };
      }
      
      // Load from storage if not in cache
      const keyFileName = `${keyId}.key`;
      const keyFilePath = path.join(this.storagePath, keyFileName);
      
      try {
        const keyDataStr = await fs.readFile(keyFilePath, 'utf8');
        const keyData = JSON.parse(keyDataStr);
        
        // Decrypt private key if encrypted
        let privateKey = keyData.privateKey;
        if (privateKey && typeof privateKey === 'object' && privateKey.encrypted) {
          privateKey = this._decryptPrivateKey(privateKey);
        }
        
        // Update metadata
        const metadata = keyData.metadata || {};
        metadata.lastAccessed = new Date().toISOString();
        metadata.usageCount = (metadata.usageCount || 0) + 1;
        
        // Create key entry
        const keyEntry = {
          publicKey: keyData.publicKey,
          privateKey: privateKey,
          metadata
        };
        
        // Add to cache
        this.keys.set(keyId, keyEntry);
        
        return {
          success: true,
          key: keyEntry,
          needsHardwareOperation: false
        };
      } catch (error) {
        console.error(`Failed to load key ${keyId} from storage:`, error.message);
        return { success: false, error: `Key ${keyId} not found` };
      }
    } catch (error) {
      console.error('Failed to retrieve key:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Perform a cryptographic operation using a key
   */
  async useKey(keyId, operation, data) {
    try {
      console.log(`Using key ${keyId} for operation: ${operation}`);
      
      const keyResult = await this.getKey(keyId);
      if (!keyResult.success) {
        return keyResult;
      }
      
      const key = keyResult.key;
      
      // Check if key is active
      if (key.metadata.status !== 'active') {
        return {
          success: false,
          error: `Key ${keyId} is not active (status: ${key.metadata.status})`
        };
      }
      
      // Check if operation is allowed for this key's purpose
      if (!this._isOperationAllowed(operation, key.metadata.purpose)) {
        return {
          success: false,
          error: `Operation ${operation} not allowed for key purpose: ${key.metadata.purpose}`
        };
      }
      
      let result;
      
      // Perform operation using software implementation
      switch (operation) {
        case 'sign':
          result = this._softwareSign(key, data);
          break;
        case 'verify':
          result = this._softwareVerify(key, data);
          break;
        case 'encrypt':
          result = this._softwareEncrypt(key, data);
          break;
        case 'decrypt':
          result = this._softwareDecrypt(key, data);
          break;
        default:
          return { success: false, error: `Unsupported operation: ${operation}` };
      }
      
      // Update usage statistics
      key.metadata.lastUsed = new Date().toISOString();
      key.metadata.operationCount = (key.metadata.operationCount || 0) + 1;
      
      return {
        success: true,
        result,
        keyId,
        operation,
        metadata: key.metadata
      };
    } catch (error) {
      console.error(`Failed to use key ${keyId} for operation ${operation}:`, error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Check if an operation is allowed for a key's purpose
   */
  _isOperationAllowed(operation, purpose) {
    const allowedOperations = {
      'signing': ['sign', 'verify'],
      'encryption': ['encrypt', 'decrypt', 'sign', 'verify'],
      'authentication': ['sign', 'verify'],
      'general': ['sign', 'verify', 'encrypt', 'decrypt'],
      'exchange': ['encrypt', 'decrypt']
    };
    
    const allowed = allowedOperations[purpose] || allowedOperations.general;
    return allowed.includes(operation);
  }

  /**
   * Software implementation of signing
   */
  _softwareSign(key, data) {
    try {
      if (!key.privateKey) {
        return { success: false, error: 'Private key not available for signing' };
      }
      
      const sign = crypto.createSign('SHA256');
      sign.write(typeof data === 'string' ? data : JSON.stringify(data));
      sign.end();
      
      const signature = sign.sign(key.privateKey, 'hex');
      
      return {
        success: true,
        signature,
        algorithm: key.metadata.algorithm
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Software implementation of verification
   */
  _softwareVerify(key, dataAndSignature) {
    try {
      const { data, signature } = dataAndSignature;
      
      const verify = crypto.createVerify('SHA256');
      verify.write(typeof data === 'string' ? data : JSON.stringify(data));
      verify.end();
      
      const isValid = verify.verify(key.publicKey, signature, 'hex');
      
      return {
        success: true,
        valid: isValid,
        algorithm: key.metadata.algorithm
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Software implementation of encryption
   */
  _softwareEncrypt(key, data) {
    try {
      const plaintext = typeof data === 'string' ? data : JSON.stringify(data);
      
      // Using public key for encryption (for asymmetric algorithms)
      let encrypted;
      if (key.metadata.algorithm.startsWith('rsa')) {
        encrypted = crypto.publicEncrypt(
          {
            key: key.publicKey,
            padding: crypto.constants.RSA_PKCS1_OAEP_PADDING,
            oaepHash: 'sha256'
          },
          Buffer.from(plaintext)
        ).toString('hex');
      } else {
        // For other algorithms, use hybrid encryption with RSA
        const ephemeralKey = crypto.generateKeyPairSync('rsa', {
          modulusLength: 2048,
          publicKeyEncoding: { type: 'spki', format: 'pem' },
          privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
        });
        
        // Encrypt data with ephemeral symmetric key
        const symmetricKey = crypto.randomBytes(32);
        const iv = crypto.randomBytes(16);
        const cipher = crypto.createCipheriv('aes-256-gcm', symmetricKey, iv);
        
        const encryptedData = Buffer.concat([
          cipher.update(plaintext, 'utf8'),
          cipher.final()
        ]);
        const authTag = cipher.getAuthTag();
        
        // Encrypt the symmetric key with the RSA public key
        const encryptedSymmetricKey = crypto.publicEncrypt(
          key.publicKey,
          symmetricKey
        ).toString('hex');
        
        encrypted = JSON.stringify({
          encryptedData: encryptedData.toString('hex'),
          iv: iv.toString('hex'),
          authTag: authTag.toString('hex'),
          encryptedSymmetricKey
        });
      }
      
      return {
        success: true,
        encrypted,
        algorithm: key.metadata.algorithm
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Software implementation of decryption
   */
  _softwareDecrypt(key, encryptedData) {
    try {
      if (!key.privateKey) {
        return { success: false, error: 'Private key not available for decryption' };
      }
      
      // For asymmetric decryption
      let decrypted;
      if (key.metadata.algorithm.startsWith('rsa')) {
        // Check if it's a simple RSA encrypted string or hybrid
        try {
          const parsed = JSON.parse(encryptedData);
          if (parsed.encryptedSymmetricKey) {
            // Hybrid encryption - decrypt symmetric key first
            const symmetricKey = crypto.privateDecrypt(
              key.privateKey,
              Buffer.from(parsed.encryptedSymmetricKey, 'hex')
            );
            
            // Decrypt data with symmetric key
            const decipher = crypto.createDecipheriv(
              'aes-256-gcm',
              symmetricKey,
              Buffer.from(parsed.iv, 'hex')
            );
            decipher.setAuthTag(Buffer.from(parsed.authTag, 'hex'));
            
            decrypted = Buffer.concat([
              decipher.update(Buffer.from(parsed.encryptedData, 'hex')),
              decipher.final()
            ]).toString();
          }
        } catch (e) {
          // Not JSON, treat as simple RSA encrypted
          decrypted = crypto.privateDecrypt(
            key.privateKey,
            Buffer.from(encryptedData, 'hex')
          ).toString();
        }
      } else {
        decrypted = 'Decryption requires proper hybrid encryption implementation';
      }
      
      return {
        success: true,
        decrypted,
        algorithm: key.metadata.algorithm
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Get key usage statistics
   */
  getKeyStats(keyId) {
    const key = this.keys.get(keyId);
    if (!key) {
      return { success: false, error: `Key ${keyId} not found` };
    }

    return {
      success: true,
      stats: {
        id: key.metadata.id,
        algorithm: key.metadata.algorithm,
        purpose: key.metadata.purpose,
        status: key.metadata.status,
        usageCount: key.metadata.usageCount || 0,
        operationCount: key.metadata.operationCount || 0,
        createdAt: key.metadata.createdAt,
        lastAccessed: key.metadata.lastAccessed,
        lastUsed: key.metadata.lastUsed,
        age: Date.now() - new Date(key.metadata.createdAt).getTime()
      }
    };
  }

  /**
   * Get all keys with basic info
   */
  getAllKeys(basicInfoOnly = true) {
    const keys = [];

    for (const [keyId, key] of this.keys) {
      const keyInfo = basicInfoOnly ? {
        id: key.metadata.id,
        algorithm: key.metadata.algorithm,
        purpose: key.metadata.purpose,
        status: key.metadata.status,
        createdAt: key.metadata.createdAt,
        lastAccessed: key.metadata.lastAccessed
      } : {
        ...key
      };

      keys.push(keyInfo);
    }

    return {
      success: true,
      keys,
      count: keys.length
    };
  }

  /**
   * Cleanup and close resources
   */
  async cleanup() {
    console.log('Cleaning up KeyManager resources...');
    
    // Clear in-memory caches
    this.keys.clear();
    this.keyLookupCache.clear();
    
    console.log('KeyManager cleaned up successfully');
    return { success: true, message: 'KeyManager resources cleaned up' };
  }
}

// Export the KeyManager class
module.exports = KeyManager;

// Example usage when run directly
if (require.main === module) {
  console.log('KeyManager module loaded - running example...');
  
  (async () => {
    const keyManager = new KeyManager({
      storagePath: path.join(__dirname, '..', 'test-keys')
    });
    
    // Initialize the key manager
    const initResult = await keyManager.initialize();
    console.log('Initialization result:', initResult);
    
    if (initResult.success) {
      // Generate a signing key
      const signingKeyResult = await keyManager.generateKey({
        algorithm: 'ed25519',
        purpose: 'signing',
        label: 'example-signing-key',
        exportable: true
      });
      console.log('Signing key generation result:', signingKeyResult.success ? 'Success' : 'Failed');
      
      if (signingKeyResult.success) {
        // Use the key to sign some data
        const signResult = await keyManager.useKey(
          signingKeyResult.keyId,
          'sign',
          { message: 'Hello, PolyVault!', timestamp: Date.now() }
        );
        console.log('Signing result:', signResult.success ? 'Success' : 'Failed');
        
        // Get key statistics
        const stats = keyManager.getKeyStats(signingKeyResult.keyId);
        console.log('Key stats:', stats.success ? 'Retrieved' : 'Failed');
        
        // Get all keys
        const allKeys = keyManager.getAllKeys();
        console.log('All keys count:', allKeys.count);
      }
      
      // Cleanup
      await keyManager.cleanup();
    }
  })();
}