/**
 * @file main.cpp
 * @brief PolyVault Agent入口
 */

#include "agent.hpp"
#include "credential_service.hpp"
#include "message_handler.hpp"
#include <iostream>
#include <string>
#include <csignal>
#include <cstdlib>
#include <memory>

using namespace polyvault;

// 全局Agent指针（用于信号处理）
Agent* g_agent = nullptr;
std::unique_ptr<MessageHandlerManager> g_handler_manager;

void signalHandler(int signal) {
    std::cout << "\n[Main] Received signal " << signal << ", shutting down..." << std::endl;
    if (g_agent) {
        g_agent->stop();
    }
    exit(0);
}

void printUsage(const char* program) {
    std::cout << "PolyVault Agent v0.1.0\n"
              << "\nUsage: " << program << " [options]\n"
              << "\nOptions:\n"
              << "  --id <agent_id>     Agent ID (required)\n"
              << "  --port <port>       Listen port (default: 5050)\n"
              << "  --no-ecal           Disable eCAL, use TCP\n"
              << "  --help              Show this help\n"
              << "\nFeatures:\n"
              << "  - Credential request/response\n"
              << "  - Cookie upload/storage\n"
              << "  - Heartbeat monitoring\n"
              << "  - Config synchronization\n"
              << std::endl;
}

int main(int argc, char* argv[]) {
    std::cout << "========================================" << std::endl;
    std::cout << "       PolyVault Agent v0.1.0          " << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << std::endl;
    
    // 解析命令行参数
    AgentConfig config;
    
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        
        if (arg == "--help") {
            printUsage(argv[0]);
            return 0;
        } else if (arg == "--id" && i + 1 < argc) {
            config.agent_id = argv[++i];
        } else if (arg == "--port" && i + 1 < argc) {
            config.listen_port = std::stoi(argv[++i]);
        } else if (arg == "--no-ecal") {
            config.use_ecal = false;
        }
    }
    
    if (config.agent_id.empty()) {
        // 使用默认ID
        config.agent_id = "polyvault-agent-" + std::to_string(std::rand() % 10000);
        std::cout << "[Main] Using auto-generated Agent ID: " << config.agent_id << std::endl;
    }
    
    // 注册信号处理
    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);
    
    // 创建凭证服务
    CredentialService credService;
    
    // 创建消息处理器管理器
    g_handler_manager = std::make_unique<MessageHandlerManager>(credService);
    
    // 创建Agent
    Agent agent(config);
    g_agent = &agent;
    
    // 设置消息处理器
    agent.setMessageHandlerManager(g_handler_manager.get());
    
    // 初始化
    if (!agent.initialize()) {
        std::cerr << "[Main] Failed to initialize agent" << std::endl;
        return 1;
    }
    
    // 添加测试凭证
    credService.storeCredential("https://accounts.google.com", "encrypted_google_token");
    credService.storeCredential("https://github.com", "encrypted_github_token");
    credService.storeCredential("https://twitter.com", "encrypted_twitter_token");
    
    std::cout << std::endl;
    std::cout << "[Main] Test credentials loaded:" << std::endl;
    std::cout << "[Main]   - accounts.google.com" << std::endl;
    std::cout << "[Main]   - github.com" << std::endl;
    std::cout << "[Main]   - twitter.com" << std::endl;
    std::cout << std::endl;
    std::cout << "[Main] Agent ready. Press Ctrl+C to exit." << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << std::endl;
    
    // 启动Agent（阻塞）
    agent.start();
    
    return 0;
}