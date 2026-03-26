# PolyVault 部署运维文档

**版本**: v4.1  
**最后更新**: 2026-03-21  
**状态**: 生产就绪  
**文档类型**: 运维指南

---

## 📖 目录

1. [文档概述](#文档概述)
2. [生产环境配置](#生产环境配置)
3. [部署架构](#部署架构)
4. [监控方案](#监控方案)
5. [日志管理](#日志管理)
6. [备份与恢复](#备份与恢复)
7. [故障排查](#故障排查)
8. [运维脚本](#运维脚本)
9. [安全加固](#安全加固)
10. [性能优化](#性能优化)

---

## 文档概述

### 适用范围

本文档面向运维工程师和系统管理员，提供PolyVault生产环境的完整部署和运维指南。

### 环境要求

| 组件 | 最低配置 | 推荐配置 | 说明 |
|------|---------|---------|------|
| **CPU** | 2核 | 4核+ | Agent服务计算需求 |
| **内存** | 2GB | 4GB+ | 包含容器开销 |
| **磁盘** | 20GB SSD | 50GB+ SSD | 数据和日志存储 |
| **网络** | 100Mbps | 1Gbps | 内部通信带宽 |
| **OS** | Ubuntu 20.04 | Ubuntu 22.04 LTS | 推荐Linux发行版 |

### 部署模式

| 模式 | 适用场景 | 组件 |
|------|---------|------|
| **单机模式** | 开发/测试 | Agent + File存储 |
| **标准模式** | 小型生产环境 | Agent + Redis |
| **高可用模式** | 企业级生产 | Agent集群 + Redis集群 + LB |
| **监控模式** | 全栈监控 | 标准模式 + Prometheus + Grafana |

---

## 生产环境配置

### 1. 系统环境准备

#### 1.1 操作系统配置

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要工具
sudo apt install -y \
    curl wget vim htop net-tools \
    apt-transport-https ca-certificates \
    gnupg lsb-release software-properties-common

# 配置时区
sudo timedatectl set-timezone Asia/Shanghai

# 配置主机名
sudo hostnamectl set-hostname polyvault-prod-01

# 配置hosts（多节点部署时）
echo "192.168.1.10 polyvault-prod-01" | sudo tee -a /etc/hosts
echo "192.168.1.11 polyvault-prod-02" | sudo tee -a /etc/hosts
echo "192.168.1.12 polyvault-prod-03" | sudo tee -a /etc/hosts
```

#### 1.2 Docker环境安装

```bash
# 添加Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加Docker仓库
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 配置Docker
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "storage-driver": "overlay2",
  "live-restore": true
}
EOF

# 启动Docker
sudo systemctl enable docker
sudo systemctl start docker

# 添加用户到docker组（可选）
sudo usermod -aG docker $USER
```

#### 1.3 系统优化

```bash
# 配置内核参数
sudo tee -a /etc/sysctl.conf > /dev/null <<EOF
# 网络优化
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000

# 文件描述符
fs.file-max = 65535
fs.nr_open = 65535

# 内存优化
vm.swappiness = 10
vm.dirty_ratio = 40
vm.dirty_background_ratio = 10
EOF

sudo sysctl -p

# 配置文件描述符限制
sudo tee -a /etc/security/limits.conf > /dev/null <<EOF
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF

# 配置防火墙
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 8080/tcp  # PolyVault API
sudo ufw allow 9090/tcp  # Metrics
sudo ufw --force enable
```

### 2. 生产环境配置

#### 2.1 配置文件

创建生产环境配置文件 `config/config.production.yaml`：

```yaml
# ==================== 生产环境配置 ====================
# PolyVault Agent 生产环境配置
# 警告：请妥善保管此文件，包含敏感配置

# ==================== 服务配置 ====================
server:
  rest_port: 8080
  metrics_port: 9090
  max_connections: 200
  request_timeout: 30
  shutdown_timeout: 30
  tls_enabled: true
  tls_cert: /app/certs/server.crt
  tls_key: /app/certs/server.key

# ==================== 日志配置 ====================
logging:
  level: warn
  dir: /app/logs
  prefix: polyvault
  max_size: 100
  max_files: 10
  console: false
  json_format: true

# ==================== 数据配置 ====================
data:
  dir: /app/data
  auto_save_interval: 300
  max_credentials: 10000
  backup_retention_days: 30

# ==================== 安全配置 ====================
security:
  key_length: 32
  encryption: AES-256-GCM
  kdf_iterations: 100000
  session_timeout: 3600
  max_login_attempts: 5
  lockout_duration: 900
  rate_limit_enabled: true
  rate_limit_rps: 100

# ==================== 存储配置 ====================
storage:
  type: redis
  file_path: /app/data/vault.dat
  redis:
    host: redis
    port: 6379
    db: 0
    password: "${REDIS_PASSWORD}"
    pool_size: 20
    timeout: 5

# ==================== 审计配置 ====================
audit:
  enabled: true
  log_file: /app/logs/audit.log
  events:
    - credential_access
    - credential_create
    - credential_delete
    - credential_update
    - auth_success
    - auth_failure
    - permission_change
    - config_change
  retention_days: 90

# ==================== 性能配置 ====================
performance:
  worker_threads: 8
  connection_pool: 50
  cache_size: 512
  gc_optimization: true
  memory_limit: 2048
```

#### 2.2 环境变量配置

创建生产环境变量文件 `.env.production`：

```bash
# ============================================
# PolyVault 生产环境变量
# ============================================

VERSION=1.0.0
LOG_LEVEL=warn
REDIS_PASSWORD=YourStrongRedisPasswordHere
GRAFANA_PASSWORD=YourStrongGrafanaPasswordHere
BACKUP_ENABLED=true
BACKUP_SCHEDULE="0 2 * * *"
BACKUP_RETENTION_DAYS=30
ALERT_ENABLED=true
ALERT_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
ALERT_EMAIL=ops@yourcompany.com
```

---

## 部署架构

### 1. 单机部署架构

```
┌─────────────────────────────────────────────────────────┐
│                      单机部署架构                        │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Docker Host                         │   │
│  │                                                 │   │
│  │  ┌─────────────┐    ┌─────────────┐            │   │
│  │  │   Agent     │    │    Redis    │            │   │
│  │  │   :8080     │◄──►│   :6379     │            │   │
│  │  │   :9090     │    │             │            │   │
│  │  └──────┬──────┘    └─────────────┘            │   │
│  │         │                                       │   │
│  │         ▼                                       │   │
│  │  ┌─────────────┐    ┌─────────────┐            │   │
│  │  │    Data     │    │    Logs     │            │   │
│  │  │   Volume    │    │   Volume    │            │   │
│  │  └─────────────┘    └─────────────┘            │   │
│  │                                                 │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2. 高可用部署架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           高可用部署架构                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                              ┌──────────┐                                  │
│                              │   LB     │                                  │
│                              │ (Nginx)  │                                  │
│                              │  :443    │                                  │
│                              └────┬─────┘                                  │
│                                   │                                        │
│              ┌────────────────────┼────────────────────┐                   │
│              │                    │                    │
│              ▼                    ▼                    ▼
│       ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│       │   Agent 1   │      │   Agent 2   │      │   Agent 3   │
│       │   :8080     │      │   :8080     │      │   :8080     │
│       └──────┬──────┘      └──────┬──────┘      └──────┬──────┘
│              │                    │                    │
│              └────────────────────┼────────────────────┘
│                                   │
│                                   ▼
│                         ┌─────────────────┐
│                         │  Redis Cluster  │
│                         │   (3 masters)   │
│                         └─────────────────┘
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 监控方案

### 1. Prometheus监控配置

```yaml
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'polyvault-agent'
    static_configs:
      - targets: ['agent:9090']
    metrics_path: /metrics

  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

### 2. 关键监控指标

| 指标 | 说明 | 告警阈值 |
|------|------|---------|
| `up` | 服务可用性 | = 0 告警 |
| `http_request_duration_seconds` | 请求延迟 | P95 > 1s 告警 |
| `process_resident_memory_bytes` | 内存使用 | > 1.5GB 告警 |

---

## 日志管理

### 1. 日志配置

```yaml
logging:
  level: warn
  dir: /app/logs
  max_size: 100
  max_files: 10
  json_format: true
```

### 2. 日志查看

```bash
# 查看错误日志
grep ERROR /app/logs/polyvault.log

# 实时监控
tail -f /app/logs/polyvault.log
```

---

## 备份与恢复

### 1. 自动备份

```bash
#!/bin/bash
# 每日备份脚本
BACKUP_DIR="/backup/polyvault"
DATE=$(date +%Y%m%d)
tar -czf ${BACKUP_DIR}/backup_${DATE}.tar.gz /app/data
```

### 2. 恢复流程

```bash
# 停止服务
docker compose stop agent
# 恢复数据
tar -xzf backup_20260321.tar.gz -C /app/data
# 启动服务
docker compose start agent
```

---

## 故障排查

### 常见问题

| 问题 | 解决方案 |
|------|---------|
| 服务无法启动 | 检查日志 `docker logs polyvault-agent` |
| 内存不足 | 调整 `memory_limit` 配置 |
| 连接Redis失败 | 检查Redis状态 `redis-cli ping` |

---

## 运维脚本

```bash
# 健康检查
curl http://localhost:8080/health

# 重启服务
docker compose restart agent

# 查看日志
docker logs -f polyvault-agent
```

---

**文档版本**: v4.1  
**最后更新**: 2026-03-21  
**维护团队**: PolyVault运维组