# PolyVault 插件化架构设计分析

**版本**: v1.0  
**日期**: 2026-03-14  
**作者**: devops-engineer  
**背景**: 杨哥提出的插件化架构方案

---

## 📋 概述

### 核心思想

将 PolyVault 重构为**主项目 + 插件生态**架构：

```
┌─────────────────────────────────────────────────────────┐
│                    主项目 (Core)                         │
│  ┌─────────────┬─────────────┬─────────────┐           │
│  │ 软总线核心   │   密码箱    │  鉴权系统   │           │
│  │ (eCAL Hub)  │ (zk_vault)  │ (Auth)      │           │
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
│ │ Flutter  │     │  Agent   │     │ 物联网端  │        │
│ │ Client   │     │  Plugin  │     │ Plugin   │        │
│ │ Plugin   │     │          │     │          │        │
│ └──────────┘     └──────────┘     └──────────┘        │
│                                                        │
│                    插件生态                             │
└─────────────────────────────────────────────────────────┘
```

---

## 1️⃣ 插件接口设计

### 1.1 Plugin API 规范

#### 核心接口定义

```protobuf
// protos/plugin.proto

syntax = "proto3";
package polyvault.plugin;

// 插件元数据
message PluginMetadata {
    string plugin_id = 1;           // 唯一标识
    string plugin_name = 2;         // 显示名称
    string plugin_version = 3;      // 版本号 (semver)
    string author = 4;              // 作者
    string description = 5;         // 描述
    repeated string permissions = 6; // 请求的权限
    PluginType type = 7;            // 插件类型
    string min_core_version = 8;    // 最低核心版本
    string entry_point = 9;         // 入口点
}

enum PluginType {
    PLUGIN_TYPE_UNSPECIFIED = 0;
    PLUGIN_TYPE_CLIENT = 1;         // 客户端插件 (Flutter)
    PLUGIN_TYPE_AGENT = 2;          // Agent 插件
    PLUGIN_TYPE_IOT = 3;            // 物联网插件
    PLUGIN_TYPE_EXTENSION = 4;      // 扩展插件
}

// 插件生命周期事件
enum PluginLifecycle {
    LIFECYCLE_UNSPECIFIED = 0;
    LIFECYCLE_LOAD = 1;             // 加载
    LIFECYCLE_START = 2;            // 启动
    LIFECYCLE_STOP = 3;             // 停止
    LIFECYCLE_UNLOAD = 4;           // 卸载
    LIFECYCLE_ERROR = 5;            // 错误
}

// 插件状态
message PluginState {
    string plugin_id = 1;
    PluginLifecycle lifecycle = 2;
    string status_message = 3;
    uint64 start_time = 4;
    uint64 last_heartbeat = 5;
    map<string, string> metrics = 6;
}

// 插件注册请求
message PluginRegisterRequest {
    PluginMetadata metadata = 1;
    bytes signature = 2;            // 插件签名
    string api_version = 3;
}

message PluginRegisterResponse {
    bool success = 1;
    string session_token = 2;       // 会话令牌
    uint32 permissions_granted = 3; // 授予的权限位掩码
    string error_message = 4;
}
```

#### 核心服务接口

```protobuf
// 插件核心服务 - 由主项目提供
service PluginHostService {
    // 生命周期管理
    rpc Register(PluginRegisterRequest) returns (PluginRegisterResponse);
    rpc Unregister(PluginUnregisterRequest) returns (PluginUnregisterResponse);
    rpc Heartbeat(PluginHeartbeatRequest) returns (PluginHeartbeatResponse);
    
    // 能力查询
    rpc GetCapabilities(GetCapabilitiesRequest) returns (GetCapabilitiesResponse);
    rpc SubscribeCapabilities(CapabilitySubscriptionRequest) 
        returns (stream CapabilityEvent);
    
    // 事件总线
    rpc PublishEvent(PublishEventRequest) returns (PublishEventResponse);
    rpc SubscribeEvents(SubscribeEventsRequest) returns (stream PluginEvent);
}

// 插件服务 - 由插件实现
service PluginService {
    // 生命周期回调
    rpc OnLoad(OnLoadRequest) returns (OnLoadResponse);
    rpc OnStart(OnStartRequest) returns (OnStartResponse);
    rpc OnStop(OnStopRequest) returns (OnStopResponse);
    rpc OnUnload(OnUnloadRequest) returns (OnUnloadResponse);
    
    // 能力提供
    rpc GetProvidedCapabilities(Empty) returns (ProvidedCapabilitiesResponse);
    
    // 事件处理
    rpc HandleEvent(PluginEvent) returns (HandleEventResponse);
}
```

### 1.2 插件生命周期管理

#### 状态机设计

```
┌─────────────────────────────────────────────────────────┐
│                  插件生命周期状态机                       │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                     ┌──────────┐                        │
│                     │  NONE    │                        │
│                     └────┬─────┘                        │
│                          │ register()                   │
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

#### 生命周期管理实现

```rust
// src/plugin/manager.rs

pub struct PluginManager {
    plugins: HashMap<PluginId, PluginInstance>,
    capability_registry: CapabilityRegistry,
    event_bus: EventBus,
    security_context: SecurityContext,
}

impl PluginManager {
    /// 加载插件
    pub async fn load_plugin(&mut self, manifest: PluginManifest) 
        -> Result<PluginId, PluginError> 
    {
        // 1. 验证插件签名
        self.verify_signature(&manifest)?;
        
        // 2. 检查版本兼容性
        self.check_version_compatibility(&manifest)?;
        
        // 3. 解析权限请求
        let permissions = self.resolve_permissions(&manifest)?;
        
        // 4. 创建沙箱环境
        let sandbox = self.create_sandbox(&manifest, permissions)?;
        
        // 5. 加载插件代码
        let instance = sandbox.load_instance(&manifest).await?;
        
        // 6. 注册能力
        self.capability_registry.register(&instance);
        
        // 7. 调用 OnLoad 回调
        instance.on_load().await?;
        
        Ok(instance.id())
    }
    
    /// 启动插件
    pub async fn start_plugin(&mut self, plugin_id: &PluginId) 
        -> Result<(), PluginError> 
    {
        let instance = self.plugins.get_mut(plugin_id)
            .ok_or(PluginError::NotFound)?;
        
        // 状态检查
        if instance.state != PluginState::Loaded {
            return Err(PluginError::InvalidState);
        }
        
        // 调用 OnStart 回调
        instance.on_start().await?;
        
        // 更新状态
        instance.state = PluginState::Started;
        
        // 启动心跳监控
        self.start_heartbeat_monitor(plugin_id);
        
        Ok(())
    }
    
    /// 停止插件
    pub async fn stop_plugin(&mut self, plugin_id: &PluginId) 
        -> Result<(), PluginError> 
    {
        let instance = self.plugins.get_mut(plugin_id)
            .ok_or(PluginError::NotFound)?;
        
        // 调用 OnStop 回调
        instance.on_stop().await?;
        
        // 更新状态
        instance.state = PluginState::Stopped;
        
        // 停止心跳监控
        self.stop_heartbeat_monitor(plugin_id);
        
        Ok(())
    }
    
    /// 卸载插件
    pub async fn unload_plugin(&mut self, plugin_id: &PluginId) 
        -> Result<(), PluginError> 
    {
        let mut instance = self.plugins.remove(plugin_id)
            .ok_or(PluginError::NotFound)?;
        
        // 停止插件（如果正在运行）
        if instance.state == PluginState::Started {
            instance.on_stop().await?;
        }
        
        // 调用 OnUnload 回调
        instance.on_unload().await?;
        
        // 注销能力
        self.capability_registry.unregister(plugin_id);
        
        // 清理沙箱
        instance.sandbox.cleanup().await?;
        
        Ok(())
    }
}
```

### 1.3 插件隔离与沙箱

#### 沙箱架构

```
┌─────────────────────────────────────────────────────────┐
│                    沙箱架构                              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              主项目进程                          │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐   │   │
│  │  │ Plugin    │  │ Plugin    │  │ Plugin    │   │   │
│  │  │ Manager   │  │ Registry  │  │ Sandbox   │   │   │
│  │  └───────────┘  └───────────┘  └───────────┘   │   │
│  │        │              │              │          │   │
│  │        └──────────────┼──────────────┘          │   │
│  │                       │                         │   │
│  │              ┌────────▼────────┐                │   │
│  │              │  IPC Bridge     │                │   │
│  │              │  (gRPC/FFI)     │                │   │
│  │              └────────┬────────┘                │   │
│  └───────────────────────┼─────────────────────────┘   │
│                          │                             │
│  ┌───────────────────────┼─────────────────────────┐   │
│  │                       │                         │   │
│  │              ┌────────▼────────┐                │   │
│  │              │   Plugin        │                │   │
│  │              │   Process       │                │   │
│  │              │  ┌───────────┐  │                │   │
│  │              │  │ 沙箱限制  │  │                │   │
│  │              │  │ - 文件访问│  │                │   │
│  │              │  │ - 网络访问│  │                │   │
│  │              │  │ - API调用 │  │                │   │
│  │              │  └───────────┘  │                │   │
│  │              └─────────────────┘                │   │
│  │                   插件进程                       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 沙箱配置示例

```json
{
  "plugin_id": "com.polyvault.flutter-client",
  "sandbox": {
    "process_isolation": true,
    "namespace_isolation": true,
    
    "resource_limits": {
      "max_memory_mb": 512,
      "max_cpu_percent": 50,
      "max_file_descriptors": 100,
      "max_network_connections": 10
    },
    
    "filesystem": {
      "read_only": ["/app/config", "/app/protos"],
      "read_write": ["/app/data/plugin", "/tmp/plugin"],
      "denied": ["/etc", "/root", "/home"]
    },
    
    "network": {
      "allowed_hosts": ["localhost", "*.polyvault.local"],
      "allowed_ports": [8080, 9090],
      "denied": ["*:*"]
    },
    
    "api_access": {
      "credential_vault": "read_only",
      "auth_system": "request_only",
      "event_bus": "full"
    }
  }
}
```

---

## 2️⃣ 安全边界设计

### 2.1 插件权限模型

#### 权限分级

```
┌─────────────────────────────────────────────────────────┐
│                  权限金字塔                              │
│                                                         │
│                    ┌─────────┐                          │
│                    │ P4 核心 │ 完全信任                 │
│                    │         │ (官方插件)               │
│                    └─────────┘                          │
│                 ┌───────────────┐                       │
│                 │  P3 高级权限  │ 高信任                │
│                 │  (凭证写入)   │                       │
│                 └───────────────┘                       │
│              ┌─────────────────────┐                    │
│              │    P2 中级权限      │ 中信任             │
│              │    (凭证读取)       │                    │
│              └─────────────────────┘                    │
│           ┌───────────────────────────┐                 │
│           │       P1 基础权限         │ 低信任          │
│           │    (事件订阅/能力发现)    │                 │
│           └───────────────────────────┘                 │
│        ┌─────────────────────────────────┐              │
│        │        P0 无权限               │              │
│        │      (仅注册/心跳)             │              │
│        └─────────────────────────────────┘              │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 权限定义

```protobuf
// 权限位掩码定义
enum Permission {
    PERMISSION_NONE = 0;
    
    // P1 基础权限
    PERMISSION_EVENT_SUBSCRIBE = 1;      // 订阅事件
    PERMISSION_EVENT_PUBLISH = 2;        // 发布事件
    PERMISSION_CAPABILITY_DISCOVER = 4;  // 发现能力
    
    // P2 中级权限
    PERMISSION_CREDENTIAL_READ = 8;      // 读取凭证
    PERMISSION_CREDENTIAL_LIST = 16;     // 列出凭证
    
    // P3 高级权限
    PERMISSION_CREDENTIAL_WRITE = 32;    // 写入凭证
    PERMISSION_CREDENTIAL_DELETE = 64;   // 删除凭证
    
    // P4 核心权限
    PERMISSION_AUTH_BYPASS = 128;        // 绕过认证
    PERMISSION_SYSTEM_ADMIN = 256;       // 系统管理
    PERMISSION_PLUGIN_MANAGE = 512;      // 插件管理
}

// 权限组
message PermissionGroup {
    string name = 1;
    uint32 permissions = 2;
    string description = 3;
}

// 预定义权限组
enum PermissionGroupType {
    PERMISSION_GROUP_VIEWER = 0;    // 只读访问
    PERMISSION_GROUP_EDITOR = 1;    // 编辑权限
    PERMISSION_GROUP_ADMIN = 2;     // 管理权限
    PERMISSION_GROUP_SYSTEM = 3;    // 系统权限
}
```

#### 权限验证流程

```rust
// src/security/permission.rs

pub struct PermissionManager {
    granted_permissions: HashMap<PluginId, PermissionSet>,
    permission_requests: HashMap<PluginId, Vec<PermissionRequest>>,
}

impl PermissionManager {
    /// 检查权限
    pub fn check_permission(
        &self,
        plugin_id: &PluginId,
        permission: Permission,
    ) -> Result<(), PermissionError> 
    {
        let granted = self.granted_permissions.get(plugin_id)
            .ok_or(PermissionError::NotRegistered)?;
        
        if !granted.has(permission) {
            return Err(PermissionError::Denied {
                required: permission,
                granted: granted.clone(),
            });
        }
        
        Ok(())
    }
    
    /// 请求权限升级
    pub async fn request_permission_upgrade(
        &mut self,
        plugin_id: &PluginId,
        permission: Permission,
        context: PermissionContext,
    ) -> Result<bool, PermissionError> 
    {
        // 1. 检查是否已授予
        if let Some(granted) = self.granted_permissions.get(plugin_id) {
            if granted.has(permission) {
                return Ok(true);
            }
        }
        
        // 2. 评估风险等级
        let risk_level = self.evaluate_risk(permission, &context);
        
        // 3. 根据风险等级决定授权方式
        match risk_level {
            RiskLevel::Low => {
                // 自动授权
                self.grant_permission(plugin_id, permission);
                Ok(true)
            }
            RiskLevel::Medium => {
                // 需要用户确认
                let approved = self.request_user_approval(
                    plugin_id, 
                    permission, 
                    &context
                ).await?;
                if approved {
                    self.grant_permission(plugin_id, permission);
                }
                Ok(approved)
            }
            RiskLevel::High => {
                // 需要生物认证
                let approved = self.request_biometric_approval(
                    plugin_id,
                    permission,
                    &context
                ).await?;
                if approved {
                    self.grant_permission(plugin_id, permission);
                }
                Ok(approved)
            }
            RiskLevel::Critical => {
                // 需要 K 宝 + 生物认证
                let approved = self.request_hardware_approval(
                    plugin_id,
                    permission,
                    &context
                ).await?;
                if approved {
                    self.grant_permission(plugin_id, permission);
                }
                Ok(approved)
            }
        }
    }
}
```

### 2.2 密码箱访问控制

#### 访问控制矩阵

```
┌─────────────────────────────────────────────────────────┐
│              密码箱访问控制矩阵                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  插件类型        │ 读取凭证 │ 写入凭证 │ 删除凭证 │ 管理 │
│  ────────────────────────────────────────────────────  │
│  Flutter Client  │   ✅     │   ✅     │   ✅     │  ❌  │
│  Agent Plugin    │   ✅     │   ❌     │   ❌     │  ❌  │
│  IoT Plugin      │   ✅*    │   ❌     │   ❌     │  ❌  │
│  Extension       │   ✅     │   ❌     │   ❌     │  ❌  │
│  Unknown         │   ❌     │   ❌     │   ❌     │  ❌  │
│                                                         │
│  * IoT Plugin 需要额外的时间限制访问                    │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 凭证访问审计

```rust
// src/vault/access_control.rs

pub struct VaultAccessController {
    vault: Arc<CredentialVault>,
    audit_log: AuditLogger,
    rate_limiter: RateLimiter,
}

impl VaultAccessController {
    /// 读取凭证（带审计）
    pub async fn read_credential(
        &self,
        plugin_id: &PluginId,
        credential_id: &CredentialId,
        context: AccessContext,
    ) -> Result<Credential, VaultError> 
    {
        // 1. 检查权限
        self.check_read_permission(plugin_id)?;
        
        // 2. 检查速率限制
        self.rate_limiter.check_rate(plugin_id, "read")?;
        
        // 3. 记录审计日志
        self.audit_log.log(AuditEvent {
            event_type: AuditEventType::CredentialRead,
            plugin_id: plugin_id.clone(),
            credential_id: credential_id.clone(),
            timestamp: SystemTime::now(),
            context: context.clone(),
            result: AuditResult::Pending,
        });
        
        // 4. 执行读取
        let result = self.vault.read(credential_id).await;
        
        // 5. 更新审计结果
        self.audit_log.update_result(
            credential_id,
            if result.is_ok() { AuditResult::Success } 
            else { AuditResult::Failure }
        );
        
        result
    }
}
```

### 2.3 数据隔离机制

#### 数据隔离架构

```
┌─────────────────────────────────────────────────────────┐
│                  数据隔离架构                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                主项目数据存储                    │   │
│  │  ┌─────────────┬─────────────┬─────────────┐   │   │
│  │  │ 密码箱      │ 鉴权数据    │ 系统配置    │   │   │
│  │  │ (加密)      │ (加密)      │ (明文)      │   │   │
│  │  └─────────────┴─────────────┴─────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│                          │                             │
│                          │ 隔离层                      │
│                          ▼                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │                插件数据存储                      │   │
│  │  ┌─────────────┬─────────────┬─────────────┐   │   │
│  │  │ Plugin A    │ Plugin B    │ Plugin C    │   │   │
│  │  │ 数据区      │ 数据区      │ 数据区      │   │   │
│  │  │ (隔离)      │ (隔离)      │ (隔离)      │   │   │
│  │  └─────────────┴─────────────┴─────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 数据隔离实现

```rust
// src/storage/isolation.rs

pub struct IsolatedStorage {
    base_path: PathBuf,
    plugin_stores: HashMap<PluginId, PluginStorage>,
}

impl IsolatedStorage {
    /// 获取插件专属存储
    pub fn get_plugin_storage(&mut self, plugin_id: &PluginId) 
        -> Result<PluginStorage, StorageError> 
    {
        if let Some(storage) = self.plugin_stores.get(plugin_id) {
            return Ok(storage.clone());
        }
        
        // 创建隔离存储目录
        let plugin_path = self.base_path.join("plugins").join(plugin_id.as_str());
        fs::create_dir_all(&plugin_path)?;
        
        // 设置权限（仅插件可访问）
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            fs::set_permissions(&plugin_path, fs::Permissions::from_mode(0o700))?;
        }
        
        let storage = PluginStorage::new(plugin_path)?;
        self.plugin_stores.insert(plugin_id.clone(), storage.clone());
        
        Ok(storage)
    }
}

/// 插件存储（隔离）
pub struct PluginStorage {
    path: PathBuf,
    encryption_key: Option<[u8; 32]>,
}

impl PluginStorage {
    /// 写入数据（加密）
    pub async fn write(&self, key: &str, data: &[u8]) -> Result<(), StorageError> {
        let encrypted = if let Some(enc_key) = &self.encryption_key {
            encrypt(data, enc_key)?
        } else {
            data.to_vec()
        };
        
        let file_path = self.path.join(key);
        fs::write(&file_path, encrypted)?;
        
        Ok(())
    }
    
    /// 读取数据（解密）
    pub async fn read(&self, key: &str) -> Result<Vec<u8>, StorageError> {
        let file_path = self.path.join(key);
        let encrypted = fs::read(&file_path)?;
        
        let decrypted = if let Some(enc_key) = &self.encryption_key {
            decrypt(&encrypted, enc_key)?
        } else {
            encrypted
        };
        
        Ok(decrypted)
    }
}
```

---

## 3️⃣ 技术实现方案

### 3.1 插件加载机制

#### 加载流程

```
┌─────────────────────────────────────────────────────────┐
│                  插件加载流程                            │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  1. 发现插件                                             │
│     ┌─────────────────────────────────────────┐        │
│     │ 扫描插件目录                             │        │
│     │ - /app/plugins/                         │        │
│     │ - ~/.polyvault/plugins/                 │        │
│     │ - 环境变量指定                           │        │
│     └────────────────┬────────────────────────┘        │
│                      ▼                                  │
│  2. 解析清单                                             │
│     ┌─────────────────────────────────────────┐        │
│     │ 读取 plugin.yaml                         │        │
│     │ 验证格式                                 │        │
│     │ 检查依赖                                 │        │
│     └────────────────┬────────────────────────┘        │
│                      ▼                                  │
│  3. 验证签名                                             │
│     ┌─────────────────────────────────────────┐        │
│     │ 验证开发者签名                           │        │
│     │ 检查证书链                               │        │
│     │ 验证时间戳                               │        │
│     └────────────────┬────────────────────────┘        │
│                      ▼                                  │
│  4. 创建沙箱                                             │
│     ┌─────────────────────────────────────────┐        │
│     │ 分配资源                                 │        │
│     │ 设置权限                                 │        │
│     │ 配置隔离                                 │        │
│     └────────────────┬────────────────────────┘        │
│                      ▼                                  │
│  5. 加载代码                                             │
│     ┌─────────────────────────────────────────┐        │
│     │ 加载动态库 (.so/.dll/.dylib)             │        │
│     │ 或启动独立进程                           │        │
│     └────────────────┬────────────────────────┘        │
│                      ▼                                  │
│  6. 注册服务                                             │
│     ┌─────────────────────────────────────────┐        │
│     │ 注册 RPC 服务                            │        │
│     │ 注册能力                                 │        │
│     │ 订阅事件                                 │        │
│     └────────────────┬────────────────────────┘        │
│                      ▼                                  │
│  7. 启动插件                                             │
│     ┌─────────────────────────────────────────┐        │
│     │ 调用 OnStart()                           │        │
│     │ 启动心跳                                 │        │
│     │ 更新状态                                 │        │
│     └─────────────────────────────────────────┘        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 加载器实现

```rust
// src/plugin/loader.rs

pub struct PluginLoader {
    config: PluginConfig,
    signer: PluginSigner,
    sandbox_factory: SandboxFactory,
}

impl PluginLoader {
    /// 加载插件包
    pub async fn load_from_package(
        &self,
        package_path: &Path,
    ) -> Result<LoadedPlugin, PluginError> 
    {
        // 1. 解压插件包
        let temp_dir = tempfile::tempdir()?;
        self.extract_package(package_path, temp_dir.path())?;
        
        // 2. 解析清单
        let manifest = self.parse_manifest(temp_dir.path())?;
        
        // 3. 验证签名
        self.verify_signature(temp_dir.path(), &manifest)?;
        
        // 4. 创建沙箱
        let sandbox = self.sandbox_factory.create(&manifest)?;
        
        // 5. 加载代码
        let code_path = temp_dir.path().join(&manifest.entry_point);
        let instance = sandbox.load(&code_path).await?;
        
        // 6. 初始化插件
        instance.initialize(&manifest).await?;
        
        Ok(LoadedPlugin {
            manifest,
            instance,
            sandbox,
        })
    }
    
    /// 解析插件清单
    fn parse_manifest(&self, plugin_dir: &Path) -> Result<PluginManifest, PluginError> {
        let manifest_path = plugin_dir.join("plugin.yaml");
        let content = fs::read_to_string(manifest_path)?;
        let manifest: PluginManifest = serde_yaml::from_str(&content)?;
        
        // 验证必需字段
        if manifest.id.is_empty() {
            return Err(PluginError::InvalidManifest("missing id".into()));
        }
        if manifest.entry_point.is_empty() {
            return Err(PluginError::InvalidManifest("missing entry_point".into()));
        }
        
        Ok(manifest)
    }
    
    /// 验证插件签名
    fn verify_signature(
        &self,
        plugin_dir: &Path,
        manifest: &PluginManifest,
    ) -> Result<(), PluginError> 
    {
        let signature_path = plugin_dir.join("plugin.sig");
        if !signature_path.exists() {
            // 未签名插件，检查是否允许
            if !self.config.allow_unsigned {
                return Err(PluginError::Unsigned);
            }
            return Ok(());
        }
        
        let signature = fs::read(signature_path)?;
        let code = fs::read(plugin_dir.join(&manifest.entry_point))?;
        
        self.signer.verify(&code, &signature, &manifest.author)?;
        
        Ok(())
    }
}
```

### 3.2 版本兼容性

#### 版本约束系统

```yaml
# plugin.yaml - 插件清单示例
id: com.polyvault.flutter-client
name: Flutter Client
version: 1.0.0
author: PolyVault Team

# 核心版本约束
core_version: ">=0.5.0,<1.0.0"

# API 版本约束
api_version: "1.0"

# 依赖其他插件
dependencies:
  - id: com.polyvault.auth
    version: ">=0.3.0"
  - id: com.polyvault.vault
    version: "~0.4.0"

# 提供的能力
provides:
  - capability: credential_provider
    version: "1.0"
  - capability: biometric_auth
    version: "1.0"

# 需要的能力
requires:
  - capability: credential_vault
    version: ">=1.0"
  - capability: event_bus
    version: ">=1.0"
```

#### 版本检查实现

```rust
// src/plugin/version.rs

use semver::{Version, VersionReq};

pub struct VersionChecker;

impl VersionChecker {
    /// 检查插件与核心的兼容性
    pub fn check_compatibility(
        core_version: &Version,
        plugin_manifest: &PluginManifest,
    ) -> Result<CompatibilityReport, VersionError> 
    {
        let mut report = CompatibilityReport::default();
        
        // 1. 检查核心版本
        let core_req = VersionReq::parse(&plugin_manifest.core_version)?;
        if core_req.matches(core_version) {
            report.core_compatible = true;
        } else {
            report.errors.push(format!(
                "Core version {} does not satisfy requirement {}",
                core_version, plugin_manifest.core_version
            ));
        }
        
        // 2. 检查 API 版本
        // ...
        
        // 3. 检查依赖
        for dep in &plugin_manifest.dependencies {
            let dep_req = VersionReq::parse(&dep.version)?;
            // 检查依赖是否已安装且版本满足
            report.dependencies.push(DependencyCheck {
                id: dep.id.clone(),
                required: dep.version.clone(),
                satisfied: false, // 实际检查逻辑
            });
        }
        
        Ok(report)
    }
}

#[derive(Default)]
pub struct CompatibilityReport {
    pub core_compatible: bool,
    pub api_compatible: bool,
    pub dependencies: Vec<DependencyCheck>,
    pub errors: Vec<String>,
}
```

### 3.3 热插拔支持

#### 热插拔架构

```
┌─────────────────────────────────────────────────────────┐
│                  热插拔架构                              │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              插件状态管理器                      │   │
│  │  ┌───────────────────────────────────────────┐  │   │
│  │  │ 状态持久化                                │  │   │
│  │  │ - 插件状态                                │  │   │
│  │  │ - 会话数据                                │  │   │
│  │  │ - 订阅关系                                │  │   │
│  │  └───────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────┘   │
│                          │                             │
│                          ▼                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │              热插拔控制器                        │   │
│  │  ┌───────────┐  ┌───────────┐  ┌───────────┐   │   │
│  │  │ 状态快照  │  │ 依赖处理  │  │ 恢复机制  │   │   │
│  │  └───────────┘  └───────────┘  └───────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  操作流程：                                             │
│  卸载: 快照状态 → 通知依赖 → 停止服务 → 卸载           │
│  更新: 快照状态 → 卸载旧版 → 加载新版 → 恢复状态       │
│  安装: 加载 → 初始化 → 注册服务 → 启动                 │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

#### 热插拔实现

```rust
// src/plugin/hotswap.rs

pub struct HotSwapController {
    state_manager: StateManager,
    dependency_resolver: DependencyResolver,
    plugin_manager: PluginManager,
}

impl HotSwapController {
    /// 热更新插件
    pub async fn update_plugin(
        &mut self,
        plugin_id: &PluginId,
        new_package: &Path,
    ) -> Result<UpdateReport, HotSwapError> 
    {
        let mut report = UpdateReport::default();
        
        // 1. 检查是否有依赖此插件的其他插件
        let dependents = self.dependency_resolver.get_dependents(plugin_id);
        if !dependents.is_empty() {
            // 通知依赖插件准备更新
            for dep in &dependents {
                self.notify_update_start(dep, plugin_id).await?;
            }
        }
        
        // 2. 快照当前状态
        let state_snapshot = self.state_manager.snapshot(plugin_id).await?;
        report.snapshot_saved = true;
        
        // 3. 优雅停止
        self.plugin_manager.stop_plugin(plugin_id).await?;
        report.plugin_stopped = true;
        
        // 4. 卸载旧版本
        let old_manifest = self.plugin_manager.get_manifest(plugin_id)?;
        self.plugin_manager.unload_plugin(plugin_id).await?;
        report.old_unloaded = true;
        
        // 5. 加载新版本
        let new_plugin = self.plugin_manager.load_plugin(new_package).await?;
        report.new_loaded = true;
        
        // 6. 恢复状态
        self.state_manager.restore(plugin_id, &state_snapshot).await?;
        report.state_restored = true;
        
        // 7. 启动新版本
        self.plugin_manager.start_plugin(plugin_id).await?;
        report.plugin_started = true;
        
        // 8. 通知依赖插件恢复
        for dep in &dependents {
            self.notify_update_complete(dep, plugin_id).await?;
        }
        
        Ok(report)
    }
    
    /// 快照插件状态
    async fn snapshot_state(&self, plugin_id: &PluginId) 
        -> Result<PluginStateSnapshot, HotSwapError> 
    {
        // 获取插件内部状态
        let internal_state = self.plugin_manager
            .get_plugin(plugin_id)?
            .get_state()
            .await?;
        
        // 获取订阅关系
        let subscriptions = self.get_subscriptions(plugin_id).await?;
        
        // 获取连接状态
        let connections = self.get_active_connections(plugin_id).await?;
        
        Ok(PluginStateSnapshot {
            plugin_id: plugin_id.clone(),
            internal_state,
            subscriptions,
            connections,
            timestamp: SystemTime::now(),
        })
    }
}
```

---

## 4️⃣ 推荐架构方案

### 目标架构

```
┌─────────────────────────────────────────────────────────┐
│              PolyVault 插件化架构                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              主项目 (Core)                       │   │
│  │  ┌─────────────┬─────────────┬─────────────┐   │   │
│  │  │ 软总线核心  │   密码箱    │  鉴权系统   │   │   │
│  │  │             │             │             │   │   │
│  │  │ • eCAL Hub  │ • zk_vault  │ • Auth Svc  │   │   │
│  │  │ • Plugin    │ • Vault API │ • Permission│   │   │
│  │  │   Manager   │ • Audit Log │ • Session   │   │   │
│  │  └─────────────┴─────────────┴─────────────┘   │   │
│  │                                                 │   │
│  │  ┌─────────────────────────────────────────┐   │   │
│  │  │         Plugin API (gRPC + Protobuf)     │   │   │
│  │  └─────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────┘   │
│                          │                             │
│                          │                             │
│  ┌───────────────────────┼───────────────────────┐    │
│  │                       │                       │    │
│  ▼                       ▼                       ▼    │
│ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│ │ Flutter      │  │ Agent        │  │ IoT          │ │
│ │ Client       │  │ Plugin       │  │ Plugin       │ │
│ │              │  │              │  │              │ │
│ │ • UI         │  │ • Native Msg │  │ • Device     │ │
│ │ • 用户交互   │  │ • 浏览器集成  │  │   Discovery  │ │
│ │ • 生物认证   │  │ • 扩展支持   │  │ • Protocol   │ │
│ │              │  │              │  │   Convert    │ │
│ └──────────────┘  └──────────────┘  └──────────────┘ │
│                                                        │
│                    官方插件生态                        │
└─────────────────────────────────────────────────────────┘
```

### 实施建议

| 阶段 | 内容 | 时间 |
|------|------|------|
| **Phase 1** | 核心重构：提取 Plugin API | 2-3 周 |
| **Phase 2** | Flutter Client 插件化 | 2 周 |
| **Phase 3** | Agent Plugin 实现 | 2 周 |
| **Phase 4** | IoT Plugin 开发 | 3 周 |
| **Phase 5** | 插件市场 & SDK | 2 周 |

---

## 5️⃣ 风险评估

| 风险 | 级别 | 缓解措施 |
|------|------|---------|
| 插件安全漏洞 | 高 | 沙箱隔离 + 权限模型 + 代码签名 |
| 性能开销 | 中 | 进程隔离 + 懒加载 + 资源限制 |
| 兼容性问题 | 中 | 版本约束 + 迁移工具 |
| 开发复杂度 | 低 | 完善 SDK + 文档 + 示例 |

---

**创建日期**: 2026-03-14  
**作者**: devops-engineer  
**状态**: 技术分析完成