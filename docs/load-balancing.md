# PolyVault 负载均衡配置指南

## 架构概述

```
                    ┌─────────────────┐
                    │   客户端请求    │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │   Nginx LB      │
                    │   负载均衡层    │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
   ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
   │  Agent-1    │   │  Agent-2    │   │  Agent-3    │
   │  (C++)      │   │  (C++)      │   │  (C++)      │
   └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
          │                  │                  │
          └──────────────────┼──────────────────┘
                             │
          ┌──────────────────┼──────────────────┐
          │                  │                  │
   ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
   │   Redis     │   │  Database   │   │ Prometheus  │
   └─────────────┘   └─────────────┘   └─────────────┘
```

## 部署方式

### Docker Compose 部署

```bash
cd deploy

# 启动负载均衡集群
docker-compose -f docker-compose.lb.yml up -d

# 查看状态
docker-compose -f docker-compose.lb.yml ps

# 扩展实例
docker-compose -f docker-compose.lb.yml scale agent=5
```

### 手动扩展

```bash
# Python脚本
python scripts/scale.py status  # 查看状态
python scripts/scale.py up      # 增加实例
python scripts/scale.py down    # 减少实例
python scripts/scale.py 5       # 设置为5个实例
```

### 自动扩展

```bash
# 基于CPU/内存自动扩展
python scripts/scale.py auto

# 设置定时任务（crontab）
*/5 * * * * cd /opt/polyvault && python scripts/scale.py auto >> /var/log/scale.log
```

## 负载均衡算法

| 算法 | 配置 | 适用场景 |
|------|------|----------|
| least_conn | 默认 | API请求 |
| ip_hash | WebSocket | 会话保持 |

```nginx
# API请求 - 最少连接
upstream polyvault_cluster {
    least_conn;
    server agent-1:8080;
    server agent-2:8080;
    server agent-3:8080;
    keepalive 64;
}

# WebSocket - IP哈希
upstream polyvault_ws {
    ip_hash;
    server agent-1:8080;
    server agent-2:8080;
    server agent-3:8080;
}
```

## 健康检查

| 端点 | 用途 | 响应 |
|------|------|------|
| `/health` | 存活探针 | `{"status":"ok"}` |
| `/metrics` | Prometheus指标 | 指标数据 |
| `/cluster/status` | 集群状态 | JSON |

### 配置示例

**Docker:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--spider", "http://localhost:8080/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

**Nginx健康检查:**
```nginx
# 被动健康检查
server agent-1:8080 max_fails=3 fail_timeout=30s;
```

## 监控

### Prometheus

访问 `http://localhost:9090`

**关键指标:**
- `http_requests_total` - 请求总数
- `http_request_duration_seconds` - 请求延迟
- `polyvault_active_connections` - 活跃连接数

### Grafana

访问 `http://localhost:3000`

默认账号: admin/admin

## 扩展阈值

| 指标 | 扩容阈值 | 缩容阈值 |
|------|----------|----------|
| CPU | > 70% | < 30% |
| 内存 | > 80% | < 40% |

- 最小实例: 2
- 最大实例: 10
- 冷却期: 300秒

## 故障排除

```bash
# 检查nginx状态
docker exec polyvault-nginx-lb nginx -t

# 重载nginx配置
docker exec polyvault-nginx-lb nginx -s reload

# 查看后端健康状态
curl http://localhost/health

# 查看集群状态
curl http://localhost/cluster/status

# 查看日志
docker logs polyvault-agent-1
```