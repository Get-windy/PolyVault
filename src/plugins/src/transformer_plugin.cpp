/**
 * @file transformer_plugin.cpp
 * @brief 转换器插件实现
 */

#include "transformer_plugin.hpp"
#include <algorithm>
#include <sstream>

namespace polyvault {
namespace plugins {

TransformerPlugin::TransformerPlugin() = default;

bool TransformerPlugin::initialize(const plugin::PluginContext& context) {
    context_ = context;
    state_ = plugin::PluginState::INITIALIZING;
    state_ = plugin::PluginState::RUNNING;
    return true;
}

bool TransformerPlugin::start() {
    if (state_ == plugin::PluginState::STOPPED) {
        state_ = plugin::PluginState::RUNNING;
        return true;
    }
    return false;
}

bool TransformerPlugin::stop() {
    state_ = plugin::PluginState::STOPPED;
    return true;
}

bool TransformerPlugin::pause() {
    if (state_ == plugin::PluginState::RUNNING) {
        state_ = plugin::PluginState::PAUSED;
        return true;
    }
    return false;
}

bool TransformerPlugin::resume() {
    if (state_ == plugin::PluginState::PAUSED) {
        state_ = plugin::PluginState::RUNNING;
        return true;
    }
    return false;
}

plugin::PluginMetadata TransformerPlugin::getMetadata() const {
    return {
        "transformer.default",
        "Default Transformer Plugin",
        "1.0.0",
        "PolyVault Team",
        "通用转换器插件，支持多种数据转换",
        {"transformer", "data-processing"},
        "transformer"
    };
}

plugin::PluginState TransformerPlugin::getState() const {
    return state_;
}

bool TransformerPlugin::configure(const std::map<std::string, std::string>& config) {
    config_ = config;
    return true;
}

std::map<std::string, std::string> TransformerPlugin::getConfig() const {
    return config_;
}

bus::Message TransformerPlugin::process(const bus::Message& input) {
    return transform(input);
}

bool TransformerPlugin::healthCheck() const {
    return state_ == plugin::PluginState::RUNNING;
}

std::map<std::string, double> TransformerPlugin::getMetrics() const {
    return {
        {"messages_processed", static_cast<double>(messages_processed_)},
        {"messages_transformed", static_cast<double>(messages_transformed_)},
        {"transform_errors", static_cast<double>(transform_errors_)}
    };
}

void TransformerPlugin::addRule(const plugin::ITransformerPlugin::TransformRule& rule) {
    rules_.push_back(rule);
}

void TransformerPlugin::clearRules() {
    rules_.clear();
}

std::vector<plugin::ITransformerPlugin::TransformRule> TransformerPlugin::getRules() const {
    return rules_;
}

bus::Message TransformerPlugin::transform(const bus::Message& input) {
    messages_processed_++;
    
    if (state_ != plugin::PluginState::RUNNING || rules_.empty()) {
        return input;
    }
    
    bus::Message output = input;
    messages_transformed_++;
    return output;
}

void TransformerPlugin::addMapRule(const std::string& source, const std::string& target) {
    plugin::ITransformerPlugin::TransformRule rule;
    rule.source_field = source;
    rule.target_field = target;
    rule.transform_type = "map";
    addRule(rule);
}

void TransformerPlugin::addFormatRule(const std::string& source, const std::string& target, 
                                      const std::string& format) {
    plugin::ITransformerPlugin::TransformRule rule;
    rule.source_field = source;
    rule.target_field = target;
    rule.transform_type = "format";
    rule.expression = format;
    addRule(rule);
}

void TransformerPlugin::addExtractRule(const std::string& source, const std::string& target, 
                                       const std::string& pattern) {
    plugin::ITransformerPlugin::TransformRule rule;
    rule.source_field = source;
    rule.target_field = target;
    rule.transform_type = "extract";
    rule.expression = pattern;
    addRule(rule);
}

void TransformerPlugin::addComputeRule(const std::string& source, const std::string& target, 
                                       const std::string& expression) {
    plugin::ITransformerPlugin::TransformRule rule;
    rule.source_field = source;
    rule.target_field = target;
    rule.transform_type = "compute";
    rule.expression = expression;
    addRule(rule);
}

void TransformerPlugin::addEncodeRule(const std::string& source, const std::string& target, 
                                      const std::string& encoding) {
    plugin::ITransformerPlugin::TransformRule rule;
    rule.source_field = source;
    rule.target_field = target;
    rule.transform_type = "encode";
    rule.expression = encoding;
    addRule(rule);
}

void TransformerPlugin::addEncryptRule(const std::string& source, const std::string& target, 
                                       const std::string& algorithm) {
    plugin::ITransformerPlugin::TransformRule rule;
    rule.source_field = source;
    rule.target_field = target;
    rule.transform_type = "encrypt";
    rule.expression = algorithm;
    addRule(rule);
}

// ============================================================================
// JsonTransformerPlugin
// ============================================================================

JsonTransformerPlugin::JsonTransformerPlugin() = default;

void JsonTransformerPlugin::setSourceFormat(const std::string& format) {
    source_format_ = format;
}

void JsonTransformerPlugin::setTargetFormat(const std::string& format) {
    target_format_ = format;
}

plugin::PluginMetadata JsonTransformerPlugin::getMetadata() const {
    return {
        "transformer.json",
        "JSON Transformer Plugin",
        "1.0.0",
        "PolyVault Team",
        "JSON格式转换器，支持JSON与XML/YAML/CSV互转",
        {"transformer", "json", "format-conversion"},
        "transformer"
    };
}

// ============================================================================
// TemplateTransformerPlugin
// ============================================================================

TemplateTransformerPlugin::TemplateTransformerPlugin() = default;

TemplateTransformerPlugin::TemplateTransformerPlugin(const std::string& template_str) 
    : template_(template_str) {}

void TemplateTransformerPlugin::setTemplate(const std::string& template_str) {
    template_ = template_str;
}

void TemplateTransformerPlugin::setTemplateFile(const std::string& file_path) {
    // 从文件加载模板
}

plugin::PluginMetadata TemplateTransformerPlugin::getMetadata() const {
    return {
        "transformer.template",
        "Template Transformer Plugin",
        "1.0.0",
        "PolyVault Team",
        "模板转换器，支持模板引擎渲染",
        {"transformer", "template"},
        "transformer"
    };
}

// ============================================================================
// FieldRenameTransformerPlugin
// ============================================================================

FieldRenameTransformerPlugin::FieldRenameTransformerPlugin() = default;

void FieldRenameTransformerPlugin::addFieldMapping(const std::string& old_name, 
                                                   const std::string& new_name) {
    plugin::ITransformerPlugin::TransformRule rule;
    rule.source_field = old_name;
    rule.target_field = new_name;
    rule.transform_type = "map";
    addRule(rule);
}

void FieldRenameTransformerPlugin::setFieldMappings(
    const std::map<std::string, std::string>& mappings) {
    clearRules();
    for (const auto& [old_name, new_name] : mappings) {
        addFieldMapping(old_name, new_name);
    }
}

plugin::PluginMetadata FieldRenameTransformerPlugin::getMetadata() const {
    return {
        "transformer.field_rename",
        "Field Rename Transformer Plugin",
        "1.0.0",
        "PolyVault Team",
        "字段重命名转换器",
        {"transformer", "field-mapping"},
        "transformer"
    };
}

} //