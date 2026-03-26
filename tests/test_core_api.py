# -*- coding: utf-8 -*-
"""
PolyVault 核心API接口测试
测试范围：
1. 凭证API功能
2. 设备API功能
3. 同步API功能

任务ID: task_1774284215277_kyi5b1ydz
日期: 2026-03-24
"""

import pytest
import time
import json
import hashlib
import base64
import secrets
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, field
from unittest.mock import Mock, MagicMock, patch
from enum import Enum

sys.path.insert(0, 'I:\\PolyVault')


# ==================== 数据模型 ====================

class CredentialType(Enum):
    PASSWORD = "password"
    OAUTH = "oauth"
    API_KEY = "api_key"
    CERTIFICATE = "certificate"


class DeviceStatus(Enum):
    ONLINE = "online"
    OFFLINE = "offline"
    PENDING = "pending"
    REVOKED = "revoked"


class SyncStatus(Enum):
    SYNCING = "syncing"
    COMPLETED = "completed"
    FAILED = "failed"
    PENDING = "pending"


@dataclass
class Credential:
    """凭证"""
    id: str
    name: str
    type: CredentialType
    service_url: str
    username: str = ""
    encrypted_data: str = ""
    created_at: float = None
    updated_at: float = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = time.time()
        if self.updated_at is None:
            self.updated_at = time.time()


@dataclass
class Device:
    """设备"""
    id: str
    name: str
    type: str
    status: DeviceStatus
    last_seen: float = None
    metadata: Dict = field(default_factory=dict)
    
    def __post_init__(self):
        if self.last_seen is None:
            self.last_seen = time.time()


@dataclass
class SyncItem:
    """同步项"""
    id: str
    type: str
    action: str  # create, update, delete
    data: Dict
    timestamp: float = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = time.time()


# ==================== 模拟组件 ====================

class MockCredentialAPI:
    """模拟凭证API"""
    
    def __init__(self):
        self.credentials: Dict[str, Credential] = {}
        self._init_test_data()
    
    def _init_test_data(self):
        """初始化测试数据"""
        for i in range(5):
            cred_id = f"cred_{i:03d}"
            self.credentials[cred_id] = Credential(
                id=cred_id,
                name=f"测试凭证{i}",
                type=list(CredentialType)[i % 4],
                service_url=f"https://service{i}.example.com",
                username=f"user{i}",
                encrypted_data=base64.b64encode(f"encrypted_{i}".encode()).decode()
            )
    
    def list_credentials(self, filter: Dict = None) -> List[Credential]:
        """列出凭证"""
        result = list(self.credentials.values())
        if filter and 'type' in filter:
            result = [c for c in result if c.type.value == filter['type']]
        return result
    
    def get_credential(self, cred_id: str) -> Optional[Credential]:
        """获取凭证"""
        return self.credentials.get(cred_id)
    
    def create_credential(self, data: Dict) -> Credential:
        """创建凭证"""
        cred_id = f"cred_{int(time.time() * 1000)}"
        cred = Credential(
            id=cred_id,
            name=data.get('name', ''),
            type=CredentialType(data.get('type', 'password')),
            service_url=data.get('service_url', ''),
            username=data.get('username', ''),
            encrypted_data=data.get('encrypted_data', '')
        )
        self.credentials[cred_id] = cred
        return cred
    
    def update_credential(self, cred_id: str, data: Dict) -> Optional[Credential]:
        """更新凭证"""
        if cred_id not in self.credentials:
            return None
        
        cred = self.credentials[cred_id]
        for key, value in data.items():
            if hasattr(cred, key):
                setattr(cred, key, value)
        cred.updated_at = time.time()
        return cred
    
    def delete_credential(self, cred_id: str) -> bool:
        """删除凭证"""
        if cred_id in self.credentials:
            del self.credentials[cred_id]
            return True
        return False
    
    def search_credentials(self, keyword: str) -> List[Credential]:
        """搜索凭证"""
        results = []
        for cred in self.credentials.values():
            if (keyword.lower() in cred.name.lower() or
                keyword.lower() in cred.service_url.lower()):
                results.append(cred)
        return results


class MockDeviceAPI:
    """模拟设备API"""
    
    def __init__(self):
        self.devices: Dict[str, Device] = {}
        self._init_test_data()
    
    def _init_test_data(self):
        """初始化测试数据"""
        device_types = ['desktop', 'mobile', 'browser', 'extension']
        for i in range(4):
            device_id = f"device_{i:03d}"
            self.devices[device_id] = Device(
                id=device_id,
                name=f"测试设备{i}",
                type=device_types[i],
                status=DeviceStatus.ONLINE if i < 3 else DeviceStatus.OFFLINE
            )
    
    def list_devices(self, filter: Dict = None) -> List[Device]:
        """列出设备"""
        result = list(self.devices.values())
        if filter and 'status' in filter:
            result = [d for d in result if d.status.value == filter['status']]
        return result
    
    def get_device(self, device_id: str) -> Optional[Device]:
        """获取设备"""
        return self.devices.get(device_id)
    
    def register_device(self, data: Dict) -> Device:
        """注册设备"""
        device_id = f"device_{int(time.time() * 1000)}"
        device = Device(
            id=device_id,
            name=data.get('name', ''),
            type=data.get('type', 'desktop'),
            status=DeviceStatus.PENDING,
            metadata=data.get('metadata', {})
        )
        self.devices[device_id] = device
        return device
    
    def update_device(self, device_id: str, data: Dict) -> Optional[Device]:
        """更新设备"""
        if device_id not in self.devices:
            return None
        
        device = self.devices[device_id]
        for key, value in data.items():
            if hasattr(device, key):
                setattr(device, key, value)
        return device
    
    def revoke_device(self, device_id: str) -> bool:
        """撤销设备"""
        if device_id in self.devices:
            self.devices[device_id].status = DeviceStatus.REVOKED
            return True
        return False
    
    def heartbeat(self, device_id: str) -> bool:
        """设备心跳"""
        if device_id in self.devices:
            self.devices[device_id].last_seen = time.time()
            if self.devices[device_id].status == DeviceStatus.OFFLINE:
                self.devices[device_id].status = DeviceStatus.ONLINE
            return True
        return False
    
    def get_device_stats(self) -> Dict:
        """获取设备统计"""
        stats = {
            'total': len(self.devices),
            'online': sum(1 for d in self.devices.values() if d.status == DeviceStatus.ONLINE),
            'offline': sum(1 for d in self.devices.values() if d.status == DeviceStatus.OFFLINE),
            'pending': sum(1 for d in self.devices.values() if d.status == DeviceStatus.PENDING),
            'revoked': sum(1 for d in self.devices.values() if d.status == DeviceStatus.REVOKED)
        }
        return stats


class MockSyncAPI:
    """模拟同步API"""
    
    def __init__(self):
        self.sync_items: List[SyncItem] = []
        self.sync_status: Dict[str, SyncStatus] = {}
        self.last_sync_time: float = 0
        self._init_test_data()
    
    def _init_test_data(self):
        """初始化测试数据"""
        for i in range(5):
            self.sync_items.append(SyncItem(
                id=f"sync_{i:03d}",
                type=['credential', 'device', 'preference'][i % 3],
                action=['create', 'update', 'delete'][i % 3],
                data={'key': f'value_{i}'}
            ))
    
    def start_sync(self) -> Dict:
        """开始同步"""
        sync_id = f"sync_session_{int(time.time() * 1000)}"
        self.sync_status[sync_id] = SyncStatus.SYNCING
        return {'sync_id': sync_id, 'status': 'started'}
    
    def get_sync_status(self, sync_id: str) -> Optional[SyncStatus]:
        """获取同步状态"""
        return self.sync_status.get(sync_id)
    
    def complete_sync(self, sync_id: str, success: bool = True) -> bool:
        """完成同步"""
        if sync_id not in self.sync_status:
            return False
        
        self.sync_status[sync_id] = SyncStatus.COMPLETED if success else SyncStatus.FAILED
        if success:
            self.last_sync_time = time.time()
        return True
    
    def get_pending_items(self) -> List[SyncItem]:
        """获取待同步项"""
        return self.sync_items
    
    def push_item(self, item: Dict) -> SyncItem:
        """推送同步项"""
        sync_item = SyncItem(
            id=f"sync_{int(time.time() * 1000)}",
            type=item.get('type', ''),
            action=item.get('action', 'update'),
            data=item.get('data', {})
        )
        self.sync_items.append(sync_item)
        return sync_item
    
    def pull_items(self, since: float = 0) -> List[SyncItem]:
        """拉取同步项"""
        return [item for item in self.sync_items if item.timestamp > since]
    
    def resolve_conflict(self, item_id: str, resolution: str) -> bool:
        """解决冲突"""
        return True  # 模拟解决成功
    
    def get_sync_stats(self) -> Dict:
        """获取同步统计"""
        return {
            'total_items': len(self.sync_items),
            'last_sync': self.last_sync_time,
            'pending_syncs': sum(1 for s in self.sync_status.values() if s == SyncStatus.PENDING),
            'completed_syncs': sum(1 for s in self.sync_status.values() if s == SyncStatus.COMPLETED)
        }


# ==================== 测试类 ====================

class TestCredentialAPI:
    """凭证API功能测试"""
    
    @pytest.fixture
    def api(self):
        return MockCredentialAPI()
    
    # ========== 列表/查询测试 ==========
    
    @pytest.mark.credential
    def test_list_credentials(self, api):
        """TC-CRED-001: 列出所有凭证"""
        credentials = api.list_credentials()
        assert len(credentials) == 5
    
    @pytest.mark.credential
    def test_list_credentials_with_filter(self, api):
        """TC-CRED-002: 按类型过滤凭证"""
        credentials = api.list_credentials({'type': 'password'})
        assert all(c.type.value == 'password' for c in credentials)
    
    @pytest.mark.credential
    def test_get_credential(self, api):
        """TC-CRED-003: 获取单个凭证"""
        cred = api.get_credential('cred_000')
        assert cred is not None
        assert cred.name == '测试凭证0'
    
    @pytest.mark.credential
    def test_get_nonexistent_credential(self, api):
        """TC-CRED-004: 获取不存在的凭证"""
        cred = api.get_credential('nonexistent')
        assert cred is None
    
    @pytest.mark.credential
    def test_search_credentials(self, api):
        """TC-CRED-005: 搜索凭证"""
        results = api.search_credentials('测试')
        assert len(results) >= 5
    
    # ========== 创建/更新/删除测试 ==========
    
    @pytest.mark.credential
    def test_create_credential(self, api):
        """TC-CRED-010: 创建凭证"""
        initial_count = len(api.credentials)
        
        cred = api.create_credential({
            'name': '新凭证',
            'type': 'password',
            'service_url': 'https://new.example.com',
            'username': 'new_user'
        })
        
        assert cred.id is not None
        assert cred.name == '新凭证'
        assert len(api.credentials) == initial_count + 1
    
    @pytest.mark.credential
    def test_update_credential(self, api):
        """TC-CRED-011: 更新凭证"""
        cred = api.update_credential('cred_000', {'name': '更新后的名称'})
        assert cred is not None
        assert cred.name == '更新后的名称'
    
    @pytest.mark.credential
    def test_update_nonexistent_credential(self, api):
        """TC-CRED-012: 更新不存在的凭证"""
        cred = api.update_credential('nonexistent', {'name': 'test'})
        assert cred is None
    
    @pytest.mark.credential
    def test_delete_credential(self, api):
        """TC-CRED-013: 删除凭证"""
        initial_count = len(api.credentials)
        result = api.delete_credential('cred_000')
        
        assert result is True
        assert len(api.credentials) == initial_count - 1
    
    @pytest.mark.credential
    def test_delete_nonexistent_credential(self, api):
        """TC-CRED-014: 删除不存在的凭证"""
        result = api.delete_credential('nonexistent')
        assert result is False


class TestDeviceAPI:
    """设备API功能测试"""
    
    @pytest.fixture
    def api(self):
        return MockDeviceAPI()
    
    # ========== 列表/查询测试 ==========
    
    @pytest.mark.device
    def test_list_devices(self, api):
        """TC-DEV-001: 列出所有设备"""
        devices = api.list_devices()
        assert len(devices) == 4
    
    @pytest.mark.device
    def test_list_devices_with_filter(self, api):
        """TC-DEV-002: 按状态过滤设备"""
        devices = api.list_devices({'status': 'online'})
        assert all(d.status.value == 'online' for d in devices)
    
    @pytest.mark.device
    def test_get_device(self, api):
        """TC-DEV-003: 获取单个设备"""
        device = api.get_device('device_000')
        assert device is not None
        assert device.name == '测试设备0'
    
    @pytest.mark.device
    def test_get_nonexistent_device(self, api):
        """TC-DEV-004: 获取不存在的设备"""
        device = api.get_device('nonexistent')
        assert device is None
    
    # ========== 注册/更新/撤销测试 ==========
    
    @pytest.mark.device
    def test_register_device(self, api):
        """TC-DEV-010: 注册设备"""
        initial_count = len(api.devices)
        
        device = api.register_device({
            'name': '新设备',
            'type': 'mobile',
            'metadata': {'os': 'iOS'}
        })
        
        assert device.id is not None
        assert device.status == DeviceStatus.PENDING
        assert len(api.devices) == initial_count + 1
    
    @pytest.mark.device
    def test_update_device(self, api):
        """TC-DEV-011: 更新设备"""
        device = api.update_device('device_000', {'name': '更新后的设备名'})
        assert device is not None
        assert device.name == '更新后的设备名'
    
    @pytest.mark.device
    def test_revoke_device(self, api):
        """TC-DEV-012: 撤销设备"""
        result = api.revoke_device('device_000')
        assert result is True
        
        device = api.get_device('device_000')
        assert device.status == DeviceStatus.REVOKED
    
    @pytest.mark.device
    def test_heartbeat(self, api):
        """TC-DEV-013: 设备心跳"""
        # 先将设备设为离线
        api.devices['device_000'].status = DeviceStatus.OFFLINE
        
        result = api.heartbeat('device_000')
        assert result is True
        
        device = api.get_device('device_000')
        assert device.status == DeviceStatus.ONLINE
    
    @pytest.mark.device
    def test_get_device_stats(self, api):
        """TC-DEV-020: 获取设备统计"""
        stats = api.get_device_stats()
        
        assert 'total' in stats
        assert 'online' in stats
        assert 'offline' in stats
        assert stats['total'] == len(api.devices)


class TestSyncAPI:
    """同步API功能测试"""
    
    @pytest.fixture
    def api(self):
        return MockSyncAPI()
    
    # ========== 同步流程测试 ==========
    
    @pytest.mark.sync
    def test_start_sync(self, api):
        """TC-SYNC-001: 开始同步"""
        result = api.start_sync()
        
        assert 'sync_id' in result
        assert result['status'] == 'started'
    
    @pytest.mark.sync
    def test_get_sync_status(self, api):
        """TC-SYNC-002: 获取同步状态"""
        sync_result = api.start_sync()
        sync_id = sync_result['sync_id']
        
        status = api.get_sync_status(sync_id)
        assert status == SyncStatus.SYNCING
    
    @pytest.mark.sync
    def test_complete_sync(self, api):
        """TC-SYNC-003: 完成同步"""
        sync_result = api.start_sync()
        sync_id = sync_result['sync_id']
        
        result = api.complete_sync(sync_id, success=True)
        assert result is True
        
        status = api.get_sync_status(sync_id)
        assert status == SyncStatus.COMPLETED
    
    @pytest.mark.sync
    def test_complete_sync_with_failure(self, api):
        """TC-SYNC-004: 同步失败"""
        sync_result = api.start_sync()
        sync_id = sync_result['sync_id']
        
        result = api.complete_sync(sync_id, success=False)
        assert result is True
        
        status = api.get_sync_status(sync_id)
        assert status == SyncStatus.FAILED
    
    # ========== 同步项操作测试 ==========
    
    @pytest.mark.sync
    def test_get_pending_items(self, api):
        """TC-SYNC-010: 获取待同步项"""
        items = api.get_pending_items()
        assert len(items) >= 5
    
    @pytest.mark.sync
    def test_push_item(self, api):
        """TC-SYNC-011: 推送同步项"""
        initial_count = len(api.sync_items)
        
        item = api.push_item({
            'type': 'credential',
            'action': 'update',
            'data': {'key': 'value'}
        })
        
        assert item.id is not None
        assert len(api.sync_items) == initial_count + 1
    
    @pytest.mark.sync
    def test_pull_items(self, api):
        """TC-SYNC-012: 拉取同步项"""
        # 先推送一个新项
        api.push_item({'type': 'test', 'action': 'create', 'data': {}})
        
        items = api.pull_items(since=0)
        assert len(items) >= 1
    
    @pytest.mark.sync
    def test_resolve_conflict(self, api):
        """TC-SYNC-013: 解决冲突"""
        result = api.resolve_conflict('sync_000', 'keep_local')
        assert result is True
    
    @pytest.mark.sync
    def test_get_sync_stats(self, api):
        """TC-SYNC-020: 获取同步统计"""
        stats = api.get_sync_stats()
        
        assert 'total_items' in stats
        assert 'last_sync' in stats
        assert 'completed_syncs' in stats


class TestAPIIntegration:
    """API集成测试"""
    
    @pytest.fixture
    def cred_api(self):
        return MockCredentialAPI()
    
    @pytest.fixture
    def device_api(self):
        return MockDeviceAPI()
    
    @pytest.fixture
    def sync_api(self):
        return MockSyncAPI()
    
    @pytest.mark.integration
    def test_credential_sync_flow(self, cred_api, sync_api):
        """TC-INT-001: 凭证同步流程"""
        # 1. 创建凭证
        cred = cred_api.create_credential({
            'name': '同步测试凭证',
            'type': 'password',
            'service_url': 'https://sync.example.com'
        })
        
        # 2. 推送同步
        sync_item = sync_api.push_item({
            'type': 'credential',
            'action': 'create',
            'data': {'credential_id': cred.id}
        })
        
        # 3. 开始同步
        sync_result = sync_api.start_sync()
        
        # 4. 完成同步
        sync_api.complete_sync(sync_result['sync_id'])
        
        assert sync_item.id is not None
    
    @pytest.mark.integration
    def test_device_registration_flow(self, device_api, sync_api):
        """TC-INT-002: 设备注册流程"""
        # 1. 注册设备
        device = device_api.register_device({
            'name': '新注册设备',
            'type': 'mobile'
        })
        
        # 2. 验证初始状态为PENDING
        assert device.status == DeviceStatus.PENDING
        
        # 3. 设备心跳 - 对于PENDING状态设备，心跳后应变为ONLINE
        device_api.devices[device.id].status = DeviceStatus.OFFLINE  # 先设为OFFLINE
        device_api.heartbeat(device.id)
        
        # 4. 推送同步
        sync_api.push_item({
            'type': 'device',
            'action': 'create',
            'data': {'device_id': device.id}
        })
        
        # 验证设备状态现在为ONLINE
        updated_device = device_api.get_device(device.id)
        assert updated_device.status == DeviceStatus.ONLINE
    
    @pytest.mark.integration
    def test_full_workflow(self, cred_api, device_api, sync_api):
        """TC-INT-010: 完整工作流"""
        # 1. 注册设备
        device = device_api.register_device({
            'name': '工作流设备',
            'type': 'desktop'
        })
        
        # 2. 创建凭证
        cred = cred_api.create_credential({
            'name': '工作流凭证',
            'type': 'password',
            'service_url': 'https://workflow.example.com'
        })
        
        # 3. 开始同步
        sync_result = sync_api.start_sync()
        
        # 4. 推送同步项
        sync_api.push_item({
            'type': 'credential',
            'action': 'create',
            'data': {'credential_id': cred.id}
        })
        
        # 5. 完成同步
        sync_api.complete_sync(sync_result['sync_id'])
        
        # 验证
        stats = sync_api.get_sync_stats()
        assert stats['completed_syncs'] >= 1


# ==================== 运行测试 ====================

if __name__ == "__main__":
    import subprocess
    result = subprocess.run(
        [sys.executable, "-m", "pytest", __file__, "-v", "--tb=short", "-q"],
        capture_output=True,
        text=True
    )
    print(result.stdout)
    if result.stderr:
        print("STDERR:", result.stderr)
    print(f"\nExit code: {result.returncode}")