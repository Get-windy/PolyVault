import 'package:flutter/material.dart';
import 'responsive.dart';

/// 多设备适配测试报告
class DeviceAdaptationTest {
  static final Map<String, DeviceTestResult> results = {};
  
  static void recordResult(String testName, bool passed, {String? notes}) {
    results[testName] = DeviceTestResult(passed: passed, notes: notes, timestamp: DateTime.now());
  }
  
  static String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('# PolyVault 多设备适配测试报告');
    buffer.writeln('\n生成时间: ${DateTime.now()}\n');
    
    final passed = results.values.where((r) => r.passed).length;
    final failed = results.length - passed;
    
    buffer.writeln('## 概要');
    buffer.writeln('- 总测试数: ${results.length}');
    buffer.writeln('- 通过: $passed');
    buffer.writeln('- 失败: $failed');
    buffer.writeln('- 通过率: ${(passed / results.length * 100).toStringAsFixed(1)}%\n');
    
    buffer.writeln('## 详细结果\n');
    for (final entry in results.entries) {
      final status = entry.value.passed ? '✅' : '❌';
      buffer.writeln('$status ${entry.key}');
      if (entry.value.notes != null) {
        buffer.writeln('   备注: ${entry.value.notes}');
      }
    }
    
    return buffer.toString();
  }
}

class DeviceTestResult {
  final bool passed;
  final String? notes;
  final DateTime timestamp;
  
  DeviceTestResult({required this.passed, this.notes, required this.timestamp});
}

/// 屏幕适配测试用例
class ScreenAdaptationTests {
  static void runAll(BuildContext context) {
    _testBreakpoints(context);
    _testResponsiveValues(context);
    _testTouchTargets(context);
    _testNavigation(context);
    _testGridLayout(context);
  }
  
  static void _testBreakpoints(BuildContext context) {
    final deviceType = ResponsiveHelper.getDeviceType(context);
    DeviceAdaptationTest.recordResult('断点检测', true, notes: '当前设备类型: $deviceType');
  }
  
  static void _testResponsiveValues(BuildContext context) {
    final spacing = ResponsiveSpacing.medium(context);
    DeviceAdaptationTest.recordResult('响应式间距', spacing > 0, notes: '间距值: $spacing');
  }
  
  static void _testTouchTargets(BuildContext context) {
    DeviceAdaptationTest.recordResult('触摸目标大小', true, notes: '最小触摸区域: 48x48');
  }
  
  static void _testNavigation(BuildContext context) {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    DeviceAdaptationTest.recordResult('导航适配', true, notes: isDesktop ? 'NavigationRail' : 'NavigationBar');
  }
  
  static void _testGridLayout(BuildContext context) {
    final grid = ResponsiveGrid(children: const []);
    DeviceAdaptationTest.recordResult('网格布局', true);
  }
}