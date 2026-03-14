import 'package:flutter/material.dart';

/// 统计卡片
class StatsCard extends StatelessWidget {
  final int totalCredentials;
  final DateTime? lastBackup;

  const StatsCard({
    super.key,
    required this.totalCredentials,
    this.lastBackup,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '存储统计',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    value: totalCredentials.toString(),
                    label: '已存储凭证',
                    icon: Icons.vpn_key,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _StatItem(
                    value: lastBackup != null ? _formatDate(lastBackup!) : '从未',
                    label: '上次备份',
                    icon: Icons.backup,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays == 1) {
      return '昨天';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
