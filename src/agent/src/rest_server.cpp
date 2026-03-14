/**
 * @file rest_server.cpp
 * @brief REST API服务器实现
 */

#include "rest_server.hpp"
#include <iostream>
#include <sstream>
#include <algorithm>
#include <chrono>

namespace polyvault {
namespace server {

// ============================================================================
// Router实现
// ============================================================================

void Router::addRoute(HttpMethod method, const std::string& path, RouteHandler handler) {
    routes_.push_back({method, path, handler});
}

std::optional<HttpResponse> Router::handleRequest(const HttpRequest& request) {
    std::map<std::string, std::string> params;
    
    for (const auto& route : routes_) {
        if (route.method == request.method && 
            matchPath(route.path, request.path, params)) {
            
            // 创建带有参数的请求副本
            HttpRequest req_with_params = request;
            req_with_params.query_params.insert(params.begin(), params.end());
            
            try {
                return route.handler(req_with_params);
            } catch (const std::exception& e) {
                return HttpResponse::error(500, e.what());
            }
        }
    }
    
    return std::nullopt;
}

bool Router::matchPath(const std::string& route_path, const std::string& request_path,
                       std::map<std::string, std::string>& params) {
    // 简化版路径匹配
    // 支持 /api/credentials/:id 格式
    
    auto route_parts = split(route_path, '/');
    auto req_parts = split(request_path, '/');
    
    if (route_parts.size() != req_parts.size()) {
        return false;
    }
    
    for (size_t i = 0; i < route_parts.size(); i++) {
        if (route_parts[i].starts_with(':')) {
            // 参数占位符
            params[route_parts[i].substr(1)] = req_parts[i];
        } else if (route_parts[i] != req_parts[i]) {
            return false;
        }
    }
    
    return true;
}

std::vector<std::string> split(const std::string& s, char delimiter) {
    std::vector<std::string> parts;
    std::stringstream ss(s);
    std::string part;
    while (std::getline(ss, part, delimiter)) {
        parts.push_back(part);
    }
    return parts;
}

// ============================================================================
// RestServer实现
// ============================================================================

RestServer::RestServer(const RestServerConfig& config) : config_(config) {}

RestServer::~RestServer() {
    stop();
}

bool RestServer::initialize() {
    if (initialized_) {
        return true;
    }
    
    std::cout << "[REST] Initializing server on " << config_.host << ":" << config_.port << std::endl;
    
    // 设置默认路由
    setupDefaultRoutes();
    
    initialized_ = true;
    std::cout << "[REST] Server initialized" << std::endl;
    return true;
}

bool RestServer::start() {
    if (running_ || !initialized_) {
        return false;
    }
    
    running_ = true;
    
    // 注意：这里需要集成实际的HTTP服务器库（如 libmicrohttpd 或 crow）
    // 当前为简化实现，只打印日志
    std::cout << "[REST] Server started at " << getBaseUrl() << std::endl;
    std::cout << "[REST] API endpoints available:" << std::endl;
    std::cout << "  GET    /health" << std::endl;
    std::cout << "  POST   /api/auth/login" << std::endl;
    std::cout << "  POST   /api/auth/register" << std::endl;
    std::cout << "  GET    /api/credentials" << std::endl;
    std::cout << "  POST   /api/credentials" << std::endl;
    std::cout << "  GET    /api/devices" << std::endl;
    std::cout << "  GET    /api/stats" << std::endl;
    std::cout << "  GET    /api/security/status" << std::endl;
    
    return true;
}

void RestServer::stop() {
    if (!running_) {
        return;
    }
    
    running_ = false;
    std::cout << "[REST] Server stopped" << std::endl;
}

void RestServer::get(const std::string& path, RouteHandler handler) {
    router_.addRoute(HttpMethod::GET, path, handler);
}

void RestServer::post(const std::string& path, RouteHandler handler) {
    router_.addRoute(HttpMethod::POST, path, handler);
}

void RestServer::put(const std::string& path, RouteHandler handler) {
    router_.addRoute(HttpMethod::PUT, path, handler);
}

void RestServer::delete_(const std::string& path, RouteHandler handler) {
    router_.addRoute(HttpMethod::DELETE, path, handler);
}

void RestServer::patch(const std::string& path, RouteHandler handler) {
    router_.addRoute(HttpMethod::PATCH, path, handler);
}

void RestServer::useBefore(std::function<void(HttpRequest&)> middleware) {
    before_middleware_.push_back(middleware);
}

std::string RestServer::getBaseUrl() const {
    return "http://" + config_.host + ":" + std::to_string(config_.port);
}

void RestServer::setupDefaultRoutes() {
    // 健康检查
    get("/health", [](const HttpRequest& req) {
        return HttpResponse::json(200, "{\"status\":\"ok\",\"timestamp\":" + 
            std::to_string(std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count()) + "}");
    });
}

HttpResponse RestServer::processRequest(const HttpRequest& request) {
    // 应用前置中间件
    for (auto& middleware : before_middleware_) {
        try {
            middleware(const_cast<HttpRequest&>(request));
        } catch (const std::exception& e) {
            return HttpResponse::error(400, e.what());
        }
    }
    
    // 路由请求
    auto response = router_.handleRequest(request);
    
    if (response.has_value()) {
        requests_served_++;
        return response.value();
    }
    
    requests_failed_++;
    return HttpResponse::error(404, "Not Found");
}

std::string RestServer::getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
    return std::to_string(ms);
}

// ============================================================================
// 便捷函数
// ============================================================================

std::unique_ptr<RestServer> createRestServer(const RestServerConfig& config) {
    return std::make_unique<RestServer>(config);
}

std::string toJson(const std::map<std::string, std::string>& obj) {
    std::string json = "{";
    bool first = true;
    for (const auto& [key, value] : obj) {
        if (!first) json += ",";
        json += "\"" + key + "\":\"" + value + "\"";
        first = false;
    }
    json += "}";
    return json;
}

std::optional<std::map<std::string, std::string>> parseJson(const std::string& json) {
    // 简化实现
    if (json.empty() || json == "{}") {
        return std::map<std::string, std::string>{};
    }
    
    // 实际应使用 JSON 解析库
    return std::nullopt;
}

} // namespace server
} // namespace polyvault