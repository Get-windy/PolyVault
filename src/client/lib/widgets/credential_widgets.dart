import 'package:flutter/material.dart';

/// 凭证类型枚举
enum CredentialType {
  website,
  app,
  api,
  database,
  wifi,
  bank,
  card,
  note,
  other,
}

/// 凭证数据模型
class CredentialModel {
  final String id;
  final String title;
  final String? username;
  final String? email;
  final String? phone;
  final String? url;
  final CredentialType type;
  final String? category;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final DateTime? lastAccessedAt;
  final bool isFavorite;
  final Map<String, dynamic>? metadata;

  const CredentialModel({
    required this.id,
    required this.title,
    this.username,
    this.email,
    this.phone,
    this.url,
    required this.type,
    this.category,
    this.tags = const [],
    required this.createdAt,
    this.modifiedAt,
    this.lastAccessedAt,
    this.isFavorite = false,
    this.metadata,
  });

  CredentialModel copyWith({
    String? id,
    String? title,
    String? username,
    String? email,
    String? phone,
    String? url,
    CredentialType? type,
    String? category,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? modifiedAt,
    DateTime? lastAccessedAt,
    bool? isFavorite,
    Map<String, dynamic>? metadata,
  }) {
    return CredentialModel(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      url: url ?? this.url,
      type: type ?? this.type,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// 凭证卡片组件
class CredentialCard extends StatelessWidget {
  final CredentialModel credential;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onFavorite;
  final bool showActions;

  const CredentialCard({
    super.key,
    required this.credential,
    this.onTap,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onFavorite,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeConfig = _getTypeConfig(credential.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：图标 + 标题 + 收藏
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeConfig.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeConfig.icon, color: typeConfig.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (credential.username != null)
                          Text(
                            credential.username!,
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (credential.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                ],
              ),

              // 分类和标签
              if (credential.category != null || credential.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (credential.category != null)
                      _buildChip(credential.category!, theme.colorScheme.primaryContainer),
                    ...credential.tags.map((tag) => _buildChip(
                      tag,
                      theme.colorScheme.surfaceContainerHighest,
                    )),
                  ],
                ),
              ],

              // 时间信息
              const SizedBox(height: 12),
              Row(
                children: [
                  if (credential.lastAccessedAt != null) ...[
                    Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                    const SizedBox(width: 4),
                    Text(
                      _formatRelativeTime(credential.lastAccessedAt!),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.calendar_today, size: 14, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(credential.createdAt),
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
                  ),
                ],
              ),

              // 操作按钮
              if (showActions) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: onCopy,
                      tooltip: '复制密码',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: '编辑',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(
                        credential.isFavorite ? Icons.star : Icons.star_border,
                        size: 20,
                        color: credential.isFavorite ? Colors.amber : null,
                      ),
                      onPressed: onFavorite,
                      tooltip: credential.isFavorite ? '取消收藏' : '收藏',
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: '删除',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  ({IconData icon, Color color, String label}) _getTypeConfig(CredentialType type) {
    return switch (type) {
      CredentialType.website => (Icons.language, Colors.blue, '网站'),
      CredentialType.app => (Icons.apps, Colors.green, '应用'),
      CredentialType.api => (Icons.api, Colors.purple, 'API'),
      CredentialType.database => (Icons.storage, Colors.orange, '数据库'),
      CredentialType.wifi => (Icons.wifi, Colors.teal, 'WiFi'),
      CredentialType.bank => (Icons.account_balance, Colors.indigo, '银行'),
      CredentialType.card => (Icons.credit_card, Colors.pink, '卡片'),
      CredentialType.note => (Icons.note, Colors.grey, '笔记'),
      CredentialType.other => (Icons.folder, Colors.brown, '其他'),
    };
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return _formatDate(dateTime);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 凭证筛选器组件
class CredentialFilter extends StatefulWidget {
  final String? selectedCategory;
  final CredentialType? selectedType;
  final bool? showFavorites;
  final void Function(String?)? onCategoryChanged;
  final void Function(CredentialType?)? onTypeChanged;
  final void Function(bool?)? onFavoritesChanged;
  final VoidCallback? onClearFilters;

  const CredentialFilter({
    super.key,
    this.selectedCategory,
    this.selectedType,
    this.showFavorites,
    this.onCategoryChanged,
    this.onTypeChanged,
    this.onFavoritesChanged,
    this.onClearFilters,
  });

  @override
  State<CredentialFilter> createState() => _CredentialFilterState();
}

class _CredentialFilterState extends State<CredentialFilter> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 筛选按钮行
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: Text(widget.selectedType?.name ?? '全部类型'),
                        selected: widget.selectedType != null,
                        onSelected: (_) => setState(() => _isExpanded = !_isExpanded),
                      ),
                      const SizedBox(width: 8),
                      if (widget.selectedCategory != null)
                        FilterChip(
                          label: Text(widget.selectedCategory!),
                          selected: true,
                          onSelected: (_) => widget.onCategoryChanged?.call(null),
                        ),
                      if (widget.showFavorites == true) ...[
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('⭐ 收藏'),
                          selected: true,
                          onSelected: (_) => widget.onFavoritesChanged?.call(null),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_hasActiveFilters)
                TextButton(
                  onPressed: widget.onClearFilters,
                  child: const Text('清除'),
                ),
            ],
          ),
        ),

        // 展开的筛选选项
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('🌐 网站'),
                  selected: widget.selectedType == CredentialType.website,
                  onSelected: (_) => _selectType(CredentialType.website),
                ),
                FilterChip(
                  label: const Text('📱 应用'),
                  selected: widget.selectedType == CredentialType.app,
                  onSelected: (_) => _selectType(CredentialType.app),
                ),
                FilterChip(
                  label: const Text('🔑 API'),
                  selected: widget.selectedType == CredentialType.api,
                  onSelected: (_) => _selectType(CredentialType.api),
                ),
                FilterChip(
                  label: const Text('🗄️ 数据库'),
                  selected: widget.selectedType == CredentialType.database,
                  onSelected: (_) => _selectType(CredentialType.database),
                ),
                FilterChip(
                  label: const Text('📶 WiFi'),
                  selected: widget.selectedType == CredentialType.wifi,
                  onSelected: (_) => _selectType(CredentialType.wifi),
                ),
                FilterChip(
                  label: const Text('🏦 银行'),
                  selected: widget.selectedType == CredentialType.bank,
                  onSelected: (_) => _selectType(CredentialType.bank),
                ),
                FilterChip(
                  label: const Text('💳 卡片'),
                  selected: widget.selectedType == CredentialType.card,
                  onSelected: (_) => _selectType(CredentialType.card),
                ),
              ],
            ),
          ),
      ],
    );
  }

  bool get _hasActiveFilters =>
      widget.selectedType != null ||
      widget.selectedCategory != null ||
      widget.showFavorites == true;

  void _selectType(CredentialType type) {
    widget.onTypeChanged?.call(widget.selectedType == type ? null : type);
  }
}

/// 批量操作栏组件
class CredentialActions extends StatelessWidget {
  final int selectedCount;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onExportSelected;
  final VoidCallback? onMoveSelected;
  final VoidCallback? onClearSelection;

  const CredentialActions({
    super.key,
    required this.selectedCount,
    this.onDeleteSelected,
    this.onExportSelected,
    this.onMoveSelected,
    this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Text(
              '已选择 $selectedCount 项',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            TextButton(
              onPressed: onClearSelection,
              child: const Text('取消'),
            ),
            const SizedBox(width: 8),
            if (onMoveSelected != null)
              OutlinedButton.icon(
                onPressed: onMoveSelected,
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('移动'),
              ),
            const SizedBox(width: 8),
            if (onExportSelected != null)
              OutlinedButton.icon(
                onPressed: onExportSelected,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('导出'),
              ),
            const SizedBox(width: 8),
            if (onDeleteSelected != null)
              FilledButton.icon(
                onPressed: onDeleteSelected,
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('删除'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 凭证搜索栏组件
class CredentialSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final String? hintText;

  const CredentialSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onClear,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText ?? '搜索凭证...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    controller?.clear();
                    onClear?.call();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}

/// 凭证列表组件
class CredentialList extends StatelessWidget {
  final List<CredentialModel> credentials;
  final void Function(CredentialModel)? onTap;
  final void Function(CredentialModel)? onCopy;
  final void Function(CredentialModel)? onEdit;
  final void Function(CredentialModel)? onDelete;
  final void Function(CredentialModel)? onFavorite;
  final Set<String>? selectedIds;
  final void Function(String)? onSelectionChanged;
  final bool selectionMode;

  const CredentialList({
    super.key,
    required this.credentials,
    this.onTap,
    this.onCopy,
    this.onEdit,
    this.onDelete,
    this.onFavorite,
    this.selectedIds,
    this.onSelectionChanged,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    if (credentials.isEmpty) {
      return const _EmptyCredentialView();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: credentials.length,
      itemBuilder: (context, index) {
        final credential = credentials[index];
        final isSelected = selectedIds?.contains(credential.id) ?? false;

        return Row(
          children: [
            if (selectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onSelectionChanged?.call(credential.id),
              ),
            Expanded(
              child: CredentialCard(
                credential: credential,
                onTap: () => selectionMode
                    ? onSelectionChanged?.call(credential.id)
                    : onTap?.call(credential),
                onCopy: () => onCopy?.call(credential),
                onEdit: () => onEdit?.call(credential),
                onDelete: () => onDelete?.call(credential),
                onFavorite: () => onFavorite?.call(credential),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 空状态视图
class _EmptyCredentialView extends StatelessWidget {
  const _EmptyCredentialView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无凭证',
            style: TextStyle(
              fontSize: 16,
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加第一个凭证',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// 凭证统计组件
class CredentialStats extends StatelessWidget {
  final int total;
  final int favorites;
  final Map<CredentialType, int> typeCounts;

  const CredentialStats({
    super.key,
    required this.total,
    required this.favorites,
    required this.typeCounts,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总计', total.toString(), Icons.lock),
          _buildStatItem('收藏', favorites.toString(), Icons.star),
          _buildStatItem('网站', (typeCounts[CredentialType.website] ?? 0).toString(), Icons.language),
          _buildStatItem('应用', (typeCounts[CredentialType.app] ?? 0).toString(), Icons.apps),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}