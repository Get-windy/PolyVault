import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 安全设置页面
class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _biometricEnabled = true;
  bool _pinEnabled = false;
  bool _autoLockEnabled = true;
  int _autoLockMinutes = 5;
  bool _clipboardClearEnabled = true;
  int _clipboardClearSeconds = 30;
  bool _sessionTimeoutEnabled = true;
  int _sessionTimeoutMinutes = 30;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('安全设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 认证方式
          _buildSectionHeader('认证方式'),
          _buildSettingTile(
            icon: Icons.fingerprint,
            title: '生物识别',
            subtitle: '指纹或面容ID',
            trailing: Switch(
              value: _biometricEnabled,
              onChanged: (value) => setState(() => _biometricEnabled = value),
            ),
          ),
          _buildSettingTile(
            icon: Icons.pin,
            title: 'PIN码',
            subtitle: _pinEnabled ? '已启用' : '未启用',
            trailing: Switch(
              value: _pinEnabled,
              onChanged: (value) => setState(() => _pinEnabled = value),
            ),
          ),
          if (_pinEnabled)
            _buildSettingTile(
              icon: Icons.edit,
              title: '修改PIN码',
              subtitle: '更改PIN码',
              onTap: () => _showChangePinDialog(),
            ),

          const SizedBox(height: 24),

          // 自动锁定
          _buildSectionHeader('自动锁定'),
          _buildSettingTile(
            icon: Icons.lock_clock,
            title: '自动锁定',
            subtitle: '离开应用后自动锁定',
            trailing: Switch(
              value: _autoLockEnabled,
              onChanged: (value) => setState(() => _autoLockEnabled = value),
            ),
          ),
          if (_autoLockEnabled)
            _buildSettingTile(
              icon: Icons.timer,
              title: '锁定时间',
              subtitle: '$_autoLockMinutes 分钟',
              onTap: () => _showAutoLockPicker(),
            ),

          const SizedBox(height: 24),

          // 剪贴板安全
          _buildSectionHeader('剪贴板安全'),
          _buildSettingTile(
            icon: Icons.content_paste,
            title: '自动清除剪贴板',
            subtitle: '复制敏感内容后自动清除',
            trailing: Switch(
              value: _clipboardClearEnabled,
              onChanged: (value) => setState(() => _clipboardClearEnabled = value),
            ),
          ),
          if (_clipboardClearEnabled)
            _buildSettingTile(
              icon: Icons.timer,
              title: '清除时间',
              subtitle: '$_clipboardClearSeconds 秒后清除',
              onTap: () => _showClipboardClearPicker(),
            ),

          const SizedBox(height: 24),

          // 会话管理
          _buildSectionHeader('会话管理'),
          _buildSettingTile(
            icon: Icons.session,
            title: '会话超时',
            subtitle: '长时间无操作后退出登录',
            trailing: Switch(
              value: _sessionTimeoutEnabled,
              onChanged: (value) => setState(() => _sessionTimeoutEnabled = value),
            ),
          ),
          if (_sessionTimeoutEnabled)
            _buildSettingTile(
              icon: Icons.timer,
              title: '超时时间',
              subtitle: '$_sessionTimeoutMinutes 分钟',
              onTap: () => _showSessionTimeoutPicker(),
            ),

          const SizedBox(height: 24),

          // 高级安全
          _buildSectionHeader('高级安全'),
          _buildSettingTile(
            icon: Icons.enhanced_encryption,
            title: '加密算法',
            subtitle: 'AES-256-GCM',
            enabled: false,
          ),
          _buildSettingTile(
            icon: Icons.key,
            title: '密钥管理',
            subtitle: '管理加密密钥',
            onTap: () => _showKeyManagementDialog(),
          ),
          _buildSettingTile(
            icon: Icons.security,
            title: '安全审计日志',
            subtitle: '查看安全事件记录',
            onTap: () {},
          ),

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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        enabled: enabled,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13)),
        trailing: trailing ??
            (onTap != null ? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant) : null),
        onTap: onTap,
      ),
    );
  }

  void _showChangePinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改PIN码'),
        content: const Text('PIN码修改功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAutoLockPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择自动锁定时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...[1, 5, 10, 30, 60].map((minutes) => ListTile(
              title: Text('$minutes 分钟'),
              trailing: _autoLockMinutes == minutes ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _autoLockMinutes = minutes);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showClipboardClearPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择清除时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...[10, 30, 60, 120].map((seconds) => ListTile(
              title: Text('$seconds 秒'),
              trailing: _clipboardClearSeconds == seconds ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _clipboardClearSeconds = seconds);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showSessionTimeoutPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择会话超时时间', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            ...[5, 15, 30, 60, 120].map((minutes) => ListTile(
              title: Text('$minutes 分钟'),
              trailing: _sessionTimeoutMinutes == minutes ? const Icon(Icons.check) : null,
              onTap: () {
                setState(() => _sessionTimeoutMinutes = minutes);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showKeyManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('密钥管理'),
        content: const Text('密钥管理功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('安全设置已保存')),
    );
    Navigator.pop(context);
  }
}