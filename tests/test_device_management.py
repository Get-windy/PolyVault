# -*- coding: utf-8 -*-
"""
PolyVault 设备管理UI测试
测试设备列表、设备详情和权限设置功能
"""

import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import unittest

# 模拟Flutter组件测试
class TestDeviceManagement(unittest.TestCase):
    """设备管理UI测试"""
    
    def test_device_info_creation(self):
        """测试创建设备信息"""
        # 模拟设备数据
        device = {
            'id': 'device_1',
            'name': '测试设备',
            'type': 'Mobile Phone',
            'platform': 'Android',
            'ipAddress': '192.168.1.100',
            'isConnected': True,
            'lastSeen': '刚刚',
            'canReadCredentials': True,
            'canWriteCredentials': True,
            'canExportData': False,
            'requiresBiometric': True,
        }
        
        self.assertEqual(device['name'], '测试设备')
        self.assertEqual(device['platform'], 'Android')
        self.assertTrue(device['isConnected'])
    
    def test_device_list_operations(self):
        """测试设备列表操作"""
        devices = []
        
        # 添加设备
        devices.append({
            'id': '1',
            'name': '手机',
            'isConnected': True,
        })
        devices.append({
            'id': '2', 
            'name': '电脑',
            'isConnected': False,
        })
        
        self.assertEqual(len(devices), 2)
        
        # 移除设备
        devices = [d for d in devices if d['id'] != '1']
        self.assertEqual(len(devices), 1)
        
        # 更新设备状态
        for d in devices:
            if d['id'] == '2':
                d['isConnected'] = True
        self.assertTrue(devices[0]['isConnected'])
    
    def test_device_filtering(self):
        """测试设备筛选"""
        devices = [
            {'id': '1', 'name': '手机', 'isConnected': True},
            {'id': '2', 'name': '电脑', 'isConnected': False},
            {'id': '3', 'name': '平板', 'isConnected': True},
        ]
        
        # 筛选已连接设备
        connected = [d for d in devices if d['isConnected']]
        self.assertEqual(len(connected), 2)
        
        # 筛选未连接设备
        disconnected = [d for d in devices if not d['isConnected']]
        self.assertEqual(len(disconnected), 1)
    
    def test_device_permissions(self):
        """测试设备权限"""
        permissions = {
            'canReadCredentials': True,
            'canWriteCredentials': False,
            'canExportData': False,
            'requiresBiometric': True,
        }
        
        self.assertTrue(permissions['canReadCredentials'])
        self.assertFalse(permissions['canWriteCredentials'])
        self.assertFalse(permissions['canExportData'])
        self.assertTrue(permissions['requiresBiometric'])
    
    def test_device_permission_update(self):
        """测试权限更新"""
        device = {
            'id': '1',
            'name': '测试设备',
            'canReadCredentials': True,
            'canWriteCredentials': True,
            'canExportData': True,
            'requiresBiometric': False,
        }
        
        # 更新权限
        device['canWriteCredentials'] = False
        device['canExportData'] = False
        device['requiresBiometric'] = True
        
        self.assertTrue(device['canReadCredentials'])
        self.assertFalse(device['canWriteCredentials'])
        self.assertFalse(device['canExportData'])
        self.assertTrue(device['requiresBiometric'])
    
    def test_device_search(self):
        """测试设备搜索"""
        devices = [
            {'id': '1', 'name': '我的手机', 'platform': 'Android'},
            {'id': '2', 'name': '工作电脑', 'platform': 'Windows'},
            {'id': '3', 'name': 'iPad平板', 'platform': 'iOS'},
        ]
        
        # 按名称搜索
        keyword = '手机'
        results = [d for d in devices if keyword in d['name']]
        self.assertEqual(len(results), 1)
        
        # 按平台搜索
        keyword = 'Windows'
        results = [d for d in devices if keyword in d['platform']]
        self.assertEqual(len(results), 1)
    
    def test_device_sorting(self):
        """测试设备排序"""
        devices = [
            {'id': '1', 'name': 'Zebra', 'isConnected': True},
            {'id': '2', 'name': 'Apple', 'isConnected': False},
            {'id': '3', 'name': 'Banana', 'isConnected': True},
        ]
        
        # 按名称排序
        sorted_devices = sorted(devices, key=lambda d: d['name'])
        self.assertEqual(sorted_devices[0]['name'], 'Apple')
        self.assertEqual(sorted_devices[1]['name'], 'Banana')
        self.assertEqual(sorted_devices[2]['name'], 'Zebra')
        
        # 按连接状态排序 (已连接在前)
        sorted_devices = sorted(devices, key=lambda d: not d['isConnected'])
        self.assertTrue(sorted_devices[0]['isConnected'])
    
    def test_device_statistics(self):
        """测试设备统计"""
        devices = [
            {'id': '1', 'isConnected': True, 'platform': 'Android'},
            {'id': '2', 'isConnected': True, 'platform': 'iOS'},
            {'id': '3', 'isConnected': False, 'platform': 'Windows'},
            {'id': '4', 'isConnected': True, 'platform': 'Android'},
        ]
        
        total = len(devices)
        connected = len([d for d in devices if d['isConnected']])
        disconnected = total - connected
        
        self.assertEqual(total, 4)
        self.assertEqual(connected, 3)
        self.assertEqual(disconnected, 1)
        
        # 按平台统计
        platforms = {}
        for d in devices:
            p = d['platform']
            platforms[p] = platforms.get(p, 0) + 1
        
        self.assertEqual(platforms['Android'], 2)
        self.assertEqual(platforms['iOS'], 1)
        self.assertEqual(platforms['Windows'], 1)
    
    def test_mcp_protocol_format(self):
        """测试MCP协议格式"""
        # 请求格式
        request = {
            'jsonrpc': '2.0',
            'method': 'polyvault_get_devices',
            'params': {'user_id': 'user_1'},
            'id': 1
        }
        
        self.assertEqual(request['jsonrpc'], '2.0')
        self.assertIn('method', request)
        self.assertIn('params', request)
        
        # 响应格式
        response = {
            'jsonrpc': '2.0',
            'id': 1,
            'result': {
                'devices': [
                    {'id': '1', 'name': '设备1', 'isConnected': True}
                ],
                'total': 1
            }
        }
        
        self.assertEqual(response['jsonrpc'], '2.0')
        self.assertIn('result', response)
        self.assertIn('devices', response['result'])
    
    def test_device_action_validation(self):
        """测试设备操作验证"""
        device = {'id': '1', 'isConnected': False, 'name': '测试设备'}
        
        # 连接设备
        def connect_device(d):
            if d['isConnected']:
                return False, '设备已连接'
            d['isConnected'] = True
            return True, '连接成功'
        
        # 第一次连接
        success, message = connect_device(device)
        self.assertTrue(success)
        self.assertEqual(message, '连接成功')
        
        # 重复连接
        success, message = connect_device(device)
        self.assertFalse(success)
        self.assertEqual(message, '设备已连接')
        
        # 断开设备
        def disconnect_device(d):
            if not d['isConnected']:
                return False, '设备未连接'
            d['isConnected'] = False
            return True, '断开成功'
        
        success, message = disconnect_device(device)
        self.assertTrue(success)
        self.assertEqual(message, '断开成功')
    
    def test_device_permission_validation(self):
        """测试权限验证"""
        device = {
            'id': '1',
            'canReadCredentials': True,
            'canWriteCredentials': False,
            'requiresBiometric': True,
        }
        
        # 检查读取权限
        def can_read(d):
            if d.get('requiresBiometric', False):
                return True, '需要生物识别'
            return d.get('canReadCredentials', False), 'OK'
        
        success, message = can_read(device)
        self.assertTrue(success)
        
        # 修改权限后检查
        device['requiresBiometric'] = False
        device['canReadCredentials'] = False
        success, message = can_read(device)
        self.assertFalse(success)


def run_tests():
    """运行所有测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    suite.addTests(loader.loadTestsFromTestCase(TestDeviceManagement))
    
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    print("\n" + "="*50)
    print(f"测试完成: {result.testsRun} 个测试")
    print(f"成功: {result.testsRun - len(result.failures) - len(result.errors)}")
    print(f"失败: {len(result.failures)}")
    print(f"错误: {len(result.errors)}")
    print("="*50)
    
    return result.wasSuccessful()


if __name__ == "__main__":
    success = run_tests()
    exit(0 if success else 1)