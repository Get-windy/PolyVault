import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Flutter性能监控
class FlutterPerformanceMonitor {
  static final FlutterPerformanceMonitor _instance = FlutterPerformanceMonitor._();
  factory FlutterPerformanceMonitor() => _instance;
  FlutterPerformanceMonitor._();

  final Map<String, _FrameTiming> _frameTimings = {};
  final Map<String, int> _operationCounts = {};
  final List<double> _fpsHistory = [];
  
  int _totalFrames = 0;
  int _droppedFrames = 0;
  DateTime _startTime = DateTime.now();

  void startMonitoring() {
    WidgetsBinding.instance.addTimingsCallback(_onTimings);
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _totalFrames++;
      final duration = timing.totalSpan.inMilliseconds;
      if (duration > 16) _droppedFrames++;
      _fpsHistory.add(1000 / duration);
    }
  }

  void recordOperation(String operation, int durationMs) {
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
    _frameTimings[operation] = _FrameTiming(
      count: (_frameTimings[operation]?.count ?? 0) + 1,
      totalMs: (_frameTimings[operation]?.totalMs ?? 0) + durationMs,
    );
  }

  double get fps => _fpsHistory.isEmpty ? 60 : _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
  int get droppedFrames => _droppedFrames;
  double get frameDropRate => _totalFrames > 0 ? _droppedFrames / _totalFrames : 0;

  Map<String, dynamic> getMetrics() => {
    'fps': fps.toStringAsFixed(1),
    'dropped_frames': _droppedFrames,
    'frame_drop_rate': (frameDropRate * 100).toStringAsFixed(2),
    'operations': _operationCounts,
    'uptime_seconds': DateTime.now().difference(_startTime).inSeconds,
  };
}

class _FrameTiming {
  final int count;
  final int totalMs;
  _FrameTiming({required this.count, required this.totalMs});
}

/// 资源监控
class ResourceMonitor {
  static final ResourceMonitor _instance = ResourceMonitor._();
  factory ResourceMonitor() => _instance;
  ResourceMonitor._();

  Map<String, dynamic> getUsage() {
    final memory = ProcessInfo.currentRss;
    return {
      'memory_mb': (memory / 1024 / 1024).toStringAsFixed(2),
      'platform': Platform.operatingSystem,
      'dart_version': Platform.version,
    };
  }
}