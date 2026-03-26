/**
 * @file filter_plugin.cpp
 * @brief 过滤器插件实现
 */

#include "filter_plugin.hpp"
#include <algorithm>
#include <sstream>
#include <json/json.h>

namespace polyvault {
namespace plugins {

// ============================================================================
// FilterPlugin 实现
// ============================================================================

FilterPlugin::FilterPlugin() = default;

bool FilterPlugin::initialize(const plugin::PluginContext& context) {
    context_ = context;
    state_ = plugin::PluginState::INITIALIZING;
    
    // 从配置加载条件
    auto it = context.config.find("conditions");
    if (it != context.config.end()) {
        // 解析JSON格式的条件
        Json::Value root;
        Json::Reader reader;
        if (reader.parse(it->second, root)) {
            for (const auto& cond : root) {
                FilterCondition condition;
                condition.field = cond["field"].asString();
                condition.op = stringToOperator(cond["op"].asString());
                condition.value = cond["value"].asString();
                condition.case_sensitive = cond.get("case_sensitive", true).asBool();
                
                if (cond.isMember("value_list")) {
                    for (const auto& val : cond["value_list"]) {
                        condition.value_list.push_back(val.asString());
                    }
                }
                
                conditions_.push_back(condition);
            }
        }
    }
    
    state_ = plugin::PluginState::RUNNING;
    return true;
}

bool FilterPlugin::start() {
    if (state_ == plugin::PluginState::STOPPED) {
        state_ = plugin::PluginState::RUNNING;
        return true;
    }
    return false;
}

bool FilterPlugin::stop() {
    state_ = plugin::PluginState::STOPPED;
    return true;
}

bool FilterPlugin::pause() {
    if (state_ == plugin::PluginState::RUNNING) {
        state_ = plugin::PluginState::PAUSED;
        return true;
    }
    return false;
}

bool FilterPlugin::resume() {
    if (state_ == plugin::PluginState::PAUSED) {
        state_ = plugin::PluginState::RUNNING;
        return true;
    }
    return false;
}

plugin::PluginMetadata FilterPlugin::getMetadata() const {
    return {
        "filter.default",
        "Default Filter Plugin",
        "1.0.0",
        "PolyVault Team",
        "通用过滤器插件，支持多种过滤条件",
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
    
    if (state_ != plugin::PluginState::RUNNING) {
        return input;  // 非运行状态，直接透传
    }
    
    if (filter(input)) {
        messages_passed_++;
        return input;
    } else {
        messages_filtered_++;
        // 返回空消息表示被过滤
        bus::Message empty_msg;
        empty_msg.message_id = input.message_id;
        empty_msg.kind = bus::MessageKind::EVENT;
        empty_msg.topic = "filtered";
        return empty_msg;
    }
}

bool FilterPlugin::healthCheck() const {
    return state_ == plugin::PluginState::RUNNING;
}

std::map<std::string, double> FilterPlugin::getMetrics() const {
    return {
        {"messages_processed", static_cast<double>(messages_processed_)},
        {"messages_passed", static_cast<double>(messages_passed_)},
        {"messages_filtered", static_cast<double>(messages_filtered_)},
        {"filter_rate", messages_processed_ > 0 
            ? static_cast<double>(messages_filtered_) / messages_processed_ 
            : 0.0}
    };
}

// IFilterPlugin 接口实现

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
    
    // 所有条件必须满足（AND逻辑）
    for (const auto& condition : conditions_) {
        if (!evaluateCondition(condition, message)) {
            return false;
        }
    }
    return true;
}

// 便捷方法

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

void FilterPlugin::addInListCondition(const std::string& field, 
                                      const std::vector<std::string>& values) {
    FilterCondition cond;
    cond.field = field;
    cond.op = FilterOperator::IN_LIST;
    cond.value_list = values;
    addCondition(cond);
}

// 私有方法

std::string FilterPlugin::getFieldValue(const bus::Message& msg, 
                                        const std::string& field) const {
    if (field == "topic") return msg.topic;
    if (field == "source_id") return msg.source_id;
    if (field == "target_id") return msg.target_id;
    if (field == "message_id") return msg.message_id;
    if (field == "kind") return std::to_string(static_cast<int>(msg.kind));
    if (field == "priority") return std::to_string(static_cast<int>(msg.priority));
    
    // 尝试从payload解析JSON字段
    if (!msg.payload.empty()) {
        Json::Value root;
        Json::Reader reader;
        std::string payload_str(msg.payload.begin(), msg.payload.end());
        if (reader.parse(payload_str, root)) {
            // 支持嵌套字段，如 "data.type"
            std::vector<std::string> parts;
            std::stringstream ss(field);
            std::string part;
            while (std::getline(ss, part, '.')) {
                parts.push_back(part);
            }
            
            const Json::Value* current = &root;
            for (const auto& p : parts) {
                if (current->isMember(p)) {
                    current = &(*current)[p];
                } else {
                    return "";
                }
            }
            return current->asString();
        }
    }
    
    return "";
}

bool FilterPlugin::evaluateCondition(const FilterCondition& condition, 
                                     const bus::Message& msg) const {
    std::string field_value = getFieldValue(msg, condition.field);
    std::string compare_value = condition.value;
    
    if (!condition.case_sensitive) {
        // 转换为小写进行比较
        std::transform(field_value.begin(), field_value.end(), 
                      field_value.begin(), ::tolower);
        std::transform(compare_value.begin(), compare_value.end(), 
                      compare_value.begin(), ::tolower);
    }
    
    return compareValues(field_value, condition.op, compare_value);
}

bool FilterPlugin::compareValues(const std::string& field_value, 
                                 FilterOperator op, 
                                 const std::string& compare_value) const {
    switch (op) {
        case FilterOperator::EQUALS:
            return field_value ==