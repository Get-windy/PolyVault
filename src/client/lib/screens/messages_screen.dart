import 'package:flutter/material.dart';
import '../models/message.dart';

/// 消息屏幕
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('消息'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              // 标记全部已读
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mockMessages.length,
        itemBuilder: (context, index) {
          final message = _mockMessages[index];
          return _buildMessageCard(context, message);
        },
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context, Message message) {
    final theme = Theme.of(context);
    final isUnread = !message.isRead;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnread ? 2 : 0,
      color: isUnread ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
      child: ListTile(
        leading: _buildMessageIcon(message.type),
        title: Row(
          children: [
            Expanded(
              child: Text(
                message.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.timeAgo,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          // 查看消息详情
        },
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
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// 模拟数据
final List<Message> _mockMessages = [
  Message(
    id: '1',
    title: '安全提醒',
    content: '检测到新设备尝试访问您的凭证，请确认是否为本人操作。',
    type: MessageType.security,
    isRead: false,
    timeAgo: '5分钟前',
  ),
  Message(
    id: '2',
    title: '凭证同步完成',
    content: '您的 GitHub 凭证已成功同步到所有设备。',
    type: MessageType.credential,
    isRead: false,
    timeAgo: '1小时前',
  ),
  Message(
    id: '3',
    title: '设备已连接',
    content: 'iPhone 15 Pro 已成功连接到您的账户。',
    type: MessageType.device,
    isRead: true,
    timeAgo: '3小时前',
  ),
  Message(
    id: '4',
    title: '系统更新',
    content: 'PolyVault 已更新到最新版本，包含安全性改进。',
    type: MessageType.system,
    isRead: true,
    timeAgo: '1天前',
  ),
];
