import 'package:flutter/material.dart';
import '../models/message.dart';

/// 消息详情页
class MessageDetailScreen extends StatelessWidget {
  final Message message;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onArchive;

  const MessageDetailScreen({
    super.key,
    required this.message,
    this.onDelete,
    this.onReply,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: onArchive ?? () => Navigator.pop(context),
            tooltip: '归档',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'delete':
                  onDelete?.call();
                case 'reply':
                  onReply?.call();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reply',
                child: Row(
                  children: [
                    Icon(Icons.reply),
                    SizedBox(width: 8),
                    Text('回复'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: theme.colorScheme.error),
                    const SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: theme.colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 消息类型和状态
            Row(
              children: [
                _buildMessageTypeChip(message.type),
                const Spacer(),
                if (!message.isRead)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '未读',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // 标题
            Text(
              message.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 时间
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(message.createdAt),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 分割线
            Divider(color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),

            // 消息内容
            Text(
              message.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),

            // 元数据展示
            if (message.metadata != null && message.metadata!.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildMetadataSection(context),
            ],

            const SizedBox(height: 32),

            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReply,
                    icon: const Icon(Icons.reply),
                    label: const Text('回复'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // 标记为已读
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已标记为已读')),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('标记已读'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTypeChip(MessageType type) {
    IconData icon;
    Color color;
    String label;

    switch (type) {
      case MessageType.security:
        icon = Icons.security;
        color = Colors.orange;
        label = '安全提醒';
      case MessageType.system:
        icon = Icons.info;
        color = Colors.blue;
        label = '系统通知';
      case MessageType.device:
        icon = Icons.devices;
        color = Colors.green;
        label = '设备消息';
      case MessageType.credential:
        icon = Icons.vpn_key;
        color = Colors.purple;
        label = '凭证消息';
      case MessageType.sync:
        icon = Icons.sync;
        color = Colors.teal;
        label = '同步消息';
      case MessageType.backup:
        icon = Icons.backup;
        color = Colors.indigo;
        label = '备份消息';
      case MessageType.general:
        icon = Icons.notifications;
        color = Colors.grey;
        label = '普通消息';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
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

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = message.metadata!;

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '详细信息',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...metadata.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        entry.value.toString(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// 消息输入组件
class MessageInputComponent extends StatefulWidget {
  final ValueChanged<String>? onSend;
  final VoidCallback? onAttachment;
  final String? placeholder;
  final bool enabled;

  const MessageInputComponent({
    super.key,
    this.onSend,
    this.onAttachment,
    this.placeholder,
    this.enabled = true,
  });

  @override
  State<MessageInputComponent> createState() => _MessageInputComponentState();
}

class _MessageInputComponentState extends State<MessageInputComponent> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateHasText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateHasText() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      widget.onSend?.call(text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 附件按钮
            if (widget.onAttachment != null)
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: widget.enabled ? widget.onAttachment : null,
                color: theme.colorScheme.primary,
                tooltip: '添加附件',
              ),
            
            // 输入框
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: widget.enabled,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: widget.placeholder ?? '输入消息...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // 发送按钮
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: Icon(
                  _hasText ? Icons.send : Icons.send_outlined,
                ),
                onPressed: (widget.enabled && _hasText) ? _handleSend : null,
                color: _hasText 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.onSurfaceVariant,
                tooltip: '发送',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 快速回复选项
class QuickReplyOptions extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onSelect;

  const QuickReplyOptions({
    super.key,
    required this.replies,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(replies[index]),
            onPressed: () => onSelect(replies[index]),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          );
        },
      ),
    );
  }
}