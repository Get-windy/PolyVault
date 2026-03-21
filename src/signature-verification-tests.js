/**
 * PolyVault Signature Verification Tests
 * Comprehensive test suite for digital signature and verification
 */

const assert = require('assert');
const crypto = require('crypto');
const fs = require('fs').promises;
const path = require('path');
const SignatureVerifier = require('./signature-verification');

const testStoragePath = path.join(__dirname, '..', 'test-signatures-temp');

describe('PolyVault Signature Verification Tests', function() {
  let verifier;
  let testKeys = {};

  before(async function() {
    // Create test storage directory
    await fs.mkdir(testStoragePath, { recursive: true });
    
    // Initialize verifier
    verifier = new SignatureVerifier({
      storagePath: testStoragePath
    });
    
    const initResult = await verifier.initialize();
    assert.strictEqual(initResult.success, true, 'Verifier should initialize');
    
    // Generate test key pairs for different algorithms
    testKeys.ed25519 = crypto.generateKeyPairSync('ed25519', {
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
    });
    
    testKeys.rsa = crypto.generateKeyPairSync('rsa', {
      modulusLength: 2048,
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
    });
    
    testKeys.ecdsa = crypto.generateKeyPairSync('ec', {
      namedCurve: 'prime256v1',
      publicKeyEncoding: { type: 'spki', format: 'pem' },
      privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
    });
    
    console.log('Test environment set up with key pairs');
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
      console.warn('Cleanup error:', error.message);
    }
    
    await verifier.cleanup();
  });

  describe('Basic Signing Tests', function() {
    it('should sign data with Ed25519 key', async function() {
      const result = await verifier.sign({
        privateKey: testKeys.ed25519.privateKey,
        data: { test: 'data', timestamp: Date.now() }
      });
      
      assert.strictEqual(result.success, true, 'Should sign successfully');
      assert.ok(result.signature, 'Should return signature');
      assert.ok(result.signatureId, 'Should return signature ID');
    });

    it('should sign data with RSA key', async function() {
      const result = await verifier.sign({
        privateKey: testKeys.rsa.privateKey,
        data: 'RSA signing test'
      });
      
      assert.strictEqual(result.success, true, 'Should sign with RSA');
      assert.ok(result.signature, 'Should return RSA signature');
    });

    it('should sign data with ECDSA key', async function() {
      const result = await verifier.sign({
        privateKey: testKeys.ecdsa.privateKey,
        data: 'ECDSA signing test'
      });
      
      assert.strictEqual(result.success, true, 'Should sign with ECDSA');
      assert.ok(result.signature, 'Should return ECDSA signature');
    });

    it('should fail without private key', async function() {
      const result = await verifier.sign({
        privateKey: null,
        data: 'test'
      });
      
      assert.strictEqual(result.success, false, 'Should fail without key');
      assert.ok(result.error, 'Should return error message');
    });

    it('should fail without data', async function() {
      const result = await verifier.sign({
        privateKey: testKeys.ed25519.privateKey,
        data: null
      });
      
      assert.strictEqual(result.success, false, 'Should fail without data');
    });
  });

  describe('Basic Verification Tests', function() {
    let testSignature;
    let testData = { message: 'Verification test', id: 123 };

    before(async function() {
      testSignature = await verifier.sign({
        privateKey: testKeys.ed25519.privateKey,
        data: testData
      });
    });

    it('should verify valid signature', async function() {
      const result = await verifier.verify({
        publicKey: testKeys.ed25519.publicKey,
        signature: testSignature.signature,
        data: testData
      });
      
      assert.strictEqual(result.success, true, 'Verification should succeed');
      assert.strictEqual(result.valid, true, 'Signature should be valid');
    });

    it('should reject invalid signature', async function() {
      const result = await verifier.verify({
        publicKey: testKeys.ed25519.publicKey,
        signature: 'invalid_signature_data',
        data: testData
      });
      
      assert.strictEqual(result.success, true, 'Should complete verification');
      assert.strictEqual(result.valid, false, 'Invalid signature should fail');
    });

    it('should reject signature with different data', async function() {
      const result = await verifier.verify({
        publicKey: testKeys.ed25519.publicKey,
        signature: testSignature.signature,
        data: { different: 'data' }
      });
      
      assert.strictEqual(result.valid, false, 'Should reject tampered data');
    });

    it('should verify with RSA key', async function() {
      const rsaSignature = await verifier.sign({
        privateKey: testKeys.rsa.privateKey,
        data: 'RSA verify test'
      });
      
      const result = await verifier.verify({
        publicKey: testKeys.rsa.publicKey,
        signature: rsaSignature.signature,
        data: 'RSA verify test'
      });
      
      assert.strictEqual(result.valid, true, 'RSA verification should pass');
    });
  });

  describe('Detached Signature Tests', function() {
    it('should create detached signature', async function() {
      const result = await verifier.createDetachedSignature({
        privateKey: testKeys.ed25519.privateKey,
        data: 'Detached signature test'
      });
      
      assert.strictEqual(result.success, true, 'Should create detached signature');
      assert.ok(result.signature, 'Should return signature');
      assert.ok(result.dataHash, 'Should return data hash');
    });

    it('should verify detached signature', async function() {
      const detached = await verifier.createDetachedSignature({
        privateKey: testKeys.ed25519.privateKey,
        data: 'Detached verify test'
      });
      
      const result = await verifier.verifyDetachedSignature({
        publicKey: testKeys.ed25519.publicKey,
        signature: detached.signature,
        data: 'Detached verify test'
      });
      
      assert.strictEqual(result.valid, true, 'Detached signature should verify');
    });

    it('should reject wrong detached signature', async function() {
      const detached = await verifier.createDetachedSignature({
        privateKey: testKeys.ed25519.privateKey,
        data: 'Original data'
      });
      
      const result = await verifier.verifyDetachedSignature({
        publicKey: testKeys.ed25519.publicKey,
        signature: detached.signature,
        data: 'Different data'
      });
      
      assert.strictEqual(result.valid, false, 'Should reject different data');
    });
  });

  describe('Batch Operations Tests', function() {
    it('should batch sign multiple items', async function() {
      const dataItems = [
        { id: 'item1', data: 'Data 1' },
        { id: 'item2', data: 'Data 2' },
        { id: 'item3', data: 'Data 3' }
      ];
      
      const result = await verifier.batchSign({
        privateKey: testKeys.ed25519.privateKey,
        dataItems
      });
      
      assert.strictEqual(result.success, true, 'Batch sign should succeed');
      assert.strictEqual(result.succeeded, 3, 'All items should sign');
      assert.strictEqual(result.failed, 0, 'No items should fail');
    });

    it('should batch verify multiple signatures', async function() {
      // First create signatures
      const dataItems = [
        { id: 'verify1', data: 'Verify test 1' },
        { id: 'verify2', data: 'Verify test 2' }
      ];
      
      const signResult = await verifier.batchSign({
        privateKey: testKeys.ed25519.privateKey,
        dataItems
      });
      
      // Now verify them
      const verifyItems = signResult.results.map((r, i) => ({
        id: r.id,
        signature: r.signature,
        data: dataItems[i].data
      }));
      
      const result = await verifier.batchVerify({
        publicKey: testKeys.ed25519.publicKey,
        signatureItems: verifyItems
      });
      
      assert.strictEqual(result.valid, 2, 'All signatures should be valid');
      assert.strictEqual(result.invalid, 0, 'No signatures should be invalid');
    });

    it('should handle batch with mixed results', async function() {
      const dataItems = [
        { id: 'valid', data: 'Valid data' },
        { id: 'invalid', data: 'Invalid' }
      ];
      
      // Create signatures
      const signResult = await verifier.batchSign({
        privateKey: testKeys.ed25519.privateKey,
        dataItems
      });
      
      // Tamper with one signature
      signResult.results[1].signature = 'tampered_signature';
      
      // Try to verify
      const verifyItems = signResult.results.map((r, i) => ({
        id: r.id,
        signature: r.signature,
        data: dataItems[i].data
      }));
      
      const result = await verifier.batchVerify({
        publicKey: testKeys.ed25519.publicKey,
        signatureItems: verifyItems
      });
      
      assert.strictEqual(result.valid, 1, 'One should be valid');
      assert.strictEqual(result.invalid, 1, 'One should be invalid');
    });
  });

  describe('Algorithm Tests', function() {
    it('should work with SHA-256', async function() {
      const signResult = await verifier.sign({
        privateKey: testKeys.ed25519.privateKey,
        data: 'SHA256 test',
        algorithm: 'sha256'
      });
      
      const verifyResult = await verifier.verify({
        publicKey: testKeys.ed25519.publicKey,
        signature: signResult.signature,
        data: 'SHA256 test',
        algorithm: 'sha256'
      });
      
      assert.strictEqual(verifyResult.valid, true, 'SHA-256 should work');
    });

    it('should work with SHA-512', async function() {
      const signResult = await verifier.sign({
        privateKey: testKeys.ed25519.privateKey,
        data: 'SHA512 test',
        algorithm: 'sha512'
      });
      
      const verifyResult = await verifier.verify({
        publicKey: testKeys.ed25519.publicKey,
        signature: signResult.signature,
        data: 'SHA512 test',
        algorithm: 'sha512'
      });
      
      assert.strictEqual(verifyResult.valid, true, 'SHA-512 should work');
    });

    it('should work with different format (base64)', async function() {
      const signResult = await verifier.sign({
        privateKey: testKeys.ed25519.privateKey,
        data: 'Format test',
        format: 'base64'
      });
      
      const verifyResult = await verifier.verify({
        publicKey: testKeys.ed25519.publicKey,
        signature: signResult.signature,
        data: 'Format test',
        format: 'base64'
      });
      
      assert.strictEqual(verifyResult.valid, true, 'Base64 format should work');
    });
  });

  describe('Signature Management Tests', function() {
    it('should save and retrieve signature', async function() {
      const signResult = await verifier.sign({
        privateKey: testKeys.ed25519.privateKey,
        data: 'Storage test'
      });
      
      const retrieveResult = await verifier.getSignature(signResult.signatureId);
      
      assert.strictEqual(retrieveResult.success, true, 'Should retrieve signature');
      assert.strictEqual(retrieveResult.signature.id, signResult.signatureId);
    });

    it('should list all signatures', async function() {
      const result = await verifier.listSignatures();
      
      assert.strictEqual(result.success, true, 'Should list signatures');
      assert.ok(result.count >= 0, 'Should return count');
    });
  });
});

// Helper for file existence check
async function fileExists(filePath) {
  try {
    await fs.access(filePath);
    return true;
  } catch {
    return false;
  }
}

// Run if executed directly
if (require.main === module) {
  console.log('Signature Verification Tests');
  console.log('Run with: npx mocha signature-verification-tests.js');
}