/// 首页响应式布局
/// 支持手机/平板/桌面多设备适配
library home_responsive;

import 'package:flutter/material.dart';
import '../theme/responsive.dart';
import '../theme/app_theme.dart';

/// 响应式首页
class ResponsiveHomeScreen extends StatelessWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        if (responsive.isDesktop) {
          return _DesktopHomeLayout();
        }
        if (responsive.isTablet) {
          return _TabletHomeLayout();
        }
        return _MobileHomeLayout();
      },
    );
  }
}

/// 移动端首页布局
class _MobileHomeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 顶部搜索栏
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildSearchHeader(context, isCompact: true),
            ),
          ),
          // 内容区域
          const SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: _ContentFeed(),
          ),
        ],
      ),
      // 底部导航
      bottomNavigationBar: _buildBottomNav(context),
      // 浮动操作按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// 平板首页布局
class _TabletHomeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Row(
        children: [
          // 侧边导航
          NavigationRail(
            extended: false,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: Text('发现'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bookmark_outline),
                selectedIcon: Icon(Icons.bookmark),
                label: Text('收藏'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('我的'),
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (index) {},
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主内容区
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  expandedHeight: 160,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildSearchHeader(context, isCompact: false),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.all(24),
                  sliver: _ContentFeed(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 桌面首页布局
class _DesktopHomeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Row(
        children: [
          // 桌面侧边栏
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: Text('发现'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.bookmark_outline),
                selectedIcon: Icon(Icons.bookmark),
                label: Text('收藏'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('我的'),
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (index) {},
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主内容区 - 三栏布局
          Expanded(
            child: Row(
              children: [
                // 左侧内容流
                Expanded(
                  flex: 2,
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(32),
                        sliver: SliverToBoxAdapter(
                          child: _buildSearchHeader(context, isCompact: false),
                        ),
                      ),
                      const SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        sliver: _ContentFeed(),
                      ),
                    ],
                  ),
                ),
                // 右侧边栏
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: _RightSidebar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 搜索头部
Widget _buildSearchHeader(BuildContext context, {required bool isCompact}) {
  final colorScheme = Theme.of(context).colorScheme;
  final responsive = Responsive.of(context);
  
  return Container(
    padding: EdgeInsets.all(isCompact ? 16 : 24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (!isCompact) ...[
          Row(
            children: [
              Text(
                'PolyVault',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              // 主题切换
              IconButton(
                icon: const Icon(Icons.dark_mode_outlined),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // 搜索框
        TextField(
          decoration: InputDecoration(
            hintText: '搜索凭证、设备...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    ),
  );
}

/// 内容流
class _ContentFeed extends StatelessWidget {
  const _ContentFeed();

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        final columns = responsive.gridColumns;
        
        return SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ContentCard(index: index),
            childCount: 12,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: responsive.isMobile ? 1.5 : 1.8,
          ),
        );
      },
    );
  }
}

/// 内容卡片
class _ContentCard extends StatelessWidget {
  final int index;
  
  const _ContentCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.vpn_key,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '服务 ${index + 1}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '用户名',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '最近使用',
                    style: Theme.of(context).textTheme.bodySmall,
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

/// 右侧边栏
class _RightSidebar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 快捷操作
          Text('快捷操作', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _QuickActionTile(icon: Icons.add, label: '添加凭证', onTap: () {}),
          _QuickActionTile(icon: Icons.devices, label: '设备管理', onTap: () {}),
          _QuickActionTile(icon: Icons.sync, label: '同步数据', onTap: () {}),
          const SizedBox(height: 24),
          // 统计
          Text('安全状态', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _StatTile(label: '凭证数量', value: '24'),
          _StatTile(label: '在线设备', value: '3'),
          _StatTile(label: '最后备份', value: '2小时前'),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// 底部导航
Widget _buildBottomNav(BuildContext context) {
  return NavigationBar(
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: '首页',
      ),
      NavigationDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: '发现',
      ),
      NavigationDestination(
        icon: Icon(Icons.bookmark_outline),
        selectedIcon: Icon(Icons.bookmark),
        label: '收藏',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: '我的',
      ),
    ],
    selectedIndex: 0,
    onDestinationSelected: (index) {},
  );
}