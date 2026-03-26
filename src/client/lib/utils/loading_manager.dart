/// 加载状态管理
/// 提供统一的加载状态管理和UI组件
library loading_manager;

import 'package:flutter/material.dart';
import '../widgets/skeleton_loader.dart';

/// 加载状态
enum LoadingState {
  idle,       // 空闲
  loading,    // 加载中
  refreshing, // 刷新中
  success,    // 成功
  error,      // 错误
  empty,      // 空数据
}

/// 加载状态控制器
class LoadingController extends ChangeNotifier {
  LoadingState _state = LoadingState.idle;
  String? _message;
  double? _progress;

  LoadingState get state => _state;
  String? get message => _message;
  double? get progress => _progress;

  bool get isLoading => _state == LoadingState.loading || _state == LoadingState.refreshing;
  bool get isIdle => _state == LoadingState.idle;
  bool get isSuccess => _state == LoadingState.success;
  bool get isError => _state == LoadingState.error;
  bool get isEmpty => _state == LoadingState.empty;

  void setLoading([String? message]) {
    _state = LoadingState.loading;
    _message = message;
    _progress = null;
    notifyListeners();
  }

  void setRefreshing([String? message]) {
    _state = LoadingState.refreshing;
    _message = message;
    _progress = null;
    notifyListeners();
  }

  void setProgress(double progress, [String? message]) {
    _progress = progress.clamp(0.0, 1.0);
    _message = message;
    notifyListeners();
  }

  void setSuccess() {
    _state = LoadingState.success;
    _message = null;
    _progress = null;
    notifyListeners();
  }

  void setError([String? message]) {
    _state = LoadingState.error;
    _message = message;
    _progress = null;
    notifyListeners();
  }

  void setEmpty([String? message]) {
    _state = LoadingState.empty;
    _message = message;
    _progress = null;
    notifyListeners();
  }

  void reset() {
    _state = LoadingState.idle;
    _message = null;
    _progress = null;
    notifyListeners();
  }
}

/// 加载状态包装器
class LoadingWrapper extends StatefulWidget {
  final Widget child;
  final LoadingController? controller;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final VoidCallback? onRetry;
  final String? emptyMessage;

  const LoadingWrapper({
    super.key,
    required this.child,
    this.controller,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.onRetry,
    this.emptyMessage,
  });

  @override
  State<LoadingWrapper> createState() => _LoadingWrapperState();
}

class _LoadingWrapperState extends State<LoadingWrapper> {
  late LoadingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? LoadingController();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return widget.loadingWidget ?? const DefaultLoadingWidget();
    }

    if (_controller.isError) {
      return widget.errorWidget ?? DefaultErrorWidget(
        message: _controller.message ?? '加载失败',
        onRetry: widget.onRetry,
      );
    }

    if (_controller.isEmpty) {
      return widget.emptyWidget ?? DefaultEmptyWidget(
        message: widget.emptyMessage ?? _controller.message,
      );
    }

    return widget.child;
  }
}

/// 默认加载组件
class DefaultLoadingWidget extends StatelessWidget {
  final String? message;
  final double? progress;

  const DefaultLoadingWidget({
    super.key,
    this.message,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (progress != null) ...[
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
          ],
          if (message != null)
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

/// 默认错误组件
class DefaultErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;

  const DefaultErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 默认空状态组件
class DefaultEmptyWidget extends StatelessWidget {
  final String? message;
  final IconData? icon;
  final Widget? action;

  const DefaultEmptyWidget({
    super.key,
    this.message,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              message ?? '暂无数据',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
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

/// 骨架屏加载组件
class SkeletonLoadingWidget extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int)? itemBuilder;
  final SkeletonType type;

  const SkeletonLoadingWidget({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
    this.type = SkeletonType.list,
  });

  @override
  Widget build(BuildContext context) {
    if (type == SkeletonType.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: itemBuilder ?? (context, index) => _buildDefaultSkeletonItem(context),
      );
    }

    if (type == SkeletonType.grid) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: itemCount,
        itemBuilder: itemBuilder ?? (context, index) => _buildDefaultSkeletonCard(context),
      );
    }

    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildDefaultSkeletonItem(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SkeletonLoader(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                SkeletonLoader(
                  width: 150,
                  height: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultSkeletonCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 12),
          SkeletonLoader(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          SkeletonLoader(
            width: 80,
            height: 12,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

/// 骨架屏类型
enum SkeletonType {
  list,
  grid,
  custom,
}

/// 加载按钮
class LoadingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Future<void> Function()? onAsyncPressed;
  final Widget child;
  final ButtonStyle? style;
  final bool isDestructive;
  final Duration? minLoadingDuration;

  const LoadingButton({
    super.key,
    this.onPressed,
    this.onAsyncPressed,
    required this.child,
    this.style,
    this.isDestructive = false,
    this.minLoadingDuration,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading) return;

    if (widget.onAsyncPressed != null) {
      setState(() => _isLoading = true);
      
      try {
        await widget.onAsyncPressed!();
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FilledButton(
      onPressed: _isLoading ? null : _handlePress,
      style: widget.style ?? FilledButton.styleFrom(
        backgroundColor: widget.isDestructive ? colorScheme.error : null,
      ),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onPrimary,
              ),
            )
          : widget.child,
    );
  }
}

/// 带刷新的加载组件
class RefreshableContent<T> extends StatefulWidget {
  final Future<List<T>> Function() onRefresh;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const RefreshableContent({
    super.key,
    required this.onRefresh,
    required this.itemBuilder,
    this.emptyWidget,
    this.loadingWidget,
    this.errorWidget,
    this.padding,
    this.controller,
  });

  @override
  State<RefreshableContent<T>> createState() => _RefreshableContentState<T>();
}

class _RefreshableContentState<T> extends State<RefreshableContent<T>> {
  List<T> _items = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.onRefresh();
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? const SkeletonLoadingWidget();
    }

    if (_error != null) {
      return widget.errorWidget ?? DefaultErrorWidget(
        message: _error!,
        onRetry: _load,
      );
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ?? const DefaultEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: widget.controller,
        padding: widget.padding ?? const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) => widget.itemBuilder(context, _items[index], index),
      ),
    );
  }
}