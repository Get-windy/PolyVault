import 'package:flutter/material.dart';

/// 通知项
class NotificationItem {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime time;
  final bool isRead;
  final String? icon;
  final Map<String, dynamic>? data;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.time,
    this.isRead = false,
    this.icon,
    this.data,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      body: body,
      type: type,
      time: time,
      isRead: isRead ?? this.isRead,
      icon: icon,
      data: data,
    );
  }
}

/// 通知类型
enum NotificationType {
  message('消息', Icons.message, Colors.blue),
  security('安全', Icons.security, Colors.red),
  system('系统', Icons.settings, Colors.orange),
  sync('同步', Icons.sync, Colors.green),
  device('设备', Icons.phone_android, Colors.purple),
  backup('备份', Icons.backup, Colors.teal);

  final String label;
  final IconData icon;
  final Color color;

  const NotificationType(this.label, this.icon, this.color);
}

/// 通知中心主屏幕
class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;

  // 通知列表
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: '新消息',
      body: '您有3条新消息来自"产品讨论群"',
      type: NotificationType.message,
      time: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
    ),
    NotificationItem(
      id: '2',
      title: '安全提醒',
      body: '检测到新设备登录: MacBook Pro',
      type: NotificationType.security,
      time: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: false,
    ),
    NotificationItem(
      id: '3',
      title: '同步完成',
      body: '数据同步成功，共同步15项',
      type: NotificationType.sync,
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
    ),
    NotificationItem(
      id: '4',
      title: '设备连接',
      body: 'iPhone 15 Pro 已连接',
      type: NotificationType.device,
      time: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: true,
    ),
    NotificationItem(
      id: '5',
      title: '系统更新',
      body: 'PolyVault v2.1.0 已发布',
      type: NotificationType.system,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '6',
      title: '备份完成',
      body: '数据备份成功',
      type: NotificationType.backup,
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
    ),
    NotificationItem(
      id: '7',
      title: '密码过期提醒',
      body: '3个密码即将过期，请及时更新',
      type: NotificationType.security,
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationItem> get _filteredNotifications {
    if (_selectedFilter == null) return _notifications;
    return _notifications.where((n) => n.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知中心'),
        centerTitle: true,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('全部已读'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '通知 ($_unreadCount)'),
            const Tab(text: '历史'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 分类筛选
          _buildFilterChips(),
          // 通知列表
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList(false),
                _buildNotificationList(true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 分类筛选
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('全部'),
            selected: _selectedFilter == null,
            onSelected: (_) => setState(() => _selectedFilter = null),
          ),
          const SizedBox(width: 8),
          ...NotificationType.values.map((type) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              avatar: Icon(type.icon, size: 16, color: type.color),
              label: Text(type.label),
              selected: _selectedFilter == type,
              onSelected: (_) => setState(() => _selectedFilter = type),
            ),
          )),
        ],
      ),
    );
  }

  /// 通知列表
  Widget _buildNotificationList(bool historical) {
    final list = _filteredNotifications.where((n) => 
      historical ? n.isRead : !n.isRead
    ).toList();

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              historical ? Icons.history : Icons.notifications_none,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              historical ? '暂无历史通知' : '暂无新通知',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              historical ? '已处理的通知将显示在这里' : '新通知将在这里显示',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final notification = list[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  /// 通知卡片
  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteNotification(notification),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: notification.isRead ? null : notification.type.color.withOpacity(0.05),
        child: InkWell(
          onTap: () => _onNotificationTap(notification),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.type.icon,
                    color: notification.type.color,
                  ),
                ),
                const SizedBox(width: 12),
                // 内容
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: notification.type.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead 
                                  ? FontWeight.normal 
                                  : FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(notification.time),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 操作按钮
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                  onSelected: (value) {
                    switch (value) {
                      case 'read':
                        _markAsRead(notification);
                        break;
                      case 'delete':
                        _deleteNotification(notification);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!notification.isRead)
                      const PopupMenuItem(
                        value: 'read',
                        child: Text('标记已读'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('删除', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 标记全部已读
  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已全部标记为已读'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 标记单条已读
  void _markAsRead(NotificationItem notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });
  }

  /// 删除通知
  void _deleteNotification(NotificationItem notification) {
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('通知已删除'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '撤销',
          onPressed: () {
            // 简化版：实际应该保存删除的通知用于撤销
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('无法撤销')),
            );
          },
        ),
      ),
    );
  }

  /// 点击通知
  void _onNotificationTap(NotificationItem notification) {
    // 标记为已读
    if (!notification.isRead) {
      _markAsRead(notification);
    }
    
    // 根据类型处理不同操作
    switch (notification.type) {
      case NotificationType.message:
        _showMessageAction(notification);
        break;
      case NotificationType.security:
        _showSecurityAction(notification);
        break;
      case NotificationType.device:
        _showDeviceAction(notification);
        break;
      default:
        _showNotificationDetail(notification);
    }
  }

  void _showMessageAction(NotificationItem notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(notification.body),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSecurityAction(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            const SizedBox(width: 12),
            const Text('安全提醒'),
          ],
        ),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('忽略'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // 导航到安全设置
            },
            child: const Text('查看详情'),
          ),
        ],
      ),
    );
  }

  void _showDeviceAction(NotificationItem notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('设备: ${notification.body}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showNotificationDetail(NotificationItem notification) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: notification.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    notification.type.icon,
                    color: notification.type.color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(notification.body),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatTime(notification.time),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: notification.type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.type.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: notification.type.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteNotification(notification);
                    },
                    child: const Text('删除'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 打开设置
  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationSettingsScreen(),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}月${time.day}日';
    }
  }
}

/// 通知设置屏幕
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _allNotifications = true;
  bool _messageNotifications = true;
  bool _securityNotifications = true;
  bool _systemNotifications = true;
  bool _deviceNotifications = true;
  bool _syncNotifications = false;
  bool _backupNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _showPreview = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知设置'),
      ),
      body: ListView(
        children: [
          // 总体开关
          SwitchListTile(
            title: const Text('启用通知'),
            subtitle: const Text('接收应用通知'),
            value: _allNotifications,
            onChanged: (value) {
              setState(() => _allNotifications = value);
            },
          ),
          const Divider(),

          // 通知类型
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '通知类型',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('消息通知'),
            subtitle: const Text('新消息提醒'),
            secondary: Icon(NotificationType.message.icon, color: NotificationType.message.color),
            value: _messageNotifications,
            onChanged: _allNotifications 
              ? (value) => setState(() => _messageNotifications = value)
              : null,
          ),
          SwitchListTile(
            title: const Text('安全通知'),
            subtitle: const Text('安全相关提醒'),
            secondary: Icon(NotificationType.security.icon, color: NotificationType.security.color),
            value: _securityNotifications,
            onChanged: _allNotifications 
              ? (value) => setState(() => _securityNotifications = value)
              : null,
          ),
          SwitchListTile(
            title: const Text('系统通知'),
            subtitle: const Text('系统更新和维护'),
            secondary: Icon(NotificationType.system.icon, color: NotificationType.system.color),
            value: _systemNotifications,
            onChanged: _allNotifications 
              ? (value) => setState(() => _systemNotifications = value)
              : null,
          ),
          SwitchListTile(
            title: const Text('设备通知'),
            subtitle: const Text('设备连接状态'),
            secondary: Icon(NotificationType.device.icon, color: NotificationType.device.color),
            value: _deviceNotifications,
            onChanged: _allNotifications 
              ? (value) => setState(() => _deviceNotifications = value)
              : null,
          ),
          SwitchListTile(
            title: const Text('同步通知'),
            subtitle: const Text('数据同步状态'),
            secondary: Icon(NotificationType.sync.icon, color: NotificationType.sync.color),
            value: _syncNotifications,
            onChanged: _allNotifications 
              ? (value) => setState(() => _syncNotifications = value)
              : null,
          ),
          SwitchListTile(
            title: const Text('备份通知'),
            subtitle: const Text('备份完成提醒'),
            secondary: Icon(NotificationType.backup.icon, color: NotificationType.backup.color),
            value: _backupNotifications,
            onChanged: _allNotifications 
              ? (value) => setState(() => _backupNotifications = value)
              : null,
          ),
          const Divider(),

          // 通知方式
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '通知方式',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('声音'),
            subtitle: const Text('播放通知声音'),
            secondary: const Icon(Icons.volume_up),
            value: _soundEnabled,
            onChanged: _allNotifications 
              ? (value) => setState(() => _soundEnabled = value)
              : null,
          ),
          SwitchListTile(
            title: const Text('振动'),
            subtitle: const Text('振动提醒'),
            secondary: const Icon(Icons.vibration),
            value: _vibrationEnabled,
            onChanged: _allNotifications 
              ? (value) => setState(() => _vibrationEnabled = value)
              : null,
          ),
          SwitchListTile(
            title: const Text('显示预览'),
            subtitle: const Text('在通知中显示消息内容'),
            secondary: const Icon(Icons.visibility),
            value: _showPreview,
            onChanged: _allNotifications 
              ? (value) => setState(() => _showPreview = value)
              : null,
          ),
          const Divider(),

          // 清空历史
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text('清空通知历史'),
            onTap: _clearHistory,
          ),
        ],
      ),
    );
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清空历史'),
        content: const Text('确定要清空所有通知历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('历史已清空'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
}