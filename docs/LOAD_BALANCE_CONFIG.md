# PolyVault - 负载均衡配置

**版本**: v1.0  
**更新日期**: 2026-03-22  

---

## 多节点部署架构

PolyVault支持多Agent节点部署，通过负载均衡提高可用性和性能。

### 架构图

```
                    ┌─────────────┐
                    │   Nginx     │
                    │ 负载均衡器  │
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
  ┌───────────┐      ┌───────────┐      ┌───────────┐
  │  Agent 1  │      │  Agent 2  │      │  Agent 3  │
  │  :8080    │      │  :8081    │      │  :8082    │
  └───────────┘      └───────────┘      └───────────┘
        │                  │                  │
        └──────────────────┼──────────────────┘
                           │
                           ▼
                 ┌─────────────────┐
                 │  Redis Cluster  │
                 │   (共享状态)     │
                 └─────────────────┘
```

---

## Nginx配置

```nginx
upstream polyvault_agents {
    least_conn;
    server 127.0.0.1:8080 weight=3;
    server 127.0.0.1:8081 weight=3;
    server 127.0.0.1:8082 weight=2;
    keepalive 32;
}

server {
    listen 443 ssl;
    server_name api.polyvault.io;

    ssl_certificate /etc/ssl/polyvault.crt;
    ssl_certificate_key /etc/ssl/polyvault.key;

    location / {
        proxy_pass http://polyvault_agents;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        proxy_pass http://polyvault_agents/health;
    }
}
```

---

## 注意事项

1. **会话状态**: PolyVault是无状态的，所有状态存储在Redis中
2. **P2P同步**: 多节点间通过Redis Cluster同步设备授权状态
3. **健康检查**: 每个Agent暴露 `/health` 端点

---

**维护**: DevOps团队