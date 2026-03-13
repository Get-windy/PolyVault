# PolyVault - eCAL环境配置指南

## Windows环境配置

### 1. 安装protoc

protoc已通过Chocolatey安装：
```powershell
choco install protoc -y
```

验证安装：
```powershell
protoc --version
# libprotoc 34.0.0
```

### 2. 安装eCAL

#### 方法A：官方安装包

1. 下载eCAL安装包：
   - 访问 https://ecal.io/download/
   - 选择 Windows 版本 (推荐 5.12+)
   - 下载 `.msi` 安装包

2. 安装：
   ```powershell
   # 以管理员权限运行
   msiexec /i eCAL-5.12.x-win64.msi
   ```

3. 配置环境变量：
   ```
   ECAL_HOME=C:\Program Files\eCAL
   PATH=%ECAL_HOME%\bin
   ```

#### 方法B：vcpkg

```powershell
vcpkg install ecal:x64-windows
```

### 3. 验证eCAL安装

```powershell
# 运行eCAL Monitor
ecal_mon_gui

# 或通过命令行
ecal_test
```

### 4. 编译项目

```powershell
cd I:\PolyVault\src\agent

# 创建构建目录
mkdir build && cd build

# 配置CMake
cmake .. -DCMAKE_PREFIX_PATH="C:/Program Files/eCAL"

# 编译
cmake --build . --config Release
```

---

## 开发依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| CMake | 4.2+ | 构建系统 |
| protoc | 34.0+ | Protobuf编译 |
| eCAL | 5.12+ | 通信中间件 |
| OpenSSL | 1.1.1+ | 加密库 |

---

## 项目结构

```
PolyVault/
├── docs/
│   ├── ARCHITECTURE.md      # 架构文档
│   └── ECAL_SETUP.md        # 本文件
├── protos/
│   └── openclaw.proto       # Protobuf定义
└── src/
    ├── agent/               # C++ Agent
    │   ├── CMakeLists.txt
    │   ├── include/
    │   │   ├── agent.hpp
    │   │   ├── credential_service.hpp
    │   │   └── crypto_utils.hpp
    │   └── src/
    │       ├── agent.cpp
    │       ├── credential_service.cpp
    │       ├── crypto_utils.cpp
    │       └── main.cpp
    ├── client/              # Flutter客户端
    └── extension/           # 浏览器扩展
```

---

## 下一步

1. 安装eCAL（参考上述方法）
2. 编译Protobuf消息
3. 编译Agent项目
4. 运行测试

---

*创建时间: 2026-03-13*