#!/usr/bin/env python3
"""
PolyVault性能基准测试脚本
测试范围：P2P通信、插件执行、加密操作、eCAL通信
"""
import pytest
import time
import statistics
import concurrent.futures
from typing import List, Dict, Any
import sys
import os

# 添加项目路径
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from core.base_test import BaseTest
from core.api_client import APIClient
from core.assertions import Assertions


class TestPolyVaultPerformance(BaseTest):
    """PolyVault性能基准测试"""
    
    @pytest.fixture(autouse=True)
    def setup(self, api_client: APIClient):
        """测试前置设置"""
        self.api = api_client
        self.base_url = api_client.base_url
        self.baseline_results = {}
    
    # ==================== P2P通信性能基准 ====================
    
    @pytest.mark.performance
    @pytest.mark.baseline
    def test_p2p_message_latency_baseline(self, api_client: APIClient):
        """
        @description: P2P消息延迟基准测试
        @expected:
            1. 平均延迟 < 15ms
            2. P95延迟 < 25ms
            3. P99延迟 < 50ms
        """
        latencies = []
        
        # 发送100条消息并测量延迟
        for i in range(100):
            start_time = time.time()
            response = api_client.post('/api/p2p/send', json={
                'target': 'peer_001',
                'message': f'benchmark_msg_{i}',
                'type': 'test'
            })
            end_time = time.time()
            
            latency = (end_time - start_time) * 1000
            latencies.append(latency)
            
            Assertions.assert_status_code(response, 200)
        
        # 计算统计指标
        avg_latency = statistics.mean(latencies)
        p95_latency = sorted(latencies)[int(len(latencies) * 0.95)]
        p99_latency = sorted(latencies)[int(len(latencies) * 0.99)]
        
        # 记录基准结果
        self.baseline_results['p2p_latency'] = {
            'avg': avg_latency,
            'p95': p95_latency,
            'p99': p99_latency
        }
        
        # 验证基准
        assert avg_latency < 15, f"平均延迟 {avg_latency}ms 超过 15ms"
        assert p95_latency < 25, f"P95延迟 {p95_latency}ms 超过 25ms"
        assert p99_latency < 50, f"P99延迟 {p99_latency}ms 超过 50ms"
    
    @pytest.mark.performance
    @pytest.mark.baseline
    def test_p2p_throughput_baseline(self, api_client: APIClient):
        """
        @description: P2P吞吐量基准测试
        @expected:
            1. 吞吐量 > 1000 msg/s
        """
        message_count = 1000
        start_time = time.time()
        
        # 并发发送消息
        def send_message(i):
            response = api_client.post('/api/p2p/send', json={
                'target': 'peer_001',
                'message': f'benchmark_msg_{i}',
                'type': 'test'
            })
            return response.status_code == 200
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=50) as executor:
            futures = [executor.submit(send_message, i) for i in range(message_count)]
            results = [f.result() for f in futures]
        
        end_time = time.time()
        duration = end_time - start_time
        throughput = message_count / duration
        
        # 记录基准结果
        self.baseline_results['p2p_throughput'] = {
            'throughput': throughput,
            'duration': duration,
            'success_rate': sum(results) / len(results)
        }
        
        # 验证基准
        assert throughput > 1000, f"吞吐量 {throughput:.2f} msg/s 低于 1000 msg/s"
        assert sum(results) / len(results) > 0.99, "成功率低于 99%"
    
    # ==================== 插件执行性能基准 ====================
    
    @pytest.mark.performance
    @pytest.mark.baseline
    def test_plugin_execution_latency_baseline(self, api_client: APIClient):
        """
        @description: 插件执行延迟基准测试
        @expected:
            1. 平均延迟 < 8ms
            2. P95延迟 < 15ms
        """
        latencies = []
        
        for i in range(100):
            start_time = time.time()
            response = api_client.post('/api/plugins/execute', json={
                'plugin_id': 'benchmark_plugin',
                'input': f'test_data_{i}',
                'timeout': 10
            })
            end_time = time.time()
            
            latency = (end_time - start_time) * 1000
            latencies.append(latency)
            
            Assertions.assert_status_code(response, 200)
        
        avg_latency = statistics.mean(latencies)
        p95_latency = sorted(latencies)[int(len(latencies) * 0.95)]
        
        self.baseline_results['plugin_latency'] = {
            'avg': avg_latency,
            'p95': p95_latency
        }
        
        assert avg_latency < 8, f"平均延迟 {avg_latency}ms 超过 8ms"
        assert p95_latency < 15, f"P95延迟 {p95_latency}ms 超过 15ms"
    
    @pytest.mark.performance
    @pytest.mark.baseline
    def test_plugin_throughput_baseline(self, api_client: APIClient):
        """
        @description: 插件吞吐量基准测试
        @expected:
            1. 吞吐量 > 500 ops/s
        """
        operation_count = 500
        start_time = time.time()
        
        def execute_plugin(i):
            response = api_client.post('/api/plugins/execute', json={
                'plugin_id': 'benchmark_plugin',
                'input': f'test_data_{i}',
                'timeout': 10
            })
            return response.status_code == 200
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
            futures = [executor.submit(execute_plugin, i) for i in range(operation_count)]
            results = [f.result() for f in futures]
        
        end_time = time.time()
        duration = end_time - start_time
        throughput = operation_count / duration
        
        self.baseline_results['plugin_throughput'] = {
            'throughput': throughput,
            'duration': duration,
            'success_rate': sum(results) / len(results)
        }
        
        assert throughput > 500, f"吞吐量 {throughput:.2f} ops/s 低于 500 ops/s"
    
    # ==================== 加密操作性能基准 ====================
    
    @pytest.mark.performance
    @pytest.mark.baseline
    def test_crypto_latency_baseline(self, api_client: APIClient):
        """
        @description: 加密操作延迟基准测试
        @expected:
            1. AES加密 < 25ms
            2. RSA签名 < 50ms
        """
        # AES加密测试
        aes_latencies = []
        for i in range(50):
            start_time = time.time()
            response = api_client.post('/api/crypto/encrypt', json={
                'algorithm': 'AES-256-GCM',
                'data': 'benchmark_data_' * 100
            })
            end_time = time.time()
            
            latency = (end_time - start_time) * 1000
            aes_latencies.append(latency)
            
            Assertions.assert_status_code(response, 200)
        
        aes_avg = statistics.mean(aes_latencies)
        
        # RSA签名测试
        rsa_latencies = []
        for i in range(20):
            start_time = time.time()
            response = api_client.post('/api/crypto/sign', json={
                'algorithm': 'RSA-2048',
                'data': 'benchmark_data_' * 100
            })
            end_time = time.time()
            
            latency = (end_time - start_time) * 1000
            rsa_latencies.append(latency)
            
            Assertions.assert_status_code(response, 200)
        
        rsa_avg = statistics.mean(rsa_latencies)
        
        self.baseline_results['crypto_latency'] = {
            'aes_avg': aes_avg,
            'rsa_avg': rsa_avg
        }
        
        assert aes_avg < 25, f"AES平均延迟 {aes_avg}ms 超过 25ms"
        assert rsa_avg < 50, f"RSA平均延迟 {rsa_avg}ms 超过 50ms"
    
    @pytest.mark.performance
    def test_04_sync_latency_baseline(self):
        """同步延迟基准测试"""
        sync_latencies = []
        
        for i in range(30):
            start_time = time.time()
            # 模拟同步操作
            result = self.ecal_service.send_message(
                topic='/polyvault/sync',
                data=b'sync_request'
            )
            end_time = time.time()
            
            latency = (end_time - start_time) * 1000
            sync_latencies.append(latency)
        
        sync_avg = statistics.mean(sync_latencies)
        
        # 验证同步延迟
        assert sync_avg < 100, f"同步平均延迟 {sync_avg}ms 超过 100ms"
        
        # 更新统计信息
        self.baseline_results['sync_latency'] = sync_avg
        self.overall_baseline = {
            'crypto_latency': self.baseline_results['crypto_latency'],
            'sync_latency': sync_avg,
            'total_tests': 4
        }