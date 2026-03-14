/**
 * @file data_sync.hpp
 * @brief 数据同步模块 - 设备间数据同步
 * 
 * 功能：
 * - 增量同步
 * - 全量同步
 * - 冲突解决
 * - 离线同步
 */

#pragma once

#include <string>
#include <memory>
#include <mutex>
#include <map>
#include <atomic>
#include <functional>
#include <chrono>
#include <vector>
#include <optional>

#ifdef USE_ECAL
#include <ecal/ecal.h>
#endif

#include "openclaw.pb.h"

namespace polyvault {
namespace sync {

// ============================================================================
// 类型定义
// ============================================================================

/**
 * @brief 同步类型
 */
enum class SyncType : uint8_t {
    FULL = 1,           // 全量同步
    INCREMENTAL = 2,    // 增量同步
    BACKGROUND = 3      // 后台同步
};

/**
 * @brief 同步状态
 */
enum class SyncStatus : uint8_t {
    IDLE = 0,
    SYNCING = 1,
    COMPLETED = 2,
    FAILED = 3,
    CONFLICT = 4
};

/**
 * @brief 数据类型
 */
enum class DataType : uint8_t {
    CREDENTIAL = 1,
    COOKIE = 2,
    CONFIG = 3,
    DEVICE = 4
};

/**
 * @brief 同步项
 */
struct SyncItem {
    std::string item_id;
    DataType data_type;
    std::string device_id;
    uint64_t version;
    uint64_t timestamp;
    std::vector<uint8_t> data;
    bool deleted = false;
};

/**
 * @brief 同步冲突
 */
struct SyncConflict {
    std::string item_id;
    SyncItem local_version;
    SyncItem remote_version;
};

/**
 * @brief 同步进度
 */
struct SyncProgress {
    SyncStatus status;
    uint32_t total_items;
    uint32_t synced_items;
    uint32_t failed_items;
    std::string current_item;
    uint64_t start_time;
    uint64_t end_time;
    
    double percentComplete() const {
        if (total_items == 0) return 100.0;
        return (static_cast<double>(synced_items) / total_items) * 100.0;
    }
};

// ============================================================================
// 冲突解决策略
// ============================================================================

enum class ConflictResolution : uint8_t {
    LOCAL_WINS = 1,     // 本地版本优先
    REMOTE_WINS = 2,    // 远程版本优先
    LATEST_WINS = 3,    // 最新版本优先
    MANUAL = 4          // 手动解决
};

// ============================================================================
// 同步配置
// ============================================================================

/**
 * @brief 同步配置
 */
struct SyncConfig {
    std::string device_id;                    // 本设备ID
    std::string user_id;                       // 用户ID
    SyncType default_sync_type = SyncType::INCREMENTAL;
    ConflictResolution conflict_resolution = ConflictResolution::LATEST_WINS;
    uint32_t max_batch_size = 100;             // 每批最大同步数
    uint32_t retry_count = 3;                  // 重试次数
    uint32_t retry_delay_ms = 1000;            // 重试延迟
    uint32_t sync_interval_ms = 60000;         // 同步间隔(1分钟)
    bool auto_sync = true;                     // 自动同步
    bool encrypt_sync = true;                  // 加密同步
};

// ============================================================================
// 同步器
// ============================================================================

/**
 * @brief 数据同步器
 */
class DataSync {
public:
    explicit DataSync(const SyncConfig& config);
    ~DataSync();
    
    // 生命周期
    bool initialize();
    void start();
    void stop();
    bool isRunning() const { return running_; }
    
    // 同步操作
    bool triggerFullSync();
    bool triggerIncrementalSync();
    bool triggerSyncForDevice(const std::string& target_device_id);
    
    // 状态查询
    SyncStatus getStatus() const { return status_; }
    SyncProgress getProgress() const { return progress_; }
    std::vector<SyncConflict> getConflicts() const;
    
    // 冲突解决
    void setConflictResolution(ConflictResolution resolution);
    bool resolveConflict(const std::string& item_id, bool use_local);
    
    // 事件回调
    using SyncCallback = std::function<void(SyncProgress)>;
    using ConflictCallback = std::function<void(const SyncConflict&)>;
    using CompleteCallback = std::function<void(bool, const std::string&)>;
    
    void setSyncCallback(SyncCallback callback);
    void setConflictCallback(ConflictCallback callback);
    void setCompleteCallback(CompleteCallback callback);
    
    // 数据管理
    bool addLocalChange(const SyncItem& item);
    std::vector<SyncItem> getPendingChanges();
    bool applyRemoteChanges(const std::vector<SyncItem>& items);
    
    // 版本管理
    uint64_t getLocalVersion(const std::string& item_id);
    bool updateVersion(const std::string& item_id, uint64_t version);
    
private:
    SyncConfig config_;
    bool initialized_ = false;
    bool running_ = false;
    std::atomic<SyncStatus> status_{SyncStatus::IDLE};
    SyncProgress progress_;
    
    // 数据存储
    std::mutex data_mutex_;
    std::map<std::string, SyncItem> local_items_;       // 本地数据
    std::map<std::string, SyncItem> pending_items_;    // 待同步数据
    std::map<std::string, uint64_t> version_store_;    // 版本存储
    
    // 冲突存储
    std::mutex conflict_mutex_;
    std::vector<SyncConflict> conflicts_;
    
    // 线程
    std::thread sync_thread_;
    std::atomic<bool> trigger_sync_{false};
    
    // 回调
    SyncCallback sync_callback_;
    ConflictCallback conflict_callback_;
    CompleteCallback complete_callback_;
    
    // 内部方法
    void syncLoop();
    bool performSync(SyncType type);
    std::vector<SyncItem> prepareSyncBatch();
    bool applyChanges(const std::vector<SyncItem>& items);
    void handleConflict(const SyncItem& local, const SyncItem& remote);
    SyncItem resolve(const SyncItem& local, const SyncItem& remote);
    void notifyProgress();
    void notifyComplete(bool success, const std::string& message);
    uint64_t generateSyncId();
    std::string generateItemId();
};

// ============================================================================
// 设备同步管理器
// ============================================================================

/**
 * @brief 设备同步管理器
 */
class DeviceSyncManager {
public:
    DeviceSyncManager();
    ~DeviceSyncManager();
    
    bool initialize();
    
    // 设备管理
    bool registerDevice(const std::string& device_id, const std::string& endpoint);
    bool unregisterDevice(const std::string& device_id);
    std::vector<std::string> getRegisteredDevices();
    
    // 同步操作
    bool syncWithDevice(const std::string& device_id);
    bool syncWithAllDevices();
    
    // 状态
    std::map<std::string, SyncStatus> getDeviceSyncStatus() const;
    
private:
    std::mutex mutex_;
    std::map<std::string, std::string> devices_;  // device_id -> endpoint
    std::map<std::string, SyncStatus> device_status_;
    std::map<std::string, std::unique_ptr<DataSync>> syncers_;
    
    std::string local_device_id_;
};

// ============================================================================
// 便捷函数
// ============================================================================

/**
 * @brief 创建DataSync实例
 */
std::unique_ptr<DataSync> createDataSync(const SyncConfig& config);

/**
 * @brief 创建DeviceSyncManager实例
 */
std::unique_ptr<DeviceSyncManager> createDeviceSyncManager();

/**
 * @brief 创建SyncItem
 */
SyncItem createSyncItem(DataType type, const std::string& device_id, 
                        const std::vector<uint8_t>& data);

} // namespace sync
} // namespace polyvault