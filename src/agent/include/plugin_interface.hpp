/**
 * @file plugin_interface.hpp
 * @brief PolyVault插件系统接口定义
 */

#pragma once

#include <string>
#include <vector>
#include <memory>
#include <functional>
#include <map>
#include "data_bus.hpp"

namespace polyvault {
namespace plugin {

// ============================================================================
// 插件元数据
// ============================================================================

struct PluginMetadata {
    std::string id;              // 插件唯一ID
    std::string name;            // 插件名称
    std::string version;         // 版本号
    std::string author;          // 作者
    std::string description;     // 描述
    std::vector<std::string> tags;  // 标签
    std::string type;            // 插件类型: filter, transformer, aggregator, dispatcher
};

// ============================================================================
// 插件上下文
// ============================================================================

struct PluginContext {
    bus::DataBus* bus;                    // 数据总线引用
    std::map<std::string, std::string> config;  // 配置参数
    std::function<void(const std::string&)> log; // 日志函数
    std::function<void(const std::string&)> error; // 错误日志
};

// ============================================================================
// 插件状态
// ============================================================================

enum class PluginState {
    UNINITIALIZED,
    INITIALIZING,
    RUNNING,
    PAUSED,
    STOPPED,
    ERROR
};

// ============================================================================
// 插件结果
// ============================================================================

template<typename T>
struct PluginResult {
    bool success;
    std::string error_message;
    T data;
    
    static PluginResult<T> ok(T data) {
        return {true, "", std::move(data)};
    }
    
    static PluginResult<T> err(const std::string& msg) {
        return {false, msg, T{}};
    }
};

// ============================================================================
// 插件基类
// ============================================================================

class IPlugin {
public:
    virtual ~IPlugin() = default;
    
    // 生命周期管理
    virtual bool initialize(const PluginContext& context) = 0;
    virtual bool start() = 0;
    virtual bool stop() = 0;
    virtual bool pause() = 0;
    virtual bool resume() = 0;
    
    // 元数据
    virtual PluginMetadata getMetadata() const = 0;
    virtual PluginState getState() const = 0;
    
    // 配置
    virtual bool configure(const std::map<std::string, std::string>& config) = 0;
    virtual std::map<std::string, std::string> getConfig() const = 0;
    
    // 处理消息
    virtual bus::Message process(const bus::Message& input) = 0;
    
    // 健康检查
    virtual bool healthCheck() const = 0;
    
    // 指标
    virtual std::map<std::string, double> getMetrics() const = 0;
};

// ============================================================================
// 过滤器插件接口
// ============================================================================

class IFilterPlugin : public IPlugin {
public:
    // 过滤条件
    struct FilterCondition {
        std::string field;      // 字段名
        std::string op;         // 操作符: eq, ne, gt, lt, gte, lte, contains, regex
        std::string value;      // 值
    };
    
    // 添加过滤条件
    virtual void addCondition(const FilterCondition& condition) = 0;
    
    // 清除所有条件
    virtual void clearConditions() = 0;
    
    // 获取所有条件
    virtual std::vector<FilterCondition> getConditions() const = 0;
    
    // 判断消息是否通过过滤
    virtual bool filter(const bus::Message& message) = 0;
};

// ============================================================================
// 转换器插件接口
// ============================================================================

class ITransformerPlugin : public IPlugin {
public:
    // 转换规则
    struct TransformRule {
        std::string source_field;    // 源字段
        std::string target_field;    // 目标字段
        std::string transform_type;  // 转换类型: map, format, extract, compute
        std::string expression;      // 转换表达式
    };
    
    // 添加转换规则
    virtual void addRule(const TransformRule& rule) = 0;
    
    // 清除所有规则
    virtual void clearRules() = 0;
    
    // 获取所有规则
    virtual std::vector<TransformRule> getRules() const = 0;
    
    // 执行转换
    virtual bus::Message transform(const bus::Message& input) = 0;
};

// ============================================================================
// 汇流器插件接口 (Aggregator)
// ============================================================================

class IAggregatorPlugin : public IPlugin {
public:
    // 聚合窗口
    struct AggregationWindow {
        std::string type;        // tumbling, sliding, session
        uint64_t size_ms;        // 窗口大小（毫秒）
        uint64_t slide_ms;       // 滑动间隔（滑动窗口）
        uint64_t timeout_ms;     // 会话超时（会话窗口）
    };
    
    // 聚合函数
    struct AggregationFunction {
        std::string field;       // 聚合字段
        std::string function;    // 函数: sum, avg, min, max, count, first, last
        std::string alias;       // 结果别名
    };
    
    // 设置窗口
    virtual void setWindow(const AggregationWindow& window) = 0;
    
    // 添加聚合函数
    virtual void addFunction(const AggregationFunction& func) = 0;
    
    // 设置分组字段
    virtual void setGroupBy(const std::vector<std::string>& fields) = 0;
    
    // 处理消息（触发聚合）
    virtual void aggregate(const bus::Message& message) = 0;
    
    // 获取聚合结果
    virtual std::vector<bus::Message> getResults() = 0;
    
    // 触发窗口输出
    virtual std::vector<bus::Message> triggerWindow() = 0;
};

// ============================================================================
// 分发器插件接口 (Dispatcher)
// ============================================================================

class IDispatcherPlugin : public IPlugin {
public:
    // 分发目标
    struct DispatchTarget {
        std::string id;           // 目标ID
        std::string endpoint;     // 目标端点
        std::string protocol;     // 协议: http, grpc, kafka, mqtt
        std::map<std::string, std::string> headers;  // HTTP头
        int priority;             // 优先级
        bool enabled;             // 是否启用
    };
    
    // 分发策略
    enum class DispatchStrategy {
        ROUND_ROBIN,      // 轮询
        RANDOM,           // 随机
        WEIGHTED,         // 加权
        LEAST_CONNECTION, // 最少连接
        BROADCAST         // 广播
    };
    
    // 添加分发目标
    virtual void addTarget(const DispatchTarget& target) = 0;
    
    // 移除分发目标
    virtual void removeTarget(const std::string& target_id) = 0;
    
    // 获取所有目标
    virtual std::vector<DispatchTarget> getTargets() const = 0;
    
    // 设置分发策略
    virtual void setStrategy(DispatchStrategy strategy) = 0;
    
    // 分发消息
    virtual bool dispatch(const bus::Message& message) = 0;
    
    // 获取目标状态
    virtual std::map<std::string, bool> getTargetStatus() const = 0;
};

// ============================================================================
// 插件工厂
// ============================================================================

class PluginFactory {
public:
    using CreatorFunc = std::function<std::unique_ptr<IPlugin>()>;
    
    // 注册插件
    static bool registerPlugin(const std::string& type, const std::string& id, CreatorFunc creator) {
        auto& registry = getRegistry();
        std::string key = type + ":" + id;
        registry[key] = std::move(creator);
        return true;
    }
    
    // 创建插件
    static std::unique_ptr<IPlugin> create(const std::string& type, const std::string& id) {
        auto& registry = getRegistry();
        std::string key = type + ":" + id;
        auto it = registry.find(key);
        if (it != registry.end()) {
            return it->second();
        }
        return nullptr;
    }
    
    // 列出所有插件
    static std::vector<std::pair<std::string, std::string>> listPlugins() {
        std::vector<std::pair<std::string, std::string>> result;
        for (const auto& [key, _] : getRegistry()) {
            auto pos = key.find(':');
            if (pos != std::string::npos) {
                result.emplace_back(key.substr(0, pos), key.substr(pos + 1));
            }
        }
        return result;
    }
    
private:
    static std::map<std::string, CreatorFunc>& getRegistry() {
        static std::map<std::string, CreatorFunc> registry;
        return registry;
    }
};

// ============================================================================
// 插件注册宏
// ============================================================================

#define POLYVAULT_REGISTER_PLUGIN(type, id, className) \
    static bool _plugin_registered_##type##_##id = \
        polyvault::plugin::PluginFactory::registerPlugin(#type, #id, \
            []() -> std::unique_ptr<polyvault::plugin::IPlugin> { \
                return std::make_unique<className>(); \
            })

} // namespace plugin
} // namespace polyvault