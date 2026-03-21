/**
 * PolyVault Security Audit Module
 * Implements comprehensive security audit logging and monitoring
 */

const fs = require('fs').promises;
const path = require('path');
const crypto = require('crypto');

class SecurityAuditLogger {
  constructor(options = {}) {
    this.logPath = options.logPath || path.join(__dirname, '..', 'logs', 'security-audit.log');
    this.maxLogSize = options.maxLogSize || 10 * 1024 * 1024; // 10MB
    this.maxLogFiles = options.maxLogFiles || 5;
    this.enableConsole = options.enableConsole !== false;
    
    // Audit event types
    this.EventTypes = {
      KEY_GENERATION: 'KEY_GENERATION',
      KEY_ACCESS: 'KEY_ACCESS',
      KEY_USAGE: 'KEY_USAGE',
      SIGNATURE_CREATE: 'SIGNATURE_CREATE',
      SIGNATURE_VERIFY: 'SIGNATURE_VERIFY',
      AUTHENTICATION: 'AUTHENTICATION',
      AUTHORIZATION: 'AUTHORIZATION',
      DATA_ACCESS: 'DATA_ACCESS',
      CONFIG_CHANGE: 'CONFIG_CHANGE',
      SECURITY_VIOLATION: 'SECURITY_VIOLATION',
      SYSTEM_ERROR: 'SYSTEM_ERROR'
    };
    
    // Severity levels
    this.Severity = {
      DEBUG: 'DEBUG',
      INFO: 'INFO',
      WARNING: 'WARNING',
      ERROR: 'ERROR',
      CRITICAL: 'CRITICAL'
    };
  }

  /**
   * Initialize the security audit logger
   */
  async initialize() {
    try {
      // Ensure log directory exists
      const logDir = path.dirname(this.logPath);
      await fs.mkdir(logDir, { recursive: true });
      
      // Check and rotate logs if needed
      await this._checkLogRotation();
      
      console.log('SecurityAuditLogger initialized successfully');
      return { success: true };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Log a security audit event
   */
  async log(eventType, severity, details) {
    try {
      const event = {
        timestamp: new Date().toISOString(),
        eventId: this._generateEventId(),
        eventType,
        severity,
        details,
        source: 'PolyVault',
        version: '1.0.0'
      };
      
      const logEntry = JSON.stringify(event) + '\n';
      
      // Write to file
      await fs.appendFile(this.logPath, logEntry, 'utf8');
      
      // Output to console if enabled
      if (this.enableConsole) {
        console.log(`[SECURITY-AUDIT] ${event.timestamp} [${severity}] ${eventType}:`, details);
      }
      
      // Check log rotation
      await this._checkLogRotation();
      
      return { success: true, eventId: event.eventId };
    } catch (error) {
      console.error('Failed to write security audit log:', error.message);
      return { success: false, error: error.message };
    }
  }

  /**
   * Log key generation event
   */
  async logKeyGeneration(keyId, algorithm, purpose, userId = 'system') {
    return await this.log(
      this.EventTypes.KEY_GENERATION,
      this.Severity.INFO,
      {
        keyId,
        algorithm,
        purpose,
        userId,
        action: 'KEY_CREATED'
      }
    );
  }

  /**
   * Log key access event
   */
  async logKeyAccess(keyId, operation, userId = 'system', success = true) {
    return await this.log(
      this.EventTypes.KEY_ACCESS,
      success ? this.Severity.INFO : this.Severity.WARNING,
      {
        keyId,
        operation,
        userId,
        success,
        action: 'KEY_ACCESSED'
      }
    );
  }

  /**
   * Log key usage event
   */
  async logKeyUsage(keyId, operation, userId = 'system') {
    return await this.log(
      this.EventTypes.KEY_USAGE,
      this.Severity.INFO,
      {
        keyId,
        operation,
        userId,
        action: 'KEY_USED'
      }
    );
  }

  /**
   * Log signature creation event
   */
  async logSignatureCreation(keyId, signatureId, userId = 'system') {
    return await this.log(
      this.EventTypes.SIGNATURE_CREATE,
      this.Severity.INFO,
      {
        keyId,
        signatureId,
        userId,
        action: 'SIGNATURE_CREATED'
      }
    );
  }

  /**
   * Log signature verification event
   */
  async logSignatureVerification(keyId, result, userId = 'system') {
    return await this.log(
      this.EventTypes.SIGNATURE_VERIFY,
      result ? this.Severity.INFO : this.Severity.WARNING,
      {
        keyId,
        result: result ? 'VALID' : 'INVALID',
        userId,
        action: 'SIGNATURE_VERIFIED'
      }
    );
  }

  /**
   * Log authentication event
   */
  async logAuthentication(userId, method, success = true, details = {}) {
    return await this.log(
      this.EventTypes.AUTHENTICATION,
      success ? this.Severity.INFO : this.Severity.WARNING,
      {
        userId,
        method,
        success,
        ...details,
        action: 'AUTH_ATTEMPT'
      }
    );
  }

  /**
   * Log authorization event
   */
  async logAuthorization(userId, resource, permission, success = true) {
    return await this.log(
      this.EventTypes.AUTHORIZATION,
      success ? this.Severity.INFO : this.Severity.WARNING,
      {
        userId,
        resource,
        permission,
        success,
        action: 'AUTHZ_CHECK'
      }
    );
  }

  /**
   * Log security violation
   */
  async logSecurityViolation(violationType, details) {
    return await this.log(
      this.EventTypes.SECURITY_VIOLATION,
      this.Severity.CRITICAL,
      {
        violationType,
        ...details,
        action: 'VIOLATION_DETECTED'
      }
    );
  }

  /**
   * Query audit logs
   */
  async queryLogs(params = {}) {
    try {
      const {
        startTime,
        endTime,
        eventType,
        severity,
        limit = 100
      } = params;
      
      const content = await fs.readFile(this.logPath, 'utf8');
      const lines = content.split('\n').filter(line => line.trim());
      
      let events = lines.map(line => {
        try {
          return JSON.parse(line);
        } catch {
          return null;
        }
      }).filter(event => event !== null);
      
      // Filter by time range
      if (startTime) {
        events = events.filter(e => new Date(e.timestamp) >= new Date(startTime));
      }
      if (endTime) {
        events = events.filter(e => new Date(e.timestamp) <= new Date(endTime));
      }
      
      // Filter by event type
      if (eventType) {
        events = events.filter(e => e.eventType === eventType);
      }
      
      // Filter by severity
      if (severity) {
        events = events.filter(e => e.severity === severity);
      }
      
      // Sort by timestamp descending
      events.sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
      
      // Limit results
      events = events.slice(0, limit);
      
      return {
        success: true,
        count: events.length,
        events
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Get security statistics
   */
  async getStats(days = 7) {
    try {
      const startTime = new Date();
      startTime.setDate(startTime.getDate() - days);
      
      const result = await this.queryLogs({
        startTime: startTime.toISOString(),
        limit: 10000
      });
      
      if (!result.success) {
        return result;
      }
      
      // Calculate statistics
      const stats = {
        totalEvents: result.count,
        bySeverity: {},
        byEventType: {},
        failedAuthAttempts: 0,
        securityViolations: 0,
        keyOperations: 0,
        signatureOperations: 0
      };
      
      for (const event of result.events) {
        // Count by severity
        stats.bySeverity[event.severity] = (stats.bySeverity[event.severity] || 0) + 1;
        
        // Count by event type
        stats.byEventType[event.eventType] = (stats.byEventType[event.eventType] || 0) + 1;
        
        // Count specific events
        if (event.eventType === this.EventTypes.AUTHENTICATION && !event.details.success) {
          stats.failedAuthAttempts++;
        }
        if (event.eventType === this.EventTypes.SECURITY_VIOLATION) {
          stats.securityViolations++;
        }
        if (event.eventType.startsWith('KEY_')) {
          stats.keyOperations++;
        }
        if (event.eventType.startsWith('SIGNATURE_')) {
          stats.signatureOperations++;
        }
      }
      
      return {
        success: true,
        stats,
        period: `${days} days`
      };
    } catch (error) {
      return { success: false, error: error.message };
    }
  }

  /**
   * Check and rotate logs if needed
   */
  async _checkLogRotation() {
    try {
      const stats = await fs.stat(this.logPath);
      
      if (stats.size > this.maxLogSize) {
        // Rotate logs
        for (let i = this.maxLogFiles - 1; i >= 1; i--) {
          const oldPath = `${this.logPath}.${i}`;
          const newPath = `${this.logPath}.${i + 1}`;
          
          try {
            await fs.rename(oldPath, newPath);
          } catch (e) {
            // File doesn't exist, continue
          }
        }
        
        // Move current log to .1
        await fs.rename(this.logPath, `${this.logPath}.1`);
        
        // Create new log file
        await fs.writeFile(this.logPath, '', 'utf8');
      }
    } catch (error) {
      // Log file doesn't exist, which is fine
    }
  }

  /**
   * Generate unique event ID
   */
  _generateEventId() {
    return `evt_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
  }

  /**
   * Cleanup resources
   */
  async cleanup() {
    console.log('SecurityAuditLogger cleaned up');
    return { success: true };
  }
}

module.exports = SecurityAuditLogger;

// Example usage
if (require.main === module) {
  (async () => {
    const logger = new SecurityAuditLogger({
      logPath: './test-logs/security-audit.log',
      enableConsole: true
    });
    
    await logger.initialize();
    
    // Test logging
    await logger.logKeyGeneration('key_123', 'ed25519', 'signing', 'user_001');
    await logger.logKeyAccess('key_123', 'read', 'user_001', true);
    await logger.logSignatureVerification('key_123', true, 'user_001');
    await logger.logAuthentication('user_001', 'api_key', true);
    await logger.logSecurityViolation('UNAUTHORIZED_ACCESS', { 
      userId: 'unknown', 
      resource: '/api/keys' 
    });
    
    // Get stats
    const stats = await logger.getStats(1);
    console.log('Security Stats:', stats);
    
    await logger.cleanup();
  })();
}