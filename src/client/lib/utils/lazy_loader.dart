/// 懒加载工具
/// 提供列表懒加载、组件延迟加载等功能
library lazy_loader;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// 懒加载列表控制器
class LazyLoadController extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  final int _pageSize;

  LazyLoadController({int pageSize = 20}) : _pageSize = pageSize;

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;

  void startLoading() {
    _isLoading = true;
    notifyListeners();
  }

  void finishLoading({bool hasMore = true}) {
    _isLoading = false;
    _hasMore = hasMore;
    _currentPage++;
    notifyListeners();
  }

  void reset() {
    _isLoading = false;
    _hasMore = true;
    _currentPage = 0;
    notifyListeners();
  }
}

/// 懒加载列表组件
class LazyLoadListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final Widget? loadingIndicator;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;
  final double loadMoreThreshold;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;

  const LazyLoadListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.loadingIndicator,
    this.emptyWidget,
    this.padding,
    this.controller,
    this.loadMoreThreshold = 200,
    this.enablePullToRefresh = false,
    this.onRefresh,
  });

  @override
  State<LazyLoadListView<T>> createState() => _LazyLoadListViewState<T>();
}

class _LazyLoadListViewState<T> extends State<LazyLoadListView<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    
    if (maxScroll - currentScroll <= widget.loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (widget.onLoadMore == null) return;
    
    setState(() => _isLoadingMore = true);
    await widget.onLoadMore!();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget listView = ListView.builder(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(16),
      itemCount: widget.items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          return widget.loadingIndicator ?? 
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
        }
        return widget.itemBuilder(context, widget.items[index], index);
      },
    );

    if (widget.enablePullToRefresh && widget.onRefresh != null) {
      listView = RefreshIndicator(
        onRefresh: widget.onRefresh!,
        child: listView,
      );
    }

    if (widget.items.isEmpty && !_isLoadingMore) {
      return widget.emptyWidget ?? const Center(child: Text('暂无数据'));
    }

    return listView;
  }
}

/// 延迟加载组件
class DeferredLoadWidget extends StatefulWidget {
  final Widget Function() builder;
  final Duration delay;
  final Widget? placeholder;

  const DeferredLoadWidget({
    super.key,
    required this.builder,
    this.delay = const Duration(milliseconds: 100),
    this.placeholder,
  });

  @override
  State<DeferredLoadWidget> createState() => _DeferredLoadWidgetState();
}

class _DeferredLoadWidgetState extends State<DeferredLoadWidget> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _deferLoad();
  }

  void _deferLoad() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      Future.delayed(widget.delay, () {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return widget.builder();
  }
}

/// 可见性检测组件
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final void Function(bool isVisible)? onVisibilityChanged;
  final double visibilityThreshold;

  const VisibilityDetector({
    super.key,
    required this.child,
    this.onVisibilityChanged,
    this.visibilityThreshold = 0.5,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> with RouteAware {
  bool _isVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 简化的可见性检测
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderObject = context.findRenderObject();
      if (renderObject != null) {
        final bounds = renderObject.paintBounds;
        final isVisible = bounds.width > 0 && bounds.height > 0;
        if (_isVisible != isVisible) {
          _isVisible = isVisible;
          widget.onVisibilityChanged?.call(isVisible);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 按需加载的页面
class OnDemandPage extends StatefulWidget {
  final Widget Function() pageBuilder;
  final bool keepAlive;

  const OnDemandPage({
    super.key,
    required this.pageBuilder,
    this.keepAlive = false,
  });

  @override
  State<OnDemandPage> createState() => _OnDemandPageState();
}

class _OnDemandPageState extends State<OnDemandPage> with AutomaticKeepAliveClientMixin {
  Widget? _page;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  void _loadPage() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _page = widget.pageBuilder();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _page ?? const Center(child: CircularProgressIndicator());
  }
}

/// 分页加载混入
mixin PaginatedLoaderMixin<T extends StatefulWidget> on State<T> {
  List<dynamic> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;
  final int _pageSize = 20;

  List<dynamic> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  int get page => _page;

  Future<List<dynamic>> fetchPage(int page, int pageSize);

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final newItems = await fetchPage(_page, _pageSize);
      
      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _hasMore = newItems.length == _pageSize;
          _page++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      onLoadError(e);
    }
  }

  Future<void> refresh() async {
    setState(() {
      _items = [];
      _page = 0;
      _hasMore = true;
    });
    await loadMore();
  }

  void onLoadError(dynamic error) {
    debugPrint('加载错误: $error');
  }
}

/// 虚拟化列表包装器
class VirtualizedList<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final double itemExtent;
  final EdgeInsetsGeometry? padding;
  final ScrollController? controller;

  const VirtualizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemExtent,
    this.padding,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: items.length,
      itemExtent: itemExtent,
      itemBuilder: (context, index) => itemBuilder(context, items[index], index),
    );
  }
}