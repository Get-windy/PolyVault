/// 发帖页面响应式布局
/// 支持手机/平板/桌面多设备适配
library create_post_responsive;

import 'package:flutter/material.dart';
import '../theme/responsive.dart';
import '../theme/app_theme.dart';

/// 响应式发帖页面
class ResponsiveCreatePostScreen extends StatefulWidget {
  const ResponsiveCreatePostScreen({super.key});

  @override
  State<ResponsiveCreatePostScreen> createState() => _ResponsiveCreatePostScreenState();
}

class _ResponsiveCreatePostScreenState extends State<ResponsiveCreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        if (responsive.isDesktop) {
          return _DesktopCreatePostLayout(
            titleController: _titleController,
            contentController: _contentController,
            formKey: _formKey,
          );
        }
        if (responsive.isTablet) {
          return _TabletCreatePostLayout(
            titleController: _titleController,
            contentController: _contentController,
            formKey: _formKey,
          );
        }
        return _MobileCreatePostLayout(
          titleController: _titleController,
          contentController: _contentController,
          formKey: _formKey,
        );
      },
    );
  }
}

/// 移动端发帖布局
class _MobileCreatePostLayout extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final GlobalKey<FormState> formKey;
  
  const _MobileCreatePostLayout({
    required this.titleController,
    required this.contentController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建凭证'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _submit(context),
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TitleField(controller: titleController),
            const SizedBox(height: 16),
            _ServiceField(),
            const SizedBox(height: 16),
            _UsernameField(),
            const SizedBox(height: 16),
            _PasswordField(),
            const SizedBox(height: 16),
            _NotesField(controller: contentController),
            const SizedBox(height: 24),
            _QuickActions(),
          ],
        ),
      ),
    );
  }
}

/// 平板发帖布局
class _TabletCreatePostLayout extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final GlobalKey<FormState> formKey;
  
  const _TabletCreatePostLayout({
    required this.titleController,
    required this.contentController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新建凭证'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton(
              onPressed: () => _submit(context),
              child: const Text('保存'),
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _TitleField(controller: titleController),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: _ServiceField()),
                    const SizedBox(width: 16),
                    Expanded(child: _UsernameField()),
                  ],
                ),
                const SizedBox(height: 20),
                _PasswordField(),
                const SizedBox(height: 20),
                _NotesField(controller: contentController),
                const SizedBox(height: 32),
                _QuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 桌面发帖布局
class _DesktopCreatePostLayout extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController contentController;
  final GlobalKey<FormState> formKey;
  
  const _DesktopCreatePostLayout({
    required this.titleController,
    required this.contentController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Row(
        children: [
          // 左侧导航
          NavigationRail(
            extended: true,
            minExtendedWidth: 200,
            selectedIndex: -1,
            leading: FloatingActionButton(
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                label: Text('首页'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                label: Text('发现'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // 主内容
          Expanded(
            child: Row(
              children: [
                // 编辑区域
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '新建凭证',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const Spacer(),
                              FilledButton.icon(
                                onPressed: () => _submit(context),
                                icon: const Icon(Icons.save),
                                label: const Text('保存'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _TitleField(controller: titleController),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(child: _ServiceField()),
                                        const SizedBox(width: 16),
                                        Expanded(child: _UsernameField()),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    _PasswordField(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 32),
                              Expanded(
                                child: _NotesField(
                                  controller: contentController,
                                  maxLines: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 右侧工具栏
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: _RightToolbar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 标题输入
class _TitleField extends StatelessWidget {
  final TextEditingController? controller;
  
  const _TitleField({this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: '标题',
        hintText: '为这个凭证起个名字',
        prefixIcon: Icon(Icons.title),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入标题';
        }
        return null;
      },
    );
  }
}

/// 服务名输入
class _ServiceField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: '服务名称',
        hintText: '如 GitHub, AWS',
        prefixIcon: Icon(Icons.business),
      ),
    );
  }
}

/// 用户名输入
class _UsernameField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: '用户名/邮箱',
        hintText: '登录账号',
        prefixIcon: Icon(Icons.person),
      ),
    );
  }
}

/// 密码输入
class _PasswordField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: const InputDecoration(
        labelText: '密码',
        hintText: '登录密码',
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(Icons.visibility_off),
          onPressed: () {},
        ),
      ),
      obscureText: true,
    );
  }
}

/// 备注输入
class _NotesField extends StatelessWidget {
  final TextEditingController? controller;
  final int maxLines;
  
  const _NotesField({
    this.controller,
    this.maxLines = 5,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: const InputDecoration(
        labelText: '备注（可选）',
        hintText: '添加说明信息',
        prefixIcon: Icon(Icons.notes),
        alignLabelWithHint: true,
      ),
    );
  }
}

/// 快捷操作
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快捷操作', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              avatar: const Icon(Icons.password, size: 18),
              label: const Text('生成密码'),
              onPressed: () {},
            ),
            ActionChip(
              avatar: const Icon(Icons.qr_code, size: 18),
              label: const Text('扫码添加'),
              onPressed: () {},
            ),
            ActionChip(
              avatar: const Icon(Icons.upload, size: 18),
              label: const Text('导入'),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

/// 右侧工具栏
class _RightToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('工具', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _ToolTile(icon: Icons.password, title: '密码生成器', onTap: () {}),
          _ToolTile(icon: Icons.qr_code_scanner, title: '二维码扫描', onTap: () {}),
          _ToolTile(icon: Icons.attach_file, title: '添加附件', onTap: () {}),
          const Divider(height: 32),
          Text('最近使用', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _RecentItem(service: 'GitHub', time: '2分钟前'),
          _RecentItem(service: 'AWS', time: '1小时前'),
          _RecentItem(service: 'Gmail', time: '昨天'),
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
      dense: true,
    );
  }
}

class _RecentItem extends StatelessWidget {
  final String service;
  final String time;
  
  const _RecentItem({required this.service, required this.time});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.vpn_key, size: 16, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _submit(BuildContext context) {
  Navigator.pop(context);
}