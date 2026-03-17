import 'package:flutter/material.dart';
import '../models/sync_item.dart';

// 状态枚举 - 从sync_item导入后使用别名
typedef SyncStatus = SyncStatusEnum;

/// 同步状态指示器组件
class SyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final bool showLabel;
  final double size;

  const SyncStatusIndicator({
    super.key,
    required this.status,
    this.showLabel = true,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final info = _getStatusInfo();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: status == SyncStatusEnum.syncing ? null : 1,
            strokeWidth: 2,
            backgroundColor: info.color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(info.color),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Text(
            info.label,
            style: TextStyle(color: info.color, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  ({Color color, IconData icon, String label}) _getStatusInfo() {
    switch (status) {
      case SyncStatusEnum.idle:
        return (Colors.grey, Icons.cloud_queue, '等待同步');
      case SyncStatusEnum.syncing:
        return (Colors.blue, Icons.sync, '同步中');
      case SyncStatusEnum.success:
        return (Colors.green, Icons.cloud_done, '已同步');
      case SyncStatusEnum.error:
        return (Colors.red, Icons.error_outline, '同步失败');
      case SyncStatusEnum.offline:
        return (Colors.orange, Icons.cloud_off, '离线');
    }
  }
}

/// 冲突项卡片组件
class ConflictItemCard extends StatelessWidget {
  final SyncConflict conflict;
  final VoidCallback? onKeepLocal;
  final VoidCallback? onKeepRemote;
  final VoidCallback? onKeepBoth;

  const ConflictItemCard({
    super.key,
    required this.conflict,
    this.onKeepLocal,
    this.onKeepRemote,
    this.onKeepBoth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber, color: Colors.orange),
        title: Text(
          conflict.itemTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('点击查看冲突详情'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 本地版本
                _buildVersionBox(
                  '本地版本',
                  conflict.localContent,
                  conflict.localModified,
                  Colors.blue,
                ),
                const SizedBox(height: 12),
                // 远程版本
                _buildVersionBox(
                  '远程版本',
                  conflict.remoteContent,
                  conflict.remoteModified,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onKeepLocal,
                      icon: const Icon(Icons.phone_android),
                      label: const Text('保留本地'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onKeepRemote,
                      icon: const Icon(Icons.cloud),
                      label: const Text('保留远程'),
                    ),
                    OutlinedButton.icon(
                      onPressed: onKeepBoth,
                      icon: const Icon(Icons.copy_all),
                      label: const Text('保留两者'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionBox(String label, String content, DateTime time, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                _formatTime(time),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// 同步历史记录组件
class SyncHistoryList extends StatelessWidget {
  final List<SyncHistoryItem> items;
  final ScrollController? controller;

  const SyncHistoryList({
    super.key,
    required this.items,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('暂无同步历史'),
      );
    }

    return ListView.builder(
      controller: controller,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _HistoryListItem(item: items[index]);
      },
    );
  }
}

class _HistoryListItem extends StatelessWidget {
  final SyncHistoryItem item;

  const _HistoryListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionInfo = _getActionInfo();
    final statusColor = item.status == SyncStatusEnum.success ? Colors.green : Colors.red;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: actionInfo.color.withOpacity(0.1),
        child: Icon(actionInfo.icon, color: actionInfo.color),
      ),
      title: Text(item.itemTitle),
      subtitle: Text(_formatTime(item.timestamp)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          item.status == SyncStatusEnum.success ? '成功' : '失败',
          style: TextStyle(color: statusColor, fontSize: 12),
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _getActionInfo() {
    switch (item.action) {
      case SyncAction.upload:
        return (Icons.upload, Colors.blue);
      case SyncAction.download:
        return (Icons.download, Colors.green);
      case SyncAction.conflict:
        return (Icons.warning, Colors.orange);
      case SyncAction.delete:
        return (Icons.delete, Colors.red);
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

/// 进度同步指示器
class SyncProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final bool showPercentage;

  const SyncProgressIndicator({
    super.key,
    required this.progress,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (label != null) Text(label!),
                if (showPercentage)
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Colors.blue),
          ),
        ),
      ],
    );
  }
}

/// 批量同步控制组件
class BatchSyncControls extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onSyncSelected;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onClearSelection;

  const BatchSyncControls({
    super.key,
    required this.selectedCount,
    this.onSyncSelected,
    this.onDeleteSelected,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              '已选择 $selectedCount 项',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearSelection,
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onSyncSelected,
              icon: const Icon(Icons.sync),
              label: const Text('同步'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onDeleteSelected,
              icon: const Icon(Icons.delete),
              label: const Text('删除'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}