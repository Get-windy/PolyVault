# PolyVault Protobuf协议定义

## 概述

`openclaw.proto` 定义了PolyVault远程授信系统的完整通信协议。

---

## 消息类型

### 设备管理

| 消息 | 用途 |
|------|------|
| `DeviceInfo` | 设备信息（ID、类型、能力等） |
| `DeviceRegisterRequest` | 设备注册请求 |
| `DeviceRegisterResponse` | 设备注册响应 |
| `DeviceHeartbeat` | 设备心跳 |
| `DeviceListRequest/Response` | 设备列表查询 |

### 凭证管理

| 消息 | 用途 |
|------|------|
| `CredentialRequest` | 凭证请求 |
| `CredentialResponse` | 凭证响应 |
| `CredentialStoreRequest/Response` | 存储凭证 |
| `CredentialDeleteRequest/Response` | 删除凭证 |

### Cookie管理

| 消息 | 用途 |
|------|------|
| `CookieItem` | 单个Cookie |
| `CookieUploadRequest/Response` | 上传Cookie |
| `CookieDownloadRequest/Response` | 下载Cookie |

### 授权流程

| 消息 | 用途 |
|------|------|
| `AuthorizationRequest` | 授权请求 |
| `AuthorizationResponse` | 授权响应 |
| `AuthorizationCancelRequest/Response` | 取消授权 |

### 同步备份

| 消息 | 用途 |
|------|------|
| `SyncRequest` | 同步请求 |
| `SyncData` | 同步数据 |
| `SyncResponse` | 同步响应 |

---

## 枚举类型

### DeviceType
```
UNSPECIFIED | ANDROID | IOS | WINDOWS | MACOS | LINUX | HARMONY | EMBEDDED
```

### CredentialType
```
UNSPECIFIED | PASSWORD | OAUTH | API_KEY | CERTIFICATE | COOKIE
```

### AuthorizationStatus
```
UNSPECIFIED | PENDING | APPROVED | DENIED | TIMEOUT | CANCELED
```

### CapabilityType
```
UNSPECIFIED | CREDENTIAL_PROVIDER | COOKIE_STORAGE | BIOMETRIC_AUTH | SECURE_DISPLAY | SENSOR_DATA | LOCATION
```

---

## 服务定义

### CredentialService（客户端提供）

| 方法 | 请求 | 响应 |
|------|------|------|
| GetCredential | CredentialRequest | CredentialResponse |
| StoreCredential | CredentialStoreRequest | CredentialStoreResponse |
| DeleteCredential | CredentialDeleteRequest | CredentialDeleteResponse |
| UploadCookie | CookieUploadRequest | CookieUploadResponse |
| DownloadCookie | CookieDownloadRequest | CookieDownloadResponse |

### DeviceService（管理服务）

| 方法 | 请求 | 响应 |
|------|------|------|
| RegisterDevice | DeviceRegisterRequest | DeviceRegisterResponse |
| Heartbeat | DeviceHeartbeat | Empty |
| ListDevices | DeviceListRequest | DeviceListResponse |
| DiscoverCapabilities | CapabilityDiscoveryRequest | CapabilityDiscoveryResponse |

### AuthorizationService（Agent提供）

| 方法 | 请求 | 响应 |
|------|------|------|
| RequestAuthorization | AuthorizationRequest | AuthorizationResponse |
| CancelAuthorization | AuthorizationCancelRequest | AuthorizationCancelResponse |

### SyncService

| 方法 | 请求 | 响应 |
|------|------|------|
| Sync | SyncRequest | SyncResponse |

---

## 通信流程

### 1. 设备注册
```
客户端 -> DeviceService.RegisterDevice -> 服务端
服务端 -> DeviceRegisterResponse -> 客户端
```

### 2. 凭证请求
```
Agent -> CredentialService.GetCredential -> 客户端
客户端 -> CredentialResponse -> Agent
```

### 3. 授权流程
```
Agent -> AuthorizationService.RequestAuthorization -> 客户端
用户批准/拒绝
客户端 -> AuthorizationResponse -> Agent
```

---

## 版本

- **协议版本**: 1.0
- **创建日期**: 2026-03-13
- **最后更新**: 2026-03-13