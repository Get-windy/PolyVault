# PolyVault 开发环境搭建指南

**版本**: v1.0  
**创建时间**: 2026-03-13  
**适用对象**: 所有开发人员

---

## 📖 目录

1. [前置要求](#前置要求)
2. [eCAL 安装步骤](#ecal-安装步骤)
3. [Flutter 环境配置](#flutter-环境配置)
4. [Protobuf 编译配置](#protobuf-编译配置)
5. [zk_vault 集成](#zk_vault-集成)
6. [验证安装](#验证安装)
7. [常见问题](#常见问题)

---

## 前置要求

### 系统要求

| 平台 | 最低要求 | 推荐配置 |
|------|---------|---------|
| **Windows** | Windows 10 (64-bit) | Windows 11 + WSL2 |
| **macOS** | macOS 11.0+ | macOS 13.0+ (Apple Silicon) |
| **Linux** | Ubuntu 20.04+ | Ubuntu 22.04 LTS |
| **Android** | API Level 23+ | API Level 30+ |
| **iOS** | iOS 14.0+ | iOS 16.0+ |

### 必需软件

- **Git**: 2.30+
- **Flutter**: 3.16+
- **Dart**: 3.2+
- **Protobuf 编译器**: 3.20+
- **CMake**: 3.20+
- **C++ 编译器**: GCC 9+/Clang 12+/MSVC 2019+

### 推荐工具

- **IDE**: 
  - VS Code + Flutter 插件
  - Android Studio
  - Xcode (macOS/iOS 开发)
- **调试工具**: 
  - eCAL Monitor
  - Wireshark (网络分析)
  - Postman (API 测试)

---

## eCAL 安装步骤

### Windows

#### 方式 1：官方安装程序（推荐）

1. **下载安装包**
   ```powershell
   # 访问 eCAL 官方发布页面
   https://github.com/eclipse-ecal/ecal/releases
   ```

2. **运行安装程序**
   - 下载 `ecal-5.x.x-win64.exe`
   - 双击运行，选择安装路径（默认：`C:\Program Files\eCAL`)
   - 勾选 "Add eCAL to PATH"

3. **验证安装**
   ```powershell
   # 打开新的 PowerShell 窗口
   ecal --version
   ```
   
   输出示例：
   ```
   eCAL 5.13.2
   ```

4. **安装 eCAL 示例**
   ```powershell
   # 安装示例项目（可选）
   choco install ecal-samples
   ```

#### 方式 2：使用 Chocolatey

```powershell
# 安装 Chocolatey（如未安装）
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# 安装 eCAL
choco install ecal
```

---

### macOS

#### 方式 1：使用 Homebrew（推荐）

```bash
# 添加 eCAL tap
brew tap eclipse-ecal/ecal

# 安装 eCAL
brew install ecal

# 验证安装
ecal --version
```

#### 方式 2：从源码编译

```bash
# 克隆 eCAL 仓库
git clone https://github.com/eclipse-ecal/ecal.git
cd ecal

# 创建构建目录
mkdir build && cd build

# 配置 CMake
cmake .. -DCMAKE_BUILD_TYPE=Release

# 编译
cmake --build . --config Release

# 安装
sudo cmake --install .
```

---

### Linux (Ubuntu/Debian)

#### 方式 1：使用 APT 仓库

```bash
# 添加 eCAL 仓库
sudo add-apt-repository ppa:ecal/ecal-5.13
sudo apt-get update

# 安装 eCAL
sudo apt-get install ecal libecal-dev

# 验证安装
ecal --version
```

#### 方式 2：从源码编译

```bash
# 安装依赖
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    libprotobuf-dev \
    protobuf-compiler \
    libasio-dev \
    libcurl4-openssl-dev

# 克隆并编译
git clone https://github.com/eclipse-ecal/ecal.git
cd ecal
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j$(nproc)
sudo cmake --install .
```

---

### 配置 eCAL

#### 创建配置文件

在用户主目录创建 `~/.ecal/ecal.ini`：

```ini
[eCAL]
// 网络配置
network_enabled = 1
udp_network_enabled = 1
tcp_network_enabled = 1

// 共享内存配置（本地通信）
shmem_enabled = 1

// 设备发现
monitoring_enabled = 1
discovery_timeout = 1000

// 日志配置
logging_level = info
logging_to_console = 1
```

#### 启动 eCAL Monitor

```bash
# Windows
"C:\Program Files\eCAL\ecalmon.exe"

# macOS/Linux
ecalmon
```

---

## Flutter 环境配置

### 1. 安装 Flutter SDK

#### Windows

```powershell
# 使用 winget（推荐）
winget install Google.Flutter

# 或手动下载安装
# 访问：https://docs.flutter.dev/get-started/install/windows
```

#### macOS

```bash
# 使用 Homebrew
brew install --cask flutter

# 或手动下载
# 访问：https://docs.flutter.dev/get-started/install/macos
```

#### Linux

```bash
# 使用 snap
sudo snap install flutter --classic

# 或手动下载
# 访问：https://docs.flutter.dev/get-started/install/linux
```

### 2. 配置 Flutter

```bash
# 添加到 PATH（如自动配置失败）
export PATH="$PATH:`pwd`/flutter/bin"

# 运行诊断
flutter doctor

# 接受 Android 许可证（Android 开发必需）
flutter doctor --android-licenses
```

### 3. 安装 IDE 插件

#### VS Code

1. 打开 VS Code
2. 安装插件：
   - Flutter
   - Dart
   - C/C++ (用于 eCAL FFI 开发)

#### Android Studio

1. 打开 Android Studio
2. Preferences → Plugins
3. 安装 Flutter 和 Dart 插件

### 4. 配置 Android 模拟器

```bash
# 列出可用模拟器
flutter emulators

# 创建新模拟器
flutter emulators --create <name>
```

---

## Protobuf 编译配置

### 1. 安装 Protobuf 编译器

#### Windows

```powershell
# 使用 Chocolatey
choco install protobuf

# 或下载预编译二进制
# https://github.com/protocolbuffers/protobuf/releases
```

#### macOS

```bash
# 使用 Homebrew
brew install protobuf

# 验证
protoc --version
```

#### Linux

```bash
# Ubuntu/Debian
sudo apt-get install -y protobuf-compiler

# 验证
protoc --version
```

### 2. 安装 Dart Protobuf 插件

```bash
# 安装 protoc 插件
dart pub global activate protoc_plugin

# 添加到 PATH
# Windows: %LOCALAPPDATA%\Pub\Bin
# macOS/Linux: ~/.pub-cache/bin
```

### 3. 配置 Protobuf 编译

#### 创建构建脚本

在项目根目录创建 `build_protos.ps1` (Windows) 或 `build_protos.sh` (macOS/Linux)：

**Windows (PowerShell)**:
```powershell
# build_protos.ps1

$PROTO_DIR = "protos"
$DART_OUT_DIR = "lib/generated"

# 创建输出目录
New-Item -ItemType Directory -Force -Path $DART_OUT_DIR

# 编译 Protobuf 文件
protoc `
  --dart_out=$DART_OUT_DIR `
  -I$PROTO_DIR `
  $PROTO_DIR/*.proto

Write-Host "Protobuf 编译完成！"
```

**macOS/Linux (Bash)**:
```bash
#!/bin/bash
# build_protos.sh

PROTO_DIR="protos"
DART_OUT_DIR="lib/generated"

# 创建输出目录
mkdir -p $DART_OUT_DIR

# 编译 Protobuf 文件
protoc \
  --dart_out=$DART_OUT_DIR \
  -I$PROTO_DIR \
  $PROTO_DIR/*.proto

echo "Protobuf 编译完成！"
```

#### 添加到 pubspec.yaml

在 `pubspec.yaml` 中添加依赖：

```yaml
dependencies:
  protobuf: ^3.1.0
  grpc: ^3.2.0  # 如使用 gRPC

dev_dependencies:
  build_runner: ^2.4.0
  protobuf: ^3.1.0
```

### 4. 自动编译配置

#### 使用 build_runner（推荐）

```bash
# 安装 build_runner
dart pub add dev:build_runner

# 运行自动编译
dart run build_runner build

# 监听模式（开发时自动重新编译）
dart run build_runner watch
```

#### 配置 VS Code 任务

创建 `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build Protobuf",
      "type": "shell",
      "command": "./build_protos.sh",
      "windows": {
        "command": ".\\build_protos.ps1"
      },
      "group": "build",
      "problemMatcher": []
    }
  ]
}
```

---

## zk_vault 集成

### 1. 添加依赖

```bash
# 在 Flutter 项目中
flutter pub add zk_vault
```

### 2. 配置 pubspec.yaml

```yaml
dependencies:
  zk_vault: ^0.5.0  # 检查最新版本
  flutter_secure_storage: ^9.0.0  # 备用方案
```

### 3. 平台特定配置

#### Android

在 `android/app/build.gradle` 中添加：

```gradle
android {
    defaultConfig {
        minSdkVersion 23  // 必需
    }
}
```

#### iOS

在 `ios/Podfile` 中确保：

```ruby
platform :ios, '14.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
```

### 4. 初始化 zk_vault

```dart
import 'package:zk_vault/zk_vault.dart';

class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  late final ZkVault _vault;

  Future<void> initialize() async {
    _vault = ZkVault(
      appName: 'PolyVault',
      biometricAuth: true,  // 启用生物认证
    );
    
    await _vault.init();
  }

  Future<void> storeCredential(String key, String value) async {
    await _vault.write(key: key, value: value);
  }

  Future<String?> getCredential(String key) async {
    return await _vault.read(key: key);
  }
}
```

---

## 验证安装

### 1. 运行诊断脚本

创建 `verify_setup.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:ecal_dart/ecal_dart.dart';
import 'package:zk_vault/zk_vault.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('=== PolyVault 环境验证 ===\n');

  // 1. 验证 eCAL
  try {
    print('1. 验证 eCAL...');
    // TODO: eCAL 初始化测试
    print('   ✅ eCAL 正常\n');
  } catch (e) {
    print('   ❌ eCAL 错误：$e\n');
  }

  // 2. 验证 zk_vault
  try {
    print('2. 验证 zk_vault...');
    final vault = ZkVault(appName: 'PolyVault Test');
    await vault.init();
    await vault.write(key: 'test', value: 'test_value');
    final value = await vault.read(key: 'test');
    if (value == 'test_value') {
      print('   ✅ zk_vault 正常\n');
    } else {
      print('   ❌ zk_vault 读写失败\n');
    }
  } catch (e) {
    print('   ❌ zk_vault 错误：$e\n');
  }

  // 3. 验证 Protobuf
  try {
    print('3. 验证 Protobuf...');
    // TODO: Protobuf 序列化测试
    print('   ✅ Protobuf 正常\n');
  } catch (e) {
    print('   ❌ Protobuf 错误：$e\n');
  }

  print('=== 验证完成 ===');
}
```

运行：
```bash
flutter run -d <device>
```

### 2. 运行 eCAL 示例

```bash
# 启动 eCAL 示例（终端 1）
ecal_helloworld_publisher

# 启动 eCAL 示例（终端 2）
ecal_helloworld_subscriber
```

### 3. 检查 Flutter 配置

```bash
flutter doctor -v
```

确保所有检查项都是 ✅。

---

## 常见问题

### Q1: eCAL 安装后无法找到命令

**Windows**:
```powershell
# 添加 eCAL 到 PATH
$env:Path += ";C:\Program Files\eCAL\bin"
[System.Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
```

**macOS/Linux**:
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
export PATH="/usr/local/bin:$PATH"
```

---

### Q2: Flutter doctor 显示 Android 许可证未接受

```bash
flutter doctor --android-licenses
# 输入 y 接受所有许可证
```

---

### Q3: Protobuf 编译失败

**错误**: `protoc-gen-dart: program not found`

**解决**:
```bash
# 确保 protoc_plugin 已安装
dart pub global activate protoc_plugin

# 添加到 PATH
# Windows: %LOCALAPPDATA%\Pub\Bin
# macOS/Linux: ~/.pub-cache/bin
```

---

### Q4: zk_vault 初始化失败

**Android**:
- 确保 `minSdkVersion >= 23`
- 检查是否有生物识别硬件

**iOS**:
- 确保在真机上测试（模拟器不支持 Secure Enclave）
- 检查 Keychain 共享设置

---

### Q5: eCAL 设备无法发现

**检查**:
1. 防火墙是否阻止 eCAL 端口（默认 UDP 55555）
2. 网络设备是否在同一个子网
3. eCAL Monitor 中是否能看到设备

**解决**:
```ini
# 在 ecal.ini 中配置
network_enabled = 1
udp_network_enabled = 1
discovery_timeout = 2000  # 增加超时时间
```

---

### Q6: Protobuf 生成的代码过时

```bash
# 清理并重新生成
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

---

### Q7: Flutter 构建缓慢

**解决**:
```bash
# 清理构建缓存
flutter clean

# 获取依赖
flutter pub get

# 重新构建
flutter build <platform>
```

---

## 📞 获取帮助

### 官方文档

- **eCAL**: https://eclipse-ecal.github.io/ecal/
- **Flutter**: https://docs.flutter.dev/
- **Protobuf**: https://protobuf.dev/
- **zk_vault**: https://pub.dev/packages/zk_vault

### 社区支持

- **GitHub Issues**: https://github.com/PolyVault/polyvault/issues
- **Discord**: [待定]
- **邮件**: dev@polyvault.io

---

**文档维护**: PolyVault 开发团队  
**版本**: v1.0  
**最后更新**: 2026-03-13  
**反馈邮箱**: docs@polyvault.io
