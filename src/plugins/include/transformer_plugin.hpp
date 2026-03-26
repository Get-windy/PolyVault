/**
 * @file transformer_plugin.hpp
 * @brief 转换器插件实现
 * 
 * 功能：转换消息格式和内容
 */

#pragma once

#include "plugin_interface.hpp"
#include <vector>
#include <string>
#include <map>
#include <functional>

namespace polyvault {
namespace plugins {

// ============================================================================
// 转换操作类型
// ============================================================================

enum class TransformType {
    MAP,           // 字段映射
    FORMAT,        // 格式转换
    EXTRACT,       // 提取
    COMPUTE,       // 计算
    ENCRYPT,       // 加密
    DECRYPT,       // 解密
    ENCODE,        // 编码
    DECODE,        // 解码
    COMPRESS,      // 压缩
    DECOMPRESS,    // 解压缩
    CUSTOM         // 自定义
};

// ============================================================================
// 转换规则
// ============================================================================

struct TransformRule {
    std::string source_field;     // 源字段
    std::string target_field;     // 目标字段
    TransformType type;           // 转换类型
    std::string expression;       // 转换表达式/模板
    std::map<std::string, std::string> params;  // 额外参数
    bool required = true;         // 是否必需
    std::string default_value;    // 默认值
};

// ============================================================================
// 转换器插件实现
// ============================================================================

class TransformerPlugin : public plugin::ITransformerPlugin {
public:
    TransformerPlugin();
    ~TransformerPlugin() override = default;

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

    // ITransformerPlugin 接口实现
    void addRule(const plugin::ITransformerPlugin::TransformRule& rule) override;
    void clearRules() override;
    std::vector<plugin::ITransformerPlugin::TransformRule> getRules() const override;
    bus::Message transform(const bus::Message& input) override;

    // 便捷方法
    void addMapRule(const std::string& source, const std::string& target);
    void addFormatRule(const std::string& source, const std::string& target, 
                       const std::string& format);
    void addExtractRule(const std::string& source, const std::string& target, 
                        const std::string& pattern);
    void addComputeRule(const std::string& source, const std::string& target, 
                        const std::string& expression);
    void addEncodeRule(const std::string& source, const std::string& target, 
                       const std::string& encoding);
    void addEncryptRule(const std::string& source, const std::string& target, 
                        const std::string& algorithm);

private:
    // 内部方法
    std::string getFieldValue(const bus::Message& msg, const std::string& field) const;
    void setFieldValue(bus::Message& msg, const std::string& field, 
                       const std::string& value) const;
    
    std::string applyTransform(const std::string& value, 
                               const plugin::ITransformerPlugin::TransformRule& rule) const;
    
    std::string applyMap(const std::string& value, const std::string& expression) const;
    std::string applyFormat(const std::string& value, const std::string& format) const;
    std::string applyExtract(const std::string& value, const std::string& pattern) const;
    std::string applyCompute(const std::string& value, const std::string& expression) const;
    std::string applyEncode(const std::string& value, const std::string& encoding) const;
    std::string applyEncrypt(const std::string& value, const std::string& algorithm) const;
    
    TransformType stringToType(const std::string& str) const;
    std::string typeToString(TransformType type) const;
    
private:
    plugin::PluginContext context_;
    plugin::PluginState state_ = plugin::PluginState::UNINITIALIZED;
    std::map<std::string, std::string> config_;
    std::vector<plugin::ITransformerPlugin::TransformRule> rules_;
    
    // 指标
    uint64_t messages_processed_ = 0;
    uint64_t messages_transformed_ = 0;
    uint64_t transform_errors_ = 0;
};

// ============================================================================
// 预定义转换器
// ============================================================================

/**
 * @brief JSON转换器 - JSON与其他格式互转
 */
class JsonTransformerPlugin : public TransformerPlugin {
public:
    JsonTransformerPlugin();
    
    void setSourceFormat(const std::string& format);  // xml, yaml, csv
    void setTargetFormat(const std::string& format);  // xml, yaml, csv
    
    plugin::PluginMetadata getMetadata() const override;
    
private:
    std::string source_format_ = "json";
    std::string target_format_ = "json";
};

/**
 * @brief 模板转换器 - 使用模板引擎
 */
class TemplateTransformerPlugin : public TransformerPlugin {
public:
    TemplateTransformerPlugin();
    explicit TemplateTransformerPlugin(const std::string& template_str);
    
    void setTemplate(const std::string& template_str);
    void setTemplateFile(const std::string& file_path);
    
    plugin::PluginMetadata getMetadata() const override;
    
private:
    std::string template_;
};

/**
 * @brief 字段重命名转换器
 */
class FieldRenameTransformerPlugin : public TransformerPlugin {
public:
    FieldRenameTransformerPlugin();
    
    void addFieldMapping(const std::string& old_name, const std::string& new_name);
    void setFieldMappings(const std::map<std::string, std::string>& mappings);
    
    plugin::PluginMetadata getMetadata() const override;
};

} // namespace plugins
} // namespace polyvault