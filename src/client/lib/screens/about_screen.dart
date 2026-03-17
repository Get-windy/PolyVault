import 'package:flutter/material.dart';

/// 关于页面
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.shield,
                size: 50,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Name
            Text(
              'PolyVault',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Version
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '版本 2.1.0',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Description
            Text(
              '安全、便捷的密码管理应用',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Features List
            _buildFeatureSection(context),
            
            const SizedBox(height: 32),
            
            // Links
            _buildLinksSection(context),
            
            const SizedBox(height: 32),
            
            // Copyright
            Text(
              '© 2024 PolyVault. All rights reserved.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context) {
    final theme = Theme.of(context);
    final features = [
      {'icon': Icons.lock, 'title': '端到端加密', 'desc': '保护您的数据安全'},
      {'icon': Icons.sync, 'title': '多设备同步', 'desc': '跨平台实时同步'},
      {'icon': Icons.fingerprint, 'title': '生物识别', 'desc': '快速安全解锁'},
      {'icon': Icons.cloud_backup, 'title': '云端备份', 'desc': '数据永不丢失'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '功能特点',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  f['icon'] as IconData,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      f['desc'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildLinksSection(BuildContext context) {
    final theme = Theme.of(context);
    final links = [
      {'icon': Icons.description, 'title': '服务条款', 'trailing': '→'},
      {'icon': Icons.privacy_tip, 'title': '隐私政策', 'trailing': '→'},
      {'icon': Icons.help, 'title': '帮助中心', 'trailing': '→'},
      {'icon': Icons.star, 'title': '给我们评分', 'trailing': '→'},
    ];

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: links.map((link) => ListTile(
          leading: Icon(link['icon'] as IconData),
          title: Text(link['title'] as String),
          trailing: Text(link['trailing'] as String),
          onTap: () {
            // Handle tap
          },
        )).toList(),
      ),
    );
  }
}