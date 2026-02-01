# Phase 0 Foundation - Detailed Specifications

**Phase:** 0 - Foundation  
**Purpose:** Detailed technical specifications for all Phase 0 components  
**References:** [Phase 0 Plan](../plans/phase-0-foundation-plan.md)

## Core Data Models

### LatLng Model
```dart
@freezed
class LatLng with _$LatLng {
  const factory LatLng({
    /// Latitude in degrees WGS84 (-90 to 90)
    required double latitude,
    
    /// Longitude in degrees WGS84 (-180 to 180)
    required double longitude,
  }) = _LatLng;
  
  factory LatLng.fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);
  
  /// Validates coordinates are in valid range
  bool isValid() => latitude >= -90 && latitude <= 90 && 
                     longitude >= -180 && longitude <= 180;
}
```

### Viewport Model
```dart
@freezed
class Viewport with _$Viewport {
  const factory Viewport({
    /// Zoom level (1-20)
    required double zoom,
    
    /// Center point in WGS84
    required LatLng center,
    
    /// Rotation in degrees (0-360)
    @Default(0.0) double rotation,
    
    /// Geographic bounds (SW/NE corners)
    required Bounds bounds,
    
    /// Screen size in pixels
    required Size screenSize,
  }) = _Viewport;
  
  factory Viewport.fromJson(Map<String, dynamic> json) => _$ViewportFromJson(json);
}
```

## Core Services

### ProjectionService Specification

**Purpose:** Convert between WGS84, Web Mercator, and screen coordinates

**Methods:**

```dart
class ProjectionService {
  /// Converts WGS84 lat/lng to Web Mercator screen pixels
  /// 
  /// Reference: EPSG:3857 projection
  /// Avoids: ISS-001 (overlay projection mismatch)
  static Offset latLngToPixels(double lat, double lng, Viewport viewport) {
    // Implementation uses Web Mercator formula
  }
  
  /// Converts screen pixels to WGS84 lat/lng
  static LatLng pixelsToLatLng(Offset pixels, Viewport viewport) {
    // Inverse projection
  }
}
```

**Test Cases:**
- Known coordinates: (0, 0) → verify projection
- Poles: (90, 0), (-90, 0) → edge cases
- Date line: (0, 180), (0, -180) → wrap-around
- Inverse: latLng → pixels → latLng (should match)

### CacheService Specification

**Purpose:** LRU cache with TTL and coordinated invalidation  
**Avoids:** ISS-004 (stale cache data)

**API:**

```dart
class CacheService {
  /// Get cached value, null if expired or missing
  Future<T?> get<T>(String key);
  
  /// Set value with TTL
  Future<void> set<T>(String key, T value, {Duration? ttl});
  
  /// Delete by key
  Future<void> delete(String key);
  
  /// Invalidate all keys in category
  Future<void> invalidateCategory(String category);
  
  /// Get cache statistics
  CacheStats getStats();
}
```

**Configuration:**
- Default TTL: 1 hour
- Max size: 500MB
- Eviction: LRU
- Storage: Disk (path_provider)

### RetryableHttpClient Specification

**Purpose:** HTTP client with exponential backoff  
**Avoids:** ISS-010 (offline mode errors)

```dart
class RetryableHttpClient {
  /// GET with retry and cache fallback
  Future<http.Response> getWithRetry(String url, {int maxRetries = 3});
  
  /// POST with retry (no cache fallback)
  Future<http.Response> postWithRetry(String url, {Map<String, dynamic>? body});
}
```

**Retry Logic:**
- 5xx errors: retry with exponential backoff (1s, 2s, 4s)
- 4xx errors: no retry (client error)
- Timeout: retry
- SocketException: try cache fallback

## Provider Architecture

### Dependency Hierarchy

```
Layer 1 (No dependencies):
├── SettingsProvider
└── CacheProvider(CacheService)

Layer 2 (Depends on Layer 1):
└── ThemeProvider(SettingsProvider)

Layer 3: Reserved for future providers
```

**Rules:**
- Maximum 3 layers
- No circular dependencies
- All created in main.dart
- Document dependencies in provider class

## Testing Specifications

See [Phase 0 Plan](../plans/phase-0-foundation-plan.md) Section 6 for complete test list.

**Critical Tests:**
- TEST-004: ProjectionService transformations (ISS-001 prevention)
- TEST-005: CacheService LRU and TTL (ISS-004 prevention)
- TEST-006: RetryableHttpClient retry logic
- TEST-007: Provider initialization order

---

**For complete task breakdown, see:** [Phase 0 Plan](../plans/phase-0-foundation-plan.md)
