import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message.dart';

/// 消息状态
class MessagesState {
  final List<Message> messages;
  final List<Message> filteredMessages;
  final MessageType? selectedType;
  final bool isLoading;
  final String? error;

  const MessagesState({
    this.messages = const [],
    this.filteredMessages = const [],
    this.selectedType,
    this.isLoading = false,
    this.error,
  });

  MessagesState copyWith({
    List<Message>? messages,
    List<Message>? filteredMessages,
    MessageType? selectedType,
    bool? isLoading,
    String? error,
    bool clearFilter = false,
  }) {
    return MessagesState(
      messages: messages ?? this.messages,
      filteredMessages: filteredMessages ?? this.filteredMessages,
      selectedType: clearFilter ? null : (selectedType ?? this.selectedType),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => messages.where((m) => !m.isRead).length;
}

/// 消息状态管理
class MessagesNotifier extends StateNotifier<MessagesState> {
  MessagesNotifier() : super(const MessagesState()) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    state = state.copyWith(isLoading: true);
    
    // 模拟加载消息
    await Future.delayed(const Duration(milliseconds: 500));
    
    final messages = _getMockMessages();
    state = state.copyWith(
      messages: messages,
      filteredMessages: messages,
      isLoading: false,
    );
  }

  void filterByType(MessageType? type) {
    if (type == null) {
      state = state.copyWith(
        filteredMessages: state.messages,
        clearFilter: true,
      );
    } else {
      final filtered = state.messages.where((m) => m.type == type).toList();
      state = state.copyWith(
        filteredMessages: filtered,
        selectedType: type,
      );
    }
  }

  Future<void> markAsRead(String messageId) async {
    final messages = state.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isRead: true);
      }
      return m;
    }).toList();
    
    state = state.copyWith(
      messages: messages,
      filteredMessages: _applyCurrentFilter(messages),
    );
  }

  Future<void> markAllAsRead() async {
    final messages = state.messages.map((m) => m.copyWith(isRead: true)).toList();
    state = state.copyWith(
      messages: messages,
      filteredMessages: _applyCurrentFilter(messages),
    );
  }

  Future<void> deleteMessage(String messageId) async {
    final messages = state.messages.where((m) => m.id != messageId).toList();
    state = state.copyWith(
      messages: messages,
      filteredMessages: _applyCurrentFilter(messages),
    );
  }

  Future<void> refresh() async {
    await _loadMessages();
  }

  List<Message> _applyCurrentFilter(List<Message> messages) {
    if (state.selectedType == null) return messages;
    return messages.where((m) => m.type == state.selectedType).toList();
  }

  List<Message> _getMockMessages() {
    return [
      Message(
        id: '1',
        title: '安全提醒',
        content: '检测到新设备尝试访问您的凭证。IP地址: 192.168.1.100，位置: 上海。如果这不是您本人的操作，请立即修改密码。',
        type: MessageType.security,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        metadata: {'ip': '192.168.1.100', 'location': '上海'},
      ),
      Message(
        id: '2',
        title: '凭证同步完成',
        content: '您的 GitHub 凭证已成功同步到所有已连接设备。同步时间: 2026-03-24 14:00',
        type: MessageType.sync,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        metadata: {'credential_name': 'GitHub', 'devices': 3},
      ),
      Message(
        id: '3',
        title: '设备已连接',
        content: 'iPhone 15 Pro 已成功连接到您的 PolyVault 账户。您可以在设备管理中查看或移除此设备。',
        type: MessageType.system,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        metadata: {'device_name': 'iPhone 15 Pro'},
      ),
      Message(
        id: '4',
        title: '自动备份完成',
        content: '您的数据已自动备份到云端。备份大小: 2.3MB，包含 45 个凭证。下次备份时间: 明天 02:00',
        type: MessageType.backup,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        metadata: {'backup_size': '2.3MB', 'credentials': 45},
      ),
      Message(
        id: '5',
        title: '密码泄露预警',
        content: '检测到您的 Gmail 账户密码可能已在数据泄露中出现。建议您立即更改密码。',
        type: MessageType.security,
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        metadata: {'credential_name': 'Gmail', 'breach_source': '已知数据库泄露'},
      ),
      Message(
        id: '6',
        title: '系统更新',
        content: 'PolyVault 已更新到 v2.1.0 版本。新功能: 生物识别登录、自动填充增强、性能优化。',
        type: MessageType.system,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        metadata: {'version': 'v2.1.0'},
      ),
      Message(
        id: '7',
        title: '设备已移除',
        content: 'MacBook Pro 已从您的账户中移除。所有相关凭证已从该设备清除。',
        type: MessageType.system,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        metadata: {'device_name': 'MacBook Pro'},
      ),
      Message(
        id: '8',
        title: '同步冲突',
        content: '您的 AWS 凭证在多个设备上被修改。请确认要保留哪个版本。',
        type: MessageType.sync,
        isRead: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        metadata: {'credential_name': 'AWS'},
      ),
    ];
  }
}

/// 消息状态 Provider
final messagesProvider = StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  return MessagesNotifier();
});

/// 消息屏幕
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messagesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息中心'),
        centerTitle: true,
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(messagesProvider.notifier).markAllAsRead(),
              child: const Text('全部已读'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(messagesProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选器
          _buildFilterChips(context, ref, state),
          
          // 消息列表
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.filteredMessages.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMessageList(context, ref, state),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref, MessagesState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            FilterChip(
              label: const Text('全部'),
              selected: state.selectedType == null,
              onSelected: (_) => ref.read(messagesProvider.notifier).filterByType(null),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('安全'),
              selected: state.selectedType == MessageType.security,
              avatar: const Icon(Icons.security, size: 18),
              onSelected: (_) => ref.read(messagesProvider.notifier).filterByType(MessageType.security),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('系统'),
              selected: state.selectedType == MessageType.system,
              avatar: const Icon(Icons.info, size: 18),
              onSelected: (_) => ref.read(messagesProvider.notifier).filterByType(MessageType.system),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('同步'),
              selected: state.selectedType == MessageType.sync,
              avatar: const Icon(Icons.sync, size: 18),
              onSelected: (_) => ref.read(messagesProvider.notifier).filterByType(MessageType.sync),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('备份'),
              selected: state.selectedType == MessageType.backup,
              avatar: const Icon(Icons.backup, size: 18),
              onSelected: (_) => ref.read(messagesProvider.notifier).filterByType(MessageType.backup),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无消息',
            style: TextStyle(
              fontSize: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, WidgetRef ref, MessagesState state) {
    return RefreshIndicator(
      onRefresh: () => ref.read(messagesProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.filteredMessages.length,
        itemBuilder: (context, index) {
          final message = state.filteredMessages[index];
          return _MessageCard(
            message: message,
            onTap: () {
              ref.read(messagesProvider.notifier).markAsRead(message.id);
              _showMessageDetail(context, message);
            },
            onDelete: () {
              ref.read(messagesProvider.notifier).deleteMessage(message.id);
            },
          );
        },
      ),
    );
  }

  void _showMessageDetail(BuildContext context, Message message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageDetailSheet(message: message),
    );
  }
}

/// 消息卡片
class _MessageCard extends StatelessWidget {
  final Message message;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.message,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUnread = !message.isRead;

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        elevation: isUnread ? 2 : 0,
        color: isUnread 
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTypeIcon(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              message.title,
                              style: TextStyle(
                                fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (isUnread)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(message.createdAt),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
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

  Widget _buildTypeIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (message.type) {
      case MessageType.security:
        icon = Icons.security;
        color = Colors.orange;
      case MessageType.system:
        icon = Icons.info;
        color = Colors.blue;
      case MessageType.sync:
        icon = Icons.sync;
        color = Colors.green;
      case MessageType.backup:
        icon = Icons.backup;
        color = Colors.purple;
      case MessageType.general:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 60) {
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

/// 消息详情底部表单
class _MessageDetailSheet extends StatelessWidget {
  final Message message;

  const _MessageDetailSheet({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖动条
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // 标题行
          Row(
            children: [
              _buildTypeIcon(theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 消息内容
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.content,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ),
          
          // 元数据
          if (message.metadata != null && message.metadata!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMetadataSection(theme),
          ],
          
          const SizedBox(height: 24),
          
          // 操作按钮
          if (message.type == MessageType.security)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  // 跳转到安全设置
                },
                icon: const Icon(Icons.shield),
                label: const Text('查看安全设置'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeIcon(ThemeData theme) {
    IconData icon;
    Color color;

    switch (message.type) {
      case MessageType.security:
        icon = Icons.security;
        color = Colors.orange;
      case MessageType.system:
        icon = Icons.info;
        color = Colors.blue;
      case MessageType.sync:
        icon = Icons.sync;
        color = Colors.green;
      case MessageType.backup:
        icon = Icons.backup;
        color = Colors.purple;
      case MessageType.general:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildMetadataSection(ThemeData theme) {
    final metadata = message.metadata!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '详细信息',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...metadata.entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  _getMetadataLabel(entry.key),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  entry.value.toString(),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  String _getMetadataLabel(String key) {
    const labels = {
      'ip': 'IP地址',
      'location': '位置',
      'device_name': '设备名称',
      'credential_name': '凭证名称',
      'backup_size': '备份大小',
      'credentials': '凭证数量',
      'devices': '设备数量',
      'version': '版本',
      'breach_source': '泄露来源',
    };
    return labels[key] ?? key;
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
           '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}