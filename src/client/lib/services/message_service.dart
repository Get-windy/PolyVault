import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';

/// 消息服务
class MessageService {
  static MessageService? _instance;
  
  MessageService._();
  
  static MessageService getInstance() {
    _instance ??= MessageService._();
    return _instance!;
  }

  /// 获取消息列表
  Future<List<Message>> getMessages({
    MessageType? type,
    bool? unreadOnly,
    int? limit,
    int? offset,
  }) async {
    // TODO: 从API获取消息
    await Future.delayed(const Duration(milliseconds: 500));
    return _getMockMessages();
  }

  /// 获取消息详情
  Future<Message?> getMessage(String messageId) async {
    // TODO: 从API获取消息详情
    await Future.delayed(const Duration(milliseconds: 300));
    final messages = _getMockMessages();
    return messages.firstWhere((m) => m.id == messageId);
  }

  /// 标记消息为已读
  Future<void> markAsRead(String messageId) async {
    // TODO: 调用API标记已读
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 标记所有消息为已读
  Future<void> markAllAsRead() async {
    // TODO: 调用API标记全部已读
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// 删除消息
  Future<void> deleteMessage(String messageId) async {
    // TODO: 调用API删除消息
    await Future.delayed(const Duration(milliseconds: 200));
  }

  /// 获取未读消息数量
  Future<int> getUnreadCount() async {
    // TODO: 从API获取未读数量
    await Future.delayed(const Duration(milliseconds: 100));
    return 3;
  }

  /// 获取消息统计
  Future<MessageStats> getStats() async {
    // TODO: 从API获取统计
    await Future.delayed(const Duration(milliseconds: 200));
    return const MessageStats(
      total: 8,
      unread: 3,
      system: 3,
      security: 2,
    );
  }

  /// 订阅消息更新（用于实时推送）
  Stream<Message> subscribeToMessages() {
    // TODO: 实现WebSocket订阅
    return StreamController<Message>().stream;
  }

  List<Message> _getMockMessages() {
    return [
      Message(
        id: '1',
        title: '安全提醒',
        content: '检测到新设备尝试访问您的凭证。IP地址: 192.168.1.100，位置: 上海。如果这不是您本人的操作，请立即修改密码。',
        type: MessageType.security,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        metadata: {'ip': '192.168.1.100', 'location': '上海'},
      ),
      Message(
        id: '2',
        title: '凭证同步完成',
        content: '您的 GitHub 凭证已成功同步到所有已连接设备。同步时间: 2026-03-24 14:00',
        type: MessageType.sync,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        metadata: {'credential_name': 'GitHub', 'devices': 3},
      ),
      Message(
        id: '3',
        title: '设备已连接',
        content: 'iPhone 15 Pro 已成功连接到您的 PolyVault 账户。您可以在设备管理中查看或移除此设备。',
        type: MessageType.system,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        metadata: {'device_name': 'iPhone 15 Pro'},
      ),
      Message(
        id: '4',
        title: '自动备份完成',
        content: '您的数据已自动备份到云端。备份大小: 2.3MB，包含 45 个凭证。下次备份时间: 明天 02:00',
        type: MessageType.backup,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        metadata: {'backup_size': '2.3MB', 'credentials': 45},
      ),
      Message(
        id: '5',
        title: '密码泄露预警',
        content: '检测到您的 Gmail 账户密码可能已在数据泄露中出现。建议您立即更改密码。',
        type: MessageType.security,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        metadata: {'credential_name': 'Gmail', 'breach_source': '已知数据库泄露'},
      ),
      Message(
        id: '6',
        title: '系统更新',
        content: 'PolyVault 已更新到 v2.1.0 版本。新功能: 生物识别登录、自动填充增强、性能优化。',
        type: MessageType.system,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {'version': 'v2.1.0'},
      ),
    ];
  }
}

/// 消息服务 Provider
final messageServiceProvider = Provider<MessageService>((ref) {
  return MessageService.getInstance();
});