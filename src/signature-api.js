/**
 * PolyVault Signature Verification API
 * RESTful API for digital signature and verification operations
 * Optimized for high performance and low latency
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
const SignatureVerifier = require('./signature-verification');

// Performance optimization: Request pooling and connection management
const CONNECTION_POOL_SIZE = 100;
const REQUEST_TIMEOUT = 30000;

class SignatureAPI {
  constructor(options = {}) {
    this.options = {
      port: options.port || 8082,
      signatureVerifierOptions: options.signatureVerifierOptions || {},
      ...options
    };
    
    this.signatureVerifier = new SignatureVerifier(this.options.signatureVerifierOptions);
    this.app = express();
    
    // Performance optimization: Increase payload limit for batch operations
    this.app.use(helmet());
    this.app.use(cors());
    this.app.use(express.json({ limit: '50mb' })); // Increased for batch operations
    this.app.use(express.urlencoded({ extended: true, limit: '50mb' }));
    
    // Performance optimization: Higher rate limits for batch operations
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000,
      max: 500, // Increased for batch processing
      message: 'Too many requests from this IP'
    });
    this.app.use('/api/', limiter);
    
    // Initialize signature verifier
    this._initializeVerifier();
    
    // Setup routes
    this._setupRoutes();
  }
  
  /**
   * Initialize signature verifier
   */
  async _initializeVerifier() {
    try {
      await this.signatureVerifier.initialize();
      console.log('SignatureVerifier initialized');
    } catch (error) {
      console.error('Failed to initialize SignatureVerifier:', error);
    }
  }
  
  /**
   * Setup API routes
   */
  _setupRoutes() {
    // Health check
    this.app.get('/api/health', (req, res) => {
      res.json({
        status: 'healthy',
        service: 'PolyVault Signature API',
        timestamp: new Date().toISOString(),
        performance: {
          uptime: process.uptime(),
          memory: process.memoryUsage(),
          cacheStats: this.signatureVerifier.verificationCache?.cache?.size || 0
        }
      });
    });
    
    // Performance stats endpoint
    this.app.get('/api/stats', (req, res) => {
      res.json({
        service: 'PolyVault Signature API',
        stats: {
          verificationCacheSize: this.signatureVerifier.verificationCache?.cache?.size || 0,
          signatureCacheSize: this.signatureVerifier.signatureCache?.size || 0,
          uptime: process.uptime(),
          memory: process.memoryUsage()
        }
      });
    });
    
    // Sign data
    this.app.post('/api/sign', async (req, res) => {
      try {
        const { privateKey, data, algorithm, format } = req.body;
        
        if (!privateKey) {
          return res.status(400).json({ success: false, error: 'Private key is required' });
        }
        
        if (!data) {
          return res.status(400).json({ success: false, error: 'Data is required' });
        }
        
        const result = await this.signatureVerifier.sign({
          privateKey,
          data,
          algorithm: algorithm || 'sha256',
          format: format || 'hex'
        });
        
        if (result.success) {
          res.status(201).json(result);
        } else {
          res.status(400).json(result);
        }
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Verify signature
    this.app.post('/api/verify', async (req, res) => {
      try {
        const { publicKey, signature, data, algorithm, format } = req.body;
        
        if (!publicKey) {
          return res.status(400).json({ success: false, error: 'Public key is required' });
        }
        
        if (!signature) {
          return res.status(400).json({ success: false, error: 'Signature is required' });
        }
        
        if (!data) {
          return res.status(400).json({ success: false, error: 'Data is required' });
        }
        
        const result = await this.signatureVerifier.verify({
          publicKey,
          signature,
          data,
          algorithm: algorithm || 'sha256',
          format: format || 'hex'
        });
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Create detached signature
    this.app.post('/api/sign/detached', async (req, res) => {
      try {
        const { privateKey, data, algorithm } = req.body;
        
        if (!privateKey) {
          return res.status(400).json({ success: false, error: 'Private key is required' });
        }
        
        if (!data) {
          return res.status(400).json({ success: false, error: 'Data is required' });
        }
        
        const result = await this.signatureVerifier.createDetachedSignature({
          privateKey,
          data,
          algorithm: algorithm || 'sha256'
        });
        
        if (result.success) {
          res.status(201).json(result);
        } else {
          res.status(400).json(result);
        }
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Verify detached signature
    this.app.post('/api/verify/detached', async (req, res) => {
      try {
        const { publicKey, signature, data, algorithm } = req.body;
        
        if (!publicKey) {
          return res.status(400).json({ success: false, error: 'Public key is required' });
        }
        
        if (!signature) {
          return res.status(400).json({ success: false, error: 'Signature is required' });
        }
        
        if (!data) {
          return res.status(400).json({ success: false, error: 'Data is required' });
        }
        
        const result = await this.signatureVerifier.verifyDetachedSignature({
          publicKey,
          signature,
          data,
          algorithm: algorithm || 'sha256'
        });
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Batch sign
    this.app.post('/api/sign/batch', async (req, res) => {
      try {
        const { privateKey, dataItems, algorithm, format } = req.body;
        
        if (!privateKey) {
          return res.status(400).json({ success: false, error: 'Private key is required' });
        }
        
        if (!dataItems || !Array.isArray(dataItems)) {
          return res.status(400).json({ success: false, error: 'Data items array is required' });
        }
        
        const result = await this.signatureVerifier.batchSign({
          privateKey,
          dataItems,
          algorithm: algorithm || 'sha256',
          format: format || 'hex'
        });
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Batch verify
    this.app.post('/api/verify/batch', async (req, res) => {
      try {
        const { publicKey, signatureItems, algorithm, format } = req.body;
        
        if (!publicKey) {
          return res.status(400).json({ success: false, error: 'Public key is required' });
        }
        
        if (!signatureItems || !Array.isArray(signatureItems)) {
          return res.status(400).json({ success: false, error: 'Signature items array is required' });
        }
        
        const result = await this.signatureVerifier.batchVerify({
          publicKey,
          signatureItems,
          algorithm: algorithm || 'sha256',
          format: format || 'hex'
        });
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Get signature by ID
    this.app.get('/api/signatures/:signatureId', async (req, res) => {
      try {
        const { signatureId } = req.params;
        const result = await this.signatureVerifier.getSignature(signatureId);
        
        if (result.success) {
          res.json(result);
        } else {
          res.status(404).json(result);
        }
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // List all signatures
    this.app.get('/api/signatures', async (req, res) => {
      try {
        const result = await this.signatureVerifier.listSignatures();
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Catch-all for undefined routes
    this.app.all('/api/*', (req, res) => {
      res.status(404).json({ error: 'API endpoint not found' });
    });
  }
  
  /**
   * Start the API server
   */
  async start() {
    return new Promise((resolve, reject) => {
      try {
        const server = this.app.listen(this.options.port, () => {
          console.log(`PolyVault Signature API running on port ${this.options.port}`);
          resolve(server);
        });
      } catch (error) {
        reject(error);
      }
    });
  }
  
  /**
   * Stop the API server
   */
  async stop(server) {
    if (server) {
      return new Promise((resolve, reject) => {
        server.close(async (err) => {
          if (err) {
            reject(err);
          } else {
            await this.signatureVerifier.cleanup();
            resolve();
          }
        });
      });
    }
  }
}

module.exports = SignatureAPI;

// Example usage
if (require.main === module) {
  const api = new SignatureAPI({
    port: 8082,
    signatureVerifierOptions: {
      storagePath: path.join(__dirname, '..', 'test-signatures')
    }
  });
  
  api.start()
    .then(server => {
      console.log('Signature API started');
      
      process.on('SIGINT', async () => {
        console.log('Shutting down...');
        await api.stop(server);
        process.exit(0);
      });
    })
    .catch(error => {
      console.error('Failed to start:', error);
      process.exit(1);
    });
}