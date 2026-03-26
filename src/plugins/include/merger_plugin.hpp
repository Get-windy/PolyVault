/**
 * @file merger_plugin.hpp
 * @brief 汇流器插件实现 (Aggregator/Merger)
 * 
 * 功能：聚合多源消息，支持时间窗口和分组
 */

#pragma once

#include "plugin_interface.hpp"
#include <vector>
#include <string>
#include <map>
#include <queue>
#include <chrono>

namespace polyvault {
namespace plugins {

// ============================================================================
// 窗口类型
// ============================================================================

enum class WindowType {
    TUMBLING,    // 滚动窗口 - 固定大小，不重叠
    SLIDING,     // 滑动窗口 - 固定大小，可重叠
    SESSION,     // 会话窗口 - 动态大小，按活动间隙分割
    GLOBAL       // 全局窗口 - 所有数据一个窗口
};

// ============================================================================
// 聚合函数类型
// ============================================================================

enum class AggregationFunction {
    SUM,         // 求和
    AVG,         // 平均值
    MIN,         // 最小值
    MAX,         // 最大值
    COUNT,       // 计数
    FIRST,       // 第一个值
    LAST,        // 最后一个值
    DISTINCT,    // 去重计数
    COLLECT      // 收集所有值
};

// ============================================================================
// 窗口配置
// ============================================================================

struct WindowConfig {
    WindowType type = WindowType::TUMBLING;
    uint64_t size_ms = 60000;        // 窗口大小（毫秒）
    uint64_t slide_ms = 60000;       // 滑动间隔（滑动窗口）
    uint64_t timeout_ms = 30000;     // 会话超时（会话窗口）
    uint64_t max_messages = 1000;    // 最大消息数
    bool allow_late = false;         // 是否允许迟到数据
    uint64_t late_delay_ms = 0;      // 迟到数据等待时间
};

// ============================================================================
// 聚合配置
// ============================================================================

struct AggregationConfig {
    std::string field;               // 聚合字段
    AggregationFunction function;    // 聚合函数
    std::string alias;               // 结果别名
    std::string default_value;       // 默认值
};

// ============================================================================
// 汇流器插件实现
// ============================================================================

class MergerPlugin : public plugin::IAggregatorPlugin {
public:
    MergerPlugin();
    ~MergerPlugin() override = default;

    // IPlugin 接口实现
    bool initialize(const plugin::PluginContext& context) override;
    bool start() override;
    bool stop() override;
    bool pause() override;
    bool resume() override;
    
    plugin::PluginMetadata getMetadata() const override;
    plugin::PluginState getState() const override;
    
    bool configure(const std::map<std::string, std::string>& config) override;
    std::map<std::string, std::string> getConfig() const override;
    
    bus::Message process(const bus::Message& input) override;
    bool healthCheck() const override;
    std::map<std::string, double> getMetrics() const override;

    // IAggregatorPlugin 接口实现
    void setWindow(const plugin::IAggregatorPlugin::AggregationWindow& window) override;
    void addFunction(const plugin::IAggregatorPlugin::AggregationFunction& func) override;
    void setGroupBy(const std::vector<std::string>& fields) override;
    void aggregate(const bus::Message& message) override;
    std::vector<bus::Message> getResults() override;
    std::vector<bus::Message> triggerWindow() override;

    // 额外方法
    void setWindowConfig(const WindowConfig& config);
    void addAggregationConfig(const AggregationConfig& config);
    void setGroupByFields(const std::vector<std::string>& fields);
    
    // 获取当前窗口信息
    uint64_t getCurrentWindowStart() const;
    uint64_t getCurrentWindowEnd() const;
    size_t getBufferedMessageCount() const;
    
    // 手动触发
    std::vector<bus::Message> flush();
    void clearBuffer();

private:
    // 内部结构
    struct WindowState {
        uint64_t start_time;
        uint64_t end_time;
        std::vector<bus::Message> messages;
        std::map<std::string, std::vector<std::string>> groups;
    };
    
    // 内部方法
    uint64_t getCurrentTime() const;
    uint64_t calculateWindowStart(uint64_t timestamp) const;
    bool isInWindow(const bus::Message& msg, const WindowState& window) const;
    bool shouldTriggerWindow(const WindowState& window) const;
    
    bus::Message createAggregationResult(const WindowState& window);
    std::string applyAggregation(const std::vector<std::string>& values, 
                                 AggregationFunction func) const;
    
    std::string getGroupKey(const bus::Message& msg) const;
    std::string getFieldValue(const bus::Message& msg, const std::string& field) const;
    
    void checkAndTriggerWindows();
    void removeExpiredWindows();
    
private:
    plugin::PluginContext context_;
    plugin::PluginState state_ = plugin::PluginState::UNINITIALIZED;
    std::map<std::string, std::string> config_;
    
    WindowConfig window_config_;
    std::vector<AggregationConfig> aggregation_configs_;
    std::vector<std::string> group_by_fields_;
    
    // 窗口状态
    std::map<uint64_t, WindowState> windows_;  // key: window_start_time
    std::queue<bus::Message> message_buffer_;
    
    // 指标
    uint64_t messages_received_ = 0;
    uint64_t messages_aggregated_ = 0;
    uint64_t windows_triggered_ = 0;
    uint64_t late_messages_dropped_ = 0;
};

// ============================================================================
// 预定义汇流器
// ============================================================================

/**
 * @brief 计数汇流器 - 简单计数
 */
class CountMergerPlugin : public MergerPlugin {
public:
    CountMergerPlugin();
    explicit CountMergerPlugin(uint64_t window_size_ms);
    
    void setWindowSize(uint64_t ms);
    
    plugin::PluginMetadata getMetadata() const override;
};

/**
 * @brief 求和汇流器 - 对数值字段求和
 */
class SumMergerPlugin : public MergerPlugin {
public:
    SumMergerPlugin();
    SumMergerPlugin(const std::string& field, uint64_t window_size_ms);
    
    void setTargetField(const std::string& field);
    
    plugin::PluginMetadata getMetadata() const override;
    
private:
    std::string target_field_;
};

/**
 * @brief 平均值汇流器 - 计算平均值
 */
class AvgMergerPlugin : public MergerPlugin {
public:
    AvgMergerPlugin();
    AvgMergerPlugin(const std::string& field, uint64_t window_size_ms);
    
    void setTargetField(const std::string& field);
    
    plugin::PluginMetadata getMetadata() const override;
    
private:
    std::string target_field_;
};

/**
 * @brief 会话汇流器 - 按会话聚合
 */
class SessionMergerPlugin : public MergerPlugin {
public:
    SessionMergerPlugin();
    explicit SessionMergerPlugin(uint64_t timeout_ms);
    
    void setSessionTimeout(uint64_t ms);
    void setSessionField(const std::string& field);
    
    plugin::PluginMetadata getMetadata() const override;
    
private:
    std::string session_field_ = "session_id";
};

} // namespace plugins
} // namespace polyvault