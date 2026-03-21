# PolyVault Digital Signature and Verification System

## Overview

The PolyVault Digital Signature and Verification System provides comprehensive cryptographic signing and verification capabilities for data integrity. It supports multiple signature algorithms, formats, and operation modes.

## Features

### Supported Algorithms
- **Ed25519**: Modern elliptic curve signature algorithm
- **RSA**: Classic asymmetric algorithm with PKCS#1 padding
- **ECDSA**: Elliptic Curve Digital Signature Algorithm

### Hash Algorithms
- SHA-256
- SHA-384
- SHA-512

### Signature Formats
- Hexadecimal (default)
- Base64
- Binary

## Architecture

### Components

1. **SignatureVerifier** (`signature-verification.js`)
   - Core signing and verification engine
   - Supports attached and detached signatures
   - Batch operations support

2. **SignatureAPI** (`signature-api.js`)
   - RESTful API wrapper
   - HTTP endpoints for all operations
   - Rate limiting and authentication

3. **Test Suite** (`signature-verification-tests.js`)
   - Comprehensive unit tests
   - Integration tests
   - Algorithm comparison tests

## Usage Examples

### Basic Signing and Verification

```javascript
const SignatureVerifier = require('./signature-verification');
const crypto = require('crypto');

const verifier = new SignatureVerifier();
await verifier.initialize();

// Generate key pair
const { publicKey, privateKey } = crypto.generateKeyPairSync('ed25519', {
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
});

// Sign data
const signResult = await verifier.sign({
  privateKey,
  data: { message: 'Hello, PolyVault!' }
});

// Verify signature
const verifyResult = await verifier.verify({
  publicKey,
  signature: signResult.signature,
  data: { message: 'Hello, PolyVault!' }
});

console.log('Valid:', verifyResult.valid);
```

### Detached Signatures

Detached signatures are useful when you need to sign data without including the signature in the data stream:

```javascript
// Create detached signature
const detachedResult = await verifier.createDetachedSignature({
  privateKey,
  data: 'File content or any data'
});

// Verify detached signature later
const verifyResult = await verifier.verifyDetachedSignature({
  publicKey,
  signature: detachedResult.signature,
  data: 'File content or any data'
});
```

### Batch Operations

```javascript
// Batch signing
const dataItems = [
  { id: 'doc1', data: 'Document 1 content' },
  { id: 'doc2', data: 'Document 2 content' },
  { id: 'doc3', data: 'Document 3 content' }
];

const batchResult = await verifier.batchSign({
  privateKey,
  dataItems
});

console.log(`Signed ${batchResult.succeeded} of ${batchResult.total} items`);

// Batch verification
const verifyItems = batchResult.results.map((r, i) => ({
  id: r.id,
  signature: r.signature,
  data: dataItems[i].data
}));

const verifyResult = await verifier.batchVerify({
  publicKey,
  signatureItems: verifyItems
});

console.log(`Valid: ${verifyResult.valid}, Invalid: ${verifyResult.invalid}`);
```

## REST API Endpoints

### POST /api/sign
Sign data with a private key.

**Request:**
```json
{
  "privateKey": "-----BEGIN PRIVATE KEY-----\n...",
  "data": { "message": "Hello" },
  "algorithm": "sha256",
  "format": "hex"
}
```

**Response:**
```json
{
  "success": true,
  "signatureId": "sig_1234567890_abc",
  "signature": "a1b2c3d4...",
  "algorithm": "SHA256"
}
```

### POST /api/verify
Verify a signature.

**Request:**
```json
{
  "publicKey": "-----BEGIN PUBLIC KEY-----\n...",
  "signature": "a1b2c3d4...",
  "data": { "message": "Hello" }
}
```

**Response:**
```json
{
  "success": true,
  "valid": true,
  "algorithm": "SHA256"
}
```

### POST /api/sign/detached
Create a detached signature.

### POST /api/verify/detached
Verify a detached signature.

### POST /api/sign/batch
Batch sign multiple items.

### POST /api/verify/batch
Batch verify multiple signatures.

### GET /api/signatures/:signatureId
Retrieve a signature by ID.

### GET /api/signatures
List all stored signatures.

## Security Considerations

### Key Management
- Private keys should be stored securely (use KeyManager)
- Public keys can be distributed freely
- Use hardware security modules for production

### Algorithm Selection
- Ed25519 recommended for new implementations
- RSA-2048 minimum for legacy compatibility
- Use SHA-256 or stronger for hashing

### Best Practices
1. Always verify signatures before trusting data
2. Use detached signatures for file signing
3. Implement signature expiration policies
4. Log all verification attempts for audit
5. Use consistent encoding (UTF-8) for data

## Testing

Run the test suite:

```bash
npx mocha signature-verification-tests.js
```

### Test Coverage
- Basic signing with all algorithms
- Signature verification
- Detached signatures
- Batch operations
- Multiple hash algorithms
- Error handling

## Configuration

The SignatureVerifier accepts these options:

```javascript
const verifier = new SignatureVerifier({
  storagePath: './signatures',  // Where to store signatures
  keyManager: null              // Optional key manager integration
});
```

## Error Handling

All methods return a consistent response format:

```javascript
{
  success: true|false,
  error?: 'Error message if failed',
  // ... method-specific fields
}
```

Always check the `success` field before using other fields.

## Performance Considerations

- Batch operations are more efficient than individual calls
- Cache frequently verified signatures
- Use base64 format for API transmission (smaller size)
- Consider using Ed25519 for better performance

## Compliance

This implementation follows:
- RFC 8032 (Ed25519)
- PKCS#1 v2.1 (RSA)
- NIST FIPS 186-4 (ECDSA)
- OWASP Cryptographic Storage Cheat Sheet