/**
 * PolyVault Digital Signature and Verification Module
 * Implements cryptographic signing and verification for data integrity
 * Optimized for performance with caching and efficient algorithms
 */

const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');

// Performance optimization: LRU cache for verified signatures
class LRUCache {
  constructor(maxSize = 100) {
    this.maxSize = maxSize;
    this.cache = new Map();
  }

  get(key) {
    if (!this.cache.has(key)) return null;
    const value = this.cache.get(key);
    this.cache.delete(key);
    this.cache.set(key, value);
    return value;
  }

  set(key, value) {
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }
    this.cache.set(key, value);
  }

  clear() {
    this.cache.clear();
  }
}

class SignatureVerifier {
  constructor(options = {}) {
    this.storagePath = options.storagePath || path.join(__dirname, '..', 'signatures');
    this.keyManager = options.keyManager || null;
    this.signatureCache = new Map();
    
    // Performance optimization: Cache for verification results
    this.verificationCache = new LRUCache(options.cacheSize || 200);
    
    // Performance optimization: Pre-computed hash algorithms
    this.hashAlgorithms = {
      'sha256': crypto.createHash('sha256'),
      'sha384': crypto.createHash('sha384'),
      'sha512': crypto.createHash('sha512')
    };
    
    // Performance optimization: Signature pool for batch operations
    this.signaturePool = [];
    this.poolSize = options.poolSize || 50;
  }

  /**
   * Initialize the signature verifier
   */
  async initialize() {
    try {
      await fs.mkdir(this.storagePath, { recursive: true });
      console.log('SignatureVerifier initialized successfully');
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Sign data using a private key
   */
  async sign(params) {
    try {
      const { privateKey, data, algorithm = 'sha256', format = 'hex' } = params;
      
      if (!privateKey) {
        return { success: false, error: 'Private key is required' };
      }
      
      if (!data) {
        return { success: false, error: 'Data to sign is required' };
      }

      // Create signature using the appropriate algorithm
      const sign = crypto.createSign(algorithm.toUpperCase());
      sign.update(typeof data === 'string' ? data : JSON.stringify(data));
      sign.end();
      
      const signature = sign.sign(privateKey, format);
      
      // Create signature record
      const signatureId = `sig_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const signatureRecord = {
        id: signatureId,
        signature,
        format,
        algorithm: algorithm.toUpperCase(),
        createdAt: new Date().toISOString(),
        dataHash: crypto.createHash('sha256').update(typeof data === 'string' ? data : JSON.stringify(data)).digest('hex')
      };
      
      // Cache the signature
      this.signatureCache.set(signatureId, signatureRecord);
      
      // Save to storage
      await this._saveSignature(signatureRecord);
      
      return {
        success: true,
        signatureId,
        signature,
        algorithm: signatureRecord.algorithm
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Verify a signature using a public key (optimized with caching)
   */
  async verify(params) {
    try {
      const { publicKey, signature, data, algorithm = 'sha256', format = 'hex' } = params;
      
      if (!publicKey) {
        return { success: false, error: 'Public key is required' };
      }
      
      if (!signature) {
        return { success: false, error: 'Signature is required' };
      }
      
      if (!data) {
        return { success: false, error: 'Data to verify is required' };
      }

      // Performance optimization: Check cache first
      const dataStr = typeof data === 'string' ? data : JSON.stringify(data);
      const cacheKey = `${signature}:${dataStr}:${algorithm}`;
      const cachedResult = this.verificationCache.get(cacheKey);
      
      if (cachedResult !== null) {
        return cachedResult;
      }

      // Create verifier
      const verify = crypto.createVerify(algorithm.toUpperCase());
      verify.update(dataStr);
      verify.end();
      
      // Perform verification
      const isValid = verify.verify(publicKey, signature, format);
      
      const result = {
        success: true,
        valid: isValid,
        algorithm: algorithm.toUpperCase(),
        verifiedAt: new Date().toISOString()
      };
      
      // Cache the result (for identical signature + data combinations)
      this.verificationCache.set(cacheKey, result);
      
      return result;
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Sign data with a key from key manager
   */
  async signWithKeyId(params) {
    try {
      const { keyId, data, algorithm = 'sha256', format = 'hex' } = params;
      
      if (!this.keyManager) {
        return { success: false, error: 'Key manager not configured' };
      }
      
      // Get the key from key manager
      const keyResult = await this.keyManager.getKey(keyId, 'sign');
      if (!keyResult.success) {
        return { success: false, error: `Failed to get key: ${keyResult.error}` };
      }
      
      if (!keyResult.key.privateKey) {
        return { success: false, error: 'Private key not available' };
      }
      
      // Sign the data
      return await this.sign({
        privateKey: keyResult.key.privateKey,
        data,
        algorithm,
        format
      });
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Verify signature with a key from key manager
   */
  async verifyWithKeyId(params) {
    try {
      const { keyId, signature, data, algorithm = 'sha256', format = 'hex' } = params;
      
      if (!this.keyManager) {
        return { success: false, error: 'Key manager not configured' };
      }
      
      // Get the key from key manager
      const keyResult = await this.keyManager.getKey(keyId, 'verify');
      if (!keyResult.success) {
        return { success: false, error: `Failed to get key: ${keyResult.error}` };
      }
      
      // Verify the signature
      return await this.verify({
        publicKey: keyResult.key.publicKey,
        signature,
        data,
        algorithm,
        format
      });
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Create a detached signature (signature without data)
   */
  async createDetachedSignature(params) {
    try {
      const { privateKey, data, algorithm = 'sha256' } = params;
      
      if (!privateKey) {
        return { success: false, error: 'Private key is required' };
      }
      
      if (!data) {
        return { success: false, error: 'Data to sign is required' };
      }

      // Hash the data first
      const dataHash = crypto.createHash(algorithm).update(typeof data === 'string' ? data : JSON.stringify(data)).digest();
      
      // Create signature from the hash
      const sign = crypto.createSign(algorithm.toUpperCase());
      sign.update(dataHash);
      sign.end();
      
      const signature = sign.sign(privateKey, 'base64');
      
      // Create signature metadata
      const signatureId = `detached_sig_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      const signatureMeta = {
        id: signatureId,
        signature,
        algorithm: algorithm.toUpperCase(),
        dataHash: dataHash.toString('base64'),
        createdAt: new Date().toISOString()
      };
      
      // Save to storage
      await this._saveSignature(signatureMeta);
      
      return {
        success: true,
        signatureId,
        signature,
        dataHash: signatureMeta.dataHash,
        algorithm: signatureMeta.algorithm
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Verify a detached signature
   */
  async verifyDetachedSignature(params) {
    try {
      const { publicKey, signature, data, algorithm = 'sha256' } = params;
      
      if (!publicKey) {
        return { success: false, error: 'Public key is required' };
      }
      
      if (!signature) {
        return { success: false, error: 'Signature is required' };
      }
      
      if (!data) {
        return { success: false, error: 'Data to verify is required' };
      }

      // Hash the data first
      const dataHash = crypto.createHash(algorithm).update(typeof data === 'string' ? data : JSON.stringify(data)).digest();
      
      // Create verifier with the hash
      const verify = crypto.createVerify(algorithm.toUpperCase());
      verify.update(dataHash);
      verify.end();
      
      // Perform verification
      const isValid = verify.verify(publicKey, signature, 'base64');
      
      return {
        success: true,
        valid: isValid,
        algorithm: algorithm.toUpperCase(),
        verifiedAt: new Date().toISOString()
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Batch sign multiple data items
   */
  async batchSign(params) {
    try {
      const { privateKey, dataItems, algorithm = 'sha256', format = 'hex' } = params;
      
      if (!privateKey) {
        return { success: false, error: 'Private key is required' };
      }
      
      if (!dataItems || !Array.isArray(dataItems)) {
        return { success: false, error: 'Data items array is required' };
      }

      const results = [];
      
      for (const item of dataItems) {
        const result = await this.sign({
          privateKey,
          data: item.data,
          algorithm,
          format
        });
        
        results.push({
          id: item.id || `item_${results.length}`,
          ...result
        });
      }
      
      const successCount = results.filter(r => r.success).length;
      
      return {
        success: successCount > 0,
        total: dataItems.length,
        succeeded: successCount,
        failed: dataItems.length - successCount,
        results
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Batch verify multiple signatures (optimized with parallel processing)
   */
  async batchVerify(params) {
    try {
      const { publicKey, signatureItems, algorithm = 'sha256', format = 'hex', parallel = true } = params;
      
      if (!publicKey) {
        return { success: false, error: 'Public key is required' };
      }
      
      if (!signatureItems || !Array.isArray(signatureItems)) {
        return { success: false, error: 'Signature items array is required' };
      }

      let results;
      
      if (parallel && signatureItems.length > 1) {
        // Performance optimization: Parallel verification for multiple items
        const promises = signatureItems.map(item => 
          this.verify({
            publicKey,
            signature: item.signature,
            data: item.data,
            algorithm,
            format
          }).then(result => ({
            id: item.id || `item_${signatureItems.indexOf(item)}`,
            ...result
          }))
        );
        
        results = await Promise.all(promises);
      } else {
        // Sequential verification
        results = [];
        
        for (const item of signatureItems) {
          const result = await this.verify({
            publicKey,
            signature: item.signature,
            data: item.data,
            algorithm,
            format
          });
          
          results.push({
            id: item.id || `item_${results.length}`,
            ...result
          });
        }
      }
      
      const validCount = results.filter(r => r.valid).length;
      
      return {
        success: true,
        total: signatureItems.length,
        valid: validCount,
        invalid: signatureItems.length - validCount,
        results
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Save signature to storage
   */
  async _saveSignature(signatureRecord) {
    try {
      const filePath = path.join(this.storagePath, `${signatureRecord.id}.json`);
      await fs.writeFile(filePath, JSON.stringify(signatureRecord, null, 2));
    } catch (error) {
      console.error('Failed to save signature:', error.message);
    }
  }

  /**
   * Get signature by ID
   */
  async getSignature(signatureId) {
    try {
      // Check cache first
      if (this.signatureCache.has(signatureId)) {
        return { success: true, signature: this.signatureCache.get(signatureId) };
      }
      
      // Load from storage
      const filePath = path.join(this.storagePath, `${signatureId}.json`);
      const content = await fs.readFile(filePath, 'utf8');
      const signature = JSON.parse(content);
      
      // Add to cache
      this.signatureCache.set(signatureId, signature);
      
      return { success: true, signature };
    } catch (error) {
      return { success: false, error: `Signature not found: ${error.message}` };
    }
  }

  /**
   * List all signatures
   */
  async listSignatures() {
    try {
      const files = await fs.readdir(this.storagePath);
      const signatures = files
        .filter(f => f.endsWith('.json'))
        .map(f => f.replace('.json', ''));
      
      return { success: true, signatures, count: signatures.length };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Cleanup resources
   */
  async cleanup() {
    this.signatureCache.clear();
    this.verificationCache.clear();
    console.log('SignatureVerifier cleaned up');
    return { success: true };
  }
}

module.exports = SignatureVerifier;

// Example usage
if (require.main === module) {
  console.log('PolyVault Signature Verification Module');
  
  (async () => {
    const verifier = new SignatureVerifier();
    await verifier.initialize();
    
    // Generate a test key pair
    const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519', {
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
    });
    
    // Test signing
    const signResult = await verifier.sign({
      privateKey,
      data: { message: 'Test data for signing', timestamp: Date.now() }
    });
    console.log('Sign result:', signResult.success ? 'Success' : 'Failed');
    
    if (signResult.success) {
      // Test verification
      const verifyResult = await verifier.verify({
        publicKey,
        signature: signResult.signature,
        data: { message: 'Test data for signing', timestamp: Date.now() }
      });
      console.log('Verify result:', verifyResult.valid ? 'VALID' : 'INVALID');
      
      // Test detached signature
      const detachedResult = await verifier.createDetachedSignature({
        privateKey,
        data: 'Detached signature test'
      });
      console.log('Detached signature:', detachedResult.success ? 'Created' : 'Failed');
      
      if (detachedResult.success) {
        const detachedVerify = await verifier.verifyDetachedSignature({
          publicKey,
          signature: detachedResult.signature,
          data: 'Detached signature test'
        });
        console.log('Detached verify:', detachedVerify.valid ? 'VALID' : 'INVALID');
      }
    }
    
    await verifier.cleanup();
  })();
}