# PolyVault API Documentation

## Overview

PolyVault is a secure credential management and digital signature system with eCAL-based inter-process communication, Protobuf serialization, and hardware security module integration.

## Table of Contents

1. [Key Management API](#key-management-api)
2. [Signature API](#signature-api)
3. [eCAL Communication API](#ecal-communication-api)
4. [Protobuf Serialization API](#protobuf-serialization-api)

---

## Key Management API

### Configuration

```javascript
const keyManagementConfig = {
  // Master key for encryption (required, min 32 bytes)
  masterKey: process.env.POLYVAULT_MASTER_KEY,
  
  // Key storage directory
  storagePath: './keys',
  
  // Encryption settings
  encryption: {
    algorithm: 'AES-256-GCM',
    keyDerivation: {
      algorithm: 'PBKDF2',
      iterations: 100000,
      saltLength: 32
    }
  },
  
  // Cache settings
  cache: {
    enabled: true,
    ttl: 300000, // 5 minutes
    maxSize: 100
  },
  
  // Rate limiting
  rateLimit: {
    maxRequests: 1000,
    windowMs: 60000
  }
};
```

### Initialize Key Management

```javascript
const { KeyManagement } = require('./key-management-system');

const keyManagement = new KeyManagement(keyManagementConfig);
await keyManagement.initialize();
```

### Generate Key

```javascript
// Generate a new key
const keyResult = await keyManagement.generateKey({
  algorithm: 'Ed25519',  // 'RSA-2048', 'RSA-4096', 'ECDSA-P256', 'ECDSA-P384', 'Ed25519', 'X25519'
  keyId: 'my-signing-key',
  purpose: 'signing',     // 'signing', 'encryption', 'keyExchange', 'authentication'
  metadata: {
    name: 'My Signing Key',
    description: 'Key for signing documents',
    expiresAt: '2027-01-01T00:00:00Z'
  }
});

// Response
{
  keyId: 'my-signing-key',
  algorithm: 'Ed25519',
  publicKey: 'base64-encoded-public-key',
  createdAt: '2026-03-20T12:00:00Z',
  status: 'active'
}
```

### Store Key

```javascript
// Store an existing key
await keyManagement.storeKey({
  keyId: 'imported-key',
  privateKey: 'base64-encoded-private-key',
  publicKey: 'base64-encoded-public-key',
  algorithm: 'RSA-4096',
  purpose: 'encryption',
  metadata: {
    name: 'Imported Key',
    description: 'Key imported from external system'
  }
});
```

### Retrieve Key

```javascript
// Get key information (without private key)
const keyInfo = await keyManagement.getKey('my-signing-key');

// Get key with private key (requires authentication)
const keyWithPrivate = await keyManagement.getKey('my-signing-key', {
  includePrivateKey: true
});
```

### List Keys

```javascript
// List all keys with optional filters
const keys = await keyManagement.listKeys({
  algorithm: 'Ed25519',     // Optional filter
  purpose: 'signing',        // Optional filter
  status: 'active'           // Optional filter: 'active', 'deprecated', 'revoked'
});
```

### Delete Key

```javascript
// Delete a key (soft delete - marks as revoked)
await keyManagement.deleteKey('my-signing-key');

// Hard delete (permanent)
await keyManagement.deleteKey('my-signing-key', { permanent: true });
```

### Key Statistics

```javascript
const stats = await keyManagement.getStats();
// Response
{
  totalKeys: 10,
  byAlgorithm: { Ed25519: 5, 'RSA-4096': 3, 'ECDSA-P256': 2 },
  byPurpose: { signing: 6, encryption: 4 },
  byStatus: { active: 8, deprecated: 1, revoked: 1 }
}
```

---

## Signature API

### Initialize Signature Service

```javascript
const { SignatureVerification } = require('./signature-verification');

const signatureService = new SignatureVerification(keyManagement, {
  cacheEnabled: true,
  cacheMaxSize: 500,
  cacheTTL: 600000  // 10 minutes
});
```

### Sign Data

```javascript
// Sign data with specified key
const signature = await signatureService.sign({
  data: 'Hello, World!',  // String or Buffer
  keyId: 'my-signing-key',
  algorithm: 'Ed25519',   // Optional, uses key's default if not specified
  format: 'base64'        // 'base64' or 'hex'
});

// Response
{
  signature: 'base64-encoded-signature',
  algorithm: 'Ed25519',
  keyId: 'my-signing-key',
  timestamp: 1234567890
}
```

### Verify Signature

```javascript
// Verify a signature
const result = await signatureService.verify({
  data: 'Hello, World!',
  signature: 'base64-encoded-signature',
  publicKey: 'base64-encoded-public-key',
  algorithm: 'Ed25519'
});

// Response
{
  valid: true,
  algorithm: 'Ed25519',
  details: {
    matches: true,
    duration: 5
  }
}
```

### Create Detached Signature

```javascript
// Create signature separate from data (for file signing)
const detachedSig = await signatureService.signDetached({
  filePath: './document.pdf',
  keyId: 'my-signing-key',
  algorithm: 'Ed25519',
  outputPath: './document.pdf.sig'  // Optional: write to file
});

// Response
{
  signature: 'base64-encoded-signature',
  filePath: './document.pdf',
  algorithm: 'Ed25519'
}
```

### Verify Detached Signature

```javascript
// Verify a detached signature
const result = await signatureService.verifyDetached({
  filePath: './document.pdf',
  signature: 'base64-encoded-signature',
  publicKey: 'base64-encoded-public-key',
  algorithm: 'Ed25519'
});
```

### Batch Signing

```javascript
// Sign multiple pieces of data
const batchResult = await signatureService.signBatch({
  items: [
    { data: 'Message 1', keyId: 'key-1' },
    { data: 'Message 2', keyId: 'key-2' },
    { data: 'Message 3', keyId: 'key-1' }
  ]
});

// Response
{
  results: [
    { data: 'Message 1', signature: '...', success: true },
    { data: 'Message 2', signature: '...', success: true },
    { data: 'Message 3', signature: '...', success: true }
  ],
  total: 3,
  successful: 3,
  failed: 0
}
```

### Batch Verification

```javascript
// Verify multiple signatures
const batchResult = await signatureService.verifyBatch({
  items: [
    { data: 'Message 1', signature: 'sig1', publicKey: 'pk1' },
    { data: 'Message 2', signature: 'sig2', publicKey: 'pk2' }
  ],
  parallel: true  // Use parallel verification for better performance
});
```

### Get Signature Statistics

```javascript
const stats = await signatureService.getStats();
// Response
{
  totalSignatures: 1000,
  totalVerifications: 5000,
  cacheHitRate: 0.75,
  averageVerifyTime: 5,
  byAlgorithm: {
    Ed25519: { sign: 400, verify: 2000 },
    'RSA-4096': { sign: 300, verify: 1500 },
    'ECDSA-P256': { sign: 300, verify: 1500 }
  }
}
```

---

## eCAL Communication API

### Initialize Data Bus

```cpp
#include "data_bus.h"

using namespace polyvault::comm;

DataBusConfig config;
config.node_name = "My PolyVault Node";
config.enable_encryption = true;
config.timeout_ms = 5000;
config.max_message_size = 1024 * 1024;

DataBus data_bus(config);
if (!data_bus.initialize()) {
    // Handle error
}
```

### Start Communication

```cpp
if (!data_bus.start()) {
    // Handle error
}

std::string node_id = data_bus.getNodeId();
std::cout << "Node ID: " << node_id << std::endl;
```

### Publish Message

```cpp
SecureMessage msg;
msg.type = MessageType::KEY_EXCHANGE;
msg.sender_id = data_bus.getNodeId();
msg.receiver_id = "other-node-id";
msg.timestamp = std::time(nullptr);
msg.sequence_num = 1;
msg.encrypted_payload = {1, 2, 3, 4, 5};

if (!data_bus.publish("polyvault_topic", msg)) {
    // Handle error
}
```

### Subscribe to Messages

```cpp
auto callback = [](const SecureMessage& msg) {
    std::cout << "Received message type: " << static_cast<int>(msg.type) << std::endl;
    std::cout << "From: " << msg.sender_id << std::endl;
    std::cout << "Sequence: " << msg.sequence_num << std::endl;
};

if (!data_bus.subscribe("polyvault_topic", callback)) {
    // Handle error
}
```

### Send Direct Message

```cpp
SecureMessage msg;
msg.type = MessageType::SIGNATURE_REQUEST;
msg.sender_id = data_bus.getNodeId();
msg.receiver_id = "target-node-id";

// Send to specific node
if (!data_bus.sendTo("target-node-id", msg)) {
    // Handle error
}
```

### Process Callbacks

```cpp
// Call in main loop or dedicated thread
data_bus.processCallbacks();
```

### Unsubscribe

```cpp
data_bus.unsubscribe("polyvault_topic");
```

### Stop Data Bus

```cpp
data_bus.stop();
```

### Message Types

| Type | Description |
|------|-------------|
| `KEY_EXCHANGE` | Key exchange message |
| `SIGNATURE_REQUEST` | Request digital signature |
| `SIGNATURE_RESPONSE` | Signature response |
| `VERIFICATION_REQUEST` | Verify signature request |
| `VERIFICATION_RESPONSE` | Verification response |
| `HEARTBEAT` | Keep-alive heartbeat |
| `CONFIG_SYNC` | Configuration synchronization |
| `KEY_ROTATION` | Key rotation message |

---

## Protobuf Serialization API

### Serialize Message (Binary)

```cpp
#include "protobuf_serializer.h"

using namespace polyvault::serialization;

ProtobufSerializer serializer;

// Serialize to binary
std::vector<uint8_t> data = serializer.serialize(message);
```

### Deserialize Message

```cpp
// Deserialize from binary
MyMessage new_message;
if (serializer.deserialize(data, &new_message)) {
    // Process message
}
```

### Serialize to JSON

```cpp
std::string json = serializer.toJson(message);
std::cout << json << std::endl;
```

### Deserialize from JSON

```cpp
MyMessage parsed;
if (serializer.fromJson(json_string, &parsed)) {
    // Process parsed message
}
```

### Quick Helpers

```cpp
// Quick serialization
auto data = serializeMessage(my_message);

// Quick deserialization
auto msg = deserializeMessage<MyMessage>(data);

// Quick JSON
auto json = serializeToJson(my_message);
auto msg2 = deserializeFromJson<MyMessage>(json);
```

---

## Error Handling

All APIs use consistent error handling:

```javascript
try {
    const result = await keyManagement.generateKey({...});
} catch (error) {
    switch (error.code) {
        case 'KEY_EXISTS':
            // Key already exists
            break;
        case 'INVALID_ALGORITHM':
            // Unsupported algorithm
            break;
        case 'KEY_NOT_FOUND':
            // Key doesn't exist
            break;
        case 'AUTHENTICATION_REQUIRED':
            // Need authentication
            break;
        case 'RATE_LIMIT_EXCEEDED':
            // Too many requests
            break;
        default:
            // Unknown error
    }
}
```

---

## Best Practices

1. **Key Management**
   - UseEd25519 for new projects (faster, more secure)
   - Rotate keys periodically
   - Store master key securely (environment variable)
   - Enable caching for better performance

2. **Signatures**
   - Use detached signatures for file signing
   - Enable batch operations for multiple items
   - Monitor cache hit rate

3. **eCAL Communication**
   - Always check return values
   - Process callbacks regularly
   - Use encryption in production
   - Handle reconnection gracefully

4. **Security**
   - Never log private keys
   - Use hardware security modules when available
   - Implement key rotation policies
   - Monitor for suspicious activity

---

## Examples

### Complete Workflow Example

```javascript
const { KeyManagement } = require('./key-management-system');
const { SignatureVerification } = require('./signature-verification');

// Initialize
const keyMgmt = new KeyManagement(config);
await keyMgmt.initialize();

const sigSvc = new SignatureVerification(keyMgmt);

// Generate key
await keyMgmt.generateKey({
    algorithm: 'Ed25519',
    keyId: 'doc-signer',
    purpose: 'signing'
});

// Sign document
const signature = await sigSvc.sign({
    data: 'Important document content',
    keyId: 'doc-signer'
});

// Verify
const isValid = await sigSvc.verify({
    data: 'Important document content',
    signature: signature.signature,
    publicKey: '...'
});
```

---

## Support

For issues and questions:
- Documentation: [PolyVault Docs](https://github.com/polyvault/docs)
- Issues: [GitHub Issues](https://github.com/polyvault/issues)
- Email: support@polyvault.io