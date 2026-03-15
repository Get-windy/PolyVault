# PolyVault 插件开发指南

**版本**: v1.0  
**创建时间**: 2026-03-15  
**适用对象**: 插件开发者、扩展开发者

---

## 📖 目录

1. [插件架构概述](#插件架构概述)
2. [插件开发快速开始](#插件开发快速开始)
3. [插件清单文件](#插件清单文件)
4. [插件生命周期](#插件生命周期)
5. [插件 API 参考](#插件-api-参考)
6. [插件示例](#插件示例)
7. [调试与测试](#调试与测试)
8. [发布与分发](#发布与分发)

---

## 🏗️ 插件架构概述

### PolyVault 插件系统

```
┌─────────────────────────────────────────────────────────┐
│                    PolyVault Core                        │
│  ┌─────────────┬─────────────┬─────────────┐           │
│  │ Plugin      │   Vault     │    Auth     │           │
│  │ Manager     │   Core      │    Core     │           │
│  └─────────────┴─────────────┴─────────────┘           │
│                        │                                │
│                  Plugin API                             │
│                        │                                │
├────────────────────────┼────────────────────────────────┤
│                        │                                │
│  ┌─────────────────────┼─────────────────────┐         │
│  │                     │                     │         │
│  ▼                     ▼                     ▼         │
│ ┌──────────┐     ┌──────────┐     ┌──────────┐        │
│ │ Flutter  │     │  Agent   │     │   IoT    │        │
│ │ Plugin   │     │ Plugin   │     │  Plugin  │        │
│ └──────────┘     └──────────┘     └──────────┘        │
│                                                        │
│                    插件生态                             │
└─────────────────────────────────────────────────────────┘
```

### 插件类型

| 类型 | 用途 | 语言 | 示例 |
|------|------|------|------|
| **Flutter Plugin** | UI 扩展、客户端功能 | Dart | 生物认证、主题 |
| **Agent Plugin** | 后端逻辑、消息处理 | C++/Rust | 协议转换、自动化 |
| **IoT Plugin** | 物联网设备集成 | C/C++ | 传感器、执行器 |
| **Extension** | 轻量级扩展 | JavaScript/Python | 脚本、工具 |

---

## 🚀 插件开发快速开始

### 1. 安装开发工具

#### 必需工具

```bash
# C++ 插件开发
# Windows: Visual Studio 2022 + C++ 工作负载
# Linux: g++ 11+ 或 clang 14+
# macOS: Xcode Command Line Tools

# Rust 插件开发
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Flutter 插件开发
flutter doctor

# Python 插件开发
pip install polyvault-sdk
```

### 2. 创建插件模板

#### 使用 CLI 工具

```bash
# 安装 PolyVault CLI
npm install -g @polyvault/cli

# 创建 C++ Agent 插件
polyvault plugin:create my-agent-plugin --type agent --lang cpp

# 创建 Flutter 插件
polyvault plugin:create my-flutter-plugin --type flutter --lang dart

# 创建 Rust 插件
polyvault plugin:create my-rust-plugin --type agent --lang rust

# 创建 Python 插件
polyvault plugin:create my-python-plugin --type extension --lang python
```

### 3. 项目结构

#### C++ Agent 插件

```
my-agent-plugin/
├── CMakeLists.txt
├── plugin.yaml              # 插件清单
├── src/
│   ├── main.cpp            # 插件入口
│   ├── plugin.cpp          # 插件实现
│   └── plugin.h            # 插件头文件
├── include/
│   └── my_plugin.h         # 公共 API
├── tests/
│   └── test_plugin.cpp     # 单元测试
└── README.md
```

#### Flutter 插件

```
my-flutter-plugin/
├── pubspec.yaml            # 插件清单
├── lib/
│   ├── my_plugin.dart      # 插件实现
│   └── my_plugin_method_channel.dart
├── example/
│   └── lib/main.dart       # 示例应用
├── test/
│   └── my_plugin_test.dart # 单元测试
└── README.md
```

#### Rust 插件

```
my-rust-plugin/
├── Cargo.toml
├── plugin.yaml
├── src/
│   ├── lib.rs              # 插件库
│   └── plugin.rs           # 插件实现
├── tests/
│   └── integration_test.rs
└── README.md
```

---

## 📋 插件清单文件

### plugin.yaml 格式

```yaml
# 插件元数据
id: com.example.my-plugin
name: My Plugin
version: 1.0.0
description: A sample PolyVault plugin
author: Your Name <your.email@example.com>
license: MIT
homepage: https://github.com/yourname/my-plugin

# 插件类型
type: agent  # agent, flutter, iot, extension

# 版本约束
core_version: ">=0.5.0,<1.0.0"  # 最低核心版本
api_version: "1.0"              # API 版本

# 入口点
entry_point: 
  cpp: "libmy_plugin.so"
  rust: "libmy_plugin.so"
  python: "my_plugin.py"
  dart: "my_plugin.dart"

# 依赖
dependencies:
  - id: com.polyvault.auth
    version: ">=0.3.0"
  - id: com.polyvault.vault
    version: "~0.4.0"

# 提供的能力
provides:
  - capability: credential_provider
    version: "1.0"
    description: Provide credentials for services
  - capability: event_handler
    version: "1.0"
    description: Handle custom events

# 需要的能力
requires:
  - capability: credential_vault
    version: ">=1.0"
  - capability: event_bus
    version: ">=1.0"

# 权限请求
permissions:
  - credential:read
  - credential:write
  - event:subscribe
  - event:publish

# 资源配置
resources:
  memory_limit: 512MB
  cpu_limit: 50%
  storage_limit: 100MB

# 配置选项
config:
  - name: api_key
    type: string
    required: true
    description: API key for external service
  - name: timeout_ms
    type: integer
    default: 5000
    description: Request timeout in milliseconds
```

---

## 🔄 插件生命周期

### 生命周期状态

```
┌─────────────────────────────────────────────────────────┐
│                  插件生命周期状态机                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                     ┌──────────┐                        │
│                     │  NONE    │                        │
│                     └────┬─────┘                        │
│                          │ load()                       │
│                          ▼                              │
│                     ┌──────────┐                        │
│              ┌─────►│ LOADED   │◄─────┐                 │
│              │      └────┬─────┘      │                 │
│              │           │ start()    │ error/stop()    │
│              │           ▼            │                 │
│         error│      ┌──────────┐      │                 │
│              │      │ STARTED  │──────┘                 │
│              │      └────┬─────┘                        │
│              │           │ stop()                       │
│              │           ▼                              │
│              │      ┌──────────┐                        │
│              └──────│ STOPPED  │                        │
│                     └────┬─────┘                        │
│                          │ unload()                     │
│                          ▼                              │
│                     ┌──────────┐                        │
│                     │ UNLOADED │                        │
│                     └──────────┘                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 生命周期回调

#### C++ 实现

```cpp
// plugin.h
#pragma once

#include <polyvault/plugin.h>

class MyPlugin : public polyvault::IPlugin {
public:
    // 插件元数据
    polyvault::PluginMetadata metadata() const override;
    
    // 生命周期回调
    polyvault::Result onLoad(const polyvault::Context& ctx) override;
    polyvault::Result onStart() override;
    polyvault::Result onStop() override;
    polyvault::Result onUnload() override;
    
    // 能力提供
    std::vector<polyvault::Capability> getCapabilities() const override;
    
    // 事件处理
    polyvault::Result handleEvent(const polyvault::Event& event) override;
    
private:
    polyvault::Context context_;
    bool running_ = false;
};

// plugin.cpp
#include "plugin.h"

polyvault::PluginMetadata MyPlugin::metadata() const {
    return {
        .id = "com.example.my-plugin",
        .name = "My Plugin",
        .version = "1.0.0",
        .author = "Your Name",
        .description = "A sample PolyVault plugin",
    };
}

polyvault::Result MyPlugin::onLoad(const polyvault::Context& ctx) {
    // 初始化资源
    context_ = ctx;
    
    // 注册配置
    context_.config().registerOption("api_key", "");
    context_.config().registerOption("timeout_ms", 5000);
    
    // 加载配置
    std::string api_key = context_.config().get<std::string>("api_key");
    int timeout = context_.config().get<int>("timeout_ms");
    
    return polyvault::Result::Success();
}

polyvault::Result MyPlugin::onStart() {
    // 启动服务
    running_ = true;
    
    // 订阅事件
    context_.eventBus().subscribe("credential/request", 
        [this](const auto& event) {
            handleCredentialRequest(event);
        });
    
    // 注册能力
    context_.registry().registerCapability({
        .name = "credential_provider",
        .version = "1.0",
    });
    
    return polyvault::Result::Success();
}

polyvault::Result MyPlugin::onStop() {
    // 停止服务
    running_ = false;
    
    // 取消订阅
    context_.eventBus().unsubscribeAll();
    
    // 注销能力
    context_.registry().unregisterAll();
    
    return polyvault::Result::Success();
}

polyvault::Result MyPlugin::onUnload() {
    // 清理资源
    context_ = polyvault::Context();
    
    return polyvault::Result::Success();
}

std::vector<polyvault::Capability> MyPlugin::getCapabilities() const {
    return {
        {
            .name = "credential_provider",
            .version = "1.0",
            .description = "Provide credentials for services",
        }
    };
}

polyvault::Result MyPlugin::handleEvent(const polyvault::Event& event) {
    if (event.type() == "credential/request") {
        return handleCredentialRequest(event);
    }
    
    return polyvault::Result::Success();
}

polyvault::Result MyPlugin::handleCredentialRequest(const polyvault::Event& event) {
    // 处理凭证请求
    auto request = event.data<polyvault::CredentialRequest>();
    
    // 从密码箱获取凭证
    auto credential = context_.vault().get(request.service_url());
    
    // 返回凭证
    context_.eventBus().publish("credential/response", credential);
    
    return polyvault::Result::Success();
}

// 导出插件工厂函数
extern "C" POLYVAULT_PLUGIN_EXPORT polyvault::IPlugin* create_plugin() {
    return new MyPlugin();
}

extern "C" POLYVAULT_PLUGIN_EXPORT void destroy_plugin(polyvault::IPlugin* plugin) {
    delete plugin;
}
```

---

#### Rust 实现

```rust
// src/lib.rs
use polyvault_sdk::{Plugin, PluginMetadata, Context, Result, Capability, Event};

pub struct MyPlugin {
    context: Option<Context>,
    running: bool,
}

impl Plugin for MyPlugin {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata {
            id: "com.example.my-plugin".to_string(),
            name: "My Plugin".to_string(),
            version: "1.0.0".to_string(),
            author: "Your Name".to_string(),
            description: "A sample PolyVault plugin".to_string(),
        }
    }
    
    fn on_load(&mut self, ctx: Context) -> Result<()> {
        self.context = Some(ctx);
        
        // 注册配置
        if let Some(ctx) = &self.context {
            ctx.config().register("api_key", "");
            ctx.config().register("timeout_ms", 5000);
            
            // 加载配置
            let api_key = ctx.config().get::<String>("api_key")?;
            let timeout = ctx.config().get::<i32>("timeout_ms")?;
        }
        
        Ok(())
    }
    
    fn on_start(&mut self) -> Result<()> {
        self.running = true;
        
        if let Some(ctx) = &self.context {
            // 订阅事件
            ctx.event_bus().subscribe("credential/request", |event| {
                self.handle_credential_request(event);
            })?;
            
            // 注册能力
            ctx.registry().register(Capability {
                name: "credential_provider".to_string(),
                version: "1.0".to_string(),
                description: "Provide credentials for services".to_string(),
            })?;
        }
        
        Ok(())
    }
    
    fn on_stop(&mut self) -> Result<()> {
        self.running = false;
        
        if let Some(ctx) = &self.context {
            ctx.event_bus().unsubscribe_all()?;
            ctx.registry().unregister_all()?;
        }
        
        Ok(())
    }
    
    fn on_unload(&mut self) -> Result<()> {
        self.context = None;
        Ok(())
    }
    
    fn get_capabilities(&self) -> Vec<Capability> {
        vec![
            Capability {
                name: "credential_provider".to_string(),
                version: "1.0".to_string(),
                description: "Provide credentials for services".to_string(),
            }
        ]
    }
    
    fn handle_event(&self, event: Event) -> Result<()> {
        match event.event_type().as_str() {
            "credential/request" => self.handle_credential_request(event),
            _ => Ok(()),
        }
    }
}

impl MyPlugin {
    fn handle_credential_request(&self, event: Event) -> Result<()> {
        if let Some(ctx) = &self.context {
            // 处理凭证请求
            let request = event.data::<CredentialRequest>()?;
            
            // 从密码箱获取凭证
            let credential = ctx.vault().get(&request.service_url)?;
            
            // 返回凭证
            ctx.event_bus().publish("credential/response", credential)?;
        }
        
        Ok(())
    }
}

// 插件工厂
#[no_mangle]
pub extern "C" fn create_plugin() -> *mut dyn Plugin {
    Box::into_raw(Box::new(MyPlugin {
        context: None,
        running: false,
    }))
}

#[no_mangle]
pub extern "C" fn destroy_plugin(plugin: *mut dyn Plugin) {
    unsafe {
        let _ = Box::from_raw(plugin);
    }
}
```

---

#### Flutter 实现

```dart
// lib/my_plugin.dart
import 'package:flutter/services.dart';
import 'package:polyvault_sdk/polyvault_sdk.dart';

class MyPlugin extends PolyVaultPlugin {
  @override
  PluginMetadata get metadata => PluginMetadata(
        id: 'com.example.my-plugin',
        name: 'My Plugin',
        version: '1.0.0',
        author: 'Your Name',
        description: 'A sample PolyVault plugin',
      );
  
  PolyVaultContext? _context;
  bool _running = false;
  
  @override
  Future<Result> onLoad(PolyVaultContext context) async {
    _context = context;
    
    // 注册配置
    context.config.registerOption('api_key', '');
    context.config.registerOption('timeout_ms', 5000);
    
    // 加载配置
    final apiKey = await context.config.get<String>('api_key');
    final timeout = await context.config.get<int>('timeout_ms');
    
    return Result.success();
  }
  
  @override
  Future<Result> onStart() async {
    _running = true;
    
    if (_context != null) {
      // 订阅事件
      await _context!.eventBus.subscribe('credential/request', (event) {
        _handleCredentialRequest(event);
      });
      
      // 注册能力
      await _context!.registry.register(Capability(
        name: 'credential_provider',
        version: '1.0',
        description: 'Provide credentials for services',
      ));
    }
    
    return Result.success();
  }
  
  @override
  Future<Result> onStop() async {
    _running = false;
    
    if (_context != null) {
      await _context!.eventBus.unsubscribeAll();
      await _context!.registry.unregisterAll();
    }
    
    return Result.success();
  }
  
  @override
  Future<Result> onUnload() async {
    _context = null;
    return Result.success();
  }
  
  @override
  List<Capability> get capabilities => [
    Capability(
      name: 'credential_provider',
      version: '1.0',
      description: 'Provide credentials for services',
    )
  ];
  
  @override
  Future<Result> handleEvent(Event event) async {
    if (event.type == 'credential/request') {
      return _handleCredentialRequest(event);
    }
    return Result.success();
  }
  
  Future<Result> _handleCredentialRequest(Event event) async {
    if (_context == null) return Result.error('Not initialized');
    
    // 处理凭证请求
    final request = event.data as CredentialRequest;
    
    // 从密码箱获取凭证
    final credential = await _context!.vault.get(request.serviceUrl);
    
    // 返回凭证
    await _context!.eventBus.publish('credential/response', credential);
    
    return Result.success();
  }
}
```

---

## 🔌 插件 API 参考

### 核心 API

#### Context (上下文)

```cpp
namespace polyvault {

class Context {
public:
    // 配置管理
    Config& config();
    const Config& config() const;
    
    // 事件总线
    EventBus& eventBus();
    const EventBus& eventBus() const;
    
    // 密码箱访问
    Vault& vault();
    const Vault& vault() const;
    
    // 认证系统
    Auth& auth();
    const Auth& auth() const;
    
    // 能力注册
    Registry& registry();
    const Registry& registry() const;
    
    // 日志
    Logger& logger();
    const Logger& logger() const;
    
    // 文件系统
    FileSystem& fs();
    const FileSystem& fs() const;
};

}
```

#### EventBus (事件总线)

```cpp
namespace polyvault {

class EventBus {
public:
    // 订阅事件
    std::string subscribe(const std::string& topic, EventCallback callback);
    
    // 取消订阅
    bool unsubscribe(const std::string& subscription_id);
    bool unsubscribeAll();
    
    // 发布事件
    Result publish(const std::string& topic, const Event& event);
    
    // 请求/响应
    Future<Event> request(const std::string& topic, const Event& request, 
                          int timeout_ms = 5000);
};

}
```

#### Vault (密码箱)

```cpp
namespace polyvault {

class Vault {
public:
    // 获取凭证
    Future<Credential> get(const std::string& service_url);
    
    // 存储凭证
    Result put(const Credential& credential);
    
    // 删除凭证
    Result remove(const std::string& service_url);
    
    // 列出凭证
    std::vector<CredentialInfo> list();
    
    // 搜索凭证
    std::vector<CredentialInfo> search(const std::string& query);
};

}
```

#### Registry (能力注册)

```cpp
namespace polyvault {

class Registry {
public:
    // 注册能力
    Result registerCapability(const Capability& capability);
    
    // 注销能力
    Result unregisterCapability(const std::string& capability_name);
    Result unregisterAll();
    
    // 查询能力
    std::optional<Capability> getCapability(const std::string& name) const;
    std::vector<Capability> listCapabilities() const;
    
    // 发现能力
    std::vector<Capability> discoverCapabilities(const CapabilityQuery& query) const;
};

}
```

---

## 📚 插件示例

### 示例 1: 凭证提供者插件

```cpp
// credential-provider-plugin.cpp
#include <polyvault/plugin.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

class CredentialProviderPlugin : public polyvault::IPlugin {
public:
    polyvault::PluginMetadata metadata() const override {
        return {
            .id = "com.example.credential-provider",
            .name = "Credential Provider",
            .version = "1.0.0",
            .author = "Example Corp",
            .description = "Provide credentials from external vault",
        };
    }
    
    polyvault::Result onLoad(const polyvault::Context& ctx) override {
        context_ = ctx;
        
        // 配置外部密码箱连接
        auto config = context_.config();
        config.registerOption("external_vault_url", "");
        config.registerOption("external_vault_token", "");
        
        return polyvault::Result::Success();
    }
    
    polyvault::Result onStart() override {
        // 订阅凭证请求
        context_.eventBus().subscribe("credential/request", 
            [this](const auto& event) {
                handleCredentialRequest(event);
            });
        
        // 注册能力
        context_.registry().registerCapability({
            .name = "external_credential_provider",
            .version = "1.0",
            .description = "Provide credentials from external vault",
        });
        
        return polyvault::Result::Success();
    }
    
private:
    polyvault::Context context_;
    
    polyvault::Result handleCredentialRequest(const polyvault::Event& event) {
        auto request = event.data<polyvault::CredentialRequest>();
        
        // 从外部密码箱获取凭证
        auto external_vault_url = context_.config().get<std::string>("external_vault_url");
        auto token = context_.config().get<std::string>("external_vault_token");
        
        // HTTP 请求到外部密码箱
        auto credential = fetchFromExternalVault(external_vault_url, token, request.service_url());
        
        // 返回凭证
        context_.eventBus().publish("credential/response", credential);
        
        return polyvault::Result::Success();
    }
    
    polyvault::Credential fetchFromExternalVault(const std::string& url, 
                                                  const std::string& token,
                                                  const std::string& service_url) {
        // 实现外部 API 调用
        // ...
        return polyvault::Credential();
    }
};

extern "C" POLYVAULT_PLUGIN_EXPORT polyvault::IPlugin* create_plugin() {
    return new CredentialProviderPlugin();
}

extern "C" POLYVAULT_PLUGIN_EXPORT void destroy_plugin(polyvault::IPlugin* plugin) {
    delete plugin;
}
```

---

### 示例 2: 事件处理器插件

```rust
// event-handler-plugin.rs
use polyvault_sdk::{Plugin, PluginMetadata, Context, Result, Capability, Event};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
struct AuditEvent {
    event_type: String,
    timestamp: u64,
    user_id: String,
    action: String,
}

pub struct EventHandlerPlugin {
    context: Option<Context>,
}

impl Plugin for EventHandlerPlugin {
    fn metadata(&self) -> PluginMetadata {
        PluginMetadata {
            id: "com.example.event-handler".to_string(),
            name: "Event Handler".to_string(),
            version: "1.0.0".to_string(),
            author: "Example Corp".to_string(),
            description: "Handle and audit events".to_string(),
        }
    }
    
    fn on_start(&mut self) -> Result<()> {
        if let Some(ctx) = &self.context {
            // 订阅所有事件
            ctx.event_bus().subscribe("*", |event| {
                self.handle_event(event);
            })?;
            
            // 注册能力
            ctx.registry().register(Capability {
                name: "event_auditor".to_string(),
                version: "1.0".to_string(),
                description: "Audit all events".to_string(),
            })?;
        }
        
        Ok(())
    }
    
    fn handle_event(&self, event: Event) -> Result<()> {
        if let Some(ctx) = &self.context {
            // 创建审计事件
            let audit_event = AuditEvent {
                event_type: event.event_type().clone(),
                timestamp: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_secs(),
                user_id: event.user_id().unwrap_or("unknown".to_string()),
                action: format!("Event: {}", event.event_type()),
            };
            
            // 记录审计日志
            ctx.logger().info(&format!("Audit: {:?}", audit_event));
            
            // 存储到数据库
            ctx.fs().write(
                &format!("audit/{}.json", audit_event.timestamp),
                &serde_json::to_string(&audit_event)?,
            )?;
        }
        
        Ok(())
    }
}

// 插件工厂
#[no_mangle]
pub extern "C" fn create_plugin() -> *mut dyn Plugin {
    Box::into_raw(Box::new(EventHandlerPlugin {
        context: None,
    }))
}

#[no_mangle]
pub extern "C" fn destroy_plugin(plugin: *mut dyn Plugin) {
    unsafe {
        let _ = Box::from_raw(plugin);
    }
}
```

---

## 🐛 调试与测试

### 调试模式

#### 启用调试日志

```yaml
# plugin.yaml
config:
  - name: debug_mode
    type: boolean
    default: false
    description: Enable debug logging
```

```cpp
// 在插件中
if (context_.config().get<bool>("debug_mode")) {
    context_.logger().setLevel(polyvault::LogLevel::Debug);
}

context_.logger().debug("Debug message");
context_.logger().info("Info message");
context_.logger().warn("Warning message");
context_.logger().error("Error message");
```

---

### 单元测试

#### C++ 测试

```cpp
// tests/test_plugin.cpp
#include <gtest/gtest.h>
#include "../src/plugin.h"

class MyPluginTest : public ::testing::Test {
protected:
    void SetUp() override {
        plugin = std::make_unique<MyPlugin>();
    }
    
    void TearDown() override {
        plugin.reset();
    }
    
    std::unique_ptr<MyPlugin> plugin;
};

TEST_F(MyPluginTest, Metadata_ReturnsCorrectInfo) {
    auto metadata = plugin->metadata();
    
    EXPECT_EQ(metadata.id, "com.example.my-plugin");
    EXPECT_EQ(metadata.name, "My Plugin");
    EXPECT_EQ(metadata.version, "1.0.0");
}

TEST_F(MyPluginTest, OnLoad_InitializesSuccessfully) {
    polyvault::Context ctx = createMockContext();
    
    auto result = plugin->onLoad(ctx);
    
    EXPECT_TRUE(result.isSuccess());
}

TEST_F(MyPluginTest, HandleEvent_ProcessesCredentialRequest) {
    // 准备测试事件
    polyvault::Event event("credential/request");
    event.setData(polyvault::CredentialRequest{
        .service_url = "https://example.com",
    });
    
    // 执行测试
    auto result = plugin->handleEvent(event);
    
    // 验证结果
    EXPECT_TRUE(result.isSuccess());
}
```

---

### 集成测试

```cpp
// tests/integration_test.cpp
#include <gtest/gtest.h>
#include <polyvault/test.h>

class IntegrationTest : public ::testing::Test {
protected:
    void SetUp() override {
        // 启动测试环境
        test_env = polyvault::test::createTestEnvironment();
        test_env->start();
    }
    
    void TearDown() override {
        test_env->stop();
    }
    
    std::unique_ptr<polyvault::test::TestEnvironment> test_env;
};

TEST_F(IntegrationTest, PluginRegistersSuccessfully) {
    // 加载插件
    auto plugin = test_env->loadPlugin("com.example.my-plugin");
    
    // 验证插件加载成功
    ASSERT_TRUE(plugin != nullptr);
    
    // 启动插件
    auto result = test_env->startPlugin(plugin);
    EXPECT_TRUE(result.isSuccess());
    
    // 验证能力注册
    auto capabilities = test_env->listCapabilities();
    EXPECT_TRUE(std::any_of(capabilities.begin(), capabilities.end(),
        [](const auto& cap) {
            return cap.name == "credential_provider";
        }));
}
```

---

## 📦 发布与分发

### 1. 打包插件

#### 创建插件包

```bash
# 使用 CLI 工具
polyvault plugin:package my-plugin/

# 输出: my-plugin-1.0.0.pvp (PolyVault Plugin)
```

#### 插件包结构

```
my-plugin-1.0.0.pvp
├── plugin.yaml           # 清单文件
├── plugin.sig            # 签名文件
├── lib/
│   ├── linux/
│   │   └── libmy_plugin.so
│   ├── darwin/
│   │   └── libmy_plugin.dylib
│   └── win32/
│       └── my_plugin.dll
├── include/
│   └── my_plugin.h
└── README.md
```

---

### 2. 签名插件

```bash
# 生成密钥对
polyvault key:generate --output ~/.polyvault/keys/my-key

# 签名插件
polyvault plugin:sign my-plugin-1.0.0.pvp --key ~/.polyvault/keys/my-key

# 验证签名
polyvault plugin:verify my-plugin-1.0.0.pvp
```

---

### 3. 发布到插件市场

```bash
# 发布插件
polyvault plugin:publish my-plugin-1.0.0.pvp \
  --repository https://plugins.polyvault.io \
  --token $POLYVAULT_PLUGIN_TOKEN

# 查看发布状态
polyvault plugin:status com.example.my-plugin
```

---

### 4. 安装插件

```bash
# 从市场安装
polyvault plugin:install com.example.my-plugin

# 从文件安装
polyvault plugin:install my-plugin-1.0.0.pvp

# 列出已安装插件
polyvault plugin:list

# 卸载插件
polyvault plugin:uninstall com.example.my-plugin
```

---

## 📞 支持与反馈

### 获取帮助

- **文档**: https://docs.polyvault.io/plugins
- **论坛**: https://forum.polyvault.io
- **Discord**: https://discord.gg/polyvault
- **GitHub Issues**: https://github.com/polyvault/sdk/issues

### 提交插件

- **插件市场**: https://plugins.polyvault.io/submit
- **审核指南**: https://docs.polyvault.io/plugins/review-guidelines

---

**文档维护**: PolyVault Core Team  
**反馈邮箱**: dev@polyvault.io  
**最后更新**: 2026-03-15
