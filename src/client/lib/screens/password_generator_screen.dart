import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/password_widgets.dart';
import '../services/password_service.dart';

/// 密码生成器屏幕
class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() => _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  // 密码长度
  double _length = 16;
  
  // 字符集选项
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSymbols = true;
  
  // 排除字符
  String _excludeChars = '';
  
  // 生成的密码
  String _generatedPassword = '';
  
  // 密码历史
  List<String> _history = [];
  
  // 密码服务
  final PasswordService _passwordService = PasswordService();

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    final options = PasswordOptions(
      length: _length.toInt(),
      useUppercase: _useUppercase,
      useLowercase: _useLowercase,
      useNumbers: _useNumbers,
      useSymbols: _useSymbols,
      excludeChars: _excludeChars,
    );
    
    final password = _passwordService.generate(options);
    setState(() {
      _generatedPassword = password;
      // 添加到历史（去重）
      if (password.isNotEmpty && !_history.contains(password)) {
        _history.insert(0, password);
        if (_history.length > 10) {
          _history = _history.sublist(0, 10);
        }
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('密码已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearHistory() {
    setState(() {
      _history.clear();
    });
  }

  void _useFromHistory(String password) {
    setState(() {
      _generatedPassword = password;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('密码生成器'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generatePassword,
            tooltip: '重新生成',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 生成的密码展示
            _buildPasswordDisplay(),
            const SizedBox(height: 24),
            
            // 密码强度指示器
            PasswordStrengthMeter(password: _generatedPassword),
            const SizedBox(height: 24),
            
            // 密码长度滑块
            _buildLengthSlider(),
            const SizedBox(height: 16),
            
            // 字符集选择
            CharacterSetSelector(
              useUppercase: _useUppercase,
              useLowercase: _useLowercase,
              useNumbers: _useNumbers,
              useSymbols: _useSymbols,
              onChanged: (uppercase, lowercase, numbers, symbols) {
                setState(() {
                  _useUppercase = uppercase;
                  _useLowercase = lowercase;
                  _useNumbers = numbers;
                  _useSymbols = symbols;
                });
                _generatePassword();
              },
            ),
            const SizedBox(height: 16),
            
            // 排除字符
            _buildExcludeChars(),
            const SizedBox(height: 24),
            
            // 密码历史
            if (_history.isNotEmpty) ...[
              _buildHistorySection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordDisplay() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // 密码文本
          SelectableText(
            _generatedPassword,
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'monospace',
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // 操作按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 复制按钮
              FilledButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('复制'),
              ),
              const SizedBox(width: 12),
              
              // 重新生成按钮
              OutlinedButton.icon(
                onPressed: _generatePassword,
                icon: const Icon(Icons.refresh),
                label: const Text('重新生成'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLengthSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '密码长度',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_length.toInt()} 位',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: _length,
          min: 8,
          max: 64,
          divisions: 56,
          label: _length.toInt().toString(),
          onChanged: (value) {
            setState(() {
              _length = value;
            });
            _generatePassword();
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('8', style: TextStyle(color: Colors.grey)),
            Text('64', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildExcludeChars() {
    return TextField(
      decoration: const InputDecoration(
        labelText: '排除的字符',
        hintText: '例如: 0O1lI',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.block),
      ),
      onChanged: (value) {
        setState(() {
          _excludeChars = value;
        });
        _generatePassword();
      },
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '历史记录',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: _clearHistory,
              child: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        PasswordHistory(
          history: _history,
          onSelect: _useFromHistory,
          onCopy: (password) {
            Clipboard.setData(ClipboardData(text: password));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('密码已复制'),
                duration: Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 密码选项
class PasswordOptions {
  final int length;
  final bool useUppercase;
  final bool useLowercase;
  final bool useNumbers;
  final bool useSymbols;
  final String excludeChars;

  PasswordOptions({
    required this.length,
    required this.useUppercase,
    required this.useLowercase,
    required this.useNumbers,
    required this.useSymbols,
    this.excludeChars = '',
  });
}

/// 密码服务
class PasswordService {
  static const String _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const String _numbers = '0123456789';
  static const String _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

  String generate(PasswordOptions options) {
    String chars = '';
    
    if (options.useUppercase) chars += _uppercase;
    if (options.useLowercase) chars += _lowercase;
    if (options.useNumbers) chars += _numbers;
    if (options.useSymbols) chars += _symbols;
    
    // 排除指定字符
    for (var c in options.excludeChars.split('')) {
      chars = chars.replaceAll(c, '');
    }
    
    if (chars.isEmpty) {
      return '';
    }

    final random = DateTime.now().millisecondsSinceEpoch;
    final password = List.generate(
      options.length,
      (index) => chars[(random + index * 7) % chars.length],
    ).join();

    return password;
  }

  /// 计算密码强度
  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.veryWeak;
    
    int score = 0;
    
    // 长度评分
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    if (password.length >= 20) score++;
    
    // 字符类型评分
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) score++;
    
    // 根据分数返回强度
    if (score >= 7) return PasswordStrength.veryStrong;
    if (score >= 5) return PasswordStrength.strong;
    if (score >= 3) return PasswordStrength.medium;
    if (score >= 2) return PasswordStrength.weak;
    return PasswordStrength.veryWeak;
  }
}

/// 密码强度枚举
enum PasswordStrength {
  veryWeak,
  weak,
  medium,
  strong,
  veryStrong,
}

/// 密码强度扩展
extension PasswordStrengthExtension on PasswordStrength {
  String get label {
    switch (this) {
      case PasswordStrength.veryWeak:
        return '非常弱';
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.medium:
        return '中等';
      case PasswordStrength.strong:
        return '强';
      case PasswordStrength.veryStrong:
        return '非常强';
    }
  }

  double get value {
    switch (this) {
      case PasswordStrength.veryWeak:
        return 0.2;
      case PasswordStrength.weak:
        return 0.4;
      case PasswordStrength.medium:
        return 0.6;
      case PasswordStrength.strong:
        return 0.8;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.veryWeak:
        return Colors.red;
      case PasswordStrength.weak:
        return Colors.orange;
      case PasswordStrength.medium:
        return Colors.yellow.shade700;
      case PasswordStrength.strong:
        return Colors.lightGreen;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }
}