# PolyVault 部署指南

**版本**: v1.0  
**创建时间**: 2026-03-14  
**适用对象**: 运维工程师、系统管理员

---

## 📖 目录

1. [部署架构](#部署架构)
2. [构建 Flutter 客户端](#构建-flutter-客户端)
3. [构建 C++ Agent](#构建-c-agent)
4. [服务部署](#服务部署)
5. [Docker 部署方案](#docker-部署方案)
6. [配置检查清单](#配置检查清单)
7. [故障排查](#故障排查)

---

## 🏗️ 部署架构

### 系统架构图

```
┌─────────────────────────────────────────────────────────┐
│                    用户设备层                            │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   Android   │  │    iOS      │  │  Windows/   │     │
│  │   客户端    │  │   客户端    │  │   macOS     │     │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     │
│         │                │                │             │
│         └────────────────┴────────────────┘             │
│                          │                              │
│                    (eCAL 通信)                          │
└──────────────────────────┼──────────────────────────────┘
                           │
┌──────────────────────────┼──────────────────────────────┐
│                    Agent 层                              │
├──────────────────────────┼──────────────────────────────┤
│                  ┌───────▼───────┐                      │
│                  │  C++ Agent    │                      │
│                  │  (本地服务)   │                      │
│                  └───────┬───────┘                      │
│                          │                              │
│              ┌───────────┼───────────┐                  │
│              │           │           │                  │
│        ┌─────▼─────┐ ┌──▼──┐ ┌─────▼─────┐            │
│        │ Protobuf  │ │ eCAL│ │  zk_vault │            │
│        │  消息处理 │ │ 通信│ │  安全模块 │            │
│        └───────────┘ └─────┘ └───────────┘            │
└─────────────────────────────────────────────────────────┘
                           │
                    (OpenClaw API)
                           │
┌──────────────────────────┼──────────────────────────────┐
│                  OpenClaw 平台                           │
├──────────────────────────┼──────────────────────────────┤
│                  ┌───────▼───────┐                      │
│                  │  OpenClaw     │                      │
│                  │  Gateway      │                      │
│                  └───────────────┘                      │
└─────────────────────────────────────────────────────────┘
```

---

## 📱 构建 Flutter 客户端

### 前置准备

**环境检查**:
```bash
# 检查 Flutter 环境
flutter doctor -v

# 检查必需组件
# ✅ Flutter 3.16+
# ✅ Dart 3.2+
# ✅ Android SDK (Android 构建)
# ✅ Xcode (iOS 构建，仅 macOS)
```

---

### Android 构建

**步骤 1: 配置 Android 环境**

```bash
# 安装 Android SDK
# 通过 Android Studio 安装或使用命令行工具

# 设置环境变量 (Windows)
setx ANDROID_HOME "C:\Users\<用户名>\AppData\Local\Android\Sdk"
setx PATH "%PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools"

# 设置环境变量 (macOS/Linux)
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools"
```

**步骤 2: 安装依赖**

```bash
cd I:\PolyVault\client

# 获取 Flutter 依赖
flutter pub get

# 检查依赖问题
flutter analyze
```

**步骤 3: 构建 Release 版本**

```bash
# 构建 APK
flutter build apk --release

# 构建 App Bundle (推荐用于 Google Play)
flutter build appbundle --release

# 输出位置
# - APK: build/app/outputs/flutter-apk/app-release.apk
# - AAB: build/app/outputs/bundle/release/app-release.aab
```

**步骤 4: 签名配置**

**android/key.properties**:
```properties
storePassword=<密钥库密码>
keyPassword=<密钥密码>
keyAlias=<密钥别名>
storeFile=<密钥库文件路径>
```

**android/app/build.gradle**:
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

---

### iOS 构建

**步骤 1: 配置 Xcode**

```bash
# 安装 Xcode (macOS)
# 从 App Store 下载并安装

# 安装命令行工具
xcode-select --install

# 接受许可协议
sudo xcodebuild -license accept
```

**步骤 2: 配置签名**

打开 `I:\PolyVault\client\ios\Runner.xcworkspace` 在 Xcode 中:
1. 选择 Runner 项目
2.  Signing & Capabilities 标签
3.  选择开发团队
4.  配置 Bundle Identifier
5.  启用 Automatic signing

**步骤 3: 构建**

```bash
# 构建 Release 版本
flutter build ios --release

# 输出位置
# build/ios/iphoneos/Runner.app
```

**步骤 4: 归档和发布**

在 Xcode 中:
1. Product → Archive
2. 在 Organizer 窗口中点击 Distribute App
3. 选择 App Store Connect 或 Ad Hoc
4. 跟随向导完成发布

---

### Windows 构建

**步骤 1: 启用 Windows 桌面支持**

```bash
# 启用 Windows 桌面
flutter config --enable-windows-desktop

# 检查配置
flutter doctor
```

**步骤 2: 安装 Visual Studio**

- 安装 Visual Studio 2019 或更高版本
- 安装 "使用 C++ 的桌面开发" 工作负载
- 安装 Windows 10 SDK

**步骤 3: 构建**

```bash
# 构建 Release 版本
flutter build windows --release

# 输出位置
# build\windows\runner\Release\
```

**步骤 4: 打包分发**

```bash
# 创建安装包
# 方法 1: 使用 NSIS
# 方法 2: 使用 Inno Setup
# 方法 3: 手动打包 Release 目录

# 包含必需文件:
# - polyvault.exe
# - data/ (Flutter 资源)
# - *.dll (依赖库)
```

---

### macOS 构建

**步骤 1: 启用 macOS 桌面支持**

```bash
# 启用 macOS 桌面
flutter config --enable-macos-desktop

# 检查配置
flutter doctor
```

**步骤 2: 构建**

```bash
# 构建 Release 版本
flutter build macos --release

# 输出位置
# build/macos/Build/Products/Release/PolyVault.app
```

**步骤 3: 代码签名和公证**

```bash
# 代码签名
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name" \
  build/macos/Build/Products/Release/PolyVault.app

# 提交公证
xcrun notarytool submit build/macos/Build/Products/Release/PolyVault.app \
  --apple-id "your.apple.id@example.com" \
  --password "your-app-specific-password" \
  --team-id "YOUR_TEAM_ID"

#  stapler 公证票
xcrun stapler staple build/macos/Build/Products/Release/PolyVault.app
```

---

## 🤖 构建 C++ Agent

### 前置准备

**必需软件**:
- CMake 3.20+
- C++ 编译器 (GCC 9+/Clang 12+/MSVC 2019+)
- Protobuf 编译器 3.20+
- eCAL SDK
- Boost 库 (可选)

---

### Windows 构建

**步骤 1: 安装 eCAL**

```powershell
# 下载 eCAL Windows 安装程序
# https://github.com/eclipse-ecal/ecal/releases

# 安装 eCAL
# 运行安装程序，选择默认选项

# 验证安装
ecal_monitor --version
```

**步骤 2: 安装 Protobuf**

```powershell
# 使用 vcpkg 安装
git clone https://github.com/Microsoft/vcpkg.git
cd vcpkg
.\bootstrap-vcpkg.bat
.\vcpkg install protobuf:x64-windows

# 或使用 Chocolatey
choco install protobuf
```

**步骤 3: 编译 Protobuf 消息**

```powershell
cd I:\PolyVault\agent

# 生成 C++ 代码
protoc --proto_path=proto \
       --cpp_out=src/generated \
       proto/*.proto

# 验证生成
dir src\generated
```

**步骤 4: 构建 Agent**

```powershell
# 创建构建目录
mkdir build
cd build

# 配置 CMake
cmake .. -G "Visual Studio 17 2022" -A x64

# 构建
cmake --build . --config Release

# 输出
# build\Release\polyvault-agent.exe
```

**CMakeLists.txt 示例**:
```cmake
cmake_minimum_required(VERSION 3.20)
project(polyvault-agent VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 查找依赖
find_package(Protobuf REQUIRED)
find_package(eCAL REQUIRED)

# 包含目录
include_directories(
    ${PROJECT_SOURCE_DIR}/src
    ${PROJECT_SOURCE_DIR}/src/generated
    ${Protobuf_INCLUDE_DIRS}
    ${eCAL_INCLUDE_DIRS}
)

# 源文件
set(SOURCES
    src/main.cpp
    src/agent.cpp
    src/message_handler.cpp
    src/generated/auth.pb.cc
    src/generated/vault.pb.cc
    # ... 其他生成的文件
)

# 可执行文件
add_executable(polyvault-agent ${SOURCES})

# 链接库
target_link_libraries(polyvault-agent
    ${Protobuf_LIBRARIES}
    eCAL::core
)

# 安装
install(TARGETS polyvault-agent DESTINATION bin)
```

---

### Linux 构建

**步骤 1: 安装依赖**

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    libprotobuf-dev \
    protobuf-compiler \
    libecal5 \
    libboost-all-dev

# 安装 eCAL
# 参考：https://eclipse-ecal.github.io/ecal/installation.html
wget https://github.com/eclipse-ecal/ecal/releases/download/v5.13.2/ecal-5.13.2-Linux.deb
sudo dpkg -i ecal-5.13.2-Linux.deb
```

**步骤 2: 编译 Protobuf**

```bash
cd I:\PolyVault\agent

# 生成 C++ 代码
protoc --proto_path=proto \
       --cpp_out=src/generated \
       proto/*.proto
```

**步骤 3: 构建**

```bash
mkdir build && cd build

# 配置
cmake .. -DCMAKE_BUILD_TYPE=Release

# 构建
make -j$(nproc)

# 安装
sudo make install
```

---

### macOS 构建

**步骤 1: 安装依赖**

```bash
# 使用 Homebrew
brew install cmake protobuf ecal boost
```

**步骤 2: 构建**

```bash
mkdir build && cd build

# 配置
cmake .. -DCMAKE_BUILD_TYPE=Release

# 构建
make -j$(sysctl -n hw.ncpu)

# 安装
sudo make install
```

---

## 🚀 服务部署

### 部署模式

#### 模式 1: 独立部署（推荐）

```
用户设备 → PolyVault 客户端 → C++ Agent (本地) → OpenClaw API
```

**优点**:
- ✅ 低延迟
- ✅ 离线可用
- ✅ 数据本地存储

**部署步骤**:
1. 安装 Flutter 客户端
2. 安装 C++ Agent
3. 配置 OpenClaw API 端点
4. 启动 Agent 服务
5. 启动客户端

---

#### 模式 2: 集中部署

```
用户设备 → PolyVault 服务器 → OpenClaw API
```

**适用场景**:
- 企业环境
- 需要集中管理
- 多用户共享

**部署步骤**:
1. 部署服务器版本 Agent
2. 配置负载均衡
3. 配置数据库
4. 配置 SSL/TLS
5. 客户端连接服务器

---

### 配置文件

**config/production.yaml**:
```yaml
# 服务器配置
server:
  host: 0.0.0.0
  port: 8080
  workers: 4

# eCAL 配置
ecal:
  network:
    unicast: true
    multicast: false
  discovery:
    timeout: 1000

# OpenClaw API 配置
openclaw:
  base_url: https://api.openclaw.ai
  api_key: ${OPENCLAW_API_KEY}
  timeout: 30000
  retry_count: 3

# 安全配置
security:
  enable_tls: true
  cert_file: /etc/polyvault/ssl/server.crt
  key_file: /etc/polyvault/ssl/server.key

# 日志配置
logging:
  level: info
  file: /var/log/polyvault/agent.log
  max_size: 100MB
  max_files: 10

# 存储配置
storage:
  type: local
  path: /var/lib/polyvault/data
  max_size: 10GB
```

---

### Systemd 服务配置（Linux）

**/etc/systemd/system/polyvault-agent.service**:
```ini
[Unit]
Description=PolyVault C++ Agent
After=network.target ecal.service

[Service]
Type=simple
User=polyvault
Group=polyvault
ExecStart=/usr/local/bin/polyvault-agent --config /etc/polyvault/config.yaml
Restart=on-failure
RestartSec=5
LimitNOFILE=65535

# 环境变量
Environment="ECAL_HOST=0.0.0.0"
Environment="OPENCLAW_API_KEY=your_api_key"

# 安全设置
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/polyvault

[Install]
WantedBy=multi-user.target
```

**启动服务**:
```bash
# 重新加载 systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable polyvault-agent

# 启动服务
sudo systemctl start polyvault-agent

# 查看状态
sudo systemctl status polyvault-agent

# 查看日志
sudo journalctl -u polyvault-agent -f
```

---

### Windows 服务配置

**使用 NSSM (Non-Sucking Service Manager)**:

```powershell
# 下载 NSSM
# https://nssm.cc/download

# 安装服务
nssm install PolyVaultAgent "C:\Program Files\PolyVault\polyvault-agent.exe"
nssm set PolyVaultAgent AppParameters "--config C:\Program Files\PolyVault\config.yaml"
nssm set PolyVaultAgent AppDirectory "C:\Program Files\PolyVault"
nssm set PolyVaultAgent AppStdout "C:\ProgramData\PolyVault\logs\stdout.log"
nssm set PolyVaultAgent AppStderr "C:\ProgramData\PolyVault\logs\stderr.log"
nssm set PolyVaultAgent AppRotateFiles 1
nssm set PolyVaultAgent AppRotateOnline 1
nssm set PolyVaultAgent AppRotateBytes 10485760

# 启动服务
nssm start PolyVaultAgent

# 查看状态
nssm status PolyVaultAgent
```

---

## 🐳 Docker 部署方案

### Dockerfile

**Dockerfile**:
```dockerfile
# 构建阶段
FROM ubuntu:22.04 AS builder

# 安装依赖
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libprotobuf-dev \
    protobuf-compiler \
    libecal5 \
    git \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /app

# 复制源代码
COPY . .

# 编译 Protobuf
RUN protoc --proto_path=proto --cpp_out=src/generated proto/*.proto

# 构建
RUN mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)

# 运行阶段
FROM ubuntu:22.04

# 安装运行时依赖
RUN apt-get update && apt-get install -y \
    libecal5 \
    libprotobuf23 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 创建用户
RUN useradd -m -u 1000 polyvault

# 复制构建产物
COPY --from=builder /app/build/polyvault-agent /usr/local/bin/
COPY --from=builder /app/config/production.yaml /etc/polyvault/config.yaml

# 设置权限
RUN chown -R polyvault:polyvault /etc/polyvault

# 切换用户
USER polyvault

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 启动命令
CMD ["polyvault-agent", "--config", "/etc/polyvault/config.yaml"]
```

---

### Docker Compose

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  polyvault-agent:
    build: .
    container_name: polyvault-agent
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - polyvault-data:/var/lib/polyvault
      - ./logs:/var/log/polyvault
      - ./config/production.yaml:/etc/polyvault/config.yaml:ro
    environment:
      - ECAL_HOST=0.0.0.0
      - OPENCLAW_API_KEY=${OPENCLAW_API_KEY}
      - TZ=Asia/Shanghai
    networks:
      - polyvault-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s

  # 可选：Redis 缓存
  redis:
    image: redis:7-alpine
    container_name: polyvault-redis
    restart: unless-stopped
    volumes:
      - redis-data:/data
    networks:
      - polyvault-network

  # 可选：监控
  prometheus:
    image: prom/prometheus:latest
    container_name: polyvault-prometheus
    restart: unless-stopped
    volumes:
      - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - prometheus-data:/prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
    ports:
      - "9090:9090"
    networks:
      - polyvault-network

  grafana:
    image: grafana/grafana:latest
    container_name: polyvault-grafana
    restart: unless-stopped
    volumes:
      - grafana-data:/var/lib/grafana
      - ./monitoring/grafana/dashboards:/etc/grafana/provisioning/dashboards
      - ./monitoring/grafana/datasources:/etc/grafana/provisioning/datasources
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}
    networks:
      - polyvault-network
    depends_on:
      - prometheus

volumes:
  polyvault-data:
  redis-data:
  prometheus-data:
  grafana-data:

networks:
  polyvault-network:
    driver: bridge
```

---

### 部署命令

```bash
# 构建镜像
docker-compose build

# 启动服务
docker-compose up -d

# 查看日志
docker-compose logs -f polyvault-agent

# 查看状态
docker-compose ps

# 停止服务
docker-compose down

# 清理数据
docker-compose down -v
```

---

## ✅ 配置检查清单

### 部署前检查

#### 环境检查

- [ ] 操作系统版本符合要求
- [ ] 磁盘空间充足（至少 10GB）
- [ ] 内存充足（至少 4GB）
- [ ] 网络连接正常
- [ ] 防火墙规则配置

#### 依赖检查

- [ ] Flutter 3.16+ 已安装
- [ ] C++ 编译器已安装
- [ ] CMake 3.20+ 已安装
- [ ] Protobuf 编译器已安装
- [ ] eCAL SDK 已安装

#### 配置检查

- [ ] 配置文件已创建
- [ ] API 密钥已配置
- [ ] SSL 证书已配置（生产环境）
- [ ] 日志目录已创建
- [ ] 数据目录已创建

#### 安全检查

- [ ] 使用非 root 用户运行
- [ ] 文件权限正确
- [ ] 敏感信息使用环境变量
- [ ] 启用 TLS/SSL
- [ ] 配置防火墙

---

### 部署后检查

#### 服务检查

- [ ] 服务正常启动
- [ ] 服务自动重启配置
- [ ] 日志正常输出
- [ ] 端口正常监听
- [ ] 健康检查通过

#### 功能检查

- [ ] eCAL 通信正常
- [ ] OpenClaw API 连接正常
- [ ] 客户端可以连接
- [ ] 数据存储正常
- [ ] 监控指标正常

#### 性能检查

- [ ] CPU 使用率正常（< 50%）
- [ ] 内存使用正常（< 80%）
- [ ] 磁盘 I/O 正常
- [ ] 网络延迟正常（< 100ms）
- [ ] 响应时间正常（< 500ms）

---

## 🔧 故障排查

### 常见问题

#### 1. eCAL 连接失败

**症状**: `Error: eCAL connection timeout`

**排查步骤**:
```bash
# 检查 eCAL 服务状态
systemctl status ecal

# 检查 eCAL 配置
ecal_config --show

# 测试 eCAL 连接
ecal_monitor

# 检查防火墙
sudo ufw status
sudo ufw allow 55555/tcp  # eCAL 默认端口
```

**解决方案**:
```bash
# 重启 eCAL 服务
sudo systemctl restart ecal

# 重新配置 eCAL
ecal_config --set network.unicast=true
```

---

#### 2. Protobuf 编译错误

**症状**: `error: undefined reference to 'google::protobuf::Message'`

**排查步骤**:
```bash
# 检查 Protobuf 版本
protoc --version

# 检查 Protobuf 库
pkg-config --libs protobuf

# 清理构建
rm -rf build
```

**解决方案**:
```bash
# 重新安装 Protobuf
sudo apt-get install --reinstall libprotobuf-dev protobuf-compiler

# 重新编译
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

---

#### 3. Flutter 构建失败

**症状**: `Gradle build failed`

**排查步骤**:
```bash
# 检查 Flutter 环境
flutter doctor -v

# 清理构建
flutter clean

# 获取依赖
flutter pub get
```

**解决方案**:
```bash
# 升级 Gradle
# android/build.gradle
dependencies {
    classpath 'com.android.tools.build:gradle:8.0.0'
}

# 升级 Gradle Wrapper
# android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
```

---

#### 4. OpenClaw API 连接失败

**症状**: `Error: Connection refused to api.openclaw.ai`

**排查步骤**:
```bash
# 检查网络连接
curl -I https://api.openclaw.ai

# 检查 API 密钥
echo $OPENCLAW_API_KEY

# 测试 API 连接
curl -H "Authorization: Bearer $OPENCLAW_API_KEY" \
     https://api.openclaw.ai/api/health
```

**解决方案**:
```bash
# 更新 API 密钥
export OPENCLAW_API_KEY="your_new_api_key"

# 检查防火墙
sudo ufw allow out 443/tcp
```

---

#### 5. 服务无法启动

**症状**: Systemd 服务启动失败

**排查步骤**:
```bash
# 查看服务状态
sudo systemctl status polyvault-agent

# 查看日志
sudo journalctl -u polyvault-agent -n 50

# 检查配置文件
polyvault-agent --config /etc/polyvault/config.yaml --test
```

**解决方案**:
```bash
# 检查文件权限
sudo chown polyvault:polyvault /etc/polyvault/config.yaml
sudo chmod 640 /etc/polyvault/config.yaml

# 检查日志目录
sudo mkdir -p /var/log/polyvault
sudo chown polyvault:polyvault /var/log/polyvault
```

---

## 📊 监控和维护

### 监控指标

**关键指标**:
- CPU 使用率
- 内存使用率
- 磁盘使用率
- 网络流量
- eCAL 连接数
- API 请求成功率
- 平均响应时间

### 日志管理

**日志轮转配置**:
```bash
# /etc/logrotate.d/polyvault
/var/log/polyvault/*.log {
    daily
    rotate 10
    compress
    delaycompress
    missingok
    notifempty
    create 0640 polyvault polyvault
    postrotate
        systemctl kill -s HUP polyvault-agent
    endscript
}
```

### 备份策略

**数据备份**:
```bash
# 备份脚本
#!/bin/bash
BACKUP_DIR="/backup/polyvault"
DATE=$(date +%Y%m%d_%H%M%S)

# 备份数据目录
tar -czf $BACKUP_DIR/data_$DATE.tar.gz /var/lib/polyvault

# 备份配置文件
tar -czf $BACKUP_DIR/config_$DATE.tar.gz /etc/polyvault

# 删除 30 天前的备份
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
```

---

## 📞 联系方式

**部署问题咨询**:
- 邮箱：`devops@polyvault.io`
- 内部频道：PolyVault 运维群组

**紧急故障**:
- 邮箱：`emergency@polyvault.io`
- 24 小时响应

---

**文档维护**: PolyVault 文档组  
**反馈邮箱**: docs@polyvault.io  
**最后更新**: 2026-03-14
