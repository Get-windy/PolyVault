import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/connection_status_card.dart';
import '../widgets/recent_activity_list.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/stats_card.dart';
import '../services/secure_storage.dart';

/// 首页 - 主界面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<DeviceConnectionStatus> _connectedDevices = [];
  List<ActivityRecord> _recentActivities = [];
  StorageStats? _storageStats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final storage = SecureStorageService();
      
      // 加载存储统计
      final stats = await storage.getStorageStats();
      
      // 模拟加载设备连接状态（实际应从设备服务获取）
      final devices = await _loadDeviceConnections();
      
      // 加载最近活动（实际应从活动日志获取）
      final activities = await _loadRecentActivities();

      setState(() {
        _storageStats = stats;
        _connectedDevices = devices;
        _recentActivities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  Future<List<DeviceConnectionStatus>> _loadDeviceConnections() async {
    // TODO: 从设备服务获取实际连接状态
    return [
      const DeviceConnectionStatus(
        deviceId: 'device_1',
        deviceName: 'MacBook Pro',
        deviceType: 'laptop',
        isConnected: true,
        ipAddress: '192.168.1.100',
      ),
      const DeviceConnectionStatus(
        deviceId: 'device_2',
        deviceName: 'iPhone 15',
        deviceType: 'phone',
        isConnected: false,
        lastConnected: null,
      ),
    ];
  }

  Future<List<ActivityRecord>> _loadRecentActivities() async {
    // TODO: 从活动日志服务获取实际数据
    return [
      ActivityRecord(
        id: '1',
        title: '访问凭证',
        description: '查看了 GitHub 的登录凭证',
        icon: Icons.visibility,
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        type: ActivityType.credentialAccess,
      ),
      ActivityRecord(
        id: '2',
        title: '新设备连接',
        description: 'MacBook Pro 已连接',
        icon: Icons.link,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: ActivityType.deviceConnect,
      ),
      ActivityRecord(
        id: '3',
        title: '创建凭证',
        description: '添加了 AWS IAM 凭证',
        icon: Icons.add_circle,
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        type: ActivityType.credentialCreate,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PolyVault'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 连接状态卡片
            ConnectionStatusCard(
              devices: _connectedDevices,
              isLoading: _isLoading,
              onTap: () => context.push('/devices'),
            ),
            const SizedBox(height: 16),
            
            // 统计卡片
            if (_storageStats != null) ...[
              _buildStatsRow(),
              const SizedBox(height: 16),
            ],
            
            // 快捷操作
            Text(
              '快捷操作',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            QuickActionsGrid(
              onActionTap: (action) => context.push(action.route),
            ),
            const SizedBox(height: 24),
            
            // 最近活动
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '最近活动',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_recentActivities.isNotEmpty)
                  TextButton(
                    onPressed: () => context.push('/activity-log'),
                    child: const Text('查看全部'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            RecentActivityList(
              activities: _recentActivities,
              isLoading: _isLoading,
              onActivityTap: (activity) => _showActivityDetail(activity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.vpn_key,
            label: '凭证总数',
            value: '${_storageStats?.totalCredentials ?? 0}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.devices,
            label: '已连接设备',
            value: '${_connectedDevices.where((d) => d.isConnected).length}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.backup,
            label: '最近备份',
            value: _storageStats?.lastBackup != null
                ? _formatBackupTime(_storageStats!.lastBackup!)
                : '从未',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  String _formatBackupTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inDays == 0) return '今天';
    if (diff.inDays == 1) return '昨天';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}-${time.day}';
  }

  void _showActivityDetail(ActivityRecord activity) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ActivityDetailCard(
        activity: activity,
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

/// 简易统计卡片
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}