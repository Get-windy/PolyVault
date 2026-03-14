/**
 * @file rest_server.hpp
 * @brief REST API服务器 - 为Flutter客户端提供HTTP接口
 * 
 * 功能：
 * - HTTP服务器
 * - REST API端点
 * - JSON序列化/反序列化
 */

#pragma once

#include <string>
#include <memory>
#include <functional>
#include <map>
#include <mutex>
#include <thread>
#include <atomic>
#include <queue>
#include <optional>

// 简化：使用条件编译，如果需要完整HTTP功能可以使用 libmicrohttpd 或 crow
// 当前提供基础架构

namespace polyvault {
namespace server {

// ============================================================================
// HTTP类型定义
// ============================================================================

/**
 * @brief HTTP方法
 */
enum class HttpMethod {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH
};

/**
 * @brief HTTP请求
 */
struct HttpRequest {
    HttpMethod method;
    std::string path;
    std::map<std::string, std::string> headers;
    std::map<std::string, std::string> query_params;
    std::string body;
    std::string client_ip;
};

/**
 * @brief HTTP响应
 */
struct HttpResponse {
    int status_code = 200;
    std::string status_message = "OK";
    std::map<std::string, std::string> headers;
    std::string body;
    
    static HttpResponse ok(const std::string& body = "") {
        HttpResponse resp;
        resp.status_code = 200;
        resp.body = body;
        return resp;
    }
    
    static HttpResponse created(const std::string& body = "") {
        HttpResponse resp;
        resp.status_code = 201;
        resp.status_message = "Created";
        resp.body = body;
        return resp;
    }
    
    static HttpResponse error(int code, const std::string& message) {
        HttpResponse resp;
        resp.status_code = code;
        resp.status_message = message;
        resp.body = "{\"error\":\"" + message + "\"}";
        return resp;
    }
    
    static HttpResponse json(int code, const std::string& json_body) {
        HttpResponse resp;
        resp.status_code = code;
        resp.headers["Content-Type"] = "application/json";
        resp.body = json_body;
        return resp;
    }
};

// ============================================================================
// 路由处理
// ============================================================================

/**
 * @brief 路由处理函数
 */
using RouteHandler = std::function<HttpResponse(const HttpRequest&)>;

/**
 * @brief 路由器
 */
class Router {
public:
    void addRoute(HttpMethod method, const std::string& path, RouteHandler handler);
    std::optional<HttpResponse> handleRequest(const HttpRequest& request);
    
private:
    struct Route {
        HttpMethod method;
        std::string path;
        RouteHandler handler;
    };
    
    std::vector<Route> routes_;
    
    bool matchPath(const std::string& route_path, const std::string& request_path,
                   std::map<std::string, std::string>& params);
};

// ============================================================================
// REST服务器
// ============================================================================

/**
 * @brief REST API服务器配置
 */
struct RestServerConfig {
    std::string host = "0.0.0.0";
    uint16_t port = 3001;
    size_t worker_threads = 4;
    uint32_t request_timeout_ms = 30000;
    std::string cors_origin = "*";
    bool enable_logging = true;
};

/**
 * @brief REST API服务器
 * 
 * 提供REST接口供Flutter客户端连接
 */
class RestServer {
public:
    explicit RestServer(const RestServerConfig& config = {});
    ~RestServer();
    
    // 生命周期
    bool initialize();
    bool start();
    void stop();
    bool isRunning() const { return running_; }
    
    // 路由注册
    void get(const std::string& path, RouteHandler handler);
    void post(const std::string& path, RouteHandler handler);
    void put(const std::string& path, RouteHandler handler);
    void delete_(const std::string& path, RouteHandler handler);
    void patch(const std::string& path, RouteHandler handler);
    
    // 中间件
    void useBefore(std::function<void(HttpRequest&)> middleware);
    
    // 获取配置
    const RestServerConfig& config() const { return config_; }
    std::string getBaseUrl() const;
    
private:
    RestServerConfig config_;
    bool initialized_ = false;
    bool running_ = false;
    
    // 路由器
    Router router_;
    
    // 中间件
    std::vector<std::function<void(HttpRequest&)>> before_middleware_;
    
    // 统计
    std::atomic<uint64_t> requests_served_{0};
    std::atomic<uint64_t> requests_failed_{0};
    
    // 内部方法
    void setupDefaultRoutes();
    HttpResponse processRequest(const HttpRequest& request);
    std::string getCurrentTimestamp();
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建REST服务器
 */
std::unique_ptr<RestServer> createRestServer(const RestServerConfig& config = {});

/**
 * @brief JSON辅助函数
 */
std::string toJson(const std::map<std::string, std::string>& obj);
std::optional<std::map<std::string, std::string>> parseJson(const std::string& json);

} // namespace server
} // namespace polyvault