import 'package:flutter/material.dart';
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

  Future<void> _testConnection() async {
    setState(() {
      _isConnecting = true;
      _statusMessage = '正在连接...';
    });

    // 模拟连接过程
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isConnected = !_isConnected;
      _isConnecting = false;
      _statusMessage = _isConnected ? '连接成功！' : '连接已断开';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isConnected ? '设备已连接' : '设备已断开'),
          backgroundColor: _isConnected ? Colors.green : Colors.orange,
        ),
      );
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 大脉冲动画
            ConnectionPulse(
              isActive: _isConnected,
              size: 120,
              color: _isConnected ? Colors.green : Colors.grey,
            ),
            const SizedBox(height: 40),

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
                    ),
                    if (_isConnecting) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // 测试按钮
            if (_isConnecting)
              const SizedBox.shrink()
            else
              GradientButton(
                text: _isConnected ? '断开连接' : '测试连接',
                icon: _isConnected ? Icons.link_off : Icons.link,
                onPressed: _testConnection,
                gradientColors: _isConnected
                    ? [Colors.orange, Colors.red]
                    : const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),

            const SizedBox(height: 24),

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
              deviceName: '测试设备',
              deviceType: 'Flutter Client',
              isConnected: _isConnected,
              onTap: _testConnection,
            ),
          ],
        ),
      ),
    );
  }
}
