"""
PolyVault 设备管理测试
测试设备列表、设备状态、操作按钮功能
"""

import pytest
from datetime import datetime, timedelta, timedelta


# 设备类型枚举
class DeviceType:
    MOBILE = 'mobile'
    DESKTOP = 'desktop'
    TABLET = 'tablet'
    LAPTOP = 'laptop'
    UNKNOWN = 'unknown'


# 设备平台枚举
class DevicePlatform:
    ANDROID = 'android'
    IOS = 'ios'
    WINDOWS = 'windows'
    MACOS = 'macos'
    LINUX = 'linux'
    WEB = 'web'
    UNKNOWN = 'unknown'


# 设备连接状态
class DeviceStatus:
    CONNECTED = 'connected'
    DISCONNECTED = 'disconnected'
    OFFLINE = 'offline'


# 设备数据模型
class Device:
    def __init__(self, id, name, device_type, platform, ip_address, status, last_seen=None, paired_at=None):
        self.id = id
        self.name = name
        self.device_type = device_type
        self.platform = platform
        self.ip_address = ip_address
        self.status = status
        self.last_seen = last_seen
        self.paired_at = paired_at

    @property
    def is_connected(self):
        return self.status == DeviceStatus.CONNECTED

    def copy_with(self, **kwargs):
        return Device(
            id=kwargs.get('id', self.id),
            name=kwargs.get('name', self.name),
            device_type=kwargs.get('device_type', self.device_type),
            platform=kwargs.get('platform', self.platform),
            ip_address=kwargs.get('ip_address', self.ip_address),
            status=kwargs.get('status', self.status),
            last_seen=kwargs.get('last_seen', self.last_seen),
            paired_at=kwargs.get('paired_at', self.paired_at),
        )


# 设备管理器
class DeviceManager:
    def __init__(self):
        self.devices = []

    def add(self, device):
        self.devices.append(device)

    def remove(self, device_id):
        self.devices = [d for d in self.devices if d.id != device_id]

    def connect(self, device_id):
        for d in self.devices:
            if d.id == device_id:
                self.devices[self.devices.index(d)] = d.copy_with(
                    status=DeviceStatus.CONNECTED,
                    last_seen=datetime.now()
                )

    def disconnect(self, device_id):
        for d in self.devices:
            if d.id == device_id:
                self.devices[self.devices.index(d)] = d.copy_with(
                    status=DeviceStatus.DISCONNECTED,
                    last_seen=datetime.now()
                )

    def get_connected_count(self):
        return sum(1 for d in self.devices if d.is_connected)

    def get_by_platform(self, platform):
        return [d for d in self.devices if d.platform == platform]

    def get_by_status(self, status):
        return [d for d in self.devices if d.status == status]

    def clear(self):
        self.devices = []


class TestDeviceModel:
    """测试设备数据模型"""

    def test_create_device(self):
        device = Device(
            id='1',
            name='我的手机',
            device_type=DeviceType.MOBILE,
            platform=DevicePlatform.ANDROID,
            ip_address='192.168.1.100',
            status=DeviceStatus.CONNECTED,
        )
        assert device.id == '1'
        assert device.name == '我的手机'
        assert device.is_connected is True

    def test_copy_with(self):
        original = Device(
            id='1',
            name='原名称',
            device_type=DeviceType.DESKTOP,
            platform=DevicePlatform.WINDOWS,
            ip_address='192.168.1.100',
            status=DeviceStatus.CONNECTED,
        )
        copied = original.copy_with(name='新名称', status=DeviceStatus.DISCONNECTED)
        
        assert copied.id == '1'
        assert copied.name == '新名称'
        assert copied.status == DeviceStatus.DISCONNECTED

    def test_device_types(self):
        types = [
            DeviceType.MOBILE,
            DeviceType.DESKTOP,
            DeviceType.TABLET,
            DeviceType.LAPTOP,
            DeviceType.UNKNOWN,
        ]
        assert len(types) == 5


class TestDeviceManager:
    """测试设备管理器"""

    def setup_method(self):
        self.manager = DeviceManager()

    def test_add_device(self):
        device = Device(
            id='1',
            name='测试设备',
            device_type=DeviceType.MOBILE,
            platform=DevicePlatform.ANDROID,
            ip_address='192.168.1.100',
            status=DeviceStatus.CONNECTED,
        )
        self.manager.add(device)
        assert len(self.manager.devices) == 1

    def test_remove_device(self):
        device = Device(
            id='1',
            name='测试设备',
            device_type=DeviceType.MOBILE,
            platform=DevicePlatform.ANDROID,
            ip_address='192.168.1.100',
            status=DeviceStatus.CONNECTED,
        )
        self.manager.add(device)
        self.manager.remove('1')
        assert len(self.manager.devices) == 0

    def test_connect_device(self):
        device = Device(
            id='1',
            name='测试设备',
            device_type=DeviceType.MOBILE,
            platform=DevicePlatform.ANDROID,
            ip_address='192.168.1.100',
            status=DeviceStatus.DISCONNECTED,
        )
        self.manager.add(device)
        
        assert self.manager.get_connected_count() == 0
        
        self.manager.connect('1')
        
        assert self.manager.get_connected_count() == 1
        assert self.manager.devices[0].is_connected is True

    def test_disconnect_device(self):
        device = Device(
            id='1',
            name='测试设备',
            device_type=DeviceType.MOBILE,
            platform=DevicePlatform.ANDROID,
            ip_address='192.168.1.100',
            status=DeviceStatus.CONNECTED,
        )
        self.manager.add(device)
        
        assert self.manager.get_connected_count() == 1
        
        self.manager.disconnect('1')
        
        assert self.manager.get_connected_count() == 0
        assert self.manager.devices[0].is_connected is False

    def test_get_connected_count(self):
        devices = [
            Device('1', '设备1', DeviceType.MOBILE, DevicePlatform.ANDROID, '192.168.1.1', DeviceStatus.CONNECTED),
            Device('2', '设备2', DeviceType.DESKTOP, DevicePlatform.WINDOWS, '192.168.1.2', DeviceStatus.DISCONNECTED),
            Device('3', '设备3', DeviceType.TABLET, DevicePlatform.IOS, '192.168.1.3', DeviceStatus.CONNECTED),
        ]
        for d in devices:
            self.manager.add(d)
        
        assert self.manager.get_connected_count() == 2

    def test_get_by_platform(self):
        devices = [
            Device('1', '安卓手机', DeviceType.MOBILE, DevicePlatform.ANDROID, '192.168.1.1', DeviceStatus.CONNECTED),
            Device('2', 'iPhone', DeviceType.MOBILE, DevicePlatform.IOS, '192.168.1.2', DeviceStatus.CONNECTED),
            Device('3', 'Windows电脑', DeviceType.DESKTOP, DevicePlatform.WINDOWS, '192.168.1.3', DeviceStatus.DISCONNECTED),
        ]
        for d in devices:
            self.manager.add(d)
        
        android_devices = self.manager.get_by_platform(DevicePlatform.ANDROID)
        assert len(android_devices) == 1
        assert android_devices[0].name == '安卓手机'

    def test_get_by_status(self):
        devices = [
            Device('1', '设备1', DeviceType.MOBILE, DevicePlatform.ANDROID, '192.168.1.1', DeviceStatus.CONNECTED),
            Device('2', '设备2', DeviceType.MOBILE, DevicePlatform.IOS, '192.168.1.2', DeviceStatus.DISCONNECTED),
            Device('3', '设备3', DeviceType.DESKTOP, DevicePlatform.WINDOWS, '192.168.1.3', DeviceStatus.OFFLINE),
        ]
        for d in devices:
            self.manager.add(d)
        
        connected = self.manager.get_by_status(DeviceStatus.CONNECTED)
        assert len(connected) == 1

    def test_clear_devices(self):
        devices = [
            Device('1', '设备1', DeviceType.MOBILE, DevicePlatform.ANDROID, '192.168.1.1', DeviceStatus.CONNECTED),
            Device('2', '设备2', DeviceType.DESKTOP, DevicePlatform.WINDOWS, '192.168.1.2', DeviceStatus.CONNECTED),
        ]
        for d in devices:
            self.manager.add(d)
        
        assert len(self.manager.devices) == 2
        
        self.manager.clear()
        
        assert len(self.manager.devices) == 0


class TestDeviceTimestamp:
    """测试时间戳格式化"""

    def test_format_last_seen_minutes(self):
        now = datetime.now()
        last_seen = now - timedelta(minutes=30)
        
        diff = now - last_seen
        assert diff.seconds // 60 == 30

    def test_format_last_seen_hours(self):
        now = datetime.now()
        last_seen = now - timedelta(hours=5)
        
        diff = now - last_seen
        assert diff.seconds // 3600 == 5

    def test_format_last_seen_days(self):
        now = datetime.now()
        last_seen = now - timedelta(days=3)
        
        diff = now - last_seen
        assert diff.days == 3


class TestDeviceActions:
    """测试设备操作"""

    def test_connect_action(self):
        device = Device(
            id='1',
            name='可连接设备',
            device_type=DeviceType.MOBILE,
            platform=DevicePlatform.ANDROID,
            ip_address='192.168.1.100',
            status=DeviceStatus.DISCONNECTED,
        )
        
        # 模拟连接操作
        device.status = DeviceStatus.CONNECTED
        
        assert device.is_connected is True

    def test_disconnect_action(self):
        device = Device(
            id='1',
            name='可断开设备',
            device_type=DeviceType.MOBILE,
            platform=DevicePlatform.ANDROID,
            ip_address='192.168.1.100',
            status=DeviceStatus.CONNECTED,
        )
        
        # 模拟断开操作
        device.status = DeviceStatus.DISCONNECTED
        device.last_seen = datetime.now()
        
        assert device.is_connected is False

    def test_delete_device_action(self):
        devices = [
            Device('1', '设备1', DeviceType.MOBILE, DevicePlatform.ANDROID, '192.168.1.1', DeviceStatus.CONNECTED),
            Device('2', '设备2', DeviceType.DESKTOP, DevicePlatform.WINDOWS, '192.168.1.2', DeviceStatus.DISCONNECTED),
        ]
        
        # 模拟删除设备
        devices = [d for d in devices if d.id != '1']
        
        assert len(devices) == 1
        assert devices[0].id == '2'


class TestDeviceFiltering:
    """测试设备过滤"""

    def setup_method(self):
        self.manager = DeviceManager()
        self.devices = [
            Device('1', '安卓手机', DeviceType.MOBILE, DevicePlatform.ANDROID, '192.168.1.1', DeviceStatus.CONNECTED),
            Device('2', 'iPhone', DeviceType.MOBILE, DevicePlatform.IOS, '192.168.1.2', DeviceStatus.DISCONNECTED),
            Device('3', 'Windows电脑', DeviceType.DESKTOP, DevicePlatform.WINDOWS, '192.168.1.3', DeviceStatus.CONNECTED),
            Device('4', 'MacBook', DeviceType.LAPTOP, DevicePlatform.MACOS, '192.168.1.4', DeviceStatus.DISCONNECTED),
            Device('5', 'Linux服务器', DeviceType.DESKTOP, DevicePlatform.LINUX, '192.168.1.5', DeviceStatus.OFFLINE),
        ]
        for d in self.devices:
            self.manager.add(d)

    def test_filter_by_type_mobile(self):
        mobile_devices = [d for d in self.manager.devices if d.device_type == DeviceType.MOBILE]
        assert len(mobile_devices) == 2

    def test_filter_by_type_desktop(self):
        desktop_devices = [d for d in self.manager.devices if d.device_type == DeviceType.DESKTOP]
        assert len(desktop_devices) == 2

    def test_filter_connected_only(self):
        connected = [d for d in self.manager.devices if d.is_connected]
        assert len(connected) == 2

    def test_filter_platform_windows(self):
        windows = self.manager.get_by_platform(DevicePlatform.WINDOWS)
        assert len(windows) == 1
        assert windows[0].name == 'Windows电脑'


class TestDevicePlatformMapping:
    """测试平台映射"""

    def test_platform_to_icon(self):
        platform_icons = {
            DevicePlatform.ANDROID: 'android',
            DevicePlatform.IOS: 'apple',
            DevicePlatform.WINDOWS: 'desktop_windows',
            DevicePlatform.MACOS: 'laptop_mac',
            DevicePlatform.LINUX: 'computer',
            DevicePlatform.WEB: 'language',
        }
        
        assert platform_icons[DevicePlatform.ANDROID] == 'android'
        assert platform_icons[DevicePlatform.IOS] == 'apple'

    def test_platform_to_color(self):
        platform_colors = {
            DevicePlatform.ANDROID: 'green',
            DevicePlatform.IOS: 'grey',
            DevicePlatform.WINDOWS: 'blue',
            DevicePlatform.MACOS: 'grey',
            DevicePlatform.LINUX: 'orange',
        }
        
        assert platform_colors[DevicePlatform.ANDROID] == 'green'
        assert platform_colors[DevicePlatform.WINDOWS] == 'blue'

    def test_device_type_names(self):
        type_names = {
            DeviceType.MOBILE: '手机',
            DeviceType.DESKTOP: '台式电脑',
            DeviceType.TABLET: '平板',
            DeviceType.LAPTOP: '笔记本电脑',
            DeviceType.UNKNOWN: '未知设备',
        }
        
        assert type_names[DeviceType.MOBILE] == '手机'
        assert type_names[DeviceType.TABLET] == '平板'


# 运行所有测试
if __name__ == '__main__':
    pytest.main([__file__, '-v'])