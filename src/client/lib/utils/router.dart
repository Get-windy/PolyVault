import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/home_screen.dart';
import '../screens/credentials_screen.dart';
import '../screens/devices_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/connection_test_screen.dart';

/// 路由名称
class AppRoutes {
  static const String home = '/';
  static const String credentials = '/credentials';
  static const String devices = '/devices';
  static const String settings = '/settings';
  static const String connectionTest = '/connection-test';
}

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // 主页面（底部导航）
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.credentials,
            name: 'credentials',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CredentialsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.devices,
            name: 'devices',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DevicesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
      // 独立页面
      GoRoute(
        path: AppRoutes.connectionTest,
        name: 'connection-test',
        builder: (context, state) => const ConnectionTestScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '页面未找到',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// 主 Shell（底部导航）
class MainShell extends StatelessWidget {
  final Widget child;
  
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '设备状态',
          ),
          NavigationDestination(
            icon: Icon(Icons.vpn_key_outlined),
            selectedIcon: Icon(Icons.vpn_key),
            label: '凭证管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices),
            label: '设备',
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

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith(AppRoutes.credentials)) return 1;
    if (location.startsWith(AppRoutes.devices)) return 2;
    if (location.startsWith(AppRoutes.settings)) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.credentials);
        break;
      case 2:
        context.go(AppRoutes.devices);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }
}

/// 路由导航辅助类
class AppNavigator {
  static void goHome(BuildContext context) => context.go(AppRoutes.home);
  static void goCredentials(BuildContext context) => context.go(AppRoutes.credentials);
  static void goDevices(BuildContext context) => context.go(AppRoutes.devices);
  static void goSettings(BuildContext context) => context.go(AppRoutes.settings);
  static void goConnectionTest(BuildContext context) => context.push(AppRoutes.connectionTest);
}