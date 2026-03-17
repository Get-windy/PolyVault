import 'package:flutter/material.dart';

/// 通知类型枚举
enum NotificationType {
  system,
  security,
  device,
  message,
  backup,
  sync,
}

/// 通知数据模型
class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? actionText;
  final VoidCallback? onAction;
  final Map<String, dynamic>? metadata;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.actionText,
    this.onAction,
    this.metadata,
  });

  NotificationModel copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? actionText,
    VoidCallback? onAction,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionText: actionText ?? this.actionText,
      onAction: onAction ?? this.onAction,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 通知卡片组件
class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !notification.isRead;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
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
        color: isUnread
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surface,
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
                NotificationIcon(
                  type: notification.type,
                  isUnread: isUnread,
                ),
                const SizedBox(width: 12),
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme, isUnread),
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
                      if (notification.actionText != null) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: onAction,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(notification.actionText!),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildTimestamp(theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isUnread) {
    return Row(
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
    );
  }

  Widget _buildTimestamp(ThemeData theme) {
    return Text(
      _formatTimestamp(notification.timestamp),
      style: TextStyle(
        color: theme.colorScheme.outline,
        fontSize: 12,
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
class NotificationIcon extends StatelessWidget {
  final NotificationType type;
  final bool isUnread;
  final double size;

  const NotificationIcon({
    super.key,
    required this.type,
    this.isUnread = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _getIconAndColor();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(isUnread ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }

  (IconData, Color) _getIconAndColor() {
    return switch (type) {
      NotificationType.security => (Icons.security, Colors.orange),
      NotificationType.device => (Icons.devices, Colors.blue),
      NotificationType.system => (Icons.info, Colors.grey),
      NotificationType.message => (Icons.message, Colors.green),
      NotificationType.backup => (Icons.backup, Colors.purple),
      NotificationType.sync => (Icons.sync, Colors.teal),
    };
  }
}

/// 时间显示组件
class NotificationTime extends StatelessWidget {
  final DateTime timestamp;
  final bool fullFormat;

  const NotificationTime({
    super.key,
    required this.timestamp,
    this.fullFormat = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = fullFormat ? _formatFull() : _formatRelative();

    return Text(
      text,
      style: TextStyle(
        color: theme.colorScheme.outline,
        fontSize: 12,
      ),
    );
  }

  String _formatRelative() {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '${weeks}周前';
    } else {
      return '${timestamp.month}月${timestamp.day}日';
    }
  }

  String _formatFull() {
    final months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '${timestamp.year}年${months[timestamp.month - 1]}${timestamp.day}日 $hour:$minute';
  }
}

/// 通知操作按钮组件
class NotificationActions extends StatelessWidget {
  final List<NotificationAction> actions;
  final bool compact;

  const NotificationActions({
    super.key,
    required this.actions,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: actions.map((action) => _buildButton(context, action)).toList(),
      );
    }

    return Row(
      children: actions.map((action) => Expanded(child: _buildButton(context, action))).toList(),
    );
  }

  Widget _buildButton(BuildContext context, NotificationAction action) {
    if (action.isPrimary) {
      return FilledButton.icon(
        onPressed: action.onPressed,
        icon: Icon(action.icon),
        label: Text(action.label),
      );
    }

    return OutlinedButton.icon(
      onPressed: action.onPressed,
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }
}

/// 单个通知操作
class NotificationAction {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  const NotificationAction({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
  });
}

/// 通知徽章组件
class NotificationBadge extends StatelessWidget {
  final int count;
  final bool showZero;
  final double size;

  const NotificationBadge({
    super.key,
    required this.count,
    this.showZero = false,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0 && !showZero) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: count > 99 ? 4 : 2, vertical: 2),
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onError,
          fontSize: size * 0.65,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 通知列表组件
class NotificationList extends StatelessWidget {
  final List<NotificationModel> notifications;
  final void Function(NotificationModel)? onTap;
  final void Function(String id)? onDismiss;
  final bool showDividers;

  const NotificationList({
    super.key,
    required this.notifications,
    this.onTap,
    this.onDismiss,
    this.showDividers = false,
  });

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return const _EmptyNotificationView();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Column(
          children: [
            NotificationCard(
              notification: notification,
              onTap: () => onTap?.call(notification),
              onDismiss: () => onDismiss?.call(notification.id),
            ),
            if (showDividers && index < notifications.length - 1)
              Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
              ),
          ],
        );
      },
    );
  }
}

/// 空状态视图
class _EmptyNotificationView extends StatelessWidget {
  const _EmptyNotificationView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无通知',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '有新消息时会在这里显示',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 通知分组标题组件
class NotificationSectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const NotificationSectionHeader({
    super.key,
    required this.title,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}