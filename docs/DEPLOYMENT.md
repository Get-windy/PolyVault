# PolyVault 部署文档

**版本**: v1.0.0  
**更新时间**: 2026-03-24

---

## 系统要求

### 服务端

| 组件 | 最低要求 | 推荐配置 |
|------|---------|---------|
| Node.js | v18.0+ | v20.0+ |
| 内存 | 512MB | 2GB+ |
| 存储 | 1GB | 10GB+ |
| 操作系统 | Linux/Windows/macOS | Ubuntu 22.04 |

### 数据库

| 数据库 | 版本要求 |
|--------|---------|
| MySQL | 8.0+ |
| PostgreSQL | 14+ |
| Redis | 6.0+ |

---

## 快速部署

### Docker 部署（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/polyvault/polyvault.git
cd polyvault

# 2. 配置环境变量
cp .env.example .env
# 编辑 .env 文件

# 3. 启动服务
docker-compose up -d

# 4. 查看日志
docker-compose logs -f
```

### Docker Compose 配置

```yaml
version: '3.8'

services:
  api:
    image: polyvault/api:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=mysql://user:pass@db:3306/polyvault
      - REDIS_URL=redis://cache:6379
      - JWT_SECRET=your-secret-key
    depends_on:
      - db
      - cache
    restart: unless-stopped

  db:
    image: mysql:8.0
    environment:
      - MYSQL_ROOT_PASSWORD=rootpass
      - MYSQL_DATABASE=polyvault
      - MYSQL_USER=polyvault
      - MYSQL_PASSWORD=polyvault
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

  cache:
    image: redis:7-alpine
    volumes:
      - cache_data:/data
    restart: unless-stopped

volumes:
  db_data:
  cache_data:
```

---

## 手动部署

### 1. 安装依赖

```bash
# Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# MySQL
sudo apt-get install -y mysql-server

# Redis
sudo apt-get install -y redis-server
```

### 2. 配置数据库

```sql
-- 创建数据库
CREATE DATABASE polyvault CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 创建用户
CREATE USER 'polyvault'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON polyvault.* TO 'polyvault'@'localhost';
FLUSH PRIVILEGES;
```

### 3. 安装应用

```bash
# 克隆仓库
git clone https://github.com/polyvault/polyvault.git
cd polyvault

# 安装依赖
npm ci

# 配置环境变量
cp .env.example .env
nano .env
```

### 4. 环境变量配置

```bash
# .env 文件内容

# 应用配置
NODE_ENV=production
PORT=3000

# 数据库配置
DATABASE_URL=mysql://polyvault:password@localhost:3306/polyvault

# Redis配置
REDIS_URL=redis://localhost:6379

# JWT配置
JWT_SECRET=your-256-bit-secret-key
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=7d

# 加密配置
ENCRYPTION_KEY=your-32-byte-encryption-key

# 邮件配置
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@polyvault.io
SMTP_PASS=your-smtp-password
```

### 5. 运行迁移

```bash
# 运行数据库迁移
npm run migrate

# （可选）填充种子数据
npm run seed
```

### 6. 启动服务

```bash
# 使用 PM2（推荐）
npm install -g pm2
pm2 start npm --name "polyvault-api" -- start
pm2 save
pm2 startup

# 或直接运行
npm start
```

---

## SSL 配置

### 使用 Nginx 反向代理

```nginx
server {
    listen 443 ssl http2;
    server_name api.polyvault.io;

    ssl_certificate /etc/letsencrypt/live/polyvault.io/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/polyvault.io/privkey.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

server {
    listen 80;
    server_name api.polyvault.io;
    return 301 https://$server_name$request_uri;
}
```

### 使用 Let's Encrypt

```bash
# 安装 Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d api.polyvault.io

# 自动续期
sudo certbot renew --dry-run
```

---

## 移动端部署

### Flutter 客户端构建

```bash
# Android
cd src/client
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 应用签名

**Android**:
```bash
# 创建签名密钥
keytool -genkey -v -keystore polyvault.keystore -alias polyvault -keyalg RSA -keysize 2048 -validity 10000

# 配置 build.gradle
android {
    signingConfigs {
        release {
            storeFile file("polyvault.keystore")
            storePassword "password"
            keyAlias "polyvault"
            keyPassword "password"
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

---

## 监控与日志

### 日志配置

```javascript
// 使用 Winston 日志
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
  ],
});
```

### 健康检查端点

```
GET /health
```

响应：
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": 86400,
  "database": "connected",
  "redis": "connected"
}
```

---

## 备份策略

### 数据库备份

```bash
# 每日备份脚本
#!/bin/bash
DATE=$(date +%Y%m%d)
mysqldump -u polyvault -p'password' polyvault > /backup/polyvault_$DATE.sql
# 保留最近7天
find /backup -name "polyvault_*.sql" -mtime +7 -delete
```

### 定时任务

```cron
# crontab -e
0 2 * * * /scripts/backup.sh
```

---

## 故障排查

### 常见问题

1. **数据库连接失败**
   ```bash
   # 检查MySQL状态
   sudo systemctl status mysql
   # 检查连接配置
   mysql -u polyvault -p -h localhost polyvault
   ```

2. **Redis连接失败**
   ```bash
   # 检查Redis状态
   sudo systemctl status redis
   redis-cli ping
   ```

3. **内存不足**
   ```bash
   # 检查内存使用
   free -h
   # 重启服务
   pm2 restart polyvault-api
   ```

---

## 更新指南

```bash
# 拉取最新代码
git pull origin main

# 安装依赖
npm ci

# 运行迁移
npm run migrate

# 重启服务
pm2 restart polyvault-api
```