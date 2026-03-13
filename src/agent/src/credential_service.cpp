/**
 * @file credential_service.cpp
 * @brief 凭证服务实现
 */

#include "credential_service.hpp"
#include <iostream>
#include <chrono>
#include <unordered_map>

namespace polyvault {

// 临时存储（实际应使用zk_vault安全存储）
static std::unordered_map<std::string, std::string> credential_store_;

std::optional<std::string> CredentialService::getCredential(const std::string& service_url) {
    auto it = credential_store_.find(service_url);
    if (it != credential_store_.end()) {
        return it->second;
    }
    return std::nullopt;
}

bool CredentialService::storeCredential(const std::string& service_url, 
                                        const std::string& encrypted_credential) {
    credential_store_[service_url] = encrypted_credential;
    std::cout << "[CredentialService] Stored credential for: " << service_url << std::endl;
    return true;
}

bool CredentialService::deleteCredential(const std::string& service_url) {
    auto it = credential_store_.find(service_url);
    if (it != credential_store_.end()) {
        credential_store_.erase(it);
        return true;
    }
    return false;
}

bool CredentialService::hasCredential(const std::string& service_url) {
    return credential_store_.find(service_url) != credential_store_.end();
}

openclaw::CredentialResponse CredentialService::handleRequest(
    const openclaw::CredentialRequest& request) {
    
    openclaw::CredentialResponse response;
    response.set_session_id(request.session_id());
    
    auto credential = getCredential(request.service_url());
    if (credential) {
        response.set_success(true);
        response.set_encrypted_credential(*credential);
        std::cout << "[CredentialService] Found credential for: " 
                  << request.service_url() << std::endl;
    } else {
        response.set_success(false);
        response.set_error_message("Credential not found for: " + request.service_url());
        std::cout << "[CredentialService] No credential for: " 
                  << request.service_url() << std::endl;
    }
    
    return response;
}

} // namespace polyvault