import '../models/message.dart';

/// 消息服务
class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  // 模拟消息数据
  final List<Message> _mockMessages = [
    Message(
      id: '1',
      title: '备份完成',
      content: '您的凭证数据已成功备份到云端，备份时间：2024-03-15 10:30',
      type: MessageType.backup,
      category: '备份',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Message(
      id: '2',
      title: '安全提醒',
      content: '检测到新的登录设备，请确认是否为您的设备。如果这不是您的操作，请立即修改密码。',
      type: MessageType.security,
      category: '安全',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Message(
      id: '3',
      title: '同步成功',
      content: '您的凭证数据已成功同步到所有设备，共同步 12 个凭证。',
      type: MessageType.sync,
      category: '同步',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Message(
      id: '4',
      title: '系统更新',
      content: 'PolyVault 已更新到 v2.1.0 版本，新增生物识别解锁功能。',
      type: MessageType.system,
      category: '系统',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Message(
      id: '5',
      title: '密码过期提醒',
      content: '您的 Google 账号密码已使用 90 天，建议定期更换密码以保证账户安全。',
      type: MessageType.security,
      category: '安全',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  /// 获取消息列表
  Future<List<Message>> getMessages() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 按时间倒序排列
    return _mockMessages..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 获取未读消息数量
  Future<int> getUnreadCount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockMessages.where((m) => !m.isRead).length;
  }

  /// 获取消息统计
  Future<MessageStats> getMessageStats() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    return MessageStats(
      total: _mockMessages.length,
      unread: _mockMessages.where((m) => !m.isRead).length,
      system: _mockMessages.where((m) => m.type == MessageType.system).length,
      security: _mockMessages.where((m) => m.type == MessageType.security).length,
    );
  }

  /// 标记消息为已读
  Future<void> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final index = _mockMessages.indexWhere((m) => m.id == id);
    if (index != -1) {
      _mockMessages[index] = _mockMessages[index].copyWith(isRead: true);
    }
  }

  /// 标记所有消息为已读
  Future<void> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    for (var i = 0; i < _mockMessages.length; i++) {
      if (!_mockMessages[i].isRead) {
        _mockMessages[i] = _mockMessages[i].copyWith(isRead: true);
      }
    }
  }

  /// 删除消息
  Future<void> deleteMessage(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _mockMessages.removeWhere((m) => m.id == id);
  }

  /// 清空所有消息
  Future<void> clearAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockMessages.clear();
  }

  /// 发送测试消息（用于开发调试）
  Future<void> sendTestMessage() async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    _mockMessages.insert(0, Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '测试消息',
      content: '这是一条测试消息，用于验证消息系统功能。',
      type: MessageType.general,
      isRead: false,
      createdAt: DateTime.now(),
    ));
  }
}
