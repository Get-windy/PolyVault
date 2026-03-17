/**
 * PolyVault 性能测试
 * 测试消息列表、设备列表性能和内存使用
 */

import 'package:flutter/material.dart';
import '../models/message.dart';

// ============ 消息列表性能测试 ============

class MessageListPerformance {
  /// 模拟消息数据
  static List<Message> generateMessages(int count) {
    return List.generate(count, (index) {
      return Message(
        id: 'msg_$index',
        title: '消息标题 $index',
        content: '这是消息内容第 $index 条，包含一些文本内容用于测试滚动性能。' * 3,
        type: MessageType.values[index % MessageType.values.length],
        timestamp: DateTime.now().subtract(Duration(hours: index)),
        isRead: index % 3 == 0,
        senderId: 'sender_$index',
        senderName: '发送者 $index',
      );
    });
  }

  /// 测试 ListView.builder 性能
  /// 使用 builder 模式只渲染可见项目
  static Widget buildEfficientList(List<Message> messages) {
    return ListView.builder(
      itemCount: messages.length,
      // 缓存关键尺寸 - 提升滚动性能
      cacheExtent: 200,
      // 预估 item 高度
      itemExtent: 80,
      // 使用懒加载构建器
      itemBuilder: (context, index) {
        return _MessageTile(message: messages[index]);
      },
    );
  }

  /// 低效的 ListView - 不指定 itemExtent
  /// 这会导致每次滚动都要重新计算布局
  static Widget buildInefficientList(List<Message> messages) {
    return ListView.builder(
      itemCount: messages.length,
      // 没有 cacheExtent
      itemBuilder: (context, index) {
        return _MessageTile(message: messages[index]);
      },
    );
  }

  /// 使用 SliverList 的高效列表
  static Widget buildSliverList(List<Message> messages) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _MessageTile(message: messages[index]),
            childCount: messages.length,
          ),
        ),
      ],
    );
  }

  /// 使用 SliverFixedExtentList 的最优化列表
  static Widget buildOptimizedList(List<Message> messages) {
    return CustomScrollView(
      slivers: [
        SliverFixedExtentList(
          itemExtent: 80,
          delegate: SliverChildBuilderDelegate(
            (context, index) => _MessageTile(message: messages[index]),
            childCount: messages.length,
          ),
        ),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  final Message message;

  const _MessageTile({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUnread = !message.isRead;
    return ListTile(
      leading: CircleAvatar(
        child: Text(message.senderName[0]),
      ),
      title: Text(
        message.title,
        style: TextStyle(
          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        message.content,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isUnread
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

// ============ 设备列表性能测试 ============

class DeviceListPerformance {
  /// 设备数据模型
  static final List<Map<String, dynamic>> _mockDevices = List.generate(
    100,
    (index) => {
      'id': 'device_$index',
      'name': '设备 $index',
      'type': ['手机', '平板', '电脑'][index % 3],
      'platform': ['Android', 'iOS', 'Windows'][index % 3],
      'isConnected': index % 2 == 0,
      'lastSeen': DateTime.now().subtract(Duration(hours: index)),
    },
  );

  /// 获取设备列表
  static List<Map<String, dynamic>> getDevices() => _mockDevices;

  /// 高效的设备列表 - 使用 ListView.builder
  static Widget buildEfficientDeviceList() {
    final devices = _mockDevices;
    return ListView.builder(
      itemCount: devices.length,
      itemExtent: 72,
      cacheExtent: 100,
      itemBuilder: (context, index) {
        final device = devices[index];
        return ListTile(
          leading: Icon(
            device['isConnected'] ? Icons.phone_android : Icons.phone_android_outlined,
          ),
          title: Text(device['name']),
          subtitle: Text(device['platform']),
          trailing: device['isConnected']
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined, color: Colors.grey),
        );
      },
    );
  }

  /// 带筛选的高效列表
  static Widget buildFilteredList({bool? connected}) {
    final filtered = connected == null
        ? _mockDevices
        : _mockDevices.where((d) => d['isConnected'] == connected).toList();
    
    return ListView.builder(
      itemCount: filtered.length,
      itemExtent: 72,
      itemBuilder: (context, index) {
        final device = filtered[index];
        return ListTile(
          title: Text(device['name']),
        );
      },
    );
  }
}

// ============ 内存优化测试 ============

class MemoryOptimization {
  /// 图片缓存配置示例
  static ImageProvider getOptimizedImage(String url) {
    return ResizeImage(
      // 使用 resizeImage 减少内存占用
      NetworkImage(url),
      width: 200,
      height: 200,
    );
  }

  /// 延迟加载列表项
  static Widget buildLazyList() {
    return ListView.builder(
      itemCount: 1000,
      // 懒加载 - 只在接近视口时加载
      itemBuilder: (context, index) {
        // 使用 const 减少重建
        return const ListTile(
          title: Text('Item'),
        );
      },
    );
  }

  /// 避免在 build 中创建 Widget
  static final _cachedTile = const ListTile(
    title: Text('Cached'),
    subtitle: Text('This is cached'),
  );

  static Widget getCachedTile() => _cachedTile;
}

// ============ 性能基准测试 ============

class PerformanceBenchmark {
  /// 测试大量数据渲染时间
  static void benchmarkListRendering() {
    final stopwatch = Stopwatch()..start();
    
    final messages = MessageListPerformance.generateMessages(1000);
    
    stopwatch.stop();
    final generationTime = stopwatch.elapsedMilliseconds;
    
    print('生成1000条消息耗时: ${generationTime}ms');
    
    // 验证
    assert(generationTime < 100, '生成时间应小于100ms');
  }

  /// 测试筛选性能
  static void benchmarkFilter() {
    final devices = DeviceListPerformance.getDevices();
    
    final stopwatch = Stopwatch()..start();
    final filtered = devices.where((d) => d['isConnected'] == true).toList();
    stopwatch.stop();
    
    print('筛选设备耗时: ${stopwatch.elapsedMilliseconds}ms');
    print('筛选结果: ${filtered.length} 个设备');
  }

  /// 测试列表滚动平滑度建议
  static Map<String, dynamic> getScrollOptimizationTips() {
    return {
      'useListViewBuilder': true,
      'specifyItemExtent': true,
      'useCacheExtent': 200,
      'avoidAnimatedListForLargeData': true,
      'useSliverForComplexLists': true,
      'avoidRebuildInBuild': true,
      'useConstConstructors': true,
    };
  }
}

// ============ 测试用例 ============

void main() {
  print('=== PolyVault 性能测试 ===\n');
  
  // 测试消息生成
  print('1. 消息列表性能测试');
  final messages = MessageListPerformance.generateMessages(100);
  print('   - 生成了 ${messages.length} 条消息\n');
  
  // 测试设备筛选
  print('2. 设备列表性能测试');
  final devices = DeviceListPerformance.getDevices();
  print('   - 设备总数: ${devices.length}');
  final connected = devices.where((d) => d['isConnected'] == true).length;
  print('   - 在线设备: $connected\n');
  
  // 性能建议
  print('3. 性能优化建议');
  final tips = PerformanceBenchmark.getScrollOptimizationTips();
  tips.forEach((key, value) {
    print('   - $key: $value');
  });
  
  print('\n=== 测试完成 ===');
}