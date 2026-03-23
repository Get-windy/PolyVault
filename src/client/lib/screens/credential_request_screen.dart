import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ecal_service.dart';

/// 凭证请求审批界面
class CredentialRequestScreen extends StatefulWidget {
  const CredentialRequestScreen({super.key});

  @override
  State<CredentialRequestScreen> createState() => _CredentialRequestScreenState();
}

class _CredentialRequestScreenState extends State<CredentialRequestScreen> {
  final EcalService _ecalService = EcalService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeEcal();
  }

  Future<void> _initializeEcal() async {
    setState(() => _isLoading = true);
    await _ecalService.initialize();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('凭证请求'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return StreamBuilder<CredentialRequest>(
      stream: _ecalService.credentialRequests,
      builder: (context, snapshot) {
        final requests = _ecalService.pendingCredentialRequests;
        
        if (requests.isEmpty) {
          return _buildEmptyState();
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            return _buildRequestCard(requests[index]);
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无待处理的凭证请求',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '当其他设备请求凭证时，将显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CredentialRequest request) {
    final timeLeft = request.expiresIn - DateTime.now().difference(request.timestamp).inSeconds;
    final isExpired = timeLeft <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isExpired
            ? BorderSide(color: Colors.red.shade200, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 头部：请求者信息
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.devices,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'ID: ${request.requesterId.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (request.requiresBiometric)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fingerprint, size: 16, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '需验证',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const Divider(height: 24),
            
            // 凭证类型
            Row(
              children: [
                Icon(Icons.vpn_key, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '请求类型: ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  _getCredentialTypeName(request.credentialType),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            
            if (request.siteName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.language, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '站点: ',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    request.siteName!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 12),
            
            // 倒计时
            Row(
              children: [
                Icon(
                  isExpired ? Icons.error_outline : Icons.access_time,
                  size: 20,
                  color: isExpired ? Colors.red : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired
                      ? '请求已过期'
                      : '剩余 ${_formatTimeLeft(timeLeft)}',
                  style: TextStyle(
                    color: isExpired ? Colors.red : Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            if (!isExpired)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close),
                      label: const Text('拒绝'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check),
                      label: const Text('批准'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getCredentialTypeName(String type) {
    switch (type) {
      case 'password':
        return '密码';
      case 'ssh_key':
        return 'SSH密钥';
      case 'api_token':
        return 'API令牌';
      case 'certificate':
        return '证书';
      default:
        return type;
    }
  }

  String _formatTimeLeft(int seconds) {
    if (seconds <= 0) return '0秒';
    if (seconds < 60) return '$seconds秒';
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes分$secs秒';
  }

  Future<void> _approveRequest(CredentialRequest request) async {
    final confirmed = await _showConfirmationDialog(
      title: '批准凭证请求',
      content: '确定要向 ${request.requesterName} 授权凭证吗？\n\n这将允许该设备访问您存储的${_getCredentialTypeName(request.credentialType)}。',
      confirmText: '批准',
    );

    if (confirmed != true) return;

    // TODO: 实际实现中需要从安全存储获取凭证
    final credential = {
      'type': request.credentialType,
      'site': request.siteName,
      'authorizedAt': DateTime.now().toIso8601String(),
    };

    setState(() => _isLoading = true);
    
    final success = await _ecalService.approveCredentialRequest(
      request.requestId,
      credential,
    );
    
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '凭证已授权' : '授权失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(CredentialRequest request) async {
    final confirmed = await _showConfirmationDialog(
      title: '拒绝凭证请求',
      content: '确定要拒绝 ${request.requesterName} 的凭证请求吗？',
      confirmText: '拒绝',
      isDestructive: true,
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    
    final success = await _ecalService.rejectCredentialRequest(request.requestId);
    
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '已拒绝请求' : '操作失败'),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDestructive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}