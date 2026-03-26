/**
 * @file filter_plugin.hpp
 * @brief 过滤器插件实现
 * 
 * 功能：根据条件筛选消息
 */

#pragma once

#include "plugin_interface.hpp"
#include <vector>
#include <string>
#include <regex>

namespace polyvault {
namespace plugins {

// ============================================================================
// 过滤器条件类型
// ============================================================================

enum class FilterOperator {
    EQUALS,           // ==
    NOT_EQUALS,       // !=
    GREATER_THAN,     // >
    LESS_THAN,        // <
    GREATER_EQUAL,    // >=
    LESS_EQUAL,       // <=
    CONTAINS,         // 包含
    STARTS_WITH,      // 开头
    ENDS_WITH,        // 结尾
    REGEX_MATCH,      // 正则匹配
    IN_LIST,          // 在列表中
    NOT_IN_LIST       // 不在列表中
};

// ============================================================================
// 过滤器条件
// ============================================================================

struct FilterCondition {
    std::string field;           // 字段名 (如: "topic", "source_id", "payload.type")
    FilterOperator op;           // 操作符
    std::string value;           // 比较值
    bool case_sensitive = true;  // 是否区分大小写
    
    // 用于IN_LIST/NOT_IN_LIST
    std::vector<std::string> value_list;
};

// ============================================================================
// 过滤器插件实现
// ============================================================================

class FilterPlugin : public plugin::IFilterPlugin {
public:
    FilterPlugin();
    ~FilterPlugin() override = default;

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

    // IFilterPlugin 接口实现
    void addCondition(const FilterCondition& condition) override;
    void clearConditions() override;
    std::vector<FilterCondition> getConditions() const override;
    bool filter(const bus::Message& message) override;

    // 便捷方法
    void addEqualsCondition(const std::string& field, const std::string& value);
    void addContainsCondition(const std::string& field, const std::string& value);
    void addRegexCondition(const std::string& field, const std::string& pattern);
    void addInListCondition(const std::string& field, const std::vector<std::string>& values);

private:
    // 内部方法
    std::string getFieldValue(const bus::Message& msg, const std::string& field) const;
    bool evaluateCondition(const FilterCondition& condition, const bus::Message& msg) const;
    bool compareValues(const std::string& field_value, FilterOperator op, const std::string& compare_value) const;
    bool matchesRegex(const std::string& value, const std::string& pattern) const;
    
private:
    plugin::PluginContext context_;
    plugin::PluginState state_ = plugin::PluginState::UNINITIALIZED;
    std::map<std::string, std::string> config_;
    std::vector<FilterCondition> conditions_;
    
    // 指标
    uint64_t messages_processed_ = 0;
    uint64_t messages_passed_ = 0;
    uint64_t messages_filtered_ = 0;
};

// ============================================================================
// 预定义过滤器
// ============================================================================

/**
 * @brief 主题过滤器 - 按主题筛选
 */
class TopicFilterPlugin : public FilterPlugin {
public:
    TopicFilterPlugin();
    explicit TopicFilterPlugin(const std::vector<std::string>& allowed_topics);
    
    void setAllowedTopics(const std::vector<std::string>& topics);
    void addAllowedTopic(const std::string& topic);
    
    plugin::PluginMetadata getMetadata() const override;
};

/**
 * @brief 来源过滤器 - 按来源ID筛选
 */
class SourceFilterPlugin : public FilterPlugin {
public:
    SourceFilterPlugin();
    explicit SourceFilterPlugin(const std::vector<std::string>& allowed_sources);
    
    void setAllowedSources(const std::vector<std::string>& sources);
    void addAllowedSource(const std::string& source);
    
    plugin::PluginMetadata getMetadata() const override;
};

/**
 * @brief 消息类型过滤器 - 按消息类型筛选
 */
class MessageTypeFilterPlugin : public FilterPlugin {
public:
    MessageTypeFilterPlugin();
    explicit MessageTypeFilterPlugin(const std::vector<bus::MessageKind>& allowed_types);
    
    void setAllowedTypes(const std::vector<bus::MessageKind>& types);
    void addAllowedType(bus::MessageKind type);
    
    plugin::PluginMetadata getMetadata() const override;
};

} // namespace plugins
} // namespace polyvault