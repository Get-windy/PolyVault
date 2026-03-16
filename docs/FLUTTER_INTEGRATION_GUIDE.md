# PolyVault Flutter 客户端集成指南

**版本**: v1.0  
**创建时间**: 2026-03-15  
**适用对象**: Flutter 开发者、客户端集成工程师

---

## 📖 目录

1. [概述](#概述)
2. [快速开始](#快速开始)
3. [核心模块集成](#核心模块集成)
4. [eCAL 通信集成](#ecal-通信集成)
5. [密码箱 UI 组件](#密码箱-ui-组件)
6. [生物认证集成](#生物认证集成)
7. [插件系统](#插件系统)
8. [调试与测试](#调试与测试)
9. [构建与发布](#构建与发布)

---

## 🎯 概述

### PolyVault Flutter 客户端架构

```
┌─────────────────────────────────────────────────────────┐
│                   Flutter Application                    │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┬─────────────┬─────────────┐           │
│  │   UI Layer  │  Business   │   Data      │           │
│  │  (Widgets)  │   Logic     │   Layer     │           │
│  │             │  (BLoC)     │  (Repository)            │
│  └─────────────┴─────────────┴─────────────┘           │
│                        │                                │
│                  Flutter Plugin                         │
│                        │                                │
├────────────────────────┼────────────────────────────────┤
│                        │                                │
│  ┌─────────────────────┼─────────────────────┐         │
│  │                     │                     │         │
│  ▼                     ▼                     ▼         │
│ ┌──────────┐     ┌──────────┐     ┌──────────┐        │
│ │  eCAL    │     │  Native  │     │  Plugin  │        │
│ │ Binding  │     │  Crypto  │     │  System  │        │
│ └──────────┘     └──────────┘     └──────────┘        │
│                                                        │
│                    C++ Core Library                    │
└─────────────────────────────────────────────────────────┘
```

### 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| **UI** | Flutter 3.x | 跨平台 UI 框架 |
| **状态管理** | flutter_bloc | BLoC 模式 |
| **通信** | eCAL | 软总线通信 |
| **加密** | libsodium + Rust FFI | 密码学原语 |
| **存储** | Hive + ObjectBox | 本地加密存储 |
| **生物认证** | local_auth | 指纹/面部识别 |

---

## 🚀 快速开始

### 1. 环境准备

#### 安装 Flutter

```bash
# Windows
choco install flutter

# macOS
brew install --cask flutter

# Linux
sudo snap install flutter --classic

# 验证安装
flutter doctor
```

#### 配置开发环境

```bash
# 启用桌面支持
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# 检查设备
flutter devices
```

---

### 2. 创建项目

#### 使用模板创建

```bash
# 克隆 PolyVault Flutter 模板
git clone https://github.com/polyvault/flutter-template.git my-polyvault-app
cd my-polyvault-app

# 安装依赖
flutter pub get

# 运行项目
flutter run -d windows
```

#### 手动创建

```bash
# 创建新项目
flutter create --org com.polyvault --platforms=windows,macos,linux,android,ios polyvault_app

# 添加 PolyVault 依赖
cd polyvault_app

# 编辑 pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # PolyVault 核心
  polyvault_core: ^1.0.0
  polyvault_ecal: ^1.0.0
  polyvault_crypto: ^1.0.0
  
  # 状态管理
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2
  
  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  objectbox: ^3.0.0
  
  # 生物认证
  local_auth: ^2.1.6
  
  # 其他工具
  get_it: ^7.6.4  # 依赖注入
  dio: ^5.4.0     # HTTP 客户端
  protobuf: ^3.1.0 # Protobuf 支持
```

---

### 3. 项目结构

```
lib/
├── main.dart                    # 应用入口
├── app.dart                     # 应用配置
│
├── core/                        # 核心模块
│   ├── polyvault_core.dart     # PolyVault 核心封装
│   ├── ecal/                   # eCAL 通信
│   │   ├── ecal_manager.dart   # eCAL 管理器
│   │   ├── publisher.dart      # 发布服务
│   │   └── subscriber.dart     # 订阅服务
│   ├── crypto/                 # 加密模块
│   │   ├── vault.dart          # 密码箱
│   │   ├── keychain.dart       # 密钥链
│   │   └── secure_storage.dart # 安全存储
│   └── plugin/                 # 插件系统
│       ├── plugin_manager.dart # 插件管理器
│       └── plugin_registry.dart # 插件注册
│
├── features/                    # 功能模块
│   ├── auth/                   # 认证
│   │   ├── auth_bloc.dart
│   │   ├── auth_screen.dart
│   │   └── biometric_auth.dart # 生物认证
│   ├── vault/                  # 密码箱
│   │   ├── vault_bloc.dart
│   │   ├── vault_screen.dart
│   │   └── credential_list.dart
│   └── settings/               # 设置
│       ├── settings_bloc.dart
│       └── settings_screen.dart
│
├── ui/                          # UI 组件
│   ├── widgets/                # 通用组件
│   ├── theme/                  # 主题
│   └── dialogs/                # 对话框
│
└── utils/                       # 工具类
    ├── constants.dart
    └── extensions.dart
```

---

## 🔌 核心模块集成

### 1. eCAL 通信集成

#### 初始化 eCAL

```dart
// lib/core/ecal/ecal_manager.dart
import 'package:polyvault_ecal/polyvault_ecal.dart';

class EcalManager {
  static final EcalManager _instance = EcalManager._internal();
  factory EcalManager() => _instance;
  EcalManager._internal();
  
  EcalCore? _ecal;
  bool _initialized = false;
  
  /// 初始化 eCAL
  Future<bool> initialize({
    required String appName,
    String? configPath,
  }) async {
    if (_initialized) return true;
    
    try {
      _ecal = EcalCore();
      
      // 初始化 eCAL
      final result = await _ecal!.initialize(
        appName: appName,
        configPath: configPath,
      );
      
      if (result) {
        _initialized = true;
        print('✅ eCAL initialized successfully');
      }
      
      return result;
    } catch (e) {
      print('❌ eCAL initialization failed: $e');
      return false;
    }
  }
  
  /// 创建发布者
  Publisher createPublisher(String topicName) {
    if (!_initialized) throw StateError('eCAL not initialized');
    return _ecal!.createPublisher(topicName);
  }
  
  /// 创建订阅者
  Subscriber createSubscriber(String topicName) {
    if (!_initialized) throw StateError('eCAL not initialized');
    return _ecal!.createSubscriber(topicName);
  }
  
  /// 创建 RPC 服务器
  RpcServer createRpcServer(String serviceName) {
    if (!_initialized) throw StateError('eCAL not initialized');
    return _ecal!.createRpcServer(serviceName);
  }
  
  /// 创建 RPC 客户端
  RpcClient createRpcClient(String serviceName) {
    if (!_initialized) throw StateError('eCAL not initialized');
    return _ecal!.createRpcClient(serviceName);
  }
  
  /// 关闭 eCAL
  Future<void> shutdown() async {
    if (_initialized) {
      await _ecal?.shutdown();
      _initialized = false;
      print('🛑 eCAL shutdown complete');
    }
  }
}
```

---

#### 发布/订阅示例

```dart
// lib/features/vault/vault_service.dart
import '../core/ecal/ecal_manager.dart';
import '../core/ecal/subscriber.dart';

class VaultService {
  final EcalManager _ecalManager = EcalManager();
  late Publisher _publisher;
  late Subscriber _subscriber;
  
  // 主题定义
  static const String TOPIC_VAULT_REQUEST = 'polyvault.vault.request';
  static const String TOPIC_VAULT_RESPONSE = 'polyvault.vault.response';
  
  /// 初始化服务
  Future<void> initialize() async {
    // 初始化 eCAL
    await _ecalManager.initialize(appName: 'PolyVault Flutter');
    
    // 创建发布者和订阅者
    _publisher = _ecalManager.createPublisher(TOPIC_VAULT_REQUEST);
    _subscriber = _ecalManager.createSubscriber(TOPIC_VAULT_RESPONSE);
    
    // 订阅响应
    _subscriber.subscribe((topic, data, timestamp) {
      _handleResponse(data);
    });
  }
  
  /// 获取凭证
  Future<Credential?> getCredential(String serviceUrl) async {
    // 创建请求
    final request = VaultRequest(
      action: VaultAction.GET,
      serviceUrl: serviceUrl,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    // 发布请求
    await _publisher.publish(request.toBytes());
    
    // 等待响应（带超时）
    return await _waitForResponse(timeout: Duration(seconds: 5));
  }
  
  /// 存储凭证
  Future<bool> storeCredential(Credential credential) async {
    final request = VaultRequest(
      action: VaultAction.STORE,
      credential: credential,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    
    await _publisher.publish(request.toBytes());
    
    final response = await _waitForResponse(timeout: Duration(seconds: 5));
    return response?.success ?? false;
  }
  
  void _handleResponse(Uint8List data) {
    // 处理响应数据
    final response = VaultResponse.fromBytes(data);
    // 更新状态...
  }
  
  Future<Credential?> _waitForResponse({required Duration timeout}) async {
    // 实现等待逻辑
    // ...
    return null;
  }
}
```

---

### 2. 密码箱集成

#### 安全存储封装

```dart
// lib/core/crypto/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class SecureStorage {
  static final SecureStorage _instance = SecureStorage._internal();
  factory SecureStorage() => _instance;
  SecureStorage._internal();
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  
  /// 加密并存储
  Future<void> write({
    required String key,
    required String value,
    required String masterKey,
  }) async {
    // 生成加密密钥
    final encryptionKey = _deriveKey(masterKey, key);
    
    // 加密数据
    final encrypted = _encrypt(value, encryptionKey);
    
    // 存储
    await _storage.write(key: key, value: encrypted);
  }
  
  /// 读取并解密
  Future<String?> read({
    required String key,
    required String masterKey,
  }) async {
    final encrypted = await _storage.read(key: key);
    if (encrypted == null) return null;
    
    // 解密密钥
    final encryptionKey = _deriveKey(masterKey, key);
    
    // 解密数据
    return _decrypt(encrypted, encryptionKey);
  }
  
  /// 删除
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
  
  /// 清除所有
  Future<void> clear() async {
    await _storage.deleteAll();
  }
  
  /// 派生加密密钥
  Uint8List _deriveKey(String masterKey, String salt) {
    final key = sha256.convert(
      utf8.encode('$masterKey$salt'),
    ).bytes;
    return Uint8List.fromList(key);
  }
  
  /// 加密
  String _encrypt(String plainText, Uint8List key) {
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.gcm,
    ));
    
    final iv = encrypt.IV.fromLength(12);
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    return '${base64Encode(iv.bytes)}:${encrypted.base64}';
  }
  
  /// 解密
  String _decrypt(String encrypted, Uint8List key) {
    final parts = encrypted.split(':');
    if (parts.length != 2) throw FormatException('Invalid encrypted format');
    
    final iv = encrypt.IV(Uint8List.fromList(base64Decode(parts[0])));
    final encryptedData = parts[1];
    
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(key),
      mode: encrypt.AESMode.gcm,
    ));
    
    return encrypter.decrypt64(encryptedData, iv: iv);
  }
}
```

---

#### 密码箱 BLoC

```dart
// lib/features/vault/vault_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'vault_service.dart';
import '../../core/crypto/secure_storage.dart';

// 事件
abstract class VaultEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadCredentials extends VaultEvent {}
class AddCredential extends VaultEvent {
  final Credential credential;
  AddCredential(this.credential);
  @override
  List<Object?> get props => [credential];
}
class UpdateCredential extends VaultEvent {
  final Credential credential;
  UpdateCredential(this.credential);
  @override
  List<Object?> get props => [credential];
}
class DeleteCredential extends VaultEvent {
  final String id;
  DeleteCredential(this.id);
  @override
  List<Object?> get props => [id];
}

// 状态
class VaultState extends Equatable {
  final List<Credential> credentials;
  final bool isLoading;
  final String? error;
  
  const VaultState({
    required this.credentials,
    this.isLoading = false,
    this.error,
  });
  
  @override
  List<Object?> get props => [credentials, isLoading, error];
  
  VaultState copyWith({
    List<Credential>? credentials,
    bool? isLoading,
    String? error,
  }) {
    return VaultState(
      credentials: credentials ?? this.credentials,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  static const initial = VaultState(credentials: []);
}

// BLoC
class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final VaultService _vaultService;
  final SecureStorage _secureStorage;
  
  VaultBloc({
    required VaultService vaultService,
    required SecureStorage secureStorage,
  })  : _vaultService = vaultService,
        _secureStorage = secureStorage,
        super(VaultState.initial) {
    on<LoadCredentials>(_onLoadCredentials);
    on<AddCredential>(_onAddCredential);
    on<UpdateCredential>(_onUpdateCredential);
    on<DeleteCredential>(_onDeleteCredential);
  }
  
  Future<void> _onLoadCredentials(
    LoadCredentials event,
    Emitter<VaultState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      final credentials = await _vaultService.getAllCredentials();
      emit(state.copyWith(
        credentials: credentials,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
  
  Future<void> _onAddCredential(
    AddCredential event,
    Emitter<VaultState> emit,
  ) async {
    try {
      await _vaultService.storeCredential(event.credential);
      final credentials = List<Credential>.from(state.credentials)
        ..add(event.credential);
      emit(state.copyWith(credentials: credentials));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
  
  // ... 其他事件处理
}
```

---

## 🔐 生物认证集成

### 1. 配置权限

#### Android

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- 生物认证权限 -->
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <uses-permission android:name="android.permission.USE_FINGERPRINT"/>
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

#### iOS

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- 生物认证使用说明 -->
    <key>NSFaceIDUsageDescription</key>
    <string>使用 Face ID 保护您的密码箱安全</string>
</dict>
```

---

### 2. 生物认证服务

```dart
// lib/features/auth/biometric_auth.dart
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricAuth {
  static final BiometricAuth _instance = BiometricAuth._internal();
  factory BiometricAuth() => _instance;
  BiometricAuth._internal();
  
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  /// 检查是否支持生物认证
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }
  
  /// 检查是否有可用的生物特征
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }
  
  /// 获取支持的生物认证类型
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    }
  }
  
  /// 执行生物认证
  Future<bool> authenticate({
    String reason = '请验证身份以访问密码箱',
    bool useBiometricOnly = true,
  }) async {
    try {
      final isAvailable = await canCheckBiometrics();
      if (!isAvailable) return false;
      
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('生物认证失败：$e');
      return false;
    }
  }
  
  /// 使用生物认证解锁密码箱
  Future<bool> unlockVault({
    required String masterKeyHash,
  }) async {
    final authenticated = await authenticate(
      reason: '验证身份以解锁密码箱',
    );
    
    if (!authenticated) return false;
    
    // 生物认证通过，允许访问密码箱
    // 实际解密逻辑在 native 层完成
    return true;
  }
}
```

---

### 3. 生物认证 UI

```dart
// lib/features/auth/biometric_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'biometric_auth.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({Key? key}) : super(key: key);
  
  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final BiometricAuth _biometricAuth = BiometricAuth();
  bool _isSupported = false;
  bool _isLoading = true;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
  }
  
  Future<void> _checkBiometricSupport() async {
    setState(() => _isLoading = true);
    
    try {
      final isSupported = await _biometricAuth.isDeviceSupported();
      final canCheck = await _biometricAuth.canCheckBiometrics();
      
      setState(() {
        _isSupported = isSupported && canCheck;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _authenticate() async {
    final success = await _biometricAuth.authenticate(
      reason: '验证身份以访问 PolyVault',
    );
    
    if (!mounted) return;
    
    if (success) {
      // 认证成功
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 认证成功'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 导航到主界面
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      // 认证失败
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ 认证失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (!_isSupported) {
      return Scaffold(
        appBar: AppBar(title: const Text('生物认证')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.fingerprint,
                size: 100,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                '您的设备不支持生物认证',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 使用密码解锁
                  Navigator.of(context).pushNamed('/password');
                },
                child: const Text('使用密码解锁'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('生物认证')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              '请使用生物特征验证身份',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.fingerprint),
              label: const Text('验证'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔌 插件系统

### 1. Flutter 插件开发

```dart
// lib/core/plugin/plugin_manager.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PluginManager {
  static final PluginManager _instance = PluginManager._internal();
  factory PluginManager() => _instance;
  PluginManager._internal();
  
  final Map<String, PluginInfo> _plugins = {};
  final Map<String, dynamic> _pluginInstances = {};
  
  /// 加载所有插件
  Future<void> loadPlugins() async {
    final pluginDir = await _getPluginDirectory();
    
    if (!await pluginDir.exists()) {
      await pluginDir.create(recursive: true);
      return;
    }
    
    await for (final entity in pluginDir.list()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        await _loadPlugin(entity);
      }
    }
  }
  
  /// 加载单个插件
  Future<void> _loadPlugin(File pluginFile) async {
    try {
      // 读取插件清单
      final manifest = await _readManifest(pluginFile);
      
      // 验证插件
      if (!_validatePlugin(manifest)) {
        print('插件验证失败：${manifest['id']}');
        return;
      }
      
      // 加载插件
      final plugin = await _instantiatePlugin(pluginFile, manifest);
      
      // 注册插件
      _plugins[manifest['id']] = PluginInfo.fromMap(manifest);
      _pluginInstances[manifest['id']] = plugin;
      
      print('✅ 插件加载成功：${manifest['name']}');
    } catch (e) {
      print('❌ 插件加载失败：${pluginFile.path} - $e');
    }
  }
  
  /// 获取插件目录
  Future<Directory> _getPluginDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/plugins');
  }
  
  /// 读取插件清单
  Future<Map<String, dynamic>> _readManifest(File pluginFile) async {
    // 实现清单读取逻辑
    return {};
  }
  
  /// 验证插件
  bool _validatePlugin(Map<String, dynamic> manifest) {
    return manifest.containsKey('id') &&
           manifest.containsKey('name') &&
           manifest.containsKey('version');
  }
  
  /// 实例化插件
  Future<dynamic> _instantiatePlugin(
    File pluginFile,
    Map<String, dynamic> manifest,
  ) async {
    // 实现插件实例化逻辑
    return null;
  }
  
  /// 获取已加载的插件
  List<PluginInfo> getLoadedPlugins() {
    return _plugins.values.toList();
  }
  
  /// 启用插件
  Future<void> enablePlugin(String pluginId) async {
    if (!_plugins.containsKey(pluginId)) {
      throw Exception('插件不存在：$pluginId');
    }
    
    // 实现启用逻辑
  }
  
  /// 禁用插件
  Future<void> disablePlugin(String pluginId) async {
    if (!_plugins.containsKey(pluginId)) {
      throw Exception('插件不存在：$pluginId');
    }
    
    // 实现禁用逻辑
  }
  
  /// 卸载插件
  Future<void> uninstallPlugin(String pluginId) async {
    if (!_plugins.containsKey(pluginId)) {
      throw Exception('插件不存在：$pluginId');
    }
    
    // 实现卸载逻辑
    _plugins.remove(pluginId);
    _pluginInstances.remove(pluginId);
  }
}

class PluginInfo {
  final String id;
  final String name;
  final String version;
  final String description;
  final bool enabled;
  
  PluginInfo({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    this.enabled = true,
  });
  
  factory PluginInfo.fromMap(Map<String, dynamic> map) {
    return PluginInfo(
      id: map['id'],
      name: map['name'],
      version: map['version'],
      description: map['description'],
      enabled: map['enabled'] ?? true,
    );
  }
}
```

---

## 🐛 调试与测试

### 1. 调试模式

```dart
// lib/main.dart
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 启用调试模式
  if (kDebugMode) {
    await _enableDebugFeatures();
  }
  
  runApp(const PolyVaultApp());
}

Future<void> _enableDebugFeatures() async {
  // 启用详细日志
  debugPrint = (String? message, {int? wrapWidth}) {
    print('[DEBUG] $message');
  };
  
  // 启用性能覆盖
  // debugPaintSizeEnabled = true;
  
  // 启用 eCAL 调试
  // EcalManager().enableDebugLogging();
}
```

---

### 2. 单元测试

```dart
// test/vault_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:polyvault_app/features/vault/vault_service.dart';
import 'package:polyvault_app/core/ecal/ecal_manager.dart';

@GenerateMocks([EcalManager, Publisher, Subscriber])
void main() {
  group('VaultService Tests', () {
    late VaultService vaultService;
    late MockEcalManager mockEcalManager;
    late MockPublisher mockPublisher;
    late MockSubscriber mockSubscriber;
    
    setUp(() {
      mockEcalManager = MockEcalManager();
      mockPublisher = MockPublisher();
      mockSubscriber = MockSubscriber();
      
      when(mockEcalManager.createPublisher(any)).thenReturn(mockPublisher);
      when(mockEcalManager.createSubscriber(any)).thenReturn(mockSubscriber);
      
      vaultService = VaultService(ecalManager: mockEcalManager);
    });
    
    test('initialize should setup eCAL', () async {
      when(mockEcalManager.initialize(appName: anyNamed('appName')))
          .thenAnswer((_) async => true);
      
      await vaultService.initialize();
      
      verify(mockEcalManager.initialize(appName: anyNamed('appName'))).called(1);
      verify(mockEcalManager.createPublisher(any)).called(1);
      verify(mockEcalManager.createSubscriber(any)).called(1);
    });
    
    test('getCredential should publish request', () async {
      await vaultService.initialize();
      
      when(mockPublisher.publish(any)).thenAnswer((_) async => true);
      
      await vaultService.getCredential('https://example.com');
      
      verify(mockPublisher.publish(any)).called(1);
    });
  });
}
```

---

## 📦 构建与发布

### 1. Windows 构建

```bash
# 构建 Windows 版本
flutter build windows --release

# 输出位置
# build/windows/runner/Release/
```

### 2. macOS 构建

```bash
# 构建 macOS 版本
flutter build macos --release

# 创建 DMG
create-dmg \
  --volname "PolyVault" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --app-drop-link 600 185 \
  "PolyVault.dmg" \
  "build/macos/Build/Products/Release/PolyVault.app"
```

### 3. Linux 构建

```bash
# 构建 Linux 版本
flutter build linux --release

# 创建 AppImage
linuxdeploy \
  --appdir AppDir \
  --executable build/linux/x64/release/bundle/polyvault \
  --output appimage
```

---

## 📞 支持与反馈

- **文档**: https://docs.polyvault.io/flutter
- **GitHub**: https://github.com/polyvault/flutter-client
- **Discord**: https://discord.gg/polyvault

---

**文档维护**: PolyVault Core Team  
**反馈邮箱**: dev@polyvault.io  
**最后更新**: 2026-03-15
