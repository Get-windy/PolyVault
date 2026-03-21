/**
 * @file password-strength-tests.js
 * @brief 密码强度分析模块单元测试
 */

const assert = require('assert');
const passwordStrength = require('./password-strength');
const passwordApi = require('./password-strength-api');

// ==================== 测试工具 ====================

let passed = 0;
let failed = 0;
const failures = [];

function test(name, fn) {
  try {
    fn();
    passed++;
    console.log(`✅ ${name}`);
  } catch (error) {
    failed++;
    failures.push({ name, error: error.message });
    console.log(`❌ ${name}`);
    console.log(`   Error: ${error.message}`);
  }
}

function assertEqual(actual, expected, message = '') {
  if (actual !== expected) {
    throw new Error(`${message} Expected ${expected}, got ${actual}`);
  }
}

function assertTrue(condition, message = '') {
  if (!condition) {
    throw new Error(message || 'Assertion failed');
  }
}

function assertFalse(condition, message = '') {
  if (condition) {
    throw new Error(message || 'Assertion failed: expected false');
  }
}

function assertInRange(value, min, max, message = '') {
  if (value < min || value > max) {
    throw new Error(`${message} Expected ${value} to be between ${min} and ${max}`);
  }
}

// ==================== 测试用例 ====================

console.log('\n🔐 PolyVault 密码强度分析模块测试\n');
console.log('=' .repeat(60));

// ------------------- 基础功能测试 -------------------
console.log('\n📋 基础功能测试\n');

test('空密码处理', () => {
  const result = passwordStrength.analyzePasswordStrength('');
  assertEqual(result.score, 0);
  assertEqual(result.level, 'invalid');
  assertTrue(result.error !== undefined);
});

test('null 密码处理', () => {
  const result = passwordStrength.analyzePasswordStrength(null);
  assertEqual(result.score, 0);
  assertEqual(result.level, 'invalid');
});

test('极短密码评分', () => {
  const result = passwordStrength.analyzePasswordStrength('a');
  assertInRange(result.score, 0, 35);
  assertEqual(result.level, 'very_weak');
});

test('中等长度密码评分', () => {
  const result = passwordStrength.analyzePasswordStrength('Password123');
  assertInRange(result.score, 0, 80);
});

test('长密码评分', () => {
  const result = passwordStrength.analyzePasswordStrength('MyVeryLongAndSecurePassword123!@#');
  assertInRange(result.score, 70, 100);
});

// ------------------- 字符多样性测试 -------------------
console.log('\n🔤 字符多样性测试\n');

test('仅小写字母', () => {
  const result = passwordStrength.analyzePasswordStrength('abcdefgh');
  assertEqual(result.details.variety.uniqueTypes, 1);
  assertTrue(result.details.variety.types.includes('lowercase'));
});

test('仅大写字母', () => {
  const result = passwordStrength.analyzePasswordStrength('ABCDEFGH');
  assertEqual(result.details.variety.uniqueTypes, 1);
  assertTrue(result.details.variety.types.includes('uppercase'));
});

test('仅数字', () => {
  const result = passwordStrength.analyzePasswordStrength('12345678');
  assertEqual(result.details.variety.uniqueTypes, 1);
  assertTrue(result.details.variety.types.includes('digit'));
});

test('仅符号', () => {
  const result = passwordStrength.analyzePasswordStrength('!@#$%^&*');
  assertEqual(result.details.variety.uniqueTypes, 1);
  assertTrue(result.details.variety.types.includes('symbol'));
});

test('混合字符类型', () => {
  const result = passwordStrength.analyzePasswordStrength('Abc123!@#');
  assertEqual(result.details.variety.uniqueTypes, 4);
  assertTrue(result.details.variety.types.includes('lowercase'));
  assertTrue(result.details.variety.types.includes('uppercase'));
  assertTrue(result.details.variety.types.includes('digit'));
  assertTrue(result.details.variety.types.includes('symbol'));
});

// ------------------- 常见密码检测测试 -------------------
console.log('\n⚠️  常见密码检测测试\n');

test('检测常见密码 123456', () => {
  const result = passwordStrength.analyzePasswordStrength('123456');
  assertTrue(result.details.isCommon);
  assertEqual(result.details.commonPenalty, 50);
});

test('检测常见密码 password', () => {
  const result = passwordStrength.analyzePasswordStrength('password');
  assertTrue(result.details.isCommon);
});

test('检测常见密码 qwerty', () => {
  const result = passwordStrength.analyzePasswordStrength('qwerty');
  assertTrue(result.details.isCommon);
});

test('检测常见密码 Admin123', () => {
  const result = passwordStrength.analyzePasswordStrength('admin123');
  assertTrue(result.details.isCommon);
});

test('非常见密码', () => {
  const result = passwordStrength.analyzePasswordStrength('X9#mK2$pL7@nQ4!');
  assertFalse(result.details.isCommon);
  assertEqual(result.details.commonPenalty, 0);
});

// ------------------- 模式检测测试 -------------------
console.log('\n🔍 模式检测测试\n');

test('检测键盘模式 qwerty', () => {
  const result = passwordStrength.analyzePasswordStrength('qwerty123');
  assertEqual(result.details.patterns.keyboard.length, 1);
  assertTrue(result.details.patterns.keyboard.includes('qwerty'));
});

test('检测键盘模式 asdfgh', () => {
  const result = passwordStrength.analyzePasswordStrength('asdfghjk');
  assertTrue(result.details.patterns.keyboard.length > 0);
});

test('检测连续模式 123', () => {
  const result = passwordStrength.analyzePasswordStrength('abc123def');
  assertTrue(result.details.patterns.sequential.length > 0);
});

test('检测连续模式 abc', () => {
  const result = passwordStrength.analyzePasswordStrength('test123abc');
  assertTrue(result.details.patterns.sequential.some(p => p.includes('abc') || p.includes('123')));
});

test('检测重复模式 aaa', () => {
  const result = passwordStrength.analyzePasswordStrength('aaabbbccc');
  assertTrue(result.details.patterns.repeated.length > 0);
});

test('检测重复模式 111', () => {
  const result = passwordStrength.analyzePasswordStrength('111111');
  assertTrue(result.details.patterns.repeated.length > 0);
});

test('无模式密码', () => {
  const result = passwordStrength.analyzePasswordStrength('X7#mK9$pL2@');
  assertEqual(result.details.patterns.totalPatterns, 0);
});

// ------------------- 熵值计算测试 -------------------
console.log('\n📊 熵值计算测试\n');

test('单一字符熵值', () => {
  const entropy = passwordStrength.calculateEntropy('aaaaaaaa');
  assertInRange(entropy, 0, 10);
});

test('重复模式熵值', () => {
  const entropy = passwordStrength.calculateEntropy('abababab');
  assertInRange(entropy, 5, 20);
});

test('高熵值密码', () => {
  const entropy = passwordStrength.calculateEntropy('X7#mK9$pL2@nQ4!');
  assertInRange(entropy, 50, 100);
});

test('熵值随长度增加', () => {
  const entropy1 = passwordStrength.calculateEntropy('Abc123');
  const entropy2 = passwordStrength.calculateEntropy('Abc123Xyz789');
  const entropy3 = passwordStrength.calculateEntropy('Abc123Xyz789!@#$');
  assertTrue(entropy2 > entropy1);
  assertTrue(entropy3 > entropy2);
});

// ------------------- 密码验证测试 -------------------
console.log('\n✅ 密码验证测试\n');

test('验证通过 - 强密码', () => {
  const result = passwordStrength.validatePassword('MyStr0ng!Pass');
  assertTrue(result.valid);
  assertEqual(result.errors.length, 0);
});

test('验证失败 - 太短', () => {
  const result = passwordStrength.validatePassword('Ab1!');
  assertFalse(result.valid);
  assertTrue(result.errors.some(e => e.includes('长度')));
});

test('验证失败 - 缺少大写字母', () => {
  const result = passwordStrength.validatePassword('mystrong1!pass');
  assertFalse(result.valid);
  assertTrue(result.errors.some(e => e.includes('大写')));
});

test('验证失败 - 缺少小写字母', () => {
  const result = passwordStrength.validatePassword('MYSTRONG1!PASS');
  assertFalse(result.valid);
  assertTrue(result.errors.some(e => e.includes('小写')));
});

test('验证失败 - 缺少数字', () => {
  const result = passwordStrength.validatePassword('MyStrong!Password');
  assertFalse(result.valid);
  assertTrue(result.errors.some(e => e.includes('数字')));
});

test('验证失败 - 常见密码', () => {
  const result = passwordStrength.validatePassword('password123');
  assertFalse(result.valid);
  assertTrue(result.errors.some(e => e.includes('常见')));
});

// ------------------- 随机密码生成测试 -------------------
console.log('\n🎲 随机密码生成测试\n');

test('生成默认长度密码', () => {
  const password = passwordStrength.generateRandomPassword();
  assertEqual(password.length, 16);
});

test('生成指定长度密码', () => {
  const password = passwordStrength.generateRandomPassword(24);
  assertEqual(password.length, 24);
});

test('生成密码包含多种字符', () => {
  const password = passwordStrength.generateRandomPassword(16, {
    includeLowercase: true,
    includeUppercase: true,
    includeDigit: true,
    includeSymbol: true
  });
  assertTrue(/[a-z]/.test(password));
  assertTrue(/[A-Z]/.test(password));
  assertTrue(/[0-9]/.test(password));
  assertTrue(/[^a-zA-Z0-9]/.test(password));
});

test('生成密码不含符号', () => {
  const password = passwordStrength.generateRandomPassword(16, {
    includeLowercase: true,
    includeUppercase: true,
    includeDigit: true,
    includeSymbol: false
  });
  assertFalse(/[^a-zA-Z0-9]/.test(password));
});

test('生成密码排除易混淆字符', () => {
  const password = passwordStrength.generateRandomPassword(16, {
    excludeAmbiguous: true
  });
  assertFalse(/[0O1lI]/.test(password));
});

test('生成密码强度', () => {
  const password = passwordStrength.generateRandomPassword(16);
  const analysis = passwordStrength.analyzePasswordStrength(password);
  assertInRange(analysis.score, 70, 100);
});

// ------------------- API 测试 -------------------
console.log('\n🌐 API 接口测试\n');

test('API 分析密码', () => {
  const response = passwordApi.analyzePassword('Test123!@#');
  assertTrue(response.success);
  assertTrue(['weak', 'good', 'strong', 'excellent'].includes(response.data.level));
});

test('API 分析空密码', () => {
  const response = passwordApi.analyzePassword('');
  assertFalse(response.success);
  assertEqual(response.error.code, 'MISSING_PASSWORD');
});

test('API 验证密码', () => {
  const response = passwordApi.validatePassword('Str0ng!Pass');
  assertTrue(response.success);
  assertTrue(response.data.valid);
});

test('API 生成密码', () => {
  const response = passwordApi.generatePassword({ length: 16 });
  assertTrue(response.success);
  assertEqual(response.data.password.length, 16);
  assertTrue(response.data.analysis !== undefined);
});

test('API 获取评分标准', () => {
  const response = passwordApi.getScoringCriteria();
  assertTrue(response.success);
  assertTrue(response.data.scoring !== undefined);
  assertTrue(response.data.levels !== undefined);
});

test('API 批量分析', () => {
  const response = passwordApi.batchAnalyze(['weak', 'Str0ng!Pass', 'X9#mK2$pL7@nQ4!']);
  assertTrue(response.success);
  assertEqual(response.data.summary.total, 3);
  assertEqual(response.data.results.length, 3);
});

// ------------------- 边界情况测试 -------------------
console.log('\n🔬 边界情况测试\n');

test('超长密码', () => {
  const longPassword = 'A'.repeat(200);
  const result = passwordStrength.analyzePasswordStrength(longPassword);
  assertInRange(result.score, 0, 100);
});

test('Unicode 字符密码', () => {
  const result = passwordStrength.analyzePasswordStrength('密码 Test123!');
  assertTrue(result.details.variety.types.includes('unicode') || 
             result.details.variety.uniqueTypes >= 3);
});

test('空格密码', () => {
  const result = passwordStrength.analyzePasswordStrength('Test 123!');
  assertInRange(result.score, 50, 90);
});

test('表情符号密码', () => {
  const result = passwordStrength.analyzePasswordStrength('Test!😀123');
  assertInRange(result.score, 40, 100);
});

// ------------------- 辅助函数测试 -------------------
console.log('\n🔧 辅助函数测试\n');

test('assertFalse 函数存在', () => {
  assertTrue(typeof passwordStrength.analyzeVariety === 'function');
});

test('分析多样性返回正确结构', () => {
  const variety = passwordStrength.analyzeVariety('Abc123!');
  assertTrue(variety.uniqueTypes !== undefined);
  assertTrue(variety.types !== undefined);
  assertTrue(variety.counts !== undefined);
  assertTrue(variety.varietyScore !== undefined);
});

test('检测模式返回正确结构', () => {
  const patterns = passwordStrength.detectPatterns('qwerty123aaa');
  assertTrue(patterns.keyboard !== undefined);
  assertTrue(patterns.sequential !== undefined);
  assertTrue(patterns.repeated !== undefined);
  assertTrue(patterns.totalPatterns !== undefined);
  assertTrue(patterns.patternScore !== undefined);
});

// ------------------- 性能测试 -------------------
console.log('\n⚡ 性能测试\n');

test('分析 100 个密码的性能', () => {
  const startTime = Date.now();
  for (let i = 0; i < 100; i++) {
    passwordStrength.analyzePasswordStrength(`Test${i}!Pass${i}@${i}`);
  }
  const elapsed = Date.now() - startTime;
  assertTrue(elapsed < 1000, `Performance test failed: ${elapsed}ms > 1000ms`);
  console.log(`   (100 次分析耗时：${elapsed}ms)`);
});

test('生成 100 个密码的性能', () => {
  const startTime = Date.now();
  for (let i = 0; i < 100; i++) {
    passwordStrength.generateRandomPassword(16);
  }
  const elapsed = Date.now() - startTime;
  assertTrue(elapsed < 1000, `Performance test failed: ${elapsed}ms > 1000ms`);
  console.log(`   (100 次生成耗时：${elapsed}ms)`);
});

// ==================== 测试总结 ====================
console.log('\n' + '='.repeat(60));
console.log('\n📊 测试总结\n');
console.log(`✅ 通过：${passed}`);
console.log(`❌ 失败：${failed}`);
console.log(`📝 总计：${passed + failed}`);
console.log(`📈 通过率：${((passed / (passed + failed)) * 100).toFixed(1)}%`);

if (failures.length > 0) {
  console.log('\n❌ 失败的测试:\n');
  failures.forEach(({ name, error }) => {
    console.log(`  - ${name}`);
    console.log(`    ${error}\n`);
  });
}

console.log('\n' + '='.repeat(60));

// 导出结果
module.exports = {
  passed,
  failed,
  total: passed + failed,
  failures,
  successRate: (passed / (passed + failed)) * 100
};

// 如果不是被 require 的，则退出时返回错误码
if (require.main === module) {
  process.exit(failed > 0 ? 1 : 0);
}
