#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
PolyVault 安全验证测试
测试范围：
1. zk_vault集成测试
2. 硬件安全模块测试
3. 权限验证流程测试
"""

import pytest
import hashlib
import os
import sys
import time
import json
import secrets
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, field
from enum import Enum, auto
from unittest.mock import Mock, MagicMock, patch

# 添加项目目录
sys.path.insert(0, 'I:\\PolyVault')


# ============================================================================
# 枚举和类型定义
# ============================================================================

class Permission(Enum):
    """权限类型"""
    NONE = 0
    READ = 1
    WRITE = 2
    DELETE = 4
    EXECUTE = 8
    ADMIN = 16
    ALL = 31


class ResourceType(Enum):
    """资源类型"""
    CREDENTIAL = auto()
    DEVICE = auto()
    PLUGIN = auto()
    CONFIG = auto()
    LOG = auto()
    AUDIT = auto()
    SYSTEM = auto()


class RiskLevel(Enum):
    """风险级别"""
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"
    INFO = "info"


# ============================================================================
# 数据类
# ============================================================================

@dataclass
class EncryptedItem:
    """加密项"""
    item_id: str
    service_url: str
    encrypted_data: str
    nonce: str
    tag: str
    created_time: float
    last_access_time: float


@dataclass
class Role:
    """角色定义"""
    id: str
    name: str
    description: str
    permissions: int = 0
    is_admin: bool = False


@dataclass
class Identity:
    """身份信息"""
    id: str
    name: str
    type: str
    roles: List[str] = field(default_factory=list)
    created_at: float = 0.0
    expires_at: float = 0.0


@dataclass
class AccessRequest:
    """访问请求"""
    identity_id: str
    resource_type: ResourceType
    resource_id: str
    action: Permission


@dataclass
class AccessDecision:
    """访问决策"""
    allowed: bool
    reason: str
    granted_permissions: int = 0
    expires_at: float = 0.0


# ============================================================================
# zk_vault 模拟实现
# ============================================================================

class MockZkVault:
    """模拟 Zero-Knowledge Vault"""
    
    def __init__(self, config: Dict = None):
        self.config = config or {}
        self.initialized = False
        self.unlocked = False
        self.master_key = None
        self.salt = None
        self.items: Dict[str, EncryptedItem] = {}
        self.auto_lock_timeout = self.config.get('auto_lock_timeout_ms', 300000)
        
    def initialize(self) -> bool:
        """初始化保险库"""
        self.initialized = True
        self.salt = secrets.token_bytes(32)
        return True
    
    def unlock(self, master_password: str) -> bool:
        """解锁保险库"""
        if not self.initialized:
            return False
        
        # 模拟密钥派生
        self.master_key = hashlib.pbkdf2_hmac(
            'sha256',
            master_password.encode(),
            self.salt,
            100000,
            dklen=32
        )
        self.unlocked = True
        return True
    
    def lock(self):
        """锁定保险库"""
        self.unlocked = False
        self.master_key = None
    
    def store_credential(self, service_url: str, username: str, password: str) -> bool:
        """存储凭证"""
        if not self.unlocked:
            return False
        
        item_id = secrets.token_hex(16)
        # 模拟加密
        data = f"{username}:{password}:{service_url}"
        encrypted = self._encrypt(data)
        
        item = EncryptedItem(
            item_id=item_id,
            service_url=service_url,
            encrypted_data=encrypted,
            nonce=secrets.token_hex(12),
            tag=secrets.token_hex(16),
            created_time=time.time(),
            last_access_time=time.time()
        )
        
        self.items[service_url] = item
        return True
    
    def get_credential(self, service_url: str) -> Optional[str]:
        """获取凭证"""
        if not self.unlocked:
            return None
        
        item = self.items.get(service_url)
        if not item:
            return None
        
        item.last_access_time = time.time()
        # 模拟解密
        return self._decrypt(item.encrypted_data)
    
    def delete_credential(self, service_url: str) -> bool:
        """删除凭证"""
        if service_url in self.items:
            del self.items[service_url]
            return True
        return False
    
    def list_services(self) -> List[str]:
        """列出所有服务"""
        return list(self.items.keys())
    
    def derive_key(self, password: str, salt: bytes) -> bytes:
        """派生密钥"""
        return hashlib.pbkdf2_hmac(
            'sha256',
            password.encode(),
            salt,
            100000,
            dklen=32
        )
    
    def _encrypt(self, data: str) -> str:
        """模拟加密"""
        return secrets.token_hex(len(data))
    
    def _decrypt(self, data: str) -> str:
        """模拟解密"""
        return f"decrypted_{data[:20]}"


# ============================================================================
# 硬件安全模块模拟
# ============================================================================

class MockHardwareSecurityModule:
    """模拟硬件安全模块"""
    
    def __init__(self):
        self.available = True
        self.tpm_available = False
        self.secure_enclave_available = False
        self.keys: Dict[str, bytes] = {}
    
    def detect_hardware(self) -> Dict[str, bool]:
        """检测硬件安全模块"""
        return {
            'tpm': self.tpm_available,
            'secure_enclave': self.secure_enclave_available,
            'hsm': self.available
        }
    
    def generate_key(self, key_id: str) -> bytes:
        """生成密钥"""
        key = secrets.token_bytes(32)
        self.keys[key_id] = key
        return key
    
    def store_key(self, key_id: str, key: bytes) -> bool:
        """存储密钥"""
        self.keys[key_id] = key
        return True
    
    def get_key(self, key_id: str) -> Optional[bytes]:
        """获取密钥"""
        return self.keys.get(key_id)
    
    def delete_key(self, key_id: str) -> bool:
        """删除密钥"""
        if key_id in self.keys:
            del self.keys[key_id]
            return True
        return False
    
    def sign(self, key_id: str, data: bytes) -> bytes:
        """签名"""
        key = self.keys.get(key_id)
        if not key:
            raise ValueError("Key not found")
        
        # 模拟签名
        return hashlib.sha256(key + data).digest()
    
    def verify(self, key_id: str, data: bytes, signature: bytes) -> bool:
        """验证签名"""
        key = self.keys.get(key_id)
        if not key:
            return False
        
        expected = hashlib.sha256(key + data).digest()
        return secrets.compare_digest(expected, signature)


# ============================================================================
# 权限管理器
# ============================================================================

class PermissionManager:
    """权限管理器"""
    
    def __init__(self, config: Dict = None):
        self.config = config or {}
        self.roles: Dict[str, Role] = {}
        self.identities: Dict[str, Identity] = {}
        self.cache: Dict[str, AccessDecision] = {}
        self.cache_ttl = self.config.get('cache_ttl_seconds', 300)
        self.deny_by_default = self.config.get('deny_by_default', True)
        self._init_default_roles()
    
    def _init_default_roles(self):
        """初始化默认角色"""
        default_roles = [
            Role('admin', '管理员', '系统管理员', Permission.ALL.value, True),
            Role('user', '用户', '普通用户', Permission.READ.value | Permission.WRITE.value),
            Role('viewer', '查看者', '只读用户', Permission.READ.value),
            Role('service', '服务', '服务账户', Permission.READ.value | Permission.EXECUTE.value),
        ]
        
        for role in default_roles:
            self.roles[role.id] = role
    
    def create_role(self, role: Role) -> bool:
        """创建角色"""
        if role.id in self.roles:
            return False
        self.roles[role.id] = role
        return True
    
    def get_role(self, role_id: str) -> Optional[Role]:
        """获取角色"""
        return self.roles.get(role_id)
    
    def create_identity(self, identity: Identity) -> bool:
        """创建身份"""
        if identity.id in self.identities:
            return False
        self.identities[identity.id] = identity
        return True
    
    def get_identity(self, identity_id: str) -> Optional[Identity]:
        """获取身份"""
        return self.identities.get(identity_id)
    
    def assign_role(self, identity_id: str, role_id: str) -> bool:
        """分配角色"""
        identity = self.identities.get(identity_id)
        role = self.roles.get(role_id)
        
        if not identity or not role:
            return False
        
        if role_id not in identity.roles:
            identity.roles.append(role_id)
        
        return True
    
    def check_access(self, request: AccessRequest) -> AccessDecision:
        """检查访问权限"""
        # 检查缓存
        cache_key = f"{request.identity_id}:{request.resource_type.name}:{request.resource_id}:{request.action.name}"
        
        if cache_key in self.cache:
            return self.cache[cache_key]
        
        # 获取身份
        identity = self.identities.get(request.identity_id)
        if not identity:
            return AccessDecision(False, "Identity not found")
        
        # 检查过期
        if identity.expires_at > 0 and time.time() > identity.expires_at:
            return AccessDecision(False, "Identity expired")
        
        # 计算权限
        total_permissions = 0
        for role_id in identity.roles:
            role = self.roles.get(role_id)
            if role:
                total_permissions |= role.permissions
        
        # 检查权限
        required = request.action.value
        has_permission = (total_permissions & required) == required
        
        decision = AccessDecision(
            allowed=has_permission,
            reason="Permission granted" if has_permission else "Permission denied",
            granted_permissions=total_permissions
        )
        
        # 缓存结果
        self.cache[cache_key] = decision
        
        return decision
    
    def has_permission(self, identity_id: str, resource_type: ResourceType,
                       resource_id: str, action: Permission) -> bool:
        """检查权限"""
        request = AccessRequest(identity_id, resource_type, resource_id, action)
        decision = self.check_access(request)
        return decision.allowed
    
    def is_admin(self, identity_id: str) -> bool:
        """检查是否为管理员"""
        identity = self.identities.get(identity_id)
        if not identity:
            return False
        
        for role_id in identity.roles:
            role = self.roles.get(role_id)
            if role and role.is_admin:
                return True
        
        return False
    
    def clear_cache(self):
        """清除缓存"""
        self.cache.clear()


# ============================================================================
# 测试类
# ============================================================================

class TestZkVaultIntegration:
    """测试 zk_vault 集成"""
    
    @pytest.fixture
    def vault(self):
        """创建 Vault 实例"""
        vault = MockZkVault({
            'auto_lock_timeout_ms': 300000,
            'key_iterations': 100000
        })
        vault.initialize()
        return vault
    
    def test_initialize_vault(self, vault):
        """TC-ZK001: 初始化保险库"""
        assert vault.initialized is True
        assert vault.salt is not None
        assert len(vault.salt) == 32
    
    def test_unlock_vault(self, vault):
        """TC-ZK002: 解锁保险库"""
        result = vault.unlock("test-master-password-123")
        assert result is True
        assert vault.unlocked is True
        assert vault.master_key is not None
    
    def test_lock_vault(self, vault):
        """TC-ZK003: 锁定保险库"""
        vault.unlock("test-password")
        vault.lock()
        assert vault.unlocked is False
        assert vault.master_key is None
    
    def test_store_credential(self, vault):
        """TC-ZK004: 存储凭证"""
        vault.unlock("test-password")
        result = vault.store_credential(
            "https://example.com",
            "testuser",
            "testpass123"
        )
        assert result is True
        assert "https://example.com" in vault.items
    
    def test_get_credential(self, vault):
        """TC-ZK005: 获取凭证"""
        vault.unlock("test-password")
        vault.store_credential("https://example.com", "user", "pass")
        
        credential = vault.get_credential("https://example.com")
        assert credential is not None
    
    def test_delete_credential(self, vault):
        """TC-ZK006: 删除凭证"""
        vault.unlock("test-password")
        vault.store_credential("https://example.com", "user", "pass")
        
        result = vault.delete_credential("https://example.com")
        assert result is True
        assert "https://example.com" not in vault.items
    
    def test_list_services(self, vault):
        """TC-ZK007: 列出服务"""
        vault.unlock("test-password")
        vault.store_credential("https://service1.com", "user1", "pass1")
        vault.store_credential("https://service2.com", "user2", "pass2")
        
        services = vault.list_services()
        assert len(services) == 2
        assert "https://service1.com" in services
        assert "https://service2.com" in services
    
    def test_key_derivation(self, vault):
        """TC-ZK008: 密钥派生"""
        salt = secrets.token_bytes(32)
        key1 = vault.derive_key("password123", salt)
        key2 = vault.derive_key("password123", salt)
        
        assert key1 == key2  # 相同密码和盐应该派生相同密钥
        assert len(key1) == 32
    
    def test_different_passwords_different_keys(self, vault):
        """TC-ZK009: 不同密码派生不同密钥"""
        salt = secrets.token_bytes(32)
        key1 = vault.derive_key("password1", salt)
        key2 = vault.derive_key("password2", salt)
        
        assert key1 != key2
    
    def test_locked_vault_operations_fail(self, vault):
        """TC-ZK010: 锁定状态下操作失败"""
        result = vault.store_credential("https://example.com", "user", "pass")
        assert result is False
        
        credential = vault.get_credential("https://example.com")
        assert credential is None


class TestHardwareSecurityModule:
    """测试硬件安全模块"""
    
    @pytest.fixture
    def hsm(self):
        """创建 HSM 实例"""
        return MockHardwareSecurityModule()
    
    def test_detect_hardware(self, hsm):
        """TC-HSM001: 检测硬件"""
        detection = hsm.detect_hardware()
        
        assert 'tpm' in detection
        assert 'secure_enclave' in detection
        assert 'hsm' in detection
    
    def test_generate_key(self, hsm):
        """TC-HSM002: 生成密钥"""
        key = hsm.generate_key("test-key-1")
        
        assert key is not None
        assert len(key) == 32
        assert "test-key-1" in hsm.keys
    
    def test_store_key(self, hsm):
        """TC-HSM003: 存储密钥"""
        test_key = secrets.token_bytes(32)
        result = hsm.store_key("stored-key", test_key)
        
        assert result is True
        assert hsm.get_key("stored-key") == test_key
    
    def test_get_key(self, hsm):
        """TC-HSM004: 获取密钥"""
        original_key = hsm.generate_key("get-test-key")
        retrieved_key = hsm.get_key("get-test-key")
        
        assert retrieved_key == original_key
    
    def test_delete_key(self, hsm):
        """TC-HSM005: 删除密钥"""
        hsm.generate_key("delete-test-key")
        result = hsm.delete_key("delete-test-key")
        
        assert result is True
        assert hsm.get_key("delete-test-key") is None
    
    def test_sign_and_verify(self, hsm):
        """TC-HSM006: 签名和验证"""
        hsm.generate_key("sign-key")
        data = b"test data to sign"
        
        signature = hsm.sign("sign-key", data)
        assert signature is not None
        assert len(signature) == 32
        
        # 验证签名
        valid = hsm.verify("sign-key", data, signature)
        assert valid is True
    
    def test_verify_wrong_signature(self, hsm):
        """TC-HSM007: 验证错误签名"""
        hsm.generate_key("verify-key")
        data = b"test data"
        
        wrong_signature = secrets.token_bytes(32)
        valid = hsm.verify("verify-key", data, wrong_signature)
        
        assert valid is False
    
    def test_sign_with_nonexistent_key(self, hsm):
        """TC-HSM008: 使用不存在的密钥签名"""
        with pytest.raises(ValueError):
            hsm.sign("nonexistent-key", b"data")


class TestPermissionVerification:
    """测试权限验证流程"""
    
    @pytest.fixture
    def permission_manager(self):
        """创建权限管理器"""
        return PermissionManager({
            'cache_ttl_seconds': 300,
            'deny_by_default': True
        })
    
    def test_default_roles_exist(self, permission_manager):
        """TC-PV001: 默认角色存在"""
        assert 'admin' in permission_manager.roles
        assert 'user' in permission_manager.roles
        assert 'viewer' in permission_manager.roles
    
    def test_create_role(self, permission_manager):
        """TC-PV002: 创建角色"""
        new_role = Role(
            'custom_role',
            '自定义角色',
            '自定义角色描述',
            Permission.READ.value
        )
        
        result = permission_manager.create_role(new_role)
        assert result is True
        assert 'custom_role' in permission_manager.roles
    
    def test_create_identity(self, permission_manager):
        """TC-PV003: 创建身份"""
        identity = Identity(
            'user-001',
            '测试用户',
            'user',
            [],
            time.time(),
            0
        )
        
        result = permission_manager.create_identity(identity)
        assert result is True
        assert 'user-001' in permission_manager.identities
    
    def test_assign_role(self, permission_manager):
        """TC-PV004: 分配角色"""
        # 创建身份
        identity = Identity('user-002', '测试用户', 'user', [], time.time(), 0)
        permission_manager.create_identity(identity)
        
        # 分配角色
        result = permission_manager.assign_role('user-002', 'user')
        assert result is True
        
        identity = permission_manager.get_identity('user-002')
        assert 'user' in identity.roles
    
    def test_check_access_allowed(self, permission_manager):
        """TC-PV005: 检查访问权限（允许）"""
        # 创建管理员身份
        identity = Identity('admin-001', '管理员', 'user', ['admin'], time.time(), 0)
        permission_manager.create_identity(identity)
        
        # 检查权限
        request = AccessRequest(
            'admin-001',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.READ
        )
        
        decision = permission_manager.check_access(request)
        assert decision.allowed is True
    
    def test_check_access_denied(self, permission_manager):
        """TC-PV006: 检查访问权限（拒绝）"""
        # 创建查看者身份
        identity = Identity('viewer-001', '查看者', 'user', ['viewer'], time.time(), 0)
        permission_manager.create_identity(identity)
        
        # 检查写入权限（应该被拒绝）
        request = AccessRequest(
            'viewer-001',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.WRITE
        )
        
        decision = permission_manager.check_access(request)
        assert decision.allowed is False
    
    def test_is_admin(self, permission_manager):
        """TC-PV007: 检查管理员身份"""
        identity = Identity('admin-002', '管理员', 'user', ['admin'], time.time(), 0)
        permission_manager.create_identity(identity)
        
        assert permission_manager.is_admin('admin-002') is True
        assert permission_manager.is_admin('nonexistent') is False
    
    def test_permission_cache(self, permission_manager):
        """TC-PV008: 权限缓存"""
        identity = Identity('user-003', '测试用户', 'user', ['user'], time.time(), 0)
        permission_manager.create_identity(identity)
        
        # 第一次检查
        request = AccessRequest(
            'user-003',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.READ
        )
        
        decision1 = permission_manager.check_access(request)
        
        # 第二次应该使用缓存
        decision2 = permission_manager.check_access(request)
        
        assert decision1.allowed == decision2.allowed
    
    def test_clear_cache(self, permission_manager):
        """TC-PV009: 清除缓存"""
        identity = Identity('user-004', '测试用户', 'user', ['user'], time.time(), 0)
        permission_manager.create_identity(identity)
        
        # 执行检查填充缓存
        request = AccessRequest(
            'user-004',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.READ
        )
        permission_manager.check_access(request)
        
        # 清除缓存
        permission_manager.clear_cache()
        assert len(permission_manager.cache) == 0
    
    def test_expired_identity(self, permission_manager):
        """TC-PV010: 过期身份"""
        # 创建已过期身份
        identity = Identity(
            'user-005',
            '过期用户',
            'user',
            ['user'],
            time.time() - 3600,
            time.time() - 1800  # 半小时前过期
        )
        permission_manager.create_identity(identity)
        
        request = AccessRequest(
            'user-005',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.READ
        )
        
        decision = permission_manager.check_access(request)
        assert decision.allowed is False
        assert "expired" in decision.reason.lower()


class TestSecurityIntegration:
    """安全集成测试"""
    
    @pytest.fixture
    def full_stack(self):
        """创建完整安全栈"""
        vault = MockZkVault()
        vault.initialize()
        vault.unlock("master-password-123")
        
        hsm = MockHardwareSecurityModule()
        
        pm = PermissionManager()
        
        # 创建测试身份
        identity = Identity('test-user', '测试用户', 'user', ['admin'], time.time(), 0)
        pm.create_identity(identity)
        
        return {'vault': vault, 'hsm': hsm, 'permission_manager': pm}
    
    def test_full_credential_flow(self, full_stack):
        """TC-SI001: 完整凭证流程"""
        vault = full_stack['vault']
        pm = full_stack['permission_manager']
        
        # 1. 检查权限
        has_perm = pm.has_permission(
            'test-user',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.WRITE
        )
        assert has_perm is True
        
        # 2. 存储凭证
        result = vault.store_credential(
            "https://test-service.com",
            "testuser",
            "testpass123"
        )
        assert result is True
        
        # 3. 获取凭证
        credential = vault.get_credential("https://test-service.com")
        assert credential is not None
    
    def test_hsm_key_protection(self, full_stack):
        """TC-SI002: HSM 密钥保护"""
        vault = full_stack['vault']
        hsm = full_stack['hsm']
        
        # 1. 生成 HSM 密钥
        master_key = hsm.generate_key("vault-master-key")
        
        # 2. 使用密钥加密数据
        data = b"sensitive credential data"
        signature = hsm.sign("vault-master-key", data)
        
        # 3. 验证签名
        valid = hsm.verify("vault-master-key", data, signature)
        assert valid is True
    
    def test_permission_enforced_operations(self, full_stack):
        """TC-SI003: 权限强制执行"""
        vault = full_stack['vault']
        pm = full_stack['permission_manager']
        
        # 创建普通用户
        identity = Identity('normal-user', '普通用户', 'user', ['viewer'], time.time(), 0)
        pm.create_identity(identity)
        
        # 检查写入权限（应该被拒绝）
        has_write = pm.has_permission(
            'normal-user',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.WRITE
        )
        assert has_write is False
        
        # 检查读取权限（应该允许）
        has_read = pm.has_permission(
            'normal-user',
            ResourceType.CREDENTIAL,
            'cred-001',
            Permission.READ
        )
        assert has_read is True


# ============================================================================
# 运行测试
# ============================================================================

if __name__ == '__main__':
    pytest.main([__file__, '-v', '--tb=short'])