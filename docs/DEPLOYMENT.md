# PolyVault 部署指南

## 概述

PolyVault Agent是一个跨平台的远程授权服务，支持Docker容器化部署。

---

## 快速开始

### 1. 克隆项目

```bash
git clone https://github.com/openclaw/polyvault.git
cd polyvault
```

### 2. 配置

```bash
# 复制配置文件
cp config/config.yaml.example config/config.yaml

# 编辑配置
vim config/config.yaml
```

### 3. 部署

```bash
# 使用部署脚本
./scripts/deploy.sh development

# 或直接使用Docker Compose
docker compose up -d
```

### 4. 验证

```bash
# 检查服务状态
curl http://localhost:8080/health

# 查看日志
docker compose logs -f agent
```

---

## Docker部署

### 构建镜像

```bash
# 构建运行时镜像
docker build -t polyvault/agent:latest .

# 构建开发镜像
docker build -t polyvault/agent:dev --target development .
```

### 运行容器

```bash
# 基本运行
docker run -d \
  --name polyvault-agent \
  -p 8080:8080 \
  -v $(pwd)/config:/app/config:ro \
  -v $(pwd)/data:/app/data \
  polyvault/agent:latest

# 带环境变量
docker run -d \
  --name polyvault-agent \
  -p 8080:8080 \
  -e POLYVAULT_LOG_LEVEL=debug \
  -v $(pwd)/config:/app/config:ro \
  polyvault/agent:latest
```

---

## Docker Compose部署

### 服务配置

| 服务 | 端口 | 说明 |
|------|------|------|
| `agent` | 8080 | REST API |
| `agent` | 9090 | Prometheus指标 |
| `redis` | 6379 | 缓存（可选） |
| `prometheus` | 9091 | 监控（可选） |
| `grafana` | 3000 | 可视化（可选） |

### Profile模式

```bash
# 开发模式
docker compose --profile dev up -d

# 完整模式（含Redis）
docker compose --profile full up -d

# 监控模式
docker compose --profile monitoring up -d
```

---

## 环境变量

### 核心配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `POLYVAULT_LOG_LEVEL` | `info` | 日志级别 |
| `POLYVAULT_LOG_DIR` | `/app/logs` | 日志目录 |
| `POLYVAULT_DATA_DIR` | `/app/data` | 数据目录 |
| `POLYVAULT_REST_PORT` | `8080` | REST API端口 |
| `POLYVAULT_METRICS_PORT` | `9090` | 指标端口 |

### 日志级别

- `trace` - 最详细
- `debug` - 调试信息
- `info` - 常规信息
- `warn` - 警告
- `error` - 错误

---

## 配置文件

### config.yaml

```yaml
server:
  rest_port: 8080
  metrics_port: 9090
  max_connections: 100

logging:
  level: info
  dir: /app/logs
  console: true

security:
  encryption: AES-256-GCM
  session_timeout: 3600

storage:
  type: file
  file_path: /app/data/vault.dat
```

---

## 本地构建

### 前置要求

- CMake 3.16+
- C++17编译器
- OpenSSL

### 构建步骤

```bash
cd src/agent
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SIMPLE=ON
cmake --build . --parallel
```

### 运行

```bash
./polyvault_agent_simple --config ../../config/config.yaml
```

---

## 监控

### Prometheus配置

`deploy/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'polyvault'
    static_configs:
      - targets: ['agent:9090']
```

### Grafana仪表板

导入 `deploy/grafana/dashboards/polyvault.json`

---

## 健康检查

### 端点

| 端点 | 说明 |
|------|------|
| `/health` | 基本健康检查 |
| `/health/status` | 详细状态 |
| `/metrics` | Prometheus指标 |

### 示例

```bash
# 基本检查
curl http://localhost:8080/health

# 详细状态
curl http://localhost:8080/health/status

# 指标
curl http://localhost:9090/metrics
```

---

## 故障排查

### 服务无法启动

1. 检查端口占用
```bash
netstat -tlnp | grep 8080
```

2. 检查配置文件
```bash
cat config/config.yaml
```

3. 查看日志
```bash
docker compose logs agent
```

### 健康检查失败

1. 检查服务状态
```bash
docker compose ps
```

2. 检查网络
```bash
docker network ls
docker network inspect polyvault_polyvault-network
```

---

## 升级

### 拉取新版本

```bash
git pull origin main
```

### 重新构建

```bash
docker compose build --no-cache agent
```

### 滚动更新

```bash
docker compose up -d --no-deps agent
```

---

## 备份与恢复

### 备份数据

```bash
# 备份数据目录
tar -czf polyvault-data-$(date +%Y%m%d).tar.gz data/

# 备份配置
tar -czf polyvault-config-$(date +%Y%m%d).tar.gz config/
```

### 恢复数据

```bash
# 解压数据
tar -xzf polyvault-data-20260314.tar.gz

# 重启服务
docker compose restart agent
```

---

## 安全建议

1. **使用HTTPS**
   - 配置反向代理（Nginx）
   - 启用SSL证书

2. **限制网络访问**
   - 使用防火墙规则
   - 限制端口暴露

3. **定期备份**
   - 自动化备份脚本
   - 异地存储

4. **日志审计**
   - 启用审计日志
   - 定期检查异常

---

## 部署脚本参考

```bash
# 开发环境
./scripts/deploy.sh development

# 测试环境
./scripts/deploy.sh staging v0.1.0

# 生产环境
./scripts/deploy.sh production v0.1.0

# 查看状态
./scripts/deploy.sh --status

# 查看日志
./scripts/deploy.sh --logs

# 停止服务
./scripts/deploy.sh --stop

# 清理资源
./scripts/deploy.sh --clean
```