# PolyVault 设置界面文档

**版本**: v1.0  
**创建时间**: 2026-03-14  
**适用对象**: 开发者、用户

---

## 📖 目录

1. [设置界面概述](#设置界面概述)
2. [安全设置](#安全设置)
3. [数据管理](#数据管理)
4. [关于](#关于)
5. [UI 组件说明](#ui-组件说明)
6. [状态管理](#状态管理)
7. [使用示例](#使用示例)
8. [开发指南](#开发指南)

---

## 设置界面概述

### 功能定位

设置界面是用户管理应用安全配置、数据备份和应用信息的核心入口。

### 设计原则

| 原则 | 说明 |
|------|------|
| **简洁直观** | 设置项分类清晰，操作直观 |
| **安全优先** | 安全设置置顶，重要操作需确认 |
| **即时反馈** | 设置变更立即生效并反馈 |
| **本地优先** | 所有设置本地存储，不上传云端 |

### 界面结构

```
设置
├── 安全设置
│   ├── 生物识别认证
│   ├── 自动锁定
│   └── 自动锁定时间
├── 数据管理
│   ├── 备份凭证
│   ├── 恢复凭证
│   └── 清除所有数据
└── 关于
    ├── 版本信息
    └── 开源协议
```

---

## 安全设置

### 1. 生物识别认证

**功能**: 启用/禁用指纹或面容 ID 解锁

**设置项**:
- **图标**: `Icons.fingerprint`
- **标题**: "生物识别认证"
- **副标题**: "使用指纹或面容 ID 解锁"
- **控件**: Switch 开关

**状态**:
- **默认**: 启用（如果设备支持）
- **存储**: `SecureStorageService.isBiometricAvailable()`

**实现逻辑**:
```dart
// 加载生物识别可用性
Future<void> _loadSettings() async {
  final storage = SecureStorageService();
  final isBiometricAvailable = await storage.isBiometricAvailable();
  
  setState(() {
    _isBiometricEnabled = isBiometricAvailable;
  });
}

// 切换生物识别
onChanged: (value) {
  setState(() {
    _isBiometricEnabled = value;
  });
  // TODO: 保存到安全存储
}
```

**平台差异**:

| 平台 | 生物识别方式 | API |
|------|-------------|-----|
| **iOS** | Face ID / Touch ID | LocalAuthentication |
| **Android** | 指纹 / 面容 / 虹膜 | BiometricPrompt |
| **Windows** | Windows Hello | Windows.Security.Credentials |
| **macOS** | Touch ID | LocalAuthentication |

---

### 2. 自动锁定

**功能**: 应用后台运行后自动锁定

**设置项**:
- **图标**: `Icons.lock_clock`
- **标题**: "自动锁定"
- **副标题**: "离开应用后自动锁定"
- **控件**: Switch 开关

**状态**:
- **默认**: 启用
- **存储**: `SharedPreferences` 或 `SecureStorage`

**实现逻辑**:
```dart
// 监听应用生命周期
@override
void initState() {
  super.initState();
  AppLifecycleListener(
    onStateChange: (state) {
      if (state == AppLifecycleState.paused && _isAutoLockEnabled) {
        _startAutoLockTimer();
      }
    },
  );
}
```

---

### 3. 自动授权规则配置

**功能**: 配置 eCAL 设备间自动授权规则

**设置项**:
- **图标**: `Icons.security`
- **标题**: "自动授权规则"
- **副标题**: "管理信任设备的自动授权"
- **操作**: 点击进入规则配置页面

#### 3.1 规则类型

| 规则 | 说明 | 默认 |
|------|------|------|
| **同网络自动授权** | 同一 WiFi 网络下自动授权 | 开启 |
| **首次配对确认** | 新设备首次连接需确认 | 开启 |
| **授权有效期** | 授权凭证有效时间 | 24 小时 |
| **自动续期** | 到期前自动续期 | 开启 |

#### 3.2 规则配置页面

```dart
class AutoAuthRulesScreen extends StatefulWidget {
  const AutoAuthRulesScreen({super.key});

  @override
  State<AutoAuthRulesScreen> createState() => _AutoAuthRulesScreenState();
}

class _AutoAuthRulesScreenState extends State<AutoAuthRulesScreen> {
  bool _isSameNetworkAutoAuth = true;
  bool _requireFirstPairConfirm = true;
  int _authValidityHours = 24;
  bool _autoRenew = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('自动授权规则'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRuleCard(
            icon: Icons.wifi,
            title: '同网络自动授权',
            subtitle: '同一 WiFi 网络下自动授权信任设备',
            trailing: Switch(
              value: _isSameNetworkAutoAuth,
              onChanged: (value) {
                setState(() {
                  _isSameNetworkAutoAuth = value;
                });
                _saveRules();
              },
            ),
          ),
          _buildRuleCard(
            icon: Icons.verified_user,
            title: '首次配对确认',
            subtitle: '新设备首次连接需要用户确认',
            trailing: Switch(
              value: _requireFirstPairConfirm,
              onChanged: (value) {
                setState(() {
                  _requireFirstPairConfirm = value;
                });
                _saveRules();
              },
            ),
          ),
          _buildRuleCard(
            icon: Icons.timer,
            title: '授权有效期',
            subtitle: '$_authValidityHours 小时',
            trailing: DropdownButton<int>(
              value: _authValidityHours,
              items: [1, 4, 8, 12, 24, 48, 72]
                .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text('$e 小时'),
                ))
                .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _authValidityHours = value;
                  });
                  _saveRules();
                }
              },
            ),
          ),
          if (_authValidityHours < 72)
            _buildRuleCard(
              icon: Icons.refresh,
              title: '自动续期',
              subtitle: '到期前 1 小时自动续期',
              trailing: Switch(
                value: _autoRenew,
                onChanged: (value) {
                  setState(() {
                    _autoRenew = value;
                  });
                  _saveRules();
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _saveRules() async {
    final rules = AutoAuthRules(
      sameNetworkAutoAuth: _isSameNetworkAutoAuth,
      requireFirstPairConfirm: _requireFirstPairConfirm,
      validityHours: _authValidityHours,
      autoRenew: _autoRenew,
    );
    await SecureStorageService().saveAuthRules(rules);
    
    // 通知 eCAL 服务更新规则
    await EcalService.updateAuthRules(rules);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('规则已保存')),
    );
  }
}
```

#### 3.3 规则存储结构

```dart
class AutoAuthRules {
  final bool sameNetworkAutoAuth;
  final bool requireFirstPairConfirm;
  final int validityHours;
  final bool autoRenew;

  AutoAuthRules({
    required this.sameNetworkAutoAuth,
    required this.requireFirstPairConfirm,
    required this.validityHours,
    required this.autoRenew,
  });

  // 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'same_network_auto_auth': sameNetworkAutoAuth,
      'require_first_pair_confirm': requireFirstPairConfirm,
      'validity_hours': validityHours,
      'auto_renew': autoRenew,
    };
  }

  // 从 JSON 反序列化
  factory AutoAuthRules.fromJson(Map<String, dynamic> json) {
    return AutoAuthRules(
      sameNetworkAutoAuth: json['same_network_auto_auth'] ?? true,
      requireFirstPairConfirm: json['require_first_pair_confirm'] ?? true,
      validityHours: json['validity_hours'] ?? 24,
      autoRenew: json['auto_renew'] ?? true,
    );
  }
}
```

#### 3.4 eCAL 集成

**规则应用到 eCAL 通信**:

```dart
class EcalAuthManager {
  AutoAuthRules _rules;

  EcalAuthManager() {
    _loadRules();
  }

  Future<void> _loadRules() async {
    _rules = await SecureStorageService().loadAuthRules();
  }

  // 检查是否自动授权
  Future<bool> shouldAutoAuthorize(DeviceInfo device) async {
    // 规则 1: 同网络自动授权
    if (_rules.sameNetworkAutoAuth && device.isOnSameNetwork) {
      return true;
    }

    // 规则 2: 首次配对确认
    if (_rules.requireFirstPairConfirm && device.isFirstTime) {
      return false; // 需要用户确认
    }

    // 规则 3: 检查授权有效期
    if (await _isAuthExpired(device)) {
      if (_rules.autoRenew) {
        await _renewAuth(device);
        return true;
      }
      return false;
    }

    return true;
  }

  // 检查授权是否过期
  Future<bool> _isAuthExpired(DeviceInfo device) async {
    final lastAuthTime = await _getLastAuthTime(device.id);
    final expiryTime = lastAuthTime.add(
      Duration(hours: _rules.validityHours),
    );
    return DateTime.now().isAfter(expiryTime);
  }

  // 续期授权
  Future<void> _renewAuth(DeviceInfo device) async {
    await _updateAuthTime(device.id);
    // 重新发送授权凭证
    await _sendAuthCredential(device);
  }
}
```

#### 3.5 安全考虑

**安全机制**:
- ✅ 所有规则加密存储（AES-256-GCM）
- ✅ 规则变更需生物认证
- ✅ 授权凭证定期轮换
- ✅ 异常行为检测（频繁授权请求）

**风险提示**:
⚠️ **警告**: 启用同网络自动授权可能带来安全风险，建议在可信网络环境下使用。

#### 3.6 使用场景

**场景 1: 家庭环境**
```
配置:
- 同网络自动授权：✅ 开启
- 首次配对确认：✅ 开启
- 授权有效期：24 小时
- 自动续期：✅ 开启

效果: 家庭设备间自动授权，新设备需确认一次
```

**场景 2: 办公环境**
```
配置:
- 同网络自动授权：❌ 关闭
- 首次配对确认：✅ 开启
- 授权有效期：8 小时
- 自动续期：❌ 关闭

效果: 每次连接都需确认，提高安全性
```

**场景 3: 高安全环境**
```
配置:
- 同网络自动授权：❌ 关闭
- 首次配对确认：✅ 开启
- 授权有效期：1 小时
- 自动续期：❌ 关闭

效果: 每次授权仅 1 小时有效，最大化安全
```

---

### 3. 自动锁定时间

**功能**: 设置自动锁定的延迟时间

**设置项**:
- **图标**: `Icons.timer`
- **标题**: "自动锁定时间"
- **副标题**: 显示当前设置（如 "5 分钟"）
- **控件**: DropdownButton

**可选值**:
| 值 | 显示 | 说明 |
|----|------|------|
| 1 | 1 分钟 | 快速锁定 |
| 5 | 5 分钟 | 默认推荐 |
| 10 | 10 分钟 | 宽松模式 |
| 30 | 30 分钟 | 极宽松 |

**实现逻辑**:
```dart
DropdownButton<int>(
  value: _autoLockDuration,
  items: [1, 5, 10, 30]
    .map((e) => DropdownMenuItem(
      value: e,
      child: Text('$e 分钟'),
    ))
    .toList(),
  onChanged: (value) {
    if (value != null) {
      setState(() {
        _autoLockDuration = value;
      });
      // TODO: 保存设置
    }
  },
)
```

---

## 数据管理

### 1. 备份凭证

**功能**: 导出加密备份文件

**设置项**:
- **图标**: `Icons.backup`
- **标题**: "备份凭证"
- **副标题**: "导出加密备份文件"
- **操作**: 点击触发备份流程

**备份流程**:
```
1. 用户点击"备份凭证"
   ↓
2. 提示设置备份密码（如果首次）
   ↓
3. 使用备份密码加密所有凭证
   ↓
4. 生成备份文件（.pvbackup）
   ↓
5. 选择保存位置（本地/云盘）
   ↓
6. 显示备份成功提示
```

**备份文件格式**:
```json
{
  "version": "1.0",
  "created_at": "2026-03-14T13:00:00Z",
  "encrypted_data": "...",
  "checksum": "sha256:..."
}
```

**实现代码**:
```dart
_buildSettingCard(
  icon: Icons.backup,
  title: '备份凭证',
  subtitle: '导出加密备份文件',
  onTap: () async {
    // TODO: 实现备份功能
    final backupService = BackupService();
    await backupService.exportBackup();
  },
)
```

---

### 2. 恢复凭证

**功能**: 从备份文件恢复凭证

**设置项**:
- **图标**: `Icons.restore`
- **标题**: "恢复凭证"
- **副标题**: "从备份文件恢复"
- **操作**: 点击触发恢复流程

**恢复流程**:
```
1. 用户点击"恢复凭证"
   ↓
2. 选择备份文件（.pvbackup）
   ↓
3. 输入备份密码
   ↓
4. 验证文件完整性（checksum）
   ↓
5. 解密备份数据
   ↓
6. 导入凭证到本地存储
   ↓
7. 显示恢复成功提示
```

**实现代码**:
```dart
_buildSettingCard(
  icon: Icons.restore,
  title: '恢复凭证',
  subtitle: '从备份文件恢复',
  onTap: () async {
    // TODO: 实现恢复功能
    final backupService = BackupService();
    await backupService.importBackup();
  },
)
```

---

### 3. 清除所有数据

**功能**: 删除所有存储的凭证（危险操作）

**设置项**:
- **图标**: `Icons.delete_forever`
- **标题**: "清除所有数据"
- **副标题**: "删除所有存储的凭证"
- **样式**: 红色警告样式 (`isDestructive: true`)
- **操作**: 点击触发确认对话框

**确认对话框**:
```dart
void _showClearDataConfirm() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('确认清除所有数据？'),
      content: Text(
        '此操作不可逆！所有凭证将被永久删除。'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            // 执行清除
            await SecureStorageService().deleteAll();
            Navigator.pop(context);
            // 显示成功提示
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: Text('确认删除'),
        ),
      ],
    ),
  );
}
```

**安全提示**:
⚠️ **警告**: 此操作不可逆，执行前务必备份重要凭证！

---

## 关于

### 1. 版本信息

**功能**: 显示应用版本号

**设置项**:
- **图标**: `Icons.info`
- **标题**: "版本信息"
- **副标题**: "PolyVault v0.1.0"

**版本号格式**:
```
v{主版本}.{次版本}.{修订版}
```

**获取版本号**:
```dart
import 'package:package_info_plus/package_info_plus.dart';

Future<String> getAppVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return 'v${packageInfo.version}';
}
```

---

### 2. 开源协议

**功能**: 查看应用使用的开源协议

**设置项**:
- **图标**: `Icons.description`
- **标题**: "开源协议"
- **副标题**: "查看许可证信息"
- **操作**: 点击显示协议详情

**协议内容**:
- MIT License
- 第三方库许可证列表

**实现代码**:
```dart
_buildSettingCard(
  icon: Icons.description,
  title: '开源协议',
  subtitle: '查看许可证信息',
  onTap: () {
    // TODO: 显示开源协议
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('MIT License'),
        content: SingleChildScrollView(
          child: Text(licenseText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  },
)
```

---

## UI 组件说明

### 设置卡片组件

**组件名**: `_buildSettingCard`

**参数**:
```dart
Widget _buildSettingCard({
  required IconData icon,        // 图标
  required String title,         // 标题
  required String subtitle,      // 副标题
  Widget? trailing,              // 右侧控件（Switch/Dropdown）
  VoidCallback? onTap,           // 点击事件
  bool isDestructive = false,    // 是否为危险操作
})
```

**样式**:
- **卡片**: 圆角 12px，无边框阴影
- **边框**: 0.5px 描边（outlineVariant 50% 透明度）
- **图标容器**: 8px 内边距，圆角 8px
- **图标背景**: 
  - 普通项：primaryContainer
  - 危险项：errorContainer

**代码实现**:
```dart
Widget _buildSettingCard({...}) {
  final colorScheme = Theme.of(context).colorScheme;

  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: colorScheme.outlineVariant.withOpacity(0.5),
      ),
    ),
    child: ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive
              ? colorScheme.errorContainer
              : colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? colorScheme.onErrorContainer
              : colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
    ),
  );
}
```

---

### 分组标题组件

**组件名**: `_buildSectionHeader`

**参数**:
```dart
Widget _buildSectionHeader(String title)
```

**样式**:
- **字体**: 14px，加粗（w600）
- **颜色**: primary
- **内边距**: 左 16px，下 8px

**代码实现**:
```dart
Widget _buildSectionHeader(String title) {
  return Padding(
    padding: const EdgeInsets.only(left: 16, bottom: 8),
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
```

---

## 状态管理

### 状态变量

| 变量 | 类型 | 说明 | 默认值 |
|------|------|------|--------|
| `_isBiometricEnabled` | bool | 生物识别启用状态 | 设备支持则为 true |
| `_isAutoLockEnabled` | bool | 自动锁定启用状态 | true |
| `_autoLockDuration` | int | 自动锁定时间（分钟） | 5 |
| `_isLoading` | bool | 加载状态 | true |

### 状态加载流程

```dart
@override
void initState() {
  super.initState();
  _loadSettings();
}

Future<void> _loadSettings() async {
  try {
    final storage = SecureStorageService();
    final isBiometricAvailable = await storage.isBiometricAvailable();

    setState(() {
      _isBiometricEnabled = isBiometricAvailable;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
  }
}
```

### 状态保存

**TODO**: 需要将设置保存到持久化存储

```dart
Future<void> _saveSettings() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('biometric_enabled', _isBiometricEnabled);
  await prefs.setBool('auto_lock_enabled', _isAutoLockEnabled);
  await prefs.setInt('auto_lock_duration', _autoLockDuration);
}
```

---

## 使用示例

### 打开设置页面

```dart
// 从主页面导航到设置页面
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => SettingsScreen()),
);
```

### 底部导航栏集成

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: '首页',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: '设置',
    ),
  ],
  onTap: (index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
    }
  },
)
```

---

## 开发指南

### 添加新设置项

1. **在对应分组添加设置卡片**:
```dart
_buildSettingCard(
  icon: Icons.new_feature,
  title: '新功能',
  subtitle: '功能说明',
  trailing: Switch(
    value: _isNewFeatureEnabled,
    onChanged: (value) {
      setState(() {
        _isNewFeatureEnabled = value;
      });
      _saveSettings();
    },
  ),
)
```

2. **添加状态变量**:
```dart
bool _isNewFeatureEnabled = false;
```

3. **实现保存逻辑**:
```dart
Future<void> _saveSettings() async {
  // ... 现有代码
  await prefs.setBool('new_feature_enabled', _isNewFeatureEnabled);
}
```

4. **加载设置**:
```dart
Future<void> _loadSettings() async {
  // ... 现有代码
  final newFeatureEnabled = prefs.getBool('new_feature_enabled') ?? false;
  setState(() {
    _isNewFeatureEnabled = newFeatureEnabled;
  });
}
```

---

### 主题适配

设置界面使用 Flutter Material 3 主题：

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
)
```

**暗色模式支持**:
```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  ),
)
```

---

## 待实现功能

### 高优先级

- [ ] 生物识别设置保存到安全存储
- [ ] 自动锁定定时器实现
- [ ] 备份功能实现
- [ ] 恢复功能实现
- [ ] 清除数据确认对话框

### 中优先级

- [ ] 设置变更实时同步到其他页面
- [ ] 备份文件加密实现
- [ ] 开源协议详情页面

### 低优先级

- [ ] 设置导入/导出
- [ ] 多语言支持
- [ ] 自定义主题

---

## 参考资源

- [Flutter Settings UI 最佳实践](https://docs.flutter.dev/ui/ui-build)
- [Material 3 设计指南](https://m3.material.io/)
- [本地存储最佳实践](https://docs.flutter.dev/data-and-backend/local-databases)

---

**文档维护**: PolyVault 开发团队  
**版本**: v1.0  
**创建时间**: 2026-03-14  
**反馈邮箱**: docs@polyvault.io
