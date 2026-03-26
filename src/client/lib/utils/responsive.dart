import 'package:flutter/material.dart';

/// 响应式布局工具
/// 支持手机、平板、桌面多设备适配

enum DeviceType { mobile, tablet, desktop }

class ResponsiveHelper {
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return DeviceType.mobile;
    if (width < 1200) return DeviceType.tablet;
    return DeviceType.desktop;
  }
  
  static bool isMobile(BuildContext context) => getDeviceType(context) == DeviceType.mobile;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;
  
  static T responsive<T>(BuildContext context, {required T mobile, T? tablet, T? desktop}) {
    switch (getDeviceType(context)) {
      case DeviceType.desktop: return desktop ?? tablet ?? mobile;
      case DeviceType.tablet: return tablet ?? mobile;
      case DeviceType.mobile: return mobile;
    }
  }
}

/// 响应式布局构建器
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;
  
  const ResponsiveBuilder({super.key, required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveHelper.getDeviceType(context));
  }
}

/// 响应式值
class ResponsiveValue<T> {
  final T mobile;
  final T? tablet;
  final T? desktop;
  
  const ResponsiveValue({required this.mobile, this.tablet, this.desktop});
  
  T resolve(BuildContext context) => ResponsiveHelper.responsive(context, mobile: mobile, tablet: tablet, desktop: desktop);
}

/// 响应式间距
class ResponsiveSpacing {
  static double small(BuildContext context) => ResponsiveHelper.responsive(context, mobile: 8.0, tablet: 12.0, desktop: 16.0);
  static double medium(BuildContext context) => ResponsiveHelper.responsive(context, mobile: 16.0, tablet: 24.0, desktop: 32.0);
  static double large(BuildContext context) => ResponsiveHelper.responsive(context, mobile: 24.0, tablet: 32.0, desktop: 48.0);
  
  static EdgeInsets screenPadding(BuildContext context) => EdgeInsets.all(medium(context));
  static EdgeInsets cardPadding(BuildContext context) => EdgeInsets.all(small(context));
}

/// 响应式网格
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  
  const ResponsiveGrid({super.key, required this.children, this.spacing = 16, this.runSpacing = 16});
  
  int _getCrossAxisCount(BuildContext context) {
    return ResponsiveHelper.responsive(context, mobile: 1, tablet: 2, desktop: 3);
  }
  
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: runSpacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1.5,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 自适应布局 - 主从视图
class AdaptiveMasterDetail extends StatelessWidget {
  final Widget master;
  final Widget? detail;
  final String title;
  
  const AdaptiveMasterDetail({super.key, required this.master, this.detail, required this.title});
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return Row(
        children: [
          SizedBox(width: 320, child: master),
          const VerticalDivider(width: 1),
          Expanded(child: detail ?? const Center(child: Text('选择项目查看详情'))),
        ],
      );
    }
    return master;
  }
}

/// 自适应导航
class AdaptiveNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget body;
  
  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        labelType: NavigationRailLabelType.all,
        destinations: destinations.map((d) => NavigationRailDestination(icon: d.icon, label: Text(d.label))).toList(),
        leading: const FlutterLogo(size: 32),
      );
    }
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
    );
  }
}

/// 触摸目标大小优化
class TouchTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minSize;
  
  const TouchTarget({super.key, required this.child, this.onTap, this.minSize = 48});
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
        child: Center(child: child),
      ),
    );
  }
}

/// 自适应字体大小
class AdaptiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  
  const AdaptiveText(this.text, {super.key, this.style, this.textAlign});
  
  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium;
    final scaleFactor = ResponsiveHelper.responsive(context, mobile: 1.0, tablet: 1.1, desktop: 1.2);
    
    return Text(
      text,
      style: baseStyle?.copyWith(fontSize: (baseStyle.fontSize ?? 14) * scaleFactor),
      textAlign: textAlign,
    );
  }
}