import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polyvault/utils/responsive.dart';

void main() {
  group('Responsive Layout Tests', () {
    testWidgets('ResponsiveLayout根据屏幕尺寸选择布局', (WidgetTester tester) async {
      // 测试手机尺寸
      await tester.binding.setSurfaceSize(const Size(375, 812));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Container(key: const Key('mobile')),
            tablet: Container(key: const Key('tablet')),
            desktop: Container(key: const Key('desktop')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 在手机尺寸下应该显示mobile布局
      expect(find.byKey(const Key('mobile')), findsOneWidget);
      expect(find.byKey(const Key('tablet')), findsNothing);
      expect(find.byKey(const Key('desktop')), findsNothing);
    });

    testWidgets('平板尺寸显示tablet布局', (WidgetTester tester) async {
      // 测试平板尺寸
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Container(key: const Key('mobile')),
            tablet: Container(key: const Key('tablet')),
            desktop: Container(key: const Key('desktop')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 在平板尺寸下应该显示tablet布局
      expect(find.byKey(const Key('mobile')), findsNothing);
      expect(find.byKey(const Key('tablet')), findsOneWidget);
      expect(find.byKey(const Key('desktop')), findsNothing);
    });

    testWidgets('桌面尺寸显示desktop布局', (WidgetTester tester) async {
      // 测试桌面尺寸
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Container(key: const Key('mobile')),
            tablet: Container(key: const Key('tablet')),
            desktop: Container(key: const Key('desktop')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 在桌面尺寸下应该显示desktop布局
      expect(find.byKey(const Key('mobile')), findsNothing);
      expect(find.byKey(const Key('tablet')), findsNothing);
      expect(find.byKey(const Key('desktop')), findsOneWidget);
    });

    testWidgets('ResponsiveLayout支持仅提供mobile布局', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Container(key: const Key('mobile')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('mobile')), findsOneWidget);
    });

    testWidgets('屏幕旋转时重新计算布局', (WidgetTester tester) async {
      // 初始为竖屏
      await tester.binding.setSurfaceSize(const Size(375, 812));
      
      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveLayout(
            mobile: Container(key: const Key('mobile')),
            tablet: Container(key: const Key('tablet')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile')), findsOneWidget);

      // 旋转为横屏
      await tester.binding.setSurfaceSize(const Size(812, 375));
      await tester.pumpAndSettle();

      // 横屏时仍然是mobile布局（因为宽度812 < 768）
      expect(find.byKey(const Key('mobile')), findsOneWidget);
    });
  });

  group('Responsive Helper Tests', () {
    testWidgets('isMobile在窄屏幕上返回true', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      
      bool? isMobileResult;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isMobileResult = ResponsiveHelper.isMobile(context);
              return Container();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(isMobileResult, isTrue);
    });

    testWidgets('isTablet在中等宽度屏幕上返回true', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      
      bool? isTabletResult;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isTabletResult = ResponsiveHelper.isTablet(context);
              return Container();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(isTabletResult, isTrue);
    });

    testWidgets('isDesktop在宽屏幕上返回true', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      
      bool? isDesktopResult;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              isDesktopResult = ResponsiveHelper.isDesktop(context);
              return Container();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(isDesktopResult, isTrue);
    });

    testWidgets('getScreenType返回正确的屏幕类型', (WidgetTester tester) async {
      ScreenType? screenType;
      
      // 测试手机
      await tester.binding.setSurfaceSize(const Size(375, 812));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              screenType = ResponsiveHelper.getScreenType(context);
              return Container();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(screenType, ScreenType.mobile);

      // 测试平板
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      await tester.pumpAndSettle();
      expect(screenType, ScreenType.tablet);

      // 测试桌面
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      await tester.pumpAndSettle();
      expect(screenType, ScreenType.desktop);
    });
  });

  group('Adaptive Padding Tests', () {
    testWidgets('手机使用较小的padding', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePadding(
            mobile: const EdgeInsets.all(16),
            tablet: const EdgeInsets.all(24),
            desktop: const EdgeInsets.all(32),
            child: Container(key: const Key('child')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.all(16));
    });

    testWidgets('平板使用中等padding', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(768, 1024));
      
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePadding(
            mobile: const EdgeInsets.all(16),
            tablet: const EdgeInsets.all(24),
            desktop: const EdgeInsets.all(32),
            child: Container(key: const Key('child')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.all(24));
    });

    testWidgets('桌面使用较大的padding', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1440, 900));
      
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePadding(
            mobile: const EdgeInsets.all(16),
            tablet: const EdgeInsets.all(24),
            desktop: const EdgeInsets.all(32),
            child: Container(key: const Key('child')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, const EdgeInsets.all(32));
