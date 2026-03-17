import 'package:flutter/material.dart';

/// 联系人模型
class Contact {
  final String id;
  final String name;
  final String? avatar;
  final String? email;
  final String? phone;
  final ContactStatus status;
  final DateTime? lastSeen;
  final List<String> tags;
  final bool isFavorite;
  final bool isVerified;

  const Contact({
    required this.id,
    required this.name,
    this.avatar,
    this.email,
    this.phone,
    this.status = ContactStatus.offline,
    this.lastSeen,
    this.tags = const [],
    this.isFavorite = false,
    this.isVerified = false,
  });

  Contact copyWith({
    bool? isFavorite,
    ContactStatus? status,
  }) {
    return Contact(
      id: id,
      name: name,
      avatar: avatar,
      email: email,
      phone: phone,
      status: status ?? this.status,
      lastSeen: lastSeen,
      tags: tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

/// 联系人状态
enum ContactStatus { online, away, busy, offline }

/// 联系人列表主屏幕
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  // 联系人列表
  final List<Contact> _contacts = [
    Contact(
      id: '1',
      name: '张三',
      email: 'zhangsan@example.com',
      phone: '+86 138****1234',
      status: ContactStatus.online,
      lastSeen: DateTime.now(),
      tags: ['同事', '开发'],
      isFavorite: true,
      isVerified: true,
    ),
    Contact(
      id: '2',
      name: '李四',
      email: 'lisi@example.com',
      phone: '+86 139****5678',
      status: ContactStatus.away,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
      tags: ['朋友'],
      isFavorite: true,
    ),
    Contact(
      id: '3',
      name: '王五',
      email: 'wangwu@example.com',
      phone: '+86 136****9012',
      status: ContactStatus.busy,
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      tags: ['同事', '产品'],
      isVerified: true,
    ),
    Contact(
      id: '4',
      name: '赵六',
      email: 'zhaoliu@example.com',
      phone: '+86 137****3456',
      status: ContactStatus.offline,
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      tags: ['家人'],
    ),
    Contact(
      id: '5',
      name: '钱七',
      email: 'qianqi@example.com',
      phone: '+86 135****7890',
      status: ContactStatus.online,
      tags: ['开发', '开源'],
      isFavorite: true,
    ),
    Contact(
      id: '6',
      name: '孙八',
      email: 'sunba@example.com',
      phone: '+86 134****2345',
      status: ContactStatus.offline,
      lastSeen: DateTime.now().subtract(const Duration(hours: 5)),
      tags: ['设计'],
    ),
    Contact(
      id: '7',
      name: '周九',
      email: 'zhoujiu@example.com',
      phone: '+86 133****6789',
      status: ContactStatus.away,
      tags: ['运营'],
    ),
    Contact(
      id: '8',
      name: '吴十',
      email: 'wushi@example.com',
      phone: '+86 132****0123',
      status: ContactStatus.online,
      tags: ['市场'],
      isVerified: true,
    ),
  ];

  List<Contact> get _filteredContacts {
    var list = _contacts;

    if (_showFavoritesOnly) {
      list = list.where((c) => c.isFavorite).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list.where((c) =>
        c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (c.email?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
        c.tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }

    // Sort: favorites first, then alphabetically
    list.sort((a, b) {
      if (a.isFavorite && !b.isFavorite) return -1;
      if (!a.isFavorite && b.isFavorite) return 1;
      return a.name.compareTo(b.name);
    });

    return list;
  }

  int get _onlineCount => _contacts.where((c) => c.status == ContactStatus.online).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('联系人'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: _addContact,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Text('导入联系人'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('导出联系人'),
              ),
              const PopupMenuItem(
                value: 'groups',
                child: Text('分组管理'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          _buildSearchBar(),
          // 统计和筛选
          _buildStatsBar(),
          // 联系人列表
          Expanded(
            child: _filteredContacts.isEmpty
                ? _buildEmptyState()
                : _buildContactsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addContact,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  /// 搜索栏
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索联系人...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
      ),
    );
  }

  /// 统计栏
  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 在线状态
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$_onlineCount 在线',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 收藏筛选
          FilterChip(
            label: const Text('仅显示收藏'),
            selected: _showFavoritesOnly,
            onSelected: (value) => setState(() => _showFavoritesOnly = value),
            avatar: _showFavoritesOnly ? null : const Icon(Icons.star_border, size: 16),
          ),
          const Spacer(),
          // 总计
          Text(
            '共 ${_filteredContacts.length} 位联系人',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? '未找到联系人' : '暂无联系人',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? '尝试其他关键词' : '点击右下角添加联系人',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// 联系人列表
  Widget _buildContactsList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 80),
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactItem(contact);
      },
    );
  }

  /// 联系人项
  Widget _buildContactItem(Contact contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: () => _showContactDetail(contact),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _getAvatarColor(contact.name),
              child: Text(
                contact.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            // 在线状态指示器
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: _getStatusColor(contact.status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            if (contact.isFavorite)
              const Icon(Icons.star, size: 16, color: Colors.amber),
            if (contact.isFavorite) const SizedBox(width: 4),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      contact.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (contact.isVerified) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.verified, size: 14, color: Colors.blue),
                  ],
                ],
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.email != null)
              Text(
                contact.email!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                overflow: TextOverflow.ellipsis,
              ),
            if (contact.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: contact.tags.take(2).map((tag) => Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.grey[400]),
          onSelected: (value) => _handleContactAction(value, contact),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'favorite',
              child: Row(
                children: [
                  Icon(contact.isFavorite ? Icons.star_border : Icons.star, size: 20),
                  const SizedBox(width: 8),
                  Text(contact.isFavorite ? '取消收藏' : '收藏'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'message',
              child: Row(
                children: [
                  Icon(Icons.message, size: 20),
                  SizedBox(width: 8),
                  Text('发消息'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'call',
              child: Row(
                children: [
                  Icon(Icons.call, size: 20),
                  SizedBox(width: 8),
                  Text('拨打电话'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取头像颜色
  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors[name.hashCode % colors.length];
  }

  /// 获取状态颜色
  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.online:
        return Colors.green;
      case ContactStatus.away:
        return Colors.orange;
      case ContactStatus.busy:
        return Colors.red;
      case ContactStatus.offline:
        return Colors.grey;
    }
  }

  /// 添加联系人
  void _addContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('打开添加联系人表单'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 处理菜单操作
  void _handleMenuAction(String action) {
    switch (action) {
      case 'import':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导入联系人'), behavior: SnackBarBehavior.floating),
        );
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出联系人'), behavior: SnackBarBehavior.floating),
        );
        break;
      case 'groups':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分组管理'), behavior: SnackBarBehavior.floating),
        );
        break;
    }
  }

  /// 处理联系人操作
  void _handleContactAction(String action, Contact contact) {
    switch (action) {
      case 'favorite':
        setState(() {
          final index = _contacts.indexWhere((c) => c.id == contact.id);
          if (index != -1) {
            _contacts[index] = contact.copyWith(isFavorite: !contact.isFavorite);
          }
        });
        break;
      case 'message':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发消息给 ${contact.name}'), behavior: SnackBarBehavior.floating),
        );
        break;
      case 'call':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('呼叫 ${contact.name}'), behavior: SnackBarBehavior.floating),
        );
        break;
      case 'delete':
        _confirmDeleteContact(contact);
        break;
    }
  }

  /// 确认删除联系人
  void _confirmDeleteContact(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除联系人'),
        content: Text('确定要删除 "${contact.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _contacts.removeWhere((c) => c.id == contact.id));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 显示联系人详情
  void _showContactDetail(Contact contact) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContactDetailSheet(contact: contact),
    );
  }
}

/// 联系人详情面板
class _ContactDetailSheet extends StatelessWidget {
  final Contact contact;

  const _ContactDetailSheet({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // 拖动条
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // 头部
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 头像
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue,
                      child: Text(
                        contact.name[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 36,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 名称
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      contact.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (contact.isVerified) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.verified, color: Colors.blue, size: 24),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // 状态
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(contact.status),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getStatusText(contact.status),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // 信息列表
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (contact.email != null)
                  _buildInfoItem(Icons.email, '邮箱', contact.email!),
                if (contact.phone != null)
                  _buildInfoItem(Icons.phone, '电话', contact.phone!),
                if (contact.tags.isNotEmpty)
                  _buildTagsItem(contact.tags),
              ],
            ),
          ),
          // 底部按钮
          Container(
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('呼叫 ${contact.name}'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('呼叫'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('发消息给 ${contact.name}'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('发消息'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsItem(List<String> tags) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.label, color: Colors.purple),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('标签', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: tags.map((tag) => Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ContactStatus status) {
    switch (status) {
      case ContactStatus.online:
        return Colors.green;
      case ContactStatus.away:
        return Colors.orange;
      case ContactStatus.busy:
        return Colors.red;
      case ContactStatus.offline:
        return Colors.grey;
    }
  }

  String _getStatusText(ContactStatus status) {
    switch (status) {
      case ContactStatus.online:
        return '在线';
      case ContactStatus.away:
        return '离开';
      case ContactStatus.busy:
        return '忙碌';
      case ContactStatus.offline:
        return '离线';
    }
  }
}