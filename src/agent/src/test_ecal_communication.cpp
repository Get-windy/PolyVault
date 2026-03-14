/**
 * @file test_ecal_communication.cpp
 * @brief eCAL跨进程通信测试
 * 
 * 编译:
 *   mkdir build && cd build
 *   cmake .. -DUSE_ECAL=ON
 *   cmake --build .
 * 
 * 运行:
 *   终端1: ./test_ecal_server
 *   终端2: ./test_ecal_client
 */

#include <iostream>
#include <chrono>
#include <thread>
#include <atomic>
#include <signal.h>

#include "ecal_communication.hpp"

using namespace polyvault::ecal;

std::atomic<bool> g_running{true};

void signalHandler(int sig) {
    g_running = false;
    std::cout << "\n[Signal] Shutting down..." << std::endl;
}

// ============================================================================
// 服务端测试
// ============================================================================

void runServer() {
    std::cout << "========================================" << std::endl;
    std::cout << "PolyVault eCAL Server Test" << std::endl;
    std::cout << "========================================" << std::endl;
    
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    // 创建服务端
    CredentialServer server("polyvault_credential_service");
    
    // 注册回调
    server.setCredentialCallback([](const openclaw::CredentialRequest& request) {
        std::cout << "\n[Server] Received credential request:" << std::endl;
        std::cout << "  Request ID: " << request.request_id() << std::endl;
        std::cout << "  Service URL: " << request.service_url() << std::endl;
        std::cout << "  Service Name: " << request.service_name() << std::endl;
        std::cout << "  Credential Type: " << request.credential_type() << std::endl;
        std::cout << "  Reason: " << request.reason() << std::endl;
        
        // 创建响应
        openclaw::CredentialResponse response;
        response.set_request_id(request.request_id());
        response.set_status(openclaw::AUTH_STATUS_APPROVED);
        response.set_error_message("");
        response.set_timestamp(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
        
        // 设置加密凭证（模拟）
        response.set_encrypted_credential("ENCRYPTED_CREDENTIAL_DATA");
        
        std::cout << "[Server] Sending response: APPROVED" << std::endl;
        return response;
    });
    
    server.setCookieCallback([](const openclaw::CookieDownloadRequest& request) {
        std::cout << "\n[Server] Received cookie download request:" << std::endl;
        std::cout << "  Service URL: " << request.service_url() << std::endl;
        std::cout << "  Device ID: " << request.device_id() << std::endl;
        
        openclaw::CookieDownloadResponse response;
        response.set_success(true);
        response.set_error_message("");
        
        // 添加模拟Cookie
        auto* cookie = response.add_cookies();
        cookie->set_name("session_id");
        cookie->set_value("test_session_12345");
        cookie->set_domain(request.service_url());
        cookie->set_path("/");
        
        std::cout << "[Server] Sending cookies: 1 cookie" << std::endl;
        return response;
    });
    
    std::cout << "\n[Server] Waiting for requests... (Press Ctrl+C to stop)" << std::endl;
    
    // 主循环
    while (g_running) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "[Server] Stopped" << std::endl;
}

// ============================================================================
// 客户端测试
// ============================================================================

void runClient() {
    std::cout << "========================================" << std::endl;
    std::cout << "PolyVault eCAL Client Test" << std::endl;
    std::cout << "========================================" << std::endl;
    
    // 创建客户端
    CredentialClient client("polyvault_credential_service");
    
    // 等待服务端就绪
    std::cout << "[Client] Waiting for server..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(2));
    
    // 测试1: 凭证请求
    {
        std::cout << "\n[Test 1] Credential Request" << std::endl;
        
        openclaw::CredentialRequest request;
        request.set_request_id("req_test_001");
        request.set_service_url("https://accounts.google.com");
        request.set_service_name("Google");
        request.set_credential_type(openclaw::CREDENTIAL_TYPE_PASSWORD);
        request.set_reason("Login to Google account");
        request.set_timeout_seconds(30);
        request.set_timestamp(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
        
        openclaw::CredentialResponse response;
        bool success = client.getCredential(request, response, 5000);
        
        if (success) {
            std::cout << "[Client] Response received:" << std::endl;
            std::cout << "  Request ID: " << response.request_id() << std::endl;
            std::cout << "  Status: " << response.status() << std::endl;
            std::cout << "  Success: " << (response.status() == openclaw::AUTH_STATUS_APPROVED) << std::endl;
            if (response.has_encrypted_credential()) {
                std::cout << "  Credential: " << response.encrypted_credential().substr(0, 30) << "..." << std::endl;
            }
        } else {
            std::cout << "[Client] Request failed: timeout or error" << std::endl;
        }
    }
    
    // 测试2: Cookie请求
    {
        std::cout << "\n[Test 2] Cookie Download" << std::endl;
        
        openclaw::CookieDownloadRequest request;
        request.set_service_url("https://example.com");
        request.set_device_id("device_001");
        
        openclaw::CookieDownloadResponse response;
        bool success = client.downloadCookie(request, response, 5000);
        
        if (success && response.success()) {
            std::cout << "[Client] Cookies received:" << std::endl;
            for (const auto& cookie : response.cookies()) {
                std::cout << "  " << cookie.name() << " = " << cookie.value() << std::endl;
            }
        } else {
            std::cout << "[Client] Cookie request failed" << std::endl;
        }
    }
    
    // 测试3: 发布/订阅模式
    {
        std::cout << "\n[Test 3] Pub/Sub Pattern" << std::endl;
        
        // 创建事件发布者
        EventPublisher eventPublisher("polyvault/events");
        
        // 发布事件
        bool published = eventPublisher.publishEvent(
            openclaw::EVENT_DEVICE_CONNECTED,
            "device_001",
            "Device connected from client test"
        );
        
        if (published) {
            std::cout << "[Client] Event published: DEVICE_CONNECTED" << std::endl;
        } else {
            std::cout << "[Client] Failed to publish event" << std::endl;
        }
    }
    
    std::cout << "\n[Client] All tests completed" << std::endl;
}

// ============================================================================
// 主入口
// ============================================================================

void printUsage(const char* prog) {
    std::cout << "Usage: " << prog << " [server|client]" << std::endl;
    std::cout << "\nCommands:" << std::endl;
    std::cout << "  server  - Run as server (listens for requests)" << std::endl;
    std::cout << "  client  - Run as client (sends requests)" << std::endl;
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printUsage(argv[0]);
        return 1;
    }
    
    std::string mode = argv[1];
    
    if (mode == "server") {
        runServer();
    } else if (mode == "client") {
        runClient();
    } else {
        std::cerr << "Unknown mode: " << mode << std::endl;
        printUsage(argv[0]);
        return 1;
    }
    
    return 0;
}