# MEMORY.md - PolyVault (OpenClaw客户端) 项目记忆

## 2026-03-13 项目启动

### 📁 项目信息

- **项目名称**: PolyVault（别名：OpenClaw客户端项目）
- **项目目录**: I:\PolyVault
- **启动时间**: 2026-03-13 20:00
- **群组**: PolyVault开发群 (group_1773403635480_mvh5nt)

### 🎯 核心目标

1. **远程授信** - OpenClaw服务器需要登录第三方服务时，实时向用户客户端请求凭证
2. **硬件级安全** - 所有凭证在客户端由安全硬件保护（TEE/Secure Enclave/TPM）
3. **去中心化通信** - eCAL P2P加密通道，无需中心服务器
4. **跨平台覆盖** - iOS/Android/Windows/macOS/Linux/嵌入式
5. **鸿蒙优先** - 借鉴鸿蒙分布式软总线、HUKS设计

### 🔧 技术栈

| 层级 | 技术 |
|------|------|
| 通信层 | eCAL（共享内存/UDP/TCP自动切换） |
| 安全层 | zk_vault + 各平台原生Keystore |
| 客户端 | Flutter + Dart FFI |
| 本地Agent | C++/Rust + eCAL |
| 浏览器扩展 | Manifest V3 + Native Messaging |

### 👥 团队配置

| Agent | 角色 |
|-------|------|
| devops-engineer | 后端开发、eCAL集成 |
| team-member | Flutter客户端开发 |
| qa-lead | 测试、安全审计 |
| doc-writer | 技术文档 |
| product-analyst | 产品规划 |

### 📋 开发计划

#### 阶段一：基础通信与安全（1-2个月）
- [ ] 搭建eCAL开发环境
- [ ] Flutter项目初始化
- [ ] 集成zk_vault
- [ ] FFI调用eCAL C API

#### 阶段二：远程授信核心（2-3个月）
- [ ] Protobuf协议定义
- [ ] 浏览器扩展开发
- [ ] Native Messaging Host
- [ ] 完整登录授权流程

#### 阶段三：能力虚拟化（2个月）
- [ ] eCAL Service设备发现
- [ ] 凭证跨设备同步

#### 阶段四：嵌入式支持（2-3个月）
- [ ] eCAL核心裁剪
- [ ] 安全芯片集成

#### 阶段五：鸿蒙原生适配（2个月）
- [ ] HUKS集成
- [ ] 分布式软总线集成

---

## 2026-03-23 负载均衡部署配置

### 完成的工作

#### 1. 负载均衡部署配置
- **docker-compose.lb.yml** - 负载均衡Docker Compose配置
  - NGINX负载均衡器（SSL终止）
  - 可扩展Agent实例（支持 --scale）
  - Redis共享会话存储
  - 健康检查配置
  - 资源限制配置

#### 2. NGINX配置
- **config/nginx/nginx.conf** - NGINX主配置
  - least_conn负载均衡策略
  - HTTP/2支持
  - Gzip压缩
  - 速率限制
  - 安全头配置

- **config/nginx/conf.d/polyvault.conf** - 站点配置
  - HTTP->HTTPS重定向
  - SSL配置（TLS 1.2/1.3）
  - 代理头配置
  - WebSocket支持
  - 错误处理

#### 3. 部署脚本
- **scripts/deploy-lb.sh** - 负载均衡部署脚本
  - 支持多实例部署
  - 滚动更新（零停机）
  - 动态扩缩容
  - 健康检查
  - 状态监控

#### 4. 文档
- **docs/load-balancing.md** - 负载均衡部署指南
  - 架构图
  - 快速开始
  - 配置说明
  - 故障排查
  - 性能调优

### 使用方法

```bash
# 基础部署（2实例）
./scripts/deploy-lb.sh development

# 生产部署（4实例）
REPLICAS=4 ./scripts/deploy-lb.sh production latest --deploy

# 扩缩容
./scripts/deploy-lb.sh --scale 5

# 滚动更新
./scripts/deploy-lb.sh production v0.2.0 --update

# 查看状态
./scripts/deploy-lb.sh --status
```

### 负载均衡架构

```
Client → NGINX (LB) → [Agent 1, Agent 2, ... Agent N] → Redis
```

---
*创建时间: 2026-03-13 20:00*
*更新时间: 2026-03-23 12:55*