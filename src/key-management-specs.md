# PolyVault Key Management System - Specification

## Overview

The PolyVault Key Management System provides secure generation, storage, and usage of cryptographic keys for the PolyVault project. It implements industry best practices for cryptographic key lifecycle management and integrates with hardware security modules for enhanced protection.

## Architecture

### Components

1. **Key Generator** (`key-management-system.js`)
   - Creates cryptographically secure keys using Node.js crypto module
   - Supports multiple key algorithms: RSA, ECDSA, Ed25519, X25519
   - Configurable key strength and purpose

2. **Key Storage** 
   - Filesystem-based storage with metadata
   - AES-256-GCM encryption for private keys (P0 Security Fix)
   - PBKDF2 key derivation with 100,000 iterations

3. **Key Manager** (`key-management-system.js`)
   - Orchestrates key operations
   - Enforces security policies
   - Tracks usage statistics

4. **REST API** (`key-management-api.js`)
   - HTTP endpoints for key operations
   - Rate limiting and authentication
   - Comprehensive error handling

## Security Features

### AES-256-GCM Encryption (P0 Security Issue Fixed)
- **Algorithm**: AES-256-GCM (Galois/Counter Mode)
- **Key Derivation**: PBKDF2 with SHA-256, 100,000 iterations
- **IV**: 96-bit (12 bytes) random IV for each encryption
- **Authentication**: GMAC authentication tag for data integrity

### Key Protection
- Private keys are encrypted at rest
- Support for hardware security module integration (zk_vault)
- Secure key deletion procedures
- Audit logging of all key operations

### Access Control
- Role-based access control (RBAC)
- API key authentication
- Operation validation based on key purpose

## Key Lifecycle

### Generation
```
Supported Algorithms:
- RSA: 2048, 3072, 4096 bit
- ECDSA: secp256r1 (prime256v1), secp384r1
- Ed25519: EdDSA with Curve25519
- X25519: ECDH with Curve25519
```

### Storage
- Keys stored in JSON format with metadata
- Private keys encrypted using AES-256-GCM
- Metadata includes: algorithm, purpose, label, creation time, usage count

### Usage
- Sign: Create digital signatures
- Verify: Verify digital signatures
- Encrypt: Encrypt data (hybrid encryption for non-RSA)
- Decrypt: Decrypt data

### Rotation & Retirement
- Configurable automatic rotation
- Key status tracking (active, deprecated, revoked)
- Secure key destruction

## API Endpoints

### POST /api/keys/generate
Generate a new cryptographic key.

**Request Body:**
```json
{
  "algorithm": "ed25519",
  "purpose": "signing",
  "label": "my-signing-key",
  "exportable": true,
  "strength": 2048
}
```

**Response:**
```json
{
  "success": true,
  "keyId": "key_1234567890_abc123",
  "publicKey": "-----BEGIN PUBLIC KEY-----\n...",
  "metadata": {
    "id": "key_1234567890_abc123",
    "algorithm": "ed25519",
    "purpose": "signing",
    "status": "active"
  }
}
```

### GET /api/keys/:keyId
Retrieve key information.

**Response:**
```json
{
  "success": true,
  "key": {
    "publicKey": "-----BEGIN PUBLIC KEY-----\n...",
    "metadata": { ... }
  }
}
```

### GET /api/keys
List all keys.

**Query Parameters:**
- `basicInfoOnly`: Return only basic info (default: true)

### POST /api/keys/:keyId/use
Use a key for cryptographic operation.

**Request Body:**
```json
{
  "operation": "sign",
  "data": { "message": "Hello, PolyVault!" }
}
```

### GET /api/keys/:keyId/stats
Get key usage statistics.

## Configuration

The system is configured via `key-management-config.json`:

```json
{
  "keyManagement": {
    "storage": {
      "path": "./keys",
      "encryption": {
        "enabled": true,
        "algorithm": "AES-256-GCM",
        "keyDerivation": {
          "method": "PBKDF2",
          "iterations": 100000,
          "hash": "SHA-256"
        }
      }
    },
    "keyPolicies": {
      "rotation": {
        "enabled": true,
        "interval": "30d"
      }
    }
  }
}
```

## Usage Example

```javascript
const KeyManager = require('./key-management-system');

const keyManager = new KeyManager({
  storagePath: './keys'
});

// Initialize
await keyManager.initialize();

// Generate a key
const result = await keyManager.generateKey({
  algorithm: 'ed25519',
  purpose: 'signing',
  label: 'my-key',
  exportable: true
});

// Use the key to sign data
const signResult = await keyManager.useKey(result.keyId, 'sign', {
  message: 'Hello, World!'
});

// Get statistics
const stats = keyManager.getKeyStats(result.keyId);

// Cleanup
await keyManager.cleanup();
```

## Testing

Run the test suite:

```bash
npx mocha key-management-tests.js
```

### Test Categories
- Key generation tests (RSA, ECDSA, Ed25519)
- Key storage and retrieval tests
- AES-256-GCM encryption tests
- Key usage and operation tests
- Statistics and information tests
- Security and validation tests

## Compliance

This implementation follows:
- NIST SP 800-57 (Cryptographic Key Management)
- OWASP Key Management Guidelines
- Industry best practices for secure key storage

## Security Considerations

1. **Master Key**: In production, the master encryption key should be stored in a hardware security module (HSM)
2. **Key Rotation**: Implement regular key rotation policies
3. **Audit Logging**: Enable comprehensive audit logging
4. **Access Control**: Configure RBAC properly
5. **Transport Security**: Use TLS for all API communications
6. **Key Backup**: Secure backup and recovery procedures