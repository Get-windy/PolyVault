import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 快捷操作项数据模型
class QuickAction {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final String route;

  const QuickAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.route,
  });
}

/// 快捷操作网格 - 首页快捷入口
class QuickActionsGrid extends StatelessWidget {
  final List<QuickAction>? customActions;
  final void Function(QuickAction)? onActionTap;

  const QuickActionsGrid({
    super.key,
    this.customActions,
    this.onActionTap,
  });

  List<QuickAction> get _defaultActions => [
        QuickAction(
          id: 'credentials',
          label: '凭证管理',
          icon: Icons.vpn_key,
          color: Colors.blue,
          route: '/credentials',
        ),
        QuickAction(
          id: 'devices',
          label: '设备管理',
          icon: Icons.devices,
          color: Colors.green,
          route: '/devices',
        ),
        QuickAction(
          id: 'password_gen',
          label: '密码生成',
          icon: Icons.password,
          color: Colors.purple,
          route: '/password-generator',
        ),
        QuickAction(
          id: 'backup',
          label: '备份恢复',
          icon: Icons.backup,
          color: Colors.orange,
          route: '/backup',
        ),
        QuickAction(
          id: 'sync',
          label: '数据同步',
          icon: Icons.sync,
          color: Colors.teal,
          route: '/sync',
        ),
        QuickAction(
          id: 'settings',
          label: '安全设置',
          icon: Icons.security,
          color: Colors.red,
          route: '/settings/security',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final actions = customActions ?? _defaultActions;
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return _QuickActionCard(
          action: action,
          onTap: () {
            if (onActionTap != null) {
              onActionTap!(action);
            } else {
              context.push(action.route);
            }
          },
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final QuickAction action;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.action,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 紧凑型快捷操作行
class QuickActionsRow extends StatelessWidget {
  final List<QuickAction>? customActions;
  final void Function(QuickAction)? onActionTap;

  const QuickActionsRow({
    super.key,
    this.customActions,
    this.onActionTap,
  });

  List<QuickAction> get _defaultActions => [
        QuickAction(
          id: 'add_credential',
          label: '添加凭证',
          icon: Icons.add_circle_outline,
          color: Colors.blue,
          route: '/credentials/add',
        ),
        QuickAction(
          id: 'scan_qr',
          label: '扫码配对',
          icon: Icons.qr_code_scanner,
          color: Colors.green,
          route: '/devices/pair',
        ),
        QuickAction(
          id: 'password_gen',
          label: '生成密码',
          icon: Icons.auto_fix_high,
          color: Colors.purple,
          route: '/password-generator',
        ),
        QuickAction(
          id: 'security',
          label: '安全中心',
          icon: Icons.shield,
          color: Colors.orange,
          route: '/settings/security',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final actions = customActions ?? _defaultActions;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((action) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _QuickActionChip(
              action: action,
              onTap: () => onActionTap?.call(action),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final QuickAction action;
  final VoidCallback? onTap;

  const _QuickActionChip({
    required this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(action.icon, size: 18, color: action.color),
      label: Text(action.label),
      onPressed: onTap,
      backgroundColor: action.color.withOpacity(0.1),
      side: BorderSide.none,
    );
  }
}