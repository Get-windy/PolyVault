# PolyVault 用户配置手册

**版本**: v4.1  
**最后更新**: 2026-03-21  
**适用对象**: PolyVault 用户、系统管理员

---

## 📖 目录

1. [配置概述](#配置概述)
2. [安全配置](#安全配置)
3. [同步配置](#同步配置)
4. [界面配置](#界面配置)
5. [通知配置](#通知配置)
6. [高级配置](#高级配置)
7. [配置文件详解](#配置文件详解)
8. [常见问题](#常见问题)

---

## 配置概述

### 配置入口

PolyVault 提供多种配置入口：

| 入口 | 位置 | 适用配置 |
|------|------|---------|
| **设置界面** | 应用内设置页面 | 常用配置项 |
| **配置文件** | `config/config.yaml` | 完整配置 |
| **命令行** | `polyvault config` | 快速修改 |
| **环境变量** | `POLYVAULT_*` | 容器部署 |

### 配置优先级

当同一配置项在多处设置时，优先级如下：

```
命令行参数 > 环境变量 > 配置文件 > 默认值
```

### 配置文件位置

| 平台 | 配置文件路径 |
|------|-------------|
| **Windows** | `%APPDATA%\PolyVault\config\config.yaml` |
| **macOS** | `~/Library/Application Support/PolyVault/config/config.yaml` |
| **Linux** | `~/.config/polyvault/config/config.yaml` |
| **Android** | `/data/data/io.polyvault/files/config/config.yaml` |
| **iOS** | App Sandbox/Documents/config/config.yaml |

---

## 安全配置

### 主密码设置

主密码是 PolyVault 安全的核心。

#### 设置要求

| 要求 | 说明 |
|------|------|
| 最小长度 | 12 字符 |
| 推荐长度 | 16+ 字符 |
| 复杂度 | 必须包含大小写字母、数字、特殊字符 |
| 有效期 | 建议每 90 天更换 |

#### 通过配置文件设置

```yaml
security:
  master_password:
    min_length: 12
    require_uppercase: true
    require_lowercase: true
    require_number: true
    require_special: true
    special_chars: "!@#$%^&*()_+-=[]{}|;:,.<>?"
    max_attempts: 5
    lockout_duration: 900  # 秒
```

#### 通过命令行设置

```bash
polyvault config set security.master_password.min_length 16
polyvault config set security.master_password.max_attempts 3
```

### 生物识别配置

```yaml
security:
  biometric:
    enabled: true
    type: auto          # auto, fingerprint, face, none
    fallback_to_password: true
    max_failed_attempts: 5
```

### 自动锁定

```yaml
security:
  auto_lock:
    enabled: true
    timeout_minutes: 5    # 空闲多少分钟后锁定
    on_screen_off: true   # 屏幕关闭时锁定
    on_app_switch: true   # 切换应用时锁定
```

### 权限级别

PolyVault 支持三级权限配置：

```yaml
security:
  permission_levels:
    L1:
      description: "基本凭证"
      auth_method: "password_or_biometric"
      
    L2:
      description: "敏感凭证"
      auth_method: "password_required"
      categories:
        - banking
        - identity
        
    L3:
      description: "高敏感凭证"
      auth_method: "password_plus_2fa"
      categories:
        - admin
        - financial
```

### 加密配置

```yaml
security:
  encryption:
    algorithm: AES-256-GCM
    key_derivation: Argon2id
    kdf_iterations: 100000
    salt_length: 32
```

---

## 同步配置

### P2P 同步设置

```yaml
sync:
  enabled: true
  method: p2p              # p2p, relay, manual
  
  p2p:
    discovery:
      method: mdns         # mdns, dht, manual
      port: 9527
      scan_interval: 30    # 秒
    
    connection:
      timeout: 10          # 秒
      max_retries: 3
      keepalive: 60        # 秒
    
    relay:
      enabled: false
      server: ""           # 中继服务器地址
```

### 设备授权

```yaml
sync:
  authorization:
    auto_authorize_same_network: true
    require_first_pair_confirm: true
    validity_hours: 24
    auto_renew: true
    
  trusted_devices:
    - device_id: "device-001"
      name: "MacBook Pro"
      authorized_at: "2026-03-01T00:00:00Z"
      auto_renew: true
      
    - device_id: "device-002"
      name: "iPhone 15"
      authorized_at: "2026-03-05T00:00:00Z"
      auto_renew: true
```

### 冲突解决

```yaml
sync:
  conflict_resolution:
    strategy: latest_wins   # latest_wins, manual, server_wins
    
    # 自动合并规则
    auto_merge:
      enabled: true
      fields:
        - tags
        - notes
```

---

## 界面配置

### 主题设置

```yaml
ui:
  theme: system           # light, dark, system
  accent_color: "#2196F3"  # 主色调
  font_size: medium       # small, medium, large
  language: zh-CN         # zh-CN, en-US, ja-JP
```

### 列表显示

```yaml
ui:
  list:
    default_sort: name    # name, date, usage
    show_icons: true
    compact_mode: false
    show_categories: true
```

### 快捷键配置

```yaml
ui:
  shortcuts:
    new_credential: "Ctrl+N"
    search: "Ctrl+F"
    lock: "Ctrl+L"
    copy_password: "Ctrl+Shift+C"
    copy_username: "Ctrl+Shift+U"
```

---

## 通知配置

### 安全通知

```yaml
notifications:
  security:
    login_alert:
      enabled: true
      notify_on_new_device: true
      notify_on_new_location: true
    
    password_breach:
      enabled: true
      check_interval: 86400  # 每天检查
    
    expiring_passwords:
      enabled: true
      warn_days_before: 30
```

### 同步通知

```yaml
notifications:
  sync:
    on_device_added: true
    on_sync_complete: false
    on_sync_error: true
    on_conflict: true
```

### 通知渠道

```yaml
notifications:
  channels:
    push:
      enabled: true
    
    email:
      enabled: false
      address: ""
    
    desktop:
      enabled: true
      sound: true
```

---

## 高级配置

### 性能优化

```yaml
performance:
  cache_size: 1024          # MB
  worker_threads: 8         # CPU 核心数 * 2
  connection_pool: 100
  gc_optimization: true
  memory_limit: 4096        # MB
```

### 日志配置

```yaml
logging:
  level: warn               # debug, info, warn, error
  dir: logs
  max_size: 100             # MB
  max_files: 10
  console: false
  json_format: true
  
  # 敏感信息处理
  redact_sensitive: true
  redact_patterns:
    - "password"
    - "token"
    - "secret"
```

### 代理配置

```yaml
network:
  proxy:
    enabled: false
    type: socks5           # http, socks5
    host: ""
    port: 1080
    username: ""
    password: ""
```

---

## 配置文件详解

### 完整配置示例

```yaml
# PolyVault 配置文件
# 版本: v4.1
# 路径: config/config.yaml

# 应用信息
app:
  name: PolyVault
  version: "4.1.0"
  language: zh-CN

# 安全配置
security:
  master_password:
    min_length: 12
    require_uppercase: true
    require_lowercase: true
    require_number: true
    require_special: true
    max_attempts: 5
    lockout_duration: 900
    
  biometric:
    enabled: true
    type: auto
    fallback_to_password: true
    max_failed_attempts: 5
    
  auto_lock:
    enabled: true
    timeout_minutes: 5
    on_screen_off: true
    on_app_switch: true
    
  encryption:
    algorithm: AES-256-GCM
    key_derivation: Argon2id
    kdf_iterations: 100000

# 同步配置
sync:
  enabled: true
  method: p2p
  
  p2p:
    discovery:
      method: mdns
      port: 9527
      scan_interval: 30
    
    connection:
      timeout: 10
      max_retries: 3
      keepalive: 60
      
  authorization:
    auto_authorize_same_network: true
    require_first_pair_confirm: true
    validity_hours: 24
    auto_renew: true

# 界面配置
ui:
  theme: system
  accent_color: "#2196F3"
  font_size: medium
  language: zh-CN
  
  list:
    default_sort: name
    show_icons: true
    compact_mode: false

# 通知配置
notifications:
  security:
    login_alert:
      enabled: true
      notify_on_new_device: true
    password_breach:
      enabled: true
      check_interval: 86400
      
  sync:
    on_device_added: true
    on_sync_error: true

# 性能配置
performance:
  cache_size: 1024
  worker_threads: 8
  memory_limit: 4096

# 日志配置
logging:
  level: warn
  dir: logs
  max_size: 100
  max_files: 10
  redact_sensitive: true

# 网络配置
network:
  proxy:
    enabled: false
```

### 环境变量映射

配置项可通过环境变量覆盖：

| 环境变量 | 配置项 | 示例值 |
|---------|--------|--------|
| `POLYVAULT_LOG_LEVEL` | logging.level | `debug` |
| `POLYVAULT_PROXY_ENABLED` | network.proxy.enabled | `true` |
| `POLYVAULT_PROXY_HOST` | network.proxy.host | `127.0.0.1` |
| `POLYVAULT_PROXY_PORT` | network.proxy.port | `1080` |
| `POLYVAULT_SYNC_ENABLED` | sync.enabled | `false` |
| `POLYVAULT_AUTO_LOCK_TIMEOUT` | security.auto_lock.timeout_minutes | `10` |

---

## 常见问题

### Q1: 如何重置配置？

```bash
# 重置为默认配置
polyvault config reset

# 重置特定配置项
polyvault config reset security.auto_lock
```

### Q2: 配置文件损坏怎么办？

1. 备份当前配置：
```bash
cp config/config.yaml config/config.yaml.bak
```

2. 重置配置：
```bash
polyvault config reset --force
```

3. 重新设置各项配置

### Q3: 如何导出/导入配置？

```bash
# 导出配置
polyvault config export config_backup.yaml

# 导入配置
polyvault config import config_backup.yaml
```

### Q4: 配置不生效怎么办？

1. 检查配置文件语法：
```bash
polyvault config validate
```

2. 检查配置优先级，确认是否被环境变量覆盖

3. 重启应用使配置生效

### Q5: 如何查看当前配置？

```bash
# 查看所有配置
polyvault config show

# 查看特定配置项
polyvault config get security.auto_lock.timeout_minutes
```

---

## 配置最佳实践

### 生产环境配置

```yaml
# 生产环境推荐配置

security:
  auto_lock:
    timeout_minutes: 5      # 短超时
  biometric:
    enabled: true           # 启用生物识别
    
sync:
  authorization:
    auto_authorize_same_network: false  # 不自动授权
    
logging:
  level: warn               # 减少日志
  redact_sensitive: true    # 隐藏敏感信息
  
performance:
  cache_size: 2048          # 大缓存
```

### 开发环境配置

```yaml
# 开发环境配置

logging:
  level: debug              # 详细日志
  console: true             # 控制台输出
  
performance:
  cache_size: 256           # 小缓存节省内存
```

---

**技术支持**: support@polyvault.io  
**文档维护**: PolyVault 文档组