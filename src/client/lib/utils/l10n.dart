import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 支持的语言
enum AppLanguage {
  chinese('zh', '中文'),
  english('en', 'English');

  final String code;
  final String displayName;
  const AppLanguage(this.code, this.displayName);
}

/// 本地化服务
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// 字符串资源
  static final Map<String, Map<String, String>> _localizedValues = {
    'zh': {
      // 导航
      'nav_home': '设备状态',
      'nav_credentials': '凭证管理',
      'nav_devices': '设备',
      'nav_settings': '设置',
      
      // 首页
      'home_title': 'PolyVault',
      'home_device_status': '设备状态',
      'home_security_status': '安全状态',
      'home_statistics': '统计',
      'home_quick_actions': '快速操作',
      'home_add_credential': '添加凭证',
      'home_sync_device': '同步设备',
      'home_connected': '已连接',
      'home_disconnected': '未连接',
      'home_biometric_available': '生物识别可用',
      'home_biometric_unavailable': '生物识别不可用',
      'home_hardware_secure': '硬件安全',
      'home_encryption': '加密级别',
      
      // 凭证管理
      'credentials_title': '凭证管理',
      'credentials_empty': '暂无凭证',
      'credentials_empty_hint': '点击下方按钮添加您的第一个凭证',
      'credentials_add': '添加凭证',
      'credentials_edit': '编辑凭证',
      'credentials_delete': '删除',
      'credentials_service_name': '服务名称',
      'credentials_username': '用户名',
      'credentials_password': '密码',
      'credentials_notes': '备注',
      'credentials_save': '保存',
      'credentials_cancel': '取消',
      'credentials_delete_confirm': '确认删除',
      'credentials_delete_message': '确定要删除此凭证吗？',
      'credentials_copied': '已复制到剪贴板',
      'credentials_added': '凭证已保存',
      'credentials_deleted': '凭证已删除',
      'credentials_load_failed': '加载凭证失败',
      'credentials_save_failed': '保存失败',
      'credentials_delete_failed': '删除失败',
      
      // 设备管理
      'devices_title': '设备',
      'devices_empty': '暂无设备',
      'devices_empty_hint': '添加您的第一个设备开始使用',
      'devices_add': '添加设备',
      'devices_scan_qr': '扫描二维码',
      'devices_manual_input': '手动输入',
      'devices_connect': '连接',
      'devices_disconnect': '断开连接',
      'devices_delete': '删除设备',
      'devices_trust': '信任设备',
      'devices_untrust': '取消信任',
      'devices_online': '在线',
      'devices_offline': '离线',
      'devices_connecting': '连接中',
      'devices_last_seen': '最后在线',
      'devices_paired_at': '配对时间',
      'devices_platform': '平台',
      'devices_ip': 'IP地址',
      'devices_device_id': '设备ID',
      'devices_scan_complete': '扫描完成',
      'devices_added': '已添加新设备',
      'devices_deleted': '已删除设备',
      'devices_connected': '已连接到设备',
      'devices_disconnected': '已断开设备',
      
      // 设置
      'settings_title': '设置',
      'settings_appearance': '外观',
      'settings_dark_mode': '深色模式',
      'settings_security': '安全设置',
      'settings_biometric': '生物识别认证',
      'settings_biometric_hint': '使用指纹或面容ID解锁',
      'settings_auto_lock': '自动锁定',
      'settings_auto_lock_hint': '离开应用后自动锁定',
      'settings_auto_lock_time': '自动锁定时间',
      'settings_data': '数据管理',
      'settings_backup': '备份凭证',
      'settings_backup_hint': '导出加密备份文件',
      'settings_restore': '恢复凭证',
      'settings_restore_hint': '从备份文件恢复',
      'settings_clear_data': '清除所有数据',
      'settings_clear_data_hint': '删除所有存储的凭证',
      'settings_clear_confirm': '确认清除',
      'settings_clear_confirm_message': '此操作将删除所有存储的凭证，且无法恢复。确定要继续吗？',
      'settings_clear_done': '所有数据已清除',
      'settings_about': '关于',
      'settings_version': '版本信息',
      'settings_license': '开源协议',
      'settings_app_name': 'PolyVault',
      'settings_app_desc': '安全凭证存储解决方案',
      
      // 通用
      'loading': '加载中...',
      'error': '错误',
      'retry': '重试',
      'ok': '确定',
      'cancel': '取消',
      'confirm': '确认',
      'delete': '删除',
      'save': '保存',
      'edit': '编辑',
      'close': '关闭',
      'search': '搜索',
      'refresh': '刷新',
      'copy': '复制',
      'copied': '已复制',
      'minutes': '分钟',
    },
    'en': {
      // Navigation
      'nav_home': 'Status',
      'nav_credentials': 'Credentials',
      'nav_devices': 'Devices',
      'nav_settings': 'Settings',
      
      // Home
      'home_title': 'PolyVault',
      'home_device_status': 'Device Status',
      'home_security_status': 'Security Status',
      'home_statistics': 'Statistics',
      'home_quick_actions': 'Quick Actions',
      'home_add_credential': 'Add Credential',
      'home_sync_device': 'Sync Device',
      'home_connected': 'Connected',
      'home_disconnected': 'Disconnected',
      'home_biometric_available': 'Biometric Available',
      'home_biometric_unavailable': 'Biometric Unavailable',
      'home_hardware_secure': 'Hardware Secure',
      'home_encryption': 'Encryption Level',
      
      // Credentials
      'credentials_title': 'Credentials',
      'credentials_empty': 'No Credentials',
      'credentials_empty_hint': 'Tap the button below to add your first credential',
      'credentials_add': 'Add Credential',
      'credentials_edit': 'Edit Credential',
      'credentials_delete': 'Delete',
      'credentials_service_name': 'Service Name',
      'credentials_username': 'Username',
      'credentials_password': 'Password',
      'credentials_notes': 'Notes',
      'credentials_save': 'Save',
      'credentials_cancel': 'Cancel',
      'credentials_delete_confirm': 'Confirm Delete',
      'credentials_delete_message': 'Are you sure you want to delete this credential?',
      'credentials_copied': 'Copied to clipboard',
      'credentials_added': 'Credential saved',
      'credentials_deleted': 'Credential deleted',
      'credentials_load_failed': 'Failed to load credentials',
      'credentials_save_failed': 'Failed to save',
      'credentials_delete_failed': 'Failed to delete',
      
      // Devices
      'devices_title': 'Devices',
      'devices_empty': 'No Devices',
      'devices_empty_hint': 'Add your first device to get started',
      'devices_add': 'Add Device',
      'devices_scan_qr': 'Scan QR Code',
      'devices_manual_input': 'Manual Input',
      'devices_connect': 'Connect',
      'devices_disconnect': 'Disconnect',
      'devices_delete': 'Delete Device',
      'devices_trust': 'Trust Device',
      'devices_untrust': 'Untrust Device',
      'devices_online': 'Online',
      'devices_offline': 'Offline',
      'devices_connecting': 'Connecting',
      'devices_last_seen': 'Last Seen',
      'devices_paired_at': 'Paired At',
      'devices_platform': 'Platform',
      'devices_ip': 'IP Address',
      'devices_device_id': 'Device ID',
      'devices_scan_complete': 'Scan Complete',
      'devices_added': 'New device added',
      'devices_deleted': 'Device deleted',
      'devices_connected': 'Connected to device',
      'devices_disconnected': 'Disconnected from device',
      
      // Settings
      'settings_title': 'Settings',
      'settings_appearance': 'Appearance',
      'settings_dark_mode': 'Dark Mode',
      'settings_security': 'Security',
      'settings_biometric': 'Biometric Authentication',
      'settings_biometric_hint': 'Unlock with fingerprint or face ID',
      'settings_auto_lock': 'Auto Lock',
      'settings_auto_lock_hint': 'Lock when leaving app',
      'settings_auto_lock_time': 'Auto Lock Time',
      'settings_data': 'Data',
      'settings_backup': 'Backup Credentials',
      'settings_backup_hint': 'Export encrypted backup',
      'settings_restore': 'Restore Credentials',
      'settings_restore_hint': 'Restore from backup file',
      'settings_clear_data': 'Clear All Data',
      'settings_clear_data_hint': 'Delete all stored credentials',
      'settings_clear_confirm': 'Confirm Clear',
      'settings_clear_confirm_message': 'This will delete all stored credentials and cannot be undone. Continue?',
      'settings_clear_done': 'All data cleared',
      'settings_about': 'About',
      'settings_version': 'Version',
      'settings_license': 'Open Source License',
      'settings_app_name': 'PolyVault',
      'settings_app_desc': 'Secure Credential Storage Solution',
      
      // Common
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'ok': 'OK',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'save': 'Save',
      'edit': 'Edit',
      'close': 'Close',
      'search': 'Search',
      'refresh': 'Refresh',
      'copy': 'Copy',
      'copied': 'Copied',
      'minutes': 'minutes',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }

  /// 便捷方法
  String get navHome => get('nav_home');
  String get navCredentials => get('nav_credentials');
  String get navDevices => get('nav_devices');
  String get navSettings => get('nav_settings');
  String get loading => get('loading');
  String get error => get('error');
  String get ok => get('ok');
  String get cancel => get('cancel');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// 语言 Provider
final localeProvider = StateProvider<Locale>((ref) {
  // 默认跟随系统
  return const Locale('zh');
});

/// 语言列表
final availableLocalesProvider = Provider<List<Locale>>((ref) {
  return const [
    Locale('zh'),
    Locale('en'),
  ];
});

/// 扩展方法
extension LocaleExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension StringLocalization on String {
  String get localized => AppLocalizations.of(_context)!.get(this);
  BuildContext? _context;
}

String _localize(BuildContext context, String key) {
  return AppLocalizations.of(context)?.get(key) ?? key;
}