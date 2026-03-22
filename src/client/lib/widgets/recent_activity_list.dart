import 'package:flutter/material.dart';

/// 活动记录数据模型
class ActivityRecord {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final DateTime timestamp;
  final ActivityType type;

  const ActivityRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    required this.timestamp,
    required this.type,
  });

  String get relativeTime {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${timestamp.month}-${timestamp.day}';
  }
}

/// 活动类型枚举
enum ActivityType {
  credentialAccess,
  credentialCreate,
  credentialUpdate,
  credentialDelete,
  deviceConnect,
  deviceDisconnect,
  syncComplete,
  backupCreate,
  securityEvent,
}

/// 最近活动列表 - 首页活动记录展示
class RecentActivityList extends StatelessWidget {
  final List<ActivityRecord>? activities;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final void Function(ActivityRecord)? onActivityTap;

  const RecentActivityList({
    super.key,
    this.activities,
    this.isLoading = false,
    this.onViewAll,
    this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (activities == null || activities!.isEmpty) {
      return _buildEmptyState(theme);
    }

    return Column(
      children: [
        ...activities!.take(5).map((activity) => _ActivityItem(
              activity: activity,
              onTap: () => onActivityTap?.call(activity),
            )),
        if (activities!.length > 5 && onViewAll != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextButton(
              onPressed: onViewAll,
              child: Text('查看全部 ${activities!.length} 条记录'),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            '暂无活动记录',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final ActivityRecord activity;
  final VoidCallback? onTap;

  const _ActivityItem({
    required this.activity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = activity.iconColor ?? _getDefaultColor();

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          activity.icon,
          size: 20,
          color: iconColor,
        ),
      ),
      title: Text(
        activity.title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        activity.description,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        activity.relativeTime,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.outline,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Color _getDefaultColor() {
    return switch (activity.type) {
      ActivityType.credentialAccess => Colors.blue,
      ActivityType.credentialCreate => Colors.green,
      ActivityType.credentialUpdate => Colors.orange,
      ActivityType.credentialDelete => Colors.red,
      ActivityType.deviceConnect => Colors.teal,
      ActivityType.deviceDisconnect => Colors.grey,
      ActivityType.syncComplete => Colors.purple,
      ActivityType.backupCreate => Colors.indigo,
      ActivityType.securityEvent => Colors.amber,
    };
  }
}

/// 活动详情卡片
class ActivityDetailCard extends StatelessWidget {
  final ActivityRecord activity;
  final VoidCallback? onClose;

  const ActivityDetailCard({
    super.key,
    required this.activity,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    activity.icon,
                    color: _getColor(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        activity.relativeTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              activity.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 4),
                Text(
                  '${activity.timestamp.year}-${activity.timestamp.month.toString().padLeft(2, '0')}-${activity.timestamp.day.toString().padLeft(2, '0')} '
                  '${activity.timestamp.hour.toString().padLeft(2, '0')}:${activity.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor() {
    return activity.iconColor ?? switch (activity.type) {
      ActivityType.credentialAccess => Colors.blue,
      ActivityType.credentialCreate => Colors.green,
      ActivityType.credentialUpdate => Colors.orange,
      ActivityType.credentialDelete => Colors.red,
      ActivityType.deviceConnect => Colors.teal,
      ActivityType.deviceDisconnect => Colors.grey,
      ActivityType.syncComplete => Colors.purple,
      ActivityType.backupCreate => Colors.indigo,
      ActivityType.securityEvent => Colors.amber,
    };
  }
}