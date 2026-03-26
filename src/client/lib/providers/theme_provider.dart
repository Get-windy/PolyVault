/// 主题状态管理
/// 支持亮色/暗色/系统跟随模式
library theme_provider;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

/// 主题模式
enum AppThemeMode {
  system,  // 跟随系统
  light,   // 亮色
  dark,    // 暗色
}

/// 主题模式状态
class ThemeModeState {
  final AppThemeMode mode;
  final ThemeMode flutterMode;

  const ThemeModeState({
    required this.mode,
    required this.flutterMode,
  });

  factory ThemeModeState.fromAppMode(AppThemeMode mode) {
    return ThemeModeState(
      mode: mode,
      flutterMode: switch (mode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
    );
  }

  ThemeModeState copyWith({AppThemeMode? mode}) {
    return ThemeModeState.fromAppMode(mode ?? this.mode);
  }
}

/// 主题模式状态管理
class ThemeModeNotifier extends StateNotifier<ThemeModeState> {
  ThemeModeNotifier() : super(ThemeModeState.fromAppMode(AppThemeMode.system));

  /// 设置主题模式
  void setMode(AppThemeMode mode) {
    state = ThemeModeState.fromAppMode(mode);
  }

  /// 切换亮暗模式
  void toggle() {
    final newMode = state.mode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    setMode(newMode);
  }

  /// 使用亮色模式
  void useLight() => setMode(AppThemeMode.light);

  /// 使用暗色模式
  void useDark() => setMode(AppThemeMode.dark);

  /// 使用系统模式
  void useSystem() => setMode(AppThemeMode.system);
}

/// 主题模式Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeModeState>(
  (ref) => ThemeModeNotifier(),
);

/// 当前是否暗色模式
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return themeMode.mode == AppThemeMode.dark;
});

/// 亮色主题Provider
final lightThemeProvider = Provider<ThemeData>((ref) => AppTheme.lightTheme());

/// 暗色主题Provider
final darkThemeProvider = Provider<ThemeData>((ref) => AppTheme.darkTheme());

/// 主题数据Provider
final themeDataProvider = Provider<ThemeData>((ref) {
  final isDark = ref.watch(isDarkModeProvider);
  return isDark 
      ? ref.watch(darkThemeProvider) 
      : ref.watch(lightThemeProvider);
});

/// 颜色方案Provider
final colorSchemeProvider = Provider<ColorScheme>((ref) {
  final theme = ref.watch(themeDataProvider);
  return theme.colorScheme;
});

/// 文本主题Provider
final textThemeProvider = Provider<TextTheme>((ref) {
  final theme = ref.watch(themeDataProvider);
  return theme.textTheme;
});

/// 主题工具扩展
extension ThemeRef on WidgetRef {
  /// 获取当前主题
  ThemeData get theme => watch(themeDataProvider);

  /// 获取颜色方案
  ColorScheme get colorScheme => watch(colorSchemeProvider);

  /// 获取文本主题
  TextTheme get textTheme => watch(textThemeProvider);

  /// 是否暗色模式
  bool get isDarkMode => watch(isDarkModeProvider);

  /// 设置主题模式
  void setThemeMode(AppThemeMode mode) {
    read(themeModeProvider.notifier).setMode(mode);
  }

  /// 切换主题
  void toggleTheme() {
    read(themeModeProvider.notifier).toggle();
  }
}

/// 主题切换组件
class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDarkMode;

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
      ),
      onPressed: () => ref.toggleTheme(),
      tooltip: isDark ? '切换到亮色模式' : '切换到暗色模式',
    );
  }
}

/// 主题模式选择器
class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeModeProvider).mode;
    final colorScheme = ref.colorScheme;

    return SegmentedButton<AppThemeMode>(
      segments: [
        ButtonSegment(
          value: AppThemeMode.system,
          label: const Text('系统'),
          icon: const Icon(Icons.brightness_auto),
        ),
        ButtonSegment(
          value: AppThemeMode.light,
          label: const Text('亮色'),
          icon: const Icon(Icons.light_mode),
        ),
        ButtonSegment(
          value: AppThemeMode.dark,
          label: const Text('暗色'),
          icon: const Icon(Icons.dark_mode),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (Set<AppThemeMode> selection) {
        ref.setThemeMode(selection.first);
      },
    );
  }
}

/// 主题包装组件
class ThemeWrapper extends ConsumerWidget {
  final Widget child;

  const ThemeWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).flutterMode;
    final lightTheme = ref.watch(lightThemeProvider);
    final darkTheme = ref.watch(darkThemeProvider);

    return MaterialApp(
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: child,
    );
  }
}

/// 暗色模式包装组件
class DarkModeBuilder extends ConsumerWidget {
  final Widget Function(BuildContext context, bool isDark) builder;

  const DarkModeBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.isDarkMode;
    return builder(context, isDark);
  }
}