/**
 * @file permission_manager.cpp
 * @brief 权限验证模块实现
 */

#include "permission_manager.hpp"
#include <iostream>
#include <algorithm>
#include <regex>
#include <sstream>

namespace polyvault {
namespace security {

// ============================================================================
// 权限字符串转换
// ============================================================================

std::string permissionToString(Permission perm) {
    std::vector<std::string> parts;
    
    if (hasPermission(perm, Permission::READ)) parts.push_back("read");
    if (hasPermission(perm, Permission::WRITE)) parts.push_back("write");
    if (hasPermission(perm, Permission::DELETE)) parts.push_back("delete");
    if (hasPermission(perm, Permission::EXECUTE)) parts.push_back("execute");
    if (hasPermission(perm, Permission::ADMIN)) parts.push_back("admin");
    
    if (parts.empty()) return "none";
    
    std::string result;
    for (size_t i = 0; i < parts.size(); ++i) {
        if (i > 0) result += "|";
        result += parts[i];
    }
    return result;
}

Permission stringToPermission(const std::string& str) {
    Permission perm = Permission::NONE;
    
    std::istringstream iss(str);
    std::string part;
    while (std::getline(iss, part, '|')) {
        if (part == "read") perm = perm | Permission::READ;
        else if (part == "write") perm = perm | Permission::WRITE;
        else if (part == "delete") perm = perm | Permission::DELETE;
        else if (part == "execute") perm = perm | Permission::EXECUTE;
        else if (part == "admin") perm = perm | Permission::ADMIN;
        else if (part == "all") perm = Permission::ALL;
    }
    
    return perm;
}

std::string resourceTypeToString(ResourceType type) {
    switch (type) {
        case ResourceType::CREDENTIAL: return "credential";
        case ResourceType::DEVICE: return "device";
        case ResourceType::PLUGIN: return "plugin";
        case ResourceType::CONFIG: return "config";
        case ResourceType::LOG: return "log";
        case ResourceType::AUDIT: return "audit";
        case ResourceType::SYSTEM: return "system";
        default: return "unknown";
    }
}

ResourceType stringToResourceType(const std::string& str) {
    if (str == "credential") return ResourceType::CREDENTIAL;
    if (str == "device") return ResourceType::DEVICE;
    if (str == "plugin") return ResourceType::PLUGIN;
    if (str == "config") return ResourceType::CONFIG;
    if (str == "log") return ResourceType::LOG;
    if (str == "audit") return ResourceType::AUDIT;
    if (str == "system") return ResourceType::SYSTEM;
    return ResourceType::SYSTEM;
}

std::vector<Role> createDefaultRoles() {
    std::vector<Role> roles;
    
    // 管理员角色
    Role admin;
    admin.id = "admin";
    admin.name = "Administrator";
    admin.description = "Full system access";
    admin.permissions = Permission::ALL;
    admin.is_admin = true;
    admin.resource_patterns = {"*"};
    roles.push_back(admin);
    
    // 操作员角色
    Role operator_role;
    operator_role.id = "operator";
    operator_role.name = "Operator";
    operator_role.description = "Read and execute access";
    operator_role.permissions = Permission::READ | Permission::EXECUTE;
    operator_role.resource_patterns = {"credential:*", "device:*", "plugin:*"};
    roles.push_back(operator_role);
    
    // 只读角色
    Role viewer;
    viewer.id = "viewer";
    viewer.name = "Viewer";
    viewer.description = "Read-only access";
    viewer.permissions = Permission::READ;
    viewer.resource_patterns = {"credential:*", "device:*"};
    roles.push_back(viewer);
    
    // 设备角色
    Role device_role;
    device_role.id = "device";
    device_role.name = "Device";
    device_role.description = "Device access for credential requests";
    device_role.permissions = Permission::READ | Permission::EXECUTE;
    device_role.resource_patterns = {"credential:request"};
    roles.push_back(device_role);
    
    return roles;
}

Identity createAdminIdentity(const std::string& admin_id) {
    Identity admin;
    admin.id = admin_id;
    admin.name = "Administrator";
    admin.type = "user";
    admin.roles = {"admin"};
    admin.created_at = static_cast<uint64_t>(
        std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()
        ).count()
    );
    admin.expires_at = 0;  // 永不过期
    return admin;
}

// ============================================================================
// PermissionManager实现
// ============================================================================

PermissionManager::PermissionManager(const PermissionManagerConfig& config)
    : config_(config) {
    std::cout << "[PermissionManager] Created" << std::endl;
}

PermissionManager::~PermissionManager() {
    std::cout << "[PermissionManager] Destroyed" << std::endl;
}

bool PermissionManager::initialize() {
    if (initialized_) {
        return true;
    }
    
    std::cout << "[PermissionManager] Initializing..." << std::endl;
    
    // 创建默认角色
    auto default_roles = createDefaultRoles();
    for (const auto& role : default_roles) {
        roles_[role.id] = role;
    }
    
    // 创建管理员身份
    identities_[config_.admin_role_id] = createAdminIdentity(config_.admin_role_id);
    
    initialized_ = true;
    std::cout << "[PermissionManager] Initialized with " << roles_.size() << " roles" << std::endl;
    return true;
}

bool PermissionManager::createRole(const Role& role) {
    std::lock_guard<std::mutex> lock(roles_mutex_);
    
    if (roles_.find(role.id) != roles_.end()) {
        std::cerr << "[PermissionManager] Role already exists: " << role.id << std::endl;
        return false;
    }
    
    roles_[role.id] = role;
    std::cout << "[PermissionManager] Role created: " << role.id << std::endl;
    return true;
}

bool PermissionManager::updateRole(const std::string& role_id, const Role& role) {
    std::lock_guard<std::mutex> lock(roles_mutex_);
    
    auto it = roles_.find(role_id);
    if (it == roles_.end()) {
        return false;
    }
    
    it->second = role;
    it->second.id = role_id;  // 保持ID一致
    
    // 清除相关缓存
    clearCache();
    
    std::cout << "[PermissionManager] Role updated: " << role_id << std::endl;
    return true;
}

bool PermissionManager::deleteRole(const std::string& role_id) {
    std::lock_guard<std::mutex> lock(roles_mutex_);
    
    if (role_id == config_.admin_role_id) {
        std::cerr << "[PermissionManager] Cannot delete admin role" << std::endl;
        return false;
    }
    
    auto it = roles_.find(role_id);
    if (it == roles_.end()) {
        return false;
    }
    
    roles_.erase(it);
    clearCache();
    
    std::cout << "[PermissionManager] Role deleted: " << role_id << std::endl;
    return true;
}

std::optional<Role> PermissionManager::getRole(const std::string& role_id) const {
    std::lock_guard<std::mutex> lock(roles_mutex_);
    
    auto it = roles_.find(role_id);
    if (it != roles_.end()) {
        return it->second;
    }
    return std::nullopt;
}

std::vector<Role> PermissionManager::getAllRoles() const {
    std::lock_guard<std::mutex> lock(roles_mutex_);
    
    std::vector<Role> result;
    for (const auto& [_, role] : roles_) {
        result.push_back(role);
    }
    return result;
}

bool PermissionManager::createIdentity(const Identity& identity) {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    if (identities_.find(identity.id) != identities_.end()) {
        std::cerr << "[PermissionManager] Identity already exists: " << identity.id << std::endl;
        return false;
    }
    
    identities_[identity.id] = identity;
    std::cout << "[PermissionManager] Identity created: " << identity.id << std::endl;
    return true;
}

bool PermissionManager::updateIdentity(const std::string& identity_id, const Identity& identity) {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    auto it = identities_.find(identity_id);
    if (it == identities_.end()) {
        return false;
    }
    
    it->second = identity;
    it->second.id = identity_id;
    
    invalidateCache(identity_id);
    
    std::cout << "[PermissionManager] Identity updated: " << identity_id << std::endl;
    return true;
}

bool PermissionManager::deleteIdentity(const std::string& identity_id) {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    if (identity_id == config_.admin_role_id) {
        std::cerr << "[PermissionManager] Cannot delete admin identity" << std::endl;
        return false;
    }
    
    auto it = identities_.find(identity_id);
    if (it == identities_.end()) {
        return false;
    }
    
    identities_.erase(it);
    invalidateCache(identity_id);
    
    std::cout << "[PermissionManager] Identity deleted: " << identity_id << std::endl;
    return true;
}

std::optional<Identity> PermissionManager::getIdentity(const std::string& identity_id) const {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    auto it = identities_.find(identity_id);
    if (it != identities_.end()) {
        return it->second;
    }
    return std::nullopt;
}

bool PermissionManager::assignRole(const std::string& identity_id, const std::string& role_id) {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    auto it = identities_.find(identity_id);
    if (it == identities_.end()) {
        std::cerr << "[PermissionManager] Identity not found: " << identity_id << std::endl;
        return false;
    }
    
    // 检查角色是否存在
    {
        std::lock_guard<std::mutex> role_lock(roles_mutex_);
        if (roles_.find(role_id) == roles_.end()) {
            std::cerr << "[PermissionManager] Role not found: " << role_id << std::endl;
            return false;
        }
    }
    
    it->second.roles.insert(role_id);
    invalidateCache(identity_id);
    
    std::cout << "[PermissionManager] Role " << role_id << " assigned to " << identity_id << std::endl;
    return true;
}

bool PermissionManager::revokeRole(const std::string& identity_id, const std::string& role_id) {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    auto it = identities_.find(identity_id);
    if (it == identities_.end()) {
        return false;
    }
    
    it->second.roles.erase(role_id);
    invalidateCache(identity_id);
    
    std::cout << "[PermissionManager] Role " << role_id << " revoked from " << identity_id << std::endl;
    return true;
}

std::vector<std::string> PermissionManager::getIdentityRoles(const std::string& identity_id) const {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    auto it = identities_.find(identity_id);
    if (it != identities_.end()) {
        return std::vector<std::string>(it->second.roles.begin(), it->second.roles.end());
    }
    return {};
}

AccessDecision PermissionManager::checkAccess(const AccessRequest& request) {
    // 检查缓存
    if (config_.enable_cache) {
        std::string cache_key = getCacheKey(request);
        std::lock_guard<std::mutex> lock(cache_mutex_);
        
        auto it = cache_.find(cache_key);
        if (it != cache_.end()) {
            uint64_t now = static_cast<uint64_t>(
                std::chrono::duration_cast<std::chrono::milliseconds>(
                    std::chrono::system_clock::now().time_since_epoch()
                ).count()
            );
            
            if (now - it->second.second < static_cast<uint64_t>(config_.cache_ttl_seconds) * 1000) {
                return it->second.first;
            }
        }
    }
    
    AccessDecision decision;
    
    // 获取身份
    auto identity = getIdentity(request.identity_id);
    if (!identity) {
        decision.allowed = false;
        decision.reason = "Identity not found: " + request.identity_id;
        auditAccess(request, decision);
        return decision;
    }
    
    // 检查过期
    if (identity->expires_at > 0) {
        uint64_t now = static_cast<uint64_t>(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()
            ).count()
        );
        
        if (now > identity->expires_at) {
            decision.allowed = false;
            decision.reason = "Identity expired";
            auditAccess(request, decision);
            return decision;
        }
    }
    
    // 检查管理员
    if (isAdmin(request.identity_id)) {
        decision.allowed = true;
        decision.reason = "Admin access";
        decision.granted_permissions = Permission::ALL;
        auditAccess(request, decision);
        return decision;
    }
    
    // 收集所有角色的权限
    Permission total_permissions = Permission::NONE;
    
    {
        std::lock_guard<std::mutex> lock(roles_mutex_);
        
        for (const auto& role_id : identity->roles) {
            auto it = roles_.find(role_id);
            if (it != roles_.end()) {
                total_permissions = total_permissions | it->second.permissions;
            }
        }
    }
    
    // 检查权限
    if (hasPermission(total_permissions, request.action)) {
        decision.allowed = true;
        decision.reason = "Permission granted";
        decision.granted_permissions = total_permissions;
    } else {
        decision.allowed = false;
        decision.reason = "Permission denied. Required: " + permissionToString(request.action) + 
                         ", Granted: " + permissionToString(total_permissions);
    }
    
    // 应用策略
    {
        std::lock_guard<std::mutex> lock(policies_mutex_);
        
        for (const auto& policy : policies_) {
            // 检查策略是否匹配
            bool subject_match = false;
            for (const auto& pattern : policy.subject_patterns) {
                if (matchPattern(pattern, request.identity_id)) {
                    subject_match = true;
                    break;
                }
            }
            
            if (!subject_match) continue;
            
            // 检查资源类型
            bool type_match = std::find(policy.resource_types.begin(), 
                                       policy.resource_types.end(),
                                       request.resource_type) != policy.resource_types.end();
            
            if (!type_match) continue;
            
            // 检查资源模式
            bool resource_match = false;
            for (const auto& pattern : policy.resource_patterns) {
                if (matchPattern(pattern, request.resource_id)) {
                    resource_match = true;
                    break;
                }
            }
            
            if (!resource_match) continue;
            
            // 检查条件
            if (!evaluateConditions(policy.conditions, request.context)) {
                continue;
            }
            
            // 应用策略效果
            if (!policy.allow) {
                decision.allowed = false;
                decision.reason = "Denied by policy: " + policy.id;
            } else if (policy.allow && !decision.allowed) {
                // 允许策略可以覆盖默认拒绝
                if (hasPermission(policy.actions, request.action)) {
                    decision.allowed = true;
                    decision.reason = "Allowed by policy: " + policy.id;
                }
            }
        }
    }
    
    // 默认拒绝
    if (config_.deny_by_default && !decision.allowed) {
        decision.reason = "Access denied by default";
    }
    
    // 缓存结果
    if (config_.enable_cache) {
        std::string cache_key = getCacheKey(request);
        uint64_t now = static_cast<uint64_t>(
            std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()
            ).count()
        );
        
        std::lock_guard<std::mutex> lock(cache_mutex_);
        cache_[cache_key] = {decision, now};
    }
    
    auditAccess(request, decision);
    return decision;
}

bool PermissionManager::hasPermission(const std::string& identity_id,
                                       ResourceType resource_type,
                                       const std::string& resource_id,
                                       Permission action) {
    AccessRequest request;
    request.identity_id = identity_id;
    request.resource_type = resource_type;
    request.resource_id = resource_id;
    request.action = action;
    
    return checkAccess(request).allowed;
}

bool PermissionManager::isAdmin(const std::string& identity_id) const {
    std::lock_guard<std::mutex> lock(identities_mutex_);
    
    auto it = identities_.find(identity_id);
    if (it != identities_.end()) {
        return it->second.roles.find(config_.admin_role_id) != it->second.roles.end();
    }
    return false;
}

Permission PermissionManager::getIdentityPermissions(const std::string& identity_id) const {
    Permission total = Permission::NONE;
    
    auto identity = getIdentity(identity_id);
    if (!identity) {
        return total;
    }
    
    std::lock_guard<std::mutex> lock(roles_mutex_);
    
    for (const auto& role_id : identity->roles) {
        auto it = roles_.find(role_id);
        if (it != roles_.end()) {
            total = total | it->second.permissions;
        }
    }
    
    return total;
}

bool PermissionManager::matchPattern(const std::string& pattern, const std::string& value) const {
    if (pattern == "*") return true;
    
    std::string regex_pattern;
    for (char c : pattern) {
        if (c == '*') regex_pattern += ".*";
        else if (c == '?') regex_pattern += ".";
        else regex_pattern += c;
    }
    
    try {
        std::regex re("^" + regex_pattern + "$");
        return std::regex_match(value, re);
    } catch (const std::regex_error&) {
        return false;
    }
}

bool PermissionManager::evaluateConditions(
    const std::map<std::string, std::string>& conditions,
    const std::map<std::string, std::string>& context) const {
    
    for (const auto& [key, expected] : conditions) {
        auto it = context.find(key);
        if (it == context.end() || it->second != expected) {
            return false;
        }
    }
    return true;
}

std::string PermissionManager::getCacheKey(const AccessRequest& request) const {
    return request.identity_id + ":" + 
           resourceTypeToString(request.resource_type) + ":" +
           request.resource_id + ":" +
           std::to_string(static_cast<uint32_t>(request.action));
}

void PermissionManager::auditAccess(const AccessRequest& request, const AccessDecision& decision) {
    if (!config_.enable_audit) return;
    
    std::cout << "[PermissionManager] Access " << (decision.allowed ? "GRANTED" : "DENIED")
              << " for " << request.identity_id
              << " on " << resourceTypeToString(request.resource_type) << ":" << request.resource_id
              << " action=" << permissionToString(request.action)
              << " reason=" << decision.reason << std::endl;
    
    if (audit_callback_) {
        audit_callback_(request, decision);
    }
}

// 其他方法的简化实现...

std::map<std::string, AccessDecision> PermissionManager::checkAccessBatch(
    const std::vector<AccessRequest>& requests) {
    std::map<std::string, AccessDecision> results;
    for (const auto& request : requests) {
        std::string key = request.identity_id + ":" + resourceTypeToString(request.resource_type) + 
                         ":" + request.resource_id;
        results[key] = checkAccess(request);
    }
    return results;
}

bool PermissionManager::addPolicy(const PermissionPolicy& policy) {
    std::lock_guard<std::mutex> lock(policies_mutex_);
    policies_.push_back(policy);
    std::sort(policies_.begin(), policies_.end(), 
              [](const PermissionPolicy& a, const PermissionPolicy& b) {
                  return a.priority > b.priority;
              });
    clearCache();
    return true;
}

bool PermissionManager::removePolicy(const std::string& policy_id) {
    std::lock_guard<std::mutex> lock(policies_mutex_);
    auto it = std::find_if(policies_.begin(), policies_.end(),
                          [&policy_id](const PermissionPolicy& p) { return p.id == policy_id; });
    if (it == policies_.end()) return false;
    policies_.erase(it);
    clearCache();
    return true;
}

std::vector<PermissionPolicy> PermissionManager::getPolicies() const {
    std::lock_guard<std::mutex> lock(policies_mutex_);
    return policies_;
}

void PermissionManager::clearCache() {
    std::lock_guard<std::mutex> lock(cache_mutex_);
    cache_.clear();
}

void PermissionManager::invalidateCache(const std::string& identity_id) {
    std::lock_guard<std::mutex> lock(cache_mutex_);
    std::vector<std::string> keys_to_remove;
    for (const auto& [key, _] : cache_) {
        if (key.find(identity_id) != std::string::npos) {
            keys_to_remove.push_back(key);
        }
    }
    for (const auto& key : keys_to_remove) {
        cache_.erase(key);
    }
}

void PermissionManager::setAuditCallback(
    std::function<void(const AccessRequest&, const AccessDecision&)> callback) {
    audit_callback_ = std::move(callback);
}

} // namespace security
} // namespace polyvault