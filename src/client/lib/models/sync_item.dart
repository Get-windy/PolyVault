/// 同步项目类型
enum SyncItemType {
  credential,
  note,
  file,
  setting,
}

/// 同步动作
enum SyncAction {
  upload,
  download,
  conflict,
  delete,
}

/// 同步项目
class SyncItem {
  final String id;
  final SyncItemType type;
  final String title;
  final DateTime localModified;
  final DateTime remoteModified;
  final SyncStatus status;

  const SyncItem({
    required this.id,
    required this.type,
    required this.title,
    required this.localModified,
    required this.remoteModified,
    required this.status,
  });

  bool get hasConflict => localModified.isAfter(remoteModified);
}

/// 同步冲突
class SyncConflict {
  final String id;
  final String itemId;
  final String itemTitle;
  final String localContent;
  final String remoteContent;
  final DateTime localModified;
  final DateTime remoteModified;

  const SyncConflict({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.localContent,
    required this.remoteContent,
    required this.localModified,
    required this.remoteModified,
  });
}

/// 同步历史记录
class SyncHistoryItem {
  final String id;
  final DateTime timestamp;
  final SyncAction action;
  final String itemTitle;
  final SyncStatus status;
  final String? errorMessage;

  const SyncHistoryItem({
    required this.id,
    required this.timestamp,
    required this.action,
    required this.itemTitle,
    required this.status,
    this.errorMessage,
  });
}

/// 导入状态枚举
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
  offline,
}