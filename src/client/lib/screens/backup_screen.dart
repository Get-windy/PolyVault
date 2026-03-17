import 'package:flutter/material.dart';
import '../widgets/backup_widgets.dart';

/// 备份恢复屏幕
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  // 备份列表
  List<BackupItem> _backups = [];
  
  // 加载状态
  bool _isLoading = true;
  
  // 自动备份设置
  bool _autoBackupEnabled = false;
  BackupSchedule _schedule = BackupSchedule.daily;
  
  // 当前操作
  String? _currentOperation;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    
    // 模拟加载备份列表
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _backups = [
        BackupItem(
          id: '1',
          name: '完整备份',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          size: 1024 * 1024 * 50, // 50MB
          type: BackupType.full,
          status: BackupStatus.completed,
        ),
        BackupItem(
          id: '2',
          name: '增量备份',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          size: 1024 * 1024 * 10, // 10MB
          type: BackupType.incremental,
          status: BackupStatus.completed,
        ),
        BackupItem(
          id: '3',
          name: '完整备份',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          size: 1024 * 1024 * 48, // 48MB
          type: BackupType.full,
          status: BackupStatus.completed,
        ),
      ];
      _isLoading = false;
    });
  }

  Future<void> _createBackup(BackupType type) async {
    setState(() {
      _currentOperation = '正在创建备份...';
      _progress = 0.0;
    });

    // 模拟备份过程
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _progress = i / 10;
      });
    }

    // 添加新备份
    final newBackup = BackupItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: type == BackupType.full ? '完整备份' : '增量备份',
      createdAt: DateTime.now(),
      size: type == BackupType.full ? 50000000 : 10000000,
      type: type,
      status: BackupStatus.completed,
    );

    setState(() {
      _backups.insert(0, newBackup);
      _currentOperation = null;
      _progress = 0.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份创建成功')),
      );
    }
  }

  Future<void> _restoreBackup(BackupItem backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认恢复'),
        content: Text('确定要恢复 "${backup.name}" 吗？这将覆盖当前数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _currentOperation = '正在恢复备份...';
      _progress = 0.0;
    });

    // 模拟恢复过程
    for (int i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _progress = i / 10;
      });
    }

    setState(() {
      _currentOperation = null;
      _progress = 0.0;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份恢复成功')),
      );
    }
  }

  Future<void> _deleteBackup(BackupItem backup) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${backup.name}" 吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _backups.removeWhere((b) => b.id == backup.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份已删除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备份与恢复'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 操作按钮
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  
                  // 自动备份设置
                  _buildAutoBackupSettings(),
                  const SizedBox(height: 24),
                  
                  // 备份列表
                  _buildBackupList(),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _currentOperation == null 
                ? () => _createBackup(BackupType.full)
                : null,
            icon: const Icon(Icons.backup),
            label: const Text('完整备份'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _currentOperation == null
                ? () => _createBackup(BackupType.incremental)
                : null,
            icon: const Icon(Icons.add),
            label: const Text('增量备份'),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoBackupSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '自动备份',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: _autoBackupEnabled,
                onChanged: (value) {
                  setState(() {
                    _autoBackupEnabled = value;
                  });
                },
              ),
            ],
          ),
          if (_autoBackupEnabled) ...[
            const SizedBox(height: 16),
            BackupSchedulePicker(
              value: _schedule,
              onChanged: (schedule) {
                setState(() {
                  _schedule = schedule;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackupList() {
    if (_backups.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          children: [
            Icon(Icons.backup_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '暂无备份',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '备份历史',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        ..._backups.map((backup) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BackupListItem(
            backup: backup,
            onRestore: () => _restoreBackup(backup),
            onDelete: () => _deleteBackup(backup),
          ),
        )),
      ],
    );
  }
}

/// 备份项目数据模型
class BackupItem {
  final String id;
  final String name;
  final DateTime createdAt;
  final int size;
  final BackupType type;
  final BackupStatus status;

  BackupItem({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.size,
    required this.type,
    required this.status,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 备份类型
enum BackupType {
  full,
  incremental,
}

/// 备份状态
enum BackupStatus {
  pending,
  inProgress,
  completed,
  failed,
}

/// 备份计划
enum BackupSchedule {
  hourly,
  daily,
  weekly,
  monthly,
}

/// 备份计划扩展
extension BackupScheduleExtension on BackupSchedule {
  String get label {
    switch (this) {
      case BackupSchedule.hourly:
        return '每小时';
      case BackupSchedule.daily:
        return '每天';
      case BackupSchedule.weekly:
        return '每周';
      case BackupSchedule.monthly:
        return '每月';
    }
  }

  String get description {
    switch (this) {
      case BackupSchedule.hourly:
        return '每小时的指定时间自动备份';
      case BackupSchedule.daily:
        return '每天凌晨自动备份';
      case BackupSchedule.weekly:
        return '每周指定日期自动备份';
      case BackupSchedule.monthly:
        return '每月指定日期自动备份';
    }
  }
}