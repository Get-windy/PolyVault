import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/widgets/custom_button.dart';
import 'package:polyvault/widgets/empty_state.dart';
import 'package:polyvault/widgets/loading_shimmer.dart';
import 'package:polyvault/widgets/stats_card.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('CustomButton显示正确的文本', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: '点击我',
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('点击我'), findsOneWidget);
    });

    testWidgets('CustomButton点击触发回调', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: '点击我',
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('点击我'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('CustomButton支持图标', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: '保存',
              icon: Icons.save,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets('CustomButton支持禁用状态', (WidgetTester tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: '禁用按钮',
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('禁用按钮'));
      await tester.pumpAndSettle();

      expect(pressed, isFalse);
    });

    testWidgets('CustomButton支持加载状态', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: '加载中',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CustomButton支持不同类型', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                CustomButton(
                  text: '主要按钮',
                  type: ButtonType.primary,
                  onPressed: () {},
                ),
                CustomButton(
                  text: '次要按钮',
                  type: ButtonType.secondary,
                  onPressed: () {},
                ),
                CustomButton(
                  text: '危险按钮',
                  type: ButtonType.danger,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('主要按钮'), findsOneWidget);
      expect(find.text('次要按钮'), findsOneWidget);
      expect(find.text('危险按钮'), findsOneWidget);
    });
  });

  group('EmptyState Widget Tests', () {
    testWidgets('EmptyState显示正确的内容', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '没有数据',
              message: '这里还没有任何内容',
              actionLabel: '添加数据',
              onAction: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('没有数据'), findsOneWidget);
      expect(find.text('这里还没有任何内容'), findsOneWidget);
      expect(find.text('添加数据'), findsOneWidget);
    });

    testWidgets('EmptyState点击按钮触发回调', (WidgetTester tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '没有数据',
              message: '这里还没有任何内容',
              actionLabel: '添加数据',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('添加数据'));
      await tester.pumpAndSettle();

      expect(actionPressed, isTrue);
    });

    testWidgets('EmptyState支持无操作按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: '没有数据',
              message: '这里还没有任何内容',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('没有数据'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  group('LoadingShimmer Widget Tests', () {
    testWidgets('LoadingShimmer显示骨架屏', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingShimmer(
              child: Container(
                height: 100,
                width: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    testWidgets('LoadingShimmer支持列表模式', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingShimmer.list(
              itemCount: 3,
              itemHeight: 60,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });

    testWidgets('LoadingShimmer支持卡片模式', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingShimmer.card(
              height: 120,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoadingShimmer), findsOneWidget);
    });
  });

  group('StatsCard Widget Tests', () {
    testWidgets('StatsCard显示正确的统计数据', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              icon: Icons.devices,
              label: '设备数量',
              value: '12',
              color: Colors.blue,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.devices), findsOneWidget);
      expect(find.text('设备数量'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('StatsCard支持趋势指示', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsCard(
              icon: Icons.trending_up,
              label: '增长率',
              value: '+15%',
              color: Colors.green,
              trend: Trend.up,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('+15%'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
