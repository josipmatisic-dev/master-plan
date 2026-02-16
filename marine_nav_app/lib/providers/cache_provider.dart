/// Cache Provider - Layer 1
///
/// Coordinates cache operations and exposes cache state to UI.
/// Wraps CacheService for provider pattern integration.
library;

import 'package:flutter/foundation.dart';

import '../services/cache_service.dart';

/// Cache statistics data
class CacheStats {
  /// Total cache size in bytes
  final int totalSize;

  /// Number of cache entries
  final int entryCount;

  /// Number of cache hits
  final int hits;

  /// Number of cache misses
  final int misses;

  /// Cache hit rate (0.0 to 1.0)
  double get hitRate {
    final total = hits + misses;
    return total > 0 ? hits / total : 0.0;
  }

  /// Creates cache statistics.
  const CacheStats({
    required this.totalSize,
    required this.entryCount,
    required this.hits,
    required this.misses,
  });

  /// Empty cache stats
  static const empty = CacheStats(
    totalSize: 0,
    entryCount: 0,
    hits: 0,
    misses: 0,
  );
}

/// Cache Provider - Coordinates cache operations for UI
///
/// Layer 1 provider. Can depend on SettingsProvider (Layer 0).
/// Delegates all storage to [CacheService].
class CacheProvider extends ChangeNotifier {
  // ============ Private Fields ============

  final CacheService _cacheService;
  CacheStats _stats = CacheStats.empty;
  bool _isInitialized = false;

  // ============ Constructor ============

  /// Creates a CacheProvider. Optionally accepts a [CacheService] for testing.
  CacheProvider({CacheService? cacheService})
      : _cacheService = cacheService ?? CacheService();

  // ============ Public Getters ============

  /// Current cache statistics
  CacheStats get stats => _stats;

  /// Check if cache is initialized
  bool get isInitialized => _isInitialized;

  /// Cache size in MB
  double get cacheSizeMB => _stats.totalSize / (1024 * 1024);

  // ============ Initialization ============

  /// Initialize cache provider and underlying service.
  Future<void> init() async {
    try {
      await _cacheService.init();
      _isInitialized = true;
      refreshStats();
      debugPrint('CacheProvider: Initialized');
    } catch (e) {
      debugPrint('CacheProvider: Failed to init - $e');
      _isInitialized = false;
    }
  }

  // ============ Cache Operations ============

  /// Store a string value with optional TTL.
  Future<void> put(String key, String value, {Duration? ttl}) async {
    if (!_isInitialized) return;
    try {
      await _cacheService.put(key, value, ttl: ttl);
      refreshStats();
    } catch (e) {
      debugPrint('CacheProvider: Failed to put $key - $e');
    }
  }

  /// Store a JSON object with optional TTL.
  Future<void> putJson(String key, Map<String, dynamic> json,
      {Duration? ttl}) async {
    if (!_isInitialized) return;
    try {
      await _cacheService.putJson(key, json, ttl: ttl);
      refreshStats();
    } catch (e) {
      debugPrint('CacheProvider: Failed to putJson $key - $e');
    }
  }

  /// Retrieve a cached string value, or null if missing/expired.
  String? getString(String key) {
    if (!_isInitialized) return null;
    try {
      return _cacheService.get(key);
    } catch (e) {
      debugPrint('CacheProvider: Failed to get $key - $e');
      return null;
    }
  }

  /// Retrieve a cached JSON object, or null if missing/expired.
  Map<String, dynamic>? getJson(String key) {
    if (!_isInitialized) return null;
    try {
      return _cacheService.getJson(key);
    } catch (e) {
      debugPrint('CacheProvider: Failed to getJson $key - $e');
      return null;
    }
  }

  /// Refresh cache statistics from the service.
  void refreshStats() {
    if (!_isInitialized) return;
    try {
      _stats = CacheStats(
        totalSize: _cacheService.totalSizeBytes,
        entryCount: _cacheService.entryCount,
        hits: _cacheService.hits,
        misses: _cacheService.misses,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('CacheProvider: Failed to refresh stats - $e');
    }
  }

  /// Clear entire cache.
  Future<void> clearCache() async {
    if (!_isInitialized) return;
    try {
      await _cacheService.clear();
      refreshStats();
      debugPrint('CacheProvider: Cache cleared');
    } catch (e) {
      debugPrint('CacheProvider: Failed to clear cache - $e');
    }
  }

  /// Alias for [clearCache].
  Future<void> clear() => clearCache();

  /// Invalidate specific cache entry.
  Future<void> invalidate(String key) async {
    if (!_isInitialized) return;
    try {
      await _cacheService.delete(key);
      refreshStats();
    } catch (e) {
      debugPrint('CacheProvider: Failed to invalidate $key - $e');
    }
  }

  /// Alias for [invalidate].
  Future<void> remove(String key) => invalidate(key);

  /// Get cache entry (for debugging/inspection).
  Future<T?> get<T>(String key) async {
    if (!_isInitialized) return null;
    try {
      final value = _cacheService.get(key);
      return value as T?;
    } catch (e) {
      debugPrint('CacheProvider: Failed to get $key - $e');
      return null;
    }
  }
}
