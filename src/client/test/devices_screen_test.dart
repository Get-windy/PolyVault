import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/screens/devices_screen.dart';
import 'package:polyvault/widgets/device_status_card.dart';

void main() {
  group('DevicesScreen Widget Tests', () {
    testWidgets('设备管理页面显示初始状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      // 验证页面标题
      expect(find.text('设备管理'), findsOneWidget);

      // 验证有3个设备
      expect(find.byType(Card), findsNWidgets(3));

      // 验证有扫描按钮
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // 验证有添加设备按钮
      expect(find.text('添加设备'), findsOneWidget);
    });

    testWidgets('显示正确的在线/离线设备统计', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 验证在线设备数为1
      expect(find.text('1'), findsWidgets);

      // 验证离线设备数为2
      expect(find.text('2'), findsWidgets);

      // 验证总计数为3
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('在线设备卡片显示绿色边框', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 找到第一个设备卡片（在线设备）
      final firstCard = tester.widget<Card>(find.byType(Card).first);

      // 验证边框颜色为绿色
      final shape = firstCard.shape as RoundedRectangleBorder;
      expect(shape.side?.color, Colors.green.withOpacity(0.3));
    });

    testWidgets('离线设备显示最后在线时间', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 验证显示"2小时前"
      expect(find.text('2小时前'), findsOneWidget);

      // 验证显示"1天前"
      expect(find.text('1天前'), findsOneWidget);
    });

    testWidgets('点击扫描按钮触发扫描', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 点击扫描按钮
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // 验证显示扫描完成提示
      expect(find.text('扫描完成，发现 3 个设备'), findsOneWidget);
    });

    testWidgets('点击设备卡片显示详情', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 点击第一个设备卡片
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 验证显示设备详情对话框
      expect(find.text('设备信息'), findsOneWidget);
      expect(find.text('网络信息'), findsOneWidget);
    });

    testWidgets('点击添加设备按钮显示选项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 点击添加设备按钮
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证显示添加选项
      expect(find.text('扫描二维码'), findsOneWidget);
      expect(find.text('手动输入'), findsOneWidget);
    });

    testWidgets('设备图标根据平台正确显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 验证Android图标
      expect(find.byIcon(Icons.android), findsOneWidget);

      // 验证Windows图标
      expect(find.byIcon(Icons.desktop_windows), findsOneWidget);

      // 验证iOS图标
      expect(find.byIcon(Icons.apple), findsOneWidget);
    });

    testWidgets('删除设备显示确认对话框', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 点击第一个设备卡片的菜单按钮
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // 点击删除选项
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // 验证显示确认对话框
      expect(find.text('删除设备'), findsOneWidget);
      expect(find.text('确定要删除设备'), findsOneWidget);
      expect(find.text('此操作不可撤销'), findsOneWidget);
    });

    testWidgets('确认删除后设备被移除', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 初始有3个设备卡片
      expect(find.byType(Card), findsNWidgets(3));

      // 打开删除确认对话框
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();

      // 验证设备被删除
      expect(find.byType(Card), findsNWidgets(2));
    });

    testWidgets('连接离线设备更新状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 点击离线设备菜单
      await tester.tap(find.byIcon(Icons.more_vert).at(1));
      await tester.pumpAndSettle();

      // 点击连接选项
      await tester.tap(find.text('连接'));
      await tester.pumpAndSettle();

      // 验证显示已连接提示
      expect(find.textContaining('已连接到'), findsOneWidget);
    });

    testWidgets('断开连接设备更新状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // 点击在线设备菜单
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // 点击断开选项
      await tester.tap(find.text('断开'));
      await tester.pumpAndSettle();

      // 验证显示已断开提示
      expect(find.textContaining('已断开'), findsOneWidget);
    });

    testWidgets('空状态显示正确', (WidgetTester tester) async {
      // 创建一个没有设备的自定义测试widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                EmptyState(
                  icon: Icons.devices_other,
                  title: '暂无设备',
                  message: '添加您的第一个设备来开始使用',
                  actionLabel: '添加设备',
                  onAction: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证空状态显示
      expect(find.text('暂无设备'), findsOneWidget);
      expect(find.text('添加您的第一个设备来开始使用'), findsOneWidget);
      expect(find.text('添加设备'), findsOneWidget);
      expect(find.byIcon(Icons.devices_other), findsOneWidget);
    });
  });

  group('DeviceInfo Model Tests', () {
    test('Android设备返回正确的平台图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test Phone',
        type: 'Mobile Phone',
        isConnected: true,
        platform: 'android',
        ipAddress: '192.168.1.100',
      );

      expect(device.platformIcon, Icons.android);
    });

    test('iOS设备返回正确的平台图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test Phone',
        type: 'Mobile Phone',
        isConnected: true,
        platform: 'ios',
        ipAddress: '192.168.1.100',
      );

      expect(device.platformIcon, Icons.apple);
    });

    test('Windows设备返回正确的平台图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test PC',
        type: 'Desktop Computer',
        isConnected: true,
        platform: 'windows',
        ipAddress: '192.168.1.101',
      );

      expect(device.platformIcon, Icons.desktop_windows);
    });

    test('未知平台返回默认图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test Device',
        type: 'Unknown',
        isConnected: true,
        platform: 'unknown',
        ipAddress: '192.168.1.100',
      );

      expect(device.platformIcon, Icons.devices);
    });

    test('手机设备返回正确的类型图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test Phone',
        type: 'mobile phone',
        isConnected: true,
        platform: 'android',
        ipAddress: '192.168.1.100',
      );

      expect(device.typeIcon, Icons.smartphone);
    });

    test('平板设备返回正确的类型图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test Tablet',
        type: 'tablet',
        isConnected: true,
        platform: 'ios',
        ipAddress: '192.168.1.100',
      );

      expect(device.typeIcon, Icons.tablet_mac);
    });

    test('桌面设备返回正确的类型图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test PC',
        type: 'desktop computer',
        isConnected: true,
        platform: 'windows',
        ipAddress: '192.168.1.101',
      );

      expect(device.typeIcon, Icons.desktop_windows);
    });

    test('笔记本设备返回正确的类型图标', () {
      final device = DeviceInfo(
        id: '1',
        name: 'Test Laptop',
        type: 'laptop',
        isConnected: true,
        platform: 'macos',
        ipAddress: '192.168.1.100',
      );

      expect(device.typeIcon, Icons.laptop);
    });
  });
}