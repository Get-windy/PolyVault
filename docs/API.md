# PolyVault API 文档

**版本**: v1.0.0  
**更新时间**: 2026-03-24

---

## 概述

PolyVault 是一个跨设备凭证管理平台，提供安全的密码存储、设备管理和数据同步功能。

### 基础URL

```
开发环境: http://localhost:3000/api
生产环境: https://api.polyvault.io/api
```

### 认证方式

使用 Bearer Token 认证：
```
Authorization: Bearer <access_token>
```

---

## 认证 API

### POST /auth/register

注册新用户

**请求体**:
```json
{
  "username": "string",
  "email": "string",
  "password": "string",
  "userType": "human" | "ai"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "userId": "string",
    "username": "string",
    "email": "string"
  }
}
```

### POST /auth/login

用户登录

**请求体**:
```json
{
  "email": "string",
  "password": "string"
}
```

**响应**:
```json
{
  "success": true,
  "data": {
    "accessToken": "string",
    "refreshToken": "string",
    "expiresIn": 900
  }
}
```

### POST /auth/refresh-token

刷新访问令牌

**请求体**:
```json
{
  "refreshToken": "string"
}
```

### POST /auth/logout

登出当前设备

### POST /auth/logout-all

登出所有设备

---

## 凭证 API

### GET /credentials

获取凭证列表

**查询参数**:
- `page` - 页码 (默认: 1)
- `limit` - 每页数量 (默认: 20)
- `search` - 搜索关键词
- `category` - 分类过滤

**响应**:
```json
{
  "success": true,
  "data": {
    "credentials": [
      {
        "id": "string",
        "serviceName": "string",
        "username": "string",
        "category": "string",
        "createdAt": "ISO8601",
        "lastUsed": "ISO8601"
      }
    ],
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

### GET /credentials/:id

获取凭证详情

### POST /credentials

创建新凭证

**请求体**:
```json
{
  "serviceName": "string",
  "username": "string",
  "password": "string",
  "url": "string?",
  "notes": "string?",
  "category": "string?"
}
```

### PUT /credentials/:id

更新凭证

### DELETE /credentials/:id

删除凭证

---

## 设备 API

### GET /devices

获取已登录设备列表

**响应**:
```json
{
  "success": true,
  "data": {
    "devices": [
      {
        "id": "string",
        "name": "string",
        "type": "desktop" | "mobile" | "tablet",
        "platform": "string",
        "lastActive": "ISO8601",
        "isCurrent": true,
        "isTrusted": true
      }
    ]
  }
}
```

### DELETE /devices/:id

移除设备

### POST /devices/trust

信任设备

---

## 同步 API

### POST /sync/request

请求同步

**响应**:
```json
{
  "success": true,
  "data": {
    "syncId": "string",
    "devices": [
      {
        "deviceId": "string",
        "status": "pending"
      }
    ]
  }
}
```

### GET /sync/status/:syncId

获取同步状态

---

## 担保 API

### GET /guarantee/info/:userId

获取用户担保信息

### POST /guarantee/request

请求担保

**请求体**:
```json
{
  "targetUserId": "string",
  "message": "string"
}
```

### POST /guarantee/approve

批准担保请求

**请求体**:
```json
{
  "requestId": "string"
}
```

### POST /guarantee/reject

拒绝担保请求

---

## 错误响应

所有错误响应格式：

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "错误描述",
    "details": {}
  }
}
```

### 错误码

| 错误码 | HTTP状态码 | 描述 |
|--------|-----------|------|
| AUTH_001 | 401 | 未授权 |
| AUTH_002 | 403 | 权限不足 |
| VALIDATION_001 | 400 | 参数验证失败 |
| NOT_FOUND | 404 | 资源不存在 |
| RATE_LIMIT | 429 | 请求过于频繁 |
| SERVER_ERROR | 500 | 服务器内部错误 |

---

## 限流

- 认证接口: 10次/分钟
- 普通接口: 100次/分钟
- 同步接口: 10次/分钟

超过限制返回 429 状态码。

---

## SDK 示例

### JavaScript/TypeScript

```typescript
import { PolyVaultClient } from '@polyvault/sdk';

const client = new PolyVaultClient({
  baseUrl: 'https://api.polyvault.io/api',
});

// 登录
await client.auth.login({
  email: 'user@example.com',
  password: 'password123',
});

// 获取凭证
const credentials = await client.credentials.list();

// 创建凭证
await client.credentials.create({
  serviceName: 'GitHub',
  username: 'user',
  password: 'secret',
});
```

### Flutter

```dart
import 'package:polyvault/polyvault.dart';

final client = PolyVaultClient(
  baseUrl: 'https://api.polyvault.io/api',
);

await client.auth.login(
  email: 'user@example.com',
  password: 'password123',
);

final credentials = await client.credentials.list();
```

---

## 更新日志

### v1.0.0 (2026-03-24)
- 初始版本发布
- 基础认证功能
- 凭证管理
- 设备管理
- 同步功能
- 担保系统