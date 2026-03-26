/// 响应式布局工具
/// 提供断点系统和响应式组件
library responsive;

import 'package:flutter/material.dart';

/// 设备类型
enum DeviceType {
  mobile,   // 手机 (< 600px)
  tablet,   // 平板 (600px - 900px)
  desktop,  // 桌面 (> 900px)
}

/// 断点配置
class Breakpoints {
  const Breakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wide = 1600;
}

/// 响应式工具类
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  /// 媒体查询
  MediaQueryData get mediaQuery => MediaQuery.of(context);

  /// 屏幕尺寸
  Size get screenSize => mediaQuery.size;

  /// 屏幕宽度
  double get width => screenSize.width;

  /// 屏幕高度
  double get height => screenSize.height;

  /// 设备像素比
  double get devicePixelRatio => mediaQuery.devicePixelRatio;

  /// 安全区域
  EdgeInsets get padding => mediaQuery.padding;

  /// 视图内边距
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// 设备类型
  DeviceType get deviceType {
    if (width < Breakpoints.mobile) return DeviceType.mobile;
    if (width < Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// 是否手机
  bool get isMobile => deviceType == DeviceType.mobile;

  /// 是否平板
  bool get isTablet => deviceType == DeviceType.tablet;

  /// 是否桌面
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// 横屏
  bool get isLandscape => width > height;

  /// 竖屏
  bool get isPortrait => height >= width;

  /// 获取响应式值
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// 根据宽度计算列数
  int get gridColumns {
    if (width < Breakpoints.mobile) return 1;
    if (width < Breakpoints.tablet) return 2;
    if (width < Breakpoints.desktop) return 3;
    return 4;
  }

  /// 内容最大宽度
  double get maxContentWidth {
    if (width < Breakpoints.tablet) return width;
    if (width < Breakpoints.desktop) return 600;
    return 800;
  }

  /// 侧边栏宽度
  double get sidebarWidth {
    if (width < Breakpoints.tablet) return width * 0.8;
    return 280;
  }

  /// 卡片宽度
  double get cardWidth {
    if (width < Breakpoints.mobile) return width - 32;
    if (width < Breakpoints.tablet) return (width - 48) / 2;
    return (width - 64) / 3;
  }

  /// 内容内边距
  EdgeInsets get contentPadding => EdgeInsets.symmetric(
    horizontal: value(mobile: 16.0, tablet: 24.0, desktop: 32.0),
    vertical: value(mobile: 12.0, tablet: 16.0, desktop: 20.0),
  );

  /// 列表项间距
  double get listItemSpacing => value(mobile: 8.0, tablet: 12.0, desktop: 16.0);

  /// 卡片内边距
  EdgeInsets get cardPadding => EdgeInsets.all(
    value(mobile: 12.0, tablet: 16.0, desktop: 20.0),
  );

  /// 工厂方法
  static Responsive of(BuildContext context) => Responsive(context);
}

/// 响应式布局构建器
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.of(context));
  }
}

/// 响应式值选择器
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T? desktop;

  const ResponsiveValue({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final value = responsive.value(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
    
    if (value is Widget) return value as Widget;
    throw ArgumentError('Value must be a Widget');
  }
}

/// 响应式网格
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;
  final double? childAspectRatio;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.maxColumns,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final columns = maxColumns ?? responsive.gridColumns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final itemHeight = childAspectRatio != null
            ? itemWidth / childAspectRatio!
            : null;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              height: itemHeight,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// 响应式边距容器
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final padding = responsive.value(
      mobile: mobile ?? const EdgeInsets.all(16),
      tablet: tablet ?? const EdgeInsets.all(24),
      desktop: desktop ?? const EdgeInsets.all(32),
    );

    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// 响应式最大宽度容器
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Alignment alignment;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = 800,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// 自适应布局
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    
    if (responsive.isDesktop && desktop != null) {
      return desktop!;
    }
    
    if (responsive.isTablet && tablet != null) {
      return tablet!;
    }
    
    return mobile;
  }
}

/// 响应式Sliver网格
class ResponsiveSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? maxColumns;
  final double childAspectRatio;

  const ResponsiveSliverGrid({
    super.key,
    required this.children,
    this.spacing = 16,
    this.runSpacing = 16,
    this.maxColumns,
    this.childAspectRatio = 1,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final columns = maxColumns ?? responsive.gridColumns;

    return SliverPadding(
      padding: EdgeInsets.all(spacing),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) => children[index],
          childCount: children.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: runSpacing,
          crossAxisSpacing: spacing,
          childAspectRatio: childAspectRatio,
        ),
      ),
    );
  }
}

/// 响应式侧边栏布局
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? sidebar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final double sidebarWidth;
  final double sidebarBreakpoint;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    this.drawer,
    this.sidebar,
    required this.body,
    this.bottomNavigationBar,
    this.sidebarWidth = 280,
    this.sidebarBreakpoint = Breakpoints.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    
    // 桌面模式显示侧边栏
    if (responsive.width >= sidebarBreakpoint && sidebar != null) {
      return Scaffold(
        appBar: appBar,
        body: Row(
          children: [
            SizedBox(
              width: sidebarWidth,
              child: sidebar!,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        bottomNavigationBar: bottomNavigationBar,
      );
    }
    
    // 移动端使用抽屉
    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}