/**
 * PolyVault Security Audit API
 * RESTful API for security audit logging and monitoring
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const path = require('path');
const SecurityMonitor = require('./security-monitor');

class SecurityAuditAPI {
  constructor(options = {}) {
    this.options = {
      port: options.port || 8083,
      ...options
    };
    
    this.securityMonitor = new SecurityMonitor(options.securityMonitorOptions);
    this.app = express();
    
    // Middleware
    this.app.use(helmet());
    this.app.use(cors());
    this.app.use(express.json({ limit: '10mb' }));
    
    // Initialize
    this._initialize();
    
    // Setup routes
    this._setupRoutes();
  }
  
  /**
   * Initialize security monitor
   */
  async _initialize() {
    await this.securityMonitor.initialize();
  }
  
  /**
   * Setup API routes
   */
  _setupRoutes() {
    // Health check
    this.app.get('/api/health', (req, res) => {
      res.json({
        status: 'healthy',
        service: 'PolyVault Security Audit API',
        timestamp: new Date().toISOString()
      });
    });
    
    // Get security statistics
    this.app.get('/api/security/stats', async (req, res) => {
      try {
        const { days = 7 } = req.query;
        const result = await this.securityMonitor.getSecurityStats(parseInt(days));
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Query audit logs
    this.app.get('/api/security/logs', async (req, res) => {
      try {
        const {
          startTime,
          endTime,
          eventType,
          severity,
          limit = 100
        } = req.query;
        
        const result = await this.securityMonitor.queryLogs({
          startTime,
          endTime,
          eventType,
          severity,
          limit: parseInt(limit)
        });
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Get security alerts (recent critical events)
    this.app.get('/api/security/alerts', async (req, res) => {
      try {
        const result = await this.securityMonitor.queryLogs({
          severity: 'CRITICAL',
          limit: 50
        });
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Update thresholds
    this.app.post('/api/security/thresholds', async (req, res) => {
      try {
        const { thresholds } = req.body;
        
        if (!thresholds) {
          return res.status(400).json({ 
            success: false, 
            error: 'Thresholds object is required' 
          });
        }
        
        const result = this.securityMonitor.updateThresholds(thresholds);
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Log key generation event
    this.app.post('/api/security/event/key-generation', async (req, res) => {
      try {
        const { keyId, algorithm, purpose, userId } = req.body;
        
        if (!keyId || !algorithm) {
          return res.status(400).json({ 
            success: false, 
            error: 'keyId and algorithm are required' 
          });
        }
        
        const result = await this.securityMonitor.monitorKeyGeneration(
          keyId, 
          algorithm, 
          purpose || 'general', 
          userId || 'system'
        );
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Log key access event
    this.app.post('/api/security/event/key-access', async (req, res) => {
      try {
        const { keyId, operation, userId, success } = req.body;
        
        if (!keyId || !operation) {
          return res.status(400).json({ 
            success: false, 
            error: 'keyId and operation are required' 
          });
        }
        
        const result = await this.securityMonitor.monitorKeyAccess(
          keyId,
          operation,
          userId || 'system',
          success !== false
        );
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Log authentication event
    this.app.post('/api/security/event/authentication', async (req, res) => {
      try {
        const { userId, method, success, details } = req.body;
        
        if (!userId || !method) {
          return res.status(400).json({ 
            success: false, 
            error: 'userId and method are required' 
          });
        }
        
        const result = await this.securityMonitor.monitorAuthentication(
          userId,
          method,
          success !== false,
          details || {}
        );
        
        res.json(result);
      } catch (error) {
        res.status(500).json({ success: false, error: error.message });
      }
    });
    
    // Log signature verification event
    this.app.post('/api/security/event/signature', async (req, res) => {
      try {
        const { keyId, operation, result, userId } = req.body;
        
        if (!keyId || !operation) {
          return res.status(400).json({ 
            success: false, 
            error: 'keyId and operation are required' 
          });
        }
        
        const monitorResult = await this.securityMonitor.monitorSignatureOperation(
          keyId,
          operation,
          result,
          userId || 'system'
        );
        
        res.json(monitorResult);
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
          console.log(`PolyVault Security Audit API running on port ${this.options.port}`);
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
            await this.securityMonitor.cleanup();
            resolve();
          }
        });
      });
    }
  }
}

module.exports = SecurityAuditAPI;

// Example usage
if (require.main === module) {
  const api = new SecurityAuditAPI({
    port: 8083,
    securityMonitorOptions: {
      failedAuthAttempts: 3,
      keyAccessThreshold: 2
    }
  });
  
  api.start()
    .then(server => {
      console.log('Security Audit API started');
      
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