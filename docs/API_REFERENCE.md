# PolyVault API 文档

**版本**: v4.2.1  
**最后更新**: 2026-03-22  
**Base URL**: `http://localhost:8080/api/v1`  
**状态**: ✅ 已与代码同步

---

## 概述

PolyVault提供RESTful API用于凭证管理、设备同步和安全操作。

---

## 认证

### Bearer Token

```http
Authorization: Bearer <token>
```

Token通过主密码派生，存储在本地。

---

## 凭证API

### 获取凭证列表

```http
GET /credentials
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "credentials": [
      {
        "id": "cred_001",
        "title": "GitHub",
        "username": "user@example.com",
        "url": "https://github.com",
        "tags": ["dev", "work"],
        "createdAt": "2026-03-01T00:00:00Z"
      }
    ],
    "total": 10
  }
}
```

### 创建凭证

```http
POST /credentials
Content-Type: application/json

{
  "title": "New Site",
  "username": "user@example.com",
  "password": "secure_password",
  "url": "https://example.com",
  "tags": ["personal"]
}
```

### 获取凭证详情

```http
GET /credentials/{id}
```

### 更新凭证

```http
PUT /credentials/{id}
Content-Type: application/json

{
  "title": "Updated Title",
  "password": "new_password"
}
```

### 删除凭证

```http
DELETE /credentials/{id}
```

---

## 设备API

### 获取设备列表

```http
GET /devices
```

### 授权设备

```http
POST /devices/authorize
Content-Type: application/json

{
  "deviceId": "device_001",
  "deviceName": "MacBook Pro"
}
```

### 撤销设备

```http
DELETE /devices/{deviceId}
```

---

## 同步API

### 获取同步状态

```http
GET /sync/status
```

**响应**:
```json
{
  "code": 200,
  "data": {
    "lastSync": "2026-03-22T02:00:00Z",
    "pendingChanges": 0,
    "connectedDevices": 2
  }
}
```

### 触发同步

```http
POST /sync/trigger
```

---

## 安全API

### 验证主密码

```http
POST /auth/verify
Content-Type: application/json

{
  "password": "master_password"
}
```

### 获取安全状态

```http
GET /security/status
```

---

## 错误码

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 500 | 服务器错误 |

---

**技术支持**: support@polyvault.io