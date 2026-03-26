import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// PolyVault 增强容器组件
/// 提供统一的容器样式和状态处理

/// 圆角容器
class RoundedContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final void Function()? onTap;
  final double? elevation;
  final AlignmentGeometry? alignment;

  const RoundedContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
    this.border,
    this.shadow,
    this.onTap,
    this.elevation,
    this.alignment,
  }) : assert(
          (border == null && shadow == null) ||
              (elevation == null),
          'Cannot specify both border and elevation',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectiveMargin = margin ?? EdgeInsets.zero;
    final effectiveBorderRadius = borderRadius ?? AppRadius.md;
    
    final defaultShadow = [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: elevation != null ? elevation! * 4 : 8,
        offset: Offset(0, elevation != null ? elevation! * 2 : 4),
      ),
    ];
    
    final effectiveShadow = shadow ?? (elevation != null ? defaultShadow : null);

    Widget container = Container(
      width: width,
      height: height,
      color: color,
      padding: effectivePadding,
      margin: effectiveMargin,
      alignment: alignment,
      child: child,
    );

    if (effectiveBorderRadius != null || effectiveShadow != null || border != null) {
      container = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius != null
              ? BorderRadius.circular(effectiveBorderRadius)
              : null,
          boxShadow: effectiveShadow,
          border: border,
          color: color,
        ),
        child: container,
      );
    }

    if (onTap != null) {
      container = GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }
}

/// 提升的容器 - 用于重要界面区域
class ElevatedContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double? elevation;
  final void Function()? onTap;
  final AlignmentGeometry? alignment;

  const ElevatedContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
    this.elevation = 4,
    this.onTap,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return RoundedContainer(
      child: child,
      width: width,
      height: height,
      color: color ?? Theme.of(context).cardTheme.color,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin ?? const EdgeInsets.all(0),
      borderRadius: borderRadius ?? AppRadius.lg,
      elevation: elevation,
      onTap: onTap,
      alignment: alignment,
    );
  }
}

/// 信息容器
class InfoContainer extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final void Function()? onTap;
  final_alignment;

  const InfoContainer({
    super.key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RoundedContainer(
      child: child,
      color: color ?? theme.colorScheme.primary.withOpacity(0.1),
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.all(0),
      borderRadius: borderRadius ?? AppRadius.md,
      border: Border.all(
        color: color ?? theme.colorScheme.primary,
        width: 1.5,
      ),
      onTap: onTap,
      alignment: alignment,
    );
  }
}

/// 警告容器
class WarningContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final void Function()? onTap;

  const WarningContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RoundedContainer(
      child: child,
      color: theme.colorScheme.warning.withOpacity(0.1),
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.all(0),
      borderRadius: borderRadius ?? AppRadius.md,
      border: Border.all(
        color: theme.colorScheme.warning,
        width: 1.5,
      ),
      onTap: onTap,
    );
  }
}

/// 错误容器
class ErrorContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final void Function()? onTap;

  const ErrorContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RoundedContainer(
      child: child,
      color: theme.colorScheme.error.withOpacity(0.1),
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.all(0),
      borderRadius: borderRadius ?? AppRadius.md,
      border: Border.all(
        color: theme.colorScheme.error,
        width: 1.5,
      ),
      onTap: onTap,
    );
  }
}

/// 成功容器
class SuccessContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final void Function()? onTap;

  const SuccessContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return RoundedContainer(
      child: child,
      color: theme.colorScheme.success.withOpacity(0.1),
      padding: padding ?? const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.all(0),
      borderRadius: borderRadius ?? AppRadius.md,
      border: Border.all(
        color: theme.colorScheme.success,
        width: 1.5,
      ),
      onTap: onTap,
    );
  }
}

/// 卡片标题
class CardHeader extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final void Function()? onTap;

  const CardHeader({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (leading != null)
            SizedBox(
              width: 40,
              height: 40,
              child: leading!,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DefaultTextStyle.merge(
                style: theme.textTheme.headlineSmall ??
                    const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                child: title,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 卡片内容区域
class CardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? spacing;

  const CardContent({
    super.key,
    required this.child,
    this.padding,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.all(0);
    
    return Padding(
      padding: effectivePadding,
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          fontSize: 14,
          height: 1.6,
          color: AppColors.textPrimaryLight,
        ),
        child: child,
      ),
    );
  }
}

/// 卡片底部区域
class CardFooter extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final EdgeInsetsGeometry? padding;
  final Color? dividerColor;

  const CardFooter({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.padding,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? const EdgeInsets.fromLTRB(24, 16, 24, 24);
    
    return Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        border: Border(
          top: Divider.createBorderSide(
            context,
            color: dividerColor ?? AppColors.textMutedLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (leading != null) leading!,
          if (title != null) Expanded(child: title!),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}

/// 带图标和标题的卡片
class IconCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Color? iconColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final void Function()? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const IconCard({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.iconColor,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.onTap,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final iconColorEffective = iconColor ?? theme.colorScheme.primary;
    final backgroundColorEffective = backgroundColor ?? theme.cardTheme.color;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: padding ?? const EdgeInsets.all(20),
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColorEffective,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColorEffective.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                icon,
                color: iconColorEffective,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall ??
                        const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMutedLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// 带进度的卡片
class ProgressCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double progress;
  final Color? progressColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final void Function()? onTap;
  final bool showProgressText;

  const ProgressCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.progress,
    this.progressColor,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.onTap,
    this.showProgressText = false,
  }) : assert(
          progress >= 0.0 && progress <= 1.0,
          'Progress must be between 0.0 and 1.0',
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardTheme.color,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.textMutedLight.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge ??
                            const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                    ],
                  ),
                ),
                if (showProgressText)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: theme.textTheme.bodyLarge ??
                        const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.textMutedLight.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progressColor ?? theme.colorScheme.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 分隔符
class AppDivider extends StatelessWidget {
  final double? height;
  final Color? color;
  final double? thickness;
  final EdgeInsetsGeometry? margin;

  const AppDivider({
    super.key,
    this.height,
    this.color,
    this.thickness,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textMutedLight;
    
    return Divider(
      height: height ?? 1,
      color: effectiveColor,
      thickness: thickness ?? 1,
      space: margin?.vertical ?? 0,
    );
  }
}

/// 空状态容器
class EmptyStateContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;

  const EmptyStateContainer({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.padding,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.textMutedLight).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.textMutedLight,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall ??
                  const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// 加载骨架屏
class SkeletonContainer extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color? skeletonColor;
  final Color? baseColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SkeletonContainer({
    super.key,
    required this.child,
    this.isLoading = false,
    this.skeletonColor,
    this.baseColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!isLoading) return child;

    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final effectiveMargin = margin ?? EdgeInsets.zero;

    return Container(
      padding: effectivePadding,
      margin: effectiveMargin,
      decoration: BoxDecoration(
        color: baseColor ?? theme.cardTheme.color,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Opacity(
        opacity: 0.7,
        child: Container(
          decoration: BoxDecoration(
            color: skeletonColor ?? AppColors.textMutedLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          height: 100,
          width: double.infinity,
        ),
      ),
    );
  }
}
