/**
 * @file credential_service.hpp
 * @brief 凭证服务接口
 */

#pragma once

#include <string>
#include <optional>
#include "openclaw.pb.h"

namespace polyvault {

/**
 * @brief 凭证服务接口
 * 
 * 负责从安全存储获取凭证
 */
class CredentialService {
public:
    CredentialService() = default;
    ~CredentialService() = default;

    /**
     * @brief 获取凭证
     * @param service_url 服务URL
     * @return 加密凭证（成功）或空（失败）
     */
    std::optional<std::string> getCredential(const std::string& service_url);

    /**
     * @brief 存储凭证
     * @param service_url 服务URL
     * @param encrypted_credential 加密的凭证
     * @return 成功返回true
     */
    bool storeCredential(const std::string& service_url, const std::string& encrypted_credential);

    /**
     * @brief 删除凭证
     * @param service_url 服务URL
     * @return 成功返回true
     */
    bool deleteCredential(const std::string& service_url);

    /**
     * @brief 检查凭证是否存在
     */
    bool hasCredential(const std::string& service_url);

    /**
     * @brief 处理凭证请求
     * @param request 请求消息
     * @return 响应消息
     */
    openclaw::CredentialResponse handleRequest(const openclaw::CredentialRequest& request);
};

} // namespace polyvault