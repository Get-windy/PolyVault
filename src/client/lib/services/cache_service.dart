import 'dart:convert';
import '../models/credential.dart';

/// LRU缓存实现
class LRUMap<K, V> {
  final int maxSize;
  final Map<K, V> _map = {};
  final List<K> _order = [];

  LRUMap(this.maxSize);

  V? get(K key) {
    if (_map.containsKey(key)) {
      //将访问的键移到最近使用位置
      _order.remove(key);
      _order.add(key);
      return _map[key];
    }
    return null;
  }

  void put(K key, V value) {
    if (_map.containsKey(key)) {
      // 更新现有键
      _order.remove(key);
    } else if (_order.length >= maxSize) {
      // 移除最久未使用的键
      final oldestKey = _order.removeAt(0);
      _map.remove(oldestKey);
    }
    _map[key] = value;
    _order.add(key);
  }

  void remove(K key) {
    if (_map.containsKey(key)) {
      _order.remove(key);
      _map.remove(key);
    }
  }

  void clear() {
    _map.clear();
    _order.clear();
  }

  int get length => _map.length;

  bool containsKey(K key) => _map.containsKey(key);
}

/// 主题缓存
class ThemeCache {
  static final ThemeCache _instance = ThemeCache._internal();
  factory ThemeCache() => _instance;
  ThemeCache._internal();

  final LRUMap<String, dynamic> _cache = LRUMap(20);

  dynamic get(String key) => _cache.get(key);

  void set(String key, dynamic value) => _cache.put(key, value);

  void clear() => _cache.clear();
}

/// 验证缓存
class ValidationCache {
  static final ValidationCache _instance = ValidationCache._internal();
  factory ValidationCache() => _instance;
  ValidationCache._internal();

  final Map<String, bool> _cache = {};
  final Duration ttl = const Duration(minutes: 5);

  bool getCredentialExists(String serviceName, String username) {
    final key = '$serviceName:$username';
    return _cache.containsKey(key) && !_isExpired(key);
  }

  void setCredentialExists(String serviceName, String username, bool exists) {
    final key = '$serviceName:$username';
    _cache[key] = exists;
  }

  bool _isExpired(String key) {
    // TODO: 实现过期检查
    return false;
  }

  void clear() => _cache.clear();
}

/// 性能统计缓存
class PerformanceCache {
  static final PerformanceCache _instance = PerformanceCache._internal();
  factory PerformanceCache() => _instance;
  PerformanceCache._internal();

  final Map<String, int> _requestCount = {};
  final Map<String, int> _cacheHits = {};

  void recordRequest(String key) {
    _requestCount[key] = (_requestCount[key] ?? 0) + 1;
  }

  void recordCacheHit(String key) {
    _cacheHits[key] = (_cacheHits[key] ?? 0) + 1;
  }

  double getHitRate(String key) {
    final requests = _requestCount[key] ?? 0;
    if (requests == 0) return 0.0;
    return (_cacheHits[key] ?? 0) / requests;
  }

  void clear() {
    _requestCount.clear();
    _cacheHits.clear();
  }
}

/// 高速缓存凭证服务
/// 优化目标: 减少重复解密，提升凭证访问速度
class CredentialCacheService {
  static final CredentialCacheService _instance = CredentialCacheService._internal();
  factory CredentialCacheService() => _instance;
  CredentialCacheService._internal();

  final LRUMap<String, Credential> _credentialCache = LRUMap(100);
  final LRUMap<String, List<CredentialSummary>> _listCache = LRUMap(20);
  final Set<String> _decryptedIds = {};

  /// 从缓存获取凭证
  Credential? getCredential(String id) {
    PerformanceCache().recordRequest('credential:$id');
    
    final cached = _credentialCache.get(id);
    if (cached != null) {
      PerformanceCache().recordCacheHit('credential:$id');
      return cached;
    }
    return null;
  }

  /// 保存凭证到缓存
  void saveCredential(Credential credential) {
    _credentialCache.put(credential.id, credential);
  }

  /// 获取凭证列表缓存
  List<CredentialSummary>? getCredentialList(String? searchQuery) {
    final key = searchQuery ?? 'all';
    return _listCache.get(key);
  }

  /// 保存凭证列表缓存
  void saveCredentialList(String? searchQuery, List<CredentialSummary> summaries) {
    final key = searchQuery ?? 'all';
    _listCache.put(key, summaries);
  }

  /// 清除缓存
  void clear() {
    _credentialCache.clear();
    _listCache.clear();
    _decryptedIds.clear();
  }

  /// 清除特定凭证缓存
  void clearCredential(String id) {
    _credentialCache.remove(id);
    _decryptedIds.remove(id);
  }

  /// 检查凭证是否已解密
  bool isDecrypted(String id) => _decryptedIds.contains(id);

  /// 标记凭证为已解密
  void markDecrypted(String id) => _decryptedIds.add(id);

  /// 获取缓存统计
  Map<String, int> getStats => {
    'credentialCacheSize': _credentialCache.length,
    'listCacheSize': _listCache.length,
    'decryptedCount': _decryptedIds.length,
  };
}