# PolyVault 监控配置指南

**版本**: v1.0  
**创建时间**: 2026-03-24  
**适用对象**: 运维人员、系统管理员

---

## 📖 目录

1. [监控架构](#监控架构)
2. [健康检查配置](#健康检查配置)
3. [Prometheus配置](#prometheus配置)
4. [Grafana仪表板](#grafana仪表板)
5. [日志监控](#日志监控)
6. [告警配置](#告警配置)
7. [监控最佳实践](#监控最佳实践)

---

## 监控架构

### 组件概览

```
┌─────────────────────────────────────────────────────────────┐
│                      监控系统架构                             │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │  PolyVault   │───▶│  Prometheus  │───▶│   Grafana    │  │
│  │    Agent     │    │   (收集)      │    │   (可视化)   │  │
│  │  :9090/指标   │    │   :9091      │    │   :3000      │  │
│  └──────────────┘    └──────────────┘    └──────────────┘  │
│         │                   │                                │
│         │                   ▼                                │
│         │            ┌──────────────┐                       │
│         │            │  AlertManager│                       │
│         │            │   (告警)      │                       │
│         │            └──────────────┘                       │
│         ▼                                                    │
│  ┌──────────────┐                                           │
│  │  日志系统    │                                           │
│  │  /app/logs   │                                           │
│  └──────────────┘                                           │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 端口分配

| 服务 | 端口 | 用途 |
|------|------|------|
| REST API | 8080 | 业务接口 |
| Metrics | 9090 | Prometheus指标 |
| Prometheus | 9091 | 监控收集 |
| Grafana | 3000 | 可视化界面 |

---

## 健康检查配置

### 健康检查端点

| 端点 | 方法 | 说明 | 响应示例 |
|------|------|------|---------|
| `/health` | GET | 基本健康检查 | `{"status": "ok"}` |
| `/health/status` | GET | 详细状态 | 包含各组件状态 |
| `/health/ready` | GET | 就绪探针 | 用于K8s |
| `/health/live` | GET | 存活探针 | 用于K8s |

### 详细状态响应

```json
{
  "status": "healthy",
  "timestamp": "2026-03-24T00:00:00Z",
  "components": {
    "storage": {
      "status": "ok",
      "latency_ms": 5
    },
    "cache": {
      "status": "ok",
      "hit_rate": 0.95
    },
    "network": {
      "status": "ok",
      "connections": 42
    }
  },
  "metrics": {
    "uptime_seconds": 86400,
    "requests_total": 1000000,
    "errors_total": 50
  }
}
```

### Docker健康检查

```yaml
# docker-compose.yml
services:
  agent:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### Kubernetes探针

```yaml
# kubernetes/deployment.yaml
livenessProbe:
  httpGet:
    path: /health/live
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /health/ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## Prometheus配置

### prometheus.yml

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'polyvault-monitor'

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

rule_files:
  - /etc/prometheus/rules/*.yml

scrape_configs:
  # PolyVault Agent
  - job_name: 'polyvault-agent'
    static_configs:
      - targets: ['agent:9090']
    metrics_path: /metrics
    scheme: http

  # Node Exporter (可选)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']

  # Redis监控 (可选)
  - job_name: 'redis'
    static_configs:
      - targets: ['redis-exporter:9121']
```

### 指标说明

| 指标名称 | 类型 | 说明 |
|---------|------|------|
| `polyvault_requests_total` | Counter | 请求总数 |
| `polyvault_request_duration_seconds` | Histogram | 请求延迟 |
| `polyvault_active_connections` | Gauge | 活跃连接数 |
| `polyvault_credential_operations_total` | Counter | 凭证操作数 |
| `polyvault_sync_operations_total` | Counter | 同步操作数 |
| `polyvault_cache_hits_total` | Counter | 缓存命中数 |
| `polyvault_cache_misses_total` | Counter | 缓存未命中数 |
| `polyvault_storage_latency_seconds` | Histogram | 存储延迟 |

### 自定义指标

```cpp
// src/agent/metrics.cpp
#include <prometheus/counter.h>
#include <prometheus/histogram.h>

// 请求计数器
auto& request_counter = BuildCounter()
    .Name("polyvault_requests_total")
    .Help("Total number of requests")
    .Register(registry);

// 请求延迟直方图
auto& request_duration = BuildHistogram()
    .Name("polyvault_request_duration_seconds")
    .Help("Request duration in seconds")
    .Register(registry)
    .Add({}, {0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0, 5.0});
```

---

## Grafana仪表板

### 数据源配置

```yaml
# deploy/grafana/provisioning/datasources/datasources.yml
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9091
    isDefault: true
    editable: false
```

### 仪表板面板

#### 1. 请求概览面板

```json
{
  "title": "请求概览",
  "panels": [
    {
      "title": "请求速率 (QPS)",
      "type": "graph",
      "targets": [
        {
          "expr": "rate(polyvault_requests_total[5m])",
          "legendFormat": "{{method}} {{endpoint}}"
        }
      ]
    },
    {
      "title": "请求延迟 P99",
      "type": "graph",
      "targets": [
        {
          "expr": "histogram_quantile(0.99, rate(polyvault_request_duration_seconds_bucket[5m]))",
          "legendFormat": "P99"
        }
      ]
    }
  ]
}
```

#### 2. 系统资源面板

```json
{
  "title": "系统资源",
  "panels": [
    {
      "title": "CPU使用率",
      "type": "gauge",
      "targets": [
        {
          "expr": "process_cpu_seconds_total{job='polyvault-agent'}",
          "legendFormat": "CPU"
        }
      ]
    },
    {
      "title": "内存使用",
      "type": "graph",
      "targets": [
        {
          "expr": "process_resident_memory_bytes{job='polyvault-agent'}",
          "legendFormat": "RSS"
        }
      ]
    }
  ]
}
```

#### 3. 业务指标面板

```json
{
  "title": "业务指标",
  "panels": [
    {
      "title": "凭证操作统计",
      "type": "stat",
      "targets": [
        {
          "expr": "sum(polyvault_credential_operations_total)",
          "legendFormat": "总操作数"
        }
      ]
    },
    {
      "title": "同步成功率",
      "type": "gauge",
      "targets": [
        {
          "expr": "sum(rate(polyvault_sync_operations_total{status='success'}[5m])) / sum(rate(polyvault_sync_operations_total[5m])) * 100",
          "legendFormat": "成功率 %"
        }
      ]
    }
  ]
}
```

### 导入仪表板

```bash
# 通过API导入
curl -X POST http://admin:admin@localhost:3000/api/dashboards/import \
  -H "Content-Type: application/json" \
  -d @deploy/grafana/dashboards/polyvault.json

# 或通过UI导入
# 访问 http://localhost:3000 -> Dashboards -> Import
```

---

## 日志监控

### 日志配置

```yaml
# config.yaml
logging:
  level: info
  dir: /app/logs
  format: json
  console: true
  file:
    max_size: 100MB
    max_files: 10
    max_age: 30
    compress: true
```

### 日志格式

```json
{
  "timestamp": "2026-03-24T00:00:00.000Z",
  "level": "info",
  "message": "Request completed",
  "request_id": "req_123456",
  "method": "GET",
  "path": "/api/v1/credentials",
  "status": 200,
  "duration_ms": 15,
  "client_ip": "192.168.1.100",
  "user_agent": "PolyVault/1.0"
}
```

### 日志级别说明

| 级别 | 说明 | 使用场景 |
|------|------|---------|
| trace | 最详细 | 开发调试 |
| debug | 调试信息 | 问题排查 |
| info | 常规信息 | 生产环境 |
| warn | 警告 | 潜在问题 |
| error | 错误 | 需要关注 |

### 日志聚合 (ELK)

```yaml
# deploy/filebeat/filebeat.yml
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /app/logs/*.json
    json.keys_under_root: true
    json.add_error_key: true

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "polyvault-%{+yyyy.MM.dd}"
```

### 日志告警规则

```yaml
# Prometheus告警规则示例
groups:
  - name: logs
    interval: 1m
    rules:
      - alert: HighErrorRate
        expr: rate(polyvault_errors_total[5m]) > 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高错误率检测"
          description: "过去5分钟错误率超过10/秒"
```

---

## 告警配置

### AlertManager配置

```yaml
# deploy/alertmanager/alertmanager.yml
global:
  resolve_timeout: 5m
  smtp_smarthost: 'smtp.example.com:587'
  smtp_from: 'alerts@polyvault.io'
  smtp_auth_username: 'alerts@polyvault.io'
  smtp_auth_password: 'password'

route:
  group_by: ['alertname', 'severity']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  receiver: 'default'
  routes:
    - match:
        severity: critical
      receiver: 'critical'
    - match:
        severity: warning
      receiver: 'warning'

receivers:
  - name: 'default'
    email_configs:
      - to: 'team@polyvault.io'

  - name: 'critical'
    email_configs:
      - to: 'oncall@polyvault.io'
    webhook_configs:
      - url: 'https://hooks.slack.com/services/xxx'

  - name: 'warning'
    email_configs:
      - to: 'team@polyvault.io'
```

### 告警规则

```yaml
# deploy/prometheus/rules/polyvault.yml
groups:
  - name: polyvault
    interval: 30s
    rules:
      # 服务健康
      - alert: ServiceDown
        expr: up{job="polyvault-agent"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "PolyVault服务不可用"
          description: "实例 {{ $labels.instance }} 已宕机超过1分钟"

      # 高延迟
      - alert: HighLatency
        expr: histogram_quantile(0.99, rate(polyvault_request_duration_seconds_bucket[5m])) > 1
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高请求延迟"
          description: "P99延迟超过1秒"

      # 高错误率
      - alert: HighErrorRate
        expr: rate(polyvault_requests_total{status=~"5.."}[5m]) / rate(polyvault_requests_total[5m]) > 0.01
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "高错误率"
          description: "5xx错误率超过1%"

      # 内存使用过高
      - alert: HighMemoryUsage
        expr: process_resident_memory_bytes{job="polyvault-agent"} > 1073741824
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "内存使用过高"
          description: "内存使用超过1GB"

      # 缓存命中率低
      - alert: LowCacheHitRate
        expr: rate(polyvault_cache_hits_total[5m]) / (rate(polyvault_cache_hits_total[5m]) + rate(polyvault_cache_misses_total[5m])) < 0.5
        for: 10m
        labels:
          severity: info
        annotations:
          summary: "缓存命中率低"
          description: "缓存命中率低于50%"
```

---

## 监控最佳实践

### 1. 监控指标选择

**黄金信号 (Four Golden Signals)**:
- **延迟 (Latency)**: 请求响应时间
- **流量 (Traffic)**: 请求数量
- **错误 (Errors)**: 错误率
- **饱和度 (Saturation)**: 资源使用率

### 2. 告警阈值设置

| 指标 | 警告阈值 | 严重阈值 |
|------|---------|---------|
| 延迟 P99 | > 500ms | > 1s |
| 错误率 | > 1% | > 5% |
| CPU使用率 | > 70% | > 90% |
| 内存使用率 | > 80% | > 95% |
| 磁盘使用率 | > 80% | > 95% |

### 3. 监控分层

```
┌───────────────────────────────────────┐
│            业务指标监控                │  ← 最高优先级
├───────────────────────────────────────┤
│            应用性能监控                │
├───────────────────────────────────────┤
│            系统资源监控                │
├───────────────────────────────────────┤
│            基础设施监控                │  ← 基础保障
└───────────────────────────────────────┘
```

### 4. 常用命令

```bash
# 检查服务状态
curl -s http://localhost:8080/health | jq

# 查看实时指标
curl -s http://localhost:9090/metrics | grep polyvault

# 查看日志
tail -f /app/logs/agent.log | jq

# 检查Prometheus目标状态
curl -s http://localhost:9091/api/v1/targets | jq

# 手动触发告警测试
curl -X POST http://localhost:9093/api/v1/alerts -d '[{"labels":{"alertname":"TestAlert"}}]'
```

### 5. 监控检查清单

- [ ] 健康检查端点可访问
- [ ] Prometheus正常抓取指标
- [ ] Grafana仪表板数据正常
- [ ] 告警规则配置完成
- [ ] 告警通知渠道测试通过
- [ ] 日志聚合正常工作
- [ ] 监控数据保留策略配置

---

## 附录

### A. 相关文档

- [部署指南](./DEPLOYMENT.md)
- [部署运维](./DEPLOYMENT_OPERATIONS.md)
- [开发指南](./DEVELOPMENT_GUIDE.md)

### B. 外部资源

- [Prometheus文档](https://prometheus.io/docs/)
- [Grafana文档](https://grafana.com/docs/)
- [AlertManager文档](https://prometheus.io/docs/alerting/latest/alertmanager/)

---

**维护者**: PolyVault 运维团队  
**最后更新**: 2026-03-24