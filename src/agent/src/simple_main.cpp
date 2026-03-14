/**
 * @file simple_main.cpp
 * @brief PolyVault Agent Entry Point (Simple Version)
 */

#include "simple_agent.hpp"
#include <iostream>
#include <string>
#include <csignal>
#include <cstdlib>
#include <memory>
#include <chrono>

using namespace polyvault;

SimpleAgent* g_agent = nullptr;

void signalHandler(int signal) {
    std::cout << "\n[Main] Received signal " << signal << ", shutting down..." << std::endl;
    if (g_agent) {
        g_agent->stop();
    }
    exit(0);
}

void printUsage(const char* program) {
    std::cout << "PolyVault Agent v0.1.0 (Simple)\n"
              << "\nUsage: " << program << " [options]\n"
              << "\nOptions:\n"
              << "  --id <agent_id>     Agent ID\n"
              << "  --port <port>       Listen port (default: 5050)\n"
              << "  --help              Show this help\n"
              << std::endl;
}

int main(int argc, char* argv[]) {
    std::cout << "========================================" << std::endl;
    std::cout << "       PolyVault Agent v0.1.0          " << std::endl;
    std::cout << "       (Simple Build - No Protobuf)    " << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << std::endl;
    
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
        }
    }
    
    if (config.agent_id.empty()) {
        config.agent_id = "polyvault-agent-" + std::to_string(std::rand() % 10000);
        std::cout << "[Main] Auto-generated Agent ID: " << config.agent_id << std::endl;
    }
    
    std::signal(SIGINT, signalHandler);
    std::signal(SIGTERM, signalHandler);
    
    SimpleCredentialService credService;
    SimpleAgent agent(config);
    g_agent = &agent;
    
    agent.setCredentialCallback([&credService](const simple::CredentialRequest& req) {
        return credService.handleRequest(req);
    });
    
    if (!agent.initialize()) {
        std::cerr << "[Main] Failed to initialize agent" << std::endl;
        return 1;
    }
    
    credService.storeCredential("https://accounts.google.com", "encrypted_google_token_v1");
    credService.storeCredential("https://github.com", "encrypted_github_token_v1");
    credService.storeCredential("https://twitter.com", "encrypted_twitter_token_v1");
    
    std::cout << std::endl;
    std::cout << "[Main] Test credentials loaded:" << std::endl;
    std::cout << "[Main]   - accounts.google.com" << std::endl;
    std::cout << "[Main]   - github.com" << std::endl;
    std::cout << "[Main]   - twitter.com" << std::endl;
    std::cout << std::endl;
    
    std::cout << "[Main] Testing message serialization..." << std::endl;
    
    simple::CredentialRequest testReq;
    testReq.session_id = "test-session-001";
    testReq.service_url = "https://accounts.google.com";
    testReq.requester_id = "test-client";
    testReq.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    
    std::vector<uint8_t> serialized = testReq.serialize();
    std::cout << "[Main] Serialized request size: " << serialized.size() << " bytes" << std::endl;
    
    simple::CredentialRequest parsedReq;
    if (parsedReq.deserialize(serialized)) {
        std::cout << "[Main] Deserialization OK" << std::endl;
        std::cout << "[Main]   session_id: " << parsedReq.session_id << std::endl;
        std::cout << "[Main]   service_url: " << parsedReq.service_url << std::endl;
    }
    
    std::cout << std::endl;
    std::cout << "[Main] Testing credential request handling..." << std::endl;
    simple::CredentialResponse response = credService.handleRequest(testReq);
    std::cout << "[Main] Response success: " << (response.success ? "true" : "false") << std::endl;
    if (response.success) {
        std::cout << "[Main] Credential: " << response.encrypted_credential << std::endl;
    }
    
    std::cout << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << "[Main] Agent ready. Press Ctrl+C to exit." << std::endl;
    std::cout << "========================================" << std::endl;
    std::cout << std::endl;
    
    agent.start();
    
    return 0;
}