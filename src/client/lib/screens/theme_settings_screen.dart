import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 语言设置页面
class LanguageSettingsScreen extends ConsumerWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final availableLocales = ref.watch(availableLocalesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('语言设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前语言
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.language,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '当前语言',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLanguageName(currentLocale.languageCode),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 语言列表
          _buildSectionHeader('选择语言'),
          ...availableLocales.map((locale) {
            final isSelected = locale.languageCode == currentLocale.languageCode;
            return _buildLanguageItem(
              context: context,
              locale: locale,
              isSelected: isSelected,
              onTap: () {
                ref.read(localeProvider.notifier).state = locale;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已切换到 ${_getLanguageName(locale.languageCode)}'),
                  ),
                );
              },
            );
          }),

          const SizedBox(height: 24),

          // 系统语言同步
          _buildSectionHeader('系统同步'),
          Card(
            child: SwitchListTile(
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.settings_suggest,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              title: const Text('跟随系统语言'),
              subtitle: const Text('自动匹配设备语言设置'),
              value: currentLocale.languageCode == 'system',
              onChanged: (value) {
                // TODO: 实现系统语言同步
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('系统语言同步功能开发中...')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildLanguageItem({
    required BuildContext context,
    required Locale locale,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.colorScheme.primaryContainer 
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              _getLanguageFlag(locale.languageCode),
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Text(
          _getLanguageName(locale.languageCode),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(_getLanguageNativeName(locale.languageCode)),
        trailing: isSelected 
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'zh':
        return '中文 (简体)';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  String _getLanguageNativeName(String code) {
    switch (code) {
      case 'zh':
        return 'Chinese (Simplified)';
      case 'en':
        return 'English';
      default:
        return code;
    }
  }

  String _getLanguageFlag(String code) {
    switch (code) {
      case 'zh':
        return '🇨🇳';
      case 'en':
        return '🇺🇸';
      default:
        return '🌐';
    }
  }
}

/// 主题偏好设置页面
class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('外观设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前主题预览
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.palette,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '主题模式',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getThemeModeName(theme.brightness),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _buildSectionHeader('选择主题'),
          _buildThemeOption(
            context: context,
            mode: ThemeMode.system,
            title: '跟随系统',
            subtitle: '根据设备设置自动切换',
            icon: Icons.settings_suggest,
          ),
          _buildThemeOption(
            context: context,
            mode: ThemeMode.light,
            title: '浅色模式',
            subtitle: '明亮的浅色主题',
            icon: Icons.light_mode,
          ),
          _buildThemeOption(
            context: context,
            mode: ThemeMode.dark,
            title: '深色模式',
            subtitle: '护眼的深色主题',
            icon: Icons.dark_mode,
          ),

          const SizedBox(height: 24),

          // 主题颜色
          _buildSectionHeader('主题颜色'),
          _buildColorOptions(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required ThemeMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final currentMode = theme.brightness;
    final isSelected = (mode == ThemeMode.dark && currentMode == Brightness.dark) ||
                       (mode == ThemeMode.light && currentMode == Brightness.light) ||
                       (mode == ThemeMode.system);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected 
              ? theme.colorScheme.primary 
              : theme.colorScheme.outlineVariant.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected 
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : null,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已切换到 $title')),
          );
        },
      ),
    );
  }

  Widget _buildColorOptions(BuildContext context) {
    final theme = Theme.of(context);

    final colors = [
      {'name': '紫色', 'color': const Color(0xFF6366F1)},
      {'name': '蓝色', 'color': const Color(0xFF3B82F6)},
      {'name': '绿色', 'color': const Color(0xFF22C55E)},
      {'name': '橙色', 'color': const Color(0xFFF59E0B)},
      {'name': '红色', 'color': const Color(0xFFEF4444)},
      {'name': '粉色', 'color': const Color(0xFFEC4899)},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((c) {
        final isSelected = c['color'] == theme.colorScheme.primary;
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('已选择 ${c['name']} 主题色')),
            );
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: c['color'] as Color,
              shape: BoxShape.circle,
              border: isSelected 
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected 
                  ? [
                      BoxShadow(
                        color: (c['color'] as Color).withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected 
                ? const Icon(Icons.check, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }

  String _getThemeModeName(Brightness? brightness) {
    switch (brightness) {
      case Brightness.dark:
        return '深色模式';
      case Brightness.light:
        return '浅色模式';
      default:
        return '跟随系统';
    }
  }
}