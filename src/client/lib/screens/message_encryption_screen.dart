import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 加密算法
enum EncryptionAlgorithm {
  aes256('AES-256-GCM', '高级加密标准', 256, '推荐'),
  aes128('AES-128-GCM', '标准加密', 128, '兼容'),
  chacha20('ChaCha20-Poly1305', '现代流密码', 256, '高性能'),
  rsa2048('RSA-2048', '非对称加密', 2048, '密钥交换');

  final String name;
  final String description;
  final int keySize;
  final String tag;

  const EncryptionAlgorithm(this.name, this.description, this.keySize, this.tag);
}

/// 加密状态
class EncryptionStatus {
  final bool isEnabled;
  final EncryptionAlgorithm algorithm;
  final DateTime? lastKeyRotation;
  final int encryptedMessages;
  final bool hasBackup;

  const EncryptionStatus({
    required this.isEnabled,
    required this.algorithm,
    this.lastKeyRotation,
    this.encryptedMessages = 0,
    this.hasBackup = false,
  });
}

/// 密钥信息
class KeyInfo {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final KeyStatus status;
  final bool isBackedUp;

  const KeyInfo({
    required this.id,
    required this.name,
    required this.createdAt,
    this.expiresAt,
    required this.status,
    this.isBackedUp = false,
  });
}

enum KeyStatus { active, expiring, expired, revoked }

/// 消息加密设置屏幕
class MessageEncryptionScreen extends StatefulWidget {
  const MessageEncryptionScreen({super.key});

  @override
  State<MessageEncryptionScreen> createState() => _MessageEncryptionScreenState();
}

class _MessageEncryptionScreenState extends State<MessageEncryptionScreen> {
  bool _encryptionEnabled = true;
  EncryptionAlgorithm _selectedAlgorithm = EncryptionAlgorithm.aes256;
  bool _autoKeyRotation = true;
  int _keyRotationDays = 30;
  
  // 密钥列表
  final List<KeyInfo> _keys = [
    KeyInfo(
      id: 'key_1',
      name: '主密钥',
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      status: KeyStatus.active,
      isBackedUp: true,
    ),
    KeyInfo(
      id: 'key_2',
      name: '备用密钥',
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      status: KeyStatus.active,
      isBackedUp: false,
    ),
  ];

  // 加密状态
  final EncryptionStatus _status = const EncryptionStatus(
    isEnabled: true,
    algorithm: EncryptionAlgorithm.aes256,
    lastKeyRotation: null,
    encryptedMessages: 1523,
    hasBackup: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息加密'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showEncryptionInfo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 加密状态卡片
          _buildStatusCard(),
          const SizedBox(height: 16),
          
          // 加密设置
          _buildSettingsSection(),
          const SizedBox(height: 16),
          
          // 密钥管理
          _buildKeyManagementSection(),
          const SizedBox(height: 16),
          
          // 密钥导入导出
          _buildKeyBackupSection(),
          const SizedBox(height: 16),
          
          // 端到端加密说明
          _buildE2EExplanation(),
        ],
      ),
    );
  }

  /// 加密状态卡片
  Widget _buildStatusCard() {
    return Card(
      color: _encryptionEnabled ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _encryptionEnabled ? Colors.green : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _encryptionEnabled ? Icons.lock : Icons.lock_open,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _encryptionEnabled ? '消息加密已启用' : '消息加密未启用',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _encryptionEnabled 
                          ? '您的消息正在受到保护'
                          : '启用加密以保护您的消息',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_encryptionEnabled) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusItem(
                    icon: Icons.message,
                    label: '已加密消息',
                    value: '${_status.encryptedMessages}',
                  ),
                  _buildStatusItem(
                    icon: Icons.enhanced_encryption,
                    label: '加密算法',
                    value: _selectedAlgorithm.name,
                  ),
                  _buildStatusItem(
                    icon: Icons.key,
                    label: '活动密钥',
                    value: '${_keys.where((k) => k.status == KeyStatus.active).length}',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.green, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// 加密设置区域
  Widget _buildSettingsSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.settings, size: 20),
                SizedBox(width: 8),
                Text(
                  '加密设置',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 启用加密开关
          SwitchListTile(
            title: const Text('启用消息加密'),
            subtitle: const Text('对所有消息进行端到端加密'),
            value: _encryptionEnabled,
            onChanged: (value) {
              setState(() => _encryptionEnabled = value);
            },
          ),
          const Divider(height: 1),
          // 加密算法选择
          ListTile(
            title: const Text('加密算法'),
            subtitle: Text('当前: ${_selectedAlgorithm.name}'),
            trailing: const Icon(Icons.chevron_right),
            enabled: _encryptionEnabled,
            onTap: _encryptionEnabled ? _showAlgorithmSelector : null,
          ),
          const Divider(height: 1),
          // 自动密钥轮换
          SwitchListTile(
            title: const Text('自动密钥轮换'),
            subtitle: Text('每 $_keyRotationDays 天自动更换密钥'),
            value: _autoKeyRotation,
            onChanged: _encryptionEnabled 
              ? (value) => setState(() => _autoKeyRotation = value)
              : null,
          ),
          if (_autoKeyRotation && _encryptionEnabled)
            ListTile(
              title: const Text('轮换周期'),
              subtitle: Text('$_keyRotationDays 天'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showRotationPeriodPicker,
            ),
        ],
      ),
    );
  }

  /// 密钥管理区域
  Widget _buildKeyManagementSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.key, size: 20, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  '密钥管理',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _generateNewKey,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('生成新密钥'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._keys.map((key) => _buildKeyItem(key)),
        ],
      ),
    );
  }

  Widget _buildKeyItem(KeyInfo key) {
    final statusColor = key.status == KeyStatus.active 
        ? Colors.green 
        : key.status == KeyStatus.expiring 
            ? Colors.orange 
            : Colors.red;

    return ExpansionTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.vpn_key,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Text(key.name),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key.status == KeyStatus.active ? '活动' : 
              key.status == KeyStatus.expiring ? '即将过期' : '已过期',
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        '创建于: ${_formatDate(key.createdAt)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _exportKey(key),
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('导出'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewKeyDetails(key),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('详情'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (key.status == KeyStatus.active && key.id != 'key_1')
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _revokeKey(key),
                    icon: const Icon(Icons.block, size: 18, color: Colors.red),
                    label: const Text('撤销密钥', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 密钥备份区域
  Widget _buildKeyBackupSection() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.backup, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '密钥导入导出',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导出所有密钥'),
            subtitle: const Text('创建密钥备份文件'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _exportAllKeys,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入密钥'),
            subtitle: const Text('从备份文件恢复密钥'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _importKey,
          ),
        ],
      ),
    );
  }

  /// 端到端加密说明
  Widget _buildE2EExplanation() {
    return Card(
      color: Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  '端到端加密说明',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildExplanationItem(
              icon: Icons.lock,
              title: '什么是端到端加密?',
              description: '端到端加密确保只有发送者和接收者可以读取消息内容，即使是服务提供商也无法解密。',
            ),
            const SizedBox(height: 12),
            _buildExplanationItem(
              icon: Icons.verified_user,
              title: '如何保护我的消息?',
              description: '使用 AES-256-GCM 等高级加密算法，配合密钥管理确保安全性。',
            ),
            const SizedBox(height: 12),
            _buildExplanationItem(
              icon: Icons.refresh,
              title: '密钥轮换',
              description: '定期轮换密钥可以进一步提高安全性，建议至少每30天更换一次。',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue[300]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 显示加密算法选择器
  void _showAlgorithmSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '选择加密算法',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '更长的密钥提供更强的安全性',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ...EncryptionAlgorithm.values.map((algo) => RadioListTile<EncryptionAlgorithm>(
              value: algo,
              groupValue: _selectedAlgorithm,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedAlgorithm = value);
                  Navigator.pop(context);
                }
              },
              title: Row(
                children: [
                  Text(algo.name),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      algo.tag,
                      style: const TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              subtitle: Text(algo.description),
            )),
          ],
        ),
      ),
    );
  }

  /// 显示轮换周期选择器
  void _showRotationPeriodPicker() {
    final periods = [7, 14, 30, 60, 90];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '密钥轮换周期',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...periods.map((days) => ListTile(
              title: Text('$days 天'),
              trailing: _keyRotationDays == days 
                ? const Icon(Icons.check, color: Colors.green)
                : null,
              onTap: () {
                setState(() => _keyRotationDays = days);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  /// 生成新密钥
  void _generateNewKey() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_circle, color: Colors.green),
            SizedBox(width: 12),
            Text('生成新密钥'),
          ],
        ),
        content: const Text('确定要生成新的加密密钥吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _keys.add(KeyInfo(
                  id: 'key_${DateTime.now().millisecondsSinceEpoch}',
                  name: '密钥 ${_keys.length + 1}',
                  createdAt: DateTime.now(),
                  status: KeyStatus.active,
                ));
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('新密钥已生成'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('生成'),
          ),
        ],
      ),
    );
  }

  /// 导出密钥
  void _exportKey(KeyInfo key) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('正在导出密钥: ${key.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 查看密钥详情
  void _viewKeyDetails(KeyInfo key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(key.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('ID', key.id),
            _detailRow('创建时间', _formatDate(key.createdAt)),
            _detailRow('状态', key.status.name),
            _detailRow('已备份', key.isBackedUp ? '是' : '否'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  /// 撤销密钥
  void _revokeKey(KeyInfo key) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('撤销密钥'),
        content: Text('确定要撤销密钥 "${key.name}" 吗？撤销后使用该密钥加密的消息将无法解密。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _keys.indexWhere((k) => k.id == key.id);
                if (index != -1) {
                  _keys[index] = KeyInfo(
                    id: key.id,
                    name: key.name,
                    createdAt: key.createdAt,
                    status: KeyStatus.revoked,
                    isBackedUp: key.isBackedUp,
                  );
                }
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('撤销'),
          ),
        ],
      ),
    );
  }

  /// 导出所有密钥
  void _exportAllKeys() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.backup, color: Colors.blue),
            SizedBox(width: 12),
            Text('导出密钥'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('导出密钥将创建一个加密的备份文件'),
            SizedBox(height: 12),
            Text('⚠️ 请妥善保存备份文件，丢失可能导致数据无法恢复', 
              style: TextStyle(color: Colors.orange, fontSize: 13)),
          ],
        ),
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
                  content: Text('密钥已导出'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('导出'),
          ),
        ],
      ),
    );
  }

  /// 导入密钥
  void _importKey() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('请选择要导入的密钥文件'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示加密信息
  void _showEncryptionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('关于消息加密'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PolyVault 使用行业标准的加密技术保护您的消息:'),
            SizedBox(height: 12),
            Text('• AES-256-GCM: 美国国家安全局批准'),
            Text('• ChaCha20-Poly1305: 高性能现代算法'),
            Text('• 端到端加密: 只有您能读取消息'),
            SizedBox(height: 12),
            Text('您的密钥安全存储在本地设备，从不发送到服务器。',
              style: TextStyle(fontStyle: FontStyle.italic)),
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

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}