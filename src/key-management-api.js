/**
 * PolyVault Key Management API
 * RESTful API for key management operations
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const path = require('path');
const KeyManager = require('./key-management-system');

class KeyManagementAPI {
  constructor(options = {}) {
    this.options = {
      port: options.port || 8081,
      keyManagerOptions: options.keyManagerOptions || {},
      ...options
    };
    
    this.keyManager = new KeyManager(this.options.keyManagerOptions);
    this.app = express();
    
    // Middleware
    this.app.use(helmet());
    this.app.use(cors());
    this.app.use(express.json({ limit: '10mb' }));
    this.app.use(express.urlencoded({ extended: true }));
    
    // Rate limiting
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // Limit each IP to 100 requests per windowMs
      message: 'Too many requests from this IP'
    });
    this.app.use('/api/', limiter);
    
    // Authentication middleware
    this.app.use('/api/', this._authenticate.bind(this));
    
    // Initialize key manager
    this._initializeKeyManager();
    
    // Setup routes
    this._setupRoutes();
  }
  
  /**
   * Initialize the key manager
   */
  async _initializeKeyManager() {
    try {
      const result = await this.keyManager.initialize();
      if (!result.success) {
        console.error('Failed to initialize KeyManager:', result.error);
      } else {
        console.log('KeyManager initialized successfully');
      }
    } catch (error) {
      console.error('Error initializing KeyManager:', error.message);
    }
  }
  
  /**
   * Authentication middleware
   */
  _authenticate(req, res, next) {
    // Extract token from header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN
    
    if (!token) {
      // For demo purposes, we'll allow without token
      // In production, require proper authentication
      console.log('Request without auth token - allowing for demo');
      return next();
    }
    
    // Validate token (would check against stored tokens in real implementation)
    // For demo purposes, accept any token that's reasonably long
    if (token.length >= 16) {
      return next();
    } else {
      return res.status(401).json({ error: 'Invalid authentication token' });
    }
  }
  
  /**
   * Setup API routes
   */
  _setupRoutes() {
    // Health check endpoint
    this.app.get('/api/health', async (req, res) => {
      try {
        // Check if key manager is operational
        const allKeys = this.keyManager.getAllKeys(true);
        res.json({
          status: 'healthy',
          timestamp: new Date().toISOString(),
          keyCount: allKeys.count,
          service: 'PolyVault Key Management API'
        });
      } catch (error) {
        res.status(500).json({ 
          status: 'unhealthy',
          error: error.message 
        });
      }
    });
    
    // Generate a new key
    this.app.post('/api/keys/generate', async (req, res) => {
      try {
        const {
          algorithm = 'ed25519',
          purpose = 'general',
          label = '',
          exportable = false,
          strength = 2048
        } = req.body;
        
        const result = await this.keyManager.generateKey({
          algorithm,
          purpose,
          label,
          exportable,
          strength
        });
        
        if (result.success) {
          res.status(201).json(result);
        } else {
          res.status(400).json(result);
        }
      } catch (error) {
        res.status(500).json({ 
          success: false, 
          error: error.message 
        });
      }
    });
    
    // Get a key by ID
    this.app.get('/api/keys/:keyId', async (req, res) => {
      try {
        const { keyId } = req.params;
        const result = await this.keyManager.getKey(keyId);
        
        if (result.success) {
          // Don't expose private key material in the response
          const safeResponse = {
            ...result,
            key: {
              ...result.key,
              privateKey: result.key.privateKey ? '[REDACTED]' : null
            }
          };
          res.json(safeResponse);
        } else {
          res.status(404).json(result);
        }
      } catch (error) {
        res.status(500).json({ 
          success: false, 
          error: error.message 
        });
      }
    });
    
    // Get all keys
    this.app.get('/api/keys', async (req, res) => {
      try {
        const { basicInfoOnly = 'true' } = req.query;
        const result = this.keyManager.getAllKeys(basicInfoOnly === 'true');
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ 
          success: false, 
          error: error.message 
        });
      }
    });
    
    // Get key statistics
    this.app.get('/api/keys/:keyId/stats', async (req, res) => {
      try {
        const { keyId } = req.params;
        const result = this.keyManager.getKeyStats(keyId);
        
        if (result.success) {
          res.json(result);
        } else {
          res.status(404).json(result);
        }
      } catch (error) {
        res.status(500).json({ 
          success: false, 
          error: error.message 
        });
      }
    });
    
    // Use a key for cryptographic operation
    this.app.post('/api/keys/:keyId/use', async (req, res) => {
      try {
        const { keyId } = req.params;
        const { operation, data } = req.body;
        
        const result = await this.keyManager.useKey(keyId, operation, data);
        
        if (result.success) {
          res.json(result);
        } else {
          res.status(400).json(result);
        }
      } catch (error) {
        res.status(500).json({ 
          success: false, 
          error: error.message 
        });
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
          console.log(`PolyVault Key Management API server running on port ${this.options.port}`);
          console.log(`API endpoints available at: http://localhost:${this.options.port}/api`);
          resolve(server);
        });
      } catch (error) {
        reject(error);
      }
    });
  }
  
  /**
   * Stop the API server and cleanup
   */
  async stop(server) {
    if (server) {
      return new Promise((resolve, reject) => {
        server.close(async (err) => {
          if (err) {
            reject(err);
          } else {
            console.log('Key Management API server stopped');
            
            // Cleanup key manager resources
            try {
              await this.keyManager.cleanup();
            } catch (cleanupErr) {
              console.error('Error during cleanup:', cleanupErr);
            }
            
            resolve();
          }
        });
      });
    }
  }
}

// Export the KeyManagementAPI class
module.exports = KeyManagementAPI;

// Example usage when run directly
if (require.main === module) {
  const api = new KeyManagementAPI({
    port: 8081,
    keyManagerOptions: {
      storagePath: path.join(__dirname, '..', 'test-keys-api')
    }
  });
  
  console.log('Starting PolyVault Key Management API server...');
  
  api.start()
    .then(server => {
      console.log('Key Management API server started successfully');
      
      // Handle graceful shutdown
      process.on('SIGINT', async () => {
        console.log('\nShutting down Key Management API server...');
        await api.stop(server);
        process.exit(0);
      });
    })
    .catch(error => {
      console.error('Failed to start Key Management API server:', error);
      process.exit(1);
    });
}