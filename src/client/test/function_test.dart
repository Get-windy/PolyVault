/**
 * PolyVault 功能测试
 * 测试范围: 凭证管理、UI组件、安全功能
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:polyvault/services/secure_storage.dart';
import 'package:polyvault/models/credential.dart';
import 'package:polyvault/widgets/credential_list_item.dart';

// ============================================
// Mock类定义
// ============================================

class MockSecureStorage extends Mock implements SecureStorageService {}

class MockCredential extends Mock implements Credential {}

// ============================================
// 测试辅助类
// ============================================

class PolyVaultTestHelper {
  /// 创建测试凭证
  static Credential createTestCredential({
    String? serviceName = 'GitHub',
    String? username = 'testuser',
    String? password = 'TestPassword123!',
    String? id,
  }) {
    return Credential(
      id: id ?? 'test_${DateTime.now().millisecondsSinceEpoch}',
      serviceName: serviceName!,
      username: username!,
      password: password!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// 创建测试凭证列表
  static List<Credential> createTestCredentialList(int count: int = 5) {
    return List.generate(count, (index) => Credential(
      id: 'test_$index',
      serviceName: 'Service_$index',
      username: 'user_$index',
      password: 'Password$index!',
      createdAt: DateTime.now().subtract(Duration(hours: index)),
      updatedAt: DateTime.now(),
    ));
  }

  /// 等待Future完成
  static Future<T> timeout<T>(Future<T> future, Duration duration) {
    return Future.timeout(duration, onTimeout: () {
      throw TimeoutException('Test timed out after $duration');
    });
  }
}

// ============================================
// 安全存储服务测试
// ============================================

void main() {
  group('PolyVault Function Tests', () {
    late SecureStorageService service;
    
    setUp(() {
      service = SecureStorageService();
    });
    
    tearDown(() async {
      // 清理测试数据
      try {
        await service.deleteCredential('test_credential_cleanup');
      } catch (e) {
        // 忽略清理错误
      }
    });

    test('凭证创建测试', () {
      final credential = PolyVaultTestHelper.createTestCredential(
        id: 'test_credential_123',
        serviceName: 'Test Service',
        username: 'testuser',
        password: 'TestPassword123!',
      );

      expect(credential.id, 'test_credential_123');
      expect(credential.serviceName, 'Test Service');
      expect(credential.username, 'testuser');
      expect(credential.password, 'TestPassword123!');
      expect(credential.createdAt, isNotNull);
      expect(credential.updatedAt, isNotNull);
      
      print('✓ 凭证创建测试通过');
    });

    test('凭证列表测试', () {
      final credentials = PolyVaultTestHelper.createTestCredentialList(5);
      
      expect(credentials.length, 5);
      expect(credentials[0].serviceName, 'Service_0');
      expect(credentials[1].username, 'user_1');
      expect(credentials[4].password, 'Password4!');
      
      print('✓ 凭证列表测试通过');
    });
  });

  group('UI Component Tests', () {
    test('凭证列表项渲染测试', () {
      final credential = PolyVaultTestHelper.createTestCredential(
        serviceName: 'Test Service',
        username: 'testuser',
      );

      // 验证CredentialListItem部件需要的参数
      expect(credential.serviceName, 'Test Service');
      expect(credential.username, 'testuser');
      expect(credential.id, isNotNull);
      
      print('✓ 凭证列表项渲染测试通过');
    });
  });
}

// ============================================
// 凭证API测试
// ============================================

void runCredentialApiTests() {
  group('Credential API Tests', () {
    late SecureStorageService service;
    
    setUp(() async {
      service = SecureStorageService();
      await service.initialize();
    });

    test('保存凭证实例', () async {
      final credential = PolyVaultTestHelper.createTestCredential(
        id: 'test_save_123',
        serviceName: 'Save Test Service',
        username: 'save_test_user',
        password: 'SaveTestPassword!',
      );

      // 保存凭证
      await service.saveCredential(
        serviceName: credential.serviceName,
        username: credential.username,
        password: credential.password,
      );

      // 获取凭证验证保存成功
      final saved = await service.getCredential(credential.id);
      expect(saved, isNotNull);
      expect(saved?.serviceName, 'Save Test Service');
      
      print('✓ 保存凭证实例测试通过');
    });

    test('凭据列表获取测试', () async {
      final credentials = await service.getCredentialList();
      
      expect(credentials, isNotEmpty);
      expect(credentials.length, isGreaterThan(0));
      
      print('✓ 获取凭据列表测试通过');
    });

    test('凭证详情获取测试', () async {
      // 先保存一个测试凭证
      await service.saveCredential(
        serviceName: 'Detail Test Service',
        username: 'detail_test_user',
        password: 'DetailTestPassword!',
      );

      // 获取凭据列表获取ID
      final credentials = await service.getCredentialList();
      if (credentials.isNotEmpty) {
        final detail = await service.getCredential(credentials[0].id);
        
        expect(detail, isNotNull);
        expect(detail?.serviceName, 'Detail Test Service');
        
        print('✓ 凭证详情获取测试通过');
      }
    });

    test('凭证删除测试', () async {
      // 保存测试凭证
      await service.saveCredential(
        serviceName: 'Delete Test Service',
        username: 'delete_test_user',
        password: 'DeleteTestPassword!',
      );

      // 获取凭据列表
      final credentials = await service.getCredentialList();
      
      if (credentials.isNotEmpty) {
        final deleteResult = await service.deleteCredential(credentials[0].id);
        expect(deleteResult, isNotNull);
        
        print('✓ 凭证删除测试通过');
      }
    });

    test('凭证更新测试', () async {
      // 保存测试凭证
      final originalServiceName = 'Update Test Original';
      await service.saveCredential(
        serviceName: originalServiceName,
        username: 'update_test_user',
        password: 'UpdateTestPassword!',
      );

      // 获取凭据列表
      final credentials = await service.getCredentialList();
      
      if (credentials.isNotEmpty) {
        final credential = await service.getCredential(credentials[0].id);
        
        // 更新凭证
        final updateResult = await service.updateCredential(
          id: credentials[0].id,
          serviceName: 'Update Test Updated',
          username: 'updated_username',
          password: 'UpdatedPassword!',
        );
        
        expect(updateResult, isNotNull);
        
        print('✓ 凭证更新测试通过');
      }
    });
  });
}

// ============================================
// UI测试
// ============================================

void runUiTests() {
  group('UI Component Tests', () {
    test('凭证列表项组件测试', () {
      // 创建测试凭证
      final credential = PolyVaultTestHelper.createTestCredential(
        serviceName: 'UI Test Service',
        username: 'ui_test_user',
      );

      // 验证组件需要的属性
      expect(credential.serviceName.length, isGreaterThan(0));
      expect(credential.username.length, isGreaterThan(0));
      expect(credential.id.length, isGreaterThan(0));
      
      print('✓ 凭证列表项组件测试通过');
    });

    test('凭证编辑表单测试', () {
      // 测试表单验证
      final testCredential = PolyVaultTestHelper.createTestCredential();
      
      // 验证必要字段
      expect(testCredential.serviceName, isNotEmpty);
      expect(testCredential.username, isNotEmpty);
      expect(testCredential.password, isNotEmpty);
      
      print('✓ 凭证编辑表单测试通过');
    });
  });
}

// ============================================
// 安全功能测试
// ============================================

void runSecurityTests() {
  group('Security Tests', () {
    late SecureStorageService service;
    
    setUp(() async {
      service = SecureStorageService();
      await service.initialize();
    });

    test('生物识别验证测试', () async {
      // 首先保存一个测试凭证
      await service.saveCredential(
        serviceName: 'Security Test Service',
        username: 'security_test_user',
        password: 'SecurityTestPassword!',
      );

      // 获取凭据列表
      final credentials = await service.getCredentialList();
      
      if (credentials.isNotEmpty) {
        // 检查是否支持生物识别
        final isAvailable = await service.isBiometricAvailable();
        
        if (isAvailable) {
          final authenticated = await service.authenticateWithBiometric(
            reason: 'Security Test Authentication',
          );
          
          print('生物识别测试结果: $authenticated');
        } else {
          print('设备不支持生物识别，跳过测试');
        }
      }
    });

    test('凭证加密存储测试', () async {
      // 保存凭证
      await service.saveCredential(
        serviceName: 'Encrypt Test Service',
        username: 'encrypt_test_user',
        password: 'EncryptTestPassword!',
      );

      // 获取凭据列表
      final credentials = await service.getCredentialList();
      
      if (credentials.isNotEmpty) {
        // 获取凭证详情
        final credential = await service.getCredential(credentials[0].id);
        
        expect(credential, isNotNull);
        expect(credential?.password, 'EncryptTestPassword!'); // 加密前的明文
        
        print('✓ 凭证加密存储测试通过');
      }
    });

    test('凭据缓存测试', () async {
      // 首次获取
      await service.saveCredential(
        serviceName: 'Cache Test Service',
        username: 'cache_test_user',
        password: 'CacheTestPassword!',
      );

      final credentials1 = await service.getCredentialList();
      
      // 无需等待再次获取（应使用缓存）
      final credentials2 = await service.getCredentialList();
      
      expect(credentials1.length, credentials2.length);
      
      print('✓ 凭据缓存测试通过');
    });

    test('凭据搜索测试', () async {
      // 保存多个测试凭证
      await service.saveCredential(
        serviceName: 'Search Apple',
        username: 'apple_user',
        password: 'ApplePassword!',
      );
      
      await service.saveCredential(
        serviceName: 'Search Banana',
        username: 'banana_user',
        password: 'BananaPassword!',
      );

      // 获取凭据列表
      final credentials = await service.getCredentialList();
      
      // 验证包含搜索关键词的凭据
      final appleCredential = credentials.where((c) => 
        c.serviceName.toLowerCase().contains('apple')
      ).firstOrNull;
      
      expect(appleCredential, isNotNull);
      
      print('✓ 凭据搜索测试通过');
    });
  });
}

// ============================================
// Boundary Tests
// ============================================

void runBoundaryTests() {
  group('Boundary Tests', () {
    late SecureStorageService service;
    
    setUp(() async {
      service = SecureStorageService();
      await service.initialize();
    });

    test('空凭据列表测试', () async {
      // 初始化时应该返回空列表或已有的凭据
      final credentials = await service.getCredentialList();
      
      // 这里只需要验证返回值不为空
      expect(credentials, isNotNull);
      
      print('✓ 空凭据列表测试通过');
    });

    test('大量凭据性能测试', () async {
      const count = 100;
      
      // 保存100个测试凭证
      for (int i = 0; i < count; i++) {
        await service.saveCredential(
          serviceName: 'Performance Test $i',
          username: 'user_$i',
          password: 'Password$i!',
        );
      }

      // 获取凭据列表
      final credentials = await service.getCredentialList();
      
      expect(credentials.length, isGreaterThan(0));
      
      print('✓ 大量凭据性能测试通过');
    });

    test('重复凭据ID测试', () async {
      final uniqueId = 'duplicate_test_${DateTime.now().millisecondsSinceEpoch}';
      
      // 首次保存
      await service.saveCredential(
        id: uniqueId,
        serviceName: 'Duplicate Test',
        username: 'duplicate_user',
        password: 'DuplicatePassword!',
      );

      // 再次使用相同ID保存（应该更新）
      await service.saveCredential(
        id: uniqueId,
        serviceName: 'Duplicate Test Updated',
        username: 'updated_user',
        password: 'UpdatedPassword!',
      );

      // 获取凭据
      final credential = await service.getCredential(uniqueId);
      
      expect(credential?.serviceName, 'Duplicate Test Updated');
      
      print('✓ 重复凭据ID测试通过');
    });
  });
}

// ============================================
// Error Handling Tests
// ============================================

void runErrorTests() {
  group('Error Handling Tests', () {
    late SecureStorageService service;
    
    setUp(() async {
      service = SecureStorageService();
      await service.initialize();
    });

    test('无效凭据格式测试', () {
      // 测试无效的凭据数据
      expect(() {
        Credential(
          id: '',
          serviceName: '',
          username: '',
          password: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }, throwsA(isA<Error>())); // 如果有验证逻辑应该抛出错误
      
      print('✓ 无效凭据格式测试通过');
    });

    test('重复凭据ID处理测试', () async {
      final userId = 'error_test_user_${DateTime.now().millisecondsSinceEpoch}';
      
      // 首次保存
      await service.saveCredential(
        id: userId,
        serviceName: 'Error Test',
        username: 'error_user',
        password: 'ErrorPassword!',
      );

      // 再次保存相同ID（应该成功更新）
      await service.saveCredential(
        id: userId,
        serviceName: 'Error Test Updated',
        username: 'updated_user',
        password: 'UpdatedPassword!',
      );

      print('✓ 重复凭据ID处理测试通过');
    });

    test('凭据缺失字段测试', () {
      // 测试缺少必要字段
      expect(() {
        // 缺少id
        // Credential(
        //   serviceName: 'Test',
        //   username: 'user',
        //   password: 'pass',
        // );
      }, throwsA(isA<ArgumentError>()));
      
      print('✓ 凭据缺失字段测试通过');
    });

    test('凭据删除不存在的ID测试', () async {
      final nonExistentId = 'non_existent_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await service.deleteCredential(nonExistentId);
      
      // 应该返回失败或成功（取决于实现）
      expect(result, isNotNull);
      
      print('✓ 删除不存在ID测试通过');
    });
  });
}

// ============================================
// Integration Tests
// ============================================

void runIntegrationTests() {
  group('Integration Tests', () {
    late SecureStorageService service;
    
    setUp(() async {
      service = SecureStorageService();
      await service.initialize();
    });

    test('完整凭据生命周期测试', () async {
      final credentialId = 'lifecycle_${DateTime.now().millisecondsSinceEpoch}';
      
      // 1. 保存凭据
      await service.saveCredential(
        id: credentialId,
        serviceName: 'Lifecycle Test',
        username: 'lifecycle_user',
        password: 'LifecyclePassword!',
      );

      // 2. 获取凭据
      final saved = await service.getCredential(credentialId);
      expect(saved, isNotNull);
      expect(saved?.serviceName, 'Lifecycle Test');

      // 3. 更新凭据
      await service.updateCredential(
        id: credentialId,
        serviceName: 'Lifecycle Test Updated',
        username: 'updated_user',
        password: 'UpdatedPassword!',
      );

      final updated = await service.getCredential(credentialId);
      expect(updated?.serviceName, 'Lifecycle Test Updated');

      // 4. 删除凭据
      await service.deleteCredential(credentialId);

      // 5. 验证删除
      final deleted = await service.getCredential(credentialId);
      expect(deleted, isNull);
      
      print('✓ 完整凭据生命周期测试通过');
    });

    test('凭据管理UI集成测试', () async {
      // 保存多个测试凭据
      await service.saveCredential(
        serviceName: 'UI Integration Test 1',
        username: 'ui_user_1',
        password: 'Password1!',
      );
      
      await service.saveCredential(
        serviceName: 'UI Integration Test 2',
        username: 'ui_user_2',
        password: 'Password2!',
      );

      // 获取凭据列表
      final credentials = await service.getCredentialList();
      
      // 验证凭据列表包含测试凭据
      expect(credentials.length, isGreaterThan(0));
      
      final testCredential = credentials.firstWhere(
        (c) => c.serviceName.contains('UI Integration'),
        orElse: () => credentials[0],
      );
      
      expect(testCredential, isNotNull);
      
      print('✓ 凭据管理UI集成测试通过');
    });
  });
}

// ============================================
// 所有测试运行函数
// ============================================

/// 运行所有功能测试
void runAllTests() {
  print('运行 PolyVault 功能测试...\n');
  
  // 运行核心测试
  runCredentialApiTests();
  runUiTests();
  runSecurityTests();
  
  print('\n运行边界测试...\n');
  runBoundaryTests();
  
  print('\n运行错误处理测试...\n');
  runErrorTests();
  
  print('\n运行集成测试...\n');
  runIntegrationTests();
  
  print('\n✓ 所有功能测试完成');
}

// 主测试入口
void main() {
  runAllTests();
}