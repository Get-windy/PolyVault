/**
 * @file audit_logger.cpp
 * @brief 审计日志实现
 */

#include "audit_logger.hpp"
#include <iostream>
#include <sstream>
#include <iomanip>

namespace polyvault {
namespace security {

// ============================================================================
// AuditLogger实现
// ============================================================================

AuditLogger::AuditLogger(const std::string& logger_name) 
    : logger_name_(logger_name) {}

AuditLogger::~AuditLogger() = default;

bool AuditLogger::initialize() {
    std::cout << "[Audit] Initializing logger: " << logger_name_ << std::endl;
    initialized_ = true;
    return true;
}

void AuditLogger::logEvent(AuditEvent event, const std::string& user_id,
                           const std::string& resource,
                           const std::string& details) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    AuditRecord record;
    record.event = event;
    record.user_id = user_id;
    record.resource = resource;
    record.details = details;
    record.timestamp = std::chrono::system_clock::now().time_since_epoch().count();
    
    events_.push_back(record);
}

std::vector<AuditRecord> AuditLogger::queryEvents(AuditEvent event) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<AuditRecord> result;
    for (const auto& e : events_) {
        if (e.event == event) {
            result.push_back(e);
        }
    }
    return result;
}

std::vector<AuditRecord> AuditLogger::queryEventsByUser(const std::string& user_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<AuditRecord> result;
    for (const auto& e : events_) {
        if (e.user_id == user_id) {
            result.push_back(e);
        }
    }
    return result;
}

std::vector<AuditRecord> AuditLogger::queryEventsByTimeRange(int64_t start, int64_t end) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<AuditRecord> result;
    for (const auto& e : events_) {
        if (e.timestamp >= start && e.timestamp <= end) {
            result.push_back(e);
        }
    }
    return result;
}

bool AuditLogger::exportLogs(std::string& output, const std::string& format) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    if (format == "json") {
        output = "{\n  \"events\": [\n";
        for (size_t i = 0; i < events_.size(); i++) {
            const auto& e = events_[i];
            output += "    {\n";
            output += "      \"event\": \"" + std::to_string(static_cast<int>(e.event)) + "\",\n";
            output += "      \"user_id\": \"" + e.user_id + "\",\n";
            output += "      \"resource\": \"" + e.resource + "\",\n";
            output += "      \"timestamp\": " + std::to_string(e.timestamp) + "\n";
            output += "    }";
            if (i < events_.size() - 1) output += ",";
            output += "\n";
        }
        output += "  ]\n}\n";
    } else if (format == "csv") {
        output = "event,user_id,resource,timestamp,details\n";
        for (const auto& e : events_) {
            output += std::to_string(static_cast<int>(e.event)) + ",";
            output += e.user_id + ",";
            output += e.resource + ",";
            output += std::to_string(e.timestamp) + ",";
            output += e.details + "\n";
        }
    } else {
        return false;
    }
    
    return true;
}

void AuditLogger::clear() {
    std::lock_guard<std::mutex> lock(mutex_);
    events_.clear();
}

size_t AuditLogger::getEventCount() const {
    return events_.size();
}

std::unique_ptr<AuditLogger> createAuditLogger(const std::string& name) {
    return std::make_unique<AuditLogger>(name);
}

} // namespace security
} // namespace polyvault