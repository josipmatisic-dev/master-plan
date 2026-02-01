---
goal: Phase 0 Foundation - Project Setup and Core Architecture
version: 1.0
date_created: 2026-02-01
last_updated: 2026-02-01
owner: Development Team
status: 'Planned'
tags: [foundation, architecture, setup, infrastructure]
---

# Phase 0: Foundation - Implementation Plan

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

**Duration:** Week 1-2 (10 working days)  
**Effort:** ~80 hours  
**Dependencies:** None (First phase)

## Introduction

Phase 0 establishes the foundational architecture, core services, and development infrastructure for the Marine Navigation App. This phase is critical for preventing the architectural failures documented in MASTER_DEVELOPMENT_BIBLE Section A (god objects, circular dependencies, projection mismatches, provider chaos).

**Key Objectives:**
- Initialize Flutter project with proper structure
- Establish provider architecture with clear dependency hierarchy
- Implement core services (ProjectionService, CacheService, HTTP client)
- Setup comprehensive testing infrastructure
- Create CI/CD pipeline
- Document architecture decisions

**Success Metrics:**
- All core services implemented and tested (100% coverage)
- Provider dependency graph documented
- CI/CD pipeline green
- Zero circular dependencies
- All architecture rules from MASTER_DEVELOPMENT_BIBLE Section C enforced

## 1. Requirements & Constraints

### Architecture Requirements

- **REQ-001**: Maximum 300 lines per file (MASTER_DEVELOPMENT_BIBLE C.5)
- **REQ-002**: Maximum 3-layer provider dependency hierarchy (MASTER_DEVELOPMENT_BIBLE C.3)
- **REQ-003**: All providers created in main.dart (AI_AGENT_INSTRUCTIONS MB.2)
- **REQ-004**: Single source of truth for all data (MASTER_DEVELOPMENT_BIBLE C.1)
- **REQ-005**: All coordinate transformations through ProjectionService (MASTER_DEVELOPMENT_BIBLE C.2)
- **REQ-006**: Dispose all controllers and subscriptions (MASTER_DEVELOPMENT_BIBLE C.10)

### Security Requirements

- **SEC-001**: No hardcoded API keys or secrets (AI_AGENT_INSTRUCTIONS FA.1)
- **SEC-002**: All network requests with timeout (10s default) (MASTER_DEVELOPMENT_BIBLE C.4)
- **SEC-003**: Input validation on all external data
- **SEC-004**: Secure storage for sensitive user data

### Technical Constraints

- **CON-001**: Flutter SDK 3.16+ required
- **CON-002**: Dart SDK 3.0+ required
- **CON-003**: Target iOS 12+ and Android 8.0+ (API 26+)
- **CON-004**: Must work offline-first (cache-first architecture)
- **CON-005**: Maximum app size 100MB (excluding cached data)

### Development Guidelines

- **GUD-001**: Follow Provider pattern for state management
- **GUD-002**: Use freezed for immutable data models
- **GUD-003**: Write tests before implementation (TDD)
- **GUD-004**: Document all public APIs with dartdoc
- **GUD-005**: Use conventional commits for Git messages

### Architectural Patterns

- **PAT-001**: Repository pattern for data layer (MASTER_DEVELOPMENT_BIBLE Section B)
- **PAT-002**: MVVM pattern for UI layer (separation of concerns)
- **PAT-003**: Dependency injection via Provider
- **PAT-004**: Cache-first with background refresh
- **PAT-005**: Isolate-based processing for heavy computation

## 2. Implementation Steps

### Implementation Phase 1: Project Initialization

**GOAL-001**: Setup Flutter project with proper structure and dependencies

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Create Flutter project with `flutter create marine_nav_app --org dev.sailstream` | | |
| TASK-002 | Configure pubspec.yaml with required dependencies (provider, freezed, etc.) | | |
| TASK-003 | Setup project directory structure as per CODEBASE_MAP.md | | |
| TASK-004 | Configure analysis_options.yaml with strict linting rules | | |
| TASK-005 | Create .gitignore with Flutter defaults + custom exclusions | | |
| TASK-006 | Initialize Git repository and make initial commit | | |
| TASK-007 | Create README.md with project overview | | |
| TASK-008 | Setup environment configuration (.env files for dev/staging/prod) | | |

**Known Issues to Avoid:**
- ISS-003: Don't create providers in widget build methods

**Validation:**
- `flutter doctor` passes all checks
- `flutter analyze` shows zero issues
- All directories in CODEBASE_MAP created
- Linter enforces 300-line file limit

---

### Implementation Phase 2: Core Data Models

**GOAL-002**: Implement immutable data models for core domain objects

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-009 | Create LatLng model with WGS84 coordinates | | |
| TASK-010 | Create Bounds model for geographic rectangles | | |
| TASK-011 | Create Viewport model with zoom/center/rotation | | |
| TASK-012 | Create BoatPosition model with GPS data | | |
| TASK-013 | Create WeatherData model with forecast fields | | |
| TASK-014 | Create WindData model with speed/direction | | |
| TASK-015 | Create WaveData model with height/period/direction | | |
| TASK-016 | Generate freezed code with `flutter pub run build_runner build` | | |

**Known Issues to Avoid:**
- ISS-004: Ensure models are truly immutable (use @freezed)

**Validation:**
- All models use @freezed annotation
- copyWith() methods generated
- Equality comparison works correctly
- JSON serialization/deserialization works
- Unit tests for all models (100% coverage)

---

### Implementation Phase 3: Projection Service

**GOAL-003**: Implement ProjectionService for all coordinate transformations

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-017 | Create ProjectionService class skeleton | | |
| TASK-018 | Implement WGS84 to Web Mercator projection | | |
| TASK-019 | Implement Web Mercator to WGS84 inverse projection | | |
| TASK-020 | Implement latLngToPixels(lat, lng, viewport) method | | |
| TASK-021 | Implement pixelsToLatLng(offset, viewport) method | | |
| TASK-022 | Add zoom level calculations | | |
| TASK-023 | Add rotation transformation support | | |
| TASK-024 | Add unit tests with known coordinate pairs | | |

**Known Issues to Avoid:**
- **ISS-001**: CRITICAL - Overlay projection mismatch at zoom
- **ISS-012**: Wind arrow direction inverted (meteorological vs mathematical)

**Critical Implementation Details:**
```dart
// CORRECT: Web Mercator projection
static Offset latLngToPixels(double lat, double lng, Viewport viewport) {
  // Convert WGS84 to Web Mercator
  final x = (lng + 180.0) / 360.0;
  final latRad = lat * pi / 180.0;
  final y = (1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0;
  
  // Apply viewport transformation
  final worldSize = 256 * pow(2, viewport.zoom);
  final screenX = (x * worldSize) - viewport.centerX;
  final screenY = (y * worldSize) - viewport.centerY;
  
  // Apply rotation if present
  if (viewport.rotation != 0) {
    final angle = viewport.rotation * pi / 180;
    final cos = math.cos(angle);
    final sin = math.sin(angle);
    return Offset(
      screenX * cos - screenY * sin,
      screenX * sin + screenY * cos,
    );
  }
  
  return Offset(screenX, screenY);
}
```

**Validation:**
- Known coordinate pairs transform correctly
- Inverse transformation returns original coordinates (within 0.0001°)
- Zoom level changes don't affect relative positions
- Rotation transformations accurate to 0.1°
- Test coverage 100%

---

### Implementation Phase 4: Cache Service

**GOAL-004**: Implement LRU cache with TTL and coordinated invalidation

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-025 | Create CacheService class with LRU eviction | | |
| TASK-026 | Implement TTL-based expiry | | |
| TASK-027 | Add cache size limit (500MB default) | | |
| TASK-028 | Implement get/set/delete methods | | |
| TASK-029 | Add category-based invalidation | | |
| TASK-030 | Implement disk persistence with path_provider | | |
| TASK-031 | Add cache statistics (hit rate, size, entries) | | |
| TASK-032 | Create unit tests for all cache operations | | |

**Known Issues to Avoid:**
- **ISS-004**: CRITICAL - Stale weather data after fetch
- ISS-017: Tile cache growing indefinitely

**Critical Implementation Details:**
- Single unified cache (no multiple cache layers)
- Version tags for cache keys
- Coordinated invalidation across all cache types
- Background cleanup of expired entries

**Validation:**
- LRU eviction works correctly
- TTL expiry removes old entries
- Size limit enforced (oldest entries removed)
- Category invalidation clears all related entries
- Cache persists across app restarts
- Test coverage 100%

---

### Implementation Phase 5: HTTP Client with Retry

**GOAL-005**: Implement RetryableHttpClient with exponential backoff

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-033 | Create RetryableHttpClient wrapper class | | |
| TASK-034 | Implement exponential backoff algorithm | | |
| TASK-035 | Add timeout support (10s default) | | |
| TASK-036 | Implement retry on timeout/socket errors | | |
| TASK-037 | Add request/response logging | | |
| TASK-038 | Implement cache-on-error fallback | | |
| TASK-039 | Create mock server for testing | | |
| TASK-040 | Write integration tests for retry logic | | |

**Known Issues to Avoid:**
- ISS-010: Offline mode shows connection error even with cache

**Critical Implementation Details:**
```dart
Future<http.Response> getWithRetry(String url, {int maxRetries = 3}) async {
  int attempt = 0;
  
  while (attempt < maxRetries) {
    try {
      final response = await http.get(Uri.parse(url))
        .timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return response;
      } else if (response.statusCode >= 500) {
        // Server error - retry
        attempt++;
        await Future.delayed(Duration(seconds: pow(2, attempt)));
      } else {
        // Client error - don't retry
        throw ApiException(response.statusCode);
      }
    } on TimeoutException {
      attempt++;
      if (attempt >= maxRetries) {
        // Try cache fallback
        final cached = await cacheService.get(url);
        if (cached != null) return cached;
        rethrow;
      }
      await Future.delayed(Duration(seconds: pow(2, attempt)));
    } on SocketException {
      // Network error - try cache immediately
      final cached = await cacheService.get(url);
      if (cached != null) return cached;
      rethrow;
    }
  }
  
  throw MaxRetriesException();
}
```

**Validation:**
- Retries on server errors (5xx)
- Doesn't retry on client errors (4xx)
- Exponential backoff works (1s, 2s, 4s, 8s)
- Timeout after 10 seconds
- Cache fallback on network errors
- Test coverage 100%

---

### Implementation Phase 6: Provider Architecture

**GOAL-006**: Setup provider dependency hierarchy in main.dart

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-041 | Create SettingsProvider for user preferences | | |
| TASK-042 | Create ThemeProvider for dark mode | | |
| TASK-043 | Create CacheProvider for cache coordination | | |
| TASK-044 | Document provider dependency graph | | |
| TASK-045 | Configure MultiProvider in main.dart | | |
| TASK-046 | Add provider dependency diagram to CODEBASE_MAP.md | | |
| TASK-047 | Validate no circular dependencies | | |
| TASK-048 | Create provider integration tests | | |

**Known Issues to Avoid:**
- **ISS-002**: CRITICAL - God objects and circular dependencies
- **ISS-003**: CRITICAL - ProviderNotFoundException on hot reload
- ISS-007: State inconsistency across screens

**Critical Implementation Details:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services (no providers)
  final cacheService = CacheService();
  await cacheService.initialize();
  
  final httpClient = RetryableHttpClient();
  final projectionService = ProjectionService();
  
  runApp(
    MultiProvider(
      providers: [
        // Layer 1: No dependencies
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(),
        ),
        
        // Layer 2: Depends on Layer 1
        ChangeNotifierProxyProvider<SettingsProvider, ThemeProvider>(
          create: (_) => ThemeProvider(),
          update: (_, settings, theme) => theme!..updateFromSettings(settings),
        ),
        
        // Layer 3: Depends on Layer 2
        ChangeNotifierProvider(
          create: (_) => CacheProvider(cacheService),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

**Validation:**
- All providers created in main.dart
- Maximum 3 dependency layers
- No circular dependencies
- Dependency graph documented
- Hot reload works correctly
- Test coverage for provider initialization

---

### Implementation Phase 7: Testing Infrastructure

**GOAL-007**: Setup comprehensive testing infrastructure

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-049 | Configure test directory structure | | |
| TASK-050 | Create test utilities and helpers | | |
| TASK-051 | Setup widget test infrastructure | | |
| TASK-052 | Setup integration test infrastructure | | |
| TASK-053 | Configure code coverage reporting | | |
| TASK-054 | Create mock data generators | | |
| TASK-055 | Setup golden file testing | | |
| TASK-056 | Document testing guidelines | | |

**Testing Requirements:**
- Minimum 80% code coverage for all new code
- Unit tests for all services and models
- Widget tests for all custom widgets
- Integration tests for critical flows
- Golden tests for UI consistency

**Validation:**
- `flutter test` passes all tests
- Coverage report generated
- All mock data generators work
- Golden file tests pass
- CI runs tests automatically

---

### Implementation Phase 8: CI/CD Pipeline

**GOAL-008**: Setup automated build, test, and deployment pipeline

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-057 | Create GitHub Actions workflow for tests | | |
| TASK-058 | Add workflow for linting and formatting | | |
| TASK-059 | Add workflow for code coverage | | |
| TASK-060 | Setup automated build for Android | | |
| TASK-061 | Setup automated build for iOS | | |
| TASK-062 | Configure environment secrets | | |
| TASK-063 | Add status badges to README.md | | |
| TASK-064 | Test full CI/CD pipeline | | |

**CI/CD Requirements:**
- All tests must pass before merge
- Linter must show zero issues
- Coverage must be ≥80%
- Build must succeed for both platforms
- Deploy to beta on merge to main

**Validation:**
- GitHub Actions workflows execute successfully
- Failed tests block PR merge
- Coverage reports uploaded
- Builds complete in <10 minutes
- Status badges show green

## 3. Alternatives

### Alternative Approaches Considered

- **ALT-001**: GetX for state management
  - **Rejected**: Provider is official Flutter recommendation, better documentation, simpler DI
  
- **ALT-002**: BLoC pattern for state management
  - **Rejected**: More boilerplate, steeper learning curve, Provider sufficient for needs
  
- **ALT-003**: Dio instead of http package
  - **Rejected**: Can add later if needed, http package simpler for MVP
  
- **ALT-004**: Hive for caching instead of custom service
  - **Rejected**: Need more control over LRU and TTL, Hive can be storage backend
  
- **ALT-005**: MapBox instead of MapTiler
  - **Rejected**: MapTiler has better nautical chart support, offline capabilities

## 4. Dependencies

### External Dependencies

- **DEP-001**: Flutter SDK 3.16+
  - Purpose: Framework
  - Installation: `flutter upgrade`
  
- **DEP-002**: provider ^6.1.0
  - Purpose: State management and DI
  - Installation: Added to pubspec.yaml
  
- **DEP-003**: freezed ^2.4.0
  - Purpose: Immutable data models
  - Installation: Added to pubspec.yaml
  
- **DEP-004**: freezed_annotation ^2.4.0
  - Purpose: Freezed annotations
  - Installation: Added to pubspec.yaml
  
- **DEP-005**: json_annotation ^4.8.0
  - Purpose: JSON serialization
  - Installation: Added to pubspec.yaml
  
- **DEP-006**: build_runner ^2.4.0
  - Purpose: Code generation
  - Installation: Added to dev_dependencies
  
- **DEP-007**: json_serializable ^6.7.0
  - Purpose: JSON serialization code gen
  - Installation: Added to dev_dependencies
  
- **DEP-008**: http ^1.1.0
  - Purpose: HTTP requests
  - Installation: Added to pubspec.yaml
  
- **DEP-009**: path_provider ^2.1.0
  - Purpose: File system access
  - Installation: Added to pubspec.yaml
  
- **DEP-010**: shared_preferences ^2.2.0
  - Purpose: Simple key-value storage
  - Installation: Added to pubspec.yaml

### Internal Dependencies

- **DEP-011**: MASTER_DEVELOPMENT_BIBLE.md must be read before implementation
- **DEP-012**: AI_AGENT_INSTRUCTIONS.md must be followed during development
- **DEP-013**: KNOWN_ISSUES_DATABASE.md must be checked for each component

## 5. Files

### New Files Created

- **FILE-001**: `lib/main.dart` - App entry point with provider setup
- **FILE-002**: `lib/models/lat_lng.dart` - WGS84 coordinate model
- **FILE-003**: `lib/models/bounds.dart` - Geographic bounds model
- **FILE-004**: `lib/models/viewport.dart` - Map viewport state model
- **FILE-005**: `lib/models/boat_position.dart` - GPS position model
- **FILE-006**: `lib/models/weather_data.dart` - Weather data model
- **FILE-007**: `lib/models/wind_data.dart` - Wind data model
- **FILE-008**: `lib/models/wave_data.dart` - Wave data model
- **FILE-009**: `lib/models/cache_entry.dart` - Cache metadata model
- **FILE-010**: `lib/services/projection_service.dart` - Coordinate projection service
- **FILE-011**: `lib/services/cache_service.dart` - LRU cache service
- **FILE-012**: `lib/services/http_client.dart` - Retryable HTTP client
- **FILE-013**: `lib/providers/settings_provider.dart` - Settings state provider
- **FILE-014**: `lib/providers/theme_provider.dart` - Theme state provider
- **FILE-015**: `lib/providers/cache_provider.dart` - Cache coordination provider
- **FILE-016**: `lib/utils/constants.dart` - App-wide constants
- **FILE-017**: `lib/utils/logger.dart` - Logging utility
- **FILE-018**: `test/models/lat_lng_test.dart` - LatLng model tests
- **FILE-019**: `test/services/projection_service_test.dart` - Projection service tests
- **FILE-020**: `test/services/cache_service_test.dart` - Cache service tests
- **FILE-021**: `test/services/http_client_test.dart` - HTTP client tests
- **FILE-022**: `.github/workflows/test.yml` - CI test workflow
- **FILE-023**: `.github/workflows/build.yml` - CI build workflow
- **FILE-024**: `analysis_options.yaml` - Linter configuration
- **FILE-025**: `.env.example` - Environment variables template

### Modified Files

- **FILE-026**: `docs/CODEBASE_MAP.md` - Update with Phase 0 files and provider diagram
- **FILE-027**: `README.md` - Add project overview and setup instructions

## 6. Testing

### Unit Tests Required

- **TEST-001**: LatLng model serialization/deserialization
  - Test JSON encoding and decoding
  - Test equality comparison
  - Test copyWith functionality
  
- **TEST-002**: Bounds model validation
  - Test valid bounds creation
  - Test invalid bounds rejection
  - Test contains point check
  
- **TEST-003**: Viewport model transformations
  - Test zoom level changes
  - Test center point updates
  - Test rotation calculations
  
- **TEST-004**: ProjectionService coordinate transformations
  - Test WGS84 → Web Mercator conversion
  - Test Web Mercator → WGS84 inverse
  - Test pixel transformations with viewport
  - Test rotation accuracy
  - Test edge cases (poles, date line)
  
- **TEST-005**: CacheService operations
  - Test cache set/get/delete
  - Test LRU eviction
  - Test TTL expiry
  - Test size limits
  - Test category invalidation
  - Test persistence across restarts
  
- **TEST-006**: RetryableHttpClient retry logic
  - Test successful request
  - Test timeout retry
  - Test server error retry
  - Test client error no retry
  - Test cache fallback
  - Test max retries exceeded
  
- **TEST-007**: Provider initialization
  - Test provider creation order
  - Test dependency injection
  - Test no circular dependencies
  - Test hot reload recovery

### Integration Tests Required

- **TEST-008**: Full provider hierarchy
  - Test all providers initialize correctly
  - Test data flows through providers
  - Test provider updates trigger UI rebuilds
  
- **TEST-009**: Cache + HTTP integration
  - Test cache-first behavior
  - Test background refresh
  - Test offline fallback

### Widget Tests Required

- **TEST-010**: Provider widget integration
  - Test Consumer rebuilds on provider change
  - Test context.read works correctly
  - Test provider not found errors

### Performance Tests

- **TEST-011**: ProjectionService performance
  - Benchmark 1000 coordinate transformations
  - Must complete in <100ms
  
- **TEST-012**: CacheService performance
  - Benchmark 1000 cache operations
  - Must complete in <500ms

## 7. Risks & Assumptions

### Risks

- **RISK-001**: Projection math errors causing overlay misalignment
  - **Severity**: Critical
  - **Mitigation**: Extensive unit tests with known coordinate pairs, visual validation
  - **Reference**: ISS-001
  
- **RISK-002**: Provider dependency graph becoming too complex
  - **Severity**: High
  - **Mitigation**: Enforce 3-layer maximum, document dependencies clearly
  - **Reference**: ISS-002
  
- **RISK-003**: Cache implementation causing memory leaks
  - **Severity**: High
  - **Mitigation**: Strict size limits, LRU eviction, memory profiling
  - **Reference**: ISS-006
  
- **RISK-004**: HTTP retry logic causing excessive network usage
  - **Severity**: Medium
  - **Mitigation**: Exponential backoff, max retry limits, monitoring
  
- **RISK-005**: Test infrastructure inadequate for catching regressions
  - **Severity**: High
  - **Mitigation**: High coverage requirements, multiple test types, CI enforcement

### Assumptions

- **ASSUMPTION-001**: Flutter 3.16+ provides stable APIs
  - **Validation**: Check Flutter changelog before upgrade
  
- **ASSUMPTION-002**: Provider package sufficient for state management
  - **Validation**: Proven in previous attempts, official recommendation
  
- **ASSUMPTION-003**: 500MB cache size sufficient for offline use
  - **Validation**: Test with real usage patterns, adjustable if needed
  
- **ASSUMPTION-004**: 10-second timeout appropriate for API requests
  - **Validation**: Test with real APIs, adjust based on metrics
  
- **ASSUMPTION-005**: Web Mercator projection sufficient for marine navigation
  - **Validation**: Industry standard, used by MapTiler and others

## 8. Related Specifications / Further Reading

### Primary Documentation

- [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md) - Complete development reference
  - Section A: Failure Analysis - Learn from past mistakes
  - Section C: Architecture Rules - Mandatory compliance
  - Section F: Development Phases - Phase 0 overview
  
- [AI_AGENT_INSTRUCTIONS.md](../../docs/AI_AGENT_INSTRUCTIONS.md) - Development guidelines
  - MB.1: Always Read The Bible First
  - MB.2: Follow The Architecture Rules
  - MB.3: Use Working Code Inventory
  
- [KNOWN_ISSUES_DATABASE.md](../../docs/KNOWN_ISSUES_DATABASE.md) - Issue database
  - ISS-001: Overlay projection mismatch
  - ISS-002: God objects and circular deps
  - ISS-003: ProviderNotFoundException
  - ISS-004: Stale cache data
  - ISS-006: Memory leaks
  
- [CODEBASE_MAP.md](../../docs/CODEBASE_MAP.md) - Project structure reference

### Detail Specifications

- [phase-0-foundation-details.md](../details/phase-0-foundation-details.md) - Detailed component specifications

### Implementation Prompt

- [implement-phase-0-foundation.prompt.md](../prompts/implement-phase-0-foundation.prompt.md) - Step-by-step implementation guide

### External References

- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Freezed Package](https://pub.dev/packages/freezed)
- [Web Mercator Projection](https://en.wikipedia.org/wiki/Web_Mercator_projection)
- [EPSG:3857 Specification](https://epsg.io/3857)

---

**Phase 0 Completion Criteria:**

- [ ] All 64 tasks completed
- [ ] All tests passing (100% coverage for Phase 0 code)
- [ ] CI/CD pipeline green
- [ ] Provider dependency graph documented
- [ ] Zero circular dependencies verified
- [ ] Architecture rules enforced by linter
- [ ] CODEBASE_MAP.md updated
- [ ] All known issues avoided
- [ ] Ready for Phase 1 implementation

**Next Phase:** [Phase 1: Core Navigation](phase-1-core-navigation-plan.md)

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-01  
**Status:** Planned
