import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screen/password_generator_screen.dart';

/// 密码强度指示器
class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    final strength = PasswordService.calculateStrength(password);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '密码强度',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                strength.label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: strength.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 强度进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strength.value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(strength.color),
            ),
          ),
          const SizedBox(height: 12),
          
          // 强度说明
          _buildStrengthHints(strength),
        ],
      ),
    );
  }

  Widget _buildStrengthHints(PasswordStrength strength) {
    final hints = <String>[];
    
    if (password.length >= 8) hints.add('✓ 足够长度');
    if (password.length >= 12) hints.add('✓ 推荐长度');
    if (RegExp(r'[a-z]').hasMatch(password)) hints.add('✓ 包含小写字母');
    if (RegExp(r'[A-Z]').hasMatch(password)) hints.add('✓ 包含大写字母');
    if (RegExp(r'[0-9]').hasMatch(password)) hints.add('✓ 包含数字');
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) {
      hints.add('✓ 包含特殊字符');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: hints.map((hint) => Text(
        hint,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      )).toList(),
    );
  }
}

/// 字符集选择器
class CharacterSetSelector extends StatelessWidget {
  final bool useUppercase;
  final bool useLowercase;
  final bool useNumbers;
  final bool useSymbols;
  final Function(bool, bool, bool, bool) onChanged;

  const CharacterSetSelector({
    super.key,
    required this.useUppercase,
    required this.useLowercase,
    required this.useNumbers,
    required this.useSymbols,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '字符集',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          
          // 大写字母
          _buildOption(
            context,
            title: '大写字母 (A-Z)',
            example: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
            value: useUppercase,
            onChanged: (value) => onChanged(value, useLowercase, useNumbers, useSymbols),
          ),
          
          // 小写字母
          _buildOption(
            context,
            title: '小写字母 (a-z)',
            example: 'abcdefghijklmnopqrstuvwxyz',
            value: useLowercase,
            onChanged: (value) => onChanged(useUppercase, value, useNumbers, useSymbols),
          ),
          
          // 数字
          _buildOption(
            context,
            title: '数字 (0-9)',
            example: '0123456789',
            value: useNumbers,
            onChanged: (value) => onChanged(useUppercase, useLowercase, value, useSymbols),
          ),
          
          // 特殊字符
          _buildOption(
            context,
            title: '特殊字符',
            example: '!@#\$%^&*()_+-=[]{}|;:,.<>?',
            value: useSymbols,
            onChanged: (value) => onChanged(useUppercase, useLowercase, useNumbers, value),
          ),
          
          // 至少选择一个提示
          if (!useUppercase && !useLowercase && !useNumbers && !useSymbols)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '⚠️ 请至少选择一个字符集',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String example,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? true),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  example,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 密码历史列表
class PasswordHistory extends StatelessWidget {
  final List<String> history;
  final Function(String) onSelect;
  final Function(String) onCopy;

  const PasswordHistory({
    super.key,
    required this.history,
    required this.onSelect,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final password = history[index];
          final strength = PasswordService.calculateStrength(password);
          
          return ListTile(
            leading: Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: strength.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            title: Text(
              password,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              strength.label,
              style: TextStyle(
                color: strength.color,
                fontSize: 12,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => onCopy(password),
                  tooltip: '复制',
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, size: 20),
                  onPressed: () => onSelect(password),
                  tooltip: '使用',
                ),
              ],
            ),
            onTap: () => onSelect(password),
          );
        },
      ),
    );
  }
}

/// 密码输入框组件
class PasswordInputField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? value;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final VoidCallback? onGeneratePressed;

  const PasswordInputField({
    super.key,
    this.label,
    this.hint,
    this.value,
    this.onChanged,
    this.obscureText = true,
    this.onGeneratePressed,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  late TextEditingController _controller;
  bool _obscured = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(PasswordInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      obscureText: widget.obscureText && _obscured,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 显示/隐藏密码
            IconButton(
              icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
              onPressed: () {
                setState(() {
                  _obscured = !_obscured;
                });
              },
            ),
            // 生成密码按钮
            if (widget.onGeneratePressed != null)
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                onPressed: widget.onGeneratePressed,
                tooltip: '生成密码',
              ),
          ],
        ),
      ),
    );
  }
}

/// 密码验证组件
class PasswordValidator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordValidator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = _getRequirements();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements.map((req) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                req.met ? Icons.check_circle : Icons.circle_outlined,
                size: 16,
                color: req.met ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                req.text,
                style: TextStyle(
                  fontSize: 12,
                  color: req.met ? Colors.green.shade700 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<_PasswordRequirement> _getRequirements() {
    return [
      _PasswordRequirement(
        text: '至少8个字符',
        met: password.length >= 8,
      ),
      _PasswordRequirement(
        text: '包含大写字母',
        met: RegExp(r'[A-Z]').hasMatch(password),
      ),
      _PasswordRequirement(
        text: '包含小写字母',
        met: RegExp(r'[a-z]').hasMatch(password),
      ),
      _PasswordRequirement(
        text: '包含数字',
        met: RegExp(r'[0-9]').hasMatch(password),
      ),
      _PasswordRequirement(
        text: '包含特殊字符',
        met: RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password),
      ),
    ];
  }
}

class _PasswordRequirement {
  final String text;
  final bool met;

  _PasswordRequirement({
    required this.text,
    required this.met,
  });
}

/// 导出组件集合
const passwordWidgets = (
  PasswordStrengthMeter: PasswordStrengthMeter,
  CharacterSetSelector: CharacterSetSelector,
  PasswordHistory: PasswordHistory,
  PasswordInputField: PasswordInputField,
  PasswordValidator: PasswordValidator,
);