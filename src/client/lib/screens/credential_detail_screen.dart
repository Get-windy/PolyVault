import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/secure_storage.dart';

/// 凭证详情页面 - 查看和编辑凭证
class CredentialDetailScreen extends StatefulWidget {
  final String credentialId;
  final CredentialSummary? summary;

  const CredentialDetailScreen({
    super.key,
    required this.credentialId,
    this.summary,
  });

  @override
  State<CredentialDetailScreen> createState() => _CredentialDetailScreenState();
}

class _CredentialDetailScreenState extends State<CredentialDetailScreen> {
  Credential? _credential;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _showPassword = false;
  bool _requireBiometric = true;

  // 编辑表单控制器
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serviceNameController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _serviceNameController = TextEditingController();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _notesController = TextEditingController();
    _loadCredential();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCredential() async {
    setState(() => _isLoading = true);

    try {
      final storage = SecureStorageService();
      final credential = await storage.getCredential(
        widget.credentialId,
        requireBiometric: _requireBiometric,
      );

      if (credential != null) {
        setState(() {
          _credential = credential;
          _serviceNameController.text = credential.serviceName;
          _usernameController.text = credential.username;
          _passwordController.text = credential.password;
          _notesController.text = credential.notes ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('凭证不存在')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载凭证失败: $e')),
        );
      }
    }
  }

  Future<void> _saveCredential() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final storage = SecureStorageService();
      await storage.updateCredential(
        id: widget.credentialId,
        serviceName: _serviceNameController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      setState(() {
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('凭证已更新')),
        );
      }

      // 重新加载凭证
      await _loadCredential();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  Future<void> _deleteCredential() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 ${_credential?.serviceName ?? "此凭证"} 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final storage = SecureStorageService();
      await storage.deleteCredential(widget.credentialId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('凭证已删除')),
        );
        Navigator.pop(context, true); // 返回 true 表示已删除
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败: $e')),
        );
      }
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label 已复制到剪贴板'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: '清除',
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: ''));
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑凭证' : '凭证详情'),
        actions: [
          if (!_isLoading && _credential != null) ...[
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveCredential,
                tooltip: '保存',
              )
            else
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: '编辑',
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteCredential();
                    break;
                  case 'share':
                    // TODO: 实现安全分享
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('删除凭证'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('安全分享'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _credential == null
              ? _buildErrorState()
              : _isEditing
                  ? _buildEditForm()
                  : _buildDetailView(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('无法加载凭证'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadCredential,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 服务信息卡片
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // 服务图标和名称
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            _credential!.serviceName.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _credential!.serviceName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '创建于 ${_formatDate(_credential!.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 账号信息
          _buildInfoSection('账号信息', [
            _buildInfoItem(
              icon: Icons.person,
              label: '用户名',
              value: _credential!.username,
              canCopy: true,
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              icon: Icons.lock,
              label: '密码',
              value: _credential!.password,
              isPassword: true,
              canCopy: true,
            ),
          ]),

          // 备注（如果有）
          if (_credential!.notes != null && _credential!.notes!.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildInfoSection('备注', [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _credential!.notes!,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ]),
          ],

          // 时间信息
          const SizedBox(height: 24),
          _buildInfoSection('时间信息', [
            _buildTimeRow('创建时间', _credential!.createdAt),
            const SizedBox(height: 8),
            _buildTimeRow('更新时间', _credential!.updatedAt),
          ]),

          const SizedBox(height: 32),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit),
                  label: const Text('编辑'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _deleteCredential,
                  icon: const Icon(Icons.delete),
                  label: const Text('删除'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    bool isPassword = false,
    bool canCopy = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPassword && !_showPassword ? '••••••••' : value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: () => _copyToClipboard(value, label),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time) {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ${_formatDateTime(time)}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 服务名称
          TextFormField(
            controller: _serviceNameController,
            decoration: const InputDecoration(
              labelText: '服务名称',
              prefixIcon: Icon(Icons.business),
              hintText: '例如: GitHub, AWS, Google',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入服务名称';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 用户名
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: '用户名',
              prefixIcon: Icon(Icons.person),
              hintText: '您的登录账号',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入用户名';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 密码
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: '密码',
              prefixIcon: const Icon(Icons.lock),
              hintText: '您的登录密码',
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            obscureText: !_showPassword,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '请输入密码';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 备注
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: '备注（可选）',
              prefixIcon: Icon(Icons.notes),
              hintText: '添加说明信息',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 32),

          // 保存按钮
          FilledButton(
            onPressed: _saveCredential,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('保存更改'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => setState(() => _isEditing = false),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text('取消'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}