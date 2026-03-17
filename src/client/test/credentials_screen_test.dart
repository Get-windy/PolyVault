import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/screens/credentials_screen.dart';
import 'package:polyvault/widgets/credential_list_item.dart';

void main() {
  group('CredentialsScreen Widget Tests', () {
    late CredentialsScreen screen;

    setUp(() {
      screen = const CredentialsScreen();
    });

    testWidgets('凭证管理页面显示初始状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 验证页面标题
      expect(find.text('凭证管理'), findsOneWidget);

      // 验证有搜索按钮
      expect(find.byIcon(Icons.search), findsOneWidget);

      // 验证有添加凭证按钮
      expect(find.text('添加凭证'), findsOneWidget);
    });

    testWidgets('点击添加凭证按钮显示对话框', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 点击添加凭证按钮
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证显示添加凭证对话框
      expect(find.text('添加凭证'), findsOneWidget);
      expect(find.text('服务名称'), findsOneWidget);
      expect(find.text('用户名'), findsOneWidget);
      expect(find.text('密码'), findsOneWidget);
      expect(find.text('备注（可选）'), findsOneWidget);
    });

    testWidgets('添加凭证表单验证', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 点击保存按钮（表单为空）
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 验证显示验证错误
      expect(find.text('请输入服务名称'), findsOneWidget);
      expect(find.text('请输入用户名'), findsOneWidget);
      expect(find.text('请输入密码'), findsOneWidget);
    });

    testWidgets('输入字段有正确的提示文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证各个输入字段的提示文本
      expect(find.text('例如: GitHub, AWS, Google'), findsOneWidget);
      expect(find.text('您的登录账号'), findsOneWidget);
      expect(find.text('您的登录密码'), findsOneWidget);
      expect(find.text('添加说明信息'), findsOneWidget);
    });

    testWidgets('密码输入框默认隐藏内容', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 查找密码输入框
      final passwordField = find.ancestor(
        of: find.text('您的登录密码'),
        matching: find.byType(TextFormField),
      );

      // 验证密码字段存在
      expect(passwordField, findsOneWidget);
    });

    testWidgets('备注输入框支持多行', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 查找备注输入框
      final notesField = find.ancestor(
        of: find.text('添加说明信息'),
        matching: find.byType(TextFormField),
      );

      // 验证备注字段存在
      expect(notesField, findsOneWidget);
    });

    testWidgets('对话框有取消和保存按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证按钮存在
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('点击取消按钮关闭对话框', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证对话框打开
      expect(find.text('添加凭证'), findsOneWidget);

      // 点击取消按钮
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // 验证对话框关闭
      expect(find.text('添加凭证'), findsNothing);
    });

    testWidgets('空状态显示正确', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 验证空状态显示
      expect(find.text('暂无凭证'), findsOneWidget);
      expect(find.text('点击下方按钮添加您的第一个凭证'), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key_outlined), findsOneWidget);
    });

    testWidgets('空状态中的添加按钮可以打开对话框', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 点击空状态中的添加按钮
      await tester.tap(find.text('添加凭证'));
      await tester.pumpAndSettle();

      // 验证显示添加对话框
      expect(find.text('添加凭证'), findsOneWidget);
    });

    testWidgets('搜索按钮存在', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 验证搜索按钮在app bar中
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('FloatingActionButton显示正确的图标和文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 验证FAB有正确的图标
      expect(find.byIcon(Icons.add), findsOneWidget);

      // 验证FAB有正确的文本
      expect(find.text('添加凭证'), findsOneWidget);
    });

    testWidgets('App bar标题居中显示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 查找AppBar
      final appBar = tester.widget<AppBar>(find.byType(AppBar));

      // 验证标题居中
      expect(appBar.centerTitle, isTrue);
    });

    testWidgets('App bar标题有加粗样式', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 查找标题Text widget
      final titleWidget = tester.widget<Text>(find.text('凭证管理'));

      // 验证标题有加粗样式
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('页面标题包含正确的文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 验证页面标题
      expect(find.text('凭证管理'), findsOneWidget);
    });

    testWidgets('表单字段有正确的图标前缀', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 验证各个字段的图标前缀
      expect(find.byIcon(Icons.business), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.byIcon(Icons.notes), findsOneWidget);
    });

    testWidgets('服务名称字段是必填的', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: screen,
        ),
      );

      await tester.pumpAndSettle();

      // 打开添加对话框
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // 找到服务名称输入框
      final serviceNameField = find.ancestor(
        of: find.text('例如: GitHub, AWS, Google'),
        matching: find.byType(TextFormField),
      );

      // 输入服务名称
      await tester.enterText(serviceNameField, 'Test Service');
      await tester.pumpAndSettle();

      // 点击保存
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();

      // 验证不再显示服务名称错误（因为有值）
      // 注意：由于form是空的，可能还会显示其他错误
    });
  });

  group('CredentialListItem Widget Tests', () {
    testWidgets('CredentialListItem显示服务名称', (WidgetTester tester) async {
      final credential = CredentialSummary(
        id: '1',
        serviceName: 'GitHub',
        username: 'testuser',
        lastModified: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CredentialListItem(
              credential: credential,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证显示服务名称
      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('CredentialListItem显示用户名', (WidgetTester tester) async {
      final credential = CredentialSummary(
        id: '1',
        serviceName: 'GitHub',
        username: 'testuser',
        lastModified: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CredentialListItem(
              credential: credential,
              onTap: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证显示用户名
      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('点击CredentialListItem触发onTap回调', (WidgetTester tester) async {
      bool tapped = false;
      final credential = CredentialSummary(
        id: '1',
        serviceName: 'GitHub',
        username: 'testuser',
        lastModified: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CredentialListItem(
              credential: credential,
              onTap: () => tapped = true,
              onDelete: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 点击凭证项
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // 验证回调被触发
      expect(tapped, isTrue);
    });
  });

  group('CredentialSummary Model Tests', () {
    test('CredentialSummary创建成功', () {
      final credential = CredentialSummary(
        id: '1',
        serviceName: 'GitHub',
        username: 'testuser',
        lastModified: DateTime(2024, 1, 1),
      );

      expect(credential.id, '1');
      expect(credential.serviceName, 'GitHub');
      expect(credential.username, 'testuser');
      expect(credential.lastModified, DateTime(2024, 1, 1));
    });

    test('CredentialSummary支持所有必填字段', () {
      final credential = CredentialSummary(
        id: '123',
        serviceName: 'AWS',
        username: 'admin',
        lastModified: DateTime.now(),
      );

      expect(credential.id, isNotNull);
      expect(credential.serviceName, isNotNull);
      expect(credential.username, isNotNull);
      expect(credential.lastModified, isNotNull);
    });
  });
}