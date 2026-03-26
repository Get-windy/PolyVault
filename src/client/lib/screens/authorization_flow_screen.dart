import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/enhanced_animations.dart';

/// 授权流程 UI
/// 包含授权请求处理、自动授权规则管理、授权历史等功能

/// 授权请求状态
enum AuthorizationStatus {
  pending,
  approved,
  rejected,
  expired,
}

/// 授权请求
class AuthorizationRequest {
  final String id;
  final String deviceName;
  final String deviceType;
  final String credentialName;
  final String requestType; // 'read', 'write', 'export'
  final DateTime createdAt;
  final DateTime? expiresAt;
  AuthorizationStatus status;
  String? reason;
  bool requiresBiometric;

  AuthorizationRequest({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.credentialName,
    required this.requestType,
    required this.createdAt,
    this.expiresAt,
    this.status = AuthorizationStatus.pending,
    this.reason,
    this.requiresBiometric = false,
  });

  String get requestTypeText {
    switch (requestType) {
      case 'read':
        return '读取';
      case 'write':
        return '写入';
      case 'export':
        return '导出';
      default:
        return '访问';
    }
  }

  IconData get requestTypeIcon {
    switch (requestType) {
      case 'read':
        return Icons.visibility;
      case 'write':
        return Icons.edit;
      case 'export':
        return Icons.download;
      default:
        return Icons.vpn_key;
    }
  }

  Color get statusColor {
    switch (status) {
      case AuthorizationStatus.pending:
        return Colors.orange;
      case AuthorizationStatus.approved:
        return Colors.green;
      case AuthorizationStatus.rejected:
        return Colors.red;
      case AuthorizationStatus.expired:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case AuthorizationStatus.pending:
        return '待处理';
      case AuthorizationStatus.approved:
        return '已批准';
      case AuthorizationStatus.rejected:
        return '已拒绝';
      case AuthorizationStatus.expired:
        return '已过期';
    }
  }
}

/// 授权请求状态管理
final authorizationRequestsProvider =
    StateNotifierProvider<AuthorizationRequestsNotifier, List<AuthorizationRequest>>((ref) {
  return AuthorizationRequestsNotifier();
});

class AuthorizationRequestsNotifier extends StateNotifier<List<AuthorizationRequest>> {
  AuthorizationRequestsNotifier() : super([]) {
    _loadMockData();
  }

  void _loadMockData() {
    state = [
      AuthorizationRequest(
        id: 'req_1',
        deviceName: 'MacBook Pro',
        deviceType: 'laptop',
        credentialName: 'GitHub 账户',
        requestType: 'read',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        expiresAt: DateTime.now().add(const Duration(minutes: 25)),
        requiresBiometric: true,
      ),
      AuthorizationRequest(
        id: 'req_2',
        deviceName: 'iPhone 15 Pro',
        deviceType: 'phone',
        credentialName: '公司邮箱',
        requestType: 'write',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: AuthorizationStatus.approved,
      ),
      AuthorizationRequest(
        id: 'req_3',
        deviceName: 'Windows 台式机',
        deviceType: 'desktop',
        credentialName: '服务器 SSH',
        requestType: 'export',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: AuthorizationStatus.rejected,
        reason: '安全策略不允许导出敏感凭证',
      ),
    ];
  }

  void approveRequest(String id) {
    state = state.map((req) {
      if (req.id == id) {
        return AuthorizationRequest(
          id: req.id,
          deviceName: req.deviceName,
          deviceType: req.deviceType,
          credentialName: req.credentialName,
          requestType: req.requestType,
          createdAt: req.createdAt,
          expiresAt: req.expiresAt,
          status: AuthorizationStatus.approved,
          requiresBiometric: req.requiresBiometric,
        );
      }
      return req;
    }).toList();
  }

  void rejectRequest(String id, String? reason) {
    state = state.map((req) {
      if (req.id == id) {
        return AuthorizationRequest(
          id: req.id,
          deviceName: req.deviceName,
          deviceType: req.deviceType,
          credentialName: req.credentialName,
          requestType: req.requestType,
          createdAt: req.createdAt,
          expiresAt: req.expiresAt,
          status: AuthorizationStatus.rejected,
          reason: reason,
          requiresBiometric: req.requiresBiometric,
        );
      }
      return req;
    }).toList();
  }

  void addRequest(AuthorizationRequest request) {
    state = [request, ...state];
  }

  void clearExpired() {
    state = state.where((req) => req.status != AuthorizationStatus.expired).toList();
  }
}

/// 授权中心主界面
class AuthorizationCenterScreen extends ConsumerStatefulWidget {
  const AuthorizationCenterScreen({super.key});

  @override
  ConsumerState<AuthorizationCenterScreen> createState() => _AuthorizationCenterScreenState();
}

class _AuthorizationCenterScreenState extends ConsumerState<AuthorizationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final requests = ref.watch(authorizationRequestsProvider);
    final pendingCount = requests.where((r) => r.status == AuthorizationStatus.pending).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('授权中心'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(),
            tooltip: '授权历史',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: '待处理',
              icon: Badge(
                label: Text('$pendingCount'),
                isLabelVisible: pendingCount > 0,
                child: const Icon(Icons.pending_actions),
              ),
            ),
            const Tab(text: '自动规则', icon: Icon(Icons.auto_fix_high)),
            const Tab(text: '设置', icon: Icon(Icons.settings)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PendingRequestsTab(),
          _AutoRulesTab(),
          _AuthorizationSettingsTab(),
        ],
      ),
    );
  }

  void _showHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthorizationHistoryScreen()),
    );
  }
}

/// 待处理请求标签页
class _PendingRequestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(authorizationRequestsProvider);
    final pendingRequests = requests.where((r) => r.status == AuthorizationStatus.pending).toList();

    if (pendingRequests.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingRequests.length,
      itemBuilder: (context, index) {
        return StaggeredListAnimation(
          index: index,
          child: _AuthorizationRequestCard(request: pendingRequests[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleBounce(
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            offset: const Offset(0, 20),
            child: Text(
              '没有待处理的请求',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeSlideIn(
            offset: const Offset(0, 20),
            delay: const Duration(milliseconds: 100),
            child: Text(
              '所有授权请求都已处理完毕',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 授权请求卡片
class _AuthorizationRequestCard extends ConsumerWidget {
  final AuthorizationRequest request;

  const _AuthorizationRequestCard({required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: request.statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: request.statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: request.statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    request.requestTypeIcon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.credentialName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: request.statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              request.requestTypeText,
                              style: TextStyle(
                                fontSize: 12,
                                color: request.statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(request.createdAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (request.requiresBiometric)
                  Tooltip(
                    message: '需要生物识别验证',
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fingerprint, color: Colors.purple, size: 20),
                    ),
                  ),
              ],
            ),
          ),
          // 请求详情
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(Icons.devices, '请求设备', request.deviceName),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.schedule, '过期时间', _formatExpiry(request.expiresAt)),
                if (request.reason != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.info_outline, '备注', request.reason!),
                ],
              ],
            ),
          ),
          // 操作按钮
          if (request.status == AuthorizationStatus.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(context, ref),
                      icon: const Icon(Icons.close, color: Colors.red),
                      label: const Text('拒绝', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _approve(context, ref),
                      icon: const Icon(Icons.check),
                      label: const Text('批准'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    }
    return '${diff.inDays}天前';
  }

  String _formatExpiry(DateTime? expiry) {
    if (expiry == null) return '无限制';
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return '已过期';
    return '${diff.inMinutes}分钟后过期';
  }

  void _approve(BuildContext context, WidgetRef ref) {
    if (request.requiresBiometric) {
      _showBiometricDialog(context, ref);
    } else {
      ref.read(authorizationRequestsProvider.notifier).approveRequest(request.id);
      _showSuccessSnackBar(context, '已批准授权请求');
    }
  }

  void _showBiometricDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.fingerprint, color: Colors.purple),
            SizedBox(width: 12),
            Text('生物识别验证'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fingerprint, size: 80, color: Colors.purple),
            SizedBox(height: 16),
            Text('请验证您的身份以完成授权'),
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
              ref.read(authorizationRequestsProvider.notifier).approveRequest(request.id);
              _showSuccessSnackBar(context, '验证成功，已批准授权请求');
            },
            child: const Text('验证'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 12),
            Text('拒绝授权'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('确定要拒绝此授权请求吗？'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '拒绝原因（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
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
              ref.read(authorizationRequestsProvider.notifier).rejectRequest(
                    request.id,
                    reasonController.text.isNotEmpty ? reasonController.text : null,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已拒绝授权请求'), behavior: SnackBarBehavior.floating),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('拒绝'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// 自动规则标签页
class _AutoRulesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildRuleCard(
          context,
          icon: Icons.verified_user,
          iconColor: Colors.green,
          title: '可信设备自动授权',
          subtitle: '在已标记为可信的设备上自动批准读取请求',
          isEnabled: true,
          condition: '可信设备',
          action: '自动批准',
        ),
        const SizedBox(height: 12),
        _buildRuleCard(
          context,
          icon: Icons.schedule,
          iconColor: Colors.blue,
          title: '工作时间自动授权',
          subtitle: '在工作时间段（9:00-18:00）自动批准所有请求',
          isEnabled: true,
          condition: '时间段: 09:00 - 18:00',
          action: '自动批准',
        ),
        const SizedBox(height: 12),
        _buildRuleCard(
          context,
          icon: Icons.location_on,
          iconColor: Colors.purple,
          title: '安全地点自动授权',
          subtitle: '在公司网络环境下自动批准访问',
          isEnabled: false,
          condition: '地点: 公司网络',
          action: '需要确认',
        ),
        const SizedBox(height: 24),
        // 添加规则按钮
        FilledButton.icon(
          onPressed: () => _showAddRuleDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('添加规则'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required String condition,
    required String action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled ? iconColor.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // 头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isEnabled ? iconColor.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isEnabled ? iconColor.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isEnabled ? iconColor : Colors.grey, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isEnabled ? null : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: (value) {},
                  activeColor: iconColor,
                ),
              ],
            ),
          ),
          // 详情
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildDetailChip(Icons.rule, condition, Colors.blue),
                const SizedBox(width: 8),
                _buildDetailChip(Icons.flash_on, action, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
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
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '添加自动授权规则',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('触发条件', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('可信设备'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('时间段'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('安全地点'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('凭证类型'), selected: false, onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: 24),
            const Text('执行动作', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(label: const Text('自动批准'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('生物识别后批准'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('仅通知'), selected: false, onSelected: (_) {}),
                FilterChip(label: const Text('需要确认'), selected: false, onSelected: (_) {}),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('创建规则'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置标签页
class _AuthorizationSettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingSection('安全设置', [
          _buildSettingTile(
            icon: Icons.fingerprint,
            iconColor: Colors.purple,
            title: '所有请求需要生物识别',
            subtitle: '每次授权都需要验证身份',
            value: false,
          ),
          _buildSettingTile(
            icon: Icons.lock,
            iconColor: Colors.red,
            title: '敏感凭证需要二次确认',
            subtitle: '银行卡、密码等重要凭证',
            value: true,
          ),
          _buildSettingTile(
            icon: Icons.timer,
            iconColor: Colors.orange,
            title: '授权有效期',
            subtitle: '默认30分钟',
            value: true,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingSection('通知设置', [
          _buildSettingTile(
            icon: Icons.notifications,
            iconColor: Colors.blue,
            title: '接收授权请求通知',
            subtitle: '有新请求时推送通知',
            value: true,
          ),
          _buildSettingTile(
            icon: Icons.volume_up,
            iconColor: Colors.green,
            title: '授权成功通知',
            subtitle: '授权被批准或拒绝时通知',
            value: true,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingSection('其他', [
          _buildSettingTile(
            icon: Icons.auto_delete,
            iconColor: Colors.grey,
            title: '自动清理过期请求',
            subtitle: '每天自动删除过期请求',
            value: true,
          ),
        ]),
      ],
    );
  }

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(value: value, onChanged: (_) {}),
        ],
      ),
    );
  }
}

/// 授权历史界面
class AuthorizationHistoryScreen extends StatelessWidget {
  const AuthorizationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('授权历史'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 20,
        itemBuilder: (context, index) {
          return _buildHistoryItem(context, index);
        },
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, int index) {
    final statuses = [AuthorizationStatus.approved, AuthorizationStatus.rejected];
    final status = statuses[index % 2];
    final isApproved = status == AuthorizationStatus.approved;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isApproved ? Icons.check : Icons.close,
            color: isApproved ? Colors.green : Colors.red,
          ),
        ),
        title: Text('GitHub 账户'),
        subtitle: Text('${isApproved ? "已批准" : "已拒绝"} · MacBook Pro'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${index + 1}小时前',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isApproved ? Colors.green : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isApproved ? '批准' : '拒绝',
                style: TextStyle(
                  fontSize: 11,
                  color: isApproved ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}