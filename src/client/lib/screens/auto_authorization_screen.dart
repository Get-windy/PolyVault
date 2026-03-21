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
    final colorScheme = Theme.of(context).colorScheme;

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
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('添加第一条规则'),
          ),
        ],
      ),
    );
  }

  /// 构建规则卡片
  Widget _buildRuleCard(BuildContext context, WidgetRef ref, AutoAuthRule rule) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
