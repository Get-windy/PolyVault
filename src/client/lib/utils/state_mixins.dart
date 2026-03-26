import 'package:flutter/material.dart';

/// 加载状态混入
/// 为StatefulWidget提供统一的加载状态管理
mixin LoadingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isLoading = false;
  String? _loadingMessage;
  
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  
  void setLoading(bool loading, {String? message}) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        _loadingMessage = message;
      });
    }
  }
  
  /// 显示加载覆盖层
  Widget buildWithLoader(Widget child) {
    return Stack(
      children: [
        child,
        if (_isLoading) ...[
          ModalBarrier(color: Colors.black.withOpacity(0.3), dismissible: false),
          Center(child: _buildLoadingIndicator()),
        ],
      ],
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (_loadingMessage != null) ...[
            const SizedBox(height: 16),
            Text(_loadingMessage!),
          ],
        ],
      ),
    );
  }
}

/// 错误状态混入
mixin ErrorStateMixin<T extends StatefulWidget> on State<T> {
  String? _errorMessage;
  
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  
  void setError(String? error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
      });
    }
  }
  
  void clearError() => setError(null);
  
  /// 构建错误显示
  Widget? buildErrorWidget() {
    if (!hasError) return null;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
            IconButton(icon: const Icon(Icons.close), onPressed: clearError),
          ],
        ),
      ),
    );
  }
}

/// 异步操作混入
mixin AsyncOperationMixin<T extends StatefulWidget> on State<T> {
  Future<void> runAsync(Future<void> Function() operation, {String? loadingMessage, void Function(String)? onError}) async {
    try {
      if (this is LoadingStateMixin) {
        (this as LoadingStateMixin).setLoading(true, message: loadingMessage);
      }
      await operation();
    } catch (e) {
      final errorMsg = e.toString();
      if (this is ErrorStateMixin) {
        (this as ErrorStateMixin).setError(errorMsg);
      }
      onError?.call(errorMsg);
    } finally {
      if (this is LoadingStateMixin) {
        (this as LoadingStateMixin).setLoading(false);
      }
    }
  }
}