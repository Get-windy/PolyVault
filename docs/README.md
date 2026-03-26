# PolyVault 文档索引

**项目**: PolyVault - 去中心化软总线客户端  
**版本**: v1.5  
**创建时间**: 2026-03-14  
**最后更新**: 2026-03-24  
**文档总数**: 51 个  
**总大小**: ~640 KB

---

## 📖 文档阅读顺序

### 新成员入门

1. **README_DOCS_RULES.md** - 文档规则（必读）
2. **DEVELOPMENT_SETUP.md** - 开发环境搭建
3. **ARCHITECTURE.md** - 系统架构设计 (v4.1)
4. **API_REFERENCE.md** - API 接口参考
5. **PLUGIN_ARCHITECTURE.md** - 插件架构文档 ⭐新增
6. **本文档** - 了解文档结构

---

## 📁 文档结构

```
docs/
├── README.md                          # 本文档 - 文档索引
├── README_DOCS_RULES.md               # 文档规则
├── CONTRIBUTING.md                    # 贡献指南
├── FAQ.md                             # 常见问题解答 ⭐新增
│
├── ARCHITECTURE.md                    # 系统架构设计 (v4.1) ⭐更新
├── API_REFERENCE.md                   # API 接口参考 (v2.0)
├── API_EXAMPLES.md                    # API 使用示例集 ⭐新增
├── TECHNICAL_SPECIFICATION.md         # 技术规格说明
├── PROTOCOL.md                        # 通信协议文档
│
├── PLUGIN_ARCHITECTURE.md             # 插件架构文档 ⭐新增
├── PLUGIN_DEVELOPMENT_GUIDE.md        # 插件开发指南 ⭐新增
├── AGENT_DEVELOPMENT_GUIDE.md         # Agent开发指南 ⭐新增
├── BROWSER_EXTENSION_GUIDE.md         # 浏览器扩展指南 ⭐新增
├── FLUTTER_INTEGRATION_GUIDE.md       # Flutter集成指南 ⭐新增
├── FFI_BINDING_GUIDE.md               # FFI绑定指南 ⭐新增
│
├── DEVELOPMENT_SETUP.md               # 开发环境搭建
├── DEVELOPMENT_GUIDE.md               # 开发指南 (v1.0)
├── TESTING.md                         # 测试文档 (v1.0)
├── DEPLOYMENT.md                      # 部署指南 (v1.0)
│
├── USER_GUIDE.md                      # 用户指南 (v1.0)
├── DEVICE_MANAGEMENT.md               # 设备管理文档
├── SETTINGS_UI.md                     # 设置界面文档 (v1.0)
│
├── ECAL_DESIGN.md                     # eCAL设计文档 ⭐新增
├── ECAL_API.md                        # eCAL API 文档
├── ECAL_SETUP.md                      # eCAL 配置指南
│
└── test_report/                       # 测试报告目录 ⭐新增
    ├── ecal_unit_test_report.md       # eCAL单元测试报告
    └── ...
```

---

## 📚 文档分类

### 核心文档（8 个）

| 文档 | 版本 | 大小 | 说明 |
|------|------|------|------|
| **ARCHITECTURE.md** | v4.1 | ~48 KB | 系统架构设计（插件化架构、多客户端架构、权限配置、插件管理器、权限管理器）⭐更新 |
| **API_REFERENCE.md** | v2.0 | ~27 KB | API 接口参考（客户端权限配置 API、K 宝验证流程） |
| **API_EXAMPLES.md** | v1.0 | ~24 KB | API 使用示例集（完整代码示例） ⭐新增 |
| **PLUGIN_ARCHITECTURE.md** | v1.0 | ~50 KB | 插件架构文档（四大插件接口、系统插件、生态插件） ⭐新增 |
| **TECHNICAL_SPECIFICATION.md** | v1.0 | ~22 KB | 技术规格说明（eCAL + zk_vault 完整方案） |
| **PROTOCOL.md** | v1.0 | ~3 KB | 通信协议文档（Protobuf 定义） |
| **FAQ.md** | v1.0 | ~17 KB | 常见问题解答（32个常见问题） ⭐新增 |
| **ECAL_DESIGN.md** | v1.0 | ~24 KB | eCAL设计文档（端对端通信组件） ⭐新增 |

---

### 开发文档（10 个）

| 文档 | 版本 | 大小 | 说明 |
|------|------|------|------|
| **DEVELOPMENT_SETUP.md** | v1.0 | ~12 KB | 开发环境搭建指南 |
| **DEVELOPMENT_GUIDE.md** | v1.0 | ~15 KB | 开发指南（开发者入门） |
| **PLUGIN_DEVELOPMENT_GUIDE.md** | v1.0 | ~31 KB | 插件开发指南 ⭐新增 |
| **AGENT_DEVELOPMENT_GUIDE.md** | v1.0 | ~31 KB | Agent开发指南 ⭐新增 |
| **BROWSER_EXTENSION_GUIDE.md** | v1.0 | ~32 KB | 浏览器扩展指南 ⭐新增 |
| **FLUTTER_INTEGRATION_GUIDE.md** | v1.0 | ~30 KB | Flutter集成指南 ⭐新增 |
| **FFI_BINDING_GUIDE.md** | v1.0 | ~25 KB | FFI绑定指南 ⭐新增 |
| **TESTING.md** | v1.0 | ~40 KB | 测试文档（测试策略和用例） |
| **DEPLOYMENT.md** | v1.0 | ~5 KB | 部署指南（部署流程和配置） |
| **CONTRIBUTING.md** | v1.0 | ~17 KB | 贡献指南 |

---

### 用户文档（4 个）

| 文档 | 版本 | 大小 | 说明 |
|------|------|------|------|
| **USER_GUIDE.md** | v1.0 | ~26 KB | 用户配置手册（客户端配置、安全设置） |
| **USER_MANUAL.md** | v4.2 | ~23 KB | 用户手册（完整操作指南） |
| **FAQ.md** | v1.0 | ~17 KB | 常见问题解答（32个问题） |
| **TROUBLESHOOTING.md** | v1.0 | ~7 KB | 故障排查指南 ⭐新增 |

---

### eCAL 通信文档（2 个）

| 文档 | 版本 | 大小 | 说明 |
|------|------|------|------|
| **ECAL_API.md** | v1.0 | ~14 KB | eCAL API 文档 |
| **ECAL_SETUP.md** | v1.0 | ~2 KB | eCAL 配置指南 |

---

### 规范文档（1 个）

| 文档 | 版本 | 大小 | 说明 |
|------|------|------|------|
| **README_DOCS_RULES.md** | v1.0 | ~5 KB | 文档规则和规范 |

---

## 🔍 快速查找

### 按角色查找

#### 👨‍💻 开发者

**入门必读**:
1. [DEVELOPMENT_SETUP.md](./DEVELOPMENT_SETUP.md) - 开发环境搭建
2. [ARCHITECTURE.md](./ARCHITECTURE.md) - 系统架构设计
3. [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - 开发指南

**API 开发**:
1. [API_REFERENCE.md](./API_REFERENCE.md) - API 接口参考
2. [API_EXAMPLES.md](./API_EXAMPLES.md) - API 使用示例 ⭐新增
3. [PROTOCOL.md](./PROTOCOL.md) - 通信协议
4. [TECHNICAL_SPECIFICATION.md](./TECHNICAL_SPECIFICATION.md) - 技术规格

**eCAL 集成**:
1. [ECAL_API.md](./eCAL/ECAL_API.md) - eCAL API 文档
2. [ECAL_SETUP.md](./eCAL/ECAL_SETUP.md) - eCAL 配置指南

#### 📖 用户

**快速上手**:
1. [USER_GUIDE.md](./USER_GUIDE.md) - 用户指南
2. [DEVICE_MANAGEMENT.md](./DEVICE_MANAGEMENT.md) - 设备管理
3. [SETTINGS_UI.md](./SETTINGS_UI.md) - 设置界面
4. [FAQ.md](./FAQ.md) - 常见问题解答 ⭐新增

#### 🔧 运维人员

**部署配置**:
1. [DEPLOYMENT.md](./DEPLOYMENT.md) - 部署指南
2. [DEPLOYMENT_OPERATIONS.md](./DEPLOYMENT_OPERATIONS.md) - 部署运维
3. [MONITORING_CONFIG.md](./MONITORING_CONFIG.md) - 监控配置 ⭐新增
4. [PERFORMANCE_TUNING.md](./PERFORMANCE_TUNING.md) - 性能调优 ⭐新增
5. [TESTING.md](./TESTING.md) - 测试文档

#### 🤝 贡献者

**贡献流程**:
1. [CONTRIBUTING.md](./CONTRIBUTING.md) - 贡献指南
2. [README_DOCS_RULES.md](./README_DOCS_RULES.md) - 文档规则

---

### 按功能查找

#### 多客户端架构
- [ARCHITECTURE.md](./ARCHITECTURE.md) - 系统架构设计
  - 手机客户端（Android/iOS/HarmonyOS）
  - 电脑客户端（Windows/macOS/Linux）
  - 平板客户端（iPadOS/Android Tablet）
  - 浏览器扩展（Chrome/Firefox/Edge）

#### 权限管理
- [API_REFERENCE.md](./API_REFERENCE.md) - API 接口参考
  - 三级权限体系（L1 普通 → L2 增强 → L3 最高）
  - Agent 白名单管理
  - K 宝验证流程（8 步完整流程）

#### 设备管理
- [DEVICE_MANAGEMENT.md](./DEVICE_MANAGEMENT.md) - 设备管理文档
- [SETTINGS_UI.md](./SETTINGS_UI.md) - 设置界面（自动授权规则）

#### eCAL 通信
- [ECAL_API.md](./eCAL/ECAL_API.md) - eCAL API 文档
- [ECAL_SETUP.md](./eCAL/ECAL_SETUP.md) - eCAL 配置指南
- [PROTOCOL.md](./PROTOCOL.md) - 通信协议（Protobuf 定义）

#### 安全验证
- [ARCHITECTURE.md](./ARCHITECTURE.md#安全验证流程) - 安全验证流程
- [API_REFERENCE.md](./API_REFERENCE.md#k 宝验证-api) - K 宝验证 API

---

## 📊 文档统计

### 文档数量分布

```
核心文档    ████████████████  8 个 (23%)
开发文档    ████████████████████  10 个 (29%)
用户文档    ██████  3 个 (9%)
eCAL 文档    ████  3 个 (9%)
测试报告    ████████  4 个 (11%)
规范文档    ██  1 个 (3%)
其他文档    ███████  5 个 (14%)
```

### 文档完整度

| 类别 | 完成度 | 文档数 |
|------|--------|--------|
| 核心文档 | 100% ✅ | 8/8 |
| 开发文档 | 100% ✅ | 10/10 |
| 用户文档 | 100% ✅ | 3/3 |
| eCAL 文档 | 100% ✅ | 3/3 |
| 测试报告 | 100% ✅ | 4/4 |
| 规范文档 | 100% ✅ | 1/1 |
| **总体** | **100%** ✅ | **29/29** |

### 总文档量

- **文档总数**: 48 个
- **总大小**: ~600 KB
- **平均大小**: ~12.5 KB/个

### 测试报告 (新增 13 个)

| 文档 | 说明 |
|------|------|
| COMPREHENSIVE_TEST_REPORT.md | 综合测试报告 |
| compatibility_test_report.md | 兼容性测试报告 |
| e2e_test_report_2026-03-21.md | E2E测试报告 |
| functional_test_report_2026-03-21.md | 功能测试报告 |
| integration_test_report_2026-03-21.md | 集成测试报告 |
| performance_report.md | 性能测试报告 |
| performance_stress_test_2026-03-22.md | 性能压力测试 |
| plugin_integration_test.md | 插件集成测试 |
| plugin_interface_test.md | 插件接口测试 |
| security_test_report.md | 安全测试报告 |
| security_test_report_2026-03-21.md | 安全测试报告 |
| security_validation_test_report_2026-03-23.md | 安全验证测试报告 ⭐最新 |
| ui_test_report_2026-03-21.md | UI测试报告 |

---

## 🔗 文档链接检查

### 内部链接

所有文档使用相对路径链接，确保：
- ✅ 使用 `./` 开头表示当前目录
- ✅ 使用 `../` 表示上级目录
- ✅ 链接包含 `.md` 扩展名

### 外部链接

外部链接应指向：
- 官方文档（eCAL, Protobuf, Flutter 等）
- 规范文档（语义化版本等）
- 项目仓库

---

## 📝 文档维护

### 更新频率

| 文档类型 | 更新频率 | 负责人 |
|---------|---------|--------|
| API 文档 | 每次 API 变更 | 后端开发 |
| 架构文档 | 架构变更时 | 架构师 |
| 开发文档 | 每月审查 | 技术负责人 |
| 用户文档 | 功能发布时 | 产品经理 |

### 版本管理

文档版本与产品版本同步：
- **主版本号**: 破坏性变更
- **次版本号**: 新功能新增
- **修订号**: 文档修正

### 文档审查

定期审查文档：
- ✅ 准确性：与代码一致
- ✅ 完整性：覆盖所有功能
- ✅ 可读性：清晰易懂
- ✅ 时效性：及时更新

---

## 🆕 最近更新

### 2026-03-24

**新增文档**:
- ✅ [MONITORING_CONFIG.md](./MONITORING_CONFIG.md) - 监控配置指南 ⭐新增
- ✅ [PERFORMANCE_TUNING.md](./PERFORMANCE_TUNING.md) - 性能调优指南 ⭐新增

**更新文档**:
- ✅ [README.md](./README.md) - v1.5（文档索引更新，51个文档）

**文档总计**: 51 个文档，~640 KB

### 2026-03-23

**新增文档**:
- ✅ [security_validation_test_report_2026-03-23.md](./security_validation_test_report_2026-03-23.md) - 安全验证测试报告 ⭐新增

**更新文档**:
- ✅ [README.md](./README.md) - v1.3（文档索引更新，48个文档）
- ✅ [API_REFERENCE.md](./API_REFERENCE.md) - v4.2.1
- ✅ [LOAD_BALANCE_CONFIG.md](./LOAD_BALANCE_CONFIG.md) - 负载均衡配置

**测试结果**: 71项安全验证测试全部通过 ✅

### 2026-03-21

**新增文档**:
- ✅ [PLUGIN_ARCHITECTURE.md](./PLUGIN_ARCHITECTURE.md) - 插件架构文档 ⭐新增
- ✅ [PLUGIN_DEVELOPMENT_GUIDE.md](./PLUGIN_DEVELOPMENT_GUIDE.md) - 插件开发指南 ⭐新增
- ✅ [AGENT_DEVELOPMENT_GUIDE.md](./AGENT_DEVELOPMENT_GUIDE.md) - Agent开发指南 ⭐新增
- ✅ [BROWSER_EXTENSION_GUIDE.md](./BROWSER_EXTENSION_GUIDE.md) - 浏览器扩展指南 ⭐新增
- ✅ [FLUTTER_INTEGRATION_GUIDE.md](./FLUTTER_INTEGRATION_GUIDE.md) - Flutter集成指南 ⭐新增
- ✅ [FFI_BINDING_GUIDE.md](./FFI_BINDING_GUIDE.md) - FFI绑定指南 ⭐新增
- ✅ [ECAL_DESIGN.md](./ECAL_DESIGN.md) - eCAL设计文档 ⭐新增
- ✅ [API_EXAMPLES.md](./API_EXAMPLES.md) - API 使用示例集 ⭐新增
- ✅ [FAQ.md](./FAQ.md) - 常见问题解答 ⭐新增

**更新文档**:
- ✅ [README.md](./README.md) - v1.2（文档索引更新，35个文档）
- ✅ [ARCHITECTURE.md](./ARCHITECTURE.md) - v4.1（新增插件管理器、权限管理器）

**文档总计**: 35 个文档，~450 KB

### 2026-03-14

**新增文档**:
- ✅ [README.md](./README.md) - 文档索引 ⭐新增

**更新文档**:
- ✅ [ARCHITECTURE.md](./ARCHITECTURE.md) - v3.0（多客户端架构、权限配置架构）
- ✅ [API_REFERENCE.md](./API_REFERENCE.md) - v2.0（客户端权限配置 API、K 宝验证流程）
- ✅ [USER_GUIDE.md](./USER_GUIDE.md) - v1.0（完整用户配置手册）
- ✅ [SETTINGS_UI.md](./SETTINGS_UI.md) - v1.0（自动授权规则配置 +277 行）

**文档总计**: 15 个文档，~200 KB

### 2026-03-13

**新增文档**:
- ✅ [DEVICE_MANAGEMENT.md](./DEVICE_MANAGEMENT.md) - 设备管理文档
- ✅ [DEPLOYMENT.md](./DEPLOYMENT.md) - 部署指南
- ✅ [TESTING.md](./TESTING.md) - 测试文档

**更新文档**:
- ✅ [ARCHITECTURE.md](./ARCHITECTURE.md) - v2.0（实现状态更新）

### 2026-03-12

**新增文档**:
- ✅ [DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md) - 开发指南
- ✅ [USER_GUIDE.md](./USER_GUIDE.md) - 用户指南

---

## 📞 反馈和支持

### 文档问题

- 📧 邮箱：docs@polyvault.io
- 🐛 Issue: [GitHub Issues](https://github.com/polyvault/polyvault/issues)
- 💬 讨论：[GitHub Discussions](https://github.com/polyvault/polyvault/discussions)

### 文档贡献

欢迎帮助完善文档！详见 [CONTRIBUTING.md](./CONTRIBUTING.md)

---

**维护者**: PolyVault 文档组  
**最后更新**: 2026-03-23  
**文档版本**: v1.3

---

*PolyVault - 去中心化软总线客户端*
