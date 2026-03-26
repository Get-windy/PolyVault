import 'package:flutter/material.dart';

/// UX优化组件集合
/// 提供统一的加载状态、空状态、错误状态组件

// ==================== 加载状态组件 ====================

/// 全屏加载指示器
class FullScreenLoader extends StatelessWidget {
  final String? message;
  
  const FullScreenLoader({super.key, this.message});
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// 内联加载指示器
class InlineLoader extends StatelessWidget {
  final double size;
  final double strokeWidth;
  
  const InlineLoader({super.key, this.size = 20, this.strokeWidth = 2});
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth),
    );
  }
}

/// 骨架屏加载
class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  
  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    );
  }
}

/// 列表骨架屏
class ListSkeleton extends StatelessWidget {
  final int itemCount;
  
  const ListSkeleton({super.key, this.itemCount = 5});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            const SkeletonLoader(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonLoader(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  SkeletonLoader(width: MediaQuery.of(context).size.width * 0.6, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 空状态组件 ====================

/// 空状态显示
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionText,
    this.onAction,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              FilledButton(onPressed: onAction, child: Text(actionText!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== 错误状态组件 ====================

/// 错误状态显示
class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;
  
  const ErrorStateWidget({
    super.key,
    required this.message,
    this.retryText,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('出错了', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              OutlinedButton(onPressed: onRetry, child: Text(retryText ?? '重试')),
            ],
          ],
        ),
      ),
    );
  }
}

// ==================== 交互反馈组件 ====================

/// 触感反馈按钮
class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  
  const HapticButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
  });
  
  void _handlePress() {
    // 触感反馈
    // HapticFeedback.lightImpact();
    onPressed?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: style,
      onPressed: onPressed != null ? _handlePress : null,
      child: child,
    );
  }
}

/// 滑动刷新包装器
class PullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  
  const PullToRefresh({
    super.key,
    required this.child,
    required this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

// ==================== Toast提示 ====================

/// 显示Toast消息
void showToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// 显示成功Toast
void showSuccessToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text(message)]),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}