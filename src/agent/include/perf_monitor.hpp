/**
 * @file perf_monitor.hpp
 * @brief 性能监控模块
 * 
 * 功能：
 * - 性能指标收集
 * - 延迟统计
 * - 吞吐量监控
 * - 资源使用跟踪
 */

#pragma once

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <map>
#include <chrono>
#include <atomic>
#include <functional>

namespace polyvault {
namespace monitoring {

// ============================================================================
// 类型定义
// ============================================================================

/**
 * @brief 性能指标类型
 */
enum class MetricType {
    COUNTER,          // 计数器
    GAUGE,           // 仪表值
    HISTOGRAM,       // 直方图
    TIMER            // 计时器
};

/**
 * @brief 指标数据
 */
struct MetricData {
    std::string name;
    MetricType type;
    double value;
    uint64_t timestamp;
    std::map<std::string, std::string> labels;
};

/**
 * @brief 统计摘要
 */
struct StatSummary {
    double min;
    double max;
    double mean;
    double p50;      // 中位数
    double p90;
    double p95;
    double p99;
    uint64_t count;
    uint64_t sum;
};

/**
 * @brief 性能配置
// ============================================================================
 */
struct PerfConfig {
    std::string metrics_endpoint = "/metrics";  // 指标端点
    uint32_t collection_interval_ms = 1000;     // 收集间隔
    uint32_t retention_seconds = 3600;          // 保留时间
    bool enable_prometheus = false;             // Prometheus导出
    bool enable_logging = true;                 // 日志输出
};

/**
 * @brief 性能监控器
 */
class PerfMonitor {
public:
    explicit PerfMonitor(const PerfConfig& config = {});
    ~PerfMonitor();
    
    // 生命周期
    bool initialize();
    void shutdown();
    
    // 计数器
    void incrementCounter(const std::string& name, double value = 1.0,
                         const std::map<std::string, std::string>& labels = {});
    
    // 仪表值
    void setGauge(const std::string& name, double value,
                 const std::map<std::string, std::string>& labels = {});
    
    // 直方图
    void observeHistogram(const std::string& name, double value,
                         const std::map<std::string, std::string>& labels = {});
    
    // 计时器 (自动)
    class Timer {
    public:
        Timer(PerfMonitor& monitor, const std::string& name,
              const std::map<std::string, std::string>& labels = {});
        ~Timer();
    private:
        PerfMonitor& monitor_;
        std::string name_;
        std::map<std::string, std::string> labels_;
        std::chrono::high_resolution_clock::time_point start_;
    };
    
    // 计时器 (手动)
    void recordTiming(const std::string& name, uint64_t duration_ms,
                     const std::map<std::string, std::string>& labels = {});
    
    // 统计查询
    std::optional<double> getCounter(const std::string& name);
    std::optional<double> getGauge(const std::string& name);
    std::optional<StatSummary> getHistogramStats(const std::string& name);
    
    // 指标导出
    std::string toPrometheusFormat();
    std::vector<MetricData> getAllMetrics();
    
    // 报告
    void printSummary();
    void exportToLog();
    
private:
    PerfConfig config_;
    bool initialized_ = false;
    bool running_ = false;
    
    // 存储
    std::mutex mutex_;
    std::map<std::string, std::atomic<uint64_t>> counters_;
    std::map<std::string, std::atomic<double>> gauges_;
    std::map<std::string, std::vector<double>> histogram_values_;
    
    // 线程
    std::thread collection_thread_;
    std::atomic<bool> collection_running_{false};
    
    // 内部方法
    void collectionLoop();
    StatSummary calculateSummary(const std::vector<double>& values);
    std::string generatePrometheusMetric(const std::string& name, double value,
                                         const std::map<std::string, std::string>& labels);
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建PerfMonitor实例
 */
std::unique_ptr<PerfMonitor> createPerfMonitor(const PerfConfig& config = {});

/**
 * @brief 获取全局监控器
 */
PerfMonitor& getGlobalPerfMonitor();

/**
 * @brief 设置全局监控器
 */
void setGlobalPerfMonitor(std::unique_ptr<PerfMonitor> monitor);

/**
 * @brief 性能追踪装饰器
 */
template<typename Func, typename... Args>
auto traceFunction(PerfMonitor& monitor, const std::string& name, 
                   Func&& func, Args&&... args) 
    -> decltype(func(args...)) 
{
    auto start = std::chrono::high_resolution_clock::now();
    auto result = func(std::forward<Args>(args)...);
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    monitor.recordTiming(name, duration.count());
    return result;
}

} // namespace monitoring
} // namespace polyvault