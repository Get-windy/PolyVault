// eCAL通信监控（C++ Agent端）
#pragma once

#include <chrono>
#include <map>
#include <string>
#include <mutex>
#include <ecal/ecal.h>

namespace polyvault {
namespace monitoring {

struct MessageStats {
    uint64_t count = 0;
    uint64_t bytes = 0;
    double avg_latency_ms = 0;
    double max_latency_ms = 0;
    uint64_t errors = 0;
};

class EcalMonitor {
public:
    static EcalMonitor& instance() {
        static EcalMonitor inst;
        return inst;
    }

    void recordSend(const std::string& topic, size_t bytes, double latency_ms) {
        std::lock_guard<std::mutex> lock(mutex_);
        auto& stats = send_stats_[topic];
        stats.count++;
        stats.bytes += bytes;
        stats.avg_latency_ms = (stats.avg_latency_ms * (stats.count - 1) + latency_ms) / stats.count;
        stats.max_latency_ms = std::max(stats.max_latency_ms, latency_ms);
    }

    void recordReceive(const std::string& topic, size_t bytes) {
        std::lock_guard<std::mutex> lock(mutex_);
        auto& stats = recv_stats_[topic];
        stats.count++;
        stats.bytes += bytes;
    }

    void recordError(const std::string& topic) {
        std::lock_guard<std::mutex> lock(mutex_);
        send_stats_[topic].errors++;
    }

    std::map<std::string, MessageStats> getSendStats() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return send_stats_;
    }

    std::map<std::string, MessageStats> getRecvStats() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return recv_stats_;
    }

    void reset() {
        std::lock_guard<std::mutex> lock(mutex_);
        send_stats_.clear();
        recv_stats_.clear();
    }

private:
    EcalMonitor() = default;
    mutable std::mutex mutex_;
    std::map<std::string, MessageStats> send_stats_;
    std::map<std::string, MessageStats> recv_stats_;
};

// 性能计时器
class ScopedTimer {
public:
    ScopedTimer(const std::string& name) 
        : name_(name), start_(std::chrono::high_resolution_clock::now()) {}
    
    ~ScopedTimer() {
        auto end = std::chrono::high_resolution_clock::now();
        auto ms = std::chrono::duration<double, std::milli>(end - start_).count();
        EcalMonitor::instance().recordSend(name_, 0, ms);
    }

private:
    std::string name_;
    std::chrono::time_point<std::chrono::high_resolution_clock> start_;
};

} // namespace monitoring
} // namespace polyvault