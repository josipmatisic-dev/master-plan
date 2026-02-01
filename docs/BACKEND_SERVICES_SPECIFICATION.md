# Backend Services - Complete Implementation Specification

**Version:** 1.0  
**Date:** 2026-02-01  
**Status:** Ready for Implementation (Pending Flutter SDK)  
**Agent:** Backend Services Agent

---

## Table of Contents

1. [Overview](#overview)
2. [CacheService](#cacheservice)
3. [HttpClient](#httpclient)
4. [ProjectionService](#projectionservice)
5. [NMEAParser](#nmeaparser)
6. [DatabaseService](#databaseservice)
7. [Data Models](#data-models)
8. [Testing Specifications](#testing-specifications)

---

## Overview

This document provides complete implementation specifications for all Phase 0 backend services. Each service is designed to remain under 300 lines (CON-001) and follows all architecture rules from `MASTER_DEVELOPMENT_BIBLE.md`.

### Architecture Principles

- **Single Responsibility**: Each service has ONE clear purpose
- **Immutability**: All data models are immutable
- **Error Handling**: Graceful degradation, never crash
- **Testability**: All services have clear interfaces for mocking
- **Performance**: Benchmarked and optimized
- **Disposal**: All resources properly cleaned up

---

## CacheService

### Purpose
LRU disk cache with TTL for weather data, map tiles, and API responses.

### File: `lib/services/cache_service.dart`

### Public API

```dart
class CacheService {
  /// Initialize cache, load metadata, clean expired entries
  Future<void> init();
  
  /// Retrieve cached value by key, returns null if missing or expired
  Future<T?> get<T>(String key);
  
  /// Store value with optional TTL (default: 24 hours)
  Future<void> put<T>(String key, T value, {Duration? ttl});
  
  /// Delete specific cache entry
  Future<void> delete(String key);
  
  /// Clear entire cache
  Future<void> clear();
  
  /// Get total cache size in bytes
  Future<int> getSize();
  
  /// Cleanup resources
  Future<void> dispose();
}
```

### Requirements

| ID | Requirement | Validation |
|----|-------------|------------|
| REQ-CS-001 | Maximum cache size 500MB | Test with 600MB data, verify eviction |
| REQ-CS-002 | LRU eviction when limit reached | Add 6 items with 5 item limit, verify oldest removed |
| REQ-CS-003 | TTL support with automatic expiry | Put with 1s TTL, wait 2s, verify null returned |
| REQ-CS-004 | Thread-safe operations | Concurrent get/put from multiple isolates |
| REQ-CS-005 | Graceful degradation on disk errors | Mock disk full, verify no crash |
| REQ-CS-006 | JSON serialization for objects | Put/get complex objects, verify integrity |
| REQ-CS-007 | File size under 300 lines | Automated line count check |

### Implementation Algorithm

#### Data Structure

```
cache_dir/
├── entries/
│   ├── key1.json
│   ├── key2.json
│   └── key3.json
└── metadata.json  // LRU order, sizes, TTLs
```

**Metadata Format:**
```json
{
  "entries": {
    "weather_data_123": {
      "created": 1675234567890,
      "lastAccess": 1675234567890,
      "size": 15234,
      "ttl": 86400000
    }
  },
  "totalSize": 15234,
  "maxSize": 524288000
}
```

#### LRU Eviction Algorithm

```dart
void _evictIfNeeded(int newEntrySize) {
  while (_totalSize + newEntrySize > _maxSize) {
    // Find least recently used entry
    String? lruKey = _findLRUKey();
    if (lruKey == null) break;
    
    // Remove from disk and metadata
    _removeEntry(lruKey);
  }
}

String? _findLRUKey() {
  String? oldestKey;
  int oldestTime = DateTime.now().millisecondsSinceEpoch;
  
  for (var entry in _metadata.entries) {
    if (entry.value.lastAccess < oldestTime) {
      oldestTime = entry.value.lastAccess;
      oldestKey = entry.key;
    }
  }
  
  return oldestKey;
}
```

#### TTL Expiry Check

```dart
bool _isExpired(CacheEntry entry) {
  if (entry.ttl == null) return false;
  
  int now = DateTime.now().millisecondsSinceEpoch;
  int expiry = entry.created + entry.ttl!;
  
  return now > expiry;
}
```

### Error Handling Matrix

| Error | Cause | Response | User Impact |
|-------|-------|----------|-------------|
| DiskFullException | Storage exhausted | Log error, skip put(), return null on get() | Data not cached, slower performance |
| PermissionDeniedException | No write access | Fallback to memory-only mode | Cache lost on app restart |
| JsonParseException | Corrupt cache file | Delete corrupt entry, return null | Single cache miss |
| OutOfMemoryError | Metadata too large | Clear cache, restart | Cache rebuilt |

### Performance Benchmarks

- `init()`: < 500ms (with 1000 entries)
- `get()`: < 10ms
- `put()`: < 50ms (including disk write)
- `delete()`: < 20ms
- `getSize()`: < 5ms (cached in memory)

---

## HttpClient

### Purpose
Wrapper for HTTP requests with retry logic, timeout, and error handling.

### File: `lib/services/http_client.dart`

### Public API

```dart
class HttpClient {
  /// HTTP GET request with retry and timeout
  Future<Response> get(String url, {Map<String, String>? headers});
  
  /// HTTP POST request with retry and timeout
  Future<Response> post(String url, {
    Map<String, String>? headers, 
    dynamic body
  });
  
  /// GET request with automatic JSON parsing
  Future<T> getJson<T>(
    String url, 
    T Function(Map<String, dynamic>) fromJson
  );
  
  /// Cleanup resources
  void dispose();
}
```

### Requirements

| ID | Requirement | Validation |
|----|-------------|------------|
| REQ-HC-001 | 3 retry attempts with exponential backoff | Mock 2 failures + 1 success, verify timing |
| REQ-HC-002 | 30 second timeout per request | Mock slow server, verify timeout |
| REQ-HC-003 | Validate response status codes | Test 200, 404, 500 responses |
| REQ-HC-004 | Parse JSON with error handling | Test valid/invalid JSON |
| REQ-HC-005 | Log requests and errors | Verify log entries created |
| REQ-HC-006 | Support custom headers | Test auth headers passed through |
| REQ-HC-007 | File size under 300 lines | Automated line count check |

### Implementation Algorithm

#### Retry Logic with Exponential Backoff

```dart
Future<Response> _requestWithRetry(
  Future<Response> Function() request,
  {int maxAttempts = 3}
) async {
  int attempt = 0;
  Duration baseDelay = Duration(seconds: 1);
  
  while (attempt < maxAttempts) {
    try {
      return await request().timeout(Duration(seconds: 30));
    } on TimeoutException catch (e) {
      attempt++;
      if (attempt >= maxAttempts) rethrow;
      
      // Exponential backoff: 1s, 2s, 4s
      Duration delay = baseDelay * pow(2, attempt - 1);
      await Future.delayed(delay);
    } on SocketException catch (e) {
      attempt++;
      if (attempt >= maxAttempts) rethrow;
      
      Duration delay = baseDelay * pow(2, attempt - 1);
      await Future.delayed(delay);
    } on ClientException catch (e) {
      // Don't retry 4xx errors
      rethrow;
    }
  }
  
  throw Exception('Max retry attempts reached');
}
```

#### Request Logging (Sanitized)

```dart
void _logRequest(String method, String url, Map<String, String>? headers) {
  String requestId = Uuid().v4();
  Map<String, String> sanitizedHeaders = _sanitizeHeaders(headers);
  
  log('[$requestId] $method $url', headers: sanitizedHeaders);
}

Map<String, String> _sanitizeHeaders(Map<String, String>? headers) {
  if (headers == null) return {};
  
  return headers.map((key, value) {
    // Redact sensitive headers
    if (key.toLowerCase() == 'authorization' || 
        key.toLowerCase() == 'api-key') {
      return MapEntry(key, '***REDACTED***');
    }
    return MapEntry(key, value);
  });
}
```

### Error Handling Matrix

| Error Type | HTTP Code | Retry? | Exception Thrown |
|------------|-----------|--------|------------------|
| Network timeout | N/A | Yes (3x) | TimeoutException |
| Connection refused | N/A | Yes (3x) | SocketException |
| 400 Bad Request | 400 | No | ClientException |
| 401 Unauthorized | 401 | No | ClientException |
| 404 Not Found | 404 | No | ClientException |
| 500 Server Error | 500 | Yes (3x) | ServerException |
| 503 Service Unavailable | 503 | Yes (3x) | ServerException |
| JSON parse error | 200 | No | FormatException |

### Security Measures

1. **HTTPS Only (Production)**
```dart
void _validateUrl(String url) {
  if (!url.startsWith('https://') && !_isDevelopment) {
    throw ArgumentError('Only HTTPS URLs allowed in production');
  }
}
```

2. **Sanitize Error Messages**
```dart
String _sanitizeErrorMessage(String message) {
  // Remove internal URLs and paths
  return message.replaceAll(RegExp(r'https?://[^\s]+'), '[URL]');
}
```

---

## ProjectionService

### Purpose
Coordinate transformations between WGS84 (EPSG:4326) and Web Mercator (EPSG:3857).

### File: `lib/services/projection_service.dart`

### Public API

```dart
class ProjectionService {
  /// Convert Web Mercator (x, y) to WGS84 (lat, lng)
  LatLng webMercatorToWgs84(double x, double y);
  
  /// Convert WGS84 (lat, lng) to Web Mercator (x, y)
  Point wgs84ToWebMercator(double lat, double lng);
  
  /// Convert lat/lng to screen pixel coordinates
  Point latLngToScreen(LatLng latLng, Viewport viewport, Size screenSize);
  
  /// Convert screen pixel to lat/lng coordinates
  LatLng screenToLatLng(Offset screenPoint, Viewport viewport, Size screenSize);
}
```

### Requirements

| ID | Requirement | Validation |
|----|-------------|------------|
| REQ-PS-001 | Accurate transformations (error < 0.0001°) | Test known coordinates |
| REQ-PS-002 | Handle edge cases (poles, dateline) | Test lat=90, lng=180 |
| REQ-PS-003 | Account for viewport rotation and tilt | Test rotated viewport |
| REQ-PS-004 | Performance: <1ms per transformation | Benchmark 1000 conversions |
| REQ-PS-005 | File size under 300 lines | Automated line count check |

### Mathematical Formulas

#### WGS84 to Web Mercator

```dart
// Constants
static const double EARTH_RADIUS = 6378137.0; // meters
static const double MAX_LATITUDE = 85.05112878; // Web Mercator limit

Point wgs84ToWebMercator(double lat, double lng) {
  // Clamp latitude to Web Mercator limits
  lat = lat.clamp(-MAX_LATITUDE, MAX_LATITUDE);
  
  // Normalize longitude to -180 to 180
  lng = ((lng + 180) % 360) - 180;
  
  // Convert to radians
  double latRad = lat * pi / 180;
  double lngRad = lng * pi / 180;
  
  // Web Mercator formulas
  double x = EARTH_RADIUS * lngRad;
  double y = EARTH_RADIUS * log(tan(pi / 4 + latRad / 2));
  
  return Point(x, y);
}
```

#### Web Mercator to WGS84

```dart
LatLng webMercatorToWgs84(double x, double y) {
  // Inverse Web Mercator formulas
  double lng = (x / EARTH_RADIUS) * 180 / pi;
  double lat = (2 * atan(exp(y / EARTH_RADIUS)) - pi / 2) * 180 / pi;
  
  // Clamp to valid ranges
  lat = lat.clamp(-90.0, 90.0);
  lng = ((lng + 180) % 360) - 180;
  
  return LatLng(lat, lng);
}
```

#### Lat/Lng to Screen Coordinates

```dart
Point latLngToScreen(LatLng latLng, Viewport viewport, Size screenSize) {
  // 1. Convert to Web Mercator
  Point mercator = wgs84ToWebMercator(latLng.latitude, latLng.longitude);
  Point centerMercator = wgs84ToWebMercator(
    viewport.center.latitude, 
    viewport.center.longitude
  );
  
  // 2. Calculate scale factor for zoom level
  double scale = pow(2, viewport.zoom) as double;
  
  // 3. Calculate offset from center
  double dx = (mercator.x - centerMercator.x) * scale;
  double dy = (mercator.y - centerMercator.y) * scale;
  
  // 4. Apply rotation (if viewport has bearing)
  if (viewport.bearing != 0) {
    double bearingRad = viewport.bearing * pi / 180;
    double rotatedX = dx * cos(bearingRad) - dy * sin(bearingRad);
    double rotatedY = dx * sin(bearingRad) + dy * cos(bearingRad);
    dx = rotatedX;
    dy = rotatedY;
  }
  
  // 5. Convert to screen pixels (center origin)
  double screenX = screenSize.width / 2 + dx;
  double screenY = screenSize.height / 2 - dy; // Flip Y axis
  
  return Point(screenX, screenY);
}
```

### Test Cases

```dart
// Test known coordinates
testWgs84ToWebMercator() {
  // Null Island (0, 0)
  var p = service.wgs84ToWebMercator(0, 0);
  expect(p.x, closeTo(0, 0.01));
  expect(p.y, closeTo(0, 0.01));
  
  // London (51.5074, -0.1278)
  var london = service.wgs84ToWebMercator(51.5074, -0.1278);
  expect(london.x, closeTo(-14231.0, 1.0));
  expect(london.y, closeTo(6711533.0, 1.0));
}

// Test round-trip conversion
testRoundTrip() {
  var original = LatLng(45.5231, -122.6765);
  var mercator = service.wgs84ToWebMercator(original.latitude, original.longitude);
  var back = service.webMercatorToWgs84(mercator.x, mercator.y);
  
  expect(back.latitude, closeTo(original.latitude, 0.0001));
  expect(back.longitude, closeTo(original.longitude, 0.0001));
}
```

---

## NMEAParser

### Purpose
Parse NMEA 0183 sentences for GPS and sensor data.

### File: `lib/services/nmea_parser.dart`

### Public API

```dart
class NMEAParser {
  /// Parse any NMEA sentence, returns null if invalid
  NMEAMessage? parse(String sentence);
  
  /// Validate NMEA checksum
  bool validateChecksum(String sentence);
  
  /// Parse specific sentence types (static methods)
  static GPGGAMessage? parseGPGGA(String sentence);
  static GPRMCMessage? parseGPRMC(String sentence);
  static GPVTGMessage? parseGPVTG(String sentence);
}
```

### Requirements

| ID | Requirement | Validation |
|----|-------------|------------|
| REQ-NP-001 | Support GPGGA, GPRMC, GPVTG | Test each sentence type |
| REQ-NP-002 | Validate checksums | Test valid/invalid checksums |
| REQ-NP-003 | Handle malformed sentences | Test missing fields, bad format |
| REQ-NP-004 | Extract all relevant fields | Verify all fields parsed correctly |
| REQ-NP-005 | Performance: 100+ sentences/second | Benchmark 1000 sentences |
| REQ-NP-006 | File size under 300 lines | Automated line count check |

### NMEA Sentence Format

```
$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
  │     │       │        │ │         │ │ │   │   │     │ │    │  └─ Checksum
  └─ Type      └─ Lat    │ └─ Lon    │ └─ Quality indicators
               └─ Time   └─ N/S       └─ E/W
```

### Implementation Algorithm

#### Checksum Validation

```dart
bool validateChecksum(String sentence) {
  // NMEA format: $....*XX where XX is hex checksum
  if (!sentence.startsWith('\$') || !sentence.contains('*')) {
    return false;
  }
  
  int starIndex = sentence.indexOf('*');
  String data = sentence.substring(1, starIndex);
  String checksumHex = sentence.substring(starIndex + 1);
  
  // Calculate checksum (XOR of all bytes)
  int calculated = 0;
  for (int i = 0; i < data.length; i++) {
    calculated ^= data.codeUnitAt(i);
  }
  
  // Compare with provided checksum
  int provided = int.parse(checksumHex, radix: 16);
  return calculated == provided;
}
```

#### Parse GPGGA (Position + Fix Quality)

```dart
static GPGGAMessage? parseGPGGA(String sentence) {
  // Validate checksum
  if (!NMEAParser.validateChecksum(sentence)) return null;
  
  // Split into fields
  String data = sentence.substring(1, sentence.indexOf('*'));
  List<String> fields = data.split(',');
  
  // Verify sentence type
  if (fields[0] != 'GPGGA') return null;
  
  try {
    // Parse fields
    String time = fields[1];
    double lat = _parseCoordinate(fields[2], fields[3]);
    double lng = _parseCoordinate(fields[4], fields[5]);
    int quality = int.parse(fields[6]);
    int satellites = int.parse(fields[7]);
    double hdop = double.parse(fields[8]);
    double altitude = double.parse(fields[9]);
    
    return GPGGAMessage(
      time: time,
      latitude: lat,
      longitude: lng,
      quality: quality,
      satellites: satellites,
      hdop: hdop,
      altitude: altitude,
    );
  } catch (e) {
    return null; // Parsing failed
  }
}

// Convert DDMM.MMMM to decimal degrees
static double _parseCoordinate(String value, String direction) {
  if (value.isEmpty) throw FormatException('Empty coordinate');
  
  // DDMM.MMMM format
  double ddmm = double.parse(value);
  
  // Extract degrees and minutes
  int degrees = ddmm ~/ 100;
  double minutes = ddmm % 100;
  
  // Convert to decimal degrees
  double decimal = degrees + (minutes / 60);
  
  // Apply direction (N/S, E/W)
  if (direction == 'S' || direction == 'W') {
    decimal = -decimal;
  }
  
  return decimal;
}
```

### Supported Sentence Types

#### GPGGA - Global Positioning System Fix Data

**Fields:**
- Time (UTC)
- Latitude (DDMM.MMMM)
- N/S Indicator
- Longitude (DDDMM.MMMM)
- E/W Indicator
- Fix Quality (0=invalid, 1=GPS, 2=DGPS)
- Number of satellites
- Horizontal dilution of precision
- Altitude above mean sea level
- Geoidal separation

#### GPRMC - Recommended Minimum Specific GPS/Transit Data

**Fields:**
- Time (UTC)
- Status (A=active, V=void)
- Latitude
- N/S Indicator
- Longitude
- E/W Indicator
- Speed over ground (knots)
- Track angle (degrees)
- Date (DDMMYY)
- Magnetic variation

#### GPVTG - Track Made Good and Ground Speed

**Fields:**
- True track (degrees)
- Magnetic track (degrees)
- Speed (knots)
- Speed (km/h)

---

## DatabaseService

### Purpose
SQLite wrapper for local data persistence.

### File: `lib/services/database_service.dart`

### Public API

```dart
class DatabaseService {
  /// Initialize database, create tables
  Future<void> init();
  
  /// Insert record
  Future<int> insert(String table, Map<String, dynamic> values);
  
  /// Query records
  Future<List<Map<String, dynamic>>> query(
    String table,
    {String? where, List<dynamic>? whereArgs}
  );
  
  /// Update records
  Future<int> update(
    String table,
    Map<String, dynamic> values,
    {String? where, List<dynamic>? whereArgs}
  );
  
  /// Delete records
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});
  
  /// Close database
  Future<void> close();
}
```

### Schema Design

```sql
-- Settings table
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Cache metadata table (for CacheService persistence)
CREATE TABLE cache_metadata (
  key TEXT PRIMARY KEY,
  created INTEGER NOT NULL,
  last_access INTEGER NOT NULL,
  size INTEGER NOT NULL,
  ttl INTEGER
);

-- Track history table (for future phases)
CREATE TABLE track_points (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  latitude REAL NOT NULL,
  longitude REAL NOT NULL,
  timestamp INTEGER NOT NULL,
  speed REAL,
  heading REAL,
  altitude REAL
);
```

---

## Data Models

### LatLng

**File:** `lib/models/lat_lng.dart`

```dart
class LatLng {
  final double latitude;
  final double longitude;
  
  const LatLng(this.latitude, this.longitude)
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180);
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LatLng &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;
  
  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
  
  @override
  String toString() => 'LatLng($latitude, $longitude)';
  
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };
  
  factory LatLng.fromJson(Map<String, dynamic> json) => LatLng(
        json['latitude'] as double,
        json['longitude'] as double,
      );
}
```

### Bounds

**File:** `lib/models/bounds.dart`

```dart
class Bounds {
  final LatLng southwest;
  final LatLng northeast;
  
  const Bounds(this.southwest, this.northeast);
  
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
           point.latitude <= northeast.latitude &&
           point.longitude >= southwest.longitude &&
           point.longitude <= northeast.longitude;
  }
  
  bool intersects(Bounds other) {
    return !(other.southwest.latitude > northeast.latitude ||
             other.northeast.latitude < southwest.latitude ||
             other.southwest.longitude > northeast.longitude ||
             other.northeast.longitude < southwest.longitude);
  }
  
  double get width => northeast.longitude - southwest.longitude;
  double get height => northeast.latitude - southwest.latitude;
  LatLng get center => LatLng(
        (southwest.latitude + northeast.latitude) / 2,
        (southwest.longitude + northeast.longitude) / 2,
      );
}
```

### Viewport

**File:** `lib/models/viewport.dart`

```dart
class Viewport {
  final LatLng center;
  final double zoom;
  final double bearing; // 0-360 degrees
  final double pitch;   // 0-60 degrees
  
  const Viewport({
    required this.center,
    required this.zoom,
    this.bearing = 0.0,
    this.pitch = 0.0,
  }) : assert(zoom >= 0 && zoom <= 22),
       assert(bearing >= 0 && bearing <= 360),
       assert(pitch >= 0 && pitch <= 60);
  
  Viewport copyWith({
    LatLng? center,
    double? zoom,
    double? bearing,
    double? pitch,
  }) {
    return Viewport(
      center: center ?? this.center,
      zoom: zoom ?? this.zoom,
      bearing: bearing ?? this.bearing,
      pitch: pitch ?? this.pitch,
    );
  }
}
```

### BoatPosition

**File:** `lib/models/boat_position.dart`

```dart
class BoatPosition {
  final LatLng position;
  final double? heading;    // degrees, 0-360
  final double? speed;      // knots
  final double? altitude;   // meters
  final DateTime timestamp;
  final int? satellites;
  final double? hdop;
  
  const BoatPosition({
    required this.position,
    this.heading,
    this.speed,
    this.altitude,
    required this.timestamp,
    this.satellites,
    this.hdop,
  });
  
  factory BoatPosition.fromGPGGA(GPGGAMessage msg) {
    return BoatPosition(
      position: LatLng(msg.latitude, msg.longitude),
      altitude: msg.altitude,
      timestamp: DateTime.now(), // Parse from msg.time
      satellites: msg.satellites,
      hdop: msg.hdop,
    );
  }
}
```

### CacheEntry

**File:** `lib/models/cache_entry.dart`

```dart
class CacheEntry {
  final String key;
  final int created;      // milliseconds since epoch
  final int lastAccess;   // milliseconds since epoch
  final int size;         // bytes
  final int? ttl;         // milliseconds (null = no expiry)
  
  const CacheEntry({
    required this.key,
    required this.created,
    required this.lastAccess,
    required this.size,
    this.ttl,
  });
  
  bool get isExpired {
    if (ttl == null) return false;
    int now = DateTime.now().millisecondsSinceEpoch;
    return now > (created + ttl!);
  }
  
  CacheEntry accessed() {
    return CacheEntry(
      key: key,
      created: created,
      lastAccess: DateTime.now().millisecondsSinceEpoch,
      size: size,
      ttl: ttl,
    );
  }
  
  Map<String, dynamic> toJson() => {
        'key': key,
        'created': created,
        'lastAccess': lastAccess,
        'size': size,
        'ttl': ttl,
      };
  
  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
        key: json['key'] as String,
        created: json['created'] as int,
        lastAccess: json['lastAccess'] as int,
        size: json['size'] as int,
        ttl: json['ttl'] as int?,
      );
}
```

### NMEAMessage

**File:** `lib/models/nmea_message.dart`

```dart
abstract class NMEAMessage {
  final String rawSentence;
  final DateTime parsedAt;
  
  const NMEAMessage({
    required this.rawSentence,
    required this.parsedAt,
  });
}

class GPGGAMessage extends NMEAMessage {
  final String time;
  final double latitude;
  final double longitude;
  final int quality;
  final int satellites;
  final double hdop;
  final double altitude;
  
  const GPGGAMessage({
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.quality,
    required this.satellites,
    required this.hdop,
    required this.altitude,
    required String rawSentence,
    required DateTime parsedAt,
  }) : super(rawSentence: rawSentence, parsedAt: parsedAt);
}

class GPRMCMessage extends NMEAMessage {
  final String time;
  final String status;
  final double latitude;
  final double longitude;
  final double speedKnots;
  final double trackAngle;
  final String date;
  
  const GPRMCMessage({
    required this.time,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.speedKnots,
    required this.trackAngle,
    required this.date,
    required String rawSentence,
    required DateTime parsedAt,
  }) : super(rawSentence: rawSentence, parsedAt: parsedAt);
}

class GPVTGMessage extends NMEAMessage {
  final double trueTrack;
  final double magneticTrack;
  final double speedKnots;
  final double speedKmh;
  
  const GPVTGMessage({
    required this.trueTrack,
    required this.magneticTrack,
    required this.speedKnots,
    required this.speedKmh,
    required String rawSentence,
    required DateTime parsedAt,
  }) : super(rawSentence: rawSentence, parsedAt: parsedAt);
}
```

---

## Testing Specifications

### Test Structure

```
test/
├── unit/
│   ├── services/
│   │   ├── cache_service_test.dart
│   │   ├── http_client_test.dart
│   │   ├── projection_service_test.dart
│   │   ├── nmea_parser_test.dart
│   │   └── database_service_test.dart
│   ├── models/
│   │   ├── lat_lng_test.dart
│   │   ├── bounds_test.dart
│   │   ├── viewport_test.dart
│   │   ├── boat_position_test.dart
│   │   ├── cache_entry_test.dart
│   │   └── nmea_message_test.dart
└── test_helpers.dart
```

### Test Coverage Requirements

| Component | Minimum Coverage | Priority |
|-----------|-----------------|----------|
| CacheService | 85% | Critical |
| HttpClient | 85% | Critical |
| ProjectionService | 90% | Critical |
| NMEAParser | 85% | Critical |
| DatabaseService | 80% | High |
| Data Models | 80% | High |

### Test Helpers

**File:** `test/test_helpers.dart`

```dart
// Mock HTTP client for testing
class MockHttpClient extends Mock implements http.Client {}

// Test NMEA sentences
const String validGPGGA = '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
const String invalidChecksumGPGGA = '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*99';

// Test coordinates
const LatLng nullIsland = LatLng(0, 0);
const LatLng london = LatLng(51.5074, -0.1278);
const LatLng portland = LatLng(45.5231, -122.6765);
const LatLng northPole = LatLng(90, 0);
const LatLng southPole = LatLng(-90, 0);

// Temporary directory for cache tests
Future<Directory> createTempCacheDir() async {
  Directory tempDir = await Directory.systemTemp.createTemp('cache_test_');
  return tempDir;
}

// Cleanup after tests
Future<void> deleteTempDir(Directory dir) async {
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
```

### Sample Test Cases

#### CacheService Tests

```dart
void main() {
  group('CacheService', () {
    late CacheService cache;
    late Directory tempDir;
    
    setUp(() async {
      tempDir = await createTempCacheDir();
      cache = CacheService(cacheDir: tempDir.path, maxSize: 1000);
      await cache.init();
    });
    
    tearDown(() async {
      await cache.dispose();
      await deleteTempDir(tempDir);
    });
    
    test('should store and retrieve values', () async {
      await cache.put('key1', 'value1');
      final value = await cache.get<String>('key1');
      expect(value, equals('value1'));
    });
    
    test('should return null for expired entries', () async {
      await cache.put('key1', 'value1', ttl: Duration(seconds: 1));
      await Future.delayed(Duration(seconds: 2));
      final value = await cache.get<String>('key1');
      expect(value, isNull);
    });
    
    test('should evict LRU entries when size limit reached', () async {
      // Add 6 entries with 5 entry limit
      for (int i = 0; i < 6; i++) {
        await cache.put('key$i', 'value' * 20); // Each ~100 bytes
      }
      
      // Oldest entry (key0) should be evicted
      final value = await cache.get<String>('key0');
      expect(value, isNull);
      
      // Newest entries should still exist
      final value5 = await cache.get<String>('key5');
      expect(value5, isNotNull);
    });
  });
}
```

#### ProjectionService Tests

```dart
void main() {
  group('ProjectionService', () {
    late ProjectionService service;
    
    setUp(() {
      service = ProjectionService();
    });
    
    test('should convert WGS84 to Web Mercator accurately', () {
      final p = service.wgs84ToWebMercator(51.5074, -0.1278);
      expect(p.x, closeTo(-14231.0, 1.0));
      expect(p.y, closeTo(6711533.0, 1.0));
    });
    
    test('should handle round-trip conversion', () {
      const original = LatLng(45.5231, -122.6765);
      final mercator = service.wgs84ToWebMercator(
        original.latitude, 
        original.longitude
      );
      final back = service.webMercatorToWgs84(mercator.x, mercator.y);
      
      expect(back.latitude, closeTo(original.latitude, 0.0001));
      expect(back.longitude, closeTo(original.longitude, 0.0001));
    });
    
    test('should clamp latitude to Web Mercator limits', () {
      final p = service.wgs84ToWebMercator(90, 0);
      final back = service.webMercatorToWgs84(p.x, p.y);
      expect(back.latitude, lessThanOrEqualTo(85.1));
    });
  });
}
```

#### NMEAParser Tests

```dart
void main() {
  group('NMEAParser', () {
    late NMEAParser parser;
    
    setUp(() {
      parser = NMEAParser();
    });
    
    test('should validate correct checksum', () {
      const sentence = '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      expect(parser.validateChecksum(sentence), isTrue);
    });
    
    test('should reject invalid checksum', () {
      const sentence = '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*99';
      expect(parser.validateChecksum(sentence), isFalse);
    });
    
    test('should parse valid GPGGA sentence', () {
      const sentence = '\$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      final msg = NMEAParser.parseGPGGA(sentence);
      
      expect(msg, isNotNull);
      expect(msg!.latitude, closeTo(48.1173, 0.0001));
      expect(msg.longitude, closeTo(11.5167, 0.0001));
      expect(msg.satellites, equals(8));
    });
    
    test('should return null for malformed sentence', () {
      const sentence = '\$GPGGA,123519,INVALID,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47';
      final msg = NMEAParser.parseGPGGA(sentence);
      expect(msg, isNull);
    });
  });
}
```

---

## Implementation Checklist

### Before Implementation
- [x] Read and understand all architecture rules
- [x] Review failure analysis from previous attempts
- [x] Understand provider dependency constraints
- [x] Identify performance benchmarks

### CacheService
- [ ] Create `lib/services/cache_service.dart`
- [ ] Implement LRU eviction algorithm
- [ ] Add TTL expiry checking
- [ ] Add thread-safe operations
- [ ] Write unit tests (85% coverage)
- [ ] Benchmark performance (<10ms get)
- [ ] Verify <300 lines

### HttpClient
- [ ] Create `lib/services/http_client.dart`
- [ ] Implement retry with exponential backoff
- [ ] Add timeout handling
- [ ] Add request logging (sanitized)
- [ ] Write unit tests (85% coverage)
- [ ] Test all error scenarios
- [ ] Verify <300 lines

### ProjectionService
- [ ] Create `lib/services/projection_service.dart`
- [ ] Implement WGS84 ↔ Web Mercator
- [ ] Add screen coordinate transformations
- [ ] Handle rotation and tilt
- [ ] Write unit tests (90% coverage)
- [ ] Benchmark performance (<1ms)
- [ ] Verify <300 lines

### NMEAParser
- [ ] Create `lib/services/nmea_parser.dart`
- [ ] Implement checksum validation
- [ ] Add GPGGA parser
- [ ] Add GPRMC parser
- [ ] Add GPVTG parser
- [ ] Write unit tests (85% coverage)
- [ ] Benchmark performance (100+ sentences/s)
- [ ] Verify <300 lines

### DatabaseService
- [ ] Create `lib/services/database_service.dart`
- [ ] Implement SQLite wrapper
- [ ] Create schema
- [ ] Add CRUD operations
- [ ] Write unit tests (80% coverage)
- [ ] Verify <300 lines

### Data Models
- [ ] Create `lib/models/lat_lng.dart`
- [ ] Create `lib/models/bounds.dart`
- [ ] Create `lib/models/viewport.dart`
- [ ] Create `lib/models/boat_position.dart`
- [ ] Create `lib/models/cache_entry.dart`
- [ ] Create `lib/models/nmea_message.dart`
- [ ] Write unit tests for all models
- [ ] Verify immutability

### Testing
- [ ] Create `test/test_helpers.dart`
- [ ] Write all unit tests
- [ ] Achieve 80%+ overall coverage
- [ ] Set up coverage reporting
- [ ] Add to CI/CD pipeline

---

## Document End

**Next Steps:** Once Flutter SDK is available, use this specification to implement all services and models. All algorithms, error handling, and test cases are defined and ready for immediate coding.
