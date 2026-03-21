/**
 * @file password-strength-api.js
 * @brief 密码强度分析 API 接口
 * 
 * 提供 HTTP API 和模块接口用于密码强度分析
 */

const passwordStrength = require('./password-strength');

// ==================== API 响应格式 ====================

/**
 * 创建成功响应
 */
function successResponse(data, message = 'success') {
  return {
    success: true,
    message,
    data,
    timestamp: new Date().toISOString()
  };
}

/**
 * 创建错误响应
 */
function errorResponse(message, code = 'INVALID_REQUEST') {
  return {
    success: false,
    message,
    error: {
      code,
      message
    },
    timestamp: new Date().toISOString()
  };
}

// ==================== API 处理函数 ====================

/**
 * 分析密码强度
 * @param {string} password - 待分析的密码
 * @returns {object} API 响应
 */
function analyzePassword(password) {
  try {
    if (!password) {
      return errorResponse('密码不能为空', 'MISSING_PASSWORD');
    }
    
    if (typeof password !== 'string') {
      return errorResponse('密码必须是字符串', 'INVALID_PASSWORD_TYPE');
    }
    
    if (password.length > 1024) {
      return errorResponse('密码长度不能超过 1024 个字符', 'PASSWORD_TOO_LONG');
    }
    
    const result = passwordStrength.analyzePasswordStrength(password);
    
    return successResponse(result, '密码强度分析完成');
    
  } catch (error) {
    return errorResponse(`分析失败：${error.message}`, 'ANALYSIS_ERROR');
  }
}

/**
 * 验证密码是否符合要求
 * @param {string} password - 待验证的密码
 * @param {object} options - 验证选项
 * @returns {object} API 响应
 */
function validatePassword(password, options = {}) {
  try {
    if (!password) {
      return errorResponse('密码不能为空', 'MISSING_PASSWORD');
    }
    
    const result = passwordStrength.validatePassword(password, options);
    
    if (result.valid) {
      return successResponse(result, '密码验证通过');
    } else {
      return successResponse(result, '密码验证未通过');
    }
    
  } catch (error) {
    return errorResponse(`验证失败：${error.message}`, 'VALIDATION_ERROR');
  }
}

/**
 * 生成随机密码
 * @param {object} options - 生成选项
 * @returns {object} API 响应
 */
function generatePassword(options = {}) {
  try {
    const length = options.length || 16;
    
    if (length < 8 || length > 128) {
      return errorResponse('密码长度必须在 8-128 之间', 'INVALID_LENGTH');
    }
    
    const password = passwordStrength.generateRandomPassword(length, options);
    const analysis = passwordStrength.analyzePasswordStrength(password);
    
    return successResponse({
      password,
      analysis,
      options
    }, '密码生成成功');
    
  } catch (error) {
    return errorResponse(`生成失败：${error.message}`, 'GENERATION_ERROR');
  }
}

/**
 * 获取常见密码列表 (用于前端验证)
 * @returns {object} API 响应
 */
function getCommonPasswords() {
  return successResponse({
    count: passwordStrength.COMMON_PASSWORDS.size,
    note: '出于安全考虑，仅返回数量，不返回具体密码列表'
  });
}

/**
 * 获取评分标准
 * @returns {object} API 响应
 */
function getScoringCriteria() {
  return successResponse({
    scoring: passwordStrength.SCORING,
    levels: {
      excellent: { range: '90-100', text: '极强', color: '#22c55e' },
      strong: { range: '75-89', text: '强', color: '#84cc16' },
      good: { range: '60-74', text: '中等', color: '#eab308' },
      weak: { range: '40-59', text: '弱', color: '#f97316' },
      very_weak: { range: '0-39', text: '极弱', color: '#ef4444' }
    }
  });
}

/**
 * 批量分析密码 (用于密码本安全审计)
 * @param {string[]} passwords - 密码数组
 * @returns {object} API 响应
 */
function batchAnalyze(passwords) {
  try {
    if (!Array.isArray(passwords)) {
      return errorResponse('密码必须是数组', 'INVALID_INPUT');
    }
    
    if (passwords.length > 100) {
      return errorResponse('批量分析最多支持 100 个密码', 'TOO_MANY_PASSWORDS');
    }
    
    const results = passwords.map((password, index) => {
      try {
        const analysis = passwordStrength.analyzePasswordStrength(password);
        return {
          index,
          success: true,
          analysis
        };
      } catch (error) {
        return {
          index,
          success: false,
          error: error.message
        };
      }
    });
    
    const summary = {
      total: passwords.length,
      success: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length,
      averageScore: results
        .filter(r => r.success)
        .reduce((sum, r) => sum + r.analysis.score, 0) / results.filter(r => r.success).length || 0,
      distribution: {
        excellent: results.filter(r => r.success && r.analysis.score >= 90).length,
        strong: results.filter(r => r.success && r.analysis.score >= 75 && r.analysis.score < 90).length,
        good: results.filter(r => r.success && r.analysis.score >= 60 && r.analysis.score < 75).length,
        weak: results.filter(r => r.success && r.analysis.score >= 40 && r.analysis.score < 60).length,
        very_weak: results.filter(r => r.success && r.analysis.score < 40).length
      }
    };
    
    return successResponse({
      results,
      summary
    }, '批量分析完成');
    
  } catch (error) {
    return errorResponse(`批量分析失败：${error.message}`, 'BATCH_ANALYSIS_ERROR');
  }
}

// ==================== HTTP 服务器集成 ====================

/**
 * 创建 HTTP 请求处理器
 * @returns {function} HTTP 请求处理函数
 */
function createHttpHandler() {
  return (req, res) => {
    // 仅接受 POST 请求
    if (req.method !== 'POST') {
      res.writeHead(405, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(errorResponse('Method not allowed', 'METHOD_NOT_ALLOWED')));
      return;
    }
    
    // 设置 CORS
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    // 处理 OPTIONS 预检请求
    if (req.method === 'OPTIONS') {
      res.writeHead(204);
      res.end();
      return;
    }
    
    // 解析请求体
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      try {
        const { action, password, passwords, options } = JSON.parse(body);
        
        let response;
        
        switch (action) {
          case 'analyze':
            response = analyzePassword(password);
            break;
            
          case 'validate':
            response = validatePassword(password, options);
            break;
            
          case 'generate':
            response = generatePassword(options);
            break;
            
          case 'batch-analyze':
            response = batchAnalyze(passwords);
            break;
            
          case 'get-scoring':
            response = getScoringCriteria();
            break;
            
          case 'get-common-count':
            response = getCommonPasswords();
            break;
            
          default:
            response = errorResponse(`未知的操作：${action}`, 'UNKNOWN_ACTION');
        }
        
        res.writeHead(response.success ? 200 : 400);
        res.end(JSON.stringify(response));
        
      } catch (error) {
        const response = errorResponse(`请求解析失败：${error.message}`, 'PARSE_ERROR');
        res.writeHead(400);
        res.end(JSON.stringify(response));
      }
    });
  };
}

// ==================== 导出 ====================

module.exports = {
  // API 处理函数
  analyzePassword,
  validatePassword,
  generatePassword,
  batchAnalyze,
  getScoringCriteria,
  getCommonPasswords,
  
  // HTTP 集成
  createHttpHandler,
  
  // 响应工具
  successResponse,
  errorResponse
};
