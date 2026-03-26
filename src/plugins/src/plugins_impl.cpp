/**
 * @file plugins_impl.cpp
 * @brief 四大插件类型实现
 * 
 * 1. 过滤器插件 - 数据筛选
 * 2. 转换器插件 - 格式转换
 * 3. 汇流器插件 - 多源汇聚
 * 4. 分发器插件 - 一对多分发
 */

#include "../include/filter_plugin.hpp"
#include <iostream>
#include <algorithm>
#include <sstream>

namespace polyvault {
namespace plugins {

// ============================================================================
// 过滤器插件实现
// ============================================================================

FilterPlugin::FilterPlugin() {
    std::cout << "[FilterPlugin] Created" << std::endl;
}

bool FilterPlugin::initialize(const plugin::PluginContext& context) {
    context_ = context;
    state_ = plugin::PluginState::INITIALIZING;
    
    if (context.log) {
        context.log("FilterPlugin initialized");
    }
    
    state_ = plugin::PluginState::RUNNING;
    return true;
}

bool FilterPlugin::start() {
    state_ = plugin::PluginState::RUNNING;
    return true;
}

bool FilterPlugin::stop() {
    state_ = plugin::PluginState::STOPPED;
    return true;
}

bool FilterPlugin::pause() {
    state_ = plugin::PluginState::PAUSED;
    return true;
}

bool FilterPlugin::resume() {
    state_ = plugin::PluginState::RUNNING;
    return true;
}

plugin::PluginMetadata FilterPlugin::getMetadata() const {
    return {
        "filter",
        "Filter Plugin",
        "1.0.0",
        "PolyVault Team",
        "Filters messages based on conditions",
        {"filter", "data-processing"},
        "filter"
    };
}

plugin::PluginState FilterPlugin::getState() const {
    return state_;
}

bool FilterPlugin::configure(const std::map<std::string, std::string>& config) {
    config_ = config;
    return true;
}

std::map<std::string, std::string> FilterPlugin::getConfig() const {
    return config_;
}

bus::Message FilterPlugin::process(const bus::Message& input) {
    messages_processed_++;
    
    if (filter(input)) {
        messages_passed_++;
        return input;
    }
    
    messages_filtered_++;
    return bus::Message{};  // 返回空消息表示被过滤
}

bool FilterPlugin::healthCheck() const {
    return state_ == plugin::PluginState::RUNNING;
}

std::map<std::string, double> FilterPlugin::getMetrics() const {
    return {
        {"messages_processed", static_cast<double>(messages_processed_)},
        {"messages_passed", static_cast<double>(messages_passed_)},
        {"messages_filtered", static_cast<double>(messages_filtered_)},
        {"filter_rate", messages_processed_ > 0 ? 
            static_cast<double>(messages_filtered_) / messages_processed_ : 0.0}
    };
}

void FilterPlugin::addCondition(const FilterCondition& condition) {
    conditions_.push_back(condition);
}

void FilterPlugin::clearConditions() {
    conditions_.clear();
}

std::vector<FilterCondition> FilterPlugin::getConditions() const {
    return conditions_;
}

bool FilterPlugin::filter(const bus::Message& message) {
    if (conditions_.empty()) {
        return true;  // 无条件时全部通过
    }
    
    // 所有条件都必须满足 (AND逻辑)
    for (const auto& condition : conditions_) {
        if (!evaluateCondition(condition, message)) {
            return false;
        }
    }
    
    return true;
}

void FilterPlugin::addEqualsCondition(const std::string& field, const std::string& value) {
    FilterCondition cond;
    cond.field = field;
    cond.op = FilterOperator::EQUALS;
    cond.value = value;
    addCondition(cond);
}

void FilterPlugin::addContainsCondition(const std::string& field, const std::string& value) {
    FilterCondition cond;
    cond.field = field;
    cond.op = FilterOperator::CONTAINS;
    cond.value = value;
    addCondition(cond);
}

void FilterPlugin::addRegexCondition(const std::string& field, const std::string& pattern) {
    FilterCondition cond;
    cond.field = field;
    cond.op = FilterOperator::REGEX_MATCH;
    cond.value = pattern;
    addCondition(cond);
}

void FilterPlugin::addInListCondition(const std::string& field, const std::vector<std::string>& values) {
    FilterCondition cond;
    cond.field = field;
    cond.op = FilterOperator::IN_LIST;
    cond.value_list = values;
    addCondition(cond);
}

std::string FilterPlugin::getFieldValue(const bus::Message& msg, const std::string& field) const {
    if (field == "topic") return msg.topic;
    if (field == "source_id") return msg.source_id;
    if (field == "target_id") return msg.target_id;
    if (field == "message_id") return msg.message_id;
    if (field == "kind") return std::to_string(static_cast<int>(msg.kind));
    if (field == "timestamp") return std::to_string(msg.timestamp);
    
    // 支持嵌套字段 (如: "payload.type")
    if (field.find("payload.") == 0) {
        // 简化的payload字段访问
        return "";  // 实际实现需要解析payload
    }
    
    return "";
}

bool FilterPlugin::evaluateCondition(const FilterCondition& condition, const bus::Message& msg) const {
    std::string field_value = getFieldValue(msg, condition.field);
    return compareValues(field_value, condition.op, condition.value);
}

bool FilterPlugin::compareValues(const std::string& field_value, FilterOperator op, 
                                  const std::string& compare_value) const {
    switch (op) {
        case FilterOperator::EQUALS:
            return field_value == compare_value;
        case FilterOperator::NOT_EQUALS:
            return field_value != compare_value;
        case FilterOperator::CONTAINS:
            return field_value.find(compare_value) != std::string::npos;
        case FilterOperator::STARTS_WITH:
            return field_value.find(compare_value) == 0;
        case FilterOperator::ENDS_WITH: {
            if (compare_value.length() > field_value.length()) return false;
            return field_value.substr(field_value.length() - compare_value.length()) == compare_value;
        }
        case FilterOperator::REGEX_MATCH:
            return matchesRegex(field_value, compare_value);
        case FilterOperator::GREATER_THAN:
        case FilterOperator::LESS_THAN:
        case FilterOperator::GREATER_EQUAL:
        case FilterOperator::LESS_EQUAL: {
            // 数值比较
            try {
                double field_num = std::stod(field_value);
                double compare_num = std::stod(compare_value);
                switch (op) {
                    case FilterOperator::GREATER_THAN: return field_num > compare_num;
                    case FilterOperator::LESS_THAN: return field_num < compare_num;
                    case FilterOperator::GREATER_EQUAL: return field_num >= compare_num;
                    case FilterOperator::LESS_EQUAL: return field_num <= compare_num;
                    default: return false;
                }
            } catch (...) {
                return false;
            }
        }
        default:
            return false;
    }
}

bool FilterPlugin::matchesRegex(const std::string& value, const std::string& pattern) const {
    try {
        std::regex re(pattern);
        return std::regex_match(value, re);
    } catch (...) {
        return false;
    }
}

// 主题过滤器实现
TopicFilterPlugin::TopicFilterPlugin() {
    std::cout << "[TopicFilterPlugin] Created" << std::endl;
}

TopicFilterPlugin::TopicFilterPlugin(const std::vector<std::string>& allowed_topics) {
    setAllowedTopics(allowed_topics);
}

void TopicFilterPlugin::setAllowedTopics(const std::vector<std::string>& topics) {
    clearConditions();
    for (const auto& topic : topics) {
        addAllowedTopic(topic);
    }
}

void TopicFilterPlugin::addAllowedTopic(const std::string& topic) {
    FilterCondition cond;
    cond.field = "topic";
    cond.op = FilterOperator::EQUALS;
    cond.value = topic;
    addCondition(cond);
}

plugin::PluginMetadata TopicFilterPlugin::getMetadata() const {
    return {
        "topic