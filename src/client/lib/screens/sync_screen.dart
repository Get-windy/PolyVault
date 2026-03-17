import 'package:flutter/material.dart';
import '../models/sync_item.dart';

/// 同步状态
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}

/// 冲突解决策略
enum ConflictResolution {
  keepLocal,
  keepRemote,
  keepBoth,
  manual,
}

/// 同步状态页面
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 模拟同步数据
  final List<SyncItem> _syncItems = [
    SyncItem(
      id: '1',
      type: SyncItemType.credential,
      title: 'GitHub Credentials',
      localModified: DateTime.now().subtract(const Duration(hours: 2)),
      remoteModified: DateTime.now().subtract(const Duration(hours: 1)),
      status: SyncStatus.success,
    ),
    SyncItem(
      id: '2',
      type: SyncItemType.note,
      title: '项目笔记',
      localModified: DateTime.now().subtract(const Duration(days: 1)),
      remoteModified: DateTime.now().subtract(const Duration(days: 2)),
      status: SyncStatus.success,
    ),
  ];

  // 冲突列表
  final List<SyncConflict> _conflicts = [
    SyncConflict(
      id: 'c1',
      itemId: '3',
      itemTitle: 'API密钥配置',
      localContent: 'api_key_v1',
      remoteContent: 'api_key_v2',
      localModified: DateTime.now().subtract(const Duration(hours: 3)),
      remoteModified: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    SyncConflict(
      id: 'c2',
      itemId: '4',
      itemTitle: '数据库密码',
      localContent: 'db_pass_local',
      remoteContent: 'db_pass_remote',
      localModified: DateTime.now().subtract(const Duration(days: 1)),
      remoteModified: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // 同步历史
  final List<SyncHistoryItem> _history = [
    SyncHistoryItem(
      id: 'h1',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      action: SyncAction.upload,
      itemTitle: 'GitHub Credentials',
      status: SyncStatus.success,
    ),
    SyncHistoryItem(
      id: 'h2',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      action: SyncAction.download,
      itemTitle: '项目笔记',
      status: SyncStatus.success,
    ),
    SyncHistoryItem(
      id: 'h3',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      action: SyncAction.conflict,
      itemTitle: 'API密钥配置',
      status: SyncStatus.error,
    ),
  ];

  SyncStatus _currentStatus = SyncStatus.idle;
  double _syncProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 开始同步
  Future<void> _startSync() async {
    setState(() {
      _currentStatus = SyncStatus.syncing;
      _syncProgress = 0.0;
    });

    // 模拟同步过程
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _syncProgress = i / 100;
      });
    }

    setState(() {
      _currentStatus = SyncStatus.success;
    });
  }

  // 解决冲突
  Future<void> _resolveConflict(String conflictId, ConflictResolution resolution) async {
    // 模拟解决冲突
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _conflicts.removeWhere((c) => c.id == conflictId);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('冲突已解决')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('同步状态'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '状态', icon: Icon(Icons.sync)),
            Tab(text: '冲突', icon: Icon(Icons.warning)),
            Tab(text: '历史', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 状态页
          _buildStatusTab(theme),
          // 冲突页
          _buildConflictsTab(theme),
          // 历史页
          _buildHistoryTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _currentStatus == SyncStatus.syncing ? null : _startSync,
        icon: const Icon(Icons.sync),
        label: Text(_currentStatus == SyncStatus.syncing ? '同步中...' : '开始同步'),
      ),
    );
  }

  // 状态页
  Widget _buildStatusTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 同步状态卡片
          _SyncStatusCard(
            status: _currentStatus,
            progress: _syncProgress,
            lastSyncTime: DateTime.now().subtract(const Duration(hours: 1)),
            onSync: _startSync,
          ),
          const SizedBox(height: 24),
          
          // 同步项目列表
          Text(
            '同步项目',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._syncItems.map((item) => _SyncItemCard(item: item)),
        ],
      ),
    );
  }

  // 冲突页
  Widget _buildConflictsTab(ThemeData theme) {
    if (_conflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
            const SizedBox(height: 16),
            Text(
              '没有冲突',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              '所有数据已同步',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conflicts.length,
      itemBuilder: (context, index) {
        final conflict = _conflicts[index];
        return _ConflictCard(
          conflict: conflict,
          onResolve: (resolution) => _resolveConflict(conflict.id, resolution),
        );
      },
    );
  }

  // 历史页
  Widget _buildHistoryTab(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _history.length,
      itemBuilder: (context, index) {
        final item = _history[index];
        return _HistoryCard(item: item);
      },
    );
  }
}

// 同步状态卡片
class _SyncStatusCard extends StatelessWidget {
  final SyncStatus status;
  final double progress;
  final DateTime lastSyncTime;
  final VoidCallback onSync;

  const _SyncStatusCard({
    required this.status,
    required this.progress,
    required this.lastSyncTime,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusInfo = _getStatusInfo();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 状态图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: statusInfo.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(statusInfo.icon, size: 40, color: statusInfo.color),
            ),
            const SizedBox(height: 16),
            
            // 状态文字
            Text(
              statusInfo.label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            
            // 上次同步时间
            Text(
              '上次同步: ${_formatTime(lastSyncTime)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            
            // 进度条
            if (status == SyncStatus.syncing) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 8),
              Text('${(progress * 100).toInt()}%'),
            ],
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color color, String label}) _getStatusInfo() {
    switch (status) {
      case SyncStatus.idle:
        return (Icons.cloud_queue, Colors.grey, '等待同步');
      case SyncStatus.syncing:
        return (Icons.sync, Colors.blue, '同步中');
      case SyncStatus.success:
        return (Icons.cloud_done, Colors.green, '同步完成');
      case SyncStatus.error:
        return (Icons.error_outline, Colors.red, '同步失败');
      case SyncStatus.offline:
        return (Icons.cloud_off, Colors.orange, '离线模式');
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

// 同步项目卡片
class _SyncItemCard extends StatelessWidget {
  final SyncItem item;

  const _SyncItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getTypeIcon(item.type),
        title: Text(item.title),
        subtitle: Text('本地: ${_formatDate(item.localModified)}'),
        trailing: _getStatusChip(item.status),
      ),
    );
  }

  Widget _getTypeIcon(SyncItemType type) {
    switch (type) {
      case SyncItemType.credential:
        return const CircleAvatar(child: Icon(Icons.key));
      case SyncItemType.note:
        return const CircleAvatar(child: Icon(Icons.note));
      case SyncItemType.file:
        return const CircleAvatar(child: Icon(Icons.folder));
      case SyncItemType.setting:
        return const CircleAvatar(child: Icon(Icons.settings));
    }
  }

  Widget _getStatusChip(SyncStatus status) {
    final (color, label) = switch (status) {
      SyncStatus.success => (Colors.green, '已同步'),
      SyncStatus.syncing => (Colors.blue, '同步中'),
      SyncStatus.error => (Colors.red, '失败'),
      SyncStatus.offline => (Colors.orange, '离线'),
      _ => (Colors.grey, '等待'),
    };

    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// 冲突卡片
class _ConflictCard extends StatelessWidget {
  final SyncConflict conflict;
  final void Function(ConflictResolution) onResolve;

  const _ConflictCard({
    required this.conflict,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflict.itemTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 对比内容
            Row(
              children: [
                Expanded(
                  child: _buildContentBox(
                    '本地版本',
                    conflict.localContent,
                    conflict.localModified,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildContentBox(
                    '远程版本',
                    conflict.remoteContent,
                    conflict.remoteModified,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onResolve(ConflictResolution.keepLocal),
                  child: const Text('保留本地'),
                ),
                TextButton(
                  onPressed: () => onResolve(ConflictResolution.keepRemote),
                  child: const Text('保留远程'),
                ),
                TextButton(
                  onPressed: () => onResolve(ConflictResolution.keepBoth),
                  child: const Text('保留两者'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBox(String label, String content, DateTime time, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(fontFamily: 'monospace')),
          const SizedBox(height: 4),
          Text(
            _formatDate(time),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

// 历史记录卡片
class _HistoryCard extends StatelessWidget {
  final SyncHistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = _getActionInfo();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(item.itemTitle),
        subtitle: Text(_formatTime(item.timestamp)),
        trailing: _getStatusChip(item.status),
      ),
    );
  }

  ({IconData icon, Color color}) _getActionInfo() {
    return switch (item.action) {
      SyncAction.upload => (Icons.upload, Colors.blue),
      SyncAction.download => (Icons.download, Colors.green),
      SyncAction.conflict => (Icons.warning, Colors.orange),
      SyncAction.delete => (Icons.delete, Colors.red),
    };
  }

  Widget _getStatusChip(SyncStatus status) {
    final (color, label) = switch (status) {
      SyncStatus.success => (Colors.green, '成功'),
      SyncStatus.error => (Colors.red, '失败'),
      _ => (Colors.grey, '未知'),
    };

    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}