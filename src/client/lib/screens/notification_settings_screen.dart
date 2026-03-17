import 'package:flutter/material.dart';

/// 通知设置页面
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // 通知总开关
  bool _notificationsEnabled = true;
  
  // 安全通知
  bool _securityAlerts = true;
  bool _newDeviceAlerts = true;
  bool _credentialAccessAlerts = true;
  
  // 系统通知
  bool _systemUpdates = true;
  bool _backupReminders = true;
  bool _syncNotifications = true;
  
  // 消息通知
  bool _messageNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  
  // 通知样式
  bool _showContent = true;
  bool _lockScreenNotifications = true;
  bool _bannerStyle = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 通知总开关
          _buildSectionHeader('通知'),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications, color: theme.colorScheme.onPrimaryContainer, size: 20),
              ),
              title: const Text('启用通知'),
              subtitle: const Text('接收应用通知'),
              value: _notificationsEnabled,
              onChanged: (value) => setState(() => _notificationsEnabled = value),
            ),
          ),

          if (_notificationsEnabled) ...[
            const SizedBox(height: 16),

            // 安全通知
            _buildSectionHeader('安全通知'),
            _buildSwitchTile(
              icon: Icons.security,
              title: '安全提醒',
              subtitle: '异常登录、密码泄露等',
              value: _securityAlerts,
              onChanged: (v) => setState(() => _securityAlerts = v),
            ),
            _buildSwitchTile(
              icon: Icons.devices,
              title: '新设备提醒',
              subtitle: '新设备访问凭证时通知',
              value: _newDeviceAlerts,
              onChanged: (v) => setState(() => _newDeviceAlerts = v),
            ),
            _buildSwitchTile(
              icon: Icons.vpn_key,
              title: '凭证访问提醒',
              subtitle: '凭证被访问时通知',
              value: _credentialAccessAlerts,
              onChanged: (v) => setState(() => _credentialAccessAlerts = v),
            ),

            const SizedBox(height: 16),

            // 系统通知
            _buildSectionHeader('系统通知'),
            _buildSwitchTile(
              icon: Icons.system_update,
              title: '系统更新',
              subtitle: '版本更新、功能改进',
              value: _systemUpdates,
              onChanged: (v) => setState(() => _systemUpdates = v),
            ),
            _buildSwitchTile(
              icon: Icons.backup,
              title: '备份提醒',
              subtitle: '定期备份提示',
              value: _backupReminders,
              onChanged: (v) => setState(() => _backupReminders = v),
            ),
            _buildSwitchTile(
              icon: Icons.sync,
              title: '同步通知',
              subtitle: '数据同步状态',
              value: _syncNotifications,
              onChanged: (v) => setState(() => _syncNotifications = v),
            ),

            const SizedBox(height: 16),

            // 消息通知
            _buildSectionHeader('消息通知'),
            _buildSwitchTile(
              icon: Icons.message,
              title: '消息推送',
              subtitle: '接收新消息通知',
              value: _messageNotifications,
              onChanged: (v) => setState(() => _messageNotifications = v),
            ),

            const SizedBox(height: 16),

            // 通知样式
            _buildSectionHeader('通知样式'),
            _buildSwitchTile(
              icon: Icons.speaker,
              title: '声音',
              subtitle: '通知提示音',
              value: _soundEnabled,
              onChanged: (v) => setState(() => _soundEnabled = v),
            ),
            _buildSwitchTile(
              icon: Icons.vibration,
              title: '震动',
              subtitle: '手机震动提示',
              value: _vibrationEnabled,
              onChanged: (v) => setState(() => _vibrationEnabled = v),
            ),
            _buildSwitchTile(
              icon: Icons.text_snippet,
              title: '显示详情',
              subtitle: '锁屏显示消息内容',
              value: _showContent,
              onChanged: (v) => setState(() => _showContent = v),
            ),
            _buildSwitchTile(
              icon: Icons.lock,
              title: '锁屏通知',
              subtitle: '锁屏上显示通知',
              value: _lockScreenNotifications,
              onChanged: (v) => setState(() => _lockScreenNotifications = v),
            ),
            _buildSwitchTile(
              icon: Icons.badge,
              title: '横幅通知',
              subtitle: '顶部横幅显示',
              value: _bannerStyle,
              onChanged: (v) => setState(() => _bannerStyle = v),
            ),

            const SizedBox(height: 16),

            // 通知时间
            _buildSectionHeader('通知时间'),
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.schedule, color: theme.colorScheme.onPrimaryContainer, size: 20),
                ),
                title: const Text('勿扰模式'),
                subtitle: const Text('22:00 - 08:00'),
                trailing: Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
                onTap: _showDoNotDisturbSettings,
              ),
            ),

            const SizedBox(height: 16),

            // 通知渠道
            _buildSectionHeader('通知渠道'),
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.email, color: Colors.blue, size: 20),
                    ),
                    title: const Text('邮件通知'),
                    subtitle: const Text('security@example.com'),
                    trailing: Switch(
                      value: true,
                      onChanged: (v) {},
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.sms, color: Colors.green, size: 20),
                    ),
                    title: const Text('短信通知'),
                    subtitle: const Text('+86 138****8888'),
                    trailing: Switch(
                      value: false,
                      onChanged: (v) {},
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // 保存按钮
          FilledButton(
            onPressed: _saveSettings,
            child: const Text('保存设置'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer, size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  void _showDoNotDisturbSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('勿扰模式设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.nightlight_round),
              title: const Text('启用勿扰'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('开始时间'),
              trailing: const Text('22:00'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.access_time_filled),
              title: const Text('结束时间'),
              trailing: const Text('08:00'),
              onTap: () {},
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('通知设置已保存')),
    );
    Navigator.pop(context);
  }
}