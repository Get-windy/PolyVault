import 'package:flutter/material.dart';
import 'screen/backup_screen.dart';

/// 备份列表项组件
class BackupListItem extends StatelessWidget {
  final BackupItem backup;
  final VoidCallback? onRestore;
  final VoidCallback? onDelete;

  const BackupListItem({
    super.key,
    required this.backup,
    this.onRestore,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 头部
          Row(
            children: [
              // 类型图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(),
                  color: _getTypeColor(),
                ),
              ),
              const SizedBox(width: 12),
              
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      backup.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(backup.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 状态标签
              _buildStatusChip(context),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 底部信息
          Row(
            children: [
              // 大小
              Icon(Icons.storage, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                backup.formattedSize,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              
              // 类型
              Icon(Icons.category, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                backup.type == BackupType.full ? '完整备份' : '增量备份',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onRestore,
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('恢复'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, size: 18, color: Colors.red[400]),
                label: Text('删除', style: TextStyle(color: Colors.red[400])),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (backup.status) {
      case BackupStatus.completed:
        color = Colors.green;
        label = '已完成';
        icon = Icons.check_circle;
        break;
      case BackupStatus.pending:
        color = Colors.orange;
        label = '等待中';
        icon = Icons.pending;
        break;
      case BackupStatus.inProgress:
        color = Colors.blue;
        label = '进行中';
        icon = Icons.sync;
        break;
      case BackupStatus.failed:
        color = Colors.red;
        label = '失败';
        icon = Icons.error;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    return backup.type == BackupType.full ? Icons.backup : Icons.add_circle_outline;
  }

  Color _getTypeColor() {
    return backup.type == BackupType.full ? Colors.blue : Colors.orange;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}

/// 备份进度指示器
class BackupProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final bool showPercentage;

  const BackupProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(progress),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 百分比
          if (showPercentage)
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.orange;
    if (progress < 0.7) return Colors.blue;
    return Colors.green;
  }
}

/// 备份计划选择器
class BackupSchedulePicker extends StatelessWidget {
  final BackupSchedule value;
  final ValueChanged<BackupSchedule> onChanged;

  const BackupSchedulePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备份频率',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        
        // 频率选项
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: BackupSchedule.values.map((schedule) {
            final isSelected = value == schedule;
            return ChoiceChip(
              label: Text(schedule.label),
              selected: isSelected,
              onSelected: (_) => onChanged(schedule),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 12),
        
        // 描述
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 备份状态指示器
class BackupStatusIndicator extends StatelessWidget {
  final BackupStatus status;

  const BackupStatusIndicator({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == BackupStatus.inProgress)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            _getIcon(),
            size: 16,
            color: _getColor(),
          ),
        const SizedBox(width: 4),
        Text(
          _getLabel(),
          style: TextStyle(
            fontSize: 12,
            color: _getColor(),
          ),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (status) {
      case BackupStatus.completed:
        return Icons.check_circle;
      case BackupStatus.pending:
        return Icons.pending;
      case BackupStatus.inProgress:
        return Icons.sync;
      case BackupStatus.failed:
        return Icons.error;
    }
  }

  Color _getColor() {
    switch (status) {
      case BackupStatus.completed:
        return Colors.green;
      case BackupStatus.pending:
        return Colors.orange;
      case BackupStatus.inProgress:
        return Colors.blue;
      case BackupStatus.failed:
        return Colors.red;
    }
  }

  String _getLabel() {
    switch (status) {
      case BackupStatus.completed:
        return '已完成';
      case BackupStatus.pending:
        return '等待中';
      case BackupStatus.inProgress:
        return '进行中';
      case BackupStatus.failed:
        return '失败';
    }
  }
}

/// 导出组件集合
const backupWidgets = (
  BackupListItem: BackupListItem,
  BackupProgressIndicator: BackupProgressIndicator,
  BackupSchedulePicker: BackupSchedulePicker,
  BackupStatusIndicator: BackupStatusIndicator,
);