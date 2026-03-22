import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'credentials_screen.dart';
import 'devices_screen.dart';
import 'messages_screen.dart';
import 'settings_screen.dart';

/// 主布局 - 包含底部导航的 Shell
class MainLayout extends ConsumerStatefulWidget {
  final Widget? child;

  const MainLayout({super.key, this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  // 默认页面列表（当没有 child 时使用）
  final List<Widget> _screens = [
    const HomeScreen(),
    const CredentialsScreen(),
    const DevicesScreen(),
    const MessagesScreen(),
    const SettingsScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.path;
    int index = 0;
    
    if (location.startsWith('/credentials')) {
      index = 1;
    } else if (location.startsWith('/devices')) {
      index = 2;
    } else if (location.startsWith('/messages')) {
      index = 3;
    } else if (location.startsWith('/settings')) {
      index = 4;
    }
    
    if (index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: widget.child ?? _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          
          // 使用 GoRouter 导航
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/credentials');
              break;
            case 2:
              context.go('/devices');
              break;
            case 3:
              context.go('/messages');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            icon: Icon(Icons.vpn_key_outlined),
            selectedIcon: Icon(Icons.vpn_key),
            label: '凭证',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: '设备',
          ),
          NavigationDestination(
            icon: Icon(Icons.message_outlined),
            selectedIcon: Icon(Icons.message),
            label: '消息',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}