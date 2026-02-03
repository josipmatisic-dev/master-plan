# Phase 0 Foundation - Detailed Technical Specification

**Version:** 1.0
**Date Created:** 2026-02-01
**Status:** Draft
**Related Plan:** `.copilot-tracking/plans/phase-0-foundation-1.md`

## Table of Contents

1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [Service Layer Specifications](#service-layer-specifications)
4. [Data Model Specifications](#data-model-specifications)
5. [Provider Layer Specifications](#provider-layer-specifications)
6. [Theme System Specifications](#theme-system-specifications)
7. [Testing Strategy](#testing-strategy)
8. [Performance Requirements](#performance-requirements)
9. [Security Requirements](#security-requirements)
10. [File Organization](#file-organization)

---

## Overview

This document provides detailed technical specifications for Phase 0 foundation work. It expands on the implementation plan with specific technical details, code patterns, and quality requirements.

### Goals

- Establish solid architectural foundation following lessons from `docs/MASTER_DEVELOPMENT_BIBLE.md`
- Prevent past failures: god objects, circular dependencies, projection mismatches
- Set up comprehensive testing and CI/CD infrastructure
- Implement core services that will support all subsequent phases
- Establish code quality standards and development workflows

### Key Success Criteria

1. All services remain under 300 lines per file
2. Provider dependency graph is acyclic and documented
3. 80%+ test coverage for services and models
4. Zero hardcoded secrets or API keys
5. All coordinate transformations go through ProjectionService
6. CI/CD pipeline catches regressions automatically

---

## Architecture Principles

### SOLID Principles Application

**Single Responsibility Principle**
- Each service has ONE clear responsibility
- CacheService: Only caching logic
- HttpClient: Only HTTP communication
- ProjectionService: Only coordinate transformations
- NMEAParser: Only NMEA sentence parsing

**Open/Closed Principle**
- Services designed for extension through composition
- Abstract interfaces for testing (dependency injection)
- Configuration through dependency injection, not hardcoding

**Liskov Substitution Principle**
- Mock implementations for all services in tests
- Interface contracts clearly defined

**Interface Segregation Principle**
- Small, focused interfaces
- No "god interfaces" requiring everything

**Dependency Inversion Principle**
- High-level modules depend on abstractions
- Providers consume service interfaces, not concrete implementations

### Provider Dependency Layers

Following CON-004 from `docs/MASTER_DEVELOPMENT_BIBLE.md`:

```text
Layer 0 (No Dependencies):
- SettingsProvider

Layer 1 (Depends on Layer 0):
- ThemeProvider (depends on SettingsProvider)
- CacheProvider (depends on SettingsProvider)

Layer 2 (Future phases):
- MapProvider (depends on CacheProvider, SettingsProvider)
- WeatherProvider (depends on CacheProvider, SettingsProvider)
```text

**Rules:**
- Providers NEVER depend on providers in the same layer
- Dependencies only flow downward (higher layers can depend on lower)
- Document ALL dependencies in `docs/CODEBASE_MAP.md`

---

## Service Layer Specifications

### CacheService

**File:** `lib/services/cache_service.dart`

**Purpose:** LRU disk cache with TTL for weather data, map tiles, API responses

**Public Interface:**

```dart
class CacheService {
  Future<void> init();
  Future<T?> get<T>(String key);
  Future<void> put<T>(String key, T value, {Duration? ttl});
  Future<void> delete(String key);
  Future<void> clear();
  Future<int> getSize();
  Future<void> dispose();
}
```text

**Requirements:**

- **REQ-CS-001**: Maximum cache size 500MB (configurable)
- **REQ-CS-002**: LRU eviction when size limit reached
- **REQ-CS-003**: TTL support with automatic expiry
- **REQ-CS-004**: Thread-safe operations (use mutex/lock)
- **REQ-CS-005**: Graceful degradation if disk write fails
- **REQ-CS-006**: Serialization to JSON for objects
- **REQ-CS-007**: File size under 300 lines

**Implementation Details:**

- Use `path_provider` for cache directory
- Store metadata in separate `.meta` files (JSON)
- Metadata includes: timestamp, size, ttl, access_count
- Check TTL on every get() operation
- Run cleanup on init() to remove expired entries
- Track total size in memory, update on put/delete

**Error Handling:**

- If disk full: Log error, return null for get(), skip put()
- If JSON parse fails: Delete corrupt entry, return null
- If permission denied: Log error, fallback to memory-only mode

**Testing Requirements:**

- Unit test: LRU eviction (add 6 items with 5 item limit, verify oldest removed)
- Unit test: TTL expiry (put with 1s TTL, wait 2s, verify null returned)
- Unit test: Size limit enforcement
- Unit test: Concurrent access safety

---

### HttpClient

**File:** `lib/services/http_client.dart`

**Purpose:** Wrapper for HTTP requests with retry, timeout, error handling

**Public Interface:**

```dart
class HttpClient {
  Future<Response> get(String url, {Map<String, String>? headers});
  Future<Response> post(String url, {Map<String, String>? headers, dynamic body});
  Future<T> getJson<T>(String url, T Function(Map<String, dynamic>) fromJson);
  void dispose();
}
```text

**Requirements:**

- **REQ-HC-001**: 3 retry attempts with exponential backoff (1s, 2s, 4s)
- **REQ-HC-002**: 30 second timeout per request
- **REQ-HC-003**: Validate response status codes (200-299 success)
- **REQ-HC-004**: Parse JSON responses with error handling
- **REQ-HC-005**: Log all requests and errors
- **REQ-HC-006**: Support custom headers (auth, content-type)
- **REQ-HC-007**: File size under 300 lines

**Implementation Details:**

- Use dart `http` package
- Retry only on network errors, not 4xx/5xx responses
- Backoff formula: `delay = baseDelay * pow(2, attemptNumber)`
- Include request ID in logs for debugging
- Sanitize sensitive headers before logging

**Error Handling:**

- Network timeout: Throw `TimeoutException`
- HTTP 4xx: Throw `ClientException` (no retry)
- HTTP 5xx: Retry, then throw `ServerException`
- JSON parse error: Throw `FormatException`

**Security:**

- Never log request bodies or auth headers
- Validate HTTPS URLs only (no HTTP in production)
- Sanitize error messages (don't expose internal URLs)

**Testing Requirements:**

- Unit test: Successful request with 200 response
- Unit test: Retry on network timeout (mock 2 failures, 1 success)
- Unit test: No retry on 404 error
- Unit test: Timeout after 30 seconds
- Unit test: JSON parsing with valid/invalid data

---

### ProjectionService

**File:** `lib/services/projection_service.dart`

**Purpose:** Coordinate transformations between WGS84 and Web Mercator

**Public Interface:**

```dart
class ProjectionService {
  LatLng webMercatorToWgs84(double x, double y);
  Point wgs84ToWebMercator(double lat, double lng);
  Point latLngToScreen(LatLng latLng, Viewport viewport, Size screenSize);
  LatLng screenToLatLng(Offset screenPoint, Viewport viewport, Size screenSize);
}
```text

**Requirements:**

- **REQ-PS-001**: Accurate transformations (error < 0.0001 degrees)
- **REQ-PS-002**: Handle edge cases (poles, dateline crossing)
- **REQ-PS-003**: Account for viewport rotation and tilt
- **REQ-PS-004**: Performance: <1ms per transformation
- **REQ-PS-005**: File size under 300 lines

**Implementation Details:**

- Web Mercator formulas:
  - `x = R * lng * (π/180)`
  - `y = R * ln(tan(π/4 + lat*(π/360)))`
  - Earth radius R = 6378137 meters
- Inverse formulas for reverse transformation
- Clamp latitude to ±85.05112878 (Web Mercator limit)
- Handle viewport transformations with matrix math

**Error Handling:**

- Invalid latitude (>90 or <-90): Clamp to valid range, log warning
- Invalid longitude (>180 or <-180): Normalize to -180 to 180
- NaN or Infinity: Throw `ArgumentError`

**Testing Requirements:**

- Unit test: Known coordinates (0,0), (45,-122), extreme values
- Unit test: Round-trip conversion (WGS84→WebMercator→WGS84)
- Unit test: Pole handling (lat=90, lat=-90)
- Unit test: Dateline crossing (lng=180, lng=-180)
- Unit test: Screen coordinate transformation with different viewports

---

### NMEAParser

**File:** `lib/services/nmea_parser.dart`

**Purpose:** Parse NMEA 0183 sentences for GPS and sensor data

**Public Interface:**

```dart
class NMEAParser {
  NMEAMessage? parse(String sentence);
  bool validateChecksum(String sentence);
  static NMEAMessage? parseGPGGA(String sentence);
  static NMEAMessage? parseGPRMC(String sentence);
  static NMEAMessage? parseGPVTG(String sentence);
}
```text

**Requirements:**

- **REQ-NP-001**: Support GPGGA, GPRMC, GPVTG sentence types
- **REQ-NP-002**: Validate checksums for all sentences
- **REQ-NP-003**: Handle malformed sentences gracefully
- **REQ-NP-004**: Extract all relevant fields (lat, lng, speed, heading, time)
- **REQ-NP-005**: Performance: Parse 100+ sentences/second
- **REQ-NP-006**: File size under 300 lines

**NMEA Sentence Format:**

```bash
$GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47
  │     │       │        │ │         │ │ │   │   │     │ │    │  └─ Checksum
  │     │       │        │ │         │ │ │   │   │     │ │    └─ Units
  │     │       │        │ │         │ │ │   │   │     │ └─ Geoid separation
  │     │       │        │ │         │ │ │   │   │     └─ Altitude
  │     │       │        │ │         │ │ │   │   └─ Units
  │     │       │        │ │         │ │ │   └─ HDOP
  │     │       │        │ │         │ │ └─ Satellites
  │     │       │        │ │         │ └─ Fix quality
  │     │       │        │ └─ Longitude
  │     │       └─ Latitude
  └─ Type
```text

**Implementation Details:**

- Checksum: XOR of all bytes between $ and *
- Parse fields by splitting on commas
- Convert DDMM.MMMM format to decimal degrees
- Handle empty fields (null values)
- Log unknown sentence types for future support

**Error Handling:**

- Invalid checksum: Return null, log warning
- Missing required fields: Return null, log warning
- Invalid format: Return null, log warning
- Unknown sentence type: Return null, log info

**Testing Requirements:**

- Unit test: Valid GPGGA sentence
- Unit test: Invalid checksum rejected
- Unit test: Malformed sentence (missing fields)
- Unit test: Unknown sentence type
- Unit test: Coordinate conversion accuracy

---

## Data Model Specifications

### LatLng Model

**File:** `lib/models/lat_lng.dart`

**Purpose:** Immutable WGS84 coordinate pair

```dart
class LatLng {
  final double latitude;
  final double longitude;
  
  const LatLng(this.latitude, this.longitude);
  
  // Validation, equality, toString, toJson, fromJson
}
```text

**Requirements:**

- Immutable (final fields)
- Validation: latitude [-90, 90], longitude [-180, 180]
- Equality based on values (override ==, hashCode)
- JSON serialization support

---

### Bounds Model

**File:** `lib/models/bounds.dart`

**Purpose:** Geographic bounding box

```dart
class Bounds {
  final LatLng southwest;
  final LatLng northeast;
  
  const Bounds(this.southwest, this.northeast);
  
  bool contains(LatLng point);
  bool intersects(Bounds other);
  // Additional methods
}
```text

---

### Viewport Model

**File:** `lib/models/viewport.dart`

**Purpose:** Map viewport state

```dart
class Viewport {
  final LatLng center;
  final double zoom;
  final double bearing; // degrees, 0-360
  final double pitch;   // degrees, 0-60
  
  const Viewport({
    required this.center,
    required this.zoom,
    this.bearing = 0.0,
    this.pitch = 0.0,
  });
}
```text

---

## Provider Layer Specifications

### SettingsProvider

**File:** `lib/providers/settings_provider.dart`

**Purpose:** User preferences and app configuration

```dart
class SettingsProvider extends ChangeNotifier {
  SpeedUnit _speedUnit = SpeedUnit.knots;
  DistanceUnit _distanceUnit = DistanceUnit.nauticalMiles;
  String _language = 'en';
  
  Future<void> loadSettings();
  Future<void> saveSettings();
  void setSpeedUnit(SpeedUnit unit);
  void setDistanceUnit(DistanceUnit unit);
  void setLanguage(String lang);
}
```text

**Requirements:**

- Persist settings with `shared_preferences`
- Notify listeners on changes
- Load settings on app start
- Provide sensible defaults

---

### ThemeProvider

**File:** `lib/providers/theme_provider.dart`

**Purpose:** Theme mode management

```dart
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  
  ThemeProvider(SettingsProvider settings);
  
  void toggleDarkMode();
  ThemeData get lightTheme;
  ThemeData get darkTheme;
}
```text

**Requirements:**

- Depends on SettingsProvider for persistence
- Support system theme detection
- Smooth theme transitions

---

## Theme System Specifications

### Marine Color Palette

**File:** `lib/theme/colors.dart`

```dart
class MarineColors {
  // Primary (Ocean Blues)
  static const deepOcean = Color(0xFF003D5B);
  static const oceanBlue = Color(0xFF00698F);
  static const skyBlue = Color(0xFF30A9DE);
  
  // Accent (Coral/Warning)
  static const coral = Color(0xFFE85D75);
  static const sunset = Color(0xFFFF6F61);
  
  // Neutrals
  static const navyGray = Color(0xFF2C3E50);
  static const seafoam = Color(0xFFA8DADC);
  static const white = Color(0xFFF1FAEE);
}
```text

---

## Testing Strategy

### Test Structure

```text
test/
├── unit/
│   ├── services/
│   │   ├── cache_service_test.dart
│   │   ├── http_client_test.dart
│   │   ├── projection_service_test.dart
│   │   └── nmea_parser_test.dart
│   ├── models/
│   │   ├── lat_lng_test.dart
│   │   ├── bounds_test.dart
│   │   └── viewport_test.dart
│   └── utils/
├── widget/
│   └── providers/
│       ├── settings_provider_test.dart
│       └── theme_provider_test.dart
└── integration/
    └── app_initialization_test.dart
```text

### Coverage Requirements

- Services: 80%+
- Models: 80%+
- Providers: 70%+
- Overall: 75%+

### CI/CD Testing

- Run tests on every push
- Block PR merge if tests fail
- Generate coverage report
- Fail if coverage drops below threshold

---

## Performance Requirements

### Benchmarks

- CacheService.get(): <10ms
- HttpClient.get(): <100ms (excluding network latency)
- ProjectionService transformations: <1ms
- NMEAParser.parse(): <5ms per sentence

### Memory Limits

- CacheService: 500MB maximum
- App idle state: <100MB RAM
- No memory leaks (test with DevTools)

---

## Security Requirements

### Secrets Management

- Use `.env` file for API keys (not committed)
- Load with `flutter_dotenv` package
- Validate all environment variables on startup

### Input Validation

- All user input sanitized
- API responses validated before use
- NMEA sentences validated (checksum)

### Network Security

- HTTPS only for external APIs
- Certificate pinning for critical APIs (future)
- Timeout all network requests

---

## File Organization

### Complete File List

```text
lib/
├── main.dart
├── models/
│   ├── lat_lng.dart
│   ├── bounds.dart
│   ├── viewport.dart
│   ├── boat_position.dart
│   ├── cache_entry.dart
│   └── nmea_message.dart
├── providers/
│   ├── settings_provider.dart
│   ├── theme_provider.dart
│   └── cache_provider.dart
├── services/
│   ├── cache_service.dart
│   ├── http_client.dart
│   ├── projection_service.dart
│   ├── nmea_parser.dart
│   └── database_service.dart
├── theme/
│   ├── colors.dart
│   ├── text_styles.dart
│   ├── dimensions.dart
│   └── app_theme.dart
└── utils/
    └── constants.dart
```text

---

## References

- [Implementation Plan](../plans/phase-0-foundation-1.md)
- [Execution Prompt](../prompts/execute-phase-0-foundation-1.prompt.md)
- [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md)
- [Effective Dart](https://dart.dev/effective-dart)
- [Flutter Architecture Recommendations](https://docs.flutter.dev/app-architecture/recommendations)
