/**
 * @file plugin_manager.cpp
 * @brief 插件管理器实现
 */

#include "plugin_interface.hpp"
#include <iostream>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <algorithm>

#ifdef _WIN32
#include <windows.h>
#else
#include <dlfcn.h>
#endif

namespace polyvault {
namespace plugin {

namespace fs = std::filesystem;

// ============================================================================
// 插件管理器配置
// ============================================================================

struct PluginManagerConfig {
    std::string plugin_dir = "./plugins";
    bool auto_load = true;
    bool allow_unload = true;
    int max_plugins = 100;
    bool sandbox_mode = true;  // 沙箱模式限制插件权限
};

// ============================================================================
// 已加载插件信息
// ============================================================================

struct LoadedPlugin {
    std::string id;
    std::string path;
    PluginState state;
    std::unique_ptr<IPlugin> instance;
#ifdef _WIN32
    HMODULE handle = nullptr;
#else
    void* handle = nullptr;
#endif
    std::map<std::string, double> metrics;
    uint64_t load_time;
    uint64_t message_count;
};

// ============================================================================
// 插件管理器
// ============================================================================

class PluginManager {
public:
    explicit PluginManager(const PluginManagerConfig& config = {});
    ~PluginManager();
    
    // 初始化
    bool initialize(bus::DataBus* bus);
    
    // 插件发现
    std::vector<std::string> discoverPlugins(const std::string& directory = "");
    
    // 插件加载
    bool loadPlugin(const std::string& path);
    bool loadPluginById(const std::string& plugin_id);
    
    // 插件卸载
    bool unloadPlugin(const std::string& plugin_id);
    bool unloadAll();
    
    // 插件生命周期
    bool startPlugin(const std::string& plugin_id);
    bool stopPlugin(const std::string& plugin_id);
    bool pausePlugin(const std::string& plugin_id);
    bool resumePlugin(const std::string& plugin_id);
    
    // 插件查询
    bool hasPlugin(const std::string& plugin_id) const;
    LoadedPlugin* getPlugin(const std::string& plugin_id);
    std::vector<PluginMetadata> getPluginMetadata() const;
    std::vector<std::string> getPluginIds() const;
    
    // 插件处理
    bus::Message processMessage(const std::string& plugin_id, const bus::Message& msg);
    void broadcastToPlugins(const bus::Message& msg);
    
    // 健康检查
    bool healthCheck(const std::string& plugin_id) const;
    std::map<std::string, bool> healthCheckAll() const;
    
    // 指标
    std::map<std::string, double> getPluginMetrics(const std::string& plugin_id) const;
    std::map<std::string, std::map<std::string, double>> getAllMetrics() const;
    
    // 状态
    size_t getPluginCount() const;
    bool isInitialized() const { return initialized_; }
    
private:
    // 内部方法
    bool loadDynamicLibrary(const std::string& path, LoadedPlugin& plugin);
    void unloadDynamicLibrary(LoadedPlugin& plugin);
    std::unique_ptr<IPlugin> createPluginInstance(const std::string& type, const std::string& id);
    void log(const std::string& message);
    void logError(const std::string& message);
    
private:
    PluginManagerConfig config_;
    bus::DataBus* bus_ = nullptr;
    bool initialized_ = false;
    
    mutable std::mutex plugins_mutex_;
    std::map<std::string, std::unique_ptr<LoadedPlugin>> plugins_;
    std::map<std::string, std::string> type_to_id_map_;  // type:id -> plugin_id
};

// ============================================================================
// PluginManager实现
// ============================================================================

PluginManager::PluginManager(const PluginManagerConfig& config)
    : config_(config) {
    log("PluginManager created");
}

PluginManager::~PluginManager() {
    unloadAll();
    log("PluginManager destroyed");
}

bool PluginManager::initialize(bus::DataBus* bus) {
    if (initialized_) {
        return true;
    }
    
    if (!bus) {
        logError("DataBus is null");
        return false;
    }
    
    bus_ = bus;
    initialized_ = true;
    
    log("PluginManager initialized");
    
    // 自动发现并加载插件
    if (config_.auto_load) {
        auto discovered = discoverPlugins();
        for (const auto& path : discovered) {
            loadPlugin(path);
        }
    }
    
    return true;
}

std::vector<std::string> PluginManager::discoverPlugins(const std::string& directory) {
    std::vector<std::string> result;
    
    std::string search_dir = directory.empty() ? config_.plugin_dir : directory;
    
    if (!fs::exists(search_dir)) {
        log("Plugin directory does not exist: " + search_dir);
        return result;
    }
    
#ifdef _WIN32
    std::string ext = ".dll";
#else
    std::string ext = ".so";
#endif
    
    for (const auto& entry : fs::directory_iterator(search_dir)) {
        if (entry.is_regular_file()) {
            std::string path = entry.path().string();
            if (path.size() > ext.size() && 
                path.substr(path.size() - ext.size()) == ext) {
                result.push_back(path);
            }
        }
    }
    
    log("Discovered " + std::to_string(result.size()) + " plugins in " + search_dir);
    return result;
}

bool PluginManager::loadPlugin(const std::string& path) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    if (plugins_.size() >= static_cast<size_t>(config_.max_plugins)) {
        logError("Maximum plugin count reached");
        return false;
    }
    
    log("Loading plugin from: " + path);
    
    auto plugin = std::make_unique<LoadedPlugin>();
    plugin->path = path;
    plugin->state = PluginState::UNINITIALIZED;
    plugin->load_time = bus::Message::currentTimestamp();
    plugin->message_count = 0;
    
    // 加载动态库
    if (!loadDynamicLibrary(path, *plugin)) {
        logError("Failed to load dynamic library: " + path);
        return false;
    }
    
    // 创建插件实例（这里使用工厂方法）
    // 实际实现中应该从动态库获取创建函数
    std::string plugin_type = "filter";  // 从配置文件读取
    std::string plugin_id = fs::path(path).stem().string();
    
    auto instance = createPluginInstance(plugin_type, plugin_id);
    if (!instance) {
        logError("Failed to create plugin instance: " + plugin_id);
        unloadDynamicLibrary(*plugin);
        return false;
    }
    
    plugin->instance = std::move(instance);
    plugin->id = plugin_id;
    
    // 初始化插件
    PluginContext context;
    context.bus = bus_;
    context.log = [this](const std::string& msg) { log(msg); };
    context.error = [this](const std::string& msg) { logError(msg); };
    
    if (!plugin->instance->initialize(context)) {
        logError("Failed to initialize plugin: " + plugin_id);
        unloadDynamicLibrary(*plugin);
        return false;
    }
    
    plugin->state = PluginState::INITIALIZING;
    
    // 获取元数据
    auto metadata = plugin->instance->getMetadata();
    plugin->id = metadata.id;
    
    plugins_[plugin->id] = std::move(plugin);
    type_to_id_map_[metadata.type + ":" + metadata.id] = plugin->id;
    
    log("Plugin loaded: " + plugin_id);
    return true;
}

bool PluginManager::loadPluginById(const std::string& plugin_id) {
    std::string path = config_.plugin_dir + "/" + plugin_id;
#ifdef _WIN32
    path += ".dll";
#else
    path += ".so";
#endif
    return loadPlugin(path);
}

bool PluginManager::unloadPlugin(const std::string& plugin_id) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    if (!config_.allow_unload) {
        logError("Plugin unloading is disabled");
        return false;
    }
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end()) {
        logError("Plugin not found: " + plugin_id);
        return false;
    }
    
    auto& plugin = it->second;
    
    // 停止插件
    if (plugin->state == PluginState::RUNNING) {
        plugin->instance->stop();
    }
    
    // 卸载动态库
    unloadDynamicLibrary(*plugin);
    
    // 移除映射
    auto metadata = plugin->instance->getMetadata();
    type_to_id_map_.erase(metadata.type + ":" + metadata.id);
    
    plugins_.erase(it);
    
    log("Plugin unloaded: " + plugin_id);
    return true;
}

bool PluginManager::unloadAll() {
    std::vector<std::string> ids;
    {
        std::lock_guard<std::mutex> lock(plugins_mutex_);
        for (const auto& [id, _] : plugins_) {
            ids.push_back(id);
        }
    }
    
    for (const auto& id : ids) {
        unloadPlugin(id);
    }
    
    return true;
}

bool PluginManager::startPlugin(const std::string& plugin_id) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end()) {
        return false;
    }
    
    auto& plugin = it->second;
    
    if (plugin->instance->start()) {
        plugin->state = PluginState::RUNNING;
        log("Plugin started: " + plugin_id);
        return true;
    }
    
    plugin->state = PluginState::ERROR;
    return false;
}

bool PluginManager::stopPlugin(const std::string& plugin_id) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end()) {
        return false;
    }
    
    auto& plugin = it->second;
    
    if (plugin->instance->stop()) {
        plugin->state = PluginState::STOPPED;
        log("Plugin stopped: " + plugin_id);
        return true;
    }
    
    return false;
}

bool PluginManager::pausePlugin(const std::string& plugin_id) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end()) {
        return false;
    }
    
    auto& plugin = it->second;
    
    if (plugin->instance->pause()) {
        plugin->state = PluginState::PAUSED;
        log("Plugin paused: " + plugin_id);
        return true;
    }
    
    return false;
}

bool PluginManager::resumePlugin(const std::string& plugin_id) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end()) {
        return false;
    }
    
    auto& plugin = it->second;
    
    if (plugin->instance->resume()) {
        plugin->state = PluginState::RUNNING;
        log("Plugin resumed: " + plugin_id);
        return true;
    }
    
    return false;
}

bool PluginManager::hasPlugin(const std::string& plugin_id) const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    return plugins_.find(plugin_id) != plugins_.end();
}

LoadedPlugin* PluginManager::getPlugin(const std::string& plugin_id) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it != plugins_.end()) {
        return it->second.get();
    }
    return nullptr;
}

std::vector<PluginMetadata> PluginManager::getPluginMetadata() const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    std::vector<PluginMetadata> result;
    for (const auto& [id, plugin] : plugins_) {
        if (plugin->instance) {
            result.push_back(plugin->instance->getMetadata());
        }
    }
    return result;
}

std::vector<std::string> PluginManager::getPluginIds() const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    std::vector<std::string> result;
    for (const auto& [id, _] : plugins_) {
        result.push_back(id);
    }
    return result;
}

bus::Message PluginManager::processMessage(const std::string& plugin_id, const bus::Message& msg) {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end() || !it->second->instance) {
        return msg;
    }
    
    auto& plugin = it->second;
    
    if (plugin->state != PluginState::RUNNING) {
        return msg;
    }
    
    plugin->message_count++;
    
    try {
        return plugin->instance->process(msg);
    } catch (const std::exception& e) {
        logError("Plugin process error: " + std::string(e.what()));
        plugin->state = PluginState::ERROR;
        return msg;
    }
}

void PluginManager::broadcastToPlugins(const bus::Message& msg) {
    std::vector<std::string> ids = getPluginIds();
    
    for (const auto& id : ids) {
        processMessage(id, msg);
    }
}

bool PluginManager::healthCheck(const std::string& plugin_id) const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end() || !it->second->instance) {
        return false;
    }
    
    return it->second->instance->healthCheck();
}

std::map<std::string, bool> PluginManager::healthCheckAll() const {
    std::map<std::string, bool> result;
    
    std::vector<std::string> ids;
    {
        std::lock_guard<std::mutex> lock(plugins_mutex_);
        for (const auto& [id, _] : plugins_) {
            ids.push_back(id);
        }
    }
    
    for (const auto& id : ids) {
        result[id] = healthCheck(id);
    }
    
    return result;
}

std::map<std::string, double> PluginManager::getPluginMetrics(const std::string& plugin_id) const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    auto it = plugins_.find(plugin_id);
    if (it == plugins_.end() || !it->second->instance) {
        return {};
    }
    
    return it->second->instance->getMetrics();
}

std::map<std::string, std::map<std::string, double>> PluginManager::getAllMetrics() const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    
    std::map<std::string, std::map<std::string, double>> result;
    
    for (const auto& [id, plugin] : plugins_) {
        if (plugin->instance) {
            result[id] = plugin->instance->getMetrics();
        }
    }
    
    return result;
}

size_t PluginManager::getPluginCount() const {
    std::lock_guard<std::mutex> lock(plugins_mutex_);
    return plugins_.size();
}

bool PluginManager::loadDynamicLibrary(const std::string& path, LoadedPlugin& plugin) {
#ifdef _WIN32
    HMODULE handle = LoadLibraryA(path.c_str());
    if (!handle) {
        logError("LoadLibrary failed: " + std::to_string(GetLastError()));
        return false;
    }
    plugin.handle = handle;
#else
    void* handle = dlopen(path.c_str(), RTLD_NOW | RTLD_LOCAL);
    if (!handle) {
        logError("dlopen failed: " + std::string(dlerror()));
        return false;
    }
    plugin.handle = handle;
#endif
    
    return true;
}

void PluginManager::unloadDynamicLibrary(LoadedPlugin& plugin) {
#ifdef _WIN32
    if (plugin.handle) {
        FreeLibrary(plugin.handle);
        plugin.handle = nullptr;
    }
#else
    if (plugin.handle) {
        dlclose(plugin.handle);
        plugin.handle = nullptr;
    }
#endif
}

std::unique_ptr<IPlugin> PluginManager::createPluginInstance(const std::string& type, const std::string& id) {
    // 使用工厂创建插件实例
    return PluginFactory::create(type, id);
}

void PluginManager::log(const std::string& message) {
    std::cout << "[PluginManager] " << message << std::endl;
}

void PluginManager::logError(const std::string& message) {
    std::cerr << "[PluginManager ERROR] " << message << std::endl;
}

// ============================================================================
// 示例插件实现
// ============================================================================

/**
 * @brief 示例过滤器插件
 */
class ExampleFilterPlugin : public IFilterPlugin {
public:
    bool initialize(const PluginContext& context) override {
        context_ = context;
        state_ = PluginState::INITIALIZING;
        context.log("ExampleFilterPlugin initialized");
        return true;
    }
    
    bool start() override {
        state_ = PluginState::RUNNING;
        return true;
    }
    
    bool stop() override {
        state_ = PluginState::STOPPED;
        return true;
    }
    
    bool pause() override {
        state_ = PluginState::PAUSED;
        return true;
    }
    
    bool resume() override {
        state_ = PluginState::RUNNING;
        return true;
    }
    
    PluginMetadata getMetadata() const override {
        return PluginMetadata{
            "example-filter",
            "Example Filter Plugin",
            "1.0.0",
            "PolyVault Team",
            "A simple filter plugin example",
            {"filter", "example"},
            "filter"
        };
    }
    
    PluginState getState() const override {
        return state_;
    }
    
    bool configure(const std::map<std::string, std::string>& config) override {
        config_ = config;
        return true;
    }
    
    std::map<std::string, std::string> getConfig() const override {
        return config_;
    }
    
    bus::Message process(const bus::Message& input) override {
        if (filter(input)) {
            return input;
        }
        return bus::Message{};  // 被过滤掉
    }
    
    bool healthCheck() const override {
        return state_ == PluginState::RUNNING;
    }
    
    std::map<std::string, double> getMetrics() const override {
        return {
            {"messages_processed", static_cast<double>(messages_processed_)},
            {"messages_passed", static_cast<double>(messages_passed_)}
        };
    }
    
    void addCondition(const FilterCondition& condition) override {
        conditions_.push_back(condition);
    }
    
    void clearConditions() override {
        conditions_.clear();
    }
    
    std::vector<FilterCondition> getConditions() const override {
        return conditions_;
    }
    
    bool filter(const bus::Message& message) override {
        messages_processed_++;
        
        // 简单过滤逻辑
        for (const auto& cond : conditions_) {
            if (cond.field == "topic" && cond.op == "contains") {
                if (message.topic.find(cond.value) == std::string::npos) {
                    return false;
                }
            }
        }
        
        messages_passed_++;
        return true;
    }
    
private:
    PluginContext context_;
    PluginState state_ = PluginState::UNINITIALIZED;
    std::map<std::string, std::string> config_;
    std::vector<FilterCondition> conditions_;
    uint64_t messages_processed_ = 0;
    uint64_t messages_passed_ = 0;
};

// 注册示例插件
POLYVAULT_REGISTER_PLUGIN(filter, example-filter, ExampleFilterPlugin);

} // namespace plugin
} // namespace polyvault