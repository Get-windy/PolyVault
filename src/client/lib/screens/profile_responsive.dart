/// 个人中心响应式布局
/// 支持手机/平板/桌面多设备适配
library profile_responsive;

import 'package:flutter/material.dart';
import '../theme/responsive.dart';
import '../theme/app_theme.dart';

/// 响应式个人中心
class ResponsiveProfileScreen extends StatelessWidget {
  const ResponsiveProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        if (responsive.isDesktop) {
          return _DesktopProfileLayout();
        }
        if (responsive.isTablet) {
          return _TabletProfileLayout();
        }
        return _MobileProfileLayout();
      },
    );
  }
}

/// 移动端个人中心
class _MobileProfileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部用户信息
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _ProfileHeader(),
            ),
          ),
          // 设置列表
          SliverList(
            delegate: SliverChildListDelegate([
              _SettingsSection(),
            ]),
          ),
        ],
      ),
    );
  }
}

/// 平板个人中心
class _TabletProfileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 左侧用户卡片
          Container(
            width: 280,
            padding: const EdgeInsets.all(24),
            child: Card(
              child: _ProfileHeader(compact: true),
            ),
          ),
          // 右侧设置区
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _SettingsSection(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 桌面个人中心
class _DesktopProfileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            selectedIndex: 3,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                label: Text('发现'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bookmark_outline),
                label: Text('收藏'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person),
                label: Text('我的'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主内容
          Expanded(
            child: Row(
              children: [
                // 用户信息卡片
                Container(
                  width: 320,
                  padding: const EdgeInsets.all(32),
                  child: Card(
                    child: _ProfileHeader(compact: true),
                  ),
                ),
                // 设置区域
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('设置', style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 24),
                        _SettingsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 用户信息头部
class _ProfileHeader extends StatelessWidget {
  final bool compact;
  
  const _ProfileHeader({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final responsive = Responsive.of(context);
    
    return Padding(
      padding: EdgeInsets.all(compact ? 24 : 16),
      child: Column(
        mainAxisAlignment: compact ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!compact) const Spacer(),
          // 头像
          Container(
            width: compact ? 80 : 100,
            height: compact ? 80 : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.secondary],
              ),
            ),
            child: const Icon(Icons.person, size: 48, color: Colors.white),
          ),
          SizedBox(height: compact ? 16 : 12),
          // 用户名
          Text(
            '用户名',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'user@example.com',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          // 统计信息
          if (!compact) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatItem(label: '凭证', value: '24'),
                _StatItem(label: '设备', value: '5'),
                _StatItem(label: '备份', value: '3'),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // 编辑按钮
          if (compact)
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('编辑资料'),
            ),
        ],
      ),
    );
  }
}

/// 统计项
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// 设置区域
class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final crossAxisCount = responsive.value(mobile: 1, tablet: 2, desktop: 3);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 账户设置
        _SettingsGroup(
          title: '账户设置',
          children: [
            _SettingTile(
              icon: Icons.person_outline,
              title: '个人信息',
              subtitle: '修改头像、昵称等',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.lock_outline,
              title: '安全设置',
              subtitle: '密码、生物识别',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.devices_outlined,
              title: '设备管理',
              subtitle: '已登录设备',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 通用设置
        _SettingsGroup(
          title: '通用设置',
          children: [
            _SettingTile(
              icon: Icons.palette_outlined,
              title: '外观',
              subtitle: '主题、字体大小',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.notifications_outlined,
              title: '通知',
              subtitle: '推送通知设置',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.language_outlined,
              title: '语言',
              subtitle: '简体中文',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 数据设置
        _SettingsGroup(
          title: '数据与存储',
          children: [
            _SettingTile(
              icon: Icons.backup_outlined,
              title: '备份',
              subtitle: '上次备份: 2小时前',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.sync_outlined,
              title: '同步',
              subtitle: '自动同步已开启',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.delete_outline,
              title: '清除缓存',
              subtitle: '当前缓存: 128MB',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 24),
        // 关于
        _SettingsGroup(
          title: '关于',
          children: [
            _SettingTile(
              icon: Icons.info_outline,
              title: '版本',
              subtitle: 'v1.0.0',
              onTap: () {},
            ),
            _SettingTile(
              icon: Icons.help_outline,
              title: '帮助与反馈',
              subtitle: '常见问题、联系支持',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 32),
        // 退出登录
        Center(
          child: FilledButton.tonal(
            onPressed: () {},
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('退出登录'),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

/// 设置组
class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;
  
  const _SettingsGroup({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final crossAxisCount = responsive.value(mobile: 1, tablet: 2, desktop: 3);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (responsive.isMobile)
          ...children
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 8,
            crossAxisSpacing: 16,
            childAspectRatio: 3,
            children: children,
          ),
      ],
    );
  }
}

/// 设置项
class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: colorScheme.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}