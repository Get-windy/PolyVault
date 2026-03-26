# PolyVault 快速入门指南

**版本**: v1.0  
**创建日期**: 2026-03-26  
**适用对象**: 新用户、开发者、集成者

---

## 🚀 概述

PolyVault 是一个去中心化软总线客户端，支持多平台（Android/iOS/Windows/macOS/Linux）和多客户端架构。本指南帮助您在15分钟内完成安装和基本配置。

---

## 📋 目录

1. [什么是PolyVault](#什么是polyvault)
2. [核心特性](#核心特性)
3. [系统要求](#系统要求)
4. [快速安装](#快速安装)
5. [快速配置](#快速配置)
6. [基本使用](#基本使用)
7. [快速测试](#快速测试)
8. [常见问题](#常见问题)

---

## 什么是PolyVault

PolyVault 是一个去中心化的软总线客户端解决方案，提供：

- **多平台支持**: Android、iOS、Windows、macOS、Linux
- **多客户端架构**: 手机、电脑、平板、浏览器扩展
- **eCAL通信**: 端到端通信组件
- **插件化架构**: 支持插件扩展
- **安全验证**: K宝验证、三级权限体系

---

## 核心特性

| 特性 | 说明 |
|------|------|
| 跨平台 | 支持5大平台，10+种客户端 |
| eCAL通信 | 基于eCAL的高性能端到端通信 |
| 插件架构 | 支持插件扩展和自定义 |
| 安全验证 | K宝验证、三级权限体系 |
| 权限管理 | 灵活的权限配置和白名单管理 |

---

## 系统要求

### 硬件要求

| 组件 | 最低配置 | 推荐配置 |
|------|---------|---------|
| CPU | 1核 1.5GHz | 2核 2.4GHz+ |
| 内存 | 1 GB | 2 GB+ |
| 存储 | 100 MB | 500 MB+ |

### 软件要求

| 平台 | 最低版本 | 说明 |
|------|---------|------|
| Android | 8.0 | API 26+ |
| iOS | 12.0 | - |
| Windows | 10 | 64位 |
| macOS | 10.14 | 64位 |
| Linux | Ubuntu 20.04 | 64位 |

---

## 快速安装

### Android/TiOS

1. 访问应用商店搜索"PolyVault"
2. 下载并安装应用
3. 打开应用开始使用

### Windows/macOS/Linux

#### 方式一：下载安装包

1. 访问 [PolyVault官网](https://polyvault.io)
2. 下载对应平台安装包
3. 运行安装程序

#### 方式二：通过包管理器

```bash
# Windows (使用Chocolatey)
choco install polyvault

# macOS (使用Homebrew)
brew install polyvault

# Linux (使用Snap)
sudo snap install polyvault
```

#### 方式三：源码编译

```bash
# 克隆源码
git clone https://github.com/polyvault/polyvault.git
cd polyvault

# 安装依赖
pip install -r requirements.txt

# 编译构建
python setup.py build

# 安装
python setup.py install
```

---

## 快速配置

### 第一次启动

1. 打开PolyVault应用
2. 创建新账户或使用现有账户登录
3. 完成初始化设置
4. 连接到eCAL网络

### 配置文件位置

| 平台 | 配置文件路径 |
|------|-------------|
| Windows | `%APPDATA%\PolyVault\config.yaml` |
| macOS | `~/Library/Preferences/PolyVault/config.yaml` |
| Linux | `~/.config/polyvault/config.yaml` |
| Android | `/data/data/io.polyvault.app/files/config.yaml` |
| iOS | `~/Library/Application Support/PolyVault/config.yaml` |

### 主要配置项

```yaml
# config.yaml 示例
eCAL:
  host: ecal.polyvault.io
  port: 5000
  secure: true

security:
  k_bao_enabled: true
  permission_level: L2  # L1/L2/L3

monitoring:
  health_check_interval: 30  # 秒
  log_level: INFO
```

---

## 基本使用

### 1. 连接到网络

1. 打开PolyVault应用
2. 点击"连接"按钮
3. 选择eCAL网络节点
4. 输入连接凭证
5. 点击"确定"连接

### 2. 配置客户端权限

1. 进入"设置" → "权限管理"
2. 选择客户端（手机/电脑/平板）
3. 配置权限等级（L1/L2/L3）
4. 添加白名单应用

### 3. 使用K宝验证

1. 进入"设置" → "安全验证"
2. 点击"启用K宝验证"
3. 插入K宝设备
4. 输入K宝PIN码
5. 完成验证

### 4. 管理设备

1. 进入"设备管理"
2. 查看已连接设备列表
3. 点击设备进行管理
4. 设置自动授权规则

---

## 快速测试

### 基础功能测试

```bash
# 测试eCAL连接
python -m polyvault test ecal

# 测试K宝验证
python -m polyvault test k_bao

# 测试权限配置
python -m polyvault test permissions

# 运行所有测试
python -m polyvault test all
```

### 常见命令

```bash
# 查看状态
python -m polyvault status

# 查看连接
python -m polyvault connection

# 查看设备
python -m polyvault devices

# 查看日志
python -m polyvault logs
```

---

## 常见问题

### Q1: 连接eCAL网络失败？

**问题**: 无法连接到eCAL服务器

**解决方案**:
```bash
# 检查网络连接
ping ecal.polyvault.io

# 检查防火墙设置
# 确保端口5000未被阻止

# 查看详细日志
python -m polyvault logs -f
```

### Q2: K宝验证失败？

**问题**: 插入K宝后无法完成验证

**解决方案**:
```bash
# 检查K宝设备
python -m polyvault k_bao status

# 重新插入K宝
# 检查驱动是否安装
```

### Q3: 权限配置错误？

**问题**: 某些功能无法使用

**解决方案**:
```bash
# 查看当前权限等级
python -m polyvault permissions

# 修改权限配置
# 编辑 config.yaml 文件
```

---

## 下一步学习

1. [系统架构](./ARCHITECTURE.md) - 了解PolyVault架构
2. [API文档](./API_REFERENCE.md) - 学习API接口
3. [插件开发](./PLUGIN_DEVELOPMENT_GUIDE.md) - 开发插件
4. [eCAL集成](./ECAL_API.md) - eCAL通信配置

---

## 联系支持

- 📧 邮箱：support@polyvault.io
- 🐛 Issue: [GitHub Issues](https://github.com/polyvault/polyvault/issues)
- 💬 讨论：[GitHub Discussions](https://github.com/polyvault/polyvault/discussions)

---

**快速入门时间**: ≥15分钟  
**熟练使用时间**: ≥30分钟  
**系统掌握时间**: ≤1周
