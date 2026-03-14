/**
 * @file perf_monitor.cpp
 * @brief 性能监控实现
 */

#include "perf_monitor.hpp"
#include <algorithm>
#include <numeric>
#include <sstream>
#include <iostream>
#include <cmath>

namespace polyvault {
namespace monitoring {

// ============================================================================
// Timer实现
// ============================================================================

PerfMonitor::Timer::Timer(PerfMonitor& monitor, const std::string& name,
                          const std::map<std::string, std::string>& labels)
    : monitor_(monitor), name_(name), labels_(labels) {
    start_ = std::chrono::high_resolution_clock::now();
}

PerfMonitor::Timer::~Timer() {
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start_);
    monitor_.recordTiming(name_, duration.count(), labels_);
}

// ============================================================================
// PerfMonitor实现
// ============================================================================

PerfMonitor::PerfMonitor(const PerfConfig& config) : config_(config) {}
PerfMonitor::~PerfMonitor() {
    shutdown();
}

bool PerfMonitor::initialize() {
    if (initialized_) {
        return true;
    }
    
    std::cout << "[Perf] Initializing performance monitor" << std::endl;
    initialized_ = true;
    
    if (config_.collection_interval_ms > 0) {
        running_ = true;
        collection_thread_ = std::thread(&PerfMonitor::collectionLoop, this);
    }
    
    return true;
}

void PerfMonitor::shutdown() {
    if (!running_) {
        return;
    }
    
    running_ = false;
    collection_running_ = false;
    
    if (collection_thread_.joinable()) {
        collection_thread_.join();
    }
}

void PerfMonitor::incrementCounter(const std::string& name, double value,
                                   const std::map<std::string, std::string>& labels) {
    std::lock_guard<std::mutex> lock(mutex_);
    counters_[name].fetch_add(static_cast<uint64_t>(value));
}

void PerfMonitor::setGauge(const std::string& name, double value,
                           const std::map<std::string, std::string>& labels) {
    std::lock_guard<std::mutex> lock(mutex_);
    gauges_[name].store(value);
}

void PerfMonitor::observeHistogram(const std::string& name, double value,
                                  const std::map<std::string, std::string>& labels) {
    std::lock_guard<std::mutex> lock(mutex_);
    histogram_values_[name].push_back(value);
}

void PerfMonitor::recordTiming(const std::string& name, uint64_t duration_ms,
                               const std::map<std::string, std::string>& labels) {
    std::lock_guard<std::mutex> lock(mutex_);
    histogram_values_[name].push_back(static_cast<double>(duration_ms));
}

std::optional<double> PerfMonitor::getCounter(const std::string& name) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = counters_.find(name);
    if (it != counters_.end()) {
        return static_cast<double>(it->second.load());
    }
    return std::nullopt;
}

std::optional<double> PerfMonitor::getGauge(const std::string& name) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = gauges_.find(name);
    if (it != gauges_.end()) {
        return it->second.load();
    }
    return std::nullopt;
}

std::optional<StatSummary> PerfMonitor::getHistogramStats(const std::string& name) {
    std::lock_guard<std::mutex> lock(mutex_);
    auto it = histogram_values_.find(name);
    if (it != histogram_values_.end() && !it->second.empty()) {
        return calculateSummary(it->second);
    }
    return std::nullopt;
}

StatSummary PerfMonitor::calculateSummary(const std::vector<double>& values) {
    StatSummary summary;
    
    if (values.empty()) {
        return summary;
    }
    
    std::vector<double> sorted = values;
    std::sort(sorted.begin(), sorted.end());
    
    summary.min = sorted.front();
    summary.max = sorted.back();
    summary.sum = std::accumulate(sorted.begin(), sorted.end(), 0.0);
    summary.mean = summary.sum / sorted.size();
    summary.count = sorted.size();
    
    // 计算百分位数
    auto percentile = [&sorted](double p) -> double {
        if (sorted.empty()) return 0;
        double idx = p * (sorted.size() - 1);
        size_t lower = static_cast<size_t>(std::floor(idx));
        size_t upper = static_cast<size_t>(std::ceil(idx));
        if (lower == upper) return sorted[lower];
        return sorted[lower] * (upper - idx) + sorted[upper] * (idx - lower);
    };
    
    summary.p50 = percentile(0.50);
    summary.p90 = percentile(0.90);
    summary.p95 = percentile(0.95);
    summary.p99 = percentile(0.99);
    
    return summary;
}

std::string PerfMonitor::toPrometheusFormat() {
    std::lock_guard<std::mutex> lock(mutex_);
    std::ostringstream oss;
    
    // 计数器
    for (const auto& [name, counter] : counters_) {
        oss << "# TYPE " << name << " counter\n";
        oss << name << " " << counter.load() << "\n\n";
    }
    
    // 仪表
    for (const auto& [name, gauge] : gauges_) {
        oss << "# TYPE " << name << " gauge\n";
        oss << name << " " << gauge.load() << "\n\n";
    }
    
    // 直方图
    for (const auto& [name, values] : histogram_values_) {
        if (values.empty()) continue;
        
        StatSummary summary = calculateSummary(values);
        
        oss << "# TYPE " << name << "_sum gauge\n";
        oss << name << "_sum " << summary.sum << "\n";
        oss << "# TYPE " << name << "_count counter\n";
        oss << name << "_count " << summary.count << "\n\n";
    }
    
    return oss.str();
}

std::vector<polyvault::monitoring::MetricData> PerfMonitor::getAllMetrics() {
    std::lock_guard<std::mutex> lock(mutex_);
    std::vector<polyvault::monitoring::MetricData> metrics;
    
    for (const auto& [name, counter] : counters_) {
        polyvault::monitoring::MetricData m;
        m.name = name;
        m.type = polyvault::monitoring::MetricType::COUNTER;
        m.value = static_cast<double>(counter.load());
        m.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
        metrics.push_back(m);
    }
    
    for (const auto& [name, gauge] : gauges_) {
        polyvault::monitoring::MetricData m;
        m.name = name;
        m.type = polyvault::monitoring::MetricType::GAUGE;
        m.value = gauge.load();
        m.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count();
        metrics.push_back(m);
    }
    
    return metrics;
}

void PerfMonitor::printSummary() {
    std::cout << "\n=== Performance Summary ===" << std::endl;
    
    std::cout << "\nCounters:" << std::endl;
    for (const auto& [name, counter] : counters_) {
        std::cout << "  " << name << ": " << counter.load() << std::endl;
    }
    
    std::cout << "\nGauges:" << std::endl;
    for (const auto& [name, gauge] : gauges_) {
        std::cout << "  " << name << ": " << gauge.load() << std::endl;
    }
    
    std::cout << "\nHistograms:" << std::endl;
    for (const auto& [name, values] : histogram_values_) {
        if (values.empty()) continue;
        auto summary = calculateSummary(values);
        std::cout << "  " << name << " (n=" << summary.count << "):" << std::endl;
        std::cout << "    min=" << summary.min << " max=" << summary.max 
                  << " mean=" << summary.mean << std::endl;
        std::cout << "    p50=" << summary.p50 << " p90=" << summary.p90 
                  << " p95=" << summary.p95 << " p99=" << summary.p99 << std::endl;
    }
}

void PerfMonitor::exportToLog() {
    auto metrics = getAllMetrics();
    for (const auto& m : metrics) {
        std::cout << "[METRIC] " << m.name << "=" << m.value 
                  << " type=" << static_cast<int>(m.type) << std::endl;
    }
}

void PerfMonitor::collectionLoop() {
    collection_running_ = true;
    
    while (collection_running_ && running_) {
        std::this_thread::sleep_for(std::chrono::milliseconds(config_.collection_interval_ms));
        
        if (config_.enable_prometheus && config_.enable_logging) {
            std::cout << toPrometheusFormat() << std::endl;
        }
    }
}

std::string PerfMonitor::generatePrometheusMetric(const std::string& name, double value,
                                                   const std::map<std::string, std::string>& labels) {
    std::ostringstream oss;
    oss << name;
    
    if (!labels.empty()) {
        oss << "{";
        bool first = true;
        for (const auto& [k, v] : labels) {
            if (!first) oss << ",";
            oss << k << "=\"" << v << "\"";
            first = false;
        }
        oss << "}";
    }
    
    oss << " " << value;
    return oss.str();
}

// ============================================================================
// 便捷函数
// ============================================================================

std::unique_ptr<PerfMonitor> createPerfMonitor(const PerfConfig& config) {
    return std::make_unique<PerfMonitor>(config);
}

static std::unique_ptr<PerfMonitor> g_global_monitor;

PerfMonitor& getGlobalPerfMonitor() {
    if (!g_global_monitor) {
        g_global_monitor = createPerfMonitor();
    }
    return *g_global_monitor;
}

void setGlobalPerfMonitor(std::unique_ptr<PerfMonitor> monitor) {
    g_global_monitor = std::move(monitor);
}

} // namespace monitoring
} // namespace polyvault