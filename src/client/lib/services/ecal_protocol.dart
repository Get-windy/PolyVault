/// eCAL 协议定义 - 与 C++ Agent 的消息格式对齐
/// 基于 openclaw.proto 的 Dart 实现

import 'dart:convert';
import 'dart:typed_data';

// ============================================================================
// 基础消息类型
// ============================================================================

/// P2P消息信封
class P2PEnvelope {
  final String sourceId;
  final String? targetId;
  final String messageId;
  final String messageType;
  final int timestamp;
  final Uint8List payload;
  final Uint8List? signature;

  P2PEnvelope({
    required this.sourceId,
    this.targetId,
    required this.messageId,
    required this.messageType,
    int? timestamp,
    required this.payload,
    this.signature,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory P2PEnvelope.fromJson(Map<String, dynamic> json) {
    return P2PEnvelope(
      sourceId: json['source_id'] as String,
      targetId: json['target_id'] as String?,
      messageId: json['message_id'] as String,
      messageType: json['message_type'] as String,
      timestamp: json['timestamp'] as int,
      payload: _decodeBase64(json['payload'] as String),
      signature: json['signature'] != null 
          ? _decodeBase64(json['signature'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_id': sourceId,
      'target_id': targetId,
      'message_id': messageId,
      'message_type': messageType,
      'timestamp': timestamp,
      'payload': base64Encode(payload),
      'signature': signature != null ? base64Encode(signature!) : null,
    };
  }

  static Uint8List _decodeBase64(String s) {
    return base64Decode(s);
  }
}

// ============================================================================
// 设备发现
// ============================================================================

/// 设备类型
enum DeviceType {
  phone,
  desktop,
  embedded,
  tablet,
  unknown;

  String get name {
    switch (this) {
      case DeviceType.phone: return 'phone';
      case DeviceType.desktop: return 'desktop';
      case DeviceType.embedded: return 'embedded';
      case DeviceType.tablet: return 'tablet';
      case DeviceType.unknown: return 'unknown';
    }
  }

  static DeviceType fromString(String s) {
    return DeviceType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => DeviceType.unknown,
    );
  }
}

/// 平台类型
enum Platform {
  android,
  ios,
  windows,
  linux,
  macos,
  web,
  unknown;

  String get name {
    switch (this) {
      case Platform.android: return 'android';
      case Platform.ios: return 'ios';
      case Platform.windows: return 'windows';
      case Platform.linux: return 'linux';
      case Platform.macos: return 'macos';
      case Platform.web: return 'web';
      case Platform.unknown: return 'unknown';
    }
  }

  static Platform fromString(String s) {
    return Platform.values.firstWhere(
      (e) => e.name == s,
      orElse: () => Platform.unknown,
    );
  }
}

/// 发现消息
class DiscoveryMessage {
  final String deviceId;
  final String deviceName;
  final DeviceType deviceType;
  final Platform platform;
  final String version;
  final List<String> capabilities;
  final String? endpoint;
  final int timestamp;

  DiscoveryMessage({
    required this.deviceId,
    required this.deviceName,
    this.deviceType = DeviceType.phone,
    this.platform = Platform.unknown,
    this.version = '1.0.0',
    this.capabilities = const [],
    this.endpoint,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory DiscoveryMessage.fromJson(Map<String, dynamic> json) {
    return DiscoveryMessage(
      deviceId: json['device_id'] as String,
      deviceName: json['device_name'] as String,
      deviceType: DeviceType.fromString(json['device_type'] as String? ?? 'unknown'),
      platform: Platform.fromString(json['platform'] as String? ?? 'unknown'),
      version: json['version'] as String? ?? '1.0.0',
      capabilities: (json['capabilities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      endpoint: json['endpoint'] as String?,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'device_type': deviceType.name,
      'platform': platform.name,
      'version': version,
      'capabilities': capabilities,
      'endpoint': endpoint,
      'timestamp': timestamp,
    };
  }
}

/// 发现响应
class DiscoveryResponse {
  final String deviceId;
  final bool accept;
  final String? endpoint;
  final int timestamp;

  DiscoveryResponse({
    required this.deviceId,
    required this.accept,
    this.endpoint,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory DiscoveryResponse.fromJson(Map<String, dynamic> json) {
    return DiscoveryResponse(
      deviceId: json['device_id'] as String,
      accept: json['accept'] as bool,
      endpoint: json['endpoint'] as String?,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'accept': accept,
      'endpoint': endpoint,
      'timestamp': timestamp,
    };
  }
}

// ============================================================================
// 凭证操作
// ============================================================================

/// 凭证请求
class CredentialRequest {
  final String serviceUrl;
  final String sessionId;
  final int timestamp;
  final String? purpose;
  final Map<String, String>? context;

  CredentialRequest({
    required this.serviceUrl,
    required this.sessionId,
    int? timestamp,
    this.purpose,
    this.context,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory CredentialRequest.fromJson(Map<String, dynamic> json) {
    return CredentialRequest(
      serviceUrl: json['service_url'] as String,
      sessionId: json['session_id'] as String,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      purpose: json['purpose'] as String?,
      context: (json['context'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_url': serviceUrl,
      'session_id': sessionId,
      'timestamp': timestamp,
      'purpose': purpose,
      'context': context,
    };
  }
}

/// 凭证数据
class CredentialData {
  final String username;
  final String? password;
  final Map<String, String>? additional;

  CredentialData({
    required this.username,
    this.password,
    this.additional,
  });

  factory CredentialData.fromJson(Map<String, dynamic> json) {
    return CredentialData(
      username: json['username'] as String,
      password: json['password'] as String?,
      additional: (json['additional'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as String)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'additional': additional,
    };
  }
}

/// 凭证响应
class CredentialResponse {
  final String sessionId;
  final Uint8List? encryptedCredential;
  final bool success;
  final String? errorMessage;
  final int timestamp;

  CredentialResponse({
    required this.sessionId,
    this.encryptedCredential,
    required this.success,
    this.errorMessage,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory CredentialResponse.fromJson(Map<String, dynamic> json) {
    return CredentialResponse(
      sessionId: json['session_id'] as String,
      encryptedCredential: json['encrypted_credential'] != null
          ? base64Decode(json['encrypted_credential'] as String)
          : null,
      success: json['success'] as bool,
      errorMessage: json['error_message'] as String?,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'encrypted_credential': encryptedCredential != null
          ? base64Encode(encryptedCredential!)
          : null,
      'success': success,
      'error_message': errorMessage,
      'timestamp': timestamp,
    };
  }
}

/// 凭证存储请求
class CredentialStoreRequest {
  final String serviceUrl;
  final Uint8List encryptedCredential;
  final String sessionId;
  final int? expiresAt;

  CredentialStoreRequest({
    required this.serviceUrl,
    required this.encryptedCredential,
    required this.sessionId,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_url': serviceUrl,
      'encrypted_credential': base64Encode(encryptedCredential),
      'session_id': sessionId,
      'expires_at': expiresAt,
    };
  }
}

// ============================================================================
// Cookie 管理
// ============================================================================

/// Cookie 数据
class CookieData {
  final String name;
  final String value;
  final String domain;
  final String? path;
  final int? expires;
  final bool secure;
  final bool httpOnly;

  CookieData({
    required this.name,
    required this.value,
    required this.domain,
    this.path,
    this.expires,
    this.secure = false,
    this.httpOnly = false,
  });

  factory CookieData.fromJson(Map<String, dynamic> json) {
    return CookieData(
      name: json['name'] as String,
      value: json['value'] as String,
      domain: json['domain'] as String,
      path: json['path'] as String?,
      expires: json['expires'] as int?,
      secure: json['secure'] as bool? ?? false,
      httpOnly: json['http_only'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'domain': domain,
      'path': path,
      'expires': expires,
      'secure': secure,
      'http_only': httpOnly,
    };
  }
}

/// Cookie 上传请求
class CookieUploadRequest {
  final String serviceUrl;
  final Uint8List encryptedCookie;
  final String sessionId;
  final int? expiresAt;

  CookieUploadRequest({
    required this.serviceUrl,
    required this.encryptedCookie,
    required this.sessionId,
    this.expiresAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_url': serviceUrl,
      'encrypted_cookie': base64Encode(encryptedCookie),
      'session_id': sessionId,
      'expires_at': expiresAt,
    };
  }
}

/// Cookie 下载请求
class CookieDownloadRequest {
  final String serviceUrl;
  final String sessionId;

  CookieDownloadRequest({
    required this.serviceUrl,
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_url': serviceUrl,
      'session_id': sessionId,
    };
  }
}

/// Cookie 下载响应
class CookieDownloadResponse {
  final String sessionId;
  final Uint8List? encryptedCookie;
  final bool success;
  final String? errorMessage;
  final int timestamp;

  CookieDownloadResponse({
    required this.sessionId,
    this.encryptedCookie,
    required this.success,
    this.errorMessage,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory CookieDownloadResponse.fromJson(Map<String, dynamic> json) {
    return CookieDownloadResponse(
      sessionId: json['session_id'] as String,
      encryptedCookie: json['encrypted_cookie'] != null
          ? base64Decode(json['encrypted_cookie'] as String)
          : null,
      success: json['success'] as bool,
      errorMessage: json['error_message'] as String?,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// ============================================================================
// 安全与认证
// ============================================================================

/// 握手请求
class HandshakeRequest {
  final String deviceId;
  final Uint8List publicKey;
  final String protocolVersion;
  final int timestamp;
  final Uint8List challenge;

  HandshakeRequest({
    required this.deviceId,
    required this.publicKey,
    this.protocolVersion = '1.0.0',
    int? timestamp,
    required this.challenge,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'public_key': base64Encode(publicKey),
      'protocol_version': protocolVersion,
      'timestamp': timestamp,
      'challenge': base64Encode(challenge),
    };
  }
}

/// 握手响应
class HandshakeResponse {
  final String deviceId;
  final bool accept;
  final Uint8List? publicKey;
  final Uint8List? encryptedSessionKey;
  final Uint8List? challengeResponse;
  final int timestamp;

  HandshakeResponse({
    required this.deviceId,
    required this.accept,
    this.publicKey,
    this.encryptedSessionKey,
    this.challengeResponse,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory HandshakeResponse.fromJson(Map<String, dynamic> json) {
    return HandshakeResponse(
      deviceId: json['device_id'] as String,
      accept: json['accept'] as bool,
      publicKey: json['public_key'] != null
          ? base64Decode(json['public_key'] as String)
          : null,
      encryptedSessionKey: json['encrypted_session_key'] != null
          ? base64Decode(json['encrypted_session_key'] as String)
          : null,
      challengeResponse: json['challenge_response'] != null
          ? base64Decode(json['challenge_response'] as String)
          : null,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

/// 认证请求
class AuthenticationRequest {
  final String deviceId;
  final Uint8List signedToken;
  final int timestamp;

  AuthenticationRequest({
    required this.deviceId,
    required this.signedToken,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'signed_token': base64Encode(signedToken),
      'timestamp': timestamp,
    };
  }
}

/// 认证响应
class AuthenticationResponse {
  final bool success;
  final String? errorMessage;
  final int trustLevel;
  final int timestamp;

  AuthenticationResponse({
    required this.success,
    this.errorMessage,
    this.trustLevel = 0,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory AuthenticationResponse.fromJson(Map<String, dynamic> json) {
    return AuthenticationResponse(
      success: json['success'] as bool,
      errorMessage: json['error_message'] as String?,
      trustLevel: json['trust_level'] as int? ?? 0,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// ============================================================================
// 心跳与状态
// ============================================================================

/// 设备状态
class DeviceStatus {
  final bool online;
  final double batteryLevel;
  final String networkType;
  final int activeSessions;

  DeviceStatus({
    this.online = true,
    this.batteryLevel = 100.0,
    this.networkType = 'unknown',
    this.activeSessions = 0,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      online: json['online'] as bool? ?? true,
      batteryLevel: (json['battery_level'] as num?)?.toDouble() ?? 100.0,
      networkType: json['network_type'] as String? ?? 'unknown',
      activeSessions: json['active_sessions'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'online': online,
      'battery_level': batteryLevel,
      'network_type': networkType,
      'active_sessions': activeSessions,
    };
  }
}

/// 心跳消息
class Heartbeat {
  final String deviceId;
  final int timestamp;
  final int sequence;
  final DeviceStatus? status;

  Heartbeat({
    required this.deviceId,
    int? timestamp,
    this.sequence = 0,
    this.status,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'timestamp': timestamp,
      'sequence': sequence,
      'status': status?.toJson(),
    };
  }
}

/// 心跳确认
class HeartbeatAck {
  final String deviceId;
  final int timestamp;
  final int sequence;

  HeartbeatAck({
    required this.deviceId,
    required this.timestamp,
    required this.sequence,
  });

  factory HeartbeatAck.fromJson(Map<String, dynamic> json) {
    return HeartbeatAck(
      deviceId: json['device_id'] as String,
      timestamp: json['timestamp'] as int,
      sequence: json['sequence'] as int,
    );
  }
}

// ============================================================================
// 同步消息
// ============================================================================

/// 同步项
class SyncItem {
  final String type;
  final String key;
  final Uint8List encryptedData;
  final int version;
  final int timestamp;

  SyncItem({
    required this.type,
    required this.key,
    required this.encryptedData,
    required this.version,
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory SyncItem.fromJson(Map<String, dynamic> json) {
    return SyncItem(
      type: json['type'] as String,
      key: json['key'] as String,
      encryptedData: base64Decode(json['encrypted_data'] as String),
      version: json['version'] as int,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'key': key,
      'encrypted_data': base64Encode(encryptedData),
      'version': version,
      'timestamp': timestamp,
    };
  }
}

/// 同步请求
class SyncRequest {
  final String syncId;
  final int sinceTimestamp;
  final List<String> dataTypes;

  SyncRequest({
    required this.syncId,
    required this.sinceTimestamp,
    this.dataTypes = const ['credentials', 'cookies', 'settings'],
  });

  Map<String, dynamic> toJson() {
    return {
      'sync_id': syncId,
      'since_timestamp': sinceTimestamp,
      'data_types': dataTypes,
    };
  }
}

/// 同步响应
class SyncResponse {
  final String syncId;
  final bool success;
  final List<SyncItem> items;
  final int timestamp;

  SyncResponse({
    required this.syncId,
    required this.success,
    this.items = const [],
    int? timestamp,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    return SyncResponse(
      syncId: json['sync_id'] as String,
      success: json['success'] as bool,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => SyncItem.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }
}

// ============================================================================
// 错误处理
// ============================================================================

/// 错误消息
class ErrorMessage {
  final String? messageId;
  final int errorCode;
  final String errorMessage;
  final bool retryable;
  final int? retryAfterMs;

  ErrorMessage({
    this.messageId,
    required this.errorCode,
    required this.errorMessage,
    this.retryable = false,
    this.retryAfterMs,
  });

  factory ErrorMessage.fromJson(Map<String, dynamic> json) {
    return ErrorMessage(
      messageId: json['message_id'] as String?,
      errorCode: json['error_code'] as int,
      errorMessage: json['error_message'] as String,
      retryable: json['retryable'] as bool? ?? false,
      retryAfterMs: json['retry_after_ms'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'error_code': errorCode,
      'error_message': errorMessage,
      'retryable': retryable,
      'retry_after_ms': retryAfterMs,
    };
  }
}

// ============================================================================
// 事件类型
// ============================================================================

/// 事件类型
enum EventType {
  credentialAccess,
  credentialStore,
  credentialDelete,
  devicePair,
  deviceUnpair,
  syncStart,
  syncComplete,
  error,
  unknown;

  String get name {
    switch (this) {
      case EventType.credentialAccess: return 'credential_access';
      case EventType.credentialStore: return 'credential_store';
      case EventType.credentialDelete: return 'credential_delete';
      case EventType.devicePair: return 'device_pair';
      case EventType.deviceUnpair: return 'device_unpair';
      case EventType.syncStart: return 'sync_start';
      case EventType.syncComplete: return 'sync_complete';
      case EventType.error: return 'error';
      case EventType.unknown: return 'unknown';
    }
  }

  static EventType fromString(String s) {
    return EventType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => EventType.unknown,
    );
  }
}

/// 事件消息
class Event {
  final String eventId;
  final EventType type;
  final String deviceId;
  final int timestamp;
  final String message;
  final Map<String, dynamic>? data;

  Event({
    required this.eventId,
    required this.type,
    required this.deviceId,
    int? timestamp,
    required this.message,
    this.data,
  }) : timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'] as String,
      type: EventType.fromString(json['type'] as String? ?? 'unknown'),
      deviceId: json['device_id'] as String,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'type': type.name,
      'device_id': deviceId,
      'timestamp': timestamp,
      'message': message,
      'data': data,
    };
  }
}