import 'package:flutter/material.dart';

/// 连接状态指示器
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? statusText;
  final VoidCallback? onTap;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    this.statusText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isConnected
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isConnected
                  ? Colors.green.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 状态指示灯
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.orange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? Colors.green : Colors.orange)
                          .withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 状态文字
              Text(
                statusText ?? (isConnected ? '已连接' : '未连接'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isConnected ? Colors.green : Colors.orange,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: isConnected ? Colors.green : Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 设备连接状态卡片
class DeviceConnectionCard extends StatelessWidget {
  final String deviceName;
  final bool isConnected;
  final String? deviceType;
  final String? lastSeen;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;

  const DeviceConnectionCard({
    super.key,
    required this.deviceName,
    required this.isConnected,
    this.deviceType,
    this.lastSeen,
    this.onConnect,
    this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isConnected
              ? Colors.green.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 设备图标
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getDeviceIcon(),
                    size: 24,
                    color: isConnected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                // 设备信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deviceName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (deviceType != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          deviceType!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 连接状态
                ConnectionStatusIndicator(
                  isConnected: isConnected,
                ),
              ],
            ),
            if (lastSeen != null && !isConnected) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '上次在线: $lastSeen',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (isConnected && onDisconnect != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDisconnect,
                  icon: const Icon(Icons.link_off),
                  label: const Text('断开连接'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                ),
              ),
            ],
            if (!isConnected && onConnect != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onConnect,
                  icon: const Icon(Icons.link),
                  label: const Text('连接设备'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon() {
    if (deviceType == null) return Icons.devices;
    final type = deviceType!.toLowerCase();
    if (type.contains('phone') || type.contains('mobile')) {
      return Icons.smartphone;
    } else if (type.contains('computer') || type.contains('desktop')) {
      return Icons.computer;
    } else if (type.contains('tablet')) {
      return Icons.tablet;
    } else if (type.contains('laptop')) {
      return Icons.laptop;
    }
    return Icons.devices;
  }
}
