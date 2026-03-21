/**
 * @file password-strength.js
 * @brief 密码强度分析器 - 帮助用户创建更安全的密码
 * 
 * 功能:
 * - 密码强度评分 (0-100)
 * - 字符多样性分析
 * - 常见密码检测
 * - 模式检测 (连续字符、重复字符、键盘模式)
 * - 熵值计算
 * - 安全建议生成
 */

// ==================== 常量定义 ====================

const COMMON_PASSWORDS = new Set([
  '123456', '12345678', '123456789', '1234567890',
  'password', 'PASSWORD', 'Password', 'passwd', 'pass',
  'qwerty', 'QWERTY', 'abc123', '111111', '000000',
  'letmein', 'welcome', 'admin', 'admin123', 'root',
  'monkey', 'dragon', 'master', 'login', 'princess',
  'sunshine', 'shadow', 'iloveyou', '123123', '666666',
  '888888', '654321', 'superman', 'batman', 'trustno1',
  '1qaz2wsx', '1q2w3e4r', '1234qwer', 'qwer1234',
  '00000000', '11111111', '12341234', 'password1',
  'Password1', 'password123', 'Password123', 'P@ssw0rd',
  'p@ssword', 'p@ssw0rd', 'passw0rd', 'Passw0rd'
]);

const KEYBOARD_PATTERNS = [
  'qwerty', 'qwertyuiop', 'asdfgh', 'asdfghjkl', 'zxcvbn', 'zxcvbnm',
  '1234567890', '0987654321', '!@#$%^&*()',
  'qazwsx', 'wsxedc', 'edcrfv', 'rfvtgb', 'tgbyhn', 'yhnujm',
  '1qaz', '2wsx', '3edc', '4rfv', '5tgb', '6yhn', '7ujm', '8ik,',
  'qweasd', 'asdzxc', 'zxcpoi', 'poilkj', 'lkjhgf', 'mnbvcx'
];

const SEQUENTIAL_PATTERNS = [
  'abc', 'bcd', 'cde', 'def', 'efg', 'fgh', 'ghi', 'hij', 'ijk', 'jkl',
  'klm', 'lmn', 'mno', 'nop', 'opq', 'pqr', 'qrs', 'rst', 'stu', 'tuv',
  'uvw', 'vwx', 'wxy', 'xyz',
  '012', '123', '234', '345', '456', '567', '678', '789', '890',
  '321', '432', '543', '654', '765', '876', '987', '098'
];

const REPEATED_PATTERNS = [
  /(.)\1{2,}/,  // 同一字符重复 3 次以上
  /(.)(.)\1\2/,  // 两个字符交替重复
  /(.+)\1{2,}/   // 模式重复
];

// ==================== 密码强度评分标准 ====================

const SCORING = {
  minLength: 8,           // 最小长度要求
  idealLength: 16,        // 理想长度
  lengthWeight: 25,       // 长度权重
  varietyWeight: 30,      // 字符多样性权重
  entropyWeight: 25,      // 熵值权重
  patternWeight: 20,      // 模式检测权重
  
  // 字符类型权重
  lowercaseWeight: 5,
  uppercaseWeight: 5,
  digitWeight: 5,
  symbolWeight: 10,
  unicodeWeight: 5
};

// ==================== 工具函数 ====================

/**
 * 计算字符串熵值
 * @param {string} str - 输入字符串
 * @returns {number} 熵值 (bits)
 */
function calculateEntropy(str) {
  if (!str) return 0;
  
  const charSet = new Set(str);
  const charsetSize = charSet.size;
  const length = str.length;
  
  // 熵 = log2(charsetSize^length) = length * log2(charsetSize)
  return Math.round(length * Math.log2(charsetSize + 1));
}

/**
 * 检查字符类型
 * @param {string} char - 单个字符
 * @returns {string[]} 字符类型数组
 */
function getCharTypes(char) {
  const types = [];
  
  if (/[a-z]/.test(char)) types.push('lowercase');
  if (/[A-Z]/.test(char)) types.push('uppercase');
  if (/[0-9]/.test(char)) types.push('digit');
  if (/[^a-zA-Z0-9]/.test(char)) types.push('symbol');
  if (/[\u4e00-\u9fff]/.test(char)) types.push('unicode'); // 中文字符
  
  return types;
}

/**
 * 分析字符多样性
 * @param {string} password - 密码
 * @returns {object} 多样性分析结果
 */
function analyzeVariety(password) {
  const charTypes = new Set();
  const typeCounts = {
    lowercase: 0,
    uppercase: 0,
    digit: 0,
    symbol: 0,
    unicode: 0
  };
  
  for (const char of password) {
    const types = getCharTypes(char);
    types.forEach(type => {
      charTypes.add(type);
      typeCounts[type]++;
    });
  }
  
  return {
    uniqueTypes: charTypes.size,
    types: Array.from(charTypes),
    counts: typeCounts,
    varietyScore: Math.min(charTypes.size * 6, 30) // 最多 30 分
  };
}

/**
 * 检测常见密码
 * @param {string} password - 密码
 * @returns {boolean} 是否为常见密码
 */
function isCommonPassword(password) {
  const lower = password.toLowerCase();
  return COMMON_PASSWORDS.has(lower) || COMMON_PASSWORDS.has(password);
}

/**
 * 检测键盘模式
 * @param {string} password - 密码
 * @returns {string[]} 检测到的键盘模式
 */
function detectKeyboardPatterns(password) {
  const lower = password.toLowerCase();
  const found = [];
  
  for (const pattern of KEYBOARD_PATTERNS) {
    if (lower.includes(pattern)) {
      found.push(pattern);
    }
  }
  
  return found;
}

/**
 * 检测连续模式
 * @param {string} password - 密码
 * @returns {string[]} 检测到的连续模式
 */
function detectSequentialPatterns(password) {
  const lower = password.toLowerCase();
  const found = [];
  
  for (const pattern of SEQUENTIAL_PATTERNS) {
    if (lower.includes(pattern)) {
      found.push(pattern);
    }
  }
  
  return found;
}

/**
 * 检测重复模式
 * @param {string} password - 密码
 * @returns {object[]} 检测到的重复模式
 */
function detectRepeatedPatterns(password) {
  const found = [];
  
  for (const regex of REPEATED_PATTERNS) {
    const matches = password.match(regex);
    if (matches) {
      found.push({
        pattern: matches[0],
        type: 'repeated'
      });
    }
  }
  
  return found;
}

/**
 * 检测模式
 * @param {string} password - 密码
 * @returns {object} 模式检测结果
 */
function detectPatterns(password) {
  const keyboard = detectKeyboardPatterns(password);
  const sequential = detectSequentialPatterns(password);
  const repeated = detectRepeatedPatterns(password);
  
  const totalPatterns = keyboard.length + sequential.length + repeated.length;
  const patternScore = Math.max(0, 20 - (totalPatterns * 5)); // 每个模式扣 5 分
  
  return {
    keyboard: keyboard,
    sequential: sequential,
    repeated: repeated,
    totalPatterns,
    patternScore
  };
}

// ==================== 主函数 ====================

/**
 * 分析密码强度
 * @param {string} password - 待分析的密码
 * @returns {object} 完整的密码强度分析报告
 */
function analyzePasswordStrength(password) {
  if (!password || typeof password !== 'string') {
    return {
      score: 0,
      level: 'invalid',
      error: '密码不能为空',
      details: null
    };
  }
  
  const length = password.length;
  
  // 1. 长度评分 (0-25 分)
  let lengthScore = 0;
  if (length >= SCORING.idealLength) {
    lengthScore = SCORING.lengthWeight;
  } else if (length >= SCORING.minLength) {
    lengthScore = Math.round((length - SCORING.minLength + 1) / (SCORING.idealLength - SCORING.minLength + 1) * SCORING.lengthWeight);
  } else {
    lengthScore = Math.round(length / SCORING.minLength * SCORING.lengthWeight * 0.5);
  }
  
  // 2. 字符多样性分析 (0-30 分)
  const variety = analyzeVariety(password);
  
  // 3. 熵值计算 (0-25 分)
  const entropy = calculateEntropy(password);
  let entropyScore = Math.min(entropy / 4, 25); // 100 bits 熵值得满分
  
  // 4. 模式检测 (0-20 分)
  const patterns = detectPatterns(password);
  
  // 5. 常见密码检查 (直接扣 50 分)
  const isCommon = isCommonPassword(password);
  const commonPenalty = isCommon ? 50 : 0;
  
  // 计算总分
  let totalScore = lengthScore + variety.varietyScore + entropyScore + patterns.patternScore - commonPenalty;
  totalScore = Math.max(0, Math.min(100, totalScore)); // 限制在 0-100
  
  // 确定强度等级
  let level, levelColor, levelText;
  if (totalScore >= 90) {
    level = 'excellent';
    levelColor = '#22c55e';
    levelText = '极强';
  } else if (totalScore >= 75) {
    level = 'strong';
    levelColor = '#84cc16';
    levelText = '强';
  } else if (totalScore >= 60) {
    level = 'good';
    levelColor = '#eab308';
    levelText = '中等';
  } else if (totalScore >= 40) {
    level = 'weak';
    levelColor = '#f97316';
    levelText = '弱';
  } else {
    level = 'very_weak';
    levelColor = '#ef4444';
    levelText = '极弱';
  }
  
  // 生成建议
  const suggestions = generateSuggestions(password, length, variety, patterns, isCommon);
  
  return {
    score: totalScore,
    level,
    levelColor,
    levelText,
    details: {
      length: {
        value: length,
        score: lengthScore,
        maxScore: SCORING.lengthWeight,
        minRequired: SCORING.minLength,
        ideal: SCORING.idealLength
      },
      variety: {
        score: variety.varietyScore,
        maxScore: 30,
        uniqueTypes: variety.uniqueTypes,
        types: variety.types,
        counts: variety.counts
      },
      entropy: {
        value: entropy,
        score: Math.round(entropyScore),
        maxScore: 25
      },
      patterns: {
        score: patterns.patternScore,
        maxScore: 20,
        totalPatterns: patterns.totalPatterns,
        keyboard: patterns.keyboard,
        sequential: patterns.sequential,
        repeated: patterns.repeated
      },
      isCommon,
      commonPenalty
    },
    suggestions
  };
}

/**
 * 生成密码改进建议
 * @param {string} password - 密码
 * @param {number} length - 密码长度
 * @param {object} variety - 多样性分析结果
 * @param {object} patterns - 模式检测结果
 * @param {boolean} isCommon - 是否为常见密码
 * @returns {string[]} 建议数组
 */
function generateSuggestions(password, length, variety, patterns, isCommon) {
  const suggestions = [];
  
  // 长度建议
  if (length < SCORING.minLength) {
    suggestions.push(`密码长度至少需要 ${SCORING.minLength} 个字符，当前只有 ${length} 个`);
  } else if (length < SCORING.idealLength) {
    suggestions.push(`建议将密码长度增加到 ${SCORING.idealLength} 个字符以提高安全性`);
  }
  
  // 字符类型建议
  if (!variety.types.includes('lowercase')) {
    suggestions.push('添加小写字母 (a-z)');
  }
  if (!variety.types.includes('uppercase')) {
    suggestions.push('添加大写字母 (A-Z)');
  }
  if (!variety.types.includes('digit')) {
    suggestions.push('添加数字 (0-9)');
  }
  if (!variety.types.includes('symbol')) {
    suggestions.push('添加特殊符号 (!@#$%^&*等)');
  }
  
  // 常见密码警告
  if (isCommon) {
    suggestions.push('⚠️ 这是一个非常常见的密码，请立即更换！');
  }
  
  // 模式警告
  if (patterns.keyboard.length > 0) {
    suggestions.push(`避免使用键盘模式 (如：${patterns.keyboard.join(', ')})`);
  }
  if (patterns.sequential.length > 0) {
    suggestions.push(`避免使用连续字符 (如：${patterns.sequential.join(', ')})`);
  }
  if (patterns.repeated.length > 0) {
    suggestions.push(`避免重复字符 (如：${patterns.repeated.map(p => p.pattern).join(', ')})`);
  }
  
  // 熵值建议
  const entropy = calculateEntropy(password);
  if (entropy < 50) {
    suggestions.push('密码熵值较低，建议使用更随机的字符组合');
  }
  
  return suggestions;
}

/**
 * 验证密码是否符合要求
 * @param {string} password - 密码
 * @param {object} options - 验证选项
 * @returns {object} 验证结果
 */
function validatePassword(password, options = {}) {
  const {
    minLength = SCORING.minLength,
    requireUppercase = true,
    requireLowercase = true,
    requireDigit = true,
    requireSymbol = false,
    maxRepeats = 3
  } = options;
  
  const errors = [];
  
  // 长度检查
  if (password.length < minLength) {
    errors.push(`密码长度不能少于 ${minLength} 个字符`);
  }
  
  // 字符类型检查
  if (requireUppercase && !/[A-Z]/.test(password)) {
    errors.push('密码必须包含大写字母');
  }
  if (requireLowercase && !/[a-z]/.test(password)) {
    errors.push('密码必须包含小写字母');
  }
  if (requireDigit && !/[0-9]/.test(password)) {
    errors.push('密码必须包含数字');
  }
  if (requireSymbol && !/[^a-zA-Z0-9]/.test(password)) {
    errors.push('密码必须包含特殊符号');
  }
  
  // 重复字符检查
  const repeatRegex = new RegExp(`(.)\\1{${maxRepeats},}`);
  if (repeatRegex.test(password)) {
    errors.push(`密码包含过多重复字符`);
  }
  
  // 常见密码检查
  if (isCommonPassword(password)) {
    errors.push('不能使用常见密码');
  }
  
  return {
    valid: errors.length === 0,
    errors
  };
}

/**
 * 生成随机密码
 * @param {number} length - 密码长度
 * @param {object} options - 生成选项
 * @returns {string} 生成的随机密码
 */
function generateRandomPassword(length = 16, options = {}) {
  const {
    includeLowercase = true,
    includeUppercase = true,
    includeDigit = true,
    includeSymbol = true,
    excludeAmbiguous = false // 排除易混淆字符 (0, O, l, 1, I)
  } = options;
  
  let charSet = '';
  
  if (includeLowercase) {
    charSet += excludeAmbiguous ? 'abcdefghjkmnpqrstuvwxyz' : 'abcdefghijklmnopqrstuvwxyz';
  }
  if (includeUppercase) {
    charSet += excludeAmbiguous ? 'ABCDEFGHJKMNPQRSTUVWXYZ' : 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  }
  if (includeDigit) {
    charSet += excludeAmbiguous ? '23456789' : '0123456789';
  }
  if (includeSymbol) {
    charSet += excludeAmbiguous ? '!@#$%^&*?' : '!@#$%^&*()_+-=[]{}|;:,.<>?';
  }
  
  if (charSet.length === 0) {
    throw new Error('至少需要包含一种字符类型');
  }
  
  // 使用密码学安全的随机数生成器
  const crypto = require('crypto');
  const randomBytes = crypto.randomBytes(length);
  
  let password = '';
  for (let i = 0; i < length; i++) {
    password += charSet[randomBytes[i] % charSet.length];
  }
  
  return password;
}

// ==================== 导出 ====================

module.exports = {
  analyzePasswordStrength,
  validatePassword,
  generateRandomPassword,
  calculateEntropy,
  analyzeVariety,
  detectPatterns,
  isCommonPassword,
  SCORING,
  COMMON_PASSWORDS
};
