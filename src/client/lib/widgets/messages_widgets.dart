import 'package:flutter/material.dart';
import '../models/message.dart';

/// 消息列表项
class MessageListItem extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const MessageListItem({
    super.key,
    required this.message,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !message.isRead;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isUnread ? 2 : 0,
      color: isUnread 
          ? theme.colorScheme.primaryContainer.withOpacity(0.3) 
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 消息类型图标
              _buildMessageIcon(message.type),
              const SizedBox(width: 12),
              
              // 消息内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // 未读标记
                        if (isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // 消息内容
                    Text(
                      message.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isUnread
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 时间戳
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(message.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        // 分类标签
                        if (message.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message.category!,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageIcon(MessageType type) {
    IconData icon;
    Color color;

    switch (type) {
      case MessageType.security:
        icon = Icons.security;
        color = Colors.orange;
      case MessageType.system:
        icon = Icons.info;
        color = Colors.blue;
      case MessageType.device:
        icon = Icons.devices;
        color = Colors.green;
      case MessageType.credential:
        icon = Icons.vpn_key;
        color = Colors.purple;
      case MessageType.sync:
        icon = Icons.sync;
        color = Colors.teal;
      case MessageType.backup:
        icon = Icons.backup;
        color = Colors.indigo;
      case MessageType.general:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    
    return '${dateTime.month}月${dateTime.day}日';
  }
}

/// 消息筛选器
class MessageFilterChips extends StatelessWidget {
  final MessageType? selectedType;
  final ValueChanged<MessageType?> onTypeSelected;

  const MessageFilterChips({
    super.key,
    this.selectedType,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildChip(context, null, '全部'),
          const SizedBox(width: 8),
          _buildChip(context, MessageType.security, '安全'),
          const SizedBox(width: 8),
          _buildChip(context, MessageType.system, '系统'),
          const SizedBox(width: 8),
          _buildChip(context, MessageType.device, '设备'),
          const SizedBox(width: 8),
          _buildChip(context, MessageType.credential, '凭证'),
          const SizedBox(width: 8),
          _buildChip(context, MessageType.sync, '同步'),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, MessageType? type, String label) {
    final isSelected = selectedType == type;
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTypeSelected(type),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
    );
  }
}

/// 消息统计卡片
class MessageStatsCard extends StatelessWidget {
  final MessageStats stats;

  const MessageStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              context,
              Icons.inbox,
              stats.total.toString(),
              '总消息',
              theme.colorScheme.primary,
            ),
            _buildStatItem(
              context,
              Icons.mark_email_unread,
              stats.unread.toString(),
              '未读',
              Colors.orange,
            ),
            _buildStatItem(
              context,
              Icons.security,
              stats.security.toString(),
              '安全',
              Colors.red,
            ),
            _buildStatItem(
              context,
              Icons.info,
              stats.system.toString(),
              '系统',
              Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 消息为空状态
class MessageEmptyState extends StatelessWidget {
  final String? message;
  final IconData? icon;

  const MessageEmptyState({
    super.key,
    this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon ?? Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message ?? '暂无消息',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '有新消息时会在这里显示',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// 消息操作按钮
class MessageActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const MessageActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: color),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// 消息底部操作栏
class MessageActionBar extends StatelessWidget {
  final List<Message> selectedMessages;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onArchive;

  const MessageActionBar({
    super.key,
    required this.selectedMessages,
    this.onDelete,
    this.onMarkRead,
    this.onMarkUnread,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Text(
              '${selectedMessages.length} 条已选择',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            if (onMarkRead != null)
              MessageActionButton(
                icon: Icons.mark_email_read,
                label: '已读',
                onPressed: onMarkRead!,
              ),
            if (onMarkUnread != null)
              MessageActionButton(
                icon: Icons.mark_email_unread,
                label: '未读',
                onPressed: onMarkUnread!,
              ),
            if (onArchive != null)
              MessageActionButton(
                icon: Icons.archive,
                label: '归档',
                onPressed: onArchive!,
              ),
            if (onDelete != null)
              MessageActionButton(
                icon: Icons.delete,
                label: '删除',
                color: theme.colorScheme.error,
                onPressed: onDelete!,
              ),
          ],
        ),
      ),
    );
  }
}