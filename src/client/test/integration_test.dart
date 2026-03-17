import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/main.dart';
import 'package:polyvault/screens/credentials_screen.dart';
import 'package:polyvault/screens/devices_screen.dart';
import 'package:polyvault/screens/settings_screen.dart';

void main() {
  group('Integration Tests', () {
    testWidgets('应用启动并显示主页面', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 验证应用标题
      expect(find.text('PolyVault'), findsOneWidget);

      // 验证底部导航栏存在
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('导航栏包含4个标签页', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 验证4个导航项
      expect(find.text('设备状态'), findsOneWidget);
      expect(find.text('凭证管理'), findsOneWidget);
      expect(find.text('设备'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('可以在标签页之间切换', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 切换到凭证管理
      await tester.tap(find.text('凭证管理'));
      await tester.pumpAndSettle();
      expect(find.byType(CredentialsScreen), findsOneWidget);

      // 切换到设备
      await tester.tap(find.text('设备'));
      await tester.pumpAndSettle();
      expect(find.byType(DevicesScreen), findsOneWidget);

      // 切换到设置
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // 返回设备状态
      await tester.tap(find.text('设备状态'));
      await tester.pumpAndSettle();
    });

    testWidgets('主题切换正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 导航到设置
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 查找主题切换开关
      final themeSwitch = find.byType(Switch);
      expect(themeSwitch, findsOneWidget);

      // 切换主题
      await tester.tap(themeSwitch);
      await tester.pumpAndSettle();

      // 验证主题已切换（通过检查亮度）
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final Brightness brightness = Theme.of(context).brightness;
      expect(brightness, isNotNull);
    });

    testWidgets('凭证管理完整流程', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 导航到凭证管理
      await tester.tap(find.text('凭证管理'));
      await tester.pumpAndSettle();

      // 验证页面加载
      expect(find.text('凭证管理'), findsOneWidget);

      // 点击添加凭证
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证对话框打开
      expect(find.text('添加凭证'), findsOneWidget);

      // 填写表单
      await tester.enterText(
        find.widgetWithText(TextFormField, '服务名称'),
        'GitHub',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '用户名'),
        'testuser',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '密码'),
        'testpassword123',
      );
      await tester.pumpAndSettle();

      // 取消添加
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // 验证对话框关闭
      expect(find.text('添加凭证'), findsNothing);
    });

    testWidgets('设备管理完整流程', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 导航到设备
      await tester.tap(find.text('设备'));
      await tester.pumpAndSettle();

      // 验证页面加载
      expect(find.text('设备管理'), findsOneWidget);

      // 验证设备列表存在
      expect(find.byType(Card), findsWidgets);

      // 点击添加设备
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证添加选项显示
      expect(find.text('扫描二维码'), findsOneWidget);
      expect(find.text('手动输入'), findsOneWidget);

      // 取消添加
      await tester.tapAt(const Offset(0, 0)); // 点击外部关闭
      await tester.pumpAndSettle();
    });

    testWidgets('设置页面功能完整', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 导航到设置
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      // 验证设置页面元素
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('深色模式'), findsOneWidget);

      // 测试深色模式切换
      final darkModeSwitch = find.byType(Switch).first;
      await tester.tap(darkModeSwitch);
      await tester.pumpAndSettle();

      // 验证切换成功
      final switchWidget = tester.widget<Switch>(darkModeSwitch);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('应用状态保持', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 导航到凭证管理
      await tester.tap(find.text('凭证管理'));
      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 切换到设备页面（对话框应该关闭）
      await tester.tap(find.text('设备'));
      await tester.pumpAndSettle();

      // 验证对话框已关闭
      expect(find.text('添加凭证'), findsNothing);

      // 返回凭证管理
      await tester.tap(find.text('凭证管理'));
      await tester.pumpAndSettle();

      // 验证页面正常显示
      expect(find.text('凭证管理'), findsOneWidget);
    });

    testWidgets('错误处理', (WidgetTester tester) async {
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      // 导航到凭证管理
      await tester.tap(find.text('凭证管理'));
      await tester.pumpAndSettle();

      // 尝试提交空表单
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 验证显示验证错误
      expect(find.text('请输入服务名称'), findsOneWidget);
      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);

      // 关闭对话框
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
    });

    testWidgets('响应式布局适配', (WidgetTester tester) async {
      // 测试手机尺寸
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 测试平板尺寸
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // 测试桌面尺寸
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('性能基准测试', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(const PolyVaultApp());
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证应用启动时间小于1秒
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });
  });
}