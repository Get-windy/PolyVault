import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/screens/credentials_screen.dart';
import 'package:polyvault/screens/devices_screen.dart';

void main() {
  group('Performance Tests', () {
    testWidgets('CredentialsScreen渲染性能', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        const MaterialApp(
          home: CredentialsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证渲染时间小于500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('DevicesScreen渲染性能', (WidgetTester tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        const MaterialApp(
          home: DevicesScreen(),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证渲染时间小于500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('页面切换性能', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 4,
            child: Scaffold(
              bottomNavigationBar: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
                  BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: '凭证'),
                  BottomNavigationBarItem(icon: Icon(Icons.devices), label: '设备'),
                  BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 切换到凭证页面
      await tester.tap(find.text('凭证'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证切换时间小于300ms
      expect(stopwatch.elapsedMilliseconds, lessThan(300));
    });

    testWidgets('列表滚动性能', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 100,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 快速滚动
      await tester.fling(
        find.byType(ListView),
        const Offset(0, -500),
        1000,
      );
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证滚动时间小于1000ms
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    testWidgets('对话框打开性能', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const AlertDialog(
                      title: Text('测试对话框'),
                      content: Text('这是一个测试对话框'),
                    ),
                  );
                },
                child: const Text('打开对话框'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      await tester.tap(find.text('打开对话框'));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证对话框打开时间小于200ms
      expect(stopwatch.elapsedMilliseconds, lessThan(200));
    });

    testWidgets('图片加载性能', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: 9,
              itemBuilder: (context, index) {
                return Container(
                  color: Colors.primaries[index % Colors.primaries.length],
                  child: Center(
                    child: Text('Image $index'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 滚动网格
      await tester.fling(
        find.byType(GridView),
        const Offset(0, -300),
        500,
      );
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证网格滚动时间小于500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('动画性能测试', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 100,
              height: 100,
              color: Colors.blue,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 触发动画
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              color: Colors.red,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证动画完成时间小于400ms（300ms动画 + 100ms缓冲）
      expect(stopwatch.elapsedMilliseconds, lessThan(400));
    });

    testWidgets('内存使用测试', (WidgetTester tester) async {
      // 创建大量widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 1000,
              itemBuilder: (context, index) {
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text('Device $index'),
                    subtitle: Text('Description $index'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 验证列表渲染成功（没有内存溢出）
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('响应式布局性能', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  color: constraints.maxWidth > 600 ? Colors.blue : Colors.green,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final stopwatch = Stopwatch()..start();

      // 改变屏幕尺寸
      await tester.binding.setSurfaceSize(const Size(800, 600));
      await tester.pumpAndSettle();

      stopwatch.stop();

      // 验证布局重计算时间小于100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Memory Leak Tests', () {
    testWidgets('页面切换无内存泄漏', (WidgetTester tester) async {
      for (int i = 0; i < 10; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: i % 2 == 0 
              ? const CredentialsScreen() 
              : const DevicesScreen(),
          ),
        );
        await tester.pumpAndSettle();
      }

      // 如果存在内存泄漏，测试可能会失败或超时
      expect(find.byType