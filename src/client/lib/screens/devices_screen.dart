import 'package:flutter/material.dart';
import '../widgets/animated_connection_indicator.dart';
import '../widgets/qr_scanner.dart';
import '../widgets/device_status_card.dart';
import '../widgets/empty_state.dart';

/// 设备信息类
class DeviceInfo {
  String id, name, type, platform, ipAddress;
  bool isConnected;
  String? lastSeen;
  DateTime? pairedAt;
  DeviceInfo({
    required this.id, 
    required this.name, 
    required this.type, 
    required this.isConnected,
    this.lastSeen, 
    required this.platform, 
    required this.ipAddress, 
    this.pairedAt
  });
  
  /// 获取设备平台图标
  IconData get platformIcon {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.apple;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }
  
  /// 获取设备类型图标
  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'mobile phone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet_mac;
      case 'desktop computer':
        return Icons.desktop_windows;
      case 'laptop':
        return Icons.laptop;
      default:
        return Icons.devices_other;
    }
  }
}

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final List<DeviceInfo> _devices = [
    DeviceInfo(
      id: '1', 
      name: '我的手机', 
      type: 'Mobile Phone', 
      isConnected: true,
      platform: 'Android', 
      ipAddress: '192.168.1.100', 
      pairedAt: DateTime.now().subtract(const Duration(days: 30))
    ),
    DeviceInfo(
      id: '2', 
      name: '工作电脑', 
      type: 'Desktop Computer', 
      isConnected: false,
      lastSeen: '2小时前', 
      platform: 'Windows', 
      ipAddress: '192.168.1.101', 
      pairedAt: DateTime.now().subtract(const Duration(days: 60))
    ),
    DeviceInfo(
      id: '3', 
      name: 'iPad平板', 
      type: 'Tablet', 
      isConnected: false,
      lastSeen: '1天前', 
      platform: 'iOS', 
      ipAddress: '192.168.1.102', 
      pairedAt: DateTime.now().subtract(const Duration(days: 15))
    ),
  ];
  
  bool _isScanning = false;

  /// 获取在线设备数量
  int get _connectedCount => _devices.where((d) => d.isConnected).length;
  
  /// 获取离线设备数量
  int get _disconnectedCount => _devices.where((d) => !d.isConnected).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备管理'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _scanForDevices,
            tooltip: '扫描设备',
          ),
        ],
      ),
      body: _devices.isEmpty 
        ? EmptyState(
            icon: Icons.devices_other,
            title: '暂无设备',
            message: '添加您的第一个设备来开始使用',
            actionLabel: '添加设备',
            onAction: _showAddDeviceDialog,
          )
        : CustomScrollView(
            slivers: [
              // 设备统计卡片
              SliverToBoxAdapter(
                child: _buildStatsSection(),
              ),
              // 在线设备
              if (_connectedCount > 0) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '已连接设备',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final device = _devices.where((d) => d.isConnected).toList()[index];
                      return _buildDeviceCard(device);
                    },
                    childCount: _connectedCount,
                  ),
                ),
              ],
              // 离线设备
              if (_disconnectedCount > 0) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      '离线设备',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final device = _devices.where((d) => !d.isConnected).toList()[index];
                      return _buildDeviceCard(device);
                    },
                    childCount: _disconnectedCount,
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDeviceDialog,
        icon: const Icon(Icons.add),
        label: const Text('添加设备'),
      ),
    );
  }

  /// 构建设备统计区域
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.check_circle,
              label: '在线',
              value: _connectedCount.toString(),
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.cloud_off,
              label: '离线',
              value: _disconnectedCount.toString(),
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              icon: Icons.devices,
              label: '总计',
              value: _devices.length.toString(),
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建统计卡片
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建设备卡片
  Widget _buildDeviceCard(DeviceInfo device) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: device.isConnected 
              ? Colors.green.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: InkWell(
          onTap: () => _showDeviceDetail(device),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 设备图标 + 在线状态指示
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        device.typeIcon,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 28,
                      ),
                    ),
                    // 在线状态指示点
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: device.isConnected ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: device.isConnected
                          ? const Icon(Icons.link, size: 10, color: Colors.white)
                          : Icon(Icons.link_off, size: 10, color: Colors.white.withOpacity(0.7)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // 设备信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            device.platformIcon,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.platform,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.network_check,
                            size: 14,
                            color: device.isConnected ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            device.isConnected ? '已连接' : (device.lastSeen ?? '离线'),
                            style: TextStyle(
                              fontSize: 13,
                              color: device.isConnected ? Colors.green : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 操作按钮
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'connect':
                        _connectDevice(device);
                        break;
                      case 'disconnect':
                        _disconnectDevice(device);
                        break;
                      case 'detail':
                        _showDeviceDetail(device);
                        break;
                      case 'delete':
                        _deleteDevice(device);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!device.isConnected)
                      const PopupMenuItem(
                        value: 'connect',
                        child: Row(
                          children: [
                            Icon(Icons.link, size: 20),
                            SizedBox(width: 12),
                            Text('连接'),
                          ],
                        ),
                      ),
                    if (device.isConnected)
                      const PopupMenuItem(
                        value: 'disconnect',
                        child: Row(
                          children: [
                            Icon(Icons.link_off, size: 20),
                            SizedBox(width: 12),
                            Text('断开'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 12),
                          Text('详情'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('删除', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanForDevices() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isScanning = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('扫描完成，发现 ${_devices.length} 个设备'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 删除设备 - 带确认对话框
  void _deleteDevice(DeviceInfo device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('删除设备'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要删除设备 "${device.name}" 吗？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此操作不可撤销，该设备的所有数据将被清除。',
                      style: TextStyle(fontSize: 13, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _devices.removeWhere((d) => d.id == device.id));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已删除 ${device.name}'),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: '撤销',
                    onPressed: () {
                      // 简化版：这里可以添加撤销逻辑
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('无法撤销')),
                      );
                    },
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  void _addDevice(String code) {
    final newDevice = DeviceInfo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '新设备',
      type: 'Unknown',
      isConnected: false,
      lastSeen: '刚刚',
      platform: 'Unknown',
      ipAddress: '192.168.1.xxx',
      pairedAt: DateTime.now(),
    );
    setState(() => _devices.add(newDevice));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已添加新设备'), behavior: SnackBarBehavior.floating),
    );
  }

  void _connectDevice(DeviceInfo device) {
    setState(() { 
      device.isConnected = true; 
      device.lastSeen = null; 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已连接到 ${device.name}'), behavior: SnackBarBehavior.floating),
    );
  }

  void _disconnectDevice(DeviceInfo device) {
    setState(() { 
      device.isConnected = false; 
      device.lastSeen = '刚刚'; 
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已断开 ${device.name}'), behavior: SnackBarBehavior.floating),
    );
  }

  /// 设备详情页面 - 底部弹出
  void _showDeviceDetail(DeviceInfo device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 拖动条
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 头部
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // 设备图标 + 状态指示
                  Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          device.typeIcon,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 40,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: device.isConnected ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: device.isConnected
                            ? const Icon(Icons.link, size: 14, color: Colors.white)
                            : Icon(Icons.link_off, size: 14, color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: device.isConnected 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            device.isConnected ? '已连接' : '未连接',
                            style: TextStyle(
                              fontSize: 13,
                              color: device.isConnected ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(),
            // 详情内容
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  const SizedBox(height: 8),
                  _buildDetailSection('设备信息', [
                    _DetailItem(icon: device.platformIcon, label: '平台', value: device.platform),
                    _DetailItem(icon: Icons.category, label: '类型', value: device.type),
                    _DetailItem(icon: Icons.fingerprint, label: '设备ID', value: device.id),
                  ]),
                  _buildDetailSection('网络信息', [
                    _DetailItem(icon: Icons.router, label: 'IP地址', value: device.ipAddress),
                    _DetailItem(
                      icon: Icons.network_check, 
                      label: '状态', 
                      value: device.isConnected ? '正常' : '离线',
                      valueColor: device.isConnected ? Colors.green : Colors.grey,
                    ),
                  ]),
                  if (device.lastSeen != null)
                    _buildDetailSection('时间信息', [
                      _DetailItem(icon: Icons.schedule, label: '最后在线', value: device.lastSeen!),
                    ]),
                  if (device.pairedAt != null)
                    _buildDetailSection('配对信息', [
                      _DetailItem(
                        icon: Icons.calendar_today, 
                        label: '配对时间', 
                        value: '${device.pairedAt!.year}-${device.pairedAt!.month.toString().padLeft(2, '0')}-${device.pairedAt!.day.toString().padLeft(2, '0')}',
                      ),
                    ]),
                ],
              ),
            ),
            // 底部操作按钮
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteDevice(device);
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: const Text('删除设备', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          device.isConnected ? _disconnectDevice(device) : _connectDevice(device);
                        },
                        icon: Icon(device.isConnected ? Icons.link_off : Icons.link),
                        label: Text(device.isConnected ? '断开连接' : '连接设备'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建详情区块
  Widget _buildDetailSection(String title, List<_DetailItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: items.map((item) => _buildDetailRow(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(_DetailItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(item.icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const Spacer(),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: item.valueColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                '添加新设备',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.qr_code_scanner,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('扫描二维码'),
                subtitle: const Text('扫描设备上的配对二维码'),
                onTap: () {
                  Navigator.pop(context);
                  _showQRScanner();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('手动输入'),
                subtitle: const Text('输入设备配对码'),
                onTap: () {
                  Navigator.pop(context);
                  _showManualInput();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRScanner() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: QRScanner(
          onScan: (code) {
            Navigator.pop(context);
            _addDevice(code);
          },
        ),
      ),
    );
  }

  void _showManualInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('手动输入配对码'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '请输入设备配对码',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                _addDevice(controller.text);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

/// 详情项数据类
class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}