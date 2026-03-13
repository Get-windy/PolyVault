# PolyVault 贡献指南

**版本**: v1.0  
**创建时间**: 2026-03-13  
**适用对象**: 所有贡献者

---

## 📖 目录

1. [欢迎贡献](#欢迎贡献)
2. [Git 工作流](#git-工作流)
3. [代码规范](#代码规范)
4. [提交流程](#提交流程)
5. [代码审查](#代码审查)
6. [测试要求](#测试要求)
7. [文档规范](#文档规范)
8. [社区准则](#社区准则)

---

## 欢迎贡献

### 🎉 感谢你的兴趣！

PolyVault 是一个开源项目，欢迎各种形式的贡献：

- 🐛 **报告 Bug**: 发现并报告问题
- 💡 **功能建议**: 提出新功能想法
- 📝 **文档改进**: 完善文档内容
- 💻 **代码贡献**: 直接提交代码
- 🎨 **设计优化**: 改进 UI/UX
- 🌍 **翻译**: 帮助国际化

### 快速开始

1. **Fork 项目**
   ```bash
   git clone https://github.com/PolyVault/polyvault.git
   cd polyvault
   ```

2. **创建分支**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **开始贡献**
   - 阅读 [Git 工作流](#git-工作流)
   - 遵循 [代码规范](#代码规范)
   - 编写测试

4. **提交 PR**
   - 推送到你的 Fork
   - 创建 Pull Request
   - 等待审查

---

## Git 工作流

### 分支模型

我们采用 **GitHub Flow** 分支模型：

```
main (生产分支)
  │
  ├── feature/login-flow (功能分支)
  ├── feature/credential-sync
  ├── bugfix/ecal-connection-issue
  └── docs/api-update (文档分支)
```

### 分支命名规范

| 类型 | 前缀 | 示例 |
|------|------|------|
| **功能** | `feature/` | `feature/login-flow` |
| **修复** | `bugfix/` | `bugfix/ecal-connection-issue` |
| **文档** | `docs/` | `docs/api-update` |
| **重构** | `refactor/` | `refactor/vault-service` |
| **测试** | `test/` | `test/credential-service` |
| **性能** | `perf/` | `perf/protobuf-serialization` |
| **样式** | `style/` | `style/format-code` |

### 开发流程

#### 1. 从 main 创建分支

```bash
# 确保 main 分支是最新的
git checkout main
git pull origin main

# 创建新分支
git checkout -b feature/your-feature-name
```

#### 2. 进行开发

```bash
# 编写代码
# 编写测试
# 运行测试
```

#### 3. 提交更改

```bash
# 添加文件
git add lib/services/credential_service.dart
git add test/credential_service_test.dart

# 提交（遵循 Commit 规范）
git commit -m "feat: 实现凭证服务核心功能"
```

#### 4. 推送分支

```bash
# 推送到远程
git push origin feature/your-feature-name
```

#### 5. 创建 Pull Request

1. 访问 GitHub 项目页面
2. 点击 "New Pull Request"
3. 选择你的分支
4. 填写 PR 描述
5. 提交 PR

---

## Commit 规范

我们采用 **Conventional Commits** 规范。

### Commit 格式

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type 类型

| 类型 | 说明 | 示例 |
|------|------|------|
| `feat` | 新功能 | `feat: 添加凭证同步功能` |
| `fix` | Bug 修复 | `fix: 修复 eCAL 连接超时问题` |
| `docs` | 文档更新 | `docs: 更新 API 文档` |
| `style` | 代码格式 | `style: 格式化代码` |
| `refactor` | 重构 | `refactor: 重构保险库服务` |
| `perf` | 性能优化 | `perf: 优化 Protobuf 序列化` |
| `test` | 测试相关 | `test: 添加凭证服务测试` |
| `chore` | 构建/工具 | `chore: 更新依赖版本` |

### Scope 范围（可选）

| 范围 | 说明 |
|------|------|
| `ecal` | eCAL 通信层 |
| `vault` | zk_vault 安全层 |
| `flutter` | Flutter 客户端 |
| `proto` | Protobuf 定义 |
| `api` | API 接口 |
| `docs` | 文档 |
| `test` | 测试 |

### Subject 标题

- 使用祈使句："add" 而不是 "added" 或 "adds"
- 首字母小写（除非是专有名词）
- 不超过 50 个字符
- 不使用句号结尾

**示例**:
```
✅ feat: 添加凭证同步功能
❌ feat: 添加了凭证同步功能
❌ feat: 添加凭证同步功能。
```

### Body 正文（可选）

详细描述变更内容、原因和影响。

**示例**:
```
feat(vault): 实现凭证加密存储

- 使用 zk_vault 进行硬件级加密
- 支持生物认证解锁
- 实现 AES-256-GCM 加密算法

Closes #123
```

### Footer 页脚（可选）

关联 Issue 或 BREAKING CHANGE。

**示例**:
```
Closes #123
Fixes #456

BREAKING CHANGE: 加密算法从 AES-128 升级到 AES-256
```

### 完整示例

```bash
feat(vault): 实现凭证加密存储

使用 zk_vault 进行硬件级加密，确保凭证安全。

主要变更:
- 集成 zk_vault 库
- 实现生物认证接口
- 添加 AES-256-GCM 加密

性能提升:
- 加密速度提升 30%
- 内存占用降低 20%

Closes #123
```

---

## 代码规范

### Dart 代码规范

#### 1. 命名规范

```dart
// ✅ 正确：类名使用大驼峰
class CredentialService { }

// ✅ 正确：变量和方法使用小驼峰
String serviceUrl;
Future<void> getCredential() { }

// ✅ 正确：常量使用大写下划线
const int MAX_RETRY_COUNT = 3;

// ✅ 正确：枚举值使用小驼峰
enum GuaranteeStatus { pending, active, expired }

// ✅ 正确：私有成员使用下划线前缀
String _privateKey;
```

#### 2. 代码格式

```dart
// ✅ 正确：使用 2 个空格缩进
class Example {
  void method() {
    if (condition) {
      // do something
    }
  }
}

// ✅ 正确：运算符两侧加空格
int sum = a + b;

// ✅ 正确：控制流语句后加空格
if (condition) { }
for (int i = 0; i < 10; i++) { }

// ✅ 正确：空行分隔逻辑块
void process() {
  // 初始化
  var data = loadData();
  
  // 处理数据
  var result = transform(data);
  
  // 返回结果
  return result;
}
```

#### 3. 注释规范

```dart
/// 文档注释用于类、方法等
/// 
/// 详细描述可以写多行
/// 
/// 示例:
/// ```dart
/// var service = CredentialService();
/// ```
class CredentialService {
  /// 获取凭证
  /// 
  /// [serviceUrl] 是目标服务的 URL
  /// [timeout] 是超时时间（毫秒）
  /// 
  /// 返回加密的凭证数据
  /// 
  /// 可能抛出:
  /// - [VaultException] 如果保险库访问失败
  /// - [TimeoutException] 如果请求超时
  Future<Credential> getCredential(
    String serviceUrl, {
    int timeout = 10000,
  }) async {
    // 实现代码
  }
}
```

#### 4. 错误处理

```dart
// ✅ 正确：使用 try-catch 处理特定异常
try {
  await vault.read(key: 'credential');
} on VaultException catch (e) {
  logger.error('保险库访问失败', error: e);
  rethrow;
} on TimeoutException {
  logger.warning('请求超时');
  throw TimeoutException('凭证请求超时');
} catch (e) {
  logger.error('未知错误', error: e);
  rethrow;
}

// ❌ 错误：捕获所有异常但不处理
try {
  // ...
} catch (e) {
  // 空的 catch 块
}
```

#### 5. 异步编程

```dart
// ✅ 正确：使用 async/await
Future<Credential> getCredential() async {
  final data = await loadData();
  final result = await processData(data);
  return result;
}

// ✅ 正确：使用 Future.wait 并行处理
Future<void> processAll() async {
  final results = await Future.wait([
    task1(),
    task2(),
    task3(),
  ]);
}

// ❌ 错误：嵌套的 .then()
loadData().then((data) {
  processData(data).then((result) {
    // 回调地狱
  });
});
```

---

### C++ 代码规范（eCAL 本地 Agent）

#### 1. 命名规范

```cpp
// ✅ 正确：类名使用大驼峰
class CredentialService;

// ✅ 正确：函数使用小驼峰
void getCredential();

// ✅ 正确：变量使用小写下划线
std::string service_url;

// ✅ 正确：常量使用大写下划线
const int MAX_RETRY_COUNT = 3;

// ✅ 正确：私有成员使用 m_前缀
std::string m_privateKey;
```

#### 2. 头文件保护

```cpp
// ✅ 正确：使用 pragma once
#pragma once

// 或使用头文件保护宏
#ifndef CREDENTIAL_SERVICE_H
#define CREDENTIAL_SERVICE_H

#endif // CREDENTIAL_SERVICE_H
```

#### 3. 智能指针

```cpp
// ✅ 正确：使用智能指针管理内存
std::unique_ptr<CredentialService> service = 
    std::make_unique<CredentialService>();

std::shared_ptr<Config> config = 
    std::make_shared<Config>();

// ❌ 错误：使用裸指针
CredentialService* service = new CredentialService();
delete service;  // 容易忘记释放
```

---

### Protobuf 规范

#### 1. 消息命名

```protobuf
// ✅ 正确：消息名使用大驼峰
message CredentialRequest { }
message CredentialResponse { }

// ✅ 正确：字段使用下划线
message User {
  string user_id = 1;
  string service_url = 2;
}
```

#### 2. 字段编号

```protobuf
// ✅ 正确：从 1 开始，连续编号
message Example {
  string id = 1;
  string name = 2;
  int32 age = 3;
}

// ✅ 正确：预留已删除的字段编号
message Example {
  string id = 1;
  // reserved 2;  // 已删除的字段
  string name = 3;
}
```

#### 3. 注释

```protobuf
// ✅ 正确：为每个字段添加注释
message CredentialRequest {
  // 目标服务 URL，例如 "https://accounts.google.com"
  string service_url = 1;
  
  // 会话标识符（UUID 格式）
  string session_id = 2;
  
  // Unix 时间戳（毫秒）
  uint64 timestamp = 3;
}
```

---

## 提交流程

### 1. 提交前检查清单

- [ ] 代码通过所有测试
- [ ] 代码格式化工具运行通过
- [ ] 添加了必要的注释
- [ ] 更新了相关文档
- [ ] Commit 信息符合规范
- [ ] 没有调试代码或临时注释

### 2. 运行测试

```bash
# Dart/Flutter 测试
flutter test

# C++ 测试
cd tests
cmake .
make test

# 集成测试
flutter test integration_test/
```

### 3. 代码格式化

```bash
# Dart 格式化
dart format lib/

# C++ 格式化（使用 clang-format）
find src -name "*.cpp" -o -name "*.h" | xargs clang-format -i

# Protobuf 格式化
find protos -name "*.proto" | xargs clang-format -i
```

### 4. 静态分析

```bash
# Dart 分析
flutter analyze

# C++ 分析（使用 clang-tidy）
run-clang-tidy src/

# Protobuf 检查
protoc --proto_path=protos protos/*.proto
```

### 5. 提交代码

```bash
# 添加更改
git add .

# 提交（遵循 Commit 规范）
git commit -m "feat: 实现功能描述"

# 推送到远程
git push origin feature/your-branch
```

---

## 代码审查

### 审查流程

```
提交 PR
  │
  ▼
自动检查 (CI/CD)
  │
  ├── 通过 ──► 等待人工审查
  │
  └── 失败 ──► 修复后重新提交
              │
              ▼
          审查者审查
              │
              ├── 批准 ──► 合并到 main
              │
              └── 需要修改 ──► 作者修改
```

### 审查标准

#### 1. 代码质量

- ✅ 代码清晰易读
- ✅ 遵循命名规范
- ✅ 适当的错误处理
- ✅ 没有重复代码

#### 2. 功能正确性

- ✅ 实现需求功能
- ✅ 边界条件处理
- ✅ 性能考虑
- ✅ 安全考虑

#### 3. 测试覆盖

- ✅ 添加单元测试
- ✅ 测试覆盖关键路径
- ✅ 测试通过

#### 4. 文档完整性

- ✅ 更新 API 文档
- ✅ 添加代码注释
- ✅ 更新 README（如需要）

### 审查意见类型

| 类型 | 说明 | 处理 |
|------|------|------|
| `nit` | 小建议，不影响合并 | 可选择性修改 |
| `suggestion` | 改进建议 | 建议修改 |
| `request` | 必须修改 | 必须修改后才能合并 |
| `question` | 疑问 | 需要解释说明 |

### 回复审查意见

```markdown
<!-- ✅ 好的回复 -->
已修复，谢谢建议！

<!-- ✅ 好的回复 -->
这里使用这种方式是因为...（解释原因）

<!-- ❌ 不好的回复 -->
不改（没有解释原因）
```

---

## 测试要求

### 测试层级

```
┌─────────────────┐
│   E2E 测试      │  (10%)
├─────────────────┤
│   集成测试      │  (20%)
├─────────────────┤
│   单元测试      │  (70%)
└─────────────────┘
```

### 单元测试

**要求**:
- 覆盖所有公共 API
- 测试正常路径和异常路径
- 覆盖率目标：70%+

**示例** (Dart):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('CredentialService', () {
    late CredentialService service;
    late MockVault mockVault;

    setUp(() {
      mockVault = MockVault();
      service = CredentialService(vault: mockVault);
    });

    test('成功获取凭证', () async {
      // Arrange
      when(mockVault.read(key: anyNamed('key')))
          .thenAnswer((_) async => 'test_credential');

      // Act
      final result = await service.getCredential('https://example.com');

      // Assert
      expect(result, isNotNull);
      expect(result.success, isTrue);
    });

    test('凭证不存在时返回错误', () async {
      // Arrange
      when(mockVault.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);

      // Act
      final result = await service.getCredential('https://example.com');

      // Assert
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('凭证不存在'));
    });
  });
}
```

### 集成测试

**要求**:
- 测试组件间交互
- 模拟真实场景
- 覆盖关键业务流程

**示例** (Dart):

```dart
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('完整的登录授权流程', (tester) async {
    // 1. 启动应用
    await tester.pumpWidget(MyApp());

    // 2. 模拟 OpenClaw 请求凭证
    final request = CredentialRequest()
      ..serviceUrl = 'https://example.com'
      ..sessionId = 'test-session';

    // 3. 发送请求
    final response = await client.getCredential(request);

    // 4. 验证响应
    expect(response.success, isTrue);
    expect(response.encryptedCredential, isNotEmpty);
  });
}
```

### E2E 测试

**要求**:
- 测试完整用户流程
- 使用真实环境
- 自动化执行

---

## 文档规范

### 文档结构

```
docs/
├── DEVELOPMENT_SETUP.md    # 开发环境搭建
├── API_REFERENCE.md        # API 参考文档
├── CONTRIBUTING.md         # 贡献指南（本文件）
├── ARCHITECTURE.md         # 架构文档
└── USER_GUIDE.md          # 用户指南（待创建）
```

### Markdown 格式

```markdown
# 一级标题

## 二级标题

### 三级标题

- 无序列表
- 无序列表

1. 有序列表
2. 有序列表

**粗体** 和 *斜体*

[链接](https://example.com)

![图片](image.png)

```dart
// 代码块
code here
```

| 表格 | 示例 |
|------|------|
| 单元格 | 内容 |
```

### 文档更新

**何时更新文档**:
- 添加新功能时
- 修改 API 时
- 修复 Bug 时
- 架构变更时

**文档审查**:
- 文档变更需要审查
- 确保文档与代码一致
- 语言清晰准确

---

## 社区准则

### 行为准则

#### 1. 开放包容

- 欢迎不同背景的贡献者
- 尊重不同观点
- 不歧视、不骚扰

#### 2. 建设性沟通

- 对事不对人
- 提供具体、可操作的反馈
- 接受批评和建议

#### 3. 协作精神

- 乐于帮助他人
- 分享知识和经验
- 共同解决问题

### 沟通渠道

| 渠道 | 用途 | 链接 |
|------|------|------|
| **GitHub Issues** | Bug 报告、功能建议 | [链接](https://github.com/PolyVault/polyvault/issues) |
| **GitHub Discussions** | 讨论、问答 | [链接](https://github.com/PolyVault/polyvault/discussions) |
| **Discord** | 实时聊天 | [待定] |
| **邮件列表** | 公告、讨论 | dev@polyvault.io |

### 成为 Maintainer

活跃的贡献者可以被邀请成为 Maintainer：

**要求**:
- 持续贡献高质量代码
- 积极参与代码审查
- 帮助社区成员
- 理解项目愿景

**权限**:
- 审查和合并 PR
- 管理 Issues
- 参与决策

---

## 🎓 学习资源

### 推荐阅读

- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub Flow](https://guides.github.com/introduction/flow/)
- [Dart 风格指南](https://dart.dev/guides/language/effective-dart)
- [C++ 核心指南](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines)

### 技术文档

- [eCAL 文档](https://eclipse-ecal.github.io/ecal/)
- [Flutter 文档](https://docs.flutter.dev/)
- [Protobuf 文档](https://protobuf.dev/)
- [zk_vault 文档](https://pub.dev/packages/zk_vault)

---

## 📞 获取帮助

**遇到问题？**

1. 查看 [FAQ](#常见问题)
2. 搜索 [GitHub Issues](https://github.com/PolyVault/polyvault/issues)
3. 在 [Discussions](https://github.com/PolyVault/polyvault/discussions) 提问
4. 发送邮件至 dev@polyvault.io

---

**文档维护**: PolyVault 开发团队  
**版本**: v1.0  
**最后更新**: 2026-03-13  
**反馈邮箱**: docs@polyvault.io
