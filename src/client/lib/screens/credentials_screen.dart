import 'package:flutter/material.dart';
import '../services/secure_storage.dart';
import '../widgets/credential_list_item.dart';

/// 凭证管理页
class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  List<CredentialSummary> _credentials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    try {
      final storage = SecureStorageService();
      final credentials = await storage.getCredentialList();

      setState(() {
        _credentials = credentials;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载凭证失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '凭证管理',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: 实现搜索功能
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _credentials.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadCredentials,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _credentials.length,
                    itemBuilder: (context, index) {
                      final credential = _credentials[index];
                      return CredentialListItem(
                        credential: credential,
                        onTap: () => _showCredentialDetail(credential),
                        onDelete: () => _deleteCredential(credential),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCredentialDialog(),
        icon: const Icon(Icons.add),
        label: const Text('添加凭证'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.vpn_key_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无凭证',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加您的第一个凭证',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddCredentialDialog(),
            icon: const Icon(Icons.add),
            label: const Text('添加凭证'),
          ),
        ],
      ),
    );
  }

  void _showCredentialDetail(CredentialSummary credential) async {
    try {
      final storage = SecureStorageService();
      final fullCredential = await storage.getCredential(
        credential.id,
        requireBiometric: true,
      );

      if (fullCredential == null) return;

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(fullCredential.serviceName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('用户名', fullCredential.username),
                const SizedBox(height: 12),
                _buildDetailRow('密码', fullCredential.password, isPassword: true),
                if (fullCredential.notes != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow('备注', fullCredential.notes!),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
              FilledButton(
                onPressed: () {
                  // TODO: 复制密码到剪贴板
                  Navigator.pop(context);
                },
                child: const Text('复制密码'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取凭证详情失败: $e')),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isPassword ? '••••••••' : value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showAddCredentialDialog() {
    final formKey = GlobalKey<FormState>();
    String serviceName = '';
    String username = '';
    String password = '';
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加凭证'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '服务名称',
                    hintText: '例如: GitHub, AWS, Google',
                    prefixIcon: Icon(Icons.business),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入服务名称';
                    }
                    return null;
                  },
                  onSaved: (value) => serviceName = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '用户名',
                    hintText: '您的登录账号',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    return null;
                  },
                  onSaved: (value) => username = value!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: '密码',
                    hintText: '您的登录密码',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '