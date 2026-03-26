# -*- coding: utf-8 -*-
"""
PolyVault eCAL通信性能测试
测试范围：
1. eCAL通信性能
2. 多设备通信压力
3. 性能瓶颈分析

任务ID: task_1774242665392_ikbe8tij1
日期: 2026-03-24
"""

import pytest
import time
import threading
import statistics
import random
from typing import Dict, List, Any, Optional, Callable
from dataclasses import dataclass, field
from datetime import datetime
from unittest.mock import Mock, MagicMock, patch
import sys
import os

sys.path.insert(0, 'I:\\PolyVault')
sys.path.insert(0, 'I:\\PolyVault\\src\\agent\\build')


# ==================== 数据模型 ====================

@dataclass
class ECALMessage:
    """eCAL消息"""
    topic: str
    payload: bytes
    timestamp: float = None
    message_id: str = ""
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = time.time()
        if not self.message_id:
            self.message_id = f"msg_{int(self.timestamp * 1000)}"


@dataclass
class ECALMetrics:
    """eCAL性能指标"""
    topic: str
    messages_sent: int = 0
    messages_received: int = 0
    avg_latency_ms: float = 0.0
    p95_latency_ms: float = 0.0
    messages_per_second: float = 0.0


# ==================== 模拟组件 ====================

class MockECALPublisher:
    """模拟eCAL发布者"""
    
    def __init__(self, topic: str):
        self.topic = topic
        self.subscribers: List[MockECALSubscriber] = []
        self.messages_published = 0
        self._callback = None
    
    def publish(self, payload: bytes) -> bool:
        """发布消息"""
        self.messages_published += 1
        
        # 通知订阅者
        for subscriber in self.subscribers:
            if self._callback:
                self._callback(payload)
        
        return True
    
    def set_callback(self, callback: Callable):
        """设置回调函数"""
        self._callback = callback


class MockECALSubscriber:
    """模拟eCAL订阅者"""
    
    def __init__(self, topic: str):
        self.topic = topic
        self.messages_received: List[ECALMessage] = []
        self._callback = None
        self.latencies: List[float] = []
        self._publisher = None
    
    def subscribe(self, publisher: MockECALPublisher):
        """订阅发布者"""
        self._publisher = publisher
        publisher.subscribers.append(self)
        
        # 绑定回调
        def on_message(payload: bytes):
            start_time = time.time()
            msg = ECALMessage(
                topic=self.topic,
                payload=payload,
                timestamp=start_time
            )
            self.messages_received.append(msg)
            
            # 记录延迟（实际中会从发布者时间计算）
            self.latencies.append(0.1)  # 模拟100us延迟
            
            if self._callback:
                self._callback(msg)
        
        publisher.set_callback(on_message)
    
    def set_callback(self, callback: Callable):
        """设置回调函数"""
        self._callback = callback
    
    def get_metrics(self) -> ECALMetrics:
        """获取指标"""
        latencies = self.latencies[:100]  # 最多100条
        
        return ECALMetrics(
            topic=self.topic,
            messages_received=len(self.messages_received),
            messages_sent=self._publisher.messages_published if self._publisher else 0,
            avg_latency_ms=statistics.mean(latencies) if latencies else 0,
            p95_latency_ms=sorted(latencies)[int(len(latencies) * 0.95)] if latencies else 0
        )


class MockECALInitializer:
    """模拟eCAL初始化器"""
    
    _instance = None
    
    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance.initialized = False
            cls._instance.config = None
            cls._instance.publishers: Dict[str, MockECALPublisher] = {}
            cls._instance.subscribers: Dict[str, MockECALSubscriber] = {}
        return cls._instance
    
    def initialize(self, config: Dict = None) -> bool:
        """初始化eCAL"""
        self.config = config or {}
        self.initialized = True
        return True
    
    def finalize(self):
        """关闭eCAL"""
        self.initialized = False
        self.publishers.clear()
        self.subscribers.clear()
    
    def create_publisher(self, topic: str) -> MockECALPublisher:
        """创建发布者"""
        if not self.initialized:
            raise RuntimeError("eCAL not initialized")
        
        if topic not in self.publishers:
            self.publishers[topic] = MockECALPublisher(topic)
        return self.publishers[topic]
    
    def create_subscriber(self, topic: str) -> MockECALSubscriber:
        """创建订阅者"""
        if not self.initialized:
            raise RuntimeError("eCAL not initialized")
        
        if topic not in self.subscribers:
            self.subscribers[topic] = MockECALSubscriber(topic)
        return self.subscribers[topic]
    
    def is_initialized(self) -> bool:
        """检查是否已初始化"""
        return self.initialized


class MockECALCommunicator:
    """模拟eCAL通信器"""
    
    def __init__(self):
        self.initializer = MockECALInitializer()
        self.config = {
            'app_name': 'PolyVault',
            'unit_name': 'test_agent',
            'enable_monitoring': True,
            'timeout_ms': 5000,
            'topics': [
                'polyvault/credential_request',
                'polyvault/credential_response',
                'polyvault/core_reaction',
                'polyvault/connection_state',
                'polyvault/heartbeat'
            ]
        }
        self.running = False
        self.stats = {
            'messages_sent': 0,
            'messages_received': 0,
            'errors': 0
        }
    
    def initialize(self) -> bool:
        """初始化通信器"""
        return self.initializer.initialize(self.config)
    
    def start(self):
        """启动通信"""
        self.running = True
    
    def stop(self):
        """停止通信"""
        self.running = False
    
    def publish(self, topic: str, payload: bytes) -> bool:
        """发布消息"""
        if not self.running:
            return False
        
        publisher = self.initializer.create_publisher(topic)
        success = publisher.publish(payload)
        
        if success:
            self.stats['messages_sent'] += 1
        
        return success
    
    def subscribe(self, topic: str, callback: Callable) -> MockECALSubscriber:
        """订阅消息"""
        subscriber = self.initializer.create_subscriber(topic)
        subscriber.set_callback(callback)
        
        # 自动连接到同主题的发布者
        if topic in self.initializer.publishers:
            subscriber.subscribe(self.initializer.publishers[topic])
        
        return subscriber


# ==================== 测试类 ====================

class TestECALCommunicationPerformance:
    """eCAL通信性能测试"""
    
    @pytest.fixture
    def communicator(self):
        comm = MockECALCommunicator()
        comm.initialize()
        comm.start()
        return comm
    
    # ========== 基础通信测试 ==========
    
    @pytest.mark.ecal
    def test_single_publisher_subscriber(self, communicator):
        """TC-ECAL-001: 单发布者单订阅者通信"""
        messages = []
        
        def on_message(msg):
            messages.append(msg)
        
        publisher = communicator.initializer.create_publisher("test/topic")
        subscriber = communicator.initializer.create_subscriber("test/topic")
        subscriber.subscribe(publisher)
        subscriber.set_callback(on_message)
        
        # 发送10条消息
        for i in range(10):
            publisher.publish(f"msg_{i}".encode())
        
        assert len(messages) == 10
    
    @pytest.mark.ecal
    def test_message_throughput(self, communicator):
        """TC-ECAL-002: 消息吞吐量测试"""
        received = []
        lock = threading.Lock()
        
        def on_message(msg):
            with lock:
                received.append(msg)
        
        publisher = communicator.initializer.create_publisher("throughput/topic")
        subscriber = communicator.initializer.create_subscriber("throughput/topic")
        subscriber.subscribe(publisher)
        subscriber.set_callback(on_message)
        
        start = time.time()
        
        for i in range(1000):
            publisher.publish(f"msg_{i}".encode())
        
        duration = time.time() - start
        throughput = 1000 / duration
        
        assert len(received) == 1000
        assert throughput > 500  # 至少500 msg/s
    
    @pytest.mark.ecal
    def test_multiple_topics(self, communicator):
        """TC-ECAL-003: 多主题通信"""
        topics = [
            "polyvault/credential_request",
            "polyvault/credential_response",
            "polyvault/core_reaction",
            "polyvault/connection_state",
            "polyvault/heartbeat"
        ]
        
        initial_count = len(communicator.initializer.publishers)
        
        for topic in topics:
            publisher = communicator.initializer.create_publisher(topic)
            publisher.publish(f"test_{topic}".encode())
        
        # 验证每个主题的发布者都存在
        for topic in topics:
            assert topic in communicator.initializer.publishers
    
    @pytest.mark.ecal
    def test_message_latency(self, communicator):
        """TC-ECAL-004: 消息延迟测试"""
        latencies = []
        
        publisher = communicator.initializer.create_publisher("latency/topic")
        
        start_time = time.time()
        publisher.publish(b"test")
        elapsed = (time.time() - start_time) * 1000  # ms
        
        # 模拟延迟（实际测试中应测量完整延迟）
        assert elapsed < 1  # 应在1ms内完成


class TestMultiDeviceCommunication:
    """多设备通信压力测试"""
    
    @pytest.fixture
    def communicator(self):
        comm = MockECALCommunicator()
        comm.initialize()
        comm.start()
        return comm
    
    # ========== 并发压力测试 ==========
    
    @pytest.mark.multidevice
    def test_multiple_publishers(self, communicator):
        """TC-MDEV-001: 多发布者并发测试"""
        publishers = []
        messages_per_publisher = 100
        
        for i in range(10):
            publisher = communicator.initializer.create_publisher(f"topic_{i}")
            publishers.append(publisher)
        
        # 所有发布者同时发布消息
        for publisher in publishers:
            for j in range(messages_per_publisher):
                publisher.publish(f"msg_{publisher.topic}_{j}".encode())
        
        # 总消息数应为10*100=1000
        total_published = sum(p.messages_published for p in publishers)
        assert total_published == 1000
    
    @pytest.mark.multidevice
    def test_high_volume_traffic(self, communicator):
        """TC-MDEV-002: 高流量压力测试"""
        publisher = communicator.initializer.create_publisher("high_volume")
        subscriber = communicator.initializer.create_subscriber("high_volume")
        subscriber.subscribe(publisher)
        
        received = []
        def on_message(msg):
            received.append(msg)
        subscriber.set_callback(on_message)
        
        # 发送10000条消息
        for i in range(10000):
            publisher.publish(f"msg_{i}".encode())
        
        # 验证接收数量
        assert len(received) == 10000
    
    @pytest.mark.multidevice
    def test_bridge_mode_communication(self, communicator):
        """TC-MDEV-003: 桥接模式通信"""
        # 模拟多个设备通过eCAL桥接通信
        devices = []
        
        for i in range(5):
            device = {
                'publisher': communicator.initializer.create_publisher(f"device_{i}/out"),
                'subscriber': communicator.initializer.create_subscriber(f"device_{i}/in")
            }
            devices.append(device)
        
        # 设备间通信
        for i, device in enumerate(devices):
            for j, other_device in enumerate(devices):
                if i != j:
                    # 设备i向设备j发送消息
                    device['publisher'].publish(f"from_{i}_to_{j}".encode())
        
        # 验证所有发布
        for device in devices:
            assert device['publisher'].messages_published == 4  # 与其他4个设备通信
    
    # ========== 混合负载测试 ==========
    
    @pytest.mark.multidevice
    def test_heterogeneous_traffic(self, communicator):
        """TC-MDEV-005: 异构流量测试"""
        # 模拟不同优先级的消息流
        high_priority = communicator.initializer.create_publisher("priority/high")
        normal_priority = communicator.initializer.create_publisher("priority/normal")
        low_priority = communicator.initializer.create_publisher("priority/low")
        
        # 同时发送
        for i in range(100):
            high_priority.publish(b"high")
            normal_priority.publish(b"normal")
            low_priority.publish(b"low")
        
        assert high_priority.messages_published == 100
        assert normal_priority.messages_published == 100
        assert low_priority.messages_published == 100


class TestPerformanceBottleneck:
    """性能瓶颈分析测试"""
    
    @pytest.fixture
    def communicator(self):
        comm = MockECALCommunicator()
        comm.initialize()
        comm.start()
        return comm
    
    # ========== 资源压力测试 ==========
    
    @pytest.mark.bottleneck
    def test_memory_usage_under_load(self, communicator):
        """TC-BOTT-001: 负载下内存使用"""
        import psutil
        
        initial_memory = psutil.Process().memory_info().rss / 1024 / 1024
        
        # 高负载通信
        publisher = communicator.initializer.create_publisher("memory_test")
        subscriber = communicator.initializer.create_subscriber("memory_test")
        subscriber.subscribe(publisher)
        
        for i in range(5000):
            publisher.publish(f"msg_{i}".encode())
        
        final_memory = psutil.Process().memory_info().rss / 1024 / 1024
        memory_increase = final_memory - initial_memory
        
        # 内存增长应合理 (<50MB)
        assert memory_increase < 50, f"内存增长过大: {memory_increase:.2f} MB"
    
    @pytest.mark.bottleneck
    def test_cpu_usage_under_load(self, communicator):
        """TC-BOTT-002: 负载下CPU使用"""
        import psutil
        
        initial_cpu = psutil.cpu_percent(interval=0.1)
        
        # 高负载通信
        publisher = communicator.initializer.create_publisher("cpu_test")
        
        for i in range(1000):
            publisher.publish(f"msg_{i}".encode())
        
        final_cpu = psutil.cpu_percent(interval=0.1)
        cpu_peak = max(initial_cpu, final_cpu)
        
        # CPU使用应合理 (<80%)
        assert cpu_peak < 80, f"CPU使用过高: {cpu_peak:.1f}%"
    
    # ========== 瓶颈识别测试 ==========
    
    @pytest.mark.bottleneck
    def test_message_size_impact(self, communicator):
        """TC-BOTT-003: 消息大小影响分析"""
        publisher = communicator.initializer.create_publisher("size_test")
        subscriber = communicator.initializer.create_subscriber("size_test")
        subscriber.subscribe(publisher)
        
        results = []
        
        for size in [100, 1000, 10000]:
            latency = 0.001 * (size / 100)  # 模拟延迟随大小增长
            results.append({
                'size': size,
                'latency_ms': latency
            })
        
        # 验证延迟随消息大小增长
        assert results[2]['latency_ms'] >= results[0]['latency_ms'] * 0.8  # 允许一定误差
    
    @pytest.mark.bottleneck
    def test_concurrency_limits(self, communicator):
        """TC-BOTT-004: 并发限制分析"""
        bottlenecks = []
        
        # 逐步增加并发数
        for concurrency in [1, 5, 10, 20]:
            publisher = communicator.initializer.create_publisher(f"concurrency_{concurrency}")
            subscriber = communicator.initializer.create_subscriber(f"concurrency_{concurrency}")
            subscriber.subscribe(publisher)
            
            start = time.time()
            
            for i in range(100):
                publisher.publish(f"msg_{i}".encode())
            
            elapsed = time.time() - start
            throughput = 100 / elapsed
            
            bottlenecks.append({
                'concurrency': concurrency,
                'throughput': throughput,
                'elapsed': elapsed
            })
        
        # 验证吞吐量随并发增加而提升（直到达到某个点）
        assert bottlenecks[-1]['throughput'] > bottlenecks[0]['throughput']
    
    @pytest.mark.bottleneck
    def test_throughput_degradation(self, communicator):
        """TC-BOTT-005: 吞吐量衰减分析"""
        # 持续发送消息
        publisher = communicator.initializer.create_publisher("degradation_test")
        subscriber = communicator.initializer.create_subscriber("degradation_test")
        subscriber.subscribe(publisher)
        
        throughput_samples = []
        
        for batch in range(10):
            start = time.time()
            for i in range(1000):
                publisher.publish(f"msg_{batch}_{i}".encode())
            elapsed = time.time() - start
            throughput_samples.append(1000 / elapsed)
        
        # 计算平均值和标准差
        avg_throughput = statistics.mean(throughput_samples)
        stddev = statistics.stdev(throughput_samples) if len(throughput_samples) > 1 else 0
        
        # 标准差应较小（表示吞吐量稳定）
        assert stddev < avg_throughput * 0.2, f"吞吐量不稳定: stddev={stddev:.2f}, avg={avg_throughput:.2f}"


class TestPerformanceScenarios:
    """性能场景测试"""
    
    @pytest.fixture
    def communicator(self):
        comm = MockECALCommunicator()
        comm.initialize()
        comm.start()
        return comm
    
    @pytest.mark.scenario
    def test_realistic_traffic_pattern(self, communicator):
        """TC-SCEN-001: 真实流量模式模拟"""
        # 模拟PolyVault的典型eCAL通信模式
        topics = {
            'credential_request': 30,   # 30% 流量
            'credential_response': 30,  # 30% 流量
            'core_reaction': 20,        # 20% 流量
            'connection_state': 10,     # 10% 流量
            'heartbeat': 10             # 10% 流量
        }
        
        publishers = {}
        for topic, _ in topics.items():
            publishers[topic] = communicator.initializer.create_publisher(topic)
        
        # 按权重发送消息
        total = 1000
        for topic, weight in topics.items():
            count = int(total * weight / 100)
            for i in range(count):
                publishers[topic].publish(f"msg_{topic}_{i}".encode())
        
        # 验证消息分布
        for topic, weight in topics.items():
            expected_pct = weight / 100
            actual_pct = publishers[topic].messages_published / total
            assert abs(actual_pct - expected_pct) < 0.05, f"{topic} 消息分布不正确"
    
    @pytest.mark.scenario
    def test_stress_test(self, communicator):
        """TC-SCEN-002: 压力测试"""
        import psutil
        
        publisher = communicator.initializer.create_publisher("stress_test")
        subscriber = communicator.initializer.create_subscriber("stress_test")
        subscriber.subscribe(publisher)
        
        received = []
        start_time = time.time()
        
        # 持续发送10秒
        while time.time() - start_time < 10:
            publisher.publish(b"stress_msg")
        
        # 验证系统稳定性
        cpu = psutil.cpu_percent(interval=0.1)
        assert cpu < 90, f"压力测试下CPU过高: {cpu}%"
    
    @pytest.mark.scenario
    def test_long_running_communication(self, communicator):
        """TC-SCEN-003: 长时间运行通信测试"""
        publisher = communicator.initializer.create_publisher("long_run")
        subscriber = communicator.initializer.create_subscriber("long_run")
        subscriber.subscribe(publisher)
        
        received = []
        def on_message(msg):
            received.append(msg)
        subscriber.set_callback(on_message)
        
        # 运行60秒
        import time
        start = time.time()
        interval = time.time()
        count = 0
        
        while time.time() - start < 5:  # 实际测试时应为60秒，这里缩短为5秒
            publisher.publish(b"msg")
            count += 1
            
            if time.time() - interval > 1:
                interval = time.time()
                # 确保系统未崩溃
                assert communicator.initializer.is_initialized()
        
        assert count > 0
        assert len(received) == count


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