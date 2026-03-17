/**
 * PolyVault 安全模块测试
 * 测试生物识别、密码管理、自动锁定功能
 */

import 'package:flutter/material.dart';

// ============ 测试数据 ============

// 测试用户
final testUser = {
  'id': 'user_001',
  'username': 'test_user',
  'email': 'test@example.com',
};

// 测试凭据
final testCredential = {
  'id': 'cred_001',
  'serviceName': 'Test Service',
  'username': 'testuser',
  'password': 'Test@123456',
  'notes': 'Test notes',
};

// ============ 生物识别认证测试 ============

class BiometricAuthTest {
  /// 生物识别类型
  static const biometricTypes = ['fingerprint', 'face', 'iris'];
  
  /// 测试生物识别可用性检查
  static bool checkBiometricAvailable(String biometricType) {
    // 模拟检查生物识别是否可用
    return biometricTypes.contains(biometricType);
  }
  
  /// 测试生物识别认证流程
  static Future<BiometricResult> authenticate({
    required String biometricType,
    required String reason,
  }) async {
    // 模拟认证延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 模拟成功/失败
    final success = biometricTypes.contains(biometricType);
    
    return BiometricResult(
      success: success,
      error: success ? null : 'Biometric not available',
      biometricType: biometricType,
    );
  }
  
  /// 测试生物识别设置
  static Map<String, dynamic> getBiometricSettings() {
    return {
      'enabled': true,
      'type': 'fingerprint',
      'lastUsed': DateTime.now().toIso8601String(),
    };
  }
}

class BiometricResult {
  final bool success;
  final String? error;
  final String biometricType;
  
  BiometricResult({
    required this.success,
    this.error,
    required this.biometricType,
  });
}

// 测试生物识别功能
void testBiometricAuth() {
  print('\n=== 生物识别认证测试 ===');
  
  // 测试可用性检查
  print('1. 检查指纹可用: ${BiometricAuthTest.checkBiometricAvailable("fingerprint")}');
  print('2. 检查面容ID可用: ${BiometricAuthTest.checkBiometricAvailable("face")}');
  print('3. 检查不存在的类型: ${BiometricAuthTest.checkBiometricAvailable("iris")}');
  
  // 测试认证流程
  BiometricAuthTest.authenticate(biometricType: 'fingerprint', reason: '解锁应用')
    .then((result) {
      print('4. 指纹认证结果: ${result.success}');
    });
  
  // 测试设置获取
  final settings = BiometricAuthTest.getBiometricSettings();
  print('5. 生物识别设置: $settings');
}

// ============ 密码管理测试 ============

class PasswordService {
  /// 密码强度级别
  static const strengthLevels = ['非常弱', '弱', '中等', '强', '非常强'];
  
  /// 计算密码强度
  static PasswordStrength calculateStrength(String password) {
    int score = 0;
    
    // 长度检查
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.length >= 16) score++;
    
    // 字符类型检查
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]').hasMatch(password)) score++;
    
    // 转换到 0-1 范围
    double value = score / 7.0;
    
    // 确定级别
    int level;
    Color color;
    String label;
    
    if (score <= 1) {
      level = 0;
      color = Colors.red;
      label = '非常弱';
    } else if (score <= 2) {
      level = 1;
      color = Colors.orange;
      label = '弱';
    } else if (score <= 4) {
      level = 2;
      color = Colors.yellow;
      label = '中等';
    } else if (score <= 5) {
      level = 3;
      color = Colors.lightGreen;
      label = '强';
    } else {
      level = 4;
      color = Colors.green;
      label = '非常强';
    }
    
    return PasswordStrength(
      value: value,
      score: score,
      level: level,
      color: color,
      label: label,
    );
  }
  
  /// 验证密码
  static bool validatePassword(String password) {
    // 至少8位，包含大小写和数字
    if (password.length < 8) return false;
    if (!RegExp(r'[a-z]').hasMatch(password)) return false;
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    return true;
  }
  
  /// 生成随机密码
  static String generatePassword({
    int length = 16,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecial = true,
  }) {
    String chars = '';
    if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeNumbers) chars += '0123456789';
    if (includeSpecial) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    final random = DateTime.now().millisecondsSinceEpoch;
    return List.generate(length, (i) => chars[(random + i * 17) % chars.length]).join();
  }
}

class PasswordStrength {
  final double value;
  final int score;
  final int level;
  final Color color;
  final String label;
  
  PasswordStrength({
    required this.value,
    required this.score,
    required this.level,
    required this.color,
    required this.label,
  });
}

// 测试密码管理
void testPasswordManagement() {
  print('\n=== 密码管理测试 ===');
  
  // 测试密码强度计算
  final tests = ['123', 'password', 'Password1', 'Password123!', 'MyV3ry$tr0ngP@ssw0rd'];
  
  tests.forEach((pwd) {
    final strength = PasswordService.calculateStrength(pwd);
    print('密码 "$pwd" -> 强度: ${strength.label} (${strength.score}/7)');
  });
  
  // 测试密码验证
  print('\n密码验证:');
  print('Password1: ${PasswordService.validatePassword("Password1")}');
  print('weak: ${PasswordService.validatePassword("weak")}');
  print('Valid123: ${PasswordService.validatePassword("Valid123")}');
  
  // 测试密码生成
  print('\n密码生成:');
  print('默认: ${PasswordService.generatePassword()}');
  print('12位: ${PasswordService.generatePassword(length: 12)}');
  print('无特殊字符: ${PasswordService.generatePassword(includeSpecial: false)}');
}

// ============ 自动锁定机制测试 ============

class AutoLockManager {
  /// 锁定超时选项 (分钟)
  static const lockTimeoutOptions = [1, 5, 10, 15, 30, 60];
  
  /// 当前锁定设置
  static var _autoLockEnabled = true;
  static var _lockTimeoutMinutes = 5;
  static var _lastActiveTime = DateTime.now();
  
  /// 检查是否应该锁定
  static bool shouldLock() {
    if (!_autoLockEnabled) return false;
    
    final diff = DateTime.now().difference(_lastActiveTime).inMinutes;
    return diff >= _lockTimeoutMinutes;
  }
  
  /// 更新最后活动时间
  static void updateLastActive() {
    _lastActiveTime = DateTime.now();
  }
  
  /// 设置自动锁定
  static void setAutoLock(bool enabled, int minutes) {
    _autoLockEnabled = enabled;
    _lockTimeoutMinutes = minutes;
  }
  
  /// 获取锁定状态
  static Map<String, dynamic> getLockStatus() {
    return {
      'enabled': _autoLockEnabled,
      'timeout': _lockTimeoutMinutes,
      'lastActive': _lastActiveTime.toIso8601String(),
      'shouldLock': shouldLock(),
    };
  }
}

// 测试自动锁定
void testAutoLock() {
  print('\n=== 自动锁定测试 ===');
  
  // 测试初始状态
  print('1. 初始状态: ${AutoLockManager.getLockStatus()}');
  
  // 测试时间检查
  AutoLockManager.setAutoLock(true, 5);
  print('2. 设置5分钟超时: ${AutoLockManager.getLockStatus()}');
  
  // 模拟时间流逝
  AutoLockManager._lastActiveTime = DateTime.now().subtract(const Duration(minutes: 10));
  print('3. 10分钟后检查: shouldLock=${AutoLockManager.shouldLock()}');
  
  // 模拟刚活动
  AutoLockManager.updateLastActive();
  print('4. 更新活动时间: shouldLock=${AutoLockManager.shouldLock()}');
}

// ============ 安全风险测试 ============

class SecurityRiskTest {
  /// 风险级别
  static const riskLevels = {
    'critical': {'color': Colors.red, 'priority': 5},
    'high': {'color': Colors.orange, 'priority': 4},
    'medium': {'color': Colors.yellow, 'priority': 3},
    'low': {'color': Colors.blue, 'priority': 2},
    'info': {'color': Colors.grey, 'priority': 1},
  };
  
  /// 评估凭据安全性
  static Map<String, dynamic> assessCredential(String password) {
    final issues = <String>[];
    
    if (password.length < 8) issues.add('密码太短');
    if (!RegExp(r'[A-Z]').hasMatch(password)) issues.add('缺少大写字母');
    if (!RegExp(r'[0-9]').hasMatch(password)) issues.add('缺少数字');
    if (!RegExp(r'[!@#$%^&*]').hasMatch(password)) issues.add('缺少特殊字符');
    
    return {
      'issues': issues,
      'score': issues.isEmpty ? 100 : 100 - issues.length * 20,
      'level': issues.isEmpty ? 'low' : issues.length <= 1 ? 'medium' : 'high',
    };
  }
  
  /// 检测常见弱密码
  static bool isCommonPassword(String password) {
    const common = [
      '123456', 'password', '12345678', 'qwerty', '123456789',
      '12345', '1234', '111111', '1234567', 'dragon',
    ];
    return common.contains(password.toLowerCase());
  }
}

// 测试安全风险评估
void testSecurityRisks() {
  print('\n=== 安全风险测试 ===');
  
  // 测试凭据评估
  print('凭据评估:');
  print('  "password123": ${SecurityRiskTest.assessCredential("password123")}');
  print('  "MyStr0ngP@ss": ${SecurityRiskTest.assessCredential("MyStr0ngP@ss")}');
  
  // 测试弱密码检测
  print('\n弱密码检测:');
  print('  "password": ${SecurityRiskTest.isCommonPassword("password")}');
  print('  "MyStr0ngP@ss": ${SecurityRiskTest.isCommonPassword("MyStr0ngP@ss")}');
}

// ============ 主测试函数 ============

void main() {
  print('========================================');
  print('  PolyVault 安全模块测试');
  print('========================================');
  
  testBiometricAuth();
  testPasswordManagement();
  testAutoLock();
  testSecurityRisks();
  
  print('\n========================================');
  print('  所有测试完成');
  print('========================================');
}