import 'package:flutter/material.dart';

/// 设备类型枚举
enum DeviceType {
  mobile,
  desktop,
  tablet,
  laptop,
  unknown,
}

/// 设备平台
enum DevicePlatform {
  android,
  ios,
  windows,
  macos,
  linux,
  web,
  unknown,
}

/// 设备状态
enum DeviceConnectionStatus {
  connected,
  disconnected,
  offline,
}

/// 设备数据模型
class DeviceModel {
  final String id;
  final String name;
  final DeviceType type;
  final DevicePlatform platform;
  final String ipAddress;
  final DeviceConnectionStatus status;
  final DateTime? lastSeen;
  final DateTime? pairedAt;
  final Map<String, dynamic>? metadata;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.platform,
    required this.ipAddress,
    required this.status,
    this.lastSeen,
    this.pairedAt,
    this.metadata,
  });

  bool get isConnected => status == DeviceConnectionStatus.connected;

  DeviceModel copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DevicePlatform? platform,
    String? ipAddress,
    DeviceConnectionStatus? status,
    DateTime? lastSeen,
    DateTime? pairedAt,
    Map<String, dynamic>? metadata,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      platform: platform ?? this.platform,
      ipAddress: ipAddress ?? this.ipAddress,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      pairedAt: pairedAt ?? this.pairedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 设备卡片组件
class DeviceCard extends StatelessWidget {
  final DeviceModel device;
  final VoidCallback? onTap;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onDelete;

  const DeviceCard({
    super.key,
    required this.device,
    this.onTap,
    this.onConnect,
    this.onDisconnect,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 设备图标
              DeviceStatus(
                isConnected: device.isConnected,
                platform: device.platform,
                size: 48,
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
                          ),
                        ),
                        if (device.isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '已连接',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getDeviceTypeName(device.type),
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.computer,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          device.ipAddress,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (device.lastSeen != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatLastSeen(device.lastSeen!),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // 操作按钮
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'connect':
                      onConnect?.call();
                      break;
                    case 'disconnect':
                      onDisconnect?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (device.isConnected)
                    const PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off),
                          SizedBox(width: 8),
                          Text('断开连接'),
                        ],
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: 'connect',
                      child: Row(
                        children: [
                          Icon(Icons.link),
                          SizedBox(width: 8),
                          Text('连接'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
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
    );
  }

  String _getDeviceTypeName(DeviceType type) {
    return switch (type) {
      DeviceType.mobile => '手机',
      DeviceType.desktop => '台式电脑',
      DeviceType.tablet => '平板',
      DeviceType.laptop => '笔记本电脑',
      DeviceType.unknown => '未知设备',
    };
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${diff.inDays}天前';
    }
  }
}

/// 设备状态指示器
class DeviceStatus extends StatelessWidget {
  final bool isConnected;
  final DevicePlatform platform;
  final double size;

  const DeviceStatus({
    super.key,
    required this.isConnected,
    required this.platform,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getPlatformIcon();

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: size * 0.5),
        ),
        if (isConnected)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  (IconData, Color) _getPlatformIcon() {
    return switch (platform) {
      DevicePlatform.android => (Icons.android, Colors.green),
      DevicePlatform.ios => (Icons.apple, Colors.grey),
      DevicePlatform.windows => (Icons.desktop_windows, Colors.blue),
      DevicePlatform.macos => (Icons.laptop_mac, Colors.grey),
      DevicePlatform.linux => (Icons.computer, Colors.orange),
      DevicePlatform.web => (Icons.language, Colors.blue),
      DevicePlatform.unknown => (Icons.devices, Colors.grey),
    };
  }
}

/// 设备操作按钮组件
class DeviceActions extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final VoidCallback? onDelete;
  final VoidCallback? onViewDetails;
  final bool compact;

  const DeviceActions({
    super.key,
    required this.isConnected,
    this.onConnect,
    this.onDisconnect,
    this.onDelete,
    this.onViewDetails,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isConnected ? Icons.link_off : Icons.link),
            onPressed: isConnected ? onDisconnect : onConnect,
            tooltip: isConnected ? '断开' : '连接',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: onViewDetails,
            tooltip: '详情',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: onDelete,
            tooltip: '删除',
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: isConnected ? onDisconnect : onConnect,
            icon: Icon(isConnected ? Icons.link_off : Icons.link),
            label: Text(isConnected ? '断开' : '连接'),
          ),
        ),
      ],
    );
  }
}

/// 设备详情组件
class DeviceDetailInfo extends StatelessWidget {
  final List<DeviceDetailItem> items;

  const DeviceDetailInfo({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) => _buildItem(context, item)).toList(),
    );
  }

  Widget _buildItem(BuildContext context, DeviceDetailItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
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
}

/// 设备详情项
class DeviceDetailItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const DeviceDetailItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
}

/// 设备列表组件
class DeviceList extends StatelessWidget {
  final List<DeviceModel> devices;
  final void Function(DeviceModel)? onTap;
  final void Function(DeviceModel)? onConnect;
  final void Function(DeviceModel)? onDisconnect;
  final void Function(DeviceModel)? onDelete;
  final bool showDividers;

  const DeviceList({
    super.key,
    required this.devices,
    this.onTap,
    this.onConnect,
    this.onDisconnect,
    this.onDelete,
    this.showDividers = false,
  });

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const _EmptyDeviceView();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: devices.length,
      itemBuilder: (context, index) {
        final device = devices[index];
        return Column(
          children: [
            DeviceCard(
              device: device,
              onTap: () => onTap?.call(device),
              onConnect: () => onConnect?.call(device),
              onDisconnect: () => onDisconnect?.call(device),
              onDelete: () => onDelete?.call(device),
            ),
            if (showDividers && index < devices.length - 1)
              Divider(
                height: 1,
                indent: 80,
                endIndent: 16,
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
              ),
          ],
        );
      },
    );
  }
}

/// 空状态视图
class _EmptyDeviceView extends StatelessWidget {
  const _EmptyDeviceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.devices_other,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无设备',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加设备以开始使用',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 设备筛选组件
class DeviceFilter extends StatelessWidget {
  final String? selectedPlatform;
  final bool? showConnected;
  final void Function(String?)? onPlatformChanged;
  final void Function(bool?)? onConnectionChanged;

  const DeviceFilter({
    super.key,
    this.selectedPlatform,
    this.showConnected,
    this.onPlatformChanged,
    this.onConnectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            label: const Text('全部'),
            selected: selectedPlatform == null,
            onSelected: (_) => onPlatformChanged?.call(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('手机'),
            selected: selectedPlatform == 'mobile',
            onSelected: (_) => onPlatformChanged?.call('mobile'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('电脑'),
            selected: selectedPlatform == 'desktop',
            onSelected: (_) => onPlatformChanged?.call('desktop'),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('平板'),
            selected: selectedPlatform == 'tablet',
            onSelected: (_) => onPlatformChanged?.call('tablet'),
          ),
          const SizedBox(width: 16),
          FilterChip(
            label: const Text('仅显示已连接'),
            selected: showConnected == true,
            onSelected: (_) => onConnectionChanged?.call(showConnected == true ? null : true),
          ),
        ],
      ),
    );
  }
}