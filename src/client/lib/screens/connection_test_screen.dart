import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/animated_connection_indicator.dart';
import '../widgets/custom_button.dart';

/// 连接测试页面
class ConnectionTestScreen extends StatefulWidget {
  const ConnectionTestScreen({super.key});

  @override
  State<ConnectionTestScreen> createState() => _ConnectionTestScreenState();
}

class _ConnectionTestScreenState extends State<ConnectionTestScreen> {
  bool _isConnected = false;
  bool _isConnecting = false;
  String _statusMessage = '等待连接...';
  
  // 连接统计
  int _pingMs = 0;
  int _packetLoss = 0;
  int _testCount = 0;
  int _successCount = 0;
  List<ConnectionTestResult> _testHistory = [];
  
  // 测试类型
  TestType _currentTest = TestType.basic;
  Timer? _pingTimer;

  @override
  void dispose() {
    _pingTimer?.cancel();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _statusMessage = '正在${_getTestTypeName()}...';
    });

    // 模拟连接过程
    await Future.delayed(const Duration(seconds: 2));

    // 模拟测试结果
    final success = await _simulateTest();

    setState(() {
      _isConnected = success;
      _isConnecting = false;
      _testCount++;
      if (success) {
        _successCount++;
        _pingMs = _generateRandomPing();
        _packetLoss = _generateRandomPacketLoss();
        _statusMessage = '连接成功！延迟 ${_pingMs}ms';
      } else {
        _statusMessage = '连接失败，请检查网络';
      }
      
      // 添加到历史记录
      _testHistory.insert(0, ConnectionTestResult(
        timestamp: DateTime.now(),
        testType: _currentTest,
        success: success,
        pingMs: _pingMs,
        packetLoss: _packetLoss,
      ));
      
      // 只保留最近20条记录
      if (_testHistory.length > 20) {
        _testHistory = _testHistory.sublist(0, 20);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '设备连接测试通过' : '连接测试失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<bool> _simulateTest() async {
    // 模拟90%成功率
    await Future.delayed(const Duration(milliseconds: 500));
    return DateTime.now().millisecond % 100 < 90;
  }

  int _generateRandomPing() {
    // 生成20-200ms的随机延迟
    return 20 + (DateTime.now().millisecond % 180);
  }

  int _generateRandomPacketLoss() {
    // 生成0-5%的随机丢包率
    return DateTime.now().millisecond % 6;
  }

  String _getTestTypeName() {
    switch (_currentTest) {
      case TestType.basic:
        return '基础连接测试';
      case TestType.ping:
        return 'Ping测试';
      case TestType.latency:
        return '延迟测试';
      case TestType.stress:
        return '压力测试';
    }
  }

  void _startContinuousPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_isConnected) {
        _testConnection();
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已开启连续测试模式（每5秒）'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _stopContinuousPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('测试历史'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _testHistory.isEmpty
              ? const Center(child: Text('暂无测试记录'))
              : ListView.builder(
                  itemCount: _testHistory.length,
                  itemBuilder: (context, index) {
                    final result = _testHistory[index];
                    return ListTile(
                      leading: Icon(
                        result.success ? Icons.check_circle : Icons.error,
                        color: result.success ? Colors.green : Colors.red,
                      ),
                      title: Text(_getTestTypeNameByType(result.testType)),
                      subtitle: Text(
                        '${result.timestamp.hour}:${result.timestamp.minute}:${result.timestamp.second}',
                      ),
                      trailing: result.success
                          ? Text('${result.pingMs}ms')
                          : const Text('失败'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  String _getTestTypeNameByType(TestType type) {
    switch (type) {
      case TestType.basic:
        return '基础连接';
      case TestType.ping:
        return 'Ping测试';
      case TestType.latency:
        return '延迟测试';
      case TestType.stress:
        return '压力测试';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '连接测试',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(context),
            tooltip: '测试历史',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 大脉冲动画
            Center(
              child: ConnectionPulse(
                isActive: _isConnected,
                size: 120,
                color: _isConnected ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // 状态卡片
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _isConnected
                      ? Colors.green.withOpacity(0.3)
                      : colorScheme.outlineVariant.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    AnimatedConnectionIndicator(
                      isConnected: _isConnected,
                      statusText: _isConnected ? '已连接' : '未连接',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _isConnected ? Colors.green : colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isConnecting) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 连接统计
            if (_testCount > 0) ...[
              _buildStatsCard(colorScheme),
              const SizedBox(height: 24),
            ],

            // 测试类型选择
            _buildTestTypeSelector(colorScheme),
            const SizedBox(height: 24),

            // 测试按钮
            if (_isConnecting)
              const Center(child: CircularProgressIndicator())
            else ...[
              GradientButton(
                text: _isConnected ? '重新测试' : '开始测试',
                icon: _isConnected ? Icons.refresh : Icons.play_arrow,
                onPressed: _testConnection,
                gradientColors: _isConnected
                    ? [Colors.blue, Colors.blue.shade700]
                    : const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              const SizedBox(height: 12),
              if (_isConnected)
                GradientButton(
                  text: _pingTimer != null ? '停止连续测试' : '连续测试',
                  icon: _pingTimer != null ? Icons.stop : Icons.repeat,
                  onPressed: _pingTimer != null ? _stopContinuousPing : _startContinuousPing,
                  gradientColors: _pingTimer != null
                      ? [Colors.orange, Colors.red]
                      : [Colors.green, Colors.green.shade700],
                ),
            ],

            const SizedBox(height: 32),

            // 设备列表
            Text(
              '测试设备',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            AnimatedDeviceCard(
              deviceName: 'PolyVault Agent',
              deviceType: 'C++ Agent (eCAL)',
              isConnected: _isConnected,
              onTap: _testConnection,
            ),
            AnimatedDeviceCard(
              deviceName: '本地存储',
              deviceType: 'Secure Storage',
              isConnected: true,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('本地存储始终可用')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '连接统计',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem('测试次数', '$_testCount', Icons.repeat),
                _buildStatItem('成功次数', '$_successCount', Icons.check_circle),
                _buildStatItem(
                  '成功率',
                  '${_testCount > 0 ? ((_successCount / _testCount) * 100).toStringAsFixed(1) : 0}%',
                  Icons.trending_up,
                ),
              ],
            ),
            if (_isConnected) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem('延迟', '${_pingMs}ms', Icons.timer),
                  _buildStatItem('丢包率', '$_packetLoss%', Icons.warning),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTypeSelector(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '测试类型',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: TestType.values.map((type) {
            final isSelected = _currentTest == type;
            return ChoiceChip(
              label: Text(_getTestTypeNameByType(type)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentTest = type;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 测试类型枚举
enum TestType {
  basic,
  ping,
  latency,
  stress,
}

/// 连接测试结果
class ConnectionTestResult {
  final DateTime timestamp;
  final TestType testType;
  final bool success;
  final int pingMs;
  final int packetLoss;

  ConnectionTestResult({
    required this.timestamp,
    required this.testType,
    required this.success,
    required this.pingMs,
    required this.packetLoss,
  });
}