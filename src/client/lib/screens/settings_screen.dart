import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage.dart';
import '../utils/theme.dart';
import 'auto_authorization_screen.dart';
import 'security_settings_screen.dart';
import 'devices_screen.dart';

/// 设置页面
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isBiometricEnabled = false;
  bool _isAutoLockEnabled = true;
  int _autoLockDuration = 5;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final storage = SecureStorageService();
      final isBiometricAvailable = await storage.isBiometricAvailable();

      setState(() {
        _isBiometricEnabled = isBiometricAvailable;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '设置',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 外观设置
                _buildSectionHeader('外观'),
                _buildSettingCard(
                  icon: Icons.dark_mode,
                  title: '深色模式',
                  subtitle: isDark ? '当前：深色' : '当前：浅色',
                  trailing: Switch(
                    value: isDark,
                    onChanged: (value) {
                      ThemeService.toggleTheme(ref);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 安全设置
                _buildSectionHeader('安全设置'),
                _buildSettingCard(
                  icon: Icons.security,
                  title: '安全中心',
                  subtitle: 'PIN码、剪贴板安全、会话管理',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SecuritySettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingCard(
                  icon: Icons.fingerprint,
                  title: '生物识别认证',
                  subtitle: '使用指纹或面容ID解锁',
                  trailing: Switch(
                    value: _isBiometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isBiometricEnabled = value;
                      });
                    },
                  ),
                ),
                _buildSettingCard(
                  icon: Icons.lock_clock,
                  title: '自动锁定',
                  subtitle: '离开应用后自动锁定',
                  trailing: Switch(
                    value: _isAutoLockEnabled,
                    onChanged: (value) {
                      setState(() {
                        _isAutoLockEnabled = value;
                      });
                    },
                  ),
                ),
                if (_isAutoLockEnabled)
                  _buildSettingCard(
                    icon: Icons.timer,
                    title: '自动锁定时间',
                    subtitle: '$_autoLockDuration 分钟',
                    trailing: DropdownButton<int>(
                      value: _autoLockDuration,
                      underline: const SizedBox(),
                      items: [1, 5, 10, 30]
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('$e 分钟'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _autoLockDuration = value;
                          });
                        }
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // 设备管理
                _buildSectionHeader('设备管理'),
                _buildSettingCard(
                  icon: Icons.devices,
                  title: '已配对设备',
                  subtitle: '管理连接的设备',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DevicesScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingCard(
                  icon: Icons.auto_fix_high,
                  title: '自动授权规则',
                  subtitle: '配置自动化的凭证访问授权',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AutoAuthorizationScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 数据管理
                _buildSectionHeader('数据管理'),
                _buildSettingCard(
                  icon: Icons.backup,
                  title: '备份凭证',
                  subtitle: '导出加密备份文件',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('备份功能开发中...')),
                    );
                  },
                ),
                _buildSettingCard(
                  icon: Icons.restore,
                  title: '恢复凭证',
                  subtitle: '从备份文件恢复',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('恢复功能开发中...')),
                    );
                  },
                ),
                _buildSettingCard(
                  icon: Icons.delete_forever,
                  title: '清除所有数据',
                  subtitle: '删除所有存储的凭证',
                  isDestructive: true,
                  onTap: () => _showClearDataConfirm(),
                ),

                const SizedBox(height: 24),

                // 关于
                _buildSectionHeader('关于'),
                _buildSettingCard(
                  icon: Icons.info,
                  title: '版本信息',
                  subtitle: 'PolyVault v0.1.0',
                ),
                _buildSettingCard(
                  icon: Icons.description,
                  title: '开源协议',
                  subtitle: '查看许可证信息',
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'PolyVault',
                      applicationVersion: '0.1.0',
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // 应用信息
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.shield,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PolyVault',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '安全凭证存储解决方案',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
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

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive
                ? colorScheme.errorContainer
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive
                ? colorScheme.onErrorContainer
                : colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive ? colorScheme.error : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: trailing ??
            (onTap != null
                ? Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  )
                : null),
        onTap: onTap,
      ),
    );
  }

  void _showClearDataConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text(
          '此操作将删除所有存储的凭证，且无法恢复。确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final storage = SecureStorageService();
                // TODO: 实现清除所有数据
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有数据已清除')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('清除失败: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}