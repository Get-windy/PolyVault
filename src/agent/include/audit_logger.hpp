/**
 * @file audit_logger.hpp
 * @brief 安全审计日志系统
 * 
 * 功能：
 * - 事件记录
 * - 日志存储
 * - 日志查询
 * - 合规报告
 */

#pragma once

#include <string>
#include <vector>
#include <memory>
#include <mutex>
#include <map>
#include <functional>
#include <chrono>
#include <fstream>
#include <sstream>

namespace polyvault {
namespace security {

// ============================================================================
// 类型定义
// ============================================================================

/**
 * @brief 审计级别
 */
enum class AuditLevel : uint8_t {
    DEBUG = 0,
    INFO = 1,
    WARNING = 2,
    ERROR = 3,
    CRITICAL = 4
};

/**
 * @brief 审计事件类型
 */
enum class AuditEventType : uint16_t {
    // 认证事件 (1000-1099)
    AUTH_LOGIN = 1001,
    AUTH_LOGOUT = 1002,
    AUTH_FAILED = 1003,
    AUTH_LOCKOUT = 1004,
    
    // 凭证事件 (2000-2099)
    CREDENTIAL_CREATE = 2001,
    CREDENTIAL_ACCESS = 2002,
    CREDENTIAL_UPDATE = 2003,
    CREDENTIAL_DELETE = 2004,
    CREDENTIAL_EXPORT = 2005,
    
    // 密钥事件 (3000-3099)
    KEY_GENERATE = 3001,
    KEY_ACCESS = 3002,
    KEY_ROTATE = 3003,
    KEY_REVOKE = 3004,
    KEY_DELETE = 3005,
    KEY_EXPIRED = 3006,
    
    // 签名事件 (4000-4099)
    SIGN_CREATE = 4001,
    SIGN_VERIFY = 4002,
    SIGN_VERIFY_FAILED = 4003,
    
    //  vault事件 (5000-5099)
    VAULT_UNLOCK = 5001,
    VAULT_LOCK = 5002,
    VAULT_ACCESS = 5003,
    VAULT_ERROR = 5004,
    
    // 系统事件 (9000-9099)
    SYSTEM_START = 9001,
    SYSTEM_STOP = 9002,
    CONFIG_CHANGE = 9003,
    SECURITY_ALERT = 9004
};

/**
 * @brief 审计记录
 */
struct AuditRecord {
    uint64_t timestamp;                     // 时间戳 (毫秒)
    AuditEventType event_type;              // 事件类型
    AuditLevel level;                       // 审计级别
    std::string actor;                       // 参与者
    std::string target;                     // 目标
    std::string action;                     // 动作
    std::string result;                     // 结果 (success/failure)
    std::map<std::string, std::string> details;  // 详情
    std::string source_ip;                  // 源IP
    std::string user_agent;                 // 用户代理
    std::string session_id;                 // 会话ID
};

// ============================================================================
// 审计日志配置
// ============================================================================

/**
 * @brief 审计日志配置
 */
struct AuditConfig {
    std::string log_path = "./logs";        // 日志目录
    std::string log_prefix = "audit";       // 日志前缀
    uint32_t max_file_size_mb = 100;        // 最大文件大小
    uint32_t max_file_count = 10;           // 最大文件数
    bool enable_console = true;              // 输出到控制台
    bool enable_file = true;                // 输出到文件
    bool enable_remote = false;             // 远程发送
    std::string remote_endpoint;             // 远程端点
    AuditLevel min_level = AuditLevel::INFO; // 最低审计级别
    uint32_t retention_days = 365;          // 保留天数
};

// ============================================================================
// 审计日志器
// ============================================================================

/**
 * @brief 安全审计日志器
 * 
 * 特性：
 * - 实时记录安全相关事件
 * - 多级别日志
 * - 日志轮转
 * - 结构化日志格式
 * - 可配置的存储后端
 */
class AuditLogger {
public:
    explicit AuditLogger(const AuditConfig& config = {});
    ~AuditLogger();
    
    // 生命周期
    bool initialize();
    void shutdown();
    bool isInitialized() const { return initialized_; }
    
    // 日志记录
    void log(AuditEventType event_type, 
            AuditLevel level,
            const std::string& actor,
            const std::string& action,
            const std::string& result,
            const std::map<std::string, std::string>& details = {});
    
    // 便捷方法
    void auth(const std::string& actor, const std::string& action, 
             bool success, const std::string& details = "");
    
    void credential(const std::string& actor, const std::string& service,
                   const std::string& action, bool success);
    
    void key(const std::string& actor, const std::string& key_id,
            const std::string& action, bool success);
    
    void vault(const std::string& actor, const std::string& action,
              bool success, const std::string& details = "");
    
    void security(const std::string& message, 
                 const std::map<std::string, std::string>& details = {});
    
    // 查询
    std::vector<AuditRecord> query(
        AuditEventType event_type = AuditEventType::SYSTEM_START,
        const std::string& actor = "",
        uint64_t start_time = 0,
        uint64_t end_time = 0,
        size_t limit = 100);
    
    std::vector<AuditRecord> getRecent(size_t count = 10);
    
    // 统计
    struct Statistics {
        uint64_t total_records;
        uint64_t auth_events;
        uint64_t credential_events;
        uint64_t key_events;
        uint64_t security_events;
        uint64_t errors;
    };
    
    Statistics getStatistics();
    
    // 配置
    void setLevel(AuditLevel level);
    void setRemoteEndpoint(const std::string& endpoint);
    void setCallback(std::function<void(const AuditRecord&)> callback);
    
    // 导出
    bool exportToJson(const std::string& filepath, 
                     uint64_t start_time = 0,
                     uint64_t end_time = 0);
    
    bool exportToCsv(const std::string& filepath,
                     uint64_t start_time = 0,
                     uint64_t end_time = 0);
    
    // 清理
    void cleanup();
    
private:
    AuditConfig config_;
    bool initialized_ = false;
    bool running_ = false;
    
    // 存储
    std::mutex records_mutex_;
    std::vector<AuditRecord> records_;
    size_t max_records_in_memory_ = 10000;
    
    // 文件输出
    std::ofstream log_file_;
    uint64_t current_file_size_ = 0;
    uint32_t current_file_index_ = 0;
    
    // 统计
    std::mutex stats_mutex_;
    Statistics statistics_;
    
    // 回调
    std::function<void(const AuditRecord&)> record_callback_;
    
    // 内部方法
    bool openLogFile();
    void rotateLogFile();
    void writeRecord(const AuditRecord& record);
    std::string formatRecord(const AuditRecord& record);
    std::string levelToString(AuditLevel level);
    std::string eventToString(AuditEventType event);
    uint64_t getCurrentTimestamp();
    void updateStatistics(const AuditRecord& record);
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建AuditLogger实例
 */
std::unique_ptr<AuditLogger> createAuditLogger(const AuditConfig& config = {});

/**
 * @brief 获取全局审计日志器实例
 */
AuditLogger& getGlobalAuditLogger();

/**
 * @brief 设置全局审计日志器
 */
void setGlobalAuditLogger(std::unique_ptr<AuditLogger> logger);

/**
 * @brief 格式化审计记录为JSON
 */
std::string auditRecordToJson(const AuditRecord& record);

/**
 * @brief 格式化审计记录为CSV行
 */
std::string auditRecordToCsv(const AuditRecord& record);

/**
 * @brief 解析审计级别
 */
AuditLevel parseAuditLevel(const std::string& level);

/**
 * @brief 解析事件类型
 */
AuditEventType parseAuditEventType(const std::string& type);

} // namespace security
} // namespace polyvault