/// 表单验证工具类
/// 提供统一的验证规则和错误提示
library form_validators;

import 'package:flutter/material.dart';

/// 验证结果
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final ValidationErrorType? errorType;

  const ValidationResult.valid()
      : isValid = true,
        errorMessage = null,
        errorType = null;

  const ValidationResult.invalid(this.errorMessage, [this.errorType])
      : isValid = false;

  bool get isInvalid => !isValid;
}

/// 验证错误类型
enum ValidationErrorType {
  required,       // 必填
  format,         // 格式错误
  length,         // 长度不符
  strength,       // 强度不足
  mismatch,       // 不匹配
  duplicate,      // 重复
  invalid,        // 无效
}

/// 表单验证器
class FormValidators {
  FormValidators._();

  /// 必填验证
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? '此字段'}不能为空';
    }
    return null;
  }

  /// 邮箱验证
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  /// 用户名验证
  static String? username(String? value, {int minLength = 3, int maxLength = 20}) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < minLength) {
      return '用户名至少需要 $minLength 个字符';
    }
    
    if (value.length > maxLength) {
      return '用户名不能超过 $maxLength 个字符';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return '用户名只能包含字母、数字和下划线';
    }
    
    return null;
  }

  /// 密码验证
  static String? password(String? value, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireNumber = true,
    bool requireSpecial = false,
  }) {
    if (value == null || value.isEmpty) return null;
    
    if (value.length < minLength) {
      return '密码至少需要 $minLength 个字符';
    }
    
    if (requireUppercase && !value.contains(RegExp(r'[A-Z]'))) {
      return '密码需要包含至少一个大写字母';
    }
    
    if (requireLowercase && !value.contains(RegExp(r'[a-z]'))) {
      return '密码需要包含至少一个小写字母';
    }
    
    if (requireNumber && !value.contains(RegExp(r'[0-9]'))) {
      return '密码需要包含至少一个数字';
    }
    
    if (requireSpecial && !value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return '密码需要包含至少一个特殊字符';
    }
    
    return null;
  }

  /// 确认密码验证
  static String? confirmPassword(String? value, String? originalPassword) {
    if (value != originalPassword) {
      return '两次输入的密码不一致';
    }
    return null;
  }

  /// 手机号验证
  static String? phone(String? value, {String countryCode = 'CN'}) {
    if (value == null || value.isEmpty) return null;
    
    // 中国手机号验证
    if (countryCode == 'CN') {
      final phoneRegex = RegExp(r'^1[3-9]\d{9}$');
      if (!phoneRegex.hasMatch(value)) {
        return '请输入有效的手机号码';
      }
    }
    
    return null;
  }

  /// URL验证
  static String? url(String? value, {bool requireHttps = false}) {
    if (value == null || value.isEmpty) return null;
    
    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme) {
        return '请输入有效的URL';
      }
      if (requireHttps && uri.scheme != 'https') {
        return '请使用HTTPS链接';
      }
    } catch (e) {
      return '请输入有效的URL';
    }
    
    return null;
  }

  /// 端口号验证
  static String? port(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final port = int.tryParse(value);
    if (port == null || port < 1 || port > 65535) {
      return '请输入有效的端口号 (1-65535)';
    }
    
    return null;
  }

  /// IP地址验证
  static String? ipAddress(String? value) {
    if (value == null || value.isEmpty) return null;
    
    final ipv4Regex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    
    final ipv6Regex = RegExp(
      r'^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$'
    );
    
    if (!ipv4Regex.hasMatch(value) && !ipv6Regex.hasMatch(value)) {
      return '请输入有效的IP地址';
    }
    
    return null;
  }

  /// 数字范围验证
  static String? numberRange(String? value, {
    num? min,
    num? max,
    bool integer = false,
  }) {
    if (value == null || value.isEmpty) return null;
    
    final numValue = integer ? int.tryParse(value) : num.tryParse(value);
    
    if (numValue == null) {
      return '请输入有效的${integer ? "整数" : "数字"}';
    }
    
    if (min != null && numValue < min) {
      return '数值不能小于 $min';
    }
    
    if (max != null && numValue > max) {
      return '数值不能大于 $max';
    }
    
    return null;
  }

  /// 长度验证
  static String? length(String? value, {
    int? minLength,
    int? maxLength,
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) return null;
    
    if (minLength != null && value.length < minLength) {
      return '${fieldName ?? '内容'}至少需要 $minLength 个字符';
    }
    
    if (maxLength != null && value.length > maxLength) {
      return '${fieldName ?? '内容'}不能超过 $maxLength 个字符';
    }
    
    return null;
  }

  /// 服务名称验证
  static String? serviceName(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入服务名称';
    }
    
    if (value.length < 2) {
      return '服务名称至少需要2个字符';
    }
    
    if (value.length > 50) {
      return '服务名称不能超过50个字符';
    }
    
    return null;
  }

  /// 组合验证器
  static FormFieldValidator<String> combine(List<FormFieldValidator<String>> validators) {
    return (String? value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) return result;
      }
      return null;
    };
  }

  /// 创建带防抖的验证器
  static FormFieldValidator<String> withDebounce(
    FormFieldValidator<String> validator, {
    Duration debounceTime = const Duration(milliseconds: 300),
  }) {
    return (String? value) {
      // 防抖逻辑需要在StatefulWidget中处理
      return validator(value);
    };
  }
}

/// 密码强度评估器
class PasswordStrengthEvaluator {
  /// 评估密码强度
  static PasswordStrength evaluate(String password) {
    int score = 0;
    
    // 长度加分
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    
    // 字符类型加分
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    
    // 连续字符检测
    if (!_hasConsecutiveChars(password)) score++;
    
    // 常见密码检测
    if (!_isCommonPassword(password)) score++;
    
    if (score <= 3) return PasswordStrength.weak;
    if (score <= 5) return PasswordStrength.medium;
    if (score <= 7) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  static bool _hasConsecutiveChars(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password.codeUnitAt(i + 1) == password.codeUnitAt(i) + 1 &&
          password.codeUnitAt(i + 2) == password.codeUnitAt(i) + 2) {
        return true;
      }
    }
    return false;
  }

  static bool _isCommonPassword(String password) {
    const commonPasswords = [
      'password', '123456', '12345678', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
    ];
    return commonPasswords.contains(password.toLowerCase());
  }
}

/// 密码强度等级
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong;

  String get label {
    switch (this) {
      case PasswordStrength.weak: return '弱';
      case PasswordStrength.medium: return '中等';
      case PasswordStrength.strong: return '强';
      case PasswordStrength.veryStrong: return '非常强';
    }
  }

  Color get color {
    switch (this) {
      case PasswordStrength.weak: return const Color(0xFFE53935);
      case PasswordStrength.medium: return const Color(0xFFFFA726);
      case PasswordStrength.strong: return const Color(0xFF43A047);
      case PasswordStrength.veryStrong: return const Color(0xFF1B5E20);
    }
  }

  IconData get icon {
    switch (this) {
      case PasswordStrength.weak: return Icons.warning;
      case PasswordStrength.medium: return Icons.info;
      case PasswordStrength.strong: return Icons.check_circle;
      case PasswordStrength.veryStrong: return Icons.verified;
    }
  }
}