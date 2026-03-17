"""
PolyVault 同步状态测试
测试同步状态、冲突检测、历史记录
"""

import pytest
from datetime import datetime, timedelta


# 同步状态枚举 (与Dart对应)
class SyncStatus:
    IDLE = 'idle'
    SYNCING = 'syncing'
    SUCCESS = 'success'
    ERROR = 'error'
    OFFLINE = 'offline'


# 同步项目类型
class SyncItemType:
    CREDENTIAL = 'credential'
    NOTE = 'note'
    FILE = 'file'
    SETTING = 'setting'


# 同步动作
class SyncAction:
    UPLOAD = 'upload'
    DOWNLOAD = 'download'
    CONFLICT = 'conflict'
    DELETE = 'delete'


# 冲突解决策略
class ConflictResolution:
    KEEP_LOCAL = 'keep_local'
    KEEP_REMOTE = 'keep_remote'
    KEEP_BOTH = 'keep_both'
    MANUAL = 'manual'


# 同步项目
class SyncItem:
    def __init__(self, id, type, title, local_modified, remote_modified, status):
        self.id = id
        self.type = type
        self.title = title
        self.local_modified = local_modified
        self.remote_modified = remote_modified
        self.status = status

    def has_conflict(self):
        return self.local_modified > self.remote_modified


# 同步冲突
class SyncConflict:
    def __init__(self, id, item_id, item_title, local_content, remote_content, local_modified, remote_modified):
        self.id = id
        self.item_id = item_id
        self.item_title = item_title
        self.local_content = local_content
        self.remote_content = remote_content
        self.local_modified = local_modified
        self.remote_modified = remote_modified


# 同步历史记录
class SyncHistoryItem:
    def __init__(self, id, timestamp, action, item_title, status, error_message=None):
        self.id = id
        self.timestamp = timestamp
        self.action = action
        self.item_title = item_title
        self.status = status
        self.error_message = error_message


# 同步管理器
class SyncManager:
    def __init__(self):
        self.items = []
        self.conflicts = []
        self.history = []
        self.status = SyncStatus.IDLE

    def add_item(self, item):
        self.items.append(item)

    def detect_conflicts(self):
        conflicts = []
        for item in self.items:
            if item.has_conflict():
                conflict = SyncConflict(
                    id=f"conflict_{item.id}",
                    item_id=item.id,
                    item_title=item.title,
                    local_content="local_data",
                    remote_content="remote_data",
                    local_modified=item.local_modified,
                    remote_modified=item.remote_modified,
                )
                conflicts.append(conflict)
        self.conflicts = conflicts
        return conflicts

    def resolve_conflict(self, conflict_id, resolution):
        self.conflicts = [c for c in self.conflicts if c.id != conflict_id]
        return True

    def sync(self):
        self.status = SyncStatus.SYNCING
        # 模拟同步
        self.status = SyncStatus.SUCCESS

    def add_history(self, item):
        self.history.append(item)


# ============ 同步状态测试 ============

class TestSyncStatus:
    """测试同步状态"""

    def test_default_status_is_idle(self):
        manager = SyncManager()
        assert manager.status == SyncStatus.IDLE

    def test_syncing_status(self):
        manager = SyncManager()
        manager.status = SyncStatus.SYNCING
        assert manager.status == SyncStatus.SYNCING

    def test_success_status(self):
        manager = SyncManager()
        manager.status = SyncStatus.SUCCESS
        assert manager.status == SyncStatus.SUCCESS

    def test_error_status(self):
        manager = SyncManager()
        manager.status = SyncStatus.ERROR
        assert manager.status == SyncStatus.ERROR

    def test_offline_status(self):
        manager = SyncManager()
        manager.status = SyncStatus.OFFLINE
        assert manager.status == SyncStatus.OFFLINE


# ============ 同步项目测试 ============

class TestSyncItems:
    """测试同步项目"""

    def test_create_sync_item(self):
        now = datetime.now()
        item = SyncItem('1', SyncItemType.CREDENTIAL, 'GitHub', now, now, SyncStatus.SUCCESS)
        assert item.id == '1'
        assert item.type == SyncItemType.CREDENTIAL
        assert item.title == 'GitHub'

    def test_no_conflict_when_local_older(self):
        local = datetime.now() - timedelta(hours=2)
        remote = datetime.now() - timedelta(hours=1)
        item = SyncItem('1', SyncItemType.NOTE, 'Test', local, remote, SyncStatus.SUCCESS)
        assert item.has_conflict() is False

    def test_conflict_when_local_newer(self):
        local = datetime.now() - timedelta(hours=1)
        remote = datetime.now() - timedelta(hours=2)
        item = SyncItem('1', SyncItemType.NOTE, 'Test', local, remote, SyncStatus.SUCCESS)
        assert item.has_conflict() is True

    def test_credential_type(self):
        item = SyncItem('1', SyncItemType.CREDENTIAL, 'API Key', datetime.now(), datetime.now(), SyncStatus.SUCCESS)
        assert item.type == SyncItemType.CREDENTIAL


# ============ 冲突检测测试 ============

class TestConflictDetection:
    """测试冲突检测"""

    def test_detect_no_conflicts(self):
        manager = SyncManager()
        old_time = datetime.now() - timedelta(hours=2)
        new_time = datetime.now() - timedelta(hours=1)
        item = SyncItem('1', SyncItemType.NOTE, 'Test', old_time, new_time, SyncStatus.SUCCESS)
        manager.add_item(item)
        
        conflicts = manager.detect_conflicts()
        assert len(conflicts) == 0

    def test_detect_single_conflict(self):
        manager = SyncManager()
        local = datetime.now() - timedelta(hours=1)
        remote = datetime.now() - timedelta(hours=2)
        item = SyncItem('1', SyncItemType.NOTE, 'Test', local, remote, SyncStatus.SUCCESS)
        manager.add_item(item)
        
        conflicts = manager.detect_conflicts()
        assert len(conflicts) == 1

    def test_detect_multiple_conflicts(self):
        manager = SyncManager()
        # 添加多个有冲突的项目
        for i in range(3):
            local = datetime.now() - timedelta(hours=i+1)
            remote = datetime.now() - timedelta(hours=i+2)
            item = SyncItem(str(i), SyncItemType.NOTE, f'Test{i}', local, remote, SyncStatus.SUCCESS)
            manager.add_item(item)
        
        conflicts = manager.detect_conflicts()
        assert len(conflicts) == 3

    def test_conflict_contains_all_info(self):
        manager = SyncManager()
        local = datetime.now() - timedelta(hours=1)
        remote = datetime.now() - timedelta(hours=2)
        item = SyncItem('1', SyncItemType.CREDENTIAL, 'API Key', local, remote, SyncStatus.SUCCESS)
        manager.add_item(item)
        
        conflicts = manager.detect_conflicts()
        assert len(conflicts) == 1
        assert conflicts[0].item_title == 'API Key'
        assert conflicts[0].local_content is not None
        assert conflicts[0].remote_content is not None


# ============ 冲突解决测试 ============

class TestConflictResolution:
    """测试冲突解决"""

    def test_resolve_conflict_keep_local(self):
        manager = SyncManager()
        local = datetime.now() - timedelta(hours=1)
        remote = datetime.now() - timedelta(hours=2)
        item = SyncItem('1', SyncItemType.CREDENTIAL, 'Test', local, remote, SyncStatus.SUCCESS)
        manager.add_item(item)
        manager.detect_conflicts()
        
        result = manager.resolve_conflict('conflict_1', ConflictResolution.KEEP_LOCAL)
        assert result is True
        assert len(manager.conflicts) == 0

    def test_resolve_conflict_keep_remote(self):
        manager = SyncManager()
        local = datetime.now() - timedelta(hours=1)
        remote = datetime.now() - timedelta(hours=2)
        item = SyncItem('1', SyncItemType.CREDENTIAL, 'Test', local, remote, SyncStatus.SUCCESS)
        manager.add_item(item)
        manager.detect_conflicts()
        
        result = manager.resolve_conflict('conflict_1', ConflictResolution.KEEP_REMOTE)
        assert result is True
        assert len(manager.conflicts) == 0

    def test_resolve_conflict_keep_both(self):
        manager = SyncManager()
        local = datetime.now() - timedelta(hours=1)
        remote = datetime.now() - timedelta(hours=2)
        item = SyncItem('1', SyncItemType.CREDENTIAL, 'Test', local, remote, SyncStatus.SUCCESS)
        manager.add_item(item)
        manager.detect_conflicts()
        
        result = manager.resolve_conflict('conflict_1', ConflictResolution.KEEP_BOTH)
        assert result is True


# ============ 同步历史测试 ============

class TestSyncHistory:
    """测试同步历史"""

    def test_add_history_item(self):
        manager = SyncManager()
        history_item = SyncHistoryItem(
            'h1', datetime.now(), SyncAction.UPLOAD, 'Test', SyncStatus.SUCCESS
        )
        manager.add_history(history_item)
        assert len(manager.history) == 1

    def test_history_contains_upload_action(self):
        manager = SyncManager()
        history_item = SyncHistoryItem(
            'h1', datetime.now(), SyncAction.UPLOAD, 'Test', SyncStatus.SUCCESS
        )
        manager.add_history(history_item)
        assert manager.history[0].action == SyncAction.UPLOAD

    def test_history_contains_download_action(self):
        manager = SyncManager()
        history_item = SyncHistoryItem(
            'h1', datetime.now(), SyncAction.DOWNLOAD, 'Test', SyncStatus.SUCCESS
        )
        manager.add_history(history_item)
        assert manager.history[0].action == SyncAction.DOWNLOAD

    def test_history_contains_error_status(self):
        manager = SyncManager()
        history_item = SyncHistoryItem(
            'h1', datetime.now(), SyncAction.CONFLICT, 'Test', SyncStatus.ERROR, 'Conflict detected'
        )
        manager.add_history(history_item)
        assert manager.history[0].status == SyncStatus.ERROR
        assert manager.history[0].error_message == 'Conflict detected'

    def test_multiple_history_items(self):
        manager = SyncManager()
        for i in range(5):
            item = SyncHistoryItem(
                f'h{i}', datetime.now(), SyncAction.UPLOAD, f'Test{i}', SyncStatus.SUCCESS
            )
            manager.add_history(item)
        assert len(manager.history) == 5


# ============ 同步流程测试 ============

class TestSyncProcess:
    """测试同步流程"""

    def test_sync_changes_status(self):
        manager = SyncManager()
        manager.sync()
        assert manager.status == SyncStatus.SUCCESS

    def test_sync_with_conflicts(self):
        manager = SyncManager()
        # 添加有冲突的项目
        local = datetime.now() - timedelta(hours=1)
        remote = datetime.now() - timedelta(hours=2)
        item = SyncItem('1', SyncItemType.NOTE, 'Test', local, remote, SyncStatus.SUCCESS)
        manager.add_item(item)
        
        # 检测冲突
        conflicts = manager.detect_conflicts()
        assert len(conflicts) == 1
        
        # 解决冲突
        manager.resolve_conflict('conflict_1', ConflictResolution.KEEP_LOCAL)
        
        # 同步
        manager.sync()
        assert manager.status == SyncStatus.SUCCESS


# ============ 数据模型测试 ============

class TestSyncModels:
    """测试数据模型"""

    def test_sync_item_attributes(self):
        now = datetime.now()
        item = SyncItem(
            'test-id',
            SyncItemType.FILE,
            'Test File',
            now,
            now,
            SyncStatus.SUCCESS
        )
        assert item.id == 'test-id'
        assert item.type == SyncItemType.FILE
        assert item.title == 'Test File'
        assert item.status == SyncStatus.SUCCESS

    def test_conflict_attributes(self):
        now = datetime.now()
        conflict = SyncConflict(
            'c1', 'item-1', 'Test Item', 'local', 'remote', now, now
        )
        assert conflict.id == 'c1'
        assert conflict.item_id == 'item-1'
        assert conflict.local_content == 'local'
        assert conflict.remote_content == 'remote'

    def test_history_item_attributes(self):
        now = datetime.now()
        history = SyncHistoryItem('h1', now, SyncAction.UPLOAD, 'Test', SyncStatus.SUCCESS, 'No error')
        assert history.id == 'h1'
        assert history.action == SyncAction.UPLOAD
        assert history.status == SyncStatus.SUCCESS
        assert history.error_message == 'No error'


# 运行测试
if __name__ == '__main__':
    pytest.main([__file__, '-v'])