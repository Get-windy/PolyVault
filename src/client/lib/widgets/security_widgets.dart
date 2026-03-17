import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 安全风险级别
enum RiskLevel {
  critical,
  high,
  medium,
  low,
  info,
}

/// 安全项类型
enum SecurityItemType {
  password,
  twoFactor,
  device,
  session,
  backup,
  encryption,
  privacy,
  other,
}

/// 安全风险项
class SecurityRiskItem {
  final String id;
  final String title;
  final String description;
  final RiskLevel level;
  final SecurityItemType type;
  final String? actionText;
  final VoidCallback? onAction;
  final bool isResolved;

  const SecurityRiskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.type,
    this.actionText,
    this.onAction,
    this.isResolved = false,
  });

  SecurityRiskItem copyWith({
    bool? isResolved,
  }) {
    return SecurityRiskItem(
      id: id,
      title: title,
      description: description,
      level: level,
      type: type,
      actionText: actionText,
      onAction: onAction,
      isResolved: isResolved ?? this.isResolved,
    );
  }
}

/// 安全建议
class SecurityTip {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int priority;

  const SecurityTip({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.priority,
  });
}

/// 安全评分组件
class SecurityScore extends StatelessWidget {
  final int score;
  final double size;

  const SecurityScore({
    super.key,
    required this.score,
    this.size = 150,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, label) = _getScoreInfo();

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // 背景圆
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 12,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              // 进度圆
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 12,
                  color: color,
                  strokeCap: StrokeCap.round,
                ),
              ),
              // 分数
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      score.toString(),
                      style: TextStyle(
                        fontSize: size * 0.25,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '分',
                      style: TextStyle(
                        fontSize: size * 0.1,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  (Color, String) _getScoreInfo() {
    if (score >= 90) return (Colors.green, '优秀');
    if (score >= 70) return (Colors.blue, '良好');
    if (score >= 50) return (Colors.orange, '一般');
    return (Colors.red, '危险');
  }
}

/// 风险项卡片
class RiskItem extends StatelessWidget {
  final SecurityRiskItem item;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const RiskItem({
    super.key,
    required this.item,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelConfig = _getLevelConfig();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 风险图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: levelConfig.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(levelConfig.icon, color: levelConfig.color),
              ),
              const SizedBox(width: 16),
              // 内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: levelConfig.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            levelConfig.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: levelConfig.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.actionText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.actionText!,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // 箭头
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({Color color, IconData icon, String label}) _getLevelConfig() {
    return switch (item.level) {
      RiskLevel.critical => (Colors.red, Icons.warning, '严重'),
      RiskLevel.high => (Colors.orange, Icons.error, '高'),
      RiskLevel.medium => (Colors.amber, Icons.info, '中'),
      RiskLevel.low => (Colors.blue, Icons.info_outline, '低'),
      RiskLevel.info => (Colors.grey, Icons.help_outline, '提示'),
    };
  }
}

/// 安全建议组件
class SecurityTipCard extends StatelessWidget {
  final SecurityTip tip;
  final VoidCallback? onAction;

  const SecurityTipCard({
    super.key,
    required this.tip,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                tip.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tip.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 安全状态概览
class SecurityOverview extends StatelessWidget {
  final int totalItems;
  final int resolvedItems;
  final int criticalCount;
  final int highCount;

  const SecurityOverview({
    super.key,
    required this.totalItems,
    required this.resolvedItems,
    required this.criticalCount,
    required this.highCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('总计', totalItems.toString(), Icons.shield, theme.colorScheme.primary),
          _buildStatItem('已修复', resolvedItems.toString(), Icons.check_circle, Colors.green),
          _buildStatItem('严重', criticalCount.toString(), Icons.warning, Colors.red),
          _buildStatItem('高危', highCount.toString(), Icons.error, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
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
}

/// 安全检查列表
class SecurityChecklist extends StatelessWidget {
  final List<SecurityRiskItem> items;
  final void Function(String id)? onItemAction;

  const SecurityChecklist({
    super.key,
    required this.items,
    this.onItemAction,
  });

  @override
  Widget build(BuildContext context) {
    // 按风险级别分组
    final grouped = <RiskLevel, List<SecurityRiskItem>>{};
    for (final item in items) {
      if (!grouped.containsKey(item.level)) {
        grouped[item.level] = [];
      }
      grouped[item.level]!.add(item);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _getLevelLabel(entry.key),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _getLevelColor(entry.key),
                ),
              ),
            ),
            ...entry.value.map((item) => RiskItem(
              item: item,
              onAction: () => onItemAction?.call(item.id),
            )),
          ],
        );
      }).toList(),
    );
  }

  String _getLevelLabel(RiskLevel level) {
    return switch (level) {
      RiskLevel.critical => '🔴 严重风险',
      RiskLevel.high => '🟠 高风险',
      RiskLevel.medium => '🟡 中等风险',
      RiskLevel.low => '🔵 低风险',
      RiskLevel.info => '⚪ 安全提示',
    };
  }

  Color _getLevelColor(RiskLevel level) {
    return switch (level) {
      RiskLevel.critical => Colors.red,
      RiskLevel.high => Colors.orange,
      RiskLevel.medium => Colors.amber,
      RiskLevel.low => Colors.blue,
      RiskLevel.info => Colors.grey,
    };
  }
}