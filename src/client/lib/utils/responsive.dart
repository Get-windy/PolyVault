import 'package:flutter/material.dart';

/// 响应式布局辅助工具
class ResponsiveUtils {
  /// 获取屏幕尺寸类别
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return ScreenSize.small;
    } else if (width < 840) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }

  /// 判断是否是移动设备
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// 判断是否是平板
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 840;
  }

  /// 判断是否是桌面设备
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 840;
  }

  /// 获取列数（根据屏幕宽度）
  static int getCrossAxisCount(BuildContext context, {int small = 1, int medium = 2, int large = 3}) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.large:
        return large;
    }
  }

  /// 获取内边距
  static EdgeInsets getPadding(BuildContext context) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.small:
        return const EdgeInsets.all(12);
      case ScreenSize.medium:
        return const EdgeInsets.all(20);
      case ScreenSize.large:
        return const EdgeInsets.all(32);
    }
  }

  /// 获取卡片宽度
  static double getCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return width - 24;
    } else if (width < 840) {
      return (width - 48) / 2;
    } else {
      return (width - 64) / 3;
    }
  }

  /// 获取字体大小
  static double getFontSize(BuildContext context, {double small = 14, double medium = 16, double large = 18}) {
    final size = getScreenSize(context);
    switch (size) {
      case ScreenSize.small:
        return small;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.large:
        return large;
    }
  }
}

/// 屏幕尺寸枚举
enum ScreenSize {
  small,   // 手机
  medium,  // 平板
  large,   // 桌面
}

/// 响应式网格视图
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final EdgeInsets? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveUtils.getCrossAxisCount(
          context,
          small: 1,
          medium: 2,
          large: 3,
        );

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          padding: padding ?? ResponsiveUtils.getPadding(context),
          children: children,
        );
      },
    );
  }
}

/// 响应式单列/双列视图
class ResponsiveListView extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsiveListView({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: maxWidth != null 
            ? BoxConstraints(maxWidth: maxWidth!)
            : const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
  }
}

/// 响应式卡片
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
        child: Padding(
          padding: padding ?? EdgeInsets.all(isMobile ? 12 : 16),
          child: child,
        ),
      ),
    );
  }
}

/// 响应式图标按钮
class ResponsiveIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double? size;

  const ResponsiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? (ResponsiveUtils.isMobile(context) ? 24 : 28);

    return IconButton(
      icon: Icon(icon, size: iconSize),
      onPressed: onPressed,
      tooltip: tooltip,
      iconSize: iconSize,
    );
  }
}

/// 响应式文本
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = ResponsiveUtils.getFontSize(context);

    return Text(
      text,
      style: style?.copyWith(fontSize: style?.fontSize ?? fontSize) ??
          TextStyle(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}