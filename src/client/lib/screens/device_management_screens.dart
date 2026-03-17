import 'package:flutter/material.dart';
import '../widgets/animated_connection_indicator.dart';

/// 设备权限设置数据模型
class DevicePermissions {
  bool canReadCredentials;
  bool canWriteCredentials;
  bool canExportData;
  bool requiresBiometric;
  int sessionTimeout; // 分钟
  bool allowOfflineAccess;
  
  DevicePermissions({
    this.canReadCredentials = true,
    this.canWriteCredentials = true,
    this.canExportData = true,
    this.requiresBiometric = false,
    this.sessionTimeout = 30,
    this.allowOfflineAccess = false,
  });
}

/// 设备权限设置页面
class DevicePermissionScreen extends StatefulWidget {
  final DeviceInfo device;
  
  const DevicePermissionScreen({super.key, required this.device});
  
  @override
  State<DevicePermissionScreen> createState() => _DevicePermissionScreenState();
}

class _DevicePermissionScreenState extends State<DevicePermissionScreen> {
  late bool _canReadCredentials;
  late bool _canWriteCredentials;
  late bool _canExportData;
  late bool _requiresBiometric;
  
  @override
  void initState() {
    super.initState();
    _canReadCredentials = widget.device.canReadCredentials;
    _canWriteCredentials = widget.device.canWriteCredentials;
    _canExportData = widget.device.canExportData;
    _requiresBiometric = widget.device.requiresBiometric;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.device.name} - 权限设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 设备信息卡片
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ConnectionPulse(isActive: widget.device.isConnected, size: 48),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.device.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(widget.device.platform, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // 权限设置标题
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text('数据访问权限', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ),
          
          // 读取凭证权限
          _buildPermissionTile(
            icon: Icons.visibility,
            iconColor: Colors.blue,
            title: '读取凭证',
            subtitle: '允许设备查看存储的凭证',
            value: _canReadCredentials,
            onChanged: (value) => setState(() => _canReadCredentials = value),
          ),
          
          // 写入凭证权限
          _buildPermissionTile(
            icon: Icons.edit,
            iconColor: Colors.green,
            title: '写入凭证',
            subtitle: '允许设备添加或修改凭证',
            value: _canWriteCredentials,
            onChanged: (value) => setState(() => _canWriteCredentials = value),
          ),
          
          // 导出数据权限
          _buildPermissionTile(
            icon: Icons.download,
            iconColor: Colors.orange,
            title: '导出数据',
            subtitle: '允许设备导出凭证数据',
            value: _canExportData,
            onChanged: (value) => setState(() => _canExportData = value),
          ),
          
          const SizedBox(height: 16),
          
          // 安全设置标题
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text('安全设置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
          ),
          
          // 生物识别要求
          _buildPermissionTile(
            icon: Icons.fingerprint,
            iconColor: Colors.purple,
            title: '生物识别验证',
            subtitle: '每次访问需验证身份',
            value: _requiresBiometric,
            onChanged: (value) => setState(() => _requiresBiometric = value),
          ),
          
          const SizedBox(height: 32),
          
          // 保存按钮
          FilledButton(
            onPressed: _savePermissions,
            child: const Text('保存设置'),
          ),
        ],
      ),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
  
  void _savePermissions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.device.name} 权限设置已保存')),
    );
    Navigator.pop(context);
  }
}

/// 设备卡片组件
class DeviceCard extends StatelessWidget {
  final DeviceInfo device;
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
      elevation: device.isConnected ? 2 : 0,
      color: device.isConnected 
          ? theme.colorScheme.primaryContainer.withOpacity(0.3) 
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 状态指示器
              ConnectionPulse(
                isActive: device.isConnected, 
                size: 48,
                color: device.isConnected ? Colors.green : Colors.grey,
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              style: TextStyle(fontSize: 12, color: Colors.green),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${device.platform} · ${device.type}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          device.lastSeen ?? (device.isConnected ? '在线' : '未知'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch(value) {
                    case 'connect':
                      onConnect?.call();
                    case 'disconnect':
                      onDisconnect?.call();
                    case 'delete':
                      onDelete?.call();
                  }
                },
                itemBuilder: (context) => [
                  if (!device.isConnected)
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
                  if (device.isConnected)
                    const PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off),
                          SizedBox(width: 8),
                          Text('断开'),
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
}

/// 空状态组件
class DeviceEmptyState extends StatelessWidget {
  final VoidCallback? onAddDevice;
  
  const DeviceEmptyState({super.key, this.onAddDevice});
  
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
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无设备',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加您的第一个设备开始使用',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddDevice,
            icon: const Icon(Icons.add),
            label: const Text('添加设备'),
          ),
        ],
      ),
    );
  }
}

/// 设备列表刷新头
class DeviceListHeader extends StatelessWidget {
  final int totalCount;
  final int connectedCount;
  final bool isRefreshing;
  
  const DeviceListHeader({
    super.key,
    required this.totalCount,
    required this.connectedCount,
    this.isRefreshing = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.devices,
              value: totalCount.toString(),
              label: '总设备数',
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.link,
              value: connectedCount.toString(),
              label: '已连接',
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.link_off,
              value: (totalCount - connectedCount).toString(),
              label: '未连接',
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Re-export DeviceInfo from devices_screen.dart
export 'devices_screen.dart' show DeviceInfo;