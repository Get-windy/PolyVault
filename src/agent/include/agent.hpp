/**
 * @file agent.hpp
 * @brief PolyVault Agent - 远程授信客户端Agent
 * 
 * 功能：
 * - 通过eCAL与客户端通信
 * - 处理凭证请求
 * - 管理本地安全存储
 * - 支持Cookie上传、心跳、配置同步
 */

#pragma once

#include <string>
#include <memory>
#include <functional>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#include <ecal/msg/protobuf/publisher.h>
#include <ecal/msg/protobuf/subscriber.h>
#endif

#include "openclaw.pb.h"

namespace polyvault {

// 前向声明
class MessageHandlerManager;

/**
 * @brief Agent配置
 */
struct AgentConfig {
    std::string agent_id;           // Agent唯一标识
    std::string client_endpoint;    // 客户端端点
    bool use_ecal = true;           // 是否使用eCAL
    int listen_port = 5050;         // 监听端口（非eCAL模式）
};

/**
 * @brief 凭证请求回调类型
 */
using CredentialCallback = std::function<openclaw::CredentialResponse(
    const openclaw::CredentialRequest&)>;

/**
 * @brief PolyVault Agent主类
 */
class Agent {
public:
    explicit Agent(const AgentConfig& config);
    ~Agent();

    // 禁止拷贝
    Agent(const Agent&) = delete;
    Agent& operator=(const Agent&) = delete;

    /**
     * @brief 初始化Agent
     * @return 成功返回true
     */
    bool initialize();

    /**
     * @brief 启动Agent服务
     */
    void start();

    /**
     * @brief 停止Agent服务
     */
    void stop();

    /**
     * @brief 注册凭证请求处理回调
     */
    void setCredentialCallback(CredentialCallback callback);

    /**
     * @brief 设置消息处理器管理器
     */
    void setMessageHandlerManager(MessageHandlerManager* manager);

    /**
     * @brief 获取Agent状态
     */
    bool isRunning() const;

    /**
     * @brief 获取Agent ID
     */
    const std::string& getAgentId() const { return config_.agent_id; }

private:
    AgentConfig config_;
    class Impl;
    std::unique_ptr<Impl> impl_;
};

} // namespace polyvault