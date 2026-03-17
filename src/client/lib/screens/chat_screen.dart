import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final bool isEncrypted;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    required this.timestamp,
    required this.status,
    this.isEncrypted = true,
    required this.isMine,
  });
}

/// 消息类型
enum MessageType {
  text,
  image,
  file,
  voice,
  system,
}

/// 消息状态
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed,
}

/// 聊天界面主屏幕
class ChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final bool isEncrypted;

  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    this.isEncrypted = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _showEncryptionBadge = true;

  // 聊天消息列表
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '1',
      senderId: 'contact_1',
      senderName: '张三',
      type: MessageType.text,
      content: '你好！这是一个加密消息测试。',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      status: MessageStatus.read,
      isEncrypted: true,
      isMine: false,
    ),
    ChatMessage(
      id: '2',
      senderId: 'me',
      senderName: '我',
      type: MessageType.text,
      content: '你好！消息已启用端到端加密。',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
      status: MessageStatus.read,
      isEncrypted: true,
      isMine: true,
    ),
    ChatMessage(
      id: '3',
      senderId: 'contact_1',
      senderName: '张三',
      type: MessageType.text,
      content: '太棒了！我们可以安全地交流。',
      timestamp: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
      status: MessageStatus.read,
      isEncrypted: true,
      isMine: false,
    ),
    ChatMessage(
      id: '4',
      senderId: 'me',
      senderName: '我',
      type: MessageType.file,
      content: 'document.pdf',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      status: MessageStatus.read,
      isEncrypted: true,
      isMine: true,
    ),
    ChatMessage(
      id: '5',
      senderId: 'contact_1',
      senderName: '张三',
      type: MessageType.image,
      content: 'https://example.com/image.jpg',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      status: MessageStatus.read,
      isEncrypted: true,
      isMine: false,
    ),
    ChatMessage(
      id: '6',
      senderId: 'me',
      senderName: '我',
      type: MessageType.text,
      content: '收到图片了，很清晰！',
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      status: MessageStatus.delivered,
      isEncrypted: true,
      isMine: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      senderName: '我',
      type: MessageType.text,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isEncrypted: widget.isEncrypted,
      isMine: true,
    );

    setState(() {
      _messages.add(message);
    });

    _messageController.clear();
    _scrollToBottom();

    // 模拟发送
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: message.id,
              senderId: message.senderId,
              senderName: message.senderName,
              type: message.type,
              content: message.content,
              timestamp: message.timestamp,
              status: MessageStatus.sent,
              isEncrypted: message.isEncrypted,
              isMine: true,
            );
          }
        });
      }
    });

    // 模拟送达
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: message.id,
              senderId: message.senderId,
              senderName: message.senderName,
              type: message.type,
              content: message.content,
              timestamp: message.timestamp,
              status: MessageStatus.delivered,
              isEncrypted: message.isEncrypted,
              isMine: true,
            );
          }
        });
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('图片'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择图片'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file, color: Colors.orange),
              title: const Text('文件'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择文件'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.red),
              title: const Text('语音'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('开始录音'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('打开相机'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 加密提示条
          if (widget.isEncrypted) _buildEncryptionBanner(),
          // 消息列表
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          // 输入区域
          _buildInputArea(),
        ],
      ),
    );
  }

  /// 构建AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          // 头像
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              widget.contactName[0],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 名称和状态
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '在线',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // 加密状态
        if (widget.isEncrypted)
          IconButton(
            icon: const Icon(Icons.lock, size: 20),
            color: Colors.green,
            tooltip: '端到端加密',
            onPressed: _showEncryptionInfo,
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: _showChatOptions,
        ),
      ],
    );
  }

  /// 加密提示条
  Widget _buildEncryptionBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      color: Colors.green.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock, size: 14, color: Colors.green),
          const SizedBox(width: 6),
          Text(
            '消息已端到端加密',
            style: TextStyle(fontSize: 12, color: Colors.green[700]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _showEncryptionBadge = !_showEncryptionBadge),
            child: Text(
              _showEncryptionBadge ? '隐藏' : '显示',
              style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// 消息气泡
  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMine) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: Text(
                message.senderName[0],
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          // 消息内容
          Flexible(
            child: Column(
              crossAxisAlignment: message.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 消息气泡
                GestureDetector(
                  onLongPress: () => _showMessageOptions(message),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: message.isMine
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[200],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.isMine ? 16 : 4),
                        bottomRight: Radius.circular(message.isMine ? 4 : 16),
                      ),
                    ),
                    child: _buildMessageContent(message),
                  ),
                ),
                const SizedBox(height: 4),
                // 时间和状态
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEncrypted)
                      const Icon(Icons.lock, size: 10, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                    if (message.isMine) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(message.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (message.isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// 消息内容
  Widget _buildMessageContent(ChatMessage message) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isMine ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              '图片',
              style: TextStyle(
                color: message.isMine ? Colors.white70 : Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        );
      case MessageType.file:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: message.isMine ? Colors.white70 : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  color: message.isMine ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case MessageType.voice:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow,
              color: message.isMine ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '0:15',
              style: TextStyle(
                color: message.isMine ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        );
      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        );
    }
  }

  /// 状态图标
  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 12, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 12, color: Colors.white70);
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 12, color: Colors.lightBlueAccent);
      case MessageStatus.failed:
        return const Icon(Icons.error, size: 12, color: Colors.red);
    }
  }

  /// 输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 附件按钮
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: Theme.of(context).colorScheme.primary,
              onPressed: _showAttachmentMenu,
            ),
            // 输入框
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // 发送按钮
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 20,
              child: IconButton(
                icon: const Icon(Icons.send, size: 18),
                color: Colors.white,
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示消息选项
  void _showMessageOptions(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('复制'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            if (message.isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _messages.removeWhere((m) => m.id == message.id));
                },
              ),
            ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('转发'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('选择转发联系人'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 显示加密信息
  void _showEncryptionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.green),
            SizedBox(width: 12),
            Text('端到端加密'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('此对话已启用端到端加密。'),
            SizedBox(height: 12),
            Text(
              '这意味着只有你和对方可以读取消息内容，即使是服务器也无法解密。',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  /// 显示聊天选项
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('联系人信息'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('搜索聊天记录'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('免打扰'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('屏蔽联系人', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}