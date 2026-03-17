import 'package:flutter/material.dart';

/// 通知数据模型
enum NotificationType {
  system,      // 系统通知
  security,    // 安全通知
  device,      // 设备通知
  message,     // 消息通知
  backup,      // 备份通知
  sync,        // 同步通知
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 通知中心页面
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 通知数据
  final List<AppNotification> _notifications = [
    // 安全通知
    AppNotification(
      id: '1',
      type: NotificationType.security,
      title: '新设备登录',
      content: '您的账户在新设备(iPhone 15 Pro)上登录，如不是您本人操作，请立即更改密码。',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
    ),
    AppNotification(
      id: '2',
      type: NotificationType.security,
      title: '密码强度提醒',
      content: '您的主密码已使用超过90天，建议定期更换以确保安全。',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    // 系统通知
    AppNotification(
      id: '3',
      type: NotificationType.system,
      title: '系统更新可用',
      content: 'PolyVault v2.5.0 已发布，新版本包含多项改进和错误修复。',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
    // 设备通知
    AppNotification(
      id: '4',
      type: NotificationType.device,
      title: '设备同步完成',
      content: '您的数据已成功同步到 Windows PC (Chrome)。',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
    ),
    AppNotification(
      id: '5',
      type: NotificationType.device,
      title: '设备离线',
      content: '您的设备 MacBook Pro 已离线超过24小时。',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    // 备份通知
    AppNotification(
      id: '6',
      type: NotificationType.backup,
      title: '自动备份完成',
      content: '您的数据已于今天 03:00 自动备份到云端。',
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: true,
    ),
    // 同步通知
    AppNotification(
      id: '7',
      type: NotificationType.sync,
      title: '同步冲突',
      content: '检测到数据同步冲突，已自动保留最新版本。',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      isRead: false,
    ),
    // 更多系统通知
    AppNotification(
      id: '8',
      type: NotificationType.system,
      title: '安全公告',
      content: '我们已更新隐私政策，请查阅最新条款。',
      timestamp: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('全部已读'),
            ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'clear', child: Text('清除全部')),
              const PopupMenuItem(value: 'settings', child: Text('通知设置')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '全部 ($unreadCount)'),
            const Tab(text: '安全'),
            const Tab(text: '设备'),
            const Tab(text: '系统'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(_notifications),
          _buildNotificationList(_notifications.where((n) => n.type == NotificationType.security).toList()),
          _buildNotificationList(_notifications.where((n) => n.type == NotificationType.device).toList()),
          _buildNotificationList(_notifications.where((n) => n.type == NotificationType.system || n.type == NotificationType.backup || n.type == NotificationType.sync).toList()),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<AppNotification> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无通知',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () => _showNotificationDetail(notification),
          onDismiss: () => _deleteNotification(notification.id),
        );
      },
    );
  }

  void _showNotificationDetail(AppNotification notification) {
    // 标记为已读
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _NotificationDetailSheet(notification: notification),
    );
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已全部标记为已读')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        _showClearConfirmDialog();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/notification-settings');
        break;
    }
  }

  void _showClearConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除通知'),
        content: const Text('确定要清除所有通知吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

/// 通知卡片组件
class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        elevation: isUnread ? 2 : 0,
        color: isUnread ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isUnread
              ? BorderSide(color: theme.colorScheme.primary.withOpacity(0.3))
              : BorderSide.none,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 通知图标
                _NotificationIcon(type: notification.type, isUnread: isUnread),
                const SizedBox(width: 12),
                // 通知内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.content,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimestamp(notification.timestamp),
                        style: TextStyle(
                          color: theme.colorScheme.outline,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右箭头
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${timestamp.month}月${timestamp.day}日';
    }
  }
}

/// 通知图标组件
class _NotificationIcon extends StatelessWidget {
  final NotificationType type;
  final bool isUnread;

  const _NotificationIcon({
    required this.type,
    required this.isUnread,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      NotificationType.security => (Icons.security, Colors.orange),
      NotificationType.device => (Icons.devices, Colors.blue),
      NotificationType.system => (Icons.info, Colors.grey),
      NotificationType.message => (Icons.message, Colors.green),
      NotificationType.backup => (Icons.backup, Colors.purple),
      NotificationType.sync => (Icons.sync, Colors.teal),
    };

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(isUnread ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

/// 通知详情底部弹窗
class _NotificationDetailSheet extends StatelessWidget {
  final AppNotification notification;

  const _NotificationDetailSheet({required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 拖动手柄
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 内容
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // 标题
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 时间
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatFullTimestamp(notification.timestamp),
                          style: TextStyle(
                            color: theme.colorScheme.outline,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 内容
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 操作按钮
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // 查看相关
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('查看详情'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // 标记已读
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('知道了'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFullTimestamp(DateTime timestamp) {
    final months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.year}年${months[timestamp.month - 1]}${timestamp.day}日 $hour:$minute';
  }
}