import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 配对设备信息
class PairedDevice {
  final String id;
  final String name;
  final String type;
  final String platform;
  final String? lastIp;
  final DateTime pairedAt;
  final DateTime? lastSeen;
  final PairingStatus status;
  final bool isTrusted;

  const PairedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.platform,
    this.lastIp,
    required this.pairedAt,
    this.lastSeen,
    required this.status,
    this.isTrusted = false,
  });

  PairedDevice copyWith({
    PairingStatus? status,
    bool? isTrusted,
  }) {
    return PairedDevice(
      id: id,
      name: name,
      type: type,
      platform: platform,
      lastIp: lastIp,
      pairedAt: pairedAt,
      lastSeen: lastSeen,
      status: status ?? this.status,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }
}

/// 配对状态
enum PairingStatus {
  connected,
  disconnected,
  pending,
  blocked,
}

/// 配对请求
class PairingRequest {
  final String deviceName;
  final String deviceType;
  final String deviceId;
  final String pairingCode;
  final DateTime createdAt;

  const PairingRequest({
    required this.deviceName,
    required this.deviceType,
    required this.deviceId,
    required this.pairingCode,
    required this.createdAt,
  });
}

/// 设备配对主屏幕
class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 已配对设备列表
  final List<PairedDevice> _pairedDevices = [
    PairedDevice(
      id: 'device_1',
      name: '我的iPhone 15 Pro',
      type: '手机',
      platform: 'iOS',
      lastIp: '192.168.1.101',
      pairedAt: DateTime.now().subtract(const Duration(days: 30)),
      lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      status: PairingStatus.connected,
      isTrusted: true,
    ),
    PairedDevice(
      id: 'device_2',
      name: 'MacBook Pro',
      type: '笔记本电脑',
      platform: 'macOS',
      lastIp: '192.168.1.102',
      pairedAt: DateTime.now().subtract(const Duration(days: 60)),
      lastSeen: DateTime.now().subtract(const Duration(hours: 2)),
      status: PairingStatus.connected,
      isTrusted: true,
    ),
    PairedDevice(
      name: 'iPad Air',
      id: 'device_3',
      type: '平板',
      platform: 'iPadOS',
      lastIp: '192.168.1.103',
      pairedAt: DateTime.now().subtract(const Duration(days: 15)),
      lastSeen: DateTime.now().subtract(const Duration(days: 1)),
      status: PairingStatus.disconnected,
      isTrusted: false,
    ),
  ];

  // 配对历史
  final List<Map<String, dynamic>> _pairingHistory = [
    {'action': '配对成功', 'device': '我的iPhone 15 Pro', 'time': DateTime.now().subtract(const Duration(days: 30))},
    {'action': '断开连接', 'device': '旧手机', 'time': DateTime.now().subtract(const Duration(days: 25))},
    {'action': '信任设备', 'device': 'MacBook Pro', 'time': DateTime.now().subtract(const Duration(days: 55))},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设备配对'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '扫码配对', icon: Icon(Icons.qr_code_scanner)),
            Tab(text: '手动输入', icon: Icon(Icons.keyboard)),
            Tab(text: '配对历史', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRPairingTab(),
          _buildManualPairingTab(),
          _buildPairingHistoryTab(),
        ],
      ),
    );
  }

  /// 扫码配对标签页
  Widget _buildQRPairingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 配对说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.phone_android, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    '扫码配对新设备',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '在要配对的设备上打开PolyVault，进入"设置 > 设备配对"，然后扫描下方二维码',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 二维码占位符 (实际应集成二维码扫描库)
          Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_2, size: 120, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('配对码', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PV-2024-ABC123',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 刷新按钮
          OutlinedButton.icon(
            onPressed: _refreshPairingCode,
            icon: const Icon(Icons.refresh),
            label: const Text('刷新配对码'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          // 配对状态提示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '配对码有效期5分钟，请在有效时间内完成扫描',
                    style: TextStyle(color: Colors.blue[700]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 手动输入配对码标签页
  Widget _buildManualPairingTab() {
    final codeController = TextEditingController();
    final nameController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.keyboard, size: 32, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '手动输入配对码',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '如果无法扫描二维码，可以在此手动输入配对码',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 配对码输入
            const Text(
              '配对码',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: codeController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                UpperCaseTextFormatter(),
                LengthLimitingTextInputFormatter(16),
              ],
              decoration: InputDecoration(
                hintText: '例如: PV-2024-ABC123',
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入配对码';
                }
                if (value.length < 8) {
                  return '配对码长度不足';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 设备名称输入
            const Text(
              '设备名称 (可选)',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: '例如: 我的MacBook',
                prefixIcon: const Icon(Icons.devices),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 配对按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _startPairing(codeController.text),
                icon: const Icon(Icons.link),
                label: const Text('开始配对'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 已配对设备列表
            const Text(
              '已配对设备',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...(_pairedDevices.map((device) => _buildPairedDeviceItem(device))),
          ],
        ),
      ),
    );
  }

  /// 配对历史标签页
  Widget _buildPairingHistoryTab() {
    if (_pairingHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              '暂无配对历史',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              '您的配对记录将显示在这里',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pairingHistory.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '共 ${_pairingHistory.length} 条记录',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          );
        }
        final item = _pairingHistory[index - 1];
        return _buildHistoryItem(item);
      },
    );
  }

  /// 配对历史项
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final action = item['action'] as String;
    final actionColor = action.contains('成功') || action.contains('信任') 
        ? Colors.green 
        : action.contains('断开') || action.contains('移除') 
            ? Colors.red 
            : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: actionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            action.contains('成功') ? Icons.check_circle : 
            action.contains('断开') ? Icons.link_off : 
            action.contains('信任') ? Icons.verified : Icons.history,
            color: actionColor,
            size: 20,
          ),
        ),
        title: Text(item['device'] as String),
        subtitle: Text(
          _formatTime(item['time'] as DateTime),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: actionColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            action,
            style: TextStyle(fontSize: 12, color: actionColor, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  /// 已配对设备项
  Widget _buildPairedDeviceItem(PairedDevice device) {
    final statusColor = device.status == PairingStatus.connected 
        ? Colors.green 
        : device.status == PairingStatus.pending 
            ? Colors.orange 
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _getDeviceIcon(device.type),
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Row(
          children: [
            Expanded(child: Text(device.name)),
            if (device.isTrusted)
              const Icon(Icons.verified, size: 16, color: Colors.blue),
          ],
        ),
        subtitle: Text(
          '${device.platform} • ${device.status == PairingStatus.connected ? "已连接" : "未连接"}',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'trust':
                _trustDevice(device);
                break;
              case 'block':
                _blockDevice(device);
                break;
              case 'remove':
                _removeDevice(device);
                break;
            }
          },
          itemBuilder: (context) => [
            if (!device.isTrusted)
              const PopupMenuItem(value: 'trust', child: Text('设为信任设备')),
            const PopupMenuItem(value: 'block', child: Text('阻止连接')),
            const PopupMenuItem(
              value: 'remove',
              child: Text('移除设备', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  /// 获取设备图标
  IconData _getDeviceIcon(String type) {
    switch (type) {
      case '手机':
        return Icons.smartphone;
      case '平板':
        return Icons.tablet_mac;
      case '笔记本电脑':
        return Icons.laptop;
      case '台式机':
        return Icons.desktop_windows;
      default:
        return Icons.devices;
    }
  }

  /// 格式化时间
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 30) {
      return '${diff.inDays}天前';
    } else {
      return '${time.month}月${time.day}日';
    }
  }

  /// 刷新配对码
  void _refreshPairingCode() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已生成新的配对码'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 开始配对
  void _startPairing(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _PairingProgressDialog(pairingCode: code),
    );
  }

  /// 信任设备
  void _trustDevice(PairedDevice device) {
    setState(() {
      final index = _pairedDevices.indexWhere((d) => d.id == device.id);
      if (index != -1) {
        _pairedDevices[index] = device.copyWith(isTrusted: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name} 已设为信任设备'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 阻止设备
  void _blockDevice(PairedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('阻止设备'),
        content: Text('确定要阻止 "${device.name}" 吗？阻止后将无法连接。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                final index = _pairedDevices.indexWhere((d) => d.id == device.id);
                if (index != -1) {
                  _pairedDevices[index] = device.copyWith(status: PairingStatus.blocked);
                }
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('阻止'),
          ),
        ],
      ),
    );
  }

  /// 移除设备
  void _removeDevice(PairedDevice device) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除设备'),
        content: Text('确定要移除 "${device.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _pairedDevices.removeWhere((d) => d.id == device.id);
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }
}

/// 配对进度对话框
class _PairingProgressDialog extends StatefulWidget {
  final String pairingCode;

  const _PairingProgressDialog({required this.pairingCode});

  @override
  State<_PairingProgressDialog> createState() => _PairingProgressDialogState();
}

class _PairingProgressDialogState extends State<_PairingProgressDialog> {
  int _step = 0;
  final List<String> _steps = [
    '正在连接...',
    '验证设备...',
    '确认配对...',
    '配对成功!',
  ];

  @override
  void initState() {
    super.initState();
    _simulatePairing();
  }

  Future<void> _simulatePairing() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        setState(() => _step = i);
      }
    }
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设备配对成功!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.link, color: Colors.blue),
          const SizedBox(width: 12),
          const Text('设备配对'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度指示器
          LinearProgressIndicator(
            value: (_step + 1) / _steps.length,
            backgroundColor: Colors.grey[200],
          ),
          const SizedBox(height: 24),
          // 步骤列表
          ...List.generate(_steps.length, (index) {
            final isActive = index == _step;
            final isCompleted = index < _step;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isCompleted ? Icons.check_circle : 
                    isActive ? Icons.radio_button_checked : 
                    Icons.circle_outlined,
                    color: isCompleted ? Colors.green : 
                    isActive ? Colors.blue : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _steps[index],
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      color: isActive ? Colors.blue : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// 大写输入格式化
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}