# PolyVault - 贡献指南

感谢你考虑为 PolyVault 项目做出贡献！🎉

## 📖 目录

- [行为准则](#行为准则)
- [如何贡献](#如何贡献)
- [开发流程](#开发流程)
- [代码规范](#代码规范)
- [提交指南](#提交指南)
- [测试要求](#测试要求)
- [文档要求](#文档要求)

---

## 行为准则

### 我们的承诺

- 🤝 **尊重他人**: 保持友好和尊重的交流
- 🔒 **安全第一**: 始终考虑安全性
- 🎯 **聚焦主题**: 讨论围绕项目相关话题
- 📚 **持续学习**: 愿意学习和改进

---

## 如何贡献

### 贡献类型

| 类型 | 说明 |
|------|------|
| 🐛 **Bug 报告** | 发现并报告 Bug |
| 🔧 **Bug 修复** | 修复已知 Bug |
| ✨ **新功能** | 添加新功能 |
| 📖 **文档改进** | 改进文档内容 |
| 🎨 **UI 优化** | 改进用户界面 |
| 🧪 **测试补充** | 增加测试覆盖率 |

---

## 开发流程

### 1. Fork 项目

在 Gitee 页面点击右上角的 **Fork** 按钮。

### 2. 克隆项目

```bash
git clone https://gitee.com/your-username/polyvault.git
cd polyvault
```

### 3. 创建分支

```bash
# 功能分支
git checkout -b feature/device-sync

# Bug 修复分支
git checkout -b fix/auth-issue
```

### 4. 安装依赖

```bash
# Flutter 客户端
cd src/client
flutter pub get

# 本地 Agent（如需要）
cd ../agent
cargo build
```

### 5. 进行修改

按照代码规范进行开发。

### 6. 运行测试

```bash
# Flutter 测试
flutter test

# 代码检查
flutter analyze
```

### 7. 提交更改

```bash
git add .
git commit -m "feat: add device sync feature"
```

### 8. 创建 Pull Request

在 Gitee 上创建 Pull Request。

---

## 代码规范

### Dart/Flutter

遵循 Dart 官方风格指南：

```dart
// 类名：大驼峰
class UserProfile {}

// 变量和函数：小驼峰
String userName = 'John';
void getUserInfo() {}

// 常量：小写 + 下划线
const max_retry_count = 3;

// 私有成员：下划线前缀
int _privateCount = 0;
```

**代码格式**:
```bash
# 格式化代码
flutter format .

# 分析代码
flutter analyze
```

---

## 提交指南

### Commit Message 格式

```
<type>(<scope>): <subject>
```

**示例**:
```bash
feat(client): add device management screen
fix(auth): resolve biometric auth issue
docs(readme): update installation guide
```

### 提交类型

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档更新 |
| `style` | 代码格式 |
| `refactor` | 重构 |
| `test` | 测试相关 |
| `chore` | 构建/工具 |

---

## 测试要求

### 单元测试

**新功能必须包含测试**：

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should calculate correctly', () {
    expect(calculate(2, 3), equals(5));
  });
}
```

### 测试覆盖率

目标覆盖率 > 80%

```bash
# 生成覆盖率报告
flutter test --coverage

# 查看报告
genhtml coverage/lcov.info -o coverage/html
```

---

## 文档要求

### 代码注释

**公共 API 必须有注释**：

```dart
/// 获取设备列表
/// 
/// [page] 页码
/// [limit] 每页数量
/// 
/// 返回设备列表
Future<List<Device>> getDevices({int page = 1, int limit = 20}) async {
  // ...
}
```

### API 文档

新增 API 必须更新 `docs/API_REFERENCE.md`。

---

## 资源链接

- [开发指南](./docs/DEVELOPMENT_GUIDE.md)
- [API 文档](./docs/API_REFERENCE.md)
- [架构文档](./docs/ARCHITECTURE.md)

---

**最后更新**: 2026-03-14  
**维护者**: PolyVault 开发团队  
**许可证**: MIT
