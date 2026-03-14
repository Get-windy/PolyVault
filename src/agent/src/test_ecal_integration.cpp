/**
 * @file test_ecal_integration.cpp
 * @brief eCAL集成测试 - 跨进程通信测试
 * 
 * 编译:
 *   cd src/agent/build
 *   cmake .. -DUSE_ECAL=ON -DBUILD_TESTS=ON
 *   cmake --build . --target test_ecal_integration
 * 
 * 运行 (需要两个终端):
 *   终端1: ./test_ecal_integration server
 *   终端2: ./test_ecal_integration client
 */

#include <iostream>
#include <thread>
#include <chrono>
#include <atomic>
#include <signal.h>
#include <memory>
#include <sstream>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#include <ecal/msg/protobuf/publisher.h>
#include <ecal/msg/protobuf/subscriber.h>
#include <ecal/msg/protobuf/server.h>
#include <ecal/msg/protobuf/client.h>
#endif

#include "ecal_communication.hpp"
#include "data_bus.hpp"
#include "openclaw.pb.h"

using namespace polyvault;
using namespace polyvault::ecal;
using namespace polyvault::bus;

std::atomic<bool> g_running{true};

void signalHandler(int sig) {
    g_running = false;
    std::cout << "\n[Signal] Shutting down..." << std::endl;
}

// ============================================================================
// 测试辅助函数
// ============================================================================

void printSection(const std::string& name) {
    std::cout << "\n========================================" << std::endl;
    std::cout << name << std::endl;
    std::cout << "========================================" << std::endl;
}

bool checkEcalAvailable() {
#ifdef USE_ECAL
    if (!eCAL::Initialize(0, nullptr, "TestApp")) {
        std::cerr << "[ERROR] Failed to initialize eCAL" << std::endl;
        return false;
    }
    
    std::cout << "[INFO] eCAL version: " << eCAL::GetVersionString() << std::endl;
    std::cout << "[INFO] eCAL initialized successfully" << std::endl;
    return true;
#else
    std::cerr << "[ERROR] eCAL not available - compile with -DUSE_ECAL=ON" << std::endl;
    return false;
#endif
}

// ============================================================================
// 1. 基础eCAL发布/订阅测试
// ============================================================================

void testBasicPubSub() {
    printSection("Test 1: Basic Pub/Sub");
    
#ifdef USE_ECAL
    // 创建发布者
    eCAL::protobuf::CPublisher<openclaw::Event> publisher("polyvault/test/event");
    
    // 创建订阅者
    std::atomic<int> receive_count{0};
    eCAL::protobuf::CSubscriber<openclaw::Event> subscriber("polyvault/test/event");
    
    subscriber.AddReceiveCallback([&receive_count](const char* topic, const openclaw::Event& event) {
        std::cout << "[Subscriber] Received event: " << event.message() << std::endl;
        receive_count++;
    });
    
    // 发布消息
    for (int i = 0; i < 5; i++) {
        openclaw::Event event;
        event.set_event_id("evt_" + std::to_string(i));
        event.set_type(openclaw::EVENT_DEVICE_CONNECTED);
        event.set_device_id("test_device");
        event.set_message("Test message " + std::to_string(i));
        event.set_timestamp(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
        
        publisher.Send(event);
        std::cout << "[Publisher] Sent event " << i << std::endl;
        
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    // 等待接收
    std::this_thread::sleep_for(std::chrono::seconds(1));
    
    std::cout << "[Result] Received " << receive_count << " messages" << std::endl;
    std::cout << "[Result] " << (receive_count >= 3 ? "PASSED" : "FAILED") << std::endl;
#else
    std::cout << "[SKIP] eCAL not available" << std::endl;
#endif
}

// ============================================================================
// 2. RPC服务测试
// ============================================================================

void testRPCService() {
    printSection("Test 2: RPC Service");
    
#ifdef USE_ECAL
    // 创建服务端
    CredentialServer server("polyvault_rpc_test");
    
    // 设置回调
    server.setCredentialCallback([](const openclaw::CredentialRequest& request) {
        std::cout << "[Server] Received request for: " << request.service_url() << std::endl;
        
        openclaw::CredentialResponse response;
        response.set_request_id(request.request_id());
        response.set_status(openclaw::AUTH_STATUS_APPROVED);
        response.set_encrypted_credential("MOCK_CREDENTIAL_DATA");
        response.set_timestamp(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
        
        return response;
    });
    
    // 创建客户端
    CredentialClient client("polyvault_rpc_test");
    
    // 等待服务就绪
    std::this_thread::sleep_for(std::chrono::seconds(1));
    
    // 发送请求
    openclaw::CredentialRequest request;
    request.set_request_id("req_001");
    request.set_service_url("https://example.com");
    request.set_service_name("Example");
    request.set_credential_type(openclaw::CREDENTIAL_TYPE_PASSWORD);
    request.set_reason("Test login");
    request.set_timestamp(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
    
    openclaw::CredentialResponse response;
    bool success = client.getCredential(request, response, 5000);
    
    if (success) {
        std::cout << "[Client] Response status: " << response.status() << std::endl;
        std::cout << "[Client] Credential: " << response.encrypted_credential().substr(0, 20) << "..." << std::endl;
        std::cout << "[Result] PASSED" << std::endl;
    } else {
        std::cout << "[Result] FAILED - Request timeout" << std::endl;
    }
#else
    std::cout << "[SKIP] eCAL not available" << std::endl;
#endif
}

// ============================================================================
// 3. 数据总线集成测试
// ============================================================================

void testDataBusEcal() {
    printSection("Test 3: Data Bus with eCAL");
    
#ifdef USE_ECAL
    DataBusConfig config;
    config.bus_name = "PolyVaultDataBus";
    config.node_id = "test_node";
    config.use_ecal = true;
    config.worker_threads = 2;
    
    DataBus bus(config);
    bus.initialize();
    bus.start();
    
    std::atomic<int> event_count{0};
    
    // 订阅事件
    bus.subscribe("events", [&event_count](const Message& msg) {
        std::cout << "[Bus] Received event message: " << msg.topic << std::endl;
        event_count++;
        
        // 尝试解析Event
        openclaw::Event event;
        if (ProtobufSerializer::extractEvent(msg, event)) {
            std::cout << "[Bus] Parsed event: " << event.message() << std::endl;
        }
    });
    
    // 发布事件
    for (int i = 0; i < 3; i++) {
        auto event_msg = createEventMessage("device_001", 
                                            openclaw::EVENT_DEVICE_CONNECTED,
                                            "Device connected event " + std::to_string(i));
        bus.publish("events", event_msg);
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
    }
    
    std::this_thread::sleep_for(std::chrono::milliseconds(500));
    
    std::cout << "[Result] Received " << event_count << " events" << std::endl;
    std::cout << "[Result] " << (event_count >= 3 ? "PASSED" : "FAILED") << std::endl;
    
    bus.stop();
#else
    std::cout << "[SKIP] eCAL not available" << std::endl;
#endif
}

// ============================================================================
// 4. 性能测试
// ============================================================================

void testPerformance() {
    printSection("Test 4: Performance Test");
    
#ifdef USE_ECAL
    const int message_count = 1000;
    
    eCAL::protobuf::CPublisher<openclaw::Event> publisher("polyvault/perf/test");
    
    std::atomic<int> receive_count{0};
    eCAL::protobuf::CSubscriber<openclaw::Event> subscriber("polyvault/perf/test");
    
    subscriber.AddReceiveCallback([&receive_count](const char*, const openclaw::Event&) {
        receive_count++;
    });
    
    auto start_time = std::chrono::high_resolution_clock::now();
    
    // 发送消息
    for (int i = 0; i < message_count; i++) {
        openclaw::Event event;
        event.set_event_id("perf_" + std::to_string(i));
        event.set_type(openclaw::EVENT_SYNC_COMPLETED);
        event.set_device_id("perf_device");
        event.set_message("Performance test message");
        event.set_timestamp(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
        
        publisher.Send(event);
    }
    
    // 等待接收完成
    while (receive_count < message_count) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        if (receive_count >= message_count) break;
    }
    
    auto end_time = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end_time - start_time).count();
    
    double throughput = static_cast<double>(message_count) / (duration / 1000.0);
    
    std::cout << "[Perf] Sent " << message_count << " messages" << std::endl;
    std::cout << "[Perf] Received " << receive_count << " messages" << std::endl;
    std::cout << "[Perf] Duration: " << duration << " ms" << std::endl;
    std::cout << "[Perf] Throughput: " << throughput << " msg/sec" << std::endl;
    std::cout << "[Result] " << (receive_count >= message_count * 0.9 ? "PASSED" : "FAILED") << std::endl;
#else
    std::cout << "[SKIP] eCAL not available" << std::endl;
#endif
}

// ============================================================================
// 5. 跨进程通信演示 (Server模式)
// ============================================================================

void runServerMode() {
    printSection("Server Mode - Waiting for requests");
    
#ifdef USE_ECAL
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    // 创建服务端
    CredentialServer server("polyvault_credential_service");
    
    server.setCredentialCallback([](const openclaw::CredentialRequest& request) {
        std::cout << "\n[Server] Credential Request:" << std::endl;
        std::cout << "  Service: " << request.service_name() << std::endl;
        std::cout << "  URL: " << request.service_url() << std::endl;
        std::cout << "  Type: " << request.credential_type() << std::endl;
        
        openclaw::CredentialResponse response;
        response.set_request_id(request.request_id());
        response.set_status(openclaw::AUTH_STATUS_APPROVED);
        response.set_encrypted_credential("SECURE_TOKEN_" + request.request_id());
        response.set_timestamp(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
        
        return response;
    });
    
    server.setCookieCallback([](const openclaw::CookieDownloadRequest& request) {
        std::cout << "\n[Server] Cookie Request:" << std::endl;
        std::cout << "  Service: " << request.service_url() << std::endl;
        
        openclaw::CookieDownloadResponse response;
        response.set_success(true);
        
        auto* cookie = response.add_cookies();
        cookie->set_name("session");
        cookie->set_value("cookie_value_12345");
        cookie->set_domain(request.service_url());
        cookie->set_path("/");
        
        return response;
    });
    
    std::cout << "[Server] Listening for requests... (Ctrl+C to stop)" << std::endl;
    
    while (g_running) {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }
    
    std::cout << "[Server] Stopped" << std::endl;
#else
    std::cerr << "[ERROR] eCAL not available" << std::endl;
#endif
}

// ============================================================================
// 6. 跨进程通信演示 (Client模式)
// ============================================================================

void runClientMode() {
    printSection("Client Mode - Sending requests");
    
#ifdef USE_ECAL
    // 创建客户端
    CredentialClient client("polyvault_credential_service");
    
    std::cout << "[Client] Waiting for server..." << std::endl;
    std::this_thread::sleep_for(std::chrono::seconds(2));
    
    // 测试1: 凭证请求
    {
        std::cout << "\n[Test 1] Credential Request" << std::endl;
        
        openclaw::CredentialRequest request;
        request.set_request_id("req_" + std::to_string(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count()));
        request.set_service_url("https://github.com");
        request.set_service_name("GitHub");
        request.set_credential_type(openclaw::CREDENTIAL_TYPE_PASSWORD);
        request.set_reason("Login to GitHub");
        request.set_timestamp(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count());
        
        openclaw::CredentialResponse response;
        bool success = client.getCredential(request, response, 5000);
        
        if (success) {
            std::cout << "[Client] Success! Status: " << response.status() << std::endl;
            std::cout << "[Client] Credential: " << response.encrypted_credential() << std::endl;
        } else {
            std::cout << "[Client] Failed: timeout or error" << std::endl;
        }
    }
    
    // 测试2: Cookie下载
    {
        std::cout << "\n[Test 2] Cookie Download" << std::endl;
        
        openclaw::CookieDownloadRequest request;
        request.set_service_url("https://example.com");
        request.set_device_id("client_device");
        
        openclaw::CookieDownloadResponse response;
        bool success = client.downloadCookie(request, response, 5000);
        
        if (success && response.success()) {
            std::cout << "[Client] Got " << response.cookies_size() << " cookies" << std::endl;
            for (const auto& cookie : response.cookies()) {
                std::cout << "[Client] Cookie: " << cookie.name() << " = " << cookie.value() << std::endl;
            }
        } else {
            std::cout << "[Client] Failed to get cookies" << std::endl;
        }
    }
    
    std::cout << "\n[Client] All tests completed" << std::endl;
#else
    std::cerr << "[ERROR] eCAL not available" << std::endl;
#endif
}

// ============================================================================
// 主入口
// ============================================================================

void printUsage(const char* prog) {
    std::cout << "Usage: " << prog << " [mode]" << std::endl;
    std::cout << "\nModes:" << std::endl;
    std::cout << "  test       - Run all tests" << std::endl;
    std::cout << "  server     - Run as RPC server" << std::endl;
    std::cout << "  client     - Run as RPC client (test with server)" << std::endl;
    std::cout << "  pubsub     - Test publish/subscribe" << std::endl;
    std::cout << "  rpc        - Test RPC calls" << std::endl;
    std::cout << "  databus    - Test data bus with eCAL" << std::endl;
    std::cout << "  perf       - Test performance" << std::endl;
}

int main(int argc, char* argv[]) {
    std::cout << "==================================================" << std::endl;
    std::cout << "PolyVault eCAL Integration Tests" << std::endl;
    std::cout << "==================================================" << std::endl;
    
    if (argc < 2) {
        printUsage(argv[0]);
        return 1;
    }
    
    std::string mode = argv[1];
    
    // 检查eCAL可用性
    if (!checkEcalAvailable()) {
        return 1;
    }
    
    if (mode == "test") {
        // 运行所有测试
        testBasicPubSub();
        testRPCService();
        testDataBusEcal();
        testPerformance();
    } else if (mode == "server") {
        runServerMode();
    } else if (mode == "client") {
        runClientMode();
    } else if (mode == "pubsub") {
        testBasicPubSub();
    } else if (mode == "rpc") {
        testRPCService();
    } else if (mode == "databus") {
        testDataBusEcal();
    } else if (mode == "perf") {
        testPerformance();
    } else {
        std::cerr << "Unknown mode: " << mode << std::endl;
        printUsage(argv[0]);
        return 1;
    }
    
    std::cout << "\n==================================================" << std::endl;
    std::cout << "Tests completed" << std::endl;
    std::cout << "==================================================" << std::endl;
    
    return 0;
}