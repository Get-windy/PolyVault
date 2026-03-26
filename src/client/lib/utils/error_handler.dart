/// 错误处理服务
/// 提供统一的错误捕获、转换和用户友好提示
library error_handler;

import 'dart:io';
import 'package:flutter/material.dart';

/// 应用错误类型
enum AppErrorType {
  network,        // 网络错误
  server,         // 服务器错误
  authentication, // 认证错误
  authorization,  // 授权错误
  validation,     // 验证错误
  storage,        // 存储错误
  encryption,     // 加密错误
  biometric,      // 生物识别错误
  timeout,        // 超时错误
  unknown,        // 未知错误
}

/// 应用错误
class AppError implements Exception {
  final String message;
  final String? technicalMessage;
  final AppErrorType type;
  final int? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    this.technicalMessage,
    required this.type,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  factory AppError.fromException(dynamic error, [StackTrace? stackTrace]) {
    // 网络错误
    if (error is SocketException) {
      return AppError(
        message: '网络连接失败，请检查网络设置',
        technicalMessage: error.message,
        type: AppErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (error is HttpException) {
      return AppError(
        message: '网络请求失败',
        technicalMessage: error.message,
        type: AppErrorType.network,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 超时错误
    if (error is TimeoutException || error.toString().contains('Timeout')) {
      return AppError(
        message: '请求超时，请稍后重试',
        technicalMessage: error.toString(),
        type: AppErrorType.timeout,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 格式化错误消息
    if (error is FormatException) {
      return AppError(
        message: '数据格式错误',
        technicalMessage: error.message,
        type: AppErrorType.validation,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 参数错误
    if (error is ArgumentError) {
      return AppError(
        message: '参数错误',
        technicalMessage: error.toString(),
        type: AppErrorType.validation,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 认证错误
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('unauthorized') || errorStr.contains('401')) {
      return AppError(
        message: '身份验证失败，请重新登录',
        type: AppErrorType.authentication,
        code: 401,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorStr.contains('forbidden') || errorStr.contains('403')) {
      return AppError(
        message: '没有权限执行此操作',
        type: AppErrorType.authorization,
        code: 403,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorStr.contains('not found') || errorStr.contains('404')) {
      return AppError(
        message: '请求的资源不存在',
        type: AppErrorType.server,
        code: 404,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (errorStr.contains('server') || errorStr.contains('500')) {
      return AppError(
        message: '服务器错误，请稍后重试',
        type: AppErrorType.server,
        code: 500,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 生物识别错误
    if (errorStr.contains('biometric') || errorStr.contains('fingerprint')) {
      return AppError(
        message: '生物识别验证失败',
        technicalMessage: error.toString(),
        type: AppErrorType.biometric,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 加密错误
    if (errorStr.contains('encryption') || errorStr.contains('decrypt')) {
      return AppError(
        message: '数据加密/解密失败',
        technicalMessage: error.toString(),
        type: AppErrorType.encryption,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 存储错误
    if (errorStr.contains('storage') || errorStr.contains('write')) {
      return AppError(
        message: '数据存储失败',
        technicalMessage: error.toString(),
        type: AppErrorType.storage,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    // 默认未知错误
    return AppError(
      message: '发生未知错误，请稍后重试',
      technicalMessage: error.toString(),
      type: AppErrorType.unknown,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  @override
  String toString() => 'AppError: $message (${type.name})';
}

/// 错误处理器
class ErrorHandler {
  ErrorHandler._();

  /// 获取用户友好的错误消息
  static String getUserMessage(dynamic error) {
    if (error is AppError) {
      return error.message;
    }
    return AppError.fromException(error).message;
  }

  /// 获取错误类型图标
  static IconData getErrorIcon(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return Icons.wifi_off;
      case AppErrorType.server:
        return Icons.cloud_off;
      case AppErrorType.authentication:
        return Icons.lock_outline;
      case AppErrorType.authorization:
        return Icons.no_accounts;
      case AppErrorType.validation:
        return Icons.error_outline;
      case AppErrorType.storage:
        return Icons.save_alt;
      case AppErrorType.encryption:
        return Icons.enhanced_encryption;
      case AppErrorType.biometric:
        return Icons.fingerprint;
      case AppErrorType.timeout:
        return Icons.timer_off;
      case AppErrorType.unknown:
        return Icons.help_outline;
    }
  }

  /// 获取错误颜色
  static Color getErrorColor(AppErrorType type, ColorScheme colorScheme) {
    switch (type) {
      case AppErrorType.network:
      case AppErrorType.server:
      case AppErrorType.timeout:
        return Colors.orange;
      case AppErrorType.authentication:
      case AppErrorType.authorization:
      case AppErrorType.encryption:
        return colorScheme.error;
      case AppErrorType.validation:
        return Colors.amber;
      case AppErrorType.storage:
        return Colors.blueGrey;
      case AppErrorType.biometric:
        return Colors.purple;
      case AppErrorType.unknown:
        return colorScheme.onSurfaceVariant;
    }
  }

  /// 获取重试建议
  static String getRetrySuggestion(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
        return '请检查网络连接后重试';
      case AppErrorType.server:
        return '服务器暂时不可用，请稍后重试';
      case AppErrorType.authentication:
        return '请检查登录凭证后重试';
      case AppErrorType.authorization:
        return '如需权限，请联系管理员';
      case AppErrorType.validation:
        return '请检查输入信息是否正确';
      case AppErrorType.storage:
        return '请检查存储空间是否充足';
      case AppErrorType.encryption:
        return '请检查密钥是否正确';
      case AppErrorType.biometric:
        return '请确认设备支持生物识别功能';
      case AppErrorType.timeout:
        return '网络响应较慢，请稍后重试';
      case AppErrorType.unknown:
        return '如果问题持续，请联系支持';
    }
  }

  /// 判断是否可重试
  static bool isRetryable(AppErrorType type) {
    switch (type) {
      case AppErrorType.network:
      case AppErrorType.server:
      case AppErrorType.timeout:
        return true;
      case AppErrorType.authentication:
      case AppErrorType.authorization:
      case AppErrorType.validation:
      case AppErrorType.storage:
      case AppErrorType.encryption:
      case AppErrorType.biometric:
      case AppErrorType.unknown:
        return false;
    }
  }
}

/// 错误显示组件
mixin ErrorDisplayMixin<T extends StatefulWidget> on State<T> {
  /// 显示错误Snackbar
  void showErrorSnackBar(
    dynamic error, {
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onRetry,
  }) {
    final appError = error is AppError 
        ? error 
        : AppError.fromException(error);
    
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              ErrorHandler.getErrorIcon(appError.type),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    appError.message,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (appError.technicalMessage != null)
                    Text(
                      appError.technicalMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: ErrorHandler.getErrorColor(appError.type, colorScheme),
        duration: duration,
        action: onRetry != null && ErrorHandler.isRetryable(appError.type)
            ? SnackBarAction(
                label: '重试',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }

  /// 显示错误对话框
  Future<void> showErrorDialog(
    dynamic error, {
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) async {
    final appError = error is AppError 
        ? error 
        : AppError.fromException(error);
    
    final colorScheme = Theme.of(context).colorScheme;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          ErrorHandler.getErrorIcon(appError.type),
          color: ErrorHandler.getErrorColor(appError.type, colorScheme),
          size: 48,
        ),
        title: Text(appError.message),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ErrorHandler.getRetrySuggestion(appError.type),
              textAlign: TextAlign.center,
            ),
            if (appError.technicalMessage != null) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('技术详情'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      appError.technicalMessage!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null && ErrorHandler.isRetryable(appError.type))
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('重试'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDismiss?.call();
            },
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  /// 显示成功Snackbar
  void showSuccessSnackBar(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// 异步操作结果封装
class AsyncResult<T> {
  final T? data;
  final AppError? error;
  final bool isLoading;

  const AsyncResult.loading()
      : data = null,
        error = null,
        isLoading = true;

  const AsyncResult.success(this.data)
      : error = null,
        isLoading = false;

  const AsyncResult.error(this.error)
      : data = null,
        isLoading = false;

  bool get isSuccess => data != null && error == null;
  bool get isError => error != null;

  /// 安全获取数据，如果出错则返回默认值
  T getOrElse(T defaultValue) => data ?? defaultValue;

  /// 转换数据
  AsyncResult<R> map<R>(R Function(T) mapper) {
    if (isLoading) return AsyncResult<R>.loading();
    if (error != null) return AsyncResult<R>.error(error);
    return AsyncResult<R>.success(mapper(data as T));
  }
}