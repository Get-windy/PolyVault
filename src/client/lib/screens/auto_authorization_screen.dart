import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 自动授权规则数据模型
class AutoAuthRule {
  String id;
  String name;
  String description;
  bool isEnabled;
  AutoAuthCondition condition;
  AutoAuthAction action;
  DateTime createdAt;
  DateTime? lastTriggeredAt;
  int triggerCount;

  AutoAuthRule({
    required this.id,
    required this.name,
    required this.description,
    this.isEnabled = true,
    required this.condition,
    required this.action,
    required this.createdAt,
    this.lastTriggeredAt,
    this.triggerCount = 0,
  });
}

/// 自动授权条件
class AutoAuthCondition {
  String type; // 'trusted_device', 'time_range', 'location', 'credential_type'
  Map<String, dynamic> params;

  AutoAuthCondition({
    required this.type,
    required this.params,
  });

  String get displayText {
    switch (type) {
      case 'trusted_device':
        return '可信设备';
      case 'time_range':
        final start = params['start_time'] ?? '09:00';
        final end = params['end_time'] ?? '18:00';
        return '时间段: $start - $end';
      case 'location':
        return '安全地点: ${params['location_name'] ?? '未知'}';
      case 'credential_type':
        final types = (params['types'] as List<dynamic>?)?.join(', ') ?? '所有类型';
        return '凭证类型: $types';
      default:
        return '未知条件';
    }
  }
}

/// 自动授权动作
class AutoAuthAction {
  String type; // 'allow', 'allow_with_biometric', 'notify', 'require_confirmation'
  Map<String, dynamic> params;

  AutoAuthAction({
    required this.type,
    this.params = const {},
  });

  String get displayText {
    switch (type) {
      case 'allow':
        return '自动允许';
      case 'allow_with_biometric':
        return '生物识别后允许';
      case 'notify':
        return '仅通知';
      case 'require_confirmation':
        return '需要确认';
      default:
        return '未知动作';
    }
  }

  IconData get icon {
    switch (type) {
      case 'allow':
        return Icons.check_circle;
      case 'allow_with_biometric':
        return Icons.fingerprint;
      case 'notify':
        return Icons.notifications;
      case 'require_confirmation':
        return Icons.help;
      default:
        return Icons.device_unknown;
    }
  }

  Color get color {
    switch (type) {
      case 'allow':
        return Colors.green;
      case 'allow_with_biometric':
        return Colors.blue;
      case 'notify':
        return Colors.orange;
      case 'require_confirmation':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}

/// 自动授权规则状态管理
final autoAuthRulesProvider = StateNotifierProvider<AutoAuthRulesNotifier, List<AutoAuthRule>>((ref) {
  return AutoAuthRulesNotifier();
});

class AutoAuthRulesNotifier extends StateNotifier<List<AutoAuthRule>> {
  AutoAuthRulesNotifier() : super([]) {
    _loadRules();
  }

  void _loadRules() {
    // 模拟加载默认规则
    state = [
      AutoAuthRule(
        id: 'rule_1',
        name: '可信设备自动授权',
        description: '在已标记为可信的设备上自动授权访问',
        isEnabled: true,
        condition: AutoAuthCondition(
          type: 'trusted_device',
          params: {'trusted': true},
        ),
        action: AutoAuthAction(
          type: 'allow_with_biometric',
          params: {},
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastTriggeredAt: DateTime.now().subtract(const Duration(hours: 2)),
        triggerCount: 156,
      ),
      AutoAuthRule(
        id: 'rule_2',
        name: '工作时间自动授权',
        description: '在工作时间段内（9:00-18:00）自动授权',
        isEnabled: true,
        condition: AutoAuthCondition(
          type: 'time_range',
          params: {'start_time': '09:00', 'end_time': '18:00'},
        ),
        action: AutoAuthAction(
          type: 'allow',
          params: {},
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        lastTriggeredAt: DateTime.now().subtract(const Duration(hours: 5)),
        triggerCount: 89,
      ),
      AutoAuthRule(
        id: 'rule_3',
        name: '社交凭证访问通知',
        description: '访问社交类凭证时发送通知',
        isEnabled: false,
        condition: AutoAuthCondition(
          type: 'credential_type',
          params: {'types': ['social', 'messaging']},
        ),
        action: AutoAuthAction(
          type: 'notify',
          params: {'notify_type': 'push'},
        ),
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        triggerCount: 0,
      ),
    ];
  }

  void addRule(AutoAuthRule rule) {
    state = [...state, rule];
  }

  void updateRule(AutoAuthRule updatedRule) {
    state = state.map((rule) => rule.id == updatedRule.id ? updatedRule : rule).toList();
  }

  void deleteRule(String id) {
    state = state.where((rule) => rule.id != id).toList();
  }

  void toggleRule(String id) {
    state = state.map((rule) {
      if (rule.id == id) {
        return AutoAuthRule(
          id: rule.id,
          name: rule.name,
          description: rule.description,
          isEnabled: !rule.isEnabled,
          condition: rule.condition,
          action: rule.action,
          createdAt: rule.createdAt,
          lastTriggeredAt: rule.lastTriggeredAt,
          triggerCount: rule.triggerCount,
        );
      }
      return rule;
    }).toList();
  }
}

/// 自动授权规则配置页面
class AutoAuthorizationScreen extends ConsumerWidget {
  const AutoAuthorizationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(autoAuthRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '自动授权规则',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRuleDialog(context, ref),
            tooltip: '添加规则',
          ),
        ],
      ),
      body: rules.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              itemBuilder: (context, index) {
                final rule = rules[index];
                return _buildRuleCard(context, ref, rule);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRuleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('添加规则'),
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_fix_high,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无自动授权规则',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加规则来自动化处理凭证访问请求',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建规则卡片
  Widget _buildRuleCard(BuildContext context, WidgetRef ref, AutoAuthRule rule) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // 规则头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: rule.isEnabled ? colorScheme.primaryContainer : Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  rule.action.icon,
                  color: rule.isEnabled ? colorScheme.onPrimaryContainer : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rule.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: rule.isEnabled ? colorScheme.onPrimaryContainer : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        rule.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: rule.isEnabled ? colorScheme.onPrimaryContainer.withOpacity(0.7) : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: rule.isEnabled,
                  onChanged: (_) => ref.read(autoAuthRulesProvider.notifier).toggleRule(rule.id),
                ),
              ],
            ),
          ),
          // 规则详情
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow(
                  icon: Icons.rule,
                  label: '条件',
                  value: rule.condition.displayText,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: rule.action.icon,
                  label: '动作',
                  value: rule.action.displayText,
                  valueColor: rule.action.color,
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                  icon: Icons.bar_chart,
                  label: '触发次数',
                  value: '${rule.triggerCount} 次',
                ),
                if (rule.lastTriggeredAt != null) ...[
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    icon: Icons.schedule,
                    label: '上次触发',
                    value: _formatDateTime(rule.lastTriggeredAt!),
                  ),
                ],
              ],
            ),
          ),
          // 操作按钮
          ButtonBar(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('编辑'),
                onPressed: () => _showEditRuleDialog(context, ref, rule),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('删除'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => _showDeleteConfirmDialog(context, ref, rule),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} 分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} 小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} 天前';
    } else {
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  /// 显示添加规则对话框
  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const AddRuleSheet(),
    );
  }

  /// 显示编辑规则对话框
  void _showEditRuleDialog(BuildContext context, WidgetRef ref, AutoAuthRule rule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AddRuleSheet(existingRule: rule),
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref, AutoAuthRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除规则 "${rule.name}" 吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              ref.read(autoAuthRulesProvider.notifier).deleteRule(rule.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('规则已删除')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

/// 添加/编辑规则底部表单
class AddRuleSheet extends ConsumerStatefulWidget {
  final AutoAuthRule? existingRule;

  const AddRuleSheet({super.key, this.existingRule});

  @override
  ConsumerState<AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends ConsumerState<AddRuleSheet> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String _conditionType = 'trusted_device';
  String _actionType = 'allow';
  Map<String, dynamic> _conditionParams = {};
  Map<String, dynamic> _actionParams = {};

  // 时间范围控制器
  final _startTimeController = TextEditingController(text: '09:00');
  final _endTimeController = TextEditingController(text: '18:00');
  final _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingRule != null) {
      _nameController.text = widget.existingRule!.name;
      _descController.text = widget.existingRule!.description;
      _conditionType = widget.existingRule!.condition.type;
      _conditionParams = Map.from(widget.existingRule!.condition.params);
      _actionType = widget.existingRule!.action.type;
      _actionParams = Map.from(widget.existingRule!.action.params);

      if (_conditionType == 'time_range') {
        _startTimeController.text = _conditionParams['start_time'] ?? '09:00';
        _endTimeController.text = _conditionParams['end_time'] ?? '18:00';
      } else if (_conditionType == 'location') {
        _locationController.text = _conditionParams['location_name'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.existingRule != null ? '编辑规则' : '添加新规则',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 规则名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '规则名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 规则描述
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '规则描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // 条件类型选择
            const Text('触发条件', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('可信设备'),
                  selected: _conditionType == 'trusted_device',
                  onSelected: (s) => setState(() => _conditionType = 'trusted_device'),
                ),
                ChoiceChip(
                  label: const Text('时间段'),
                  selected: _conditionType == 'time_range',
                  onSelected: (s) => setState(() => _conditionType = 'time_range'),
                ),
                ChoiceChip(
                  label: const Text('安全地点'),
                  selected: _conditionType == 'location',
                  onSelected: (s) => setState(() => _conditionType = 'location'),
                ),
                ChoiceChip(
                  label: const Text('凭证类型'),
                  selected: _conditionType == 'credential_type',
                  onSelected: (s) => setState(() => _conditionType = 'credential_type'),
                ),
              ],
            ),

            // 条件参数
            if (_conditionType == 'time_range') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startTimeController,
                      decoration: const InputDecoration(
                        labelText: '开始时间',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _endTimeController,
                      decoration: const InputDecoration(
                        labelText: '结束时间',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_conditionType == 'location') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: '地点名称',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.location_on),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 动作类型选择
            const Text('执行动作', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('自动允许'),
                  selected: _actionType == 'allow',
                  onSelected: (s) => setState(() => _actionType = 'allow'),
                ),
                ChoiceChip(
                  label: const Text('生物识别后允许'),
                  selected: _actionType == 'allow_with_biometric',
                  onSelected: (s) => setState(() => _actionType = 'allow_with_biometric'),
                ),
                ChoiceChip(
                  label: const Text('仅通知'),
                  selected: _actionType == 'notify',
                  onSelected: (s) => setState(() => _actionType = 'notify'),
                ),
                ChoiceChip(
                  label: const Text('需要确认'),
                  selected: _actionType == 'require_confirmation',
                  onSelected: (s) => setState(() => _actionType = 'require_confirmation'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRule,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(widget.existingRule != null ? '保存修改' : '创建规则'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRule() {
    final name = _nameController.text.trim();
    final desc = _descController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入规则名称')),
      );
      return;
    }

    // 构建条件参数
    Map<String, dynamic> conditionParams = {};
    switch (_conditionType) {
      case 'time_range':
        conditionParams = {
          'start_time': _startTimeController.text,
          'end_time': _endTimeController.text,
        };
        break;
      case 'location':
        conditionParams = {'location_name': _locationController.text};
        break;
      case 'trusted_device':
        conditionParams = {'trusted': true};
        break;
      default:
        conditionParams = {};
    }

    final rule = AutoAuthRule(
      id: widget.existingRule?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: desc,
      condition: AutoAuthCondition(
        type: _conditionType,
        params: conditionParams,
      ),
      action: AutoAuthAction(
        type: _actionType,
        params: _actionParams,
      ),
      createdAt: widget.existingRule?.createdAt ?? DateTime.now(),
      lastTriggeredAt: widget.existingRule?.lastTriggeredAt,
      triggerCount: widget.existingRule?.triggerCount ?? 0,
    );

    if (widget.existingRule != null) {
      ref.read(autoAuthRulesProvider.notifier).updateRule(rule);
    } else {
      ref.read(autoAuthRulesProvider.notifier).addRule(rule);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.existingRule != null ? '规则已更新' : '规则已创建'),
      ),
    );
  }
}