# PolyVault

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-4.2.1-green.svg)](https://github.com/polyvault/polyvault/releases)

PolyVault是一款跨平台密码管理器，采用零知识加密架构，确保您的敏感信息安全存储。

## ✨ 特性

- **零知识加密** - 数据仅在您的设备上解密
- **多端同步** - 支持Windows、macOS、Linux、iOS、Android
- **硬件安全** - 支持TPM、Secure Enclave
- **AI Agent集成** - 智能填写表单
- **浏览器扩展** - 支持Chrome/Firefox/Edge
- **开源透明** - 核心代码开源

## 📋 技术栈

| 层级 | 技术 |
|------|------|
| 后端 | Rust + Actix-web |
| 前端 | Flutter |
| 数据库 | SQLite + SQLCipher |
| 加密 | AES-256-GCM + Argon2id |

## 🚀 快速开始

### 安装

```bash
# Windows
winget install polyvault

# macOS
brew install polyvault

# Linux
snap install polyvault
```

### 首次运行

```bash
polyvault init
polyvault config set security.master_password.min_length 16
polyvault run
```

## 📦 项目结构

```
polyvault/
├── src/
│   ├── agent/          # 主应用进程
│   ├── core/          # 核心逻辑库
│   └── client/        # Flutter客户端
├── docs/              # 文档
└── tests/             # 测试
```

## 🔧 开发

```bash
# 构建Rust核心
cd src/core
cargo build

# 构建Flutter客户端
cd ../client
flutter pub get
flutter run
```

## 📚 文档

- [用户手册](docs/USER_MANUAL.md)
- [API参考](docs/API_REFERENCE.md)
- [部署指南](docs/DEPLOYMENT_OPERATIONS.md)
- [开发者指南](docs/developer-guide.md)

## 🤝 贡献

欢迎提交Issue和PR！

1. Fork项目
2. 创建分支
3. 提交代码
4. 发起PR

## 📄 许可证

MIT License

---

## 📈 开发进度 (2026-03-26)

### 代码变更统计

| 类别 | 数量 | 说明 |
|------|------|------|
| 新增文件 | 20+ | Flutter屏幕、服务、组件 |
| 修改文件 | 15+ | 状态管理、安全存储 |
| 新增代码行 | ~8,000 | Dart |

### 任务完成进度

- ✅ 凭证管理 (CRUD)
- ✅ 硬件安全存储 (zk_vault)
- ✅ 生物识别验证
- ✅ 设备配对流程
- ✅ 消息系统UI
- ✅ 授权流程UI
- ✅ 界面美化 (主题系统)
- ✅ 负载均衡后端
- 🔄 多设备同步 (开发中)
- 🔄 备份恢复功能 (规划中)

### 代码审查结果 (2026-03-26)

| 维度 | 评分 | 说明 |
|------|------|------|
| 安全 | 9.0/10 | 硬件级加密存储 |
| 性能 | 7.5/10 | 缓存机制可优化 |
| 代码质量 | 8.0/10 | 状态管理清晰 |

### 发现问题

| 优先级 | 问题 | 状态 |
|--------|------|------|
| P1 | 密码明文传递 | 待使用安全通道 |
| P2 | 缓存无过期 | 待添加TTL |

### 下一步计划

1. 完善多设备同步
2. 实现安全传输协议
3. 备份功能开发
4. 性能优化