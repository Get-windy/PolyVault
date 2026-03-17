import 'package:flutter/material.dart';

/// 插件信息模型
class PluginInfo {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final PluginCategory category;
  final bool isInstalled;
  final bool isEnabled;
  final String? iconUrl;
  final List<String> permissions;
  final Map<String, dynamic>? settings;

  const PluginInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.author,
    required this.category,
    this.isInstalled = false,
    this.isEnabled = false,
    this.iconUrl,
    this.permissions = const [],
    this.settings,
  });

  PluginInfo copyWith({
    bool? isInstalled,
    bool? isEnabled,
    Map<String, dynamic>? settings,
  }) {
    return PluginInfo(
      id: id,
      name: name,
      description: description,
      version: version,
      author: author,
      category: category,
      isInstalled: isInstalled ?? this.isInstalled,
      isEnabled: isEnabled ?? this.isEnabled,
      iconUrl: iconUrl,
      permissions: permissions,
      settings: settings ?? this.settings,
    );
  }
}

/// 插件分类
enum PluginCategory {
  security('安全', Icons.security),
  sync('同步', Icons.sync),
  backup('备份', Icons.backup_drive),
  theme('主题', Icons.palette),
  integration('集成', Icons.integration_instructions),
  utility('工具', Icons.build),
  social('社交', Icons.people),
  productivity('效率', Icons.rocket_launch);

  final String label;
  final IconData icon;
  const PluginCategory(this.label, this.icon);
}

/// 插件管理主屏幕
class PluginManagementScreen extends StatefulWidget {
  const PluginManagementScreen({super.key});

  @override
  State<PluginManagementScreen> createState() => _PluginManagementScreenState();
}

class _PluginManagementScreenState extends State<PluginManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 已安装的插件
  final List<PluginInfo> _installedPlugins = [
    const PluginInfo(
      id: 'plugin_1',
      name: '密码生成器',
      description: '生成强密码并自动填充',
      version: '1.2.0',
      author: 'PolyVault Team',
      category: PluginCategory.security,
      isInstalled: true,
      isEnabled: true,
      permissions: ['clipboard', 'storage'],
      settings: {'length': 16, 'includeSymbols': true},
    ),
    const PluginInfo(
      id: 'plugin_2',
      name: '云同步',
      description: '多设备数据同步',
      version: '2.0.1',
      author: 'PolyVault Team',
      category: PluginCategory.sync,
      isInstalled: true,
      isEnabled: true,
      permissions: ['network', 'storage'],
      settings: {'autoSync': true, 'interval': 30},
    ),
    const PluginInfo(
      id: 'plugin_3',
      name: '生物识别增强',
      description: '增强生物识别体验',
      version: '1.0.5',
      author: '第三方开发者',
      category: PluginCategory.security,
      isInstalled: true,
      isEnabled: false,
      permissions: ['biometric'],
    ),
  ];

  // 插件市场插件
  final List<PluginInfo> _marketplacePlugins = [
    const PluginInfo(
      id: 'market_1',
      name: '密码导入器',
      description: '从其他密码管理器导入数据',
      version: '1.0.0',
      author: '社区',
      category: PluginCategory.utility,
      isInstalled: false,
    ),
    const PluginInfo(
      id: 'market_2',
      name: '暗码门',
      description: '紧急情况下快速隐藏应用',
      version: '2.1.0',
      author: 'Security Pro',
      category: PluginCategory.security,
      isInstalled: false,
    ),
    const PluginInfo(
      id: 'market_3',
      name: '主题包 - 赛博朋克',
      description: '赛博朋克风格主题',
      version: '1.0.0',
      author: 'Design Studio',
      category: PluginCategory.theme,
      isInstalled: false,
    ),
    const PluginInfo(
      id: 'market_4',
      name: '密码健康检查',
      description: '分析并建议改进密码',
      version: '1.5.0',
      author: 'PolyVault Team',
      category: PluginCategory.security,
      isInstalled: false,
    ),
    const PluginInfo(
      id: 'market_5',
      name: '团队协作',
      description: '团队共享凭证',
      version: '1.0.0',
      author: 'Enterprise',
      category: PluginCategory.productivity,
      isInstalled: false,
    ),
    const PluginInfo(
      id: 'market_6',
      name: 'RSS阅读器',
      description: '订阅安全新闻',
      version: '0.9.0',
      author: 'NewsHub',
      category: PluginCategory.social,
      isInstalled: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件管理'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '已安装', icon: Icon(Icons.apps)),
            Tab(text: '插件市场', icon: Icon(Icons.store)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInstalledTab(),
          _buildMarketplaceTab(),
        ],
      ),
    );
  }

  /// 已安装插件列表
  Widget _buildInstalledTab() {
    if (_installedPlugins.isEmpty) {
      return _buildEmptyState(
        icon: Icons.extension_off,
        title: '暂无已安装插件',
        subtitle: '去插件市场发现更多功能',
        action: '浏览市场',
        onAction: () => _tabController.animateTo(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _installedPlugins.length + 1, // +1 for stats card
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildStatsCard();
        }
        final plugin = _installedPlugins[index - 1];
        return _buildInstalledPluginCard(plugin);
      },
    );
  }

  /// 插件市场
  Widget _buildMarketplaceTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _marketplacePlugins.length,
      itemBuilder: (context, index) {
        final plugin = _marketplacePlugins[index];
        return _buildMarketplacePluginCard(plugin);
      },
    );
  }

  /// 统计卡片
  Widget _buildStatsCard() {
    final enabled = _installedPlugins.where((p) => p.isEnabled).length;
    final total = _installedPlugins.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                icon: Icons.check_circle,
                label: '已启用',
                value: enabled.toString(),
                color: Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.extension,
                label: '总插件',
                value: total.toString(),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                icon: Icons.category,
                label: '分类',
                value: PluginCategory.values.length.toString(),
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
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
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 已安装插件卡片
  Widget _buildInstalledPluginCard(PluginInfo plugin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            plugin.category.icon,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                plugin.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            _buildStatusChip(plugin.isEnabled),
          ],
        ),
        subtitle: Text(
          'v${plugin.version} • ${plugin.author}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plugin.description,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                // 权限
                if (plugin.permissions.isNotEmpty) ...[
                  const Text(
                    '权限:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: plugin.permissions
                        .map((p) => Chip(
                              label: Text(p, style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                // 操作按钮
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPluginSettings(plugin),
                        icon: const Icon(Icons.settings, size: 18),
                        label: const Text('设置'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _uninstallPlugin(plugin),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text('卸载', style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // 启用/禁用开关
                SwitchListTile(
                  title: Text(plugin.isEnabled ? '已启用' : '已禁用'),
                  subtitle: Text(plugin.isEnabled ? '插件正在运行中' : '插件已停止'),
                  value: plugin.isEnabled,
                  onChanged: (value) => _togglePlugin(plugin, value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 插件市场卡片
  Widget _buildMarketplacePluginCard(PluginInfo plugin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                plugin.category.icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          plugin.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(plugin.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          plugin.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: _getCategoryColor(plugin.category),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plugin.description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v${plugin.version} • ${plugin.author}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _installPlugin(plugin),
              child: const Text('安装'),
            ),
          ],
        ),
      ),
    );
  }

  /// 状态标签
  Widget _buildStatusChip(bool isEnabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isEnabled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isEnabled ? '已启用' : '已禁用',
        style: TextStyle(
          fontSize: 11,
          color: isEnabled ? Colors.green : Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.store),
              label: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取分类颜色
  Color _getCategoryColor(PluginCategory category) {
    switch (category) {
      case PluginCategory.security:
        return Colors.red;
      case PluginCategory.sync:
        return Colors.blue;
      case PluginCategory.backup:
        return Colors.orange;
      case PluginCategory.theme:
        return Colors.purple;
      case PluginCategory.integration:
        return Colors.teal;
      case PluginCategory.utility:
        return Colors.green;
      case PluginCategory.social:
        return Colors.pink;
      case PluginCategory.productivity:
        return Colors.indigo;
    }
  }

  /// 切换插件启用状态
  void _togglePlugin(PluginInfo plugin, bool enabled) {
    setState(() {
      final index = _installedPlugins.indexWhere((p) => p.id == plugin.id);
      if (index != -1) {
        _installedPlugins[index] = _installedPlugins[index].copyWith(isEnabled: enabled);
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled ? '已启用 ${plugin.name}' : '已禁用 ${plugin.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 安装插件
  void _installPlugin(PluginInfo plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.extension, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('安装插件'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要安装 "${plugin.name}" 吗？'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('版本: ${plugin.version}', style: const TextStyle(fontSize: 13)),
                  Text('作者: ${plugin.author}', style: const TextStyle(fontSize: 13)),
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
              Navigator.pop(context);
              _doInstallPlugin(plugin);
            },
            child: const Text('安装'),
          ),
        ],
      ),
    );
  }

  void _doInstallPlugin(PluginInfo plugin) {
    final newPlugin = plugin.copyWith(isInstalled: true, isEnabled: true);
    setState(() {
      _installedPlugins.add(newPlugin);
      _marketplacePlugins.removeWhere((p) => p.id == plugin.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plugin.name} 安装成功'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '查看',
          onPressed: () => _tabController.animateTo(0),
        ),
      ),
    );
  }

  /// 卸载插件
  void _uninstallPlugin(PluginInfo plugin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('卸载插件'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('确定要卸载 "${plugin.name}" 吗？'),
            const SizedBox(height: 8),
            const Text(
              '卸载后插件数据将被清除，且无法恢复。',
              style: TextStyle(color: Colors.red, fontSize: 13),
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
              Navigator.pop(context);
              _doUninstallPlugin(plugin);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('卸载'),
          ),
        ],
      ),
    );
  }

  void _doUninstallPlugin(PluginInfo plugin) {
    setState(() {
      _installedPlugins.removeWhere((p) => p.id == plugin.id);
      _marketplacePlugins.add(plugin.copyWith(isInstalled: false));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${plugin.name} 已卸载'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 插件设置
  void _showPluginSettings(PluginInfo plugin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PluginSettingsSheet(plugin: plugin),
    );
  }
}

/// 插件设置面板
class _PluginSettingsSheet extends StatefulWidget {
  final PluginInfo plugin;

  const _PluginSettingsSheet({required this.plugin});

  @override
  State<_PluginSettingsSheet> createState() => _PluginSettingsSheetState();
}

class _PluginSettingsSheetState extends State<_PluginSettingsSheet> {
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.plugin.settings ?? {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
          // 标题
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.plugin.name} 设置',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
          // 设置内容
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.plugin.category == PluginCategory.security) ...[
                  _buildSwitchSetting(
                    title: '启用安全保护',
                    subtitle: '增强安全检测',
                    value: _settings['enableProtection'] ?? true,
                    onChanged: (v) => setState(() => _settings['enableProtection'] = v),
                  ),
                  _buildSliderSetting(
                    title: '安全级别',
                    subtitle: '调整检测灵敏度',
                    value: (_settings['securityLevel'] ?? 5).toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    onChanged: (v) => setState(() => _settings['securityLevel'] = v.toInt()),
                  ),
                ],
                if (widget.plugin.category == PluginCategory.sync) ...[
                  _buildSwitchSetting(
                    title: '自动同步',
                    subtitle: '在后台自动同步数据',
                    value: _settings['autoSync'] ?? true,
                    onChanged: (v) => setState(() => _settings['autoSync'] = v),
                  ),
                  _buildDropdownSetting(
                    title: '同步间隔',
                    subtitle: '选择自动同步频率',
                    value: _settings['interval'] ?? 30,
                    options: const [5, 15, 30, 60, 120],
                    labels: const ['5分钟', '15分钟', '30分钟', '1小时', '2小时'],
                    onChanged: (v) => setState(() => _settings['interval'] = v),
                  ),
                ],
                _buildSwitchSetting(
                  title: '通知提醒',
                  subtitle: '接收插件更新通知',
                  value: _settings['notifications'] ?? true,
                  onChanged: (v) => setState(() => _settings['notifications'] = v),
                ),
              ],
            ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('设置已保存'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('保存设置'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderSetting({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              label: value.toInt().toString(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownSetting<T>({
    required String title,
    required String subtitle,
    required T value,
    required List<T> options,
    required List<String> labels,
    required ValueChanged<T> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: DropdownButton<T>(
          value: value,
          underline: const SizedBox(),
          items: options.asMap().entries.map((e) {
            return DropdownMenuItem<T>(
              value: e.value,
              child: Text(labels[e.key]),
            );
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}