/**
 * PolyVault Security Monitoring Module
 * Real-time security monitoring and alerting
 */

const EventEmitter = require('events');
const SecurityAuditLogger = require('./security-audit');

class SecurityMonitor extends EventEmitter {
  constructor(options = {}) {
    super();
    
    this.auditLogger = options.auditLogger || new SecurityAuditLogger({
      logPath: options.logPath
    });
    
    // Alert thresholds
    this.thresholds = {
      failedAuthAttempts: options.failedAuthThreshold || 5,
      keyAccessDenied: options.keyAccessThreshold || 3,
      signatureVerificationFailed: options.signatureThreshold || 10,
      rateLimitExceeded: options.rateLimitThreshold || 100
    };
    
    // Track events for rate limiting
    this.eventCounts = new Map();
    this.rateLimitWindow = options.rateLimitWindow || 60000; // 1 minute
    
    // Initialize
    this._initialize();
  }

  /**
   * Initialize the security monitor
   */
  async _initialize() {
    await this.auditLogger.initialize();
    
    // Set up periodic cleanup of event counts
    setInterval(() => {
      this._cleanupEventCounts();
    }, this.rateLimitWindow);
  }

  /**
   * Monitor key generation
   */
  async monitorKeyGeneration(keyId, algorithm, purpose, userId) {
    await this.auditLogger.logKeyGeneration(keyId, algorithm, purpose, userId);
    
    this.emit('key:generated', { keyId, algorithm, purpose, userId });
    
    return { success: true };
  }

  /**
   * Monitor key access
   */
  async monitorKeyAccess(keyId, operation, userId, success) {
    await this.auditLogger.logKeyAccess(keyId, operation, userId, success);
    
    // Check for repeated failures
    if (!success) {
      const failKey = `key_access_fail:${keyId}`;
      const count = this._incrementEventCount(failKey);
      
      if (count >= this.thresholds.keyAccessDenied) {
        await this._triggerAlert('KEY_ACCESS_THRESHOLD', {
          keyId,
          operation,
          userId,
          count,
          message: `Multiple failed key access attempts detected for key ${keyId}`
        });
        
        // Reset count after alert
        this.eventCounts.delete(failKey);
      }
    }
    
    this.emit('key:accessed', { keyId, operation, userId, success });
    
    return { success: true };
  }

  /**
   * Monitor signature operations
   */
  async monitorSignatureOperation(keyId, operation, result, userId) {
    if (operation === 'create') {
      await this.auditLogger.logSignatureCreation(keyId, result.signatureId, userId);
      this.emit('signature:created', { keyId, signatureId: result.signatureId, userId });
    } else if (operation === 'verify') {
      await this.auditLogger.logSignatureVerification(keyId, result, userId);
      
      // Check for repeated verification failures
      if (!result) {
        const failKey = `sig_verify_fail:${keyId}`;
        const count = this._incrementEventCount(failKey);
        
        if (count >= this.thresholds.signatureVerificationFailed) {
          await this._triggerAlert('SIGNATURE_THRESHOLD', {
            keyId,
            count,
            message: `Multiple signature verification failures detected for key ${keyId}`
          });
          
          this.eventCounts.delete(failKey);
        }
      }
      
      this.emit('signature:verified', { keyId, result, userId });
    }
    
    return { success: true };
  }

  /**
   * Monitor authentication attempts
   */
  async monitorAuthentication(userId, method, success, details = {}) {
    await this.auditLogger.logAuthentication(userId, method, success, details);
    
    // Check for repeated authentication failures
    if (!success) {
      const failKey = `auth_fail:${userId}`;
      const count = this._incrementEventCount(failKey);
      
      if (count >= this.thresholds.failedAuthAttempts) {
        await this._triggerAlert('AUTH_THRESHOLD', {
          userId,
          method,
          count,
          message: `Multiple authentication failures for user ${userId}`
        });
        
        // Reset count after alert
        this.eventCounts.delete(failKey);
      }
    }
    
    this.emit('auth:attempt', { userId, method, success });
    
    return { success: true };
  }

  /**
   * Monitor authorization checks
   */
  async monitorAuthorization(userId, resource, permission, success) {
    await this.auditLogger.logAuthorization(userId, resource, permission, success);
    
    if (!success) {
      // Log as security violation
      await this.auditLogger.logSecurityViolation('UNAUTHORIZED_ACCESS', {
        userId,
        resource,
        permission
      });
      
      await this._triggerAlert('UNAUTHORIZED_ACCESS', {
        userId,
        resource,
        permission,
        message: `Unauthorized access attempt to ${resource}`
      });
    }
    
    this.emit('authz:check', { userId, resource, permission, success });
    
    return { success: true };
  }

  /**
   * Monitor rate limiting
   */
  async monitorRateLimit(userId, endpoint, count) {
    if (count > this.thresholds.rateLimitExceeded) {
      await this._triggerAlert('RATE_LIMIT', {
        userId,
        endpoint,
        count,
        message: `Rate limit exceeded for user ${userId} on ${endpoint}`
      });
      
      await this.auditLogger.logSecurityViolation('RATE_LIMIT_EXCEEDED', {
        userId,
        endpoint,
        count
      });
    }
    
    return { success: true };
  }

  /**
   * Get security statistics
   */
  async getSecurityStats(days = 7) {
    return await this.auditLogger.getStats(days);
  }

  /**
   * Query audit logs
   */
  async queryLogs(params) {
    return await this.auditLogger.queryLogs(params);
  }

  /**
   * Increment event count
   */
  _incrementEventCount(key) {
    const current = this.eventCounts.get(key) || 0;
    const newCount = current + 1;
    this.eventCounts.set(key, newCount);
    return newCount;
  }

  /**
   * Clean up old event counts
   */
  _cleanupEventCounts() {
    const now = Date.now();
    for (const [key, timestamp] of this.eventCounts) {
      if (now - timestamp > this.rateLimitWindow * 2) {
        this.eventCounts.delete(key);
      }
    }
  }

  /**
   * Trigger security alert
   */
  async _triggerAlert(alertType, details) {
    const alert = {
      alertType,
      timestamp: new Date().toISOString(),
      severity: 'CRITICAL',
      ...details
    };
    
    // Emit alert event
    this.emit('alert', alert);
    
    // Also log as critical security event
    await this.auditLogger.logSecurityViolation(alertType, details);
    
    return alert;
  }

  /**
   * Update thresholds
   */
  updateThresholds(newThresholds) {
    this.thresholds = {
      ...this.thresholds,
      ...newThresholds
    };
    
    return { success: true, thresholds: this.thresholds };
  }

  /**
   * Cleanup resources
   */
  async cleanup() {
    await this.auditLogger.cleanup();
    this.eventCounts.clear();
    return { success: true };
  }
}

module.exports = SecurityMonitor;

// Example usage
if (require.main === module) {
  const monitor = new SecurityMonitor({
    failedAuthAttempts: 3,
    keyAccessThreshold: 2
  });
  
  // Listen for alerts
  monitor.on('alert', (alert) => {
    console.log('🚨 SECURITY ALERT:', alert);
  });
  
  // Test monitoring
  (async () => {
    // Test authentication monitoring
    await monitor.monitorAuthentication('user_001', 'api_key', false);
    await monitor.monitorAuthentication('user_001', 'api_key', false);
    await monitor.monitorAuthentication('user_001', 'api_key', false); // Should trigger alert
    
    // Test key access monitoring
    await monitor.monitorKeyAccess('key_001', 'read', 'user_001', false);
    await monitor.monitorKeyAccess('key_001', 'read', 'user_001', false); // Should trigger alert
    
    // Get stats
    const stats = await monitor.getSecurityStats(1);
    console.log('Security Stats:', JSON.stringify(stats, null, 2));
    
    await monitor.cleanup();
  })();
}