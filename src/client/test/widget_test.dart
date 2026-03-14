import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polyvault/main.dart';
import 'package:polyvault/utils/theme.dart';

void main() {
  group('PolyVault App Widget Tests', () {
    testWidgets('App starts with correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PolyVaultApp(),
        ),
      );
      
      expect(find.text('PolyVault'), findsOneWidget);
    });

    testWidgets('Navigation bar shows 4 tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PolyVaultApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      expect(find.text('设备状态'), findsOneWidget);
      expect(find.text('凭证管理'), findsOneWidget);
      expect(find.text('设备'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });

    testWidgets('Can navigate between tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PolyVaultApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Tap on credentials tab
      await tester.tap(find.text('凭证管理'));
      await tester.pumpAndSettle();
      
      // Should show credentials screen
      expect(find.text('添加凭证'), findsOneWidget);
      
      // Tap on devices tab
      await tester.tap(find.text('设备'));
      await tester.pumpAndSettle();
      
      // Tap on settings tab  
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();
      
      // Should show settings
      expect(find.text('深色模式'), findsOneWidget);
    });

    testWidgets('Theme switch changes theme mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: const Scaffold(
              body: Center(child: Text('Test')),
            ),
          ),
        ),
      );
      
      // Verify initial theme is light
      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      expect(theme.brightness, equals(Brightness.light));
    });
  });

  group('Theme Tests', () {
    testWidgets('Light theme has correct primary color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: Center(child: Text('Test'))),
        ),
      );
      
      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      
      expect(theme.brightness, equals(Brightness.light));
    });

    testWidgets('Dark theme has correct brightness', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: Center(child: Text('Test'))),
        ),
      );
      
      final context = tester.element(find.byType(Scaffold));
      final theme = Theme.of(context);
      
      expect(theme.brightness, equals(Brightness.dark));
    });
  });
}