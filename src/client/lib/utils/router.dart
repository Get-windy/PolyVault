import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/main_layout.dart';
import '../screens/home_screen.dart';
import '../screens/credentials_screen.dart';
import '../screens/credential_detail_screen.dart';
import '../screens/devices_screen.dart';
import '../screens/device_pairing_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/security_settings_screen.dart';
import '../screens/theme_settings_screen.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/auto_authorization_screen.dart';
import '../screens/password_generator_screen.dart';
import '../screens/backup_screen.dart';
import '../screens/sync_screen.dart';
import '../screens/notification_center_screen.dart';
import '../screens/about_screen.dart';
import '../screens/connection_test_screen.dart';

/// 路由名称
class AppRoutes {
  static const String home = '/';
  static const String credentials = '/credentials';
  static const String credentialDetail = '/credentials/:id';
  static const String devices = '/devices';
  static const String devicePairing = '/devices/pair';
  static const String messages = '/messages';
  static const String settings = '/settings';
  static const String securitySettings = '/settings/security';
  static const String themeSettings = '/settings/theme';
  static const String notificationSettings = '/settings/notifications';
  static const String autoAuthorization = '/settings/auto-authorization';
  static const String passwordGenerator = '/password-generator';
  static const String backup = '/backup';
  static const String sync = '/sync';
  static const String notifications = '/notifications';
  static const String about = '/about';
  static const String connectionTest = '/connection-test';
}

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // 主 Shell 路由
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/credentials',
            name: 'credentials',
            builder: (context, state) => const CredentialsScreen(),
          ),
          GoRoute(
            path: '/devices',
            name: 'devices',
            builder: (context, state) => const DevicesScreen(),
          ),
          GoRoute(
            path: '/messages',
            name: 'messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      
      // 独立页面（不在主 Shell 中）
      GoRoute(
        path: '/credentials/:id',
        name: 'credential-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CredentialDetailScreen(credentialId: id);
        },
      ),
      GoRoute(
        path: AppRoutes.devicePairing,
        name: 'device-pairing',
        builder: (context, state) => const DevicePairingScreen(),
      ),
      GoRoute(
        path: AppRoutes.securitySettings,
        name: 'security-settings',
        builder: (context, state) => const SecuritySettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.themeSettings,
        name: 'theme-settings',
        builder: (context, state) => const ThemeSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.notificationSettings,
        name: 'notification-settings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.autoAuthorization,
        name: 'auto-authorization',
        builder: (context, state) => const AutoAuthorizationScreen(),
      ),
      GoRoute(
        path: AppRoutes.passwordGenerator,
        name: 'password-generator',
        builder: (context, state) => const PasswordGeneratorScreen(),
      ),
      GoRoute(
        path: AppRoutes.backup,
        name: 'backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: AppRoutes.sync,
        name: 'sync',
        builder: (context, state) => const SyncScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
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

/// 路由导航辅助类
class AppNavigator {
  static void goHome(BuildContext context) => context.go(AppRoutes.home);
  static void goCredentials(BuildContext context) => context.go(AppRoutes.credentials);
  static void goDevices(BuildContext context) => context.go(AppRoutes.devices);
  static void goMessages(BuildContext context) => context.go(AppRoutes.messages);
  static void goSettings(BuildContext context) => context.go(AppRoutes.settings);
  static void goConnectionTest(BuildContext context) => context.push(AppRoutes.connectionTest);
  
  static void goToCredentialDetail(BuildContext context, String id) {
    context.push('/credentials/$id');
  }
  
  static void goToSecuritySettings(BuildContext context) {
    context.push(AppRoutes.securitySettings);
  }
  
  static void goToPasswordGenerator(BuildContext context) {
    context.push(AppRoutes.passwordGenerator);
  }
  
  static void goToBackup(BuildContext context) {
    context.push(AppRoutes.backup);
  }
  
  static void goToSync(BuildContext context) {
    context.push(AppRoutes.sync);
  }
}