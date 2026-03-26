import 'package:flutter/material.dart';
import '../widgets/enhanced_animations.dart';
import '../widgets/animated_connection_indicator.dart';

/// 增强版设备管理界面
/// 包含动画效果、滑动操作、下拉刷新等功能

/// 设备信息类
class EnhancedDeviceInfo {
  final String id;
  final String name;
  final String type;
  final String platform;
  final String ipAddress;
  bool isConnected;
  String? lastSeen;
  DateTime? pairedAt;
  String? firmwareVersion;
  int? batteryLevel;
  bool canReadCredentials;
  bool canWriteCredentials;
  bool canExportData;
  bool requiresBiometric;
  bool isTrusted;

  EnhancedDeviceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.isConnected,
    this.lastSeen,
    required this.platform,
    required this.ipAddress,
    this.pairedAt,
    this.firmwareVersion,
    this.batteryLevel,
    this.canReadCredentials = true,
    this.canWriteCredentials = true,
    this.canExportData = true,
    this.requiresBiometric = false,
    this.isTrusted = false,
  });

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

  IconData get typeIcon {
    switch (type.toLowerCase()) {
      case 'mobile phone':
      case 'phone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet_mac;
      case 'desktop computer':
      case 'desktop':
        return Icons.desktop_windows;
      case 'laptop':
        return Icons.laptop;
      default:
        return Icons.devices_other;
    }
  }

  Color get statusColor => isConnected ? Colors.green : Colors.grey;
}

/// 设备管理增强版界面
class DevicesScreenEnhanced extends StatefulWidget {
  const DevicesScreenEnhanced({super.key});

  @override
  State<DevicesScreenEnhanced> createState() => _DevicesScreenEnhancedState();
}

class _DevicesScreenEnhancedState extends State<DevicesScreenEnhanced>
    with TickerProviderStateMixin {
  final List<EnhancedDeviceInfo> _devices = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _filterStatus = 'all'; // 'all', 'connected', 'disconnected'

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _loadDevices();

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() => _isLoading = true);

    // 模拟加载延迟
    await Future.delayed(const Duration(milliseconds: 800));

    // 示例数据
    _devices.addAll([
      EnhancedDeviceInfo(
        id: '1',
        name: '我的iPhone 15 Pro',
        type: 'Mobile Phone',
        isConnected: true,
        platform: 'iOS',
        ipAddress: '192.168.1.100',
        pairedAt: DateTime.now().subtract(const Duration(days: 30)),
        firmwareVersion: '1.2.0',
        batteryLevel: 85,
        isTrusted: true,
      ),
      EnhancedDeviceInfo(
        id: '2',
        name: 'MacBook Pro',
        type: 'Laptop',
        isConnected: true,
        platform: 'macOS',
        ipAddress: '192.168.1.101',
        pairedAt: DateTime.now().subtract(const Duration(days: 60)),
        firmwareVersion: '1.1.8',
        isTrusted: true,
      ),
      EnhancedDeviceInfo(
        id: '3',
        name: 'Windows台式机',
        type: 'Desktop Computer',
        isConnected: false,
        lastSeen: '2小时前',
        platform: 'Windows',
        ipAddress: '192.168.1.102',
        pairedAt: DateTime.now().subtract(const Duration(days: 15)),
        firmwareVersion: '1.1.5',
      ),
      EnhancedDeviceInfo(
        id: '4',
        name: 'iPad Air',
        type: 'Tablet',
        isConnected: false,
        lastSeen: '1天前',
        platform: 'iOS',
        ipAddress: '192.168.1.103',
        pairedAt: DateTime.now().subtract(const Duration(days: 7)),
        firmwareVersion: '1.2.0',
        batteryLevel: 45,
      ),
    ]);

    setState(() => _isLoading = false);
  }

  List<EnhancedDeviceInfo> get _filteredDevices {
    switch (_filterStatus) {
      case 'connected':
        return _devices.where((d) => d.isConnected).toList();
      case 'disconnected':
        return _devices.where((d) => !d.isConnected).toList();
      default:
        return _devices;
    }
  }

  int get _connectedCount => _devices.where((d) => d.isConnected).length;
  int get _disconnectedCount => _devices.where((d) => !d.isConnected).length;

  Future<void> _refreshDevices() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _refreshDevices,
              child: CustomScrollView(
                slivers: [
                  // 自定义AppBar
                  SliverAppBar(
                    expandedHeight: 120,
                    floating: true,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      title: const Text(
                        '设备管理',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).colorScheme.primaryContainer,
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () => _showSearch(),
                        tooltip: '搜索设备',
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        onSelected: (value) {
                          setState(() => _filterStatus = value);
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('全部设备'),
                          ),
                          const PopupMenuItem(
                            value: 'connected',
                            child: Text('仅显示已连接'),
                          ),
                          const PopupMenuItem(
                            value: 'disconnected',
                            child: Text('仅显示离线'),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 统计卡片
                  SliverToBoxAdapter(
                    child: _buildStatsCards(),
                  ),

                  // 设备列表
                  if (_filteredDevices.isEmpty)
                    SliverFillRemaining(
                      child: _buildEmptyState(),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final device = _filteredDevices[index];
                          return StaggeredListAnimation(
                            index: index,
                            child: _buildDismissibleDeviceCard(device),
                          );
                        },
                        childCount: _filteredDevices.length,
                      ),
                    ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showAddDeviceSheet,
          icon: const Icon(Icons.add),
          label: const Text('添加设备'),
          elevation: 4,
        ),
      ),
    );
  }

  /// 加载状态骨架屏
  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          title: Text('设备管理'),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Container(
              height: 100,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            childCount: 4,
          ),
        ),
      ],
    );
  }

  /// 统计卡片
  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.check_circle,
            label: '已连接',
            value: _connectedCount,
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.cloud_off,
            label: '离线',
            value: _disconnectedCount,
            color: Colors.grey,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.devices,
            label: '总计',
            value: _devices.length,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: ScaleBounce(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 28,
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
        ),
      ),
    );
  }

  /// 可滑动删除的设备卡片
  Widget _buildDismissibleDeviceCard(EnhancedDeviceInfo device) {
    return Dismissible(
      key: Key(device.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmDialog(device);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 32),
            SizedBox(height: 4),
            Text(
              '删除',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      child: _buildDeviceCard(device),
    );
  }

  /// 设备卡片
  Widget _buildDeviceCard(EnhancedDeviceInfo device) {
    return HeroTransitionWrapper(
      tag: 'device_${device.id}',
      onTap: () => _showDeviceDetail(device),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: device.isConnected
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            width: device.isConnected ? 2 : 1,
          ),
          boxShadow: device.isConnected
              ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showDeviceDetail(device),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 设备图标与状态
                  Stack(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          device.typeIcon,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      // 状态指示器
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: device.statusColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: device.isConnected
                              ? const Icon(Icons.link, size: 10, color: Colors.white)
                              : Icon(Icons.link_off, size: 10, color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                      // 信任标记
                      if (device.isTrusted)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.verified, size: 10, color: Colors.white),
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                device.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (device.batteryLevel != null)
                              _buildBatteryIndicator(device.batteryLevel!),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(device.platformIcon, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              device.platform,
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.network_check, size: 14, color: device.statusColor),
                            const SizedBox(width: 4),
                            Text(
                              device.isConnected ? '已连接' : (device.lastSeen ?? '离线'),
                              style: TextStyle(fontSize: 13, color: device.statusColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.router, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              device.ipAddress,
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 快速操作按钮
                  _buildQuickAction(device),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 电池指示器
  Widget _buildBatteryIndicator(int level) {
    Color color;
    if (level > 60) {
      color = Colors.green;
    } else if (level > 20) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_std, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            '$level%',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  /// 快速操作按钮
  Widget _buildQuickAction(EnhancedDeviceInfo device) {
    return RippleButton(
      borderRadius: BorderRadius.circular(12),
      onPressed: () => device.isConnected
          ? _disconnectDevice(device)
          : _connectDevice(device),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: device.statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          device.isConnected ? Icons.link_off : Icons.link,
          color: device.statusColor,
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleBounce(
            child: Icon(
              Icons.devices_other,
              size: 80,
              color: Colors.grey[300],
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            offset: const Offset(0, 20),
            child: Text(
              _filterStatus == 'all' ? '暂无设备' : '没有符合条件的设备',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            offset: const Offset(0, 20),
            delay: const Duration(milliseconds: 100),
            child: Text(
              '点击下方按钮添加您的第一个设备',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示设备详情
  void _showDeviceDetail(EnhancedDeviceInfo device) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DeviceDetailSheet(
        device: device,
        onConnect: () => _connectDevice(device),
        onDisconnect: () => _disconnectDevice(device),
        onDelete: () => _deleteDevice(device),
        onUpdatePermissions: (permissions) => _updatePermissions(device, permissions),
      ),
    );
  }

  /// 连接设备
  void _connectDevice(EnhancedDeviceInfo device) {
    setState(() {
      device.isConnected = true;
      device.lastSeen = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已连接到 ${device.name}'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '查看详情',
          onPressed: () => _showDeviceDetail(device),
        ),
      ),
    );
  }

  /// 断开设备
  void _disconnectDevice(EnhancedDeviceInfo device) {
    setState(() {
      device.isConnected = false;
      device.lastSeen = '刚刚';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已断开 ${device.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 删除设备
  void _deleteDevice(EnhancedDeviceInfo device) {
    setState(() => _devices.removeWhere((d) => d.id == device.id));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已删除 ${device.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 更新设备权限
  void _updatePermissions(EnhancedDeviceInfo device, Map<String, bool> permissions) {
    setState(() {
      device.canReadCredentials = permissions['read'] ?? device.canReadCredentials;
      device.canWriteCredentials = permissions['write'] ?? device.canWriteCredentials;
      device.canExportData = permissions['export'] ?? device.canExportData;
      device.requiresBiometric = permissions['biometric'] ?? device.requiresBiometric;
    });
  }

  /// 删除确认对话框
  Future<bool> _showDeleteConfirmDialog(EnhancedDeviceInfo device) async {
    return await showDialog<bool>(
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
            Text('确定要删除 "${device.name}" 吗？'),
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
                      '此操作不可撤销',
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
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 添加设备弹窗
  void _showAddDeviceSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddDeviceSheet(
        onDeviceAdded: (device) {
          setState(() => _devices.add(device));
        },
      ),
    );
  }

  /// 搜索设备
  void _showSearch() {
    showSearch(
      context: context,
      delegate: _DeviceSearchDelegate(_devices),
    );
  }
}

/// 设备详情底部弹窗
class _DeviceDetailSheet extends StatefulWidget {
  final EnhancedDeviceInfo device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onDelete;
  final void Function(Map<String, bool>) onUpdatePermissions;

  const _DeviceDetailSheet({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
    required this.onDelete,
    required this.onUpdatePermissions,
  });

  @override
  State<_DeviceDetailSheet> createState() => _DeviceDetailSheetState();
}

class _DeviceDetailSheetState extends State<_DeviceDetailSheet> {
  late bool _canRead;
  late bool _canWrite;
  late bool _canExport;
  late bool _requireBiometric;

  @override
  void initState() {
    super.initState();
    _canRead = widget.device.canReadCredentials;
    _canWrite = widget.device.canWriteCredentials;
    _canExport = widget.device.canExportData;
    _requireBiometric = widget.device.requiresBiometric;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          _buildHeader(),
          const Divider(),
          // 内容
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildInfoSection('设备信息', [
                  _buildInfoItem(Icons.devices, '名称', widget.device.name),
                  _buildInfoItem(widget.device.platformIcon, '平台', widget.device.platform),
                  _buildInfoItem(Icons.category, '类型', widget.device.type),
                  if (widget.device.firmwareVersion != null)
                    _buildInfoItem(Icons.memory, '固件版本', widget.device.firmwareVersion!),
                ]),
                _buildInfoSection('网络信息', [
                  _buildInfoItem(Icons.router, 'IP地址', widget.device.ipAddress),
                  _buildInfoItem(
                    Icons.network_check,
                    '状态',
                    widget.device.isConnected ? '已连接' : '离线',
                    valueColor: widget.device.statusColor,
                  ),
                  if (widget.device.lastSeen != null)
                    _buildInfoItem(Icons.schedule, '最后在线', widget.device.lastSeen!),
                ]),
                if (widget.device.pairedAt != null)
                  _buildInfoSection('配对信息', [
                    _buildInfoItem(
                      Icons.calendar_today,
                      '配对时间',
                      _formatDate(widget.device.pairedAt!),
                    ),
                  ]),
                _buildPermissionSection(),
              ],
            ),
          ),
          // 底部操作栏
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          HeroTransitionWrapper(
            tag: 'device_${widget.device.id}',
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    widget.device.typeIcon,
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
                      color: widget.device.statusColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: widget.device.isConnected
                        ? const Icon(Icons.link, size: 14, color: Colors.white)
                        : Icon(Icons.link_off, size: 14, color: Colors.white.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.device.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.device.isConnected ? '已连接' : '未连接',
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.device.statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (widget.device.isTrusted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 14, color: Colors.blue),
                            SizedBox(width: 4),
                            Text(
                              '已信任',
                              style: TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
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
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            '访问权限',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600]),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildPermissionTile(
                icon: Icons.visibility,
                iconColor: Colors.blue,
                title: '读取凭证',
                subtitle: '允许查看存储的凭证',
                value: _canRead,
                onChanged: (v) => setState(() => _canRead = v),
              ),
              _buildPermissionTile(
                icon: Icons.edit,
                iconColor: Colors.green,
                title: '写入凭证',
                subtitle: '允许添加或修改凭证',
                value: _canWrite,
                onChanged: (v) => setState(() => _canWrite = v),
              ),
              _buildPermissionTile(
                icon: Icons.download,
                iconColor: Colors.orange,
                title: '导出数据',
                subtitle: '允许导出凭证数据',
                value: _canExport,
                onChanged: (v) => setState(() => _canExport = v),
              ),
              _buildPermissionTile(
                icon: Icons.fingerprint,
                iconColor: Colors.purple,
                title: '生物识别',
                subtitle: '访问时需要验证身份',
                value: _requireBiometric,
                onChanged: (v) => setState(() => _requireBiometric = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: iconColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
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
                  widget.onDelete();
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text('删除', style: TextStyle(color: Colors.red)),
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
                  widget.onUpdatePermissions({
                    'read': _canRead,
                    'write': _canWrite,
                    'export': _canExport,
                    'biometric': _requireBiometric,
                  });
                  Navigator.pop(context);
                  widget.device.isConnected ? widget.onDisconnect() : widget.onConnect();
                },
                icon: Icon(widget.device.isConnected ? Icons.link_off : Icons.link),
                label: Text(widget.device.isConnected ? '断开连接' : '连接设备'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 添加设备弹窗
class _AddDeviceSheet extends StatefulWidget {
  final void Function(EnhancedDeviceInfo) onDeviceAdded;

  const _AddDeviceSheet({required this.onDeviceAdded});

  @override
  State<_AddDeviceSheet> createState() => _AddDeviceSheetState();
}

class _AddDeviceSheetState extends State<_AddDeviceSheet> {
  int _currentStep = 0;
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Text(
                  '添加新设备',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                _buildStepContent(),
                const SizedBox(height: 24),
                _buildStepIndicator(),
                const SizedBox(height: 24),
                _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildMethodSelection();
      case 1:
        return _buildInputStep();
      case 2:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildMethodSelection() {
    return Column(
      children: [
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
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _currentStep = 1),
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
              Icons.keyboard,
              color: Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
          title: const Text('手动输入'),
          subtitle: const Text('输入设备配对码'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => setState(() => _currentStep = 1),
        ),
      ],
    );
  }

  Widget _buildInputStep() {
    return Column(
      children: [
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(
            labelText: '配对码',
            hintText: 'PV-XXXX-XXXX',
            prefixIcon: Icon(Icons.vpn_key),
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '设备名称（可选）',
            hintText: '例如：我的手机',
            prefixIcon: Icon(Icons.devices),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Column(
      children: [
        const SuccessAnimation(size: 100),
        const SizedBox(height: 24),
        const Text(
          '设备添加成功！',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentStep
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[300],
          ),
        );
      }),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        if (_currentStep > 0 && _currentStep < 2)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('上一步'),
            ),
          ),
        if (_currentStep > 0 && _currentStep < 2) const SizedBox(width: 16),
        Expanded(
          child: FilledButton(
            onPressed: _handleNext,
            child: Text(_currentStep == 2 ? '完成' : '下一步'),
          ),
        ),
      ],
    );
  }

  void _handleNext() {
    if (_currentStep == 1) {
      // 模拟配对成功
      widget.onDeviceAdded(EnhancedDeviceInfo(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.isNotEmpty ? _nameController.text : '新设备',
        type: 'Unknown',
        isConnected: true,
        platform: 'Unknown',
        ipAddress: '192.168.1.xxx',
        pairedAt: DateTime.now(),
      ));
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      Navigator.pop(context);
    } else {
      setState(() => _currentStep++);
    }
  }
}

/// 设备搜索代理
class _DeviceSearchDelegate extends SearchDelegate<EnhancedDeviceInfo?> {
  final List<EnhancedDeviceInfo> devices;

  _DeviceSearchDelegate(this.devices);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = devices.where((d) =>
        d.name.toLowerCase().contains(query.toLowerCase()) ||
        d.platform.toLowerCase().contains(query.toLowerCase()) ||
        d.ipAddress.contains(query)).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final device = results[index];
        return ListTile(
          leading: Icon(device.typeIcon),
          title: Text(device.name),
          subtitle: Text('${device.platform} · ${device.ipAddress}'),
          trailing: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: device.statusColor,
              shape: BoxShape.circle,
            ),
          ),
          onTap: () => close(context, device),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}