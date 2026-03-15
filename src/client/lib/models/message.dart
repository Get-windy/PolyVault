/// 消息类型枚举
enum MessageType {
  system,
  security,
  sync,
  backup,
  general,
}

/// 消息模型
class Message {
  final String id;
  final String title;
  final String content;
  final MessageType type;
  final String? category;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const Message({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.category,
    this.isRead = false,
    required this.createdAt,
    this.metadata,
  });

  /// 从JSON创建消息对象
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.general,
      ),
      category: json['category'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.name,
      'category': category,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// 创建副本并修改字段
  Message copyWith({
    String? id,
    String? title,
    String? content,
    MessageType? type,
    String? category,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      category: category ?? this.category,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Message(id: $id, title: $title, type: $type, isRead: $isRead)';
  }
}

/// 消息统计
class MessageStats {
  final int total;
  final int unread;
  final int system;
  final int security;

  const MessageStats({
    required this.total,
    required this.unread,
    required this.system,
    required this.security,
  });

  factory MessageStats.fromJson(Map<String, dynamic> json) {
    return MessageStats(
      total: json['total'] as int,
      unread: json['unread'] as int,
      system: json['system'] as int,
      security: json['security'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'unread': unread,
      'system': system,
      'security': security,
    };
  }
}
