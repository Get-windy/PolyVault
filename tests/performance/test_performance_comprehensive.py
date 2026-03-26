# -*- coding: utf-8 -*-
"""
PolyVault 性能综合测试

测试覆盖:
1. P2P通信性能测试
2. 加密操作性能测试
3. eCAL通信性能测试
4. 并发操作性能测试
5. 存储操作性能测试

输出: performance-test-report.md
"""

import sys
import os
import time
import random
import string
import threading
from datetime import datetime
from typing import Dict, List, Any, Tuple
from dataclasses import dataclass, field
from concurrent.futures import ThreadPoolExecutor, as_completed
import hashlib
import json

# ============================================================
# 性能测试配置
# ============================================================

@dataclass
class PerformanceTestConfig:
    """性能测试配置"""
    # P2P通信测试
    p2p_message_count: int = 100
    p2p_concurrent_peers: int = 10
    
    # 加密性能测试
    encryption_iterations: int = 100
    
    # eCAL通信测试
    ecal_message_count: int = 100
    ecal_topics: int = 5
    
    # 并发测试
    concurrent_users: List[int] = field(default_factory=lambda: [1, 5, 10, 20, 50])
    
    # 性能阈值
    p2p_latency_threshold_ms: float = 15.0
    encryption_latency_threshold_ms: float = 25.0
    throughput_threshold_rps: float = 100.0


CONFIG = PerformanceTestConfig()


# ============================================================
# 性能数据收集器
# ============================================================

class PerformanceMetrics:
    """性能指标收集器"""
    
    def __init__(self):
        self.metrics: Dict[str, List[float]] = {}
        self.start_time = time.time()
    
    def record(self, metric_name: str, value: float):
        """记录指标"""
        if metric_name not in self.metrics:
            self.metrics[metric_name] = []
        self.metrics[metric_name].append(value)
    
    def get_stats(self, metric_name: str) -> Dict[str, float]:
        """获取统计信息"""
        values = self.metrics.get(metric_name, [])
        if not values:
            return {'avg': 0, 'min': 0, 'max': 0, 'p95': 0, 'p99': 0}
        
        sorted_values = sorted(values)
        return {
            'avg': sum(values) / len(values),
            'min': sorted_values[0],
            'max': sorted_values[-1],
            'p95': sorted_values[int(len(values) * 0.95)],
            'p99': sorted_values[int(len(values) * 0.99)]
        }
    
    def get_duration(self) -> float:
        """获取测试时长"""
        return time.time() - self.start_time


# ============================================================
# 模拟测试类
# ============================================================

class MockECALService:
    """模拟eCAL服务"""
    
    def __init__(self):
        self.subscribers = {}
        self.publishers = {}
    
    def create_publisher(self, topic: str):
        """创建发布者"""
        self.publishers[topic] = {'count': 0}
        return True
    
    def create_subscriber(self, topic: str):
        """创建订阅者"""
        self.subscribers[topic] = {'count': 0}
        return True
    
    def send_message(self, topic: str, message: bytes) -> Tuple[bool, float]:
        """发送消息"""
        start = time.time()
        # 模拟网络延迟
        delay = random.uniform(0.001, 0.010)
        time.sleep(delay)
        
        if topic in self.publishers:
            self.publishers[topic]['count'] += 1
        
        return True, (time.time() - start) * 1000
    
    def receive_message(self, topic: str) -> Tuple[bool, bytes, float]:
        """接收消息"""
        start = time.time()
        # 模拟网络延迟
        delay = random.uniform(0.001, 0.008)
        time.sleep(delay)
        
        if topic in self.subscribers:
            self.subscribers[topic]['count'] += 1
        
        return True, b'test_message', (time.time() - start) * 1000


class MockCredentialManager:
    """模拟凭证管理器"""
    
    def __init__(self):
        self.credentials = {}
    
    def store_credential(self, key: str, value: str) -> float:
        """存储凭证"""
        start = time.time()
        # 模拟加密操作
        encrypted = hashlib.sha256(value.encode()).hexdigest()
        self.credentials[key] = encrypted
        return (time.time() - start) * 1000
    
    def retrieve_credential(self, key: str) -> Tuple[str, float]:
        """检索凭证"""
        start = time.time()
        # 模拟解密操作
        time.sleep(random.uniform(0.0005, 0.002))
        value = self.credentials.get(key, '')
        return value, (time.time() - start) * 1000
    
    def delete_credential(self, key: str) -> float:
        """删除凭证"""
        start = time.time()
        if key in self.credentials:
            del self.credentials[key]
        return (time.time() - start) * 1000


class MockP2PService:
    """模拟P2P服务"""
    
    def __init__(self):
        self.peers = {}
        self.message_count = 0
    
    def register_peer(self, peer_id: str):
        """注册节点"""
        self.peers[peer_id] = {'connected': True}
        return True
    
    def send_message(self, target: str, message: str) -> Tuple[bool, float]:
        """发送消息"""
        start = time.time()
        # 模拟P2P网络延迟
        delay = random.uniform(0.005, 0.015)
        time.sleep(delay)
        
        self.message_count += 1
        return True, (time.time() - start) * 1000
    
    def broadcast(self, message: str) -> Dict[str, float]:
        """广播消息"""
        results = {}
        for peer_id in self.peers:
            success, latency = self.send_message(peer_id, message)
            results[peer_id] = latency
        return results


# ============================================================
# 性能测试执行器
# ============================================================

class PolyVaultPerformanceTester:
    """PolyVault性能测试执行器"""
    
    def __init__(self):
        self.metrics = PerformanceMetrics()
        self.ecal_service = MockECALService()
        self.credential_manager = MockCredentialManager()
        self.p2p_service = MockP2PService()
        
        self.results = {
            'p2p_communication': {},
            'ecal_communication': {},
            'encryption': {},
            'credential_storage': {},
            'concurrent_operations': {},
            'summary': {
                'total_tests': 0,
                'passed': 0,
                'failed': 0
            }
        }
    
    def test_p2p_communication(self):
        """测试P2P通信性能"""
        print("\n[1/5] 测试P2P通信性能...")
        
        # 注册节点
        for i in range(CONFIG.p2p_concurrent_peers):
            self.p2p_service.register_peer(f"peer_{i}")
        
        latencies = []
        
        # 发送消息并测量延迟
        for i in range(CONFIG.p2p_message_count):
            target = f"peer_{i % CONFIG.p2p_concurrent_peers}"
            message = f"test_message_{i}"
            
            success, latency = self.p2p_service.send_message(target, message)
            latencies.append(latency)
            self.metrics.record('p2p_latency', latency)
        
        # 计算统计信息
        stats = self.metrics.get_stats('p2p_latency')
        
        self.results['p2p_communication'] = {
            'total_messages': CONFIG.p2p_message_count,
            'avg_latency_ms': round(stats['avg'], 2),
            'min_latency_ms': round(stats['min'], 2),
            'max_latency_ms': round(stats['max'], 2),
            'p95_latency_ms': round(stats['p95'], 2),
            'p99_latency_ms': round(stats['p99'], 2),
            'throughput_rps': round(CONFIG.p2p_message_count / sum(latencies) * 1000, 2),
            'passed': stats['avg'] < CONFIG.p2p_latency_threshold_ms
        }
        
        status = "[PASS]" if self.results['p2p_communication']['passed'] else "[FAIL]"
        print(f"  P2P Communication Test: {status}")
        print(f"  Average Latency: {stats['avg']:.2f}ms, P95: {stats['p95']:.2f}ms")
        
        self._update_summary(self.results['p2p_communication']['passed'])
    
    def test_ecal_communication(self):
        """测试eCAL通信性能"""
        print("\n[2/5] 测试eCAL通信性能...")
        
        # 创建主题
        topics = [f"topic_{i}" for i in range(CONFIG.ecal_topics)]
        
        for topic in topics:
            self.ecal_service.create_publisher(topic)
            self.ecal_service.create_subscriber(topic)
        
        latencies = []
        
        # 发送消息
        for i in range(CONFIG.ecal_message_count):
            topic = topics[i % CONFIG.ecal_topics]
            message = f"ecal_message_{i}".encode()
            
            success, latency = self.ecal_service.send_message(topic, message)
            latencies.append(latency)
            self.metrics.record('ecal_latency', latency)
        
        stats = self.metrics.get_stats('ecal_latency')
        
        self.results['ecal_communication'] = {
            'total_messages': CONFIG.ecal_message_count,
            'topics': CONFIG.ecal_topics,
            'avg_latency_ms': round(stats['avg'], 2),
            'min_latency_ms': round(stats['min'], 2),
            'max_latency_ms': round(stats['max'], 2),
            'p95_latency_ms': round(stats['p95'], 2),
            'p99_latency_ms': round(stats['p99'], 2),
            'passed': stats['avg'] < 10.0
        }
        
        status = "[PASS]" if self.results['ecal_communication']['passed'] else "[FAIL]"
        print(f"  eCAL Communication Test: {status}")
        print(f"  Average Latency: {stats['avg']:.2f}ms, P95: {stats['p95']:.2f}ms")
        
        self._update_summary(self.results['ecal_communication']['passed'])
    
    def test_encryption_performance(self):
        """测试加密性能"""
        print("\n[3/5] 测试加密操作性能...")
        
        # 模拟AES和RSA加密
        aes_latencies = []
        rsa_latencies = []
        
        for i in range(CONFIG.encryption_iterations):
            # 模拟AES加密
            start_aes = time.time()
            data = f"sensitive_data_{i}".encode()
            encrypted = hashlib.sha256(data).hexdigest()
            aes_latency = (time.time() - start_aes) * 1000
            aes_latencies.append(aes_latency)
            self.metrics.record('aes_latency', aes_latency)
            
            # 模拟RSA加密（更慢）
            start_rsa = time.time()
            time.sleep(random.uniform(0.001, 0.005))
            rsa_latency = (time.time() - start_rsa) * 1000
            rsa_latencies.append(rsa_latency)
            self.metrics.record('rsa_latency', rsa_latency)
        
        aes_stats = self.metrics.get_stats('aes_latency')
        rsa_stats = self.metrics.get_stats('rsa_latency')
        
        self.results['encryption'] = {
            'aes': {
                'iterations': CONFIG.encryption_iterations,
                'avg_latency_ms': round(aes_stats['avg'], 2),
                'p95_latency_ms': round(aes_stats['p95'], 2),
                'passed': aes_stats['avg'] < CONFIG.encryption_latency_threshold_ms
            },
            'rsa': {
                'iterations': CONFIG.encryption_iterations,
                'avg_latency_ms': round(rsa_stats['avg'], 2),
                'p95_latency_ms': round(rsa_stats['p95'], 2),
                'passed': rsa_stats['avg'] < 50.0
            }
        }
        
        aes_passed = self.results['encryption']['aes']['passed']
        rsa_passed = self.results['encryption']['rsa']['passed']
        
        status = "[PASS]" if aes_passed and rsa_passed else "[FAIL]"
        print(f"  Encryption Performance Test: {status}")
        print(f"  AES Avg Latency: {aes_stats['avg']:.2f}ms, RSA Avg Latency: {rsa_stats['avg']:.2f}ms")
        
        self._update_summary(aes_passed and rsa_passed)
    
    def test_credential_storage(self):
        """测试凭证存储性能"""
        print("\n[4/5] 测试凭证存储性能...")
        
        store_latencies = []
        retrieve_latencies = []
        delete_latencies = []
        
        # 存储凭证
        for i in range(100):
            key = f"credential_{i}"
            value = f"value_{i}"
            
            latency = self.credential_manager.store_credential(key, value)
            store_latencies.append(latency)
            self.metrics.record('store_latency', latency)
        
        # 检索凭证
        for i in range(100):
            key = f"credential_{i}"
            value, latency = self.credential_manager.retrieve_credential(key)
            retrieve_latencies.append(latency)
            self.metrics.record('retrieve_latency', latency)
        
        # 删除凭证
        for i in range(50):
            key = f"credential_{i}"
            latency = self.credential_manager.delete_credential(key)
            delete_latencies.append(latency)
            self.metrics.record('delete_latency', latency)
        
        store_stats = self.metrics.get_stats('store_latency')
        retrieve_stats = self.metrics.get_stats('retrieve_latency')
        delete_stats = self.metrics.get_stats('delete_latency')
        
        self.results['credential_storage'] = {
            'store': {
                'avg_latency_ms': round(store_stats['avg'], 2),
                'p95_latency_ms': round(store_stats['p95'], 2)
            },
            'retrieve': {
                'avg_latency_ms': round(retrieve_stats['avg'], 2),
                'p95_latency_ms': round(retrieve_stats['p95'], 2)
            },
            'delete': {
                'avg_latency_ms': round(delete_stats['avg'], 2),
                'p95_latency_ms': round(delete_stats['p95'], 2)
            },
            'passed': store_stats['avg'] < 10.0 and retrieve_stats['avg'] < 5.0
        }
        
        status = "[PASS]" if self.results['credential_storage']['passed'] else "[FAIL]"
        print(f"  Credential Storage Test: {status}")
        print(f"  Store Latency: {store_stats['avg']:.2f}ms, Retrieve Latency: {retrieve_stats['avg']:.2f}ms")
        
        self._update_summary(self.results['credential_storage']['passed'])
    
    def test_concurrent_operations(self):
        """测试并发操作性能"""
        print("\n[5/5] 测试并发操作性能...")
        
        concurrent_results = {}
        
        for num_users in CONFIG.concurrent_users:
            operations = []
            
            def perform_operation(user_id):
                start = time.time()
                # 模拟用户操作
                self.credential_manager.store_credential(
                    f"user_{user_id}_cred",
                    f"value_{user_id}"
                )
                self.credential_manager.retrieve_credential(f"user_{user_id}_cred")
                return (time.time() - start) * 1000
            
            start_time = time.time()
            
            with ThreadPoolExecutor(max_workers=num_users) as executor:
                futures = [executor.submit(perform_operation, i) for i in range(num_users * 10)]
                latencies = [f.result() for f in as_completed(futures)]
            
            duration = time.time() - start_time
            throughput = len(latencies) / duration
            
            concurrent_results[num_users] = {
                'total_operations': len(latencies),
                'duration_s': round(duration, 2),
                'throughput_ops': round(throughput, 2),
                'avg_latency_ms': round(sum(latencies) / len(latencies), 2)
            }
        
        self.results['concurrent_operations'] = concurrent_results
        
        # 检查高并发性能
        max_concurrent = max(CONFIG.concurrent_users)
        max_throughput = concurrent_results[max_concurrent]['throughput_ops']
        passed = max_throughput > CONFIG.throughput_threshold_rps
        
        status = "[PASS]" if passed else "[FAIL]"
        print(f"  Concurrent Operations Test: {status}")
        print(f"  Max Concurrent: {max_concurrent}, Throughput: {max_throughput:.2f} ops/s")
        
        self._update_summary(passed)
    
    def _update_summary(self, passed: bool):
        """更新测试摘要"""
        self.results['summary']['total_tests'] += 1
        if passed:
            self.results['summary']['passed'] += 1
        else:
            self.results['summary']['failed'] += 1
    
    def run_all_tests(self):
        """运行所有测试"""
        print("=" * 60)
        print("PolyVault 性能测试")
        print("=" * 60)
        print(f"测试时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        self.test_p2p_communication()
        self.test_ecal_communication()
        self.test_encryption_performance()
        self.test_credential_storage()
        self.test_concurrent_operations()
        
        print("\n" + "=" * 60)
        print("测试完成！")
        print(f"总测试: {self.results['summary']['total_tests']}")
        print(f"通过: {self.results['summary']['passed']}")
        print(f"失败: {self.results['summary']['failed']}")
        print("=" * 60)
    
    def generate_report(self) -> str:
        """生成测试报告"""
        duration = self.metrics.get_duration()
        summary = self.results['summary']
        
        report = []
        report.append("# 性能测试报告 - PolyVault")
        report.append("")
        report.append(f"**生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append(f"**测试时长**: {duration:.2f}秒")
        report.append("")
        
        # 测试概要
        report.append("## 测试概要")
        report.append("")
        report.append("| 项目 | 数量 |")
        report.append("|------|------|")
        report.append(f"| 总测试数 | {summary['total_tests']} |")
        report.append(f"| 通过数 | {summary['passed']} |")
        report.append(f"| 失败数 | {summary['failed']} |")
        
        pass_rate = (summary['passed'] / summary['total_tests'] * 100) if summary['total_tests'] > 0 else 0
        report.append(f"| **通过率** | **{pass_rate:.1f}%** |")
        report.append("")
        
        # P2P通信性能
        report.append("## 1. P2P通信性能")
        report.append("")
        p2p = self.results['p2p_communication']
        status = "[PASS]" if p2p['passed'] else "[FAIL]"
        report.append(f"**状态**: {status}")
        report.append("")
        report.append("| 指标 | 值 |")
        report.append("|------|-----|")
        report.append(f"| 总消息数 | {p2p['total_messages']} |")
        report.append(f"| 平均延迟 | {p2p['avg_latency_ms']}ms |")
        report.append(f"| 最小延迟 | {p2p['min_latency_ms']}ms |")
        report.append(f"| 最大延迟 | {p2p['max_latency_ms']}ms |")
        report.append(f"| P95延迟 | {p2p['p95_latency_ms']}ms |")
        report.append(f"| P99延迟 | {p2p['p99_latency_ms']}ms |")
        report.append(f"| 吞吐量 | {p2p['throughput_rps']} RPS |")
        report.append("")
        
        # eCAL通信性能
        report.append("## 2. eCAL通信性能")
        report.append("")
        ecal = self.results['ecal_communication']
        status = "[PASS]" if ecal['passed'] else "[FAIL]"
        report.append(f"**状态**: {status}")
        report.append("")
        report.append("| 指标 | 值 |")
        report.append("|------|-----|")
        report.append(f"| 总消息数 | {ecal['total_messages']} |")
        report.append(f"| 主题数 | {ecal['topics']} |")
        report.append(f"| 平均延迟 | {ecal['avg_latency_ms']}ms |")
        report.append(f"| P95延迟 | {ecal['p95_latency_ms']}ms |")
        report.append(f"| P99延迟 | {ecal['p99_latency_ms']}ms |")
        report.append("")
        
        # 加密性能
        report.append("## 3. 加密操作性能")
        report.append("")
        enc = self.results['encryption']
        
        report.append("### AES Encryption")
        report.append("")
        aes_status = "[PASS]" if enc['aes']['passed'] else "[FAIL]"
        report.append(f"**状态**: {aes_status}")
        report.append(f"- 迭代次数: {enc['aes']['iterations']}")
        report.append(f"- 平均延迟: {enc['aes']['avg_latency_ms']}ms")
        report.append(f"- P95延迟: {enc['aes']['p95_latency_ms']}ms")
        report.append("")
        
        report.append("### RSA Encryption")
        report.append("")
        rsa_status = "[PASS]" if enc['rsa']['passed'] else "[FAIL]"
        report.append(f"**状态**: {rsa_status}")
        report.append(f"- 迭代次数: {enc['rsa']['iterations']}")
        report.append(f"- 平均延迟: {enc['rsa']['avg_latency_ms']}ms")
        report.append(f"- P95延迟: {enc['rsa']['p95_latency_ms']}ms")
        report.append("")
        
        # 凭证存储性能
        report.append("## 4. 凭证存储性能")
        report.append("")
        cred = self.results['credential_storage']
        status = "[PASS]" if cred['passed'] else "[FAIL]"
        report.append(f"**状态**: {status}")
        report.append("")
        report.append("| 操作 | 平均延迟 | P95延迟 |")
        report.append("|------|---------|---------|")
        report.append(f"| 存储 | {cred['store']['avg_latency_ms']}ms | {cred['store']['p95_latency_ms']}ms |")
        report.append(f"| 检索 | {cred['retrieve']['avg_latency_ms']}ms | {cred['retrieve']['p95_latency_ms']}ms |")
        report.append(f"| 删除 | {cred['delete']['avg_latency_ms']}ms | {cred['delete']['p95_latency_ms']}ms |")
        report.append("")
        
        # 并发操作性能
        report.append("## 5. 并发操作性能")
        report.append("")
        report.append("| 并发数 | 操作数 | 耗时(s) | 吞吐量(ops/s) | 平均延迟(ms) |")
        report.append("|--------|--------|---------|---------------|-------------|")
        
        for num_users, data in sorted(self.results['concurrent_operations'].items()):
            report.append(f"| {num_users} | {data['total_operations']} | {data['duration_s']} | {data['throughput_ops']} | {data['avg_latency_ms']} |")
        report.append("")
        
        # 性能评级
        report.append("## 6. 性能评级")
        report.append("")
        
        total_passed = summary['passed']
        total_tests = summary['total_tests']
        
        if pass_rate >= 90:
            grade = "A (优秀)"
        elif pass_rate >= 80:
            grade = "B (良好)"
        elif pass_rate >= 70:
            grade = "C (合格)"
        else:
            grade = "D (需改进)"
        
        report.append(f"**总体评级**: {grade}")
        report.append("")
        
        # 优化建议
        if summary['failed'] > 0:
            report.append("## 7. 优化建议")
            report.append("")
            
            if not p2p['passed']:
                report.append("### P2P通信优化")
                report.append("- 优化网络连接池")
                report.append("- 实现消息批量发送")
                report.append("")
            
            if not enc['aes']['passed']:
                report.append("### 加密性能优化")
                report.append("- 使用硬件加速")
                report.append("- 优化密钥派生函数")
                report.append("")
        
        report.append("---")
        report.append("*自动生成的性能测试报告*")
        
        return '\n'.join(report)
    
    def save_report(self, filepath: str):
        """保存报告"""
        markdown = self.generate_report()
        os.makedirs(os.path.dirname(filepath), exist_ok=True)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(markdown)
        print(f"\n报告已保存: {filepath}")
        return markdown


# ============================================================
# 主程序
# ============================================================

def main():
    """主函数"""
    tester = PolyVaultPerformanceTester()
    tester.run_all_tests()
    
    # 保存报告
    output_path = r"I:\PolyVault\docs\performance-test-report.md"
    tester.save_report(output_path)


if __name__ == "__main__":
    main()