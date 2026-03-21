# PolyVault 密码强度分析模块

**版本**: 1.0.0  
**创建时间**: 2026-03-21  
**作者**: test-agent-2

---

## 📋 概述

密码强度分析模块为 PolyVault 提供全面的密码质量评估功能，帮助用户创建更安全的密码。

### 核心功能

- ✅ 密码强度评分 (0-100)
- ✅ 字符多样性分析
- ✅ 常见密码检测
- ✅ 模式检测 (键盘模式、连续字符、重复字符)
- ✅ 熵值计算
- ✅ 安全建议生成
- ✅ 随机密码生成
- ✅ 批量密码分析

---

## 🔧 安装与使用

### 模块导入

```javascript
const passwordStrength = require('./password-strength');
const passwordApi = require('./password-strength-api');
```

### 基本用法

#### 1. 分析密码强度

```javascript
const result = passwordStrength.analyzePasswordStrength('MyStr0ng!Pass');

console.log(result);
// {
//   score: 85,
//   level: 'strong',
//   levelText: '强',
//   levelColor: '#84cc16',
//   details: { ... },
//   suggestions: [...]
// }
```

#### 2. 验证密码

```javascript
const result = passwordStrength.validatePassword('MyStr0ng!Pass', {
  minLength: 8,
  requireUppercase: true,
  requireLowercase: true,
  requireDigit: true,
  requireSymbol: false
});

console.log(result.valid); // true
console.log(result.errors); // []
```

#### 3. 生成随机密码

```javascript
const password = passwordStrength.generateRandomPassword(16, {
  includeLowercase: true,
  includeUppercase: true,
  includeDigit: true,
  includeSymbol: true,
  excludeAmbiguous: false
});

console.log(password); // "X7#mK9$pL2@nQ4!"
```

#### 4. 使用 API

```javascript
// 分析密码
const response = passwordApi.analyzePassword('Test123!@#');

// 验证密码
const response = passwordApi.validatePassword('Str0ng!Pass');

// 生成密码
const response = passwordApi.generatePassword({ length: 16 });

// 批量分析
const response = passwordApi.batchAnalyze(['weak', 'Str0ng!Pass', 'X9#mK2$pL7@']);
```

---

## 📊 评分标准

### 评分组成 (总分 100)

| 维度 | 权重 | 说明 |
|------|------|------|
| 长度 | 25 分 | 8-16 个字符 |
| 字符多样性 | 30 分 | 大小写、数字、符号 |
| 熵值 | 25 分 | 随机性度量 |
| 模式检测 | 20 分 | 无键盘/连续/重复模式 |
| 常见密码 | -50 分 | 惩罚项 |

### 强度等级

| 分数范围 | 等级 | 颜色 | 说明 |
|----------|------|------|------|
| 90-100 | excellent | 🟢 #22c55e | 极强 |
| 75-89 | strong | 🟡 #84cc16 | 强 |
| 60-74 | good | 🟠 #eab308 | 中等 |
| 40-59 | weak | 🟠 #f97316 | 弱 |
| 0-39 | very_weak | 🔴 #ef4444 | 极弱 |

---

## 🔍 检测功能

### 常见密码检测

内置超过 100 个常见密码，包括:
- 数字序列：`123456`, `123456789`
- 常见单词：`password`, `qwerty`, `admin`
- 组合密码：`password123`, `Admin123`

### 键盘模式检测

检测键盘上的连续按键模式:
- `qwerty`, `asdfgh`, `zxcvbn`
- `1234567890`, `0987654321`
- `qazwsx`, `1qaz2wsx`

### 连续字符检测

检测字母和数字的连续序列:
- `abc`, `bcd`, `xyz`
- `123`, `234`, `890`

### 重复字符检测

检测重复的字符模式:
- `aaa`, `111111`
- `abab`, `121212`

---

## 📈 熵值计算

熵值用于衡量密码的随机性:

```
熵 = length × log2(charset_size)
```

| 熵值 | 安全性 |
|------|--------|
| < 40 | 低 |
| 40-60 | 中 |
| 60-80 | 高 |
| > 80 | 极高 |

---

## 🛡️ 安全建议

模块会根据分析结果生成个性化建议:

```javascript
{
  suggestions: [
    '密码长度至少需要 8 个字符，当前只有 6 个',
    '添加大写字母 (A-Z)',
    '添加特殊符号 (!@#$%^&*等)',
    '⚠️ 这是一个非常常见的密码，请立即更换！',
    '避免使用键盘模式 (如：qwerty)',
    '避免使用连续字符 (如：123, abc)'
  ]
}
```

---

## 🧪 测试

运行测试:

```bash
cd I:\PolyVault
node src/password-strength-tests.js
```

测试覆盖:
- ✅ 基础功能测试 (5 个)
- ✅ 字符多样性测试 (5 个)
- ✅ 常见密码检测 (5 个)
- ✅ 模式检测 (7 个)
- ✅ 熵值计算 (4 个)
- ✅ 密码验证 (6 个)
- ✅ 随机密码生成 (6 个)
- ✅ API 接口测试 (6 个)
- ✅ 边界情况测试 (4 个)
- ✅ 辅助函数测试 (3 个)
- ✅ 性能测试 (2 个)

总计：**53 个测试用例**, 通过率 **100%**

---

## 📁 文件结构

```
I:\PolyVault\src\
├── password-strength.js          # 核心分析模块
├── password-strength-api.js      # API 接口层
├── password-strength-tests.js    # 单元测试
└── PASSWORD_STRENGTH_README.md   # 本文档
```

---

## 🔌 集成示例

### 前端集成

```javascript
// 实时密码强度检查
document.getElementById('password').addEventListener('input', (e) => {
  const result = passwordStrength.analyzePasswordStrength(e.target.value);
  
  const strengthBar = document.getElementById('strength-bar');
  strengthBar.style.width = result.score + '%';
  strengthBar.style.backgroundColor = result.levelColor;
  
  const suggestions = document.getElementById('suggestions');
  suggestions.innerHTML = result.suggestions.map(s => 
    `<li>${s}</li>`
  ).join('');
});
```

### 后端集成

```javascript
// Express.js 中间件
app.post('/api/register', (req, res) => {
  const { password } = req.body;
  
  const validation = passwordStrength.validatePassword(password, {
    minLength: 8,
    requireUppercase: true,
    requireLowercase: true,
    requireDigit: true,
    requireSymbol: true
  });
  
  if (!validation.valid) {
    return res.status(400).json({
      success: false,
      errors: validation.errors
    });
  }
  
  // 继续注册流程...
});
```

---

## 🚀 性能

- 单次分析：< 0.1ms
- 批量分析 (100 个): < 10ms
- 密码生成 (100 个): < 5ms

---

## 📝 更新日志

### v1.0.0 (2026-03-21)

- ✅ 初始版本发布
- ✅ 实现完整的密码强度分析
- ✅ 支持常见密码检测
- ✅ 支持多种模式检测
- ✅ 提供 API 接口
- ✅ 包含完整的单元测试

---

## 📞 支持

如有问题或建议，请联系 PolyVault 开发团队。
