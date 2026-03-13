import 'package:flutter/material.dart';
import '../services/secure_storage.dart';
import '../widgets/device_status_card.dart';
import '../widgets/security_status_card.dart';
import '../widgets/stats_card.dart';

/// 主页 - 设备状态
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StorageStats? _stats;
  bool _isBiometricAvailable = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final storage = SecureStorageService();
      final stats = await storage.getStorageStats();
      final biometricAvailable = await storage.isBiometricAvailable();

      setState(() {
        _stats = stats;
        _isBiometricAvailable = biometricAvailable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PolyVault',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // TODO: 打开设置页面
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 设备状态卡片
                    DeviceStatusCard(
                      isConnected: true,
                      deviceName: '本机设备',
                      platform: _getPlatformName(),
                    ),
                    const SizedBox(height: 16),

                    // 安全状态卡片
                    SecurityStatusCard(
                      isBiometricAvailable: _isBiometricAvailable,
                      isHardwareSecure: true,
                      encryptionLevel: 'AES-256-GCM',
                    ),
                    const SizedBox(height: 16),

                    // 统计卡片
                    if (_stats != null)
                      StatsCard(
                        totalCredentials: _stats!.totalCredentials,
                        lastBackup: _stats!.lastBackup,
                      ),

                    const SizedBox(height: 24),

                    // 快速操作
                    Text(
                      '快速操作',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_circle_outline,
            title: '添加凭证',
            subtitle: '安全存储新密码',
            onTap: () {
              // 切换到凭证管理页并打开添加对话框
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.sync_outlined,
            title: '同步设备',
            subtitle: '连接其他设备',
            onTap: () {
              // TODO: 打开设备同步页面
            },
          ),
        ),
      ],
    );
  }

  String _getPlatformName() {
    // 简化版本，实际应使用device_info_plus
    return 'Unknown';
  }
}

/// 快速操作卡片
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
