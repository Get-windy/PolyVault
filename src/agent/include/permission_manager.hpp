/**
 * @file permission_manager.hpp
 * @brief 权限验证模块
 * 
 * 功能：
 * - 基于角色的访问控制 (RBAC)
 * - 权限策略管理
 * - 资源访问控制
 * - 权限缓存
 */

#pragma once

#include <string>
#include <vector>
#include <map>
#include <set>
#include <memory>
#include <mutex>
#include <functional>
#include <optional>
#include <chrono>

namespace polyvault {
namespace security {

// ============================================================================
// 类型定义
// ============================================================================

/**
 * @brief 权限类型
 */
enum class Permission : uint32_t {
    NONE = 0,
    READ = 1 << 0,
    WRITE = 1 << 1,
    DELETE = 1 << 2,
    EXECUTE = 1 << 3,
    ADMIN = 1 << 4,
    ALL = READ | WRITE | DELETE | EXECUTE | ADMIN
};

// 位运算操作
inline Permission operator|(Permission a, Permission b) {
    return static_cast<Permission>(static_cast<uint32_t>(a) | static_cast<uint32_t>(b));
}

inline Permission operator&(Permission a, Permission b) {
    return static_cast<Permission>(static_cast<uint32_t>(a) & static_cast<uint32_t>(b));
}

inline bool hasPermission(Permission user_perm, Permission required) {
    return (user_perm & required) == required;
}

/**
 * @brief 资源类型
 */
enum class ResourceType : uint8_t {
    CREDENTIAL,
    DEVICE,
    PLUGIN,
    CONFIG,
    LOG,
    AUDIT,
    SYSTEM
};

/**
 * @brief 角色定义
 */
struct Role {
    std::string id;
    std::string name;
    std::string description;
    Permission permissions;
    std::set<std::string> resource_patterns;  // 允许访问的资源模式
    bool is_admin = false;
};

/**
 * @brief 用户/设备身份
 */
struct Identity {
    std::string id;
    std::string name;
    std::string type;  // user, device, service
    std::set<std::string> roles;
    std::map<std::string, std::string> attributes;
    uint64_t created_at;
    uint64_t expires_at;  // 0 = 永不过期
};

/**
 * @brief 访问请求
 */
struct AccessRequest {
    std::string identity_id;
    ResourceType resource_type;
    std::string resource_id;
    Permission action;
    std::map<std::string, std::string> context;
};

/**
 * @brief 访问决策
 */
struct AccessDecision {
    bool allowed;
    std::string reason;
    Permission granted_permissions;
    uint64_t expires_at;
    std::map<std::string, std::string> obligations;  // 附加义务
};

/**
 * @brief 权限策略
 */
struct PermissionPolicy {
    std::string id;
    std::string name;
    std::string description;
    
    // 主体（谁）
    std::vector<std::string> subject_patterns;
    
    // 资源（什么）
    std::vector<ResourceType> resource_types;
    std::vector<std::string> resource_patterns;
    
    // 动作（操作）
    Permission actions;
    
    // 条件（何时）
    std::map<std::string, std::string> conditions;
    
    // 效果（允许/拒绝）
    bool allow = true;
    
    // 优先级
    int priority = 0;
};

// ============================================================================
// 权限管理器配置
// ============================================================================

struct PermissionManagerConfig {
    bool enable_cache = true;
    int cache_ttl_seconds = 300;  // 5分钟
    bool deny_by_default = true;
    bool enable_audit = true;
    std::string admin_role_id = "admin";
};

// ============================================================================
// 权限管理器
// ============================================================================

class PermissionManager {
public:
    explicit PermissionManager(const PermissionManagerConfig& config = {});
    ~PermissionManager();
    
    // 初始化
    bool initialize();
    
    // 角色管理
    bool createRole(const Role& role);
    bool updateRole(const std::string& role_id, const Role& role);
    bool deleteRole(const std::string& role_id);
    std::optional<Role> getRole(const std::string& role_id) const;
    std::vector<Role> getAllRoles() const;
    
    // 身份管理
    bool createIdentity(const Identity& identity);
    bool updateIdentity(const std::string& identity_id, const Identity& identity);
    bool deleteIdentity(const std::string& identity_id);
    std::optional<Identity> getIdentity(const std::string& identity_id) const;
    
    // 角色分配
    bool assignRole(const std::string& identity_id, const std::string& role_id);
    bool revokeRole(const std::string& identity_id, const std::string& role_id);
    std::vector<std::string> getIdentityRoles(const std::string& identity_id) const;
    
    // 权限检查
    AccessDecision checkAccess(const AccessRequest& request);
    bool hasPermission(const std::string& identity_id, 
                       ResourceType resource_type,
                       const std::string& resource_id,
                       Permission action);
    
    // 批量权限检查
    std::map<std::string, AccessDecision> checkAccessBatch(
        const std::vector<AccessRequest>& requests);
    
    // 策略管理
    bool addPolicy(const PermissionPolicy& policy);
    bool removePolicy(const std::string& policy_id);
    std::vector<PermissionPolicy> getPolicies() const;
    
    // 缓存管理
    void clearCache();
    void invalidateCache(const std::string& identity_id);
    
    // 审计
    void setAuditCallback(std::function<void(const AccessRequest&, const AccessDecision&)> callback);
    
    // 管理员检查
    bool isAdmin(const std::string& identity_id) const;
    
    // 便捷方法
    Permission getIdentityPermissions(const std::string& identity_id) const;
    
private:
    // 内部方法
    bool matchPattern(const std::string& pattern, const std::string& value) const;
    bool evaluateConditions(const std::map<std::string, std::string>& conditions,
                           const std::map<std::string, std::string>& context) const;
    std::string getCacheKey(const AccessRequest& request) const;
    void auditAccess(const AccessRequest& request, const AccessDecision& decision);
    
private:
    PermissionManagerConfig config_;
    bool initialized_ = false;
    
    // 角色存储
    mutable std::mutex roles_mutex_;
    std::map<std::string, Role> roles_;
    
    // 身份存储
    mutable std::mutex identities_mutex_;
    std::map<std::string, Identity> identities_;
    
    // 策略存储
    mutable std::mutex policies_mutex_;
    std::vector<PermissionPolicy> policies_;
    
    // 权限缓存
    mutable std::mutex cache_mutex_;
    std::map<std::string, std::pair<AccessDecision, uint64_t>> cache_;
    
    // 审计回调
    std::function<void(const AccessRequest&, const AccessDecision&)> audit_callback_;
};

// ============================================================================
// 权限辅助工具
// ============================================================================

/**
 * @brief 权限字符串转换
 */
std::string permissionToString(Permission perm);
Permission stringToPermission(const std::string& str);

/**
 * @brief 资源类型字符串转换
 */
std::string resourceTypeToString(ResourceType type);
ResourceType stringToResourceType(const std::string& str);

/**
 * @brief 创建默认角色
 */
std::vector<Role> createDefaultRoles();

/**
 * @brief 创建管理员身份
 */
Identity createAdminIdentity(const std::string& admin_id = "admin");

} // namespace security
} // namespace polyvault