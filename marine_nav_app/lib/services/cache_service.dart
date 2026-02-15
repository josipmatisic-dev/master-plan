/// Disk-backed key-value cache with TTL and LRU eviction.
///
/// Uses SharedPreferences as storage backend. All cache keys are
/// prefixed with `cache_` to avoid collisions with app settings.
/// Metadata index stored at `cache___metadata__`.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata for a single cache entry.
class _CacheEntryMeta {
  final DateTime createdAt;
  final DateTime? expiresAt;

  _CacheEntryMeta({required this.createdAt, this.expiresAt});

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.millisecondsSinceEpoch,
        if (expiresAt != null) 'expiresAt': expiresAt!.millisecondsSinceEpoch,
      };

  factory _CacheEntryMeta.fromJson(Map<String, dynamic> json) {
    return _CacheEntryMeta(
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      expiresAt: json['expiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int)
          : null,
    );
  }
}

/// Disk-backed cache service using SharedPreferences.
///
/// Features:
/// - TTL-based expiration per entry
/// - LRU eviction when entry count exceeds [maxEntries]
/// - Hit/miss tracking for statistics
/// - All keys prefixed with `cache_` to avoid collisions
class CacheService {
  static const String _keyPrefix = 'cache_';
  static const String _metadataKey = '${_keyPrefix}__metadata__';

  /// Maximum number of entries to keep in cache.
  final int maxEntries;
  late SharedPreferences _prefs;
  Map<String, _CacheEntryMeta> _metadata = {};
  int _hits = 0;
  int _misses = 0;
  bool _initialized = false;

  /// Creates a CacheService with optional max entry limit.
  ///
  /// [maxEntries] defaults to 100.
  CacheService({this.maxEntries = 100});

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Number of cache hits since initialization.
  int get hits => _hits;

  /// Number of cache misses since initialization.
  int get misses => _misses;

  /// Number of entries currently in cache.
  int get entryCount => _metadata.length;

  /// Initialize the cache service and load metadata index.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadMetadata();
    _purgeExpired();
    _initialized = true;
  }

  /// Store a value with optional TTL.
  Future<void> put(String key, String value, {Duration? ttl}) async {
    _assertInitialized();
    final prefixedKey = '$_keyPrefix$key';

    _metadata[key] = _CacheEntryMeta(
      createdAt: DateTime.now(),
      expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
    );

    await _prefs.setString(prefixedKey, value);
    _saveMetadata();
    _evictIfNeeded();
  }

  /// Retrieve a cached value, or null if missing/expired.
  String? get(String key) {
    _assertInitialized();
    final meta = _metadata[key];

    if (meta == null) {
      _misses++;
      return null;
    }

    if (meta.isExpired) {
      _misses++;
      delete(key);
      return null;
    }

    final value = _prefs.getString('$_keyPrefix$key');
    if (value == null) {
      _misses++;
      _metadata.remove(key);
      _saveMetadata();
      return null;
    }

    _hits++;
    return value;
  }

  /// Delete a specific cache entry.
  Future<void> delete(String key) async {
    _assertInitialized();
    _metadata.remove(key);
    await _prefs.remove('$_keyPrefix$key');
    _saveMetadata();
  }

  /// Clear all cache entries.
  Future<void> clear() async {
    _assertInitialized();
    for (final key in _metadata.keys.toList()) {
      await _prefs.remove('$_keyPrefix$key');
    }
    _metadata.clear();
    _hits = 0;
    _misses = 0;
    _saveMetadata();
  }

  /// Estimated total size of cached data in bytes.
  int get totalSizeBytes {
    int size = 0;
    for (final key in _metadata.keys) {
      final value = _prefs.getString('$_keyPrefix$key');
      if (value != null) {
        size += value.length * 2; // Approximate UTF-16 size
      }
    }
    return size;
  }

  // ============ Private Methods ============

  void _assertInitialized() {
    if (!_initialized) {
      throw StateError('CacheService not initialized. Call init() first.');
    }
  }

  void _loadMetadata() {
    final raw = _prefs.getString(_metadataKey);
    if (raw == null) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _metadata = map.map((key, value) => MapEntry(
          key, _CacheEntryMeta.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      debugPrint('CacheService: Failed to load metadata - $e');
      _metadata = {};
    }
  }

  void _saveMetadata() {
    final map = _metadata.map((key, meta) => MapEntry(key, meta.toJson()));
    _prefs.setString(_metadataKey, jsonEncode(map));
  }

  void _purgeExpired() {
    final expiredKeys = _metadata.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();

    for (final key in expiredKeys) {
      _prefs.remove('$_keyPrefix$key');
      _metadata.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _saveMetadata();
    }
  }

  void _evictIfNeeded() {
    if (_metadata.length <= maxEntries) return;

    // Sort by creation time (oldest first) for LRU eviction
    final sorted = _metadata.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    final toEvict = sorted.length - maxEntries;
    for (int i = 0; i < toEvict; i++) {
      final key = sorted[i].key;
      _prefs.remove('$_keyPrefix$key');
      _metadata.remove(key);
    }

    _saveMetadata();
    debugPrint('CacheService: Evicted $toEvict entries (LRU)');
  }
}
