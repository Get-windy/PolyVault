"""
PolyVault 凭证管理测试
测试凭证列表、筛选功能、批量操作
"""

import pytest
from datetime import datetime, timedelta


# 凭证类型枚举
class CredentialType:
    WEBSITE = 'website'
    APP = 'app'
    API = 'api'
    DATABASE = 'database'
    WIFI = 'wifi'
    BANK = 'bank'
    CARD = 'card'
    NOTE = 'note'
    OTHER = 'other'


# 凭证数据模型
class Credential:
    def __init__(self, id, title, credential_type, username=None, email=None, phone=None, url=None,
                 category=None, tags=None, created_at=None, modified_at=None, last_accessed_at=None,
                 is_favorite=False):
        self.id = id
        self.title = title
        self.type = credential_type
        self.username = username
        self.email = email
        self.phone = phone
        self.url = url
        self.category = category
        self.tags = tags or []
        self.created_at = created_at or datetime.now()
        self.modified_at = modified_at
        self.last_accessed_at = last_accessed_at
        self.is_favorite = is_favorite

    def copy_with(self, **kwargs):
        return Credential(
            id=kwargs.get('id', self.id),
            title=kwargs.get('title', self.title),
            credential_type=kwargs.get('type', self.type),
            username=kwargs.get('username', self.username),
            email=kwargs.get('email', self.email),
            phone=kwargs.get('phone', self.phone),
            url=kwargs.get('url', self.url),
            category=kwargs.get('category', self.category),
            tags=kwargs.get('tags', self.tags),
            created_at=kwargs.get('created_at', self.created_at),
            modified_at=kwargs.get('modified_at', self.modified_at),
            last_accessed_at=kwargs.get('last_accessed_at', self.last_accessed_at),
            is_favorite=kwargs.get('is_favorite', self.is_favorite),
        )


# 凭证管理器
class CredentialManager:
    def __init__(self):
        self.credentials = []
        self.selected_ids = set()

    def add(self, credential):
        self.credentials.append(credential)

    def remove(self, credential_id):
        self.credentials = [c for c in self.credentials if c.id != credential_id]

    def update(self, credential_id, **kwargs):
        for i, c in enumerate(self.credentials):
            if c.id == credential_id:
                self.credentials[i] = c.copy_with(**kwargs)

    def toggle_favorite(self, credential_id):
        for i, c in enumerate(self.credentials):
            if c.id == credential_id:
                self.credentials[i] = c.copy_with(is_favorite=not c.is_favorite)

    def select(self, credential_id):
        self.selected_ids.add(credential_id)

    def deselect(self, credential_id):
        self.selected_ids.discard(credential_id)

    def toggle_selection(self, credential_id):
        if credential_id in self.selected_ids:
            self.selected_ids.discard(credential_id)
        else:
            self.selected_ids.add(credential_id)

    def select_all(self):
        self.selected_ids = {c.id for c in self.credentials}

    def clear_selection(self):
        self.selected_ids.clear()

    def get_selected(self):
        return [c for c in self.credentials if c.id in self.selected_ids]

    def get_by_type(self, credential_type):
        return [c for c in self.credentials if c.type == credential_type]

    def get_favorites(self):
        return [c for c in self.credentials if c.is_favorite]

    def search(self, query):
        query = query.lower()
        return [c for c in self.credentials if
                query in c.title.lower() or
                (c.username and query in c.username.lower()) or
                (c.email and query in c.email.lower())]

    def delete_selected(self):
        self.credentials = [c for c in self.credentials if c.id not in self.selected_ids]
        self.clear_selection()


class TestCredentialModel:
    """测试凭证数据模型"""

    def test_create_credential(self):
        cred = Credential(
            id='1',
            title='GitHub',
            credential_type=CredentialType.WEBSITE,
            username='user@example.com',
            category='开发',
            tags=['代码', '重要'],
            is_favorite=True,
        )
        assert cred.id == '1'
        assert cred.title == 'GitHub'
        assert cred.type == CredentialType.WEBSITE
        assert cred.is_favorite is True

    def test_copy_with(self):
        original = Credential(
            id='1',
            title='原标题',
            credential_type=CredentialType.APP,
            is_favorite=False,
        )
        copied = original.copy_with(title='新标题', is_favorite=True)

        assert copied.id == '1'
        assert copied.title == '新标题'
        assert copied.is_favorite is True


class TestCredentialManager:
    """测试凭证管理器"""

    def setup_method(self):
        self.manager = CredentialManager()

    def test_add_credential(self):
        cred = Credential(id='1', title='测试', credential_type=CredentialType.WEBSITE)
        self.manager.add(cred)
        assert len(self.manager.credentials) == 1

    def test_remove_credential(self):
        cred = Credential(id='1', title='测试', credential_type=CredentialType.WEBSITE)
        self.manager.add(cred)
        self.manager.remove('1')
        assert len(self.manager.credentials) == 0

    def test_toggle_favorite(self):
        cred = Credential(id='1', title='测试', credential_type=CredentialType.WEBSITE, is_favorite=False)
        self.manager.add(cred)

        self.manager.toggle_favorite('1')
        assert self.manager.credentials[0].is_favorite is True

        self.manager.toggle_favorite('1')
        assert self.manager.credentials[0].is_favorite is False


class TestSelection:
    """测试选择功能"""

    def setup_method(self):
        self.manager = CredentialManager()
        self.manager.credentials = [
            Credential(id='1', title='C1', credential_type=CredentialType.WEBSITE),
            Credential(id='2', title='C2', credential_type=CredentialType.APP),
            Credential(id='3', title='C3', credential_type=CredentialType.API),
        ]

    def test_select_single(self):
        self.manager.select('1')
        assert '1' in self.manager.selected_ids

    def test_toggle_selection(self):
        self.manager.toggle_selection('1')
        assert '1' in self.manager.selected_ids

        self.manager.toggle_selection('1')
        assert '1' not in self.manager.selected_ids

    def test_select_all(self):
        self.manager.select_all()
        assert len(self.manager.selected_ids) == 3

    def test_clear_selection(self):
        self.manager.select_all()
        self.manager.clear_selection()
        assert len(self.manager.selected_ids) == 0

    def test_get_selected(self):
        self.manager.select('1')
        self.manager.select('3')
        selected = self.manager.get_selected()
        assert len(selected) == 2


class TestFiltering:
    """测试筛选功能"""

    def setup_method(self):
        self.manager = CredentialManager()
        self.manager.credentials = [
            Credential('1', 'GitHub', CredentialType.WEBSITE, is_favorite=True),
            Credential('2', 'Slack', CredentialType.APP, is_favorite=True),
            Credential('3', 'AWS', CredentialType.API, is_favorite=False),
            Credential('4', 'Home WiFi', CredentialType.WIFI, is_favorite=False),
            Credential('5', '银行', CredentialType.BANK, is_favorite=True),
        ]

    def test_filter_by_type(self):
        websites = self.manager.get_by_type(CredentialType.WEBSITE)
        assert len(websites) == 1
        assert websites[0].title == 'GitHub'

    def test_filter_favorites(self):
        favorites = self.manager.get_favorites()
        assert len(favorites) == 3

    def test_search_by_title(self):
        results = self.manager.search('github')
        assert len(results) == 1

    def test_search_by_username(self):
        creds = [
            Credential('1', 'GitHub', CredentialType.WEBSITE, username='user1'),
            Credential('2', 'GitLab', CredentialType.WEBSITE, username='user2'),
        ]
        m = CredentialManager()
        m.credentials = creds

        results = m.search('user1')
        assert len(results) == 1


class TestBatchOperations:
    """测试批量操作"""

    def setup_method(self):
        self.manager = CredentialManager()
        self.manager.credentials = [
            Credential(id='1', title='C1', credential_type=CredentialType.WEBSITE),
            Credential(id='2', title='C2', credential_type=CredentialType.APP),
            Credential(id='3', title='C3', credential_type=CredentialType.API),
        ]

    def test_delete_selected(self):
        self.manager.select('1')
        self.manager.select('2')
        self.manager.delete_selected()

        assert len(self.manager.credentials) == 1
        assert self.manager.credentials[0].id == '3'

    def test_select_and_clear(self):
        self.manager.select_all()
        assert len(self.manager.selected_ids) == 3

        self.manager.clear_selection()
        assert len(self.manager.selected_ids) == 0


class TestCredentialTypes:
    """测试凭证类型"""

    def test_all_types(self):
        types = [
            CredentialType.WEBSITE,
            CredentialType.APP,
            CredentialType.API,
            CredentialType.DATABASE,
            CredentialType.WIFI,
            CredentialType.BANK,
            CredentialType.CARD,
            CredentialType.NOTE,
            CredentialType.OTHER,
        ]
        assert len(types) == 9

    def test_type_to_icon_mapping(self):
        type_config = {
            CredentialType.WEBSITE: 'language',
            CredentialType.APP: 'apps',
            CredentialType.API: 'api',
            CredentialType.WIFI: 'wifi',
            CredentialType.BANK: 'account_balance',
        }
        assert type_config[CredentialType.WEBSITE] == 'language'
        assert type_config[CredentialType.BANK] == 'account_balance'


class TestTimestamp:
    """测试时间戳"""

    def test_last_accessed_update(self):
        cred = Credential(
            id='1',
            title='Test',
            credential_type=CredentialType.WEBSITE,
            last_accessed_at=datetime.now() - timedelta(hours=2),
        )

        diff = datetime.now() - cred.last_accessed_at
        assert diff.seconds // 3600 == 2


class TestTagsAndCategory:
    """测试标签和分类"""

    def test_add_tags(self):
        cred = Credential(
            id='1',
            title='Test',
            credential_type=CredentialType.WEBSITE,
            tags=['工作', '重要'],
        )
        assert len(cred.tags) == 2

    def test_set_category(self):
        cred = Credential(
            id='1',
            title='Test',
            credential_type=CredentialType.WEBSITE,
            category='开发',
        )
        assert cred.category == '开发'


# 运行所有测试
if __name__ == '__main__':
    pytest.main([__file__, '-v'])