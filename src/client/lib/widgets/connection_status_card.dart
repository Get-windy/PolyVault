import 'package:flutter/material.dart';

/// 设备连接状态数据模型
class DeviceConnectionStatus {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final bool isConnected;
  final DateTime? lastConnected;
  final String? ipAddress;

  const DeviceConnectionStatus({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    this.isConnected = false,
    this.lastConnected,
    this.ipAddress,
  });
}

/// 连接状态卡片 - 用于首页展示设备连接状态
class ConnectionStatusCard extends StatelessWidget {
  final List<DeviceConnectionStatus>? devices;
  final VoidCallback? onTap;
  final bool isLoading;

  const ConnectionStatusCard({
    super.key,
    this.devices,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // 计算连接状态
    final connectedCount = devices?.where((d) => d.isConnected).length ?? 0;
    final totalCount = devices?.length ?? 0;
    final isAnyConnected = connectedCount > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAnyConnected
              ? Colors.green.withOpacity(0.3)
              : colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 状态图标
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isAnyConnected
                          ? Colors.green.withOpacity(0.1)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Icon(
                            isAnyConnected ? Icons.link : Icons.link_off,
                            color: isAnyConnected ? Colors.green : colorScheme.outline,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // 状态信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '设备连接状态',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAnyConnected
                              ? '已连接 $connectedCount/$totalCount 台设备'
                              : '暂无设备连接',
                          style: TextStyle(
                            fontSize: 13,
                            color: isAnyConnected
                                ? Colors.green
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 状态指示灯
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isAnyConnected ? Colors.green : Colors.orange,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isAnyConnected ? Colors.green : Colors.orange)
                              .withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // 已连接设备列表预览
              if (isAnyConnected && devices != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                ...devices!
                    .where((d) => d.isConnected)
                    .take(3)
                    .map((device) => _buildDeviceItem(device, colorScheme)),
                if (connectedCount > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '还有 ${connectedCount - 3} 台设备...',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceItem(DeviceConnectionStatus device, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            _getDeviceIcon(device.deviceType),
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              device.deviceName,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (device.ipAddress != null)
            Text(
              device.ipAddress!,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    final type = deviceType.toLowerCase();
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

/// 简化版连接状态卡片
class SimpleConnectionStatusCard extends StatelessWidget {
  final bool isConnected;
  final String? statusText;
  final String? connectedDeviceName;
  final VoidCallback? onTap;

  const SimpleConnectionStatusCard({
    super.key,
    required this.isConnected,
    this.statusText,
    this.connectedDeviceName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isConnected
                      ? Colors.green.withOpacity(0.1)
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConnected ? Icons.link : Icons.link_off,
                  color: isConnected ? Colors.green : colorScheme.outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? '已连接' : '未连接',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (connectedDeviceName != null || statusText != null)
                      Text(
                        connectedDeviceName ?? statusText ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
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
            ],
          ),
        ),
      ),
    );
  }
}