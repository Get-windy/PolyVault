/**
 * @file test_protobuf_serialization.cpp
 * @brief Protobuf 序列化/反序列化单元测试
 * 
 * 测试内容:
 * 1. 基础消息类型序列化
 * 2. 凭证请求/响应序列化
 * 3. 设备管理消息序列化
 * 4. Cookie 消息序列化
 * 5. 复杂嵌套消息序列化
 * 6. 边界情况测试
 */

#include <iostream>
#include <cassert>
#include <string>
#include <vector>
#include <cstring>
#include "openclaw.pb.h"

// 测试统计
struct TestStats {
    int passed = 0;
    int failed = 0;
    
    void report(const std::string& test_name, bool success) {
        if (success) {
            std::cout << "[PASS] " << test_name << std::endl;
            passed++;
        } else {
            std::cout << "[FAIL] " << test_name << std::endl;
            failed++;
        }
    }
    
    void summary() {
        std::cout << "\n========================================" << std::endl;
        std::cout << "测试总结：" << std::endl;
        std::cout << "  通过：" << passed << std::endl;
        std::cout << "  失败：" << failed << std::endl;
        std::cout << "  总计：" << (passed + failed) << std::endl;
        std::cout << "========================================" << std::endl;
    }
};

static TestStats stats;

// 辅助宏
#define TEST(name) bool test_##name()
#define RUN_TEST(name) stats.report(#name, test_##name())
#define ASSERT_TRUE(expr) if (!(expr)) { std::cerr << "  Assertion failed: " << #expr << std::endl; return false; }
#define ASSERT_FALSE(expr) if (expr) { std::cerr << "  Assertion failed: NOT " << #expr << std::endl; return false; }
#define ASSERT_EQ(a, b) if ((a) != (b)) { std::cerr << "  Assertion failed: " << #a << " != " << #b << std::endl; return false; }
#define ASSERT_NE(a, b) if ((a) == (b)) { std::cerr << "  Assertion failed: " << #a << " == " << #b << std::endl; return false; }

// ============================================================================
// 基础类型测试
// ============================================================================

TEST(device_type_enum) {
    // 测试设备类型枚举
    openclaw::DeviceInfo device;
    device.set_device_type(openclaw::DEVICE_TYPE_WINDOWS);
    
    ASSERT_EQ(device.device_type(), openclaw::DEVICE_TYPE_WINDOWS);
    
    device.set_device_type(openclaw::DEVICE_TYPE_ANDROID);
    ASSERT_EQ(device.device_type(), openclaw::DEVICE_TYPE_ANDROID);
    
    return true;
}

TEST(credential_type_enum) {
    // 测试凭证类型枚举
    openclaw::CredentialRequest request;
    request.set_credential_type(openclaw::CREDENTIAL_TYPE_PASSWORD);
    
    ASSERT_EQ(request.credential_type(), openclaw::CREDENTIAL_TYPE_PASSWORD);
    
    request.set_credential_type(openclaw::CREDENTIAL_TYPE_COOKIE);
    ASSERT_EQ(request.credential_type(), openclaw::CREDENTIAL_TYPE_COOKIE);
    
    return true;
}

TEST(authorization_status_enum) {
    // 测试授权状态枚举
    openclaw::CredentialResponse response;
    response.set_status(openclaw::AUTH_STATUS_APPROVED);
    
    ASSERT_EQ(response.status(), openclaw::AUTH_STATUS_APPROVED);
    
    response.set_status(openclaw::AUTH_STATUS_DENIED);
    ASSERT_EQ(response.status(), openclaw::AUTH_STATUS_DENIED);
    
    return true;
}

// ============================================================================
// 设备管理消息测试
// ============================================================================

TEST(device_info_serialization) {
    // 测试设备信息序列化
    openclaw::DeviceInfo device;
    device.set_device_id("device_12345");
    device.set_device_name("My Windows PC");
    device.set_device_type(openclaw::DEVICE_TYPE_WINDOWS);
    device.set_platform_version("Windows 11 23H2");
    device.set_app_version("1.0.0");
    device.set_last_active_time(1711000000);
    device.set_is_online(true);
    device.add_capabilities("credential_provider");
    device.add_capabilities("cookie_storage");
    
    // 序列化
    std::string serialized;
    bool success = device.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    ASSERT_TRUE(!serialized.empty());
    
    // 反序列化
    openclaw::DeviceInfo deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    // 验证字段
    ASSERT_EQ(deserialized.device_id(), "device_12345");
    ASSERT_EQ(deserialized.device_name(), "My Windows PC");
    ASSERT_EQ(deserialized.device_type(), openclaw::DEVICE_TYPE_WINDOWS);
    ASSERT_EQ(deserialized.platform_version(), "Windows 11 23H2");
    ASSERT_EQ(deserialized.app_version(), "1.0.0");
    ASSERT_EQ(deserialized.last_active_time(), 1711000000);
    ASSERT_TRUE(deserialized.is_online());
    ASSERT_EQ(deserialized.capabilities_size(), 2);
    ASSERT_EQ(deserialized.capabilities(0), "credential_provider");
    ASSERT_EQ(deserialized.capabilities(1), "cookie_storage");
    
    return true;
}

TEST(device_register_request_serialization) {
    // 测试设备注册请求序列化
    openclaw::DeviceRegisterRequest request;
    
    auto* device = request.mutable_device();
    device->set_device_id("new_device_001");
    device->set_device_name("New Device");
    device->set_device_type(openclaw::DEVICE_TYPE_IOS);
    
    request.set_public_key("public_key_data_here");
    request.set_device_token("apns_token_12345");
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::DeviceRegisterResponse response;
    // 注意：这里应该用 DeviceRegisterResponse 来测试响应
    openclaw::DeviceRegisterRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.device().device_id(), "new_device_001");
    ASSERT_EQ(deserialized.public_key(), "public_key_data_here");
    ASSERT_EQ(deserialized.device_token(), "apns_token_12345");
    
    return true;
}

TEST(device_heartbeat_serialization) {
    // 测试设备心跳序列化
    openclaw::DeviceHeartbeat heartbeat;
    heartbeat.set_device_id("device_123");
    heartbeat.set_timestamp(1711000000);
    
    (*heartbeat.mutable_status())["battery"] = "85%";
    (*heartbeat.mutable_status())["network"] = "wifi";
    (*heartbeat.mutable_status())["signal"] = "strong";
    
    // 序列化
    std::string serialized;
    bool success = heartbeat.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::DeviceHeartbeat deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.device_id(), "device_123");
    ASSERT_EQ(deserialized.timestamp(), 1711000000);
    ASSERT_EQ(deserialized.status().at("battery"), "85%");
    ASSERT_EQ(deserialized.status().at("network"), "wifi");
    
    return true;
}

// ============================================================================
// 凭证请求/响应测试
// ============================================================================

TEST(credential_request_serialization) {
    // 测试凭证请求序列化
    openclaw::CredentialRequest request;
    request.set_request_id("req_uuid_12345");
    request.set_service_url("https://accounts.google.com");
    request.set_service_name("Google");
    request.set_credential_type(openclaw::CREDENTIAL_TYPE_OAUTH);
    request.set_timestamp(1711000000);
    request.set_timeout_seconds(300);
    request.set_reason("Need to access Gmail");
    
    (*request.mutable_context())["scope"] = "email profile";
    (*request.mutable_context())["access_type"] = "offline";
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::CredentialRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.request_id(), "req_uuid_12345");
    ASSERT_EQ(deserialized.service_url(), "https://accounts.google.com");
    ASSERT_EQ(deserialized.service_name(), "Google");
    ASSERT_EQ(deserialized.credential_type(), openclaw::CREDENTIAL_TYPE_OAUTH);
    ASSERT_EQ(deserialized.timestamp(), 1711000000);
    ASSERT_EQ(deserialized.timeout_seconds(), 300);
    ASSERT_EQ(deserialized.reason(), "Need to access Gmail");
    ASSERT_EQ(deserialized.context().at("scope"), "email profile");
    
    return true;
}

TEST(credential_response_serialization) {
    // 测试凭证响应序列化
    openclaw::CredentialResponse response;
    response.set_request_id("req_uuid_12345");
    response.set_status(openclaw::AUTH_STATUS_APPROVED);
    response.set_encrypted_credential("encrypted_credential_data");
    response.set_timestamp(1711000100);
    
    // 序列化
    std::string serialized;
    bool success = response.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::CredentialResponse deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.request_id(), "req_uuid_12345");
    ASSERT_EQ(deserialized.status(), openclaw::AUTH_STATUS_APPROVED);
    ASSERT_EQ(deserialized.encrypted_credential(), "encrypted_credential_data");
    ASSERT_EQ(deserialized.timestamp(), 1711000100);
    
    return true;
}

TEST(credential_response_rejected) {
    // 测试被拒绝的凭证响应
    openclaw::CredentialResponse response;
    response.set_request_id("req_uuid_67890");
    response.set_status(openclaw::AUTH_STATUS_DENIED);
    response.set_error_message("User denied the request");
    response.set_timestamp(1711000200);
    
    // 序列化
    std::string serialized;
    bool success = response.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::CredentialResponse deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.request_id(), "req_uuid_67890");
    ASSERT_EQ(deserialized.status(), openclaw::AUTH_STATUS_DENIED);
    ASSERT_EQ(deserialized.error_message(), "User denied the request");
    
    return true;
}

// ============================================================================
// Cookie 管理测试
// ============================================================================

TEST(cookie_item_serialization) {
    // 测试 Cookie 项序列化
    openclaw::CookieItem cookie;
    cookie.set_name("session_id");
    cookie.set_value("abc123xyz789");
    cookie.set_domain(".example.com");
    cookie.set_path("/");
    cookie.set_expires(1743000000);
    cookie.set_secure(true);
    cookie.set_http_only(true);
    cookie.set_same_site("Strict");
    
    // 序列化
    std::string serialized;
    bool success = cookie.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::CookieItem deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.name(), "session_id");
    ASSERT_EQ(deserialized.value(), "abc123xyz789");
    ASSERT_EQ(deserialized.domain(), ".example.com");
    ASSERT_EQ(deserialized.path(), "/");
    ASSERT_EQ(deserialized.expires(), 1743000000);
    ASSERT_TRUE(deserialized.secure());
    ASSERT_TRUE(deserialized.http_only());
    ASSERT_EQ(deserialized.same_site(), "Strict");
    
    return true;
}

TEST(cookie_upload_request_serialization) {
    // 测试 Cookie 上传请求序列化
    openclaw::CookieUploadRequest request;
    request.set_request_id("upload_req_001");
    request.set_service_url("https://example.com");
    
    // 添加多个 Cookie
    auto* cookie1 = request.add_cookies();
    cookie1->set_name("session");
    cookie1->set_value("xyz123");
    cookie1->set_domain(".example.com");
    
    auto* cookie2 = request.add_cookies();
    cookie2->set_name("preferences");
    cookie2->set_value("theme=dark");
    cookie2->set_domain(".example.com");
    
    request.set_encrypted_cookies("encrypted_cookie_data");
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::CookieUploadRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.request_id(), "upload_req_001");
    ASSERT_EQ(deserialized.cookies_size(), 2);
    ASSERT_EQ(deserialized.cookies(0).name(), "session");
    ASSERT_EQ(deserialized.cookies(1).name(), "preferences");
    ASSERT_EQ(deserialized.encrypted_cookies(), "encrypted_cookie_data");
    
    return true;
}

TEST(cookie_download_response_serialization) {
    // 测试 Cookie 下载响应序列化
    openclaw::CookieDownloadResponse response;
    response.set_success(true);
    
    auto* cookie = response.add_cookies();
    cookie->set_name("auth_token");
    cookie->set_value("token_abc123");
    cookie->set_domain(".github.com");
    cookie->set_secure(true);
    
    response.set_encrypted_cookies("encrypted_cookies_data");
    
    // 序列化
    std::string serialized;
    bool success = response.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::CookieDownloadResponse deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_TRUE(deserialized.success());
    ASSERT_EQ(deserialized.cookies_size(), 1);
    ASSERT_EQ(deserialized.cookies(0).name(), "auth_token");
    
    return true;
}

// ============================================================================
// 授权流程测试
// ============================================================================

TEST(authorization_request_serialization) {
    // 测试授权请求序列化
    openclaw::AuthorizationRequest request;
    request.set_auth_id("auth_session_12345");
    request.set_created_time(1711000000);
    request.set_expires_time(1711000600);
    
    // 设置凭证请求
    auto* cred_req = request.mutable_credential_request();
    cred_req->set_request_id("cred_req_001");
    cred_req->set_service_url("https://github.com");
    cred_req->set_service_name("GitHub");
    cred_req->set_credential_type(openclaw::CREDENTIAL_TYPE_OAUTH);
    
    // 设置请求设备信息
    auto* device = request.mutable_requesting_device();
    device->set_device_id("device_abc");
    device->set_device_name("iPhone 15");
    device->set_device_type(openclaw::DEVICE_TYPE_IOS);
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::AuthorizationRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.auth_id(), "auth_session_12345");
    ASSERT_EQ(deserialized.credential_request().request_id(), "cred_req_001");
    ASSERT_EQ(deserialized.requesting_device().device_id(), "device_abc");
    
    return true;
}

TEST(authorization_response_serialization) {
    // 测试授权响应序列化
    openclaw::AuthorizationResponse response;
    response.set_auth_id("auth_session_12345");
    response.set_status(openclaw::AUTH_STATUS_APPROVED);
    response.set_device_id("device_abc");
    
    auto* cred_resp = response.mutable_credential_response();
    cred_resp->set_request_id("cred_req_001");
    cred_resp->set_status(openclaw::AUTH_STATUS_APPROVED);
    cred_resp->set_encrypted_credential("encrypted_data");
    
    // 序列化
    std::string serialized;
    bool success = response.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::AuthorizationResponse deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.auth_id(), "auth_session_12345");
    ASSERT_EQ(deserialized.status(), openclaw::AUTH_STATUS_APPROVED);
    ASSERT_EQ(deserialized.credential_response().status(), openclaw::AUTH_STATUS_APPROVED);
    
    return true;
}

// ============================================================================
// 同步功能测试
// ============================================================================

TEST(sync_request_serialization) {
    // 测试同步请求序列化
    openclaw::SyncRequest request;
    request.set_device_id("device_123");
    request.set_last_sync_time(1710900000);
    request.add_service_urls("https://github.com");
    request.add_service_urls("https://google.com");
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::SyncRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.device_id(), "device_123");
    ASSERT_EQ(deserialized.service_urls_size(), 2);
    
    return true;
}

TEST(sync_data_serialization) {
    // 测试同步数据序列化
    openclaw::SyncData data;
    data.set_service_url("https://github.com");
    data.set_encrypted_data("encrypted_sync_data_here");
    data.set_modified_time(1711000000);
    data.set_checksum("sha256_checksum_value");
    
    // 序列化
    std::string serialized;
    bool success = data.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::SyncData deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.service_url(), "https://github.com");
    ASSERT_EQ(deserialized.checksum(), "sha256_checksum_value");
    
    return true;
}

// ============================================================================
// 安全功能测试
// ============================================================================

TEST(key_exchange_request_serialization) {
    // 测试密钥交换请求序列化
    openclaw::KeyExchangeRequest request;
    request.set_device_id("device_123");
    request.set_public_key("ecdh_public_key_data");
    request.set_preferred_algorithm(openclaw::ENCRYPTION_AES_256_GCM);
    request.set_timestamp(1711000000);
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::KeyExchangeRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.preferred_algorithm(), openclaw::ENCRYPTION_AES_256_GCM);
    
    return true;
}

TEST(biometric_auth_request_serialization) {
    // 测试生物认证请求序列化
    openclaw::BiometricAuthRequest request;
    request.set_request_id("bio_req_001");
    request.set_reason("Confirm credential access");
    request.set_timeout_seconds(30);
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::BiometricAuthRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.reason(), "Confirm credential access");
    ASSERT_EQ(deserialized.timeout_seconds(), 30);
    
    return true;
}

// ============================================================================
// Native Messaging 测试
// ============================================================================

TEST(native_message_request_serialization) {
    // 测试 Native Messaging 请求序列化
    openclaw::NativeMessageRequest request;
    request.set_type(openclaw::NATIVE_MSG_CREDENTIAL_REQUEST);
    request.set_request_id("native_req_001");
    request.set_tab_id(12345);
    request.set_url("https://github.com/login");
    (*request.mutable_data())["username"] = "user@example.com";
    
    // 序列化
    std::string serialized;
    bool success = request.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::NativeMessageRequest deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.type(), openclaw::NATIVE_MSG_CREDENTIAL_REQUEST);
    ASSERT_EQ(deserialized.tab_id(), 12345);
    ASSERT_EQ(deserialized.data().at("username"), "user@example.com");
    
    return true;
}

// ============================================================================
// 自动授权规则测试
// ============================================================================

TEST(auto_auth_rule_serialization) {
    // 测试自动授权规则序列化
    openclaw::AutoAuthRule rule;
    rule.set_rule_id("rule_001");
    rule.set_service_url_pattern("https://*.github.com/*");
    rule.set_auto_approve(true);
    rule.set_max_auto_approvals(10);
    rule.set_auto_approvals_used(3);
    rule.set_created_time(1711000000);
    rule.set_expires_time(1743000000);
    rule.set_require_biometric(false);
    (*rule.mutable_conditions())["time_range"] = "9:00-18:00";
    
    // 序列化
    std::string serialized;
    bool success = rule.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::AutoAuthRule deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.service_url_pattern(), "https://*.github.com/*");
    ASSERT_TRUE(deserialized.auto_approve());
    ASSERT_EQ(deserialized.max_auto_approvals(), 10);
    
    return true;
}

// ============================================================================
// 事件系统测试
// ============================================================================

TEST(event_serialization) {
    // 测试事件消息序列化
    openclaw::Event event;
    event.set_event_id("event_12345");
    event.set_type(openclaw::EVENT_DEVICE_CONNECTED);
    event.set_device_id("device_abc");
    event.set_timestamp(1711000000);
    (*event.mutable_data())["device_name"] = "iPhone 15";
    event.set_message("New device connected successfully");
    
    // 序列化
    std::string serialized;
    bool success = event.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    // 反序列化
    openclaw::Event deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    ASSERT_EQ(deserialized.type(), openclaw::EVENT_DEVICE_CONNECTED);
    ASSERT_EQ(deserialized.message(), "New device connected successfully");
    
    return true;
}

// ============================================================================
// 边界情况测试
// ============================================================================

TEST(empty_message_serialization) {
    // 测试空消息序列化
    openclaw::DeviceInfo device;
    
    std::string serialized;
    bool success = device.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    openclaw::DeviceInfo deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    
    // 验证默认值
    ASSERT_EQ(deserialized.device_type(), openclaw::DEVICE_TYPE_UNSPECIFIED);
    ASSERT_FALSE(deserialized.is_online());
    
    return true;
}

TEST(large_payload_serialization) {
    // 测试大数据量序列化
    openclaw::CredentialResponse response;
    response.set_request_id("large_test");
    response.set_status(openclaw::AUTH_STATUS_APPROVED);
    
    // 创建大 payload (1MB)
    std::string large_data(1024 * 1024, 'x');
    response.set_encrypted_credential(large_data);
    
    std::string serialized;
    bool success = response.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    ASSERT_TRUE(serialized.size() > 1024 * 1024);
    
    openclaw::CredentialResponse deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    ASSERT_EQ(deserialized.encrypted_credential().size(), large_data.size());
    
    return true;
}

TEST(unicode_string_serialization) {
    // 测试 Unicode 字符串序列化
    openclaw::DeviceInfo device;
    device.set_device_id("device_001");
    device.set_device_name("我的设备 - 中文测试 📱");
    
    std::string serialized;
    bool success = device.SerializeToString(&serialized);
    ASSERT_TRUE(success);
    
    openclaw::DeviceInfo deserialized;
    success = deserialized.ParseFromString(serialized);
    ASSERT_TRUE(success);
    ASSERT_EQ(deserialized.device_name(), "我的设备 - 中文测试 📱");
    
    return true;
}

// ============================================================================
// 主函数
// ============================================================================

int main() {
    std::cout << "========================================" << std::endl;
    std::cout << "PolyVault Protobuf 序列化测试" << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << std::endl;
    
    // 基础类型测试
    std::cout << "--- 基础类型测试 ---" << std::endl;
    RUN_TEST(device_type_enum);
    RUN_TEST(credential_type_enum);
    RUN_TEST(authorization_status_enum);
    
    // 设备管理测试
    std::cout << "\n--- 设备管理测试 ---" << std::endl;
    RUN_TEST(device_info_serialization);
    RUN_TEST(device_register_request_serialization);
    RUN_TEST(device_heartbeat_serialization);
    
    // 凭证请求/响应测试
    std::cout << "\n--- 凭证请求/响应测试 ---" << std::endl;
    RUN_TEST(credential_request_serialization);
    RUN_TEST(credential_response_serialization);
    RUN_TEST(credential_response_rejected);
    
    // Cookie 管理测试
    std::cout << "\n--- Cookie 管理测试 ---" << std::endl;
    RUN_TEST(cookie_item_serialization);
    RUN_TEST(cookie_upload_request_serialization);
    RUN_TEST(cookie_download_response_serialization);
    
    // 授权流程测试
    std::cout << "\n--- 授权流程测试 ---" << std::endl;
    RUN_TEST(authorization_request_serialization);
    RUN_TEST(authorization_response_serialization);
    
    // 同步功能测试
    std::cout << "\n--- 同步功能测试 ---" << std::endl;
    RUN_TEST(sync_request_serialization);
    RUN_TEST(sync_data_serialization);
    
    // 安全功能测试
    std::cout << "\n--- 安全功能测试 ---" << std::endl;
    RUN_TEST(key_exchange_request_serialization);
    RUN_TEST(biometric_auth_request_serialization);
    
    // Native Messaging 测试
    std::cout << "\n--- Native Messaging 测试 ---" << std::endl;
    RUN_TEST(native_message_request_serialization);
    
    // 自动授权规则测试
    std::cout << "\n--- 自动授权规则测试 ---" << std::endl;
    RUN_TEST(auto_auth_rule_serialization);
    
    // 事件系统测试
    std::cout << "\n--- 事件系统测试 ---" << std::endl;
    RUN_TEST(event_serialization);
    
    // 边界情况测试
    std::cout << "\n--- 边界情况测试 ---" << std::endl;
    RUN_TEST(empty_message_serialization);
    RUN_TEST(large_payload_serialization);
    RUN_TEST(unicode_string_serialization);
    
    // 输出总结
    stats.summary();
    
    return stats.failed > 0 ? 1 : 0;
}
