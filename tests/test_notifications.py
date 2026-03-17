"""
PolyVault 通知中心测试
测试通知列表、通知详情、操作按钮功能
"""

import pytest
from datetime import datetime, timedelta


# 通知类型枚举
class NotificationType:
    SYSTEM = 'system'
    SECURITY = 'security'
    DEVICE = 'device'
    MESSAGE = 'message'
    BACKUP = 'backup'
    SYNC = 'sync'


# 通知数据模型
class Notification:
    def __init__(self, id, type, title, content, timestamp, is_read=False):
        self.id = id
        self.type = type
        self.title = title
        self.content = content
        self.timestamp = timestamp
        self.is_read = is_read

    def copy_with(self, **kwargs):
        return Notification(
            id=kwargs.get('id', self.id),
            type=kwargs.get('type', self.type),
            title=kwargs.get('title', self.title),
            content=kwargs.get('content', self.content),
            timestamp=kwargs.get('timestamp', self.timestamp),
            is_read=kwargs.get('is_read', self.is_read),
        )


# 通知列表管理器
class NotificationManager:
    def __init__(self):
        self.notifications = []

    def add(self, notification):
        self.notifications.append(notification)

    def remove(self, notification_id):
        self.notifications = [n for n in self.notifications if n.id != notification_id]

    def mark_as_read(self, notification_id):
        for n in self.notifications:
            if n.id == notification_id:
                self.notifications[self.notifications.index(n)] = n.copy_with(is_read=True)

    def mark_all_as_read(self):
        self.notifications = [
            n.copy_with(is_read=True) for n in self.notifications
        ]

    def get_unread_count(self):
        return sum(1 for n in self.notifications if not n.is_read)

    def get_by_type(self, notification_type):
        return [n for n in self.notifications if n.type == notification_type]

    def clear(self):
        self.notifications = []


class TestNotificationModel:
    """测试通知数据模型"""

    def test_create_notification(self):
        notification = Notification(
            id='1',
            type=NotificationType.SECURITY,
            title='测试通知',
            content='这是测试内容',
            timestamp=datetime.now(),
            is_read=False
        )
        assert notification.id == '1'
        assert notification.type == NotificationType.SECURITY
        assert notification.title == '测试通知'
        assert notification.is_read is False

    def test_copy_with(self):
        original = Notification(
            id='1',
            type=NotificationType.SYSTEM,
            title='原始标题',
            content='原始内容',
            timestamp=datetime.now(),
            is_read=False
        )
        copied = original.copy_with(title='新标题', is_read=True)
        
        assert copied.id == '1'  # 未改变
        assert copied.title == '新标题'  # 已改变
        assert copied.is_read is True  # 已改变
        assert copied.content == '原始内容'  # 未改变

    def test_notification_types(self):
        types = [
            NotificationType.SYSTEM,
            NotificationType.SECURITY,
            NotificationType.DEVICE,
            NotificationType.MESSAGE,
            NotificationType.BACKUP,
            NotificationType.SYNC,
        ]
        assert len(types) == 6


class TestNotificationManager:
    """测试通知管理器"""

    def setup_method(self):
        self.manager = NotificationManager()

    def test_add_notification(self):
        notification = Notification(
            id='1',
            type=NotificationType.SYSTEM,
            title='系统通知',
            content='系统更新可用',
            timestamp=datetime.now()
        )
        self.manager.add(notification)
        assert len(self.manager.notifications) == 1

    def test_remove_notification(self):
        notification = Notification(
            id='1',
            type=NotificationType.SYSTEM,
            title='系统通知',
            content='内容',
            timestamp=datetime.now()
        )
        self.manager.add(notification)
        assert len(self.manager.notifications) == 1
        
        self.manager.remove('1')
        assert len(self.manager.notifications) == 0

    def test_mark_as_read(self):
        notification = Notification(
            id='1',
            type=NotificationType.SECURITY,
            title='安全提醒',
            content='新设备登录',
            timestamp=datetime.now(),
            is_read=False
        )
        self.manager.add(notification)
        
        assert self.manager.get_unread_count() == 1
        
        self.manager.mark_as_read('1')
        
        assert self.manager.notifications[0].is_read is True
        assert self.manager.get_unread_count() == 0

    def test_mark_all_as_read(self):
        notifications = [
            Notification(id='1', type=NotificationType.SYSTEM, title='通知1', content='内容1', timestamp=datetime.now(), is_read=False),
            Notification(id='2', type=NotificationType.SECURITY, title='通知2', content='内容2', timestamp=datetime.now(), is_read=False),
            Notification(id='3', type=NotificationType.DEVICE, title='通知3', content='内容3', timestamp=datetime.now(), is_read=False),
        ]
        for n in notifications:
            self.manager.add(n)
        
        assert self.manager.get_unread_count() == 3
        
        self.manager.mark_all_as_read()
        
        assert self.manager.get_unread_count() == 0

    def test_get_unread_count(self):
        notifications = [
            Notification(id='1', type=NotificationType.SYSTEM, title='通知1', content='内容1', timestamp=datetime.now(), is_read=True),
            Notification(id='2', type=NotificationType.SECURITY, title='通知2', content='内容2', timestamp=datetime.now(), is_read=False),
            Notification(id='3', type=NotificationType.DEVICE, title='通知3', content='内容3', timestamp=datetime.now(), is_read=False),
        ]
        for n in notifications:
            self.manager.add(n)
        
        assert self.manager.get_unread_count() == 2

    def test_get_by_type(self):
        notifications = [
            Notification(id='1', type=NotificationType.SYSTEM, title='系统通知', content='内容', timestamp=datetime.now()),
            Notification(id='2', type=NotificationType.SECURITY, title='安全通知', content='内容', timestamp=datetime.now()),
            Notification(id='3', type=NotificationType.SYSTEM, title='系统通知2', content='内容', timestamp=datetime.now()),
        ]
        for n in notifications:
            self.manager.add(n)
        
        system_notifications = self.manager.get_by_type(NotificationType.SYSTEM)
        assert len(system_notifications) == 2
        
        security_notifications = self.manager.get_by_type(NotificationType.SECURITY)
        assert len(security_notifications) == 1

    def test_clear_notifications(self):
        notifications = [
            Notification(id='1', type=NotificationType.SYSTEM, title='通知1', content='内容', timestamp=datetime.now()),
            Notification(id='2', type=NotificationType.SECURITY, title='通知2', content='内容', timestamp=datetime.now()),
        ]
        for n in notifications:
            self.manager.add(n)
        
        assert len(self.manager.notifications) == 2
        
        self.manager.clear()
        
        assert len(self.manager.notifications) == 0


class TestNotificationTimestamp:
    """测试时间戳格式化"""

    def test_format_relative_minutes(self):
        now = datetime.now()
        timestamp = now - timedelta(minutes=30)
        
        diff = now - timestamp
        assert diff.in_minutes == 30

    def test_format_relative_hours(self):
        now = datetime.now()
        timestamp = now - timedelta(hours=5)
        
        diff = now - timestamp
        assert diff.in_hours == 5

    def test_format_relative_days(self):
        now = datetime.now()
        timestamp = now - timedelta(days=3)
        
        diff = now - timestamp
        assert diff.in_days == 3

    def test_format_relative_weeks(self):
        now = datetime.now()
        timestamp = now - timedelta(weeks=2)
        
        diff = now - timestamp
        assert diff.in_days >= 14


class TestNotificationActions:
    """测试通知操作"""

    def setup_method(self):
        self.manager = NotificationManager()

    def test_dismiss_notification(self):
        notification = Notification(
            id='1',
            type=NotificationType.SYSTEM,
            title='可删除的通知',
            content='内容',
            timestamp=datetime.now()
        )
        self.manager.add(notification)
        
        # 模拟滑动手势删除
        self.manager.remove('1')
        
        assert len(self.manager.notifications) == 0

    def test_notification_detail_view(self):
        notification = Notification(
            id='1',
            type=NotificationType.SECURITY,
            title='新设备登录',
            content='您的账户在新设备上登录',
            timestamp=datetime.now(),
            is_read=False
        )
        
        # 访问详情时自动标记为已读
        detail_viewed = notification.copy_with(is_read=True)
        
        assert detail_viewed.is_read is True

    def test_notification_action_buttons(self):
        actions = [
            {'label': '查看详情', 'icon': 'open_in_new', 'is_primary': False},
            {'label': '知道了', 'icon': 'check', 'is_primary': True},
        ]
        
        assert len(actions) == 2
        assert actions[0]['is_primary'] is False
        assert actions[1]['is_primary'] is True


class TestNotificationFiltering:
    """测试通知过滤"""

    def setup_method(self):
        self.manager = NotificationManager()
        self.notifications = [
            Notification('1', NotificationType.SECURITY, '安全1', '内容', datetime.now() - timedelta(hours=1), False),
            Notification('2', NotificationType.SECURITY, '安全2', '内容', datetime.now() - timedelta(hours=2), True),
            Notification('3', NotificationType.DEVICE, '设备1', '内容', datetime.now() - timedelta(hours=3), False),
            Notification('4', NotificationType.SYSTEM, '系统1', '内容', datetime.now() - timedelta(hours=4), True),
            Notification('5', NotificationType.SYSTEM, '系统2', '内容', datetime.now() - timedelta(hours=5), False),
        ]
        for n in self.notifications:
            self.manager.add(n)

    def test_filter_unread(self):
        unread = [n for n in self.manager.notifications if not n.is_read]
        assert len(unread) == 3

    def test_filter_by_multiple_types(self):
        security_and_device = [
            n for n in self.manager.notifications 
            if n.type in [NotificationType.SECURITY, NotificationType.DEVICE]
        ]
        assert len(security_and_device) == 3

    def test_sort_by_timestamp_desc(self):
        sorted_notifications = sorted(
            self.manager.notifications,
            key=lambda n: n.timestamp,
            reverse=True
        )
        assert sorted_notifications[0].timestamp > sorted_notifications[-1].timestamp


class TestNotificationBadge:
    """测试通知徽章"""

    def test_badge_count_zero(self):
        count = 0
        show_zero = False
        # 不显示零徽章
        assert not show_zero or count > 0

    def test_badge_count_positive(self):
        count = 5
        show_zero = True
        assert show_zero or count > 0
        assert count == 5

    def test_badge_count_overflow(self):
        count = 150
        display = '99+' if count > 99 else str(count)
        assert display == '99+'

    def test_badge_count_normal(self):
        count = 42
        display = '99+' if count > 99 else str(count)
        assert display == '42'


# 运行所有测试
if __name__ == '__main__':
    pytest.main([__file__, '-v'])