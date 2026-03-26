/// 代码分割和按需加载工具
/// 提供延迟加载页面、组件预加载等功能
library code_splitting;

import 'package:flutter/material.dart';

/// 延迟加载页面包装器
class DeferredPage extends StatefulWidget {
  final Future<Widget> Function() pageLoader;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Duration minLoadTime;

  const DeferredPage({
    super.key,
    required this.pageLoader,
    this.loadingWidget,
    this.errorWidget,
    this.minLoadTime = Duration.zero,
  });

  @override
  State<DeferredPage> createState() => _DeferredPageState();
}

class _DeferredPageState extends State<DeferredPage> {
  Widget? _loadedPage;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final startTime = DateTime.now();

    try {
      final page = await widget.pageLoader();
      
      // 确保最小加载时间（防止闪烁）
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < widget.minLoadTime) {
        await Future.delayed(widget.minLoadTime - elapsed);
      }

      if (mounted) {
        setState(() {
          _loadedPage = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return widget.errorWidget ?? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            const Text('加载失败'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _loadPage();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return _loadedPage!;
  }
}

/// 页面预加载器
class PagePreloader {
  static final PagePreloader _instance = PagePreloader._();
  factory PagePreloader() => _instance;
  PagePreloader._();

  final Map<String, Widget> _preloadedPages = {};
  final Set<String> _preloading = {};

  /// 预加载页面
  Future<void> preload(String key, Widget Function() pageBuilder) async {
    if (_preloadedPages.containsKey(key) || _preloading.contains(key)) return;

    _preloading.add(key);
    try {
      // 简化的预加载逻辑
      final page = pageBuilder();
      _preloadedPages[key] = page;
    } finally {
      _preloading.remove(key);
    }
  }

  /// 获取预加载的页面
  Widget? getPreloaded(String key) => _preloadedPages[key];

  /// 清除预加载缓存
  void clear(String? key) {
    if (key != null) {
      _preloadedPages.remove(key);
    } else {
      _preloadedPages.clear();
    }
  }
}

/// 组件延迟加载混入
mixin DeferredLoadMixin<T extends StatefulWidget> on State<T> {
  final Map<String, Widget> _deferredWidgets = {};
  final Set<String> _loading = {};

  /// 延迟加载组件
  Future<Widget?> loadDeferred(
    String key,
    Future<Widget> Function() loader,
  ) async {
    if (_deferredWidgets.containsKey(key)) {
      return _deferWidgets[key];
    }

    if (_loading.contains(key)) return null;

    _loading.add(key);
    try {
      final widget = await loader();
      _deferredWidgets[key] = widget;
      
      if (mounted) {
        setState(() {});
      }
      
      return widget;
    } finally {
      _loading.remove(key);
    }
  }

  /// 获取已加载的组件
  Widget? getDeferred(String key) => _deferredWidgets[key];

  /// 检查是否正在加载
  bool isLoading(String key) => _loading.contains(key);
}

/// 懒加载导航
class LazyNavigator {
  final Map<String, WidgetBuilder> _routes;
  final Map<String, Widget> _routeCache = {};

  LazyNavigator(this._routes);

  /// 获取路由页面
  Widget getRoute(String routeName) {
    if (_routeCache.containsKey(routeName)) {
      return _routeCache[routeName]!;
    }

    final builder = _routes[routeName];
    if (builder == null) {
      throw ArgumentError('Unknown route: $routeName');
    }

    final page = builder(null as BuildContext);
    _routeCache[routeName] = page;
    return page;
  }

  /// 预加载路由
  void preloadRoute(String routeName) {
    if (!_routeCache.containsKey(routeName) && _routes.containsKey(routeName)) {
      _routeCache[routeName] = _routes[routeName]!(null as BuildContext);
    }
  }

  /// 清除缓存
  void clearCache({String? routeName}) {
    if (routeName != null) {
      _routeCache.remove(routeName);
    } else {
      _routeCache.clear();
    }
  }
}

/// 条件渲染组件
class ConditionalRender extends StatelessWidget {
  final bool condition;
  final Widget Function() builder;
  final Widget Function()? fallback;

  const ConditionalRender({
    super.key,
    required this.condition,
    required this.builder,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return builder();
    }
    return fallback?.call() ?? const SizedBox.shrink();
  }
}

/// 分步加载组件
class StagedLoader extends StatefulWidget {
  final List<Widget> stages;
  final Duration stageDelay;
  final Widget? loadingWidget;

  const StagedLoader({
    super.key,
    required this.stages,
    this.stageDelay = const Duration(milliseconds: 100),
    this.loadingWidget,
  });

  @override
  State<StagedLoader> createState() => _StagedLoaderState();
}

class _StagedLoaderState extends State<StagedLoader> {
  int _loadedStages = 0;

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  Future<void> _loadStages() async {
    for (int i = 0; i < widget.stages.length; i++) {
      if (!mounted) break;
      
      await Future.delayed(widget.stageDelay);
      
      if (mounted) {
        setState(() => _loadedStages = i + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < _loadedStages && i < widget.stages.length; i++)
          widget.stages[i],
        if (_loadedStages < widget.stages.length)
          widget.loadingWidget ?? const CircularProgressIndicator(),
      ],
    );
  }
}

/// 动态导入模拟
class DynamicImport<T> {
  final Future<T> Function() _loader;
  T? _cached;
  bool _isLoading = false;

  DynamicImport(this._loader);

  Future<T?> load() async {
    if (_cached != null) return _cached;
    if (_isLoading) return null;

    _isLoading = true;
    try {
      _cached = await _loader();
      return _cached;
    } finally {
      _isLoading = false;
    }
  }

  T? get cached => _cached;
  bool get isLoaded => _cached != null;
  bool get isLoading => _isLoading;

  void invalidate() => _cached = null;
}

/// 懒加载包装器
class LazyBuilder extends StatefulWidget {
  final Widget Function() builder;
  final Duration delay;

  const LazyBuilder({
    super.key,
    required this.builder,
    this.delay = Duration.zero,
  });

  @override
  State<LazyBuilder> createState() => _LazyBuilderState();
}

class _LazyBuilderState extends State<LazyBuilder> {
  Widget? _built;
  bool _isBuilding = false;

  @override
  void initState() {
    super.initState();
    _build();
  }

  Future<void> _build() async {
    if (widget.delay > Duration.zero) {
      await Future.delayed(widget.delay);
    }

    if (mounted && !_isBuilding) {
      _isBuilding = true;
      setState(() {
        _built = widget.builder();
        _isBuilding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _built ?? const SizedBox.shrink();
  }
}