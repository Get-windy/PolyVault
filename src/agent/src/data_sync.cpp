/**
 * @file data_sync.cpp
 * @brief 数据同步实现
 */

#include "data_sync.hpp"
#include "ecal_communication.hpp"
#include "crypto_utils.hpp"
#include <iostream>
#include <algorithm>
#include <sstream>

namespace polyvault {
namespace sync {

// ============================================================================
// DataSync实现
// ============================================================================

DataSync::DataSync(const SyncConfig& config) : config_(config) {}

DataSync::~DataSync() {
    stop();
}

bool DataSync::initialize() {
    if (initialized_) {
        return true;
    }
    
    std::cout << "[Sync] Initializing data sync for device: " << config_.device_id << std::endl;
    
    // 初始化版本存储
    version_store_[config_.device_id] = 1;
    
    initialized_ = true;
    std::cout << "[Sync] Data sync initialized" << std::endl;
    return true;
}

void DataSync::start() {
    if (running_ || !initialized_) {
        return;
    }
    
    running_ = true;
    status_ = SyncStatus::IDLE;
    
    // 启动同步线程
    sync_thread_ = std::thread(&DataSync::syncLoop, this);
    
    std::cout << "[Sync] Data sync started" << std::endl;
}

void DataSync::stop() {
    if (!running_) {
        return;
    }
    
    running_ = false;
    
    if (sync_thread_.joinable()) {
        sync_thread_.join();
    }
    
    std::cout << "[Sync] Data sync stopped" << std::endl;
}

bool DataSync::triggerFullSync() {
    if (!running_) {
        return false;
    }
    
    std::cout << "[Sync] Triggering full sync" << std::endl;
    trigger_sync_ = true;
    return performSync(SyncType::FULL);
}

bool DataSync::triggerIncrementalSync() {
    if (!running_) {
        return false;
    }
    
    std::cout << "[Sync] Triggering incremental sync" << std::endl;
    trigger_sync_ = true;
    return performSync(SyncType::INCREMENTAL);
}

bool DataSync::triggerSyncForDevice(const std::string& target_device_id) {
    if (!running_) {
        return false;
    }
    
    std::cout << "[Sync] Syncing with device: " << target_device_id << std::endl;
    
    // 准备待同步数据
    auto batch = prepareSyncBatch();
    
    // 实际发送需要通过eCAL或网络
    // 简化实现
    progress_.total_items = static_cast<uint32_t>(batch.size());
    progress_.synced_items = 0;
    progress_.status = SyncStatus::SYNCING;
    
    // 模拟同步过程
    for (const auto& item : batch) {
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        progress_.synced_items++;
        notifyProgress();
    }
    
    progress_.status = SyncStatus::COMPLETED;
    notifyComplete(true, "Sync completed");
    
    return true;
}

std::vector<SyncConflict> DataSync::getConflicts() const {
    std::lock_guard<std::mutex> lock(conflict_mutex_);
    return conflicts_;
}

void DataSync::setConflictResolution(ConflictResolution resolution) {
    config_.conflict_resolution = resolution;
}

bool DataSync::resolveConflict(const std::string& item_id, bool use_local) {
    std::lock_guard<std::mutex> lock(conflict_mutex_);
    
    auto it = std::find_if(conflicts_.begin(), conflicts_.end(),
        [&item_id](const SyncConflict& c) { return c.item_id == item_id; });
    
    if (it == conflicts_.end()) {
        return false;
    }
    
    // 应用解决方案
    const SyncItem& resolved = use_local ? it->local_version : it->remote_version;
    
    // 更新本地数据
    {
        std::lock_guard<std::mutex> lock(data_mutex_);
        local_items_[item_id] = resolved;
    }
    
    // 移除冲突
    conflicts_.erase(it);
    
    return true;
}

void DataSync::setSyncCallback(SyncCallback callback) {
    sync_callback_ = std::move(callback);
}

void DataSync::setConflictCallback(ConflictCallback callback) {
    conflict_callback_ = std::move(callback);
}

void DataSync::setCompleteCallback(CompleteCallback callback) {
    complete_callback_ = std::move(callback);
}

bool DataSync::addLocalChange(const SyncItem& item) {
    std::lock_guard<std::mutex> lock(data_mutex_);
    
    // 更新版本
    uint64_t new_version = version_store_[item.item_id] + 1;
    
    SyncItem item_with_version = item;
    item_with_version.version = new_version;
    item_with_version.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    
    pending_items_[item.item_id] = item_with_version;
    version_store_[item.item_id] = new_version;
    
    std::cout << "[Sync] Added local change: " << item.item_id << " (v" << new_version << ")" << std::endl;
    
    return true;
}

std::vector<SyncItem> DataSync::getPendingChanges() {
    std::lock_guard<std::mutex> lock(data_mutex_);
    
    std::vector<SyncItem> items;
    for (const auto& [id, item] : pending_items_) {
        items.push_back(item);
    }
    
    return items;
}

bool DataSync::applyRemoteChanges(const std::vector<SyncItem>& items) {
    std::lock_guard<std::mutex> lock(data_mutex_);
    
    for (const auto& remote_item : items) {
        auto local_it = local_items_.find(remote_item.item_id);
        
        if (local_it == local_items_.end()) {
            // 本地不存在，直接应用
            local_items_[remote_item.item_id] = remote_item;
            version_store_[remote_item.item_id] = remote_item.version;
            std::cout << "[Sync] Applied new remote item: " << remote_item.item_id << std::endl;
        } else {
            // 存在本地版本，检查冲突
            const SyncItem& local_item = local_it->second;
            
            if (remote_item.version > local_item.version) {
                // 远程版本更新
                local_items_[remote_item.item_id] = remote_item;
                version_store_[remote_item.item_id] = remote_item.version;
                std::cout << "[Sync] Updated from remote: " << remote_item.item_id << std::endl;
            } else if (remote_item.version == local_item.version) {
                // 同版本，需要处理
                if (config_.conflict_resolution == ConflictResolution::CONFLICT) {
                    // 记录冲突
                    std::lock_guard<std::mutex> lock(conflict_mutex_);
                    SyncConflict conflict;
                    conflict.item_id = remote_item.item_id;
                    conflict.local_version = local_item;
                    conflict.remote_version = remote_item;
                    conflicts_.push_back(conflict);
                    
                    if (conflict_callback_) {
                        conflict_callback_(conflict);
                    }
                }
            }
        }
    }
    
    return true;
}

uint64_t DataSync::getLocalVersion(const std::string& item_id) {
    std::lock_guard<std::mutex> lock(data_mutex_);
    return version_store_[item_id];
}

bool DataSync::updateVersion(const std::string& item_id, uint64_t version) {
    std::lock_guard<std::mutex> lock(data_mutex_);
    version_store_[item_id] = version;
    return true;
}

void DataSync::syncLoop() {
    std::cout << "[Sync] Sync loop started" << std::endl;
    
    while (running_) {
        if (config_.auto_sync && trigger_sync_) {
            trigger_sync_ = false;
            performSync(config_.default_sync_type);
        }
        
        std::this_thread::sleep_for(std::chrono::milliseconds(config_.sync_interval_ms));
    }
    
    std::cout << "[Sync] Sync loop stopped" << std::endl;
}

bool DataSync::performSync(SyncType type) {
    status_ = SyncStatus::SYNCING;
    progress_.status = SyncStatus::SYNCING;
    progress_.start_time = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    
    // 准备同步批次
    auto batch = prepareSyncBatch();
    progress_.total_items = static_cast<uint32_t>(batch.size());
    progress_.synced_items = 0;
    
    // 模拟同步
    for (const auto& item : batch) {
        if (!running_) break;
        
        progress_.current_item = item.item_id;
        notifyProgress();
        
        // 实际发送逻辑（通过eCAL或网络）
        std::this_thread::sleep_for(std::chrono::milliseconds(5));
        
        progress_.synced_items++;
        
        // 从待同步列表移除
        {
            std::lock_guard<std::mutex> lock(data_mutex_);
            pending_items_.erase(item.item_id);
        }
    }
    
    progress_.end_time = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    progress_.status = SyncStatus::COMPLETED;
    status_ = SyncStatus::COMPLETED;
    
    notifyProgress();
    notifyComplete(true, "Sync completed successfully");
    
    return true;
}

std::vector<SyncItem> DataSync::prepareSyncBatch() {
    std::lock_guard<std::mutex> lock(data_mutex_);
    
    std::vector<SyncItem> batch;
    uint32_t count = 0;
    
    for (const auto& [id, item] : pending_items_) {
        if (count >= config_.max_batch_size) break;
        
        // 加密同步
        if (config_.encrypt_sync && !item.data.empty()) {
            // 加密数据
            // 简化实现
        }
        
        batch.push_back(item);
        count++;
    }
    
    return batch;
}

bool DataSync::applyChanges(const std::vector<SyncItem>& items) {
    return applyRemoteChanges(items);
}

void DataSync::handleConflict(const SyncItem& local, const SyncItem& remote) {
    std::lock_guard<std::mutex> lock(conflict_mutex_);
    
    SyncConflict conflict;
    conflict.item_id = local.item_id;
    conflict.local_version = local;
    conflict.remote_version = remote;
    conflicts_.push_back(conflict);
    
    status_ = SyncStatus::CONFLICT;
    
    if (conflict_callback_) {
        conflict_callback_(conflict);
    }
}

SyncItem DataSync::resolve(const SyncItem& local, const SyncItem& remote) {
    switch (config_.conflict_resolution) {
        case ConflictResolution::LOCAL_WINS:
            return local;
        case ConflictResolution::REMOTE_WINS:
            return remote;
        case ConflictResolution::LATEST_WINS:
            return (local.timestamp > remote.timestamp) ? local : remote;
        case ConflictResolution::MANUAL:
        default:
            return local; // 返回本地，等待手动解决
    }
}

void DataSync::notifyProgress() {
    if (sync_callback_) {
        sync_callback_(progress_);
    }
}

void DataSync::notifyComplete(bool success, const std::string& message) {
    if (complete_callback_) {
        complete_callback_(success, message);
    }
}

uint64_t DataSync::generateSyncId() {
    static std::atomic<uint64_t> counter{0};
    return std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count() + (++counter);
}

std::string DataSync::generateItemId() {
    static std::atomic<uint64_t> counter{0};
    return "item_" + std::to_string(++counter);
}

// ============================================================================
// DeviceSyncManager实现
// ============================================================================

DeviceSyncManager::DeviceSyncManager() {}

DeviceSyncManager::~DeviceSyncManager() {}

bool DeviceSyncManager::initialize() {
    std::cout << "[SyncManager] Initializing device sync manager" << std::endl;
    return true;
}

bool DeviceSyncManager::registerDevice(const std::string& device_id, 
                                       const std::string& endpoint) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    devices_[device_id] = endpoint;
    device_status_[device_id] = SyncStatus::IDLE;
    
    std::cout << "[SyncManager] Registered device: " << device_id << std::endl;
    return true;
}

bool DeviceSyncManager::unregisterDevice(const std::string& device_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    devices_.erase(device_id);
    device_status_.erase(device_id);
    syncers_.erase(device_id);
    
    std::cout << "[SyncManager] Unregistered device: " << device_id << std::endl;
    return true;
}

std::vector<std::string> DeviceSyncManager::getRegisteredDevices() {
    std::lock_guard<std::mutex> lock(mutex_);
    
    std::vector<std::string> result;
    for (const auto& [id, _] : devices_) {
        result.push_back(id);
    }
    return result;
}

bool DeviceSyncManager::syncWithDevice(const std::string& device_id) {
    std::lock_guard<std::mutex> lock(mutex_);
    
    auto it = syncers_.find(device_id);
    if (it == syncers_.end()) {
        // 创建新的同步器
        SyncConfig config;
        config.device_id = local_device_id_;
        syncers_[device_id] = createDataSync(config);
        it = syncers_.find(device_id);
    }
    
    device_status_[device_id] = SyncStatus::SYNCING;
    bool success = it->second->triggerSyncForDevice(device_id);
    device_status_[device_id] = success ? SyncStatus::COMPLETED : SyncStatus::FAILED;
    
    return success;
}

bool DeviceSyncManager::syncWithAllDevices() {
    std::vector<std::string> devices = getRegisteredDevices();
    
    for (const auto& device_id : devices) {
        if (!syncWithDevice(device_id)) {
            std::cerr << "[SyncManager] Failed to sync with device: " << device_id << std::endl;
        }
    }
    
    return true;
}

std::map<std::string, SyncStatus> DeviceSyncManager::getDeviceSyncStatus() const {
    std::lock_guard<std::mutex> lock(mutex_);
    return device_status_;
}

// ============================================================================
// 便捷函数
// ============================================================================

std::unique_ptr<DataSync> createDataSync(const SyncConfig& config) {
    return std::make_unique<DataSync>(config);
}

std::unique_ptr<DeviceSyncManager> createDeviceSyncManager() {
    return std::make_unique<DeviceSyncManager>();
}

SyncItem createSyncItem(DataType type, const std::string& device_id,
                        const std::vector<uint8_t>& data) {
    SyncItem item;
    item.item_id = "item_" + std::to_string(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count());
    item.data_type = type;
    item.device_id = device_id;
    item.data = data;
    item.version = 1;
    item.timestamp = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    item.deleted = false;
    return item;
}

} // namespace sync
} // namespace polyvault