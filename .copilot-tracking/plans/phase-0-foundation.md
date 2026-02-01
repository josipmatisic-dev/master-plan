---
goal: "Phase 0: Foundation - Marine Navigation App Setup and Core Infrastructure"
version: "1.0"
date_created: "2026-02-01"
last_updated: "2026-02-01"
owner: "Marine Navigation App Development Team"
status: "Planned"
tags: ["phase-0", "foundation", "infrastructure", "architecture", "setup"]
---

# Introduction

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This plan outlines Phase 0 (Foundation) for the Marine Navigation App, establishing the project structure, core services, testing infrastructure, and architectural foundation. This phase must be completed before any feature development begins to ensure a solid, maintainable codebase that avoids the critical failures documented in the MASTER_DEVELOPMENT_BIBLE.

**Duration:** Week 1-2 (10 working days)  
**Prerequisites:** Flutter 3.16+ SDK, development environment setup  
**Success Criteria:** All core services implemented, tested (>80% coverage), and documented

## 1. Requirements & Constraints

### Critical Requirements

- **REQ-001**: Project must use Flutter 3.16+ with null safety enabled
- **REQ-002**: All providers must be created in main.dart with documented dependency hierarchy (max 3 layers)
- **REQ-003**: Maximum file size: 300 lines per file, 50 lines per method
- **REQ-004**: Minimum test coverage: 80% for all new code
- **REQ-005**: All coordinate transformations must use ProjectionService (no manual lat/lng math - prevents ISS-001)
- **REQ-006**: Cache-first architecture for all network requests (prevents ISS-010)
- **REQ-007**: All resources (controllers, subscriptions, timers) must have explicit disposal (prevents ISS-006)

### Security Requirements

- **SEC-001**: No hardcoded API keys or secrets in source code
- **SEC-002**: All network requests must use HTTPS
- **SEC-003**: Input validation for all user-provided coordinates and bounds
- **SEC-004**: Secure storage for user preferences (SharedPreferences or encrypted storage)

### Architecture Constraints

- **CON-001**: Single source of truth for each data type (no duplicate state - prevents ISS-007)
- **CON-002**: No circular dependencies between providers (prevents ISS-002, ISS-003)
- **CON-003**: Network requests must have timeout (10s default) and retry logic
- **CON-004**: All heavy computation must run in isolates, not main thread (prevents ISS-009)
- **CON-005**: No God objects - use composition over inheritance (prevents ISS-002)

### Guidelines from MASTER_DEVELOPMENT_BIBLE

- **GUD-001**: Follow Section C Architecture Rules (C.1-C.10) religiously
- **GUD-002**: Reference KNOWN_ISSUES_DATABASE before implementing any pattern
- **GUD-003**: Use working code patterns from AI_AGENT_INSTRUCTIONS Section B (B.1-B.8)
- **GUD-004**: Document all provider dependencies in CODEBASE_MAP.md

### Patterns to Follow

- **PAT-001**: Provider pattern for state management (AI_AGENT_INSTRUCTIONS CP.1)
- **PAT-002**: Repository pattern for data access
- **PAT-003**: Service layer for business logic
- **PAT-004**: Cache-first with background refresh (AI_AGENT_INSTRUCTIONS CP.1)

## 2. Implementation Steps

### Implementation Phase 1: Project Initialization

**GOAL-001**: Set up Flutter project structure avoiding ISS-002 (God objects) and ISS-003 (Provider chaos)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-001 | Create Flutter project: `flutter create --org com.marine marine_navigation_app` | | |
| TASK-002 | Configure pubspec.yaml: provider ^6.1.0, http ^1.1.0, shared_preferences ^2.2.0, sqflite ^2.3.0, path_provider ^2.1.0, equatable ^2.0.5 | | |
| TASK-003 | Set up directory structure per CODEBASE_MAP: lib/{models,providers,services,screens,widgets,utils,theme} | | |
| TASK-004 | Configure analysis_options.yaml with lint rules: always_dispose_controllers, avoid_print, prefer_const | | |
| TASK-005 | Create .gitignore: exclude **/*.g.dart, .env, build/, .idea/, coverage/ | | |
| TASK-006 | Set up GitHub Actions CI: flutter analyze, flutter test, coverage upload | | |
| TASK-007 | Create README.md with architecture overview and phase status | | |

### Implementation Phase 2: Core Services - Projection

**GOAL-002**: Implement ProjectionService to prevent ISS-001 (overlay projection mismatch)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-008 | Implement ProjectionService.latLngToMeters() (WGS84 → Web Mercator) per MASTER_DEVELOPMENT_BIBLE Section C.2 | | |
| TASK-009 | Implement ProjectionService.metersToLatLng() (inverse transformation) | | |
| TASK-010 | Implement ProjectionService.latLngToPixels(lat, lng, viewport) for overlay rendering | | |
| TASK-011 | Implement ProjectionService.pixelsToLatLng(offset, viewport) for click handling | | |
| TASK-012 | Add validation: lat ∈ [-85.05112878°, 85.05112878°], lng ∈ [-180°, 180°] | | |
| TASK-013 | Create unit tests: round-trip conversions, edge cases (poles, date line), known coordinates | | |
| TASK-014 | Achieve 100% test coverage for ProjectionService | | |

### Implementation Phase 3: Core Services - Caching

**GOAL-003**: Implement CacheService with LRU and TTL to prevent ISS-004 (stale data)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-015 | Implement CacheService.get<T>(CacheKey) with TTL check and LRU update | | |
| TASK-016 | Implement CacheService.set<T>(CacheKey, value, ttl) with eviction when limit exceeded | | |
| TASK-017 | Implement LRU eviction algorithm (default limit: 100MB) | | |
| TASK-018 | Implement CacheService.invalidateCategory(category) for coordinated cache invalidation | | |
| TASK-019 | Add disk persistence using path_provider | | |
| TASK-020 | Create unit tests: cache hit/miss, TTL expiry, LRU eviction, category invalidation | | |
| TASK-021 | Achieve >90% test coverage for CacheService | | |

### Implementation Phase 4: Core Services - HTTP and NMEA

**GOAL-004**: Implement network and NMEA services to prevent ISS-009 (UI blocking)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-022 | Implement RetryableHttpClient with exponential backoff (3 attempts: 1s, 2s, 4s delays) | | |
| TASK-023 | Add timeout handling (10s default), proper error types (TimeoutException, SocketException, ApiException) | | |
| TASK-024 | Implement NMEAParser.parse(sentence) with XOR checksum validation per NMEA 0183 standard | | |
| TASK-025 | Support sentence types: GPGGA (position), GPRMC (position+speed), GPVTG (course), AIVDM (AIS) | | |
| TASK-026 | Implement isolate-based parsing following AI_AGENT_INSTRUCTIONS CP.3 pattern | | |
| TASK-027 | Add message batching: collect for 200ms before sending to main isolate | | |
| TASK-028 | Create unit tests: valid/invalid checksums, malformed input, high message rate (100/sec) | | |
| TASK-029 | Achieve >95% test coverage for NMEAParser | | |

### Implementation Phase 5: Data Models

**GOAL-005**: Create immutable, validated data models

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-030 | Create LatLng model with validation, equals/hashCode using equatable | | |
| TASK-031 | Create Bounds model with SW/NE corners, validation, contains() method | | |
| TASK-032 | Create Viewport model: center, zoom (1-20), bearing (0-360°), tilt (0-60°) | | |
| TASK-033 | Create BoatPosition model: lat, lng, speed (m/s), heading (°), accuracy (m), timestamp | | |
| TASK-034 | Create WeatherData model: wind, waves, temperature, timestamp | | |
| TASK-035 | Create WindData model: speed (m/s), direction (° meteorological), gustSpeed | | |
| TASK-036 | Create WaveData model: height (m), period (s), direction (°) | | |
| TASK-037 | Create NMEAMessage base and sentence-specific models (GGA, RMC, AIVDM) | | |
| TASK-038 | Add JSON serialization (toJson/fromJson) for all models | | |
| TASK-039 | Create unit tests for all models: validation, equality, serialization | | |

### Implementation Phase 6: Theme System

**GOAL-006**: Implement marine-themed UI with multiple color schemes

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-040 | Define marine color palette: oceanBlue (#003F87), nauticalGold (#D4AF37), safety colors | | |
| TASK-041 | Create light theme (WCAG AA compliant contrast ratios) | | |
| TASK-042 | Create dark theme (optimized for night navigation) | | |
| TASK-043 | Create red light theme (preserve night vision - all red spectrum) | | |
| TASK-044 | Define text styles: displayLarge, headlineMedium, bodyMedium, labelSmall | | |
| TASK-045 | Define spacing constants: padding8/16/24, borderRadius8/16 | | |
| TASK-046 | Implement ThemeProvider with persistence (SharedPreferences) | | |
| TASK-047 | Add auto-switch based on sunset/sunrise calculation | | |
| TASK-048 | Create widget tests: theme switching, persistence, no white flash | | |

### Implementation Phase 7: Base Providers

**GOAL-007**: Set up provider hierarchy to prevent ISS-003 (ProviderNotFoundException)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-049 | Create SettingsProvider (Layer 0): units, language, refreshInterval, gpsUpdateRate | | |
| TASK-050 | Create ThemeProvider (Layer 1, depends on SettingsProvider) | | |
| TASK-051 | Create CacheProvider (Layer 1, depends on SettingsProvider) | | |
| TASK-052 | Document provider dependency graph in CODEBASE_MAP.md (ASCII diagram) | | |
| TASK-053 | Set up MultiProvider in main.dart: Settings → Theme/Cache (correct ordering) | | |
| TASK-054 | Use ChangeNotifierProxyProvider for dependent providers | | |
| TASK-055 | Add integration test: hot reload stability, no ProviderNotFoundException | | |

### Implementation Phase 8: Testing Infrastructure

**GOAL-008**: Establish comprehensive testing framework

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-056 | Create test/ structure: {unit,widget,integration}/{services,providers,models} | | |
| TASK-057 | Set up test fixtures: mock NMEA sentences, sample weather data, test coordinates | | |
| TASK-058 | Configure flutter_test and mockito with build_runner for mock generation | | |
| TASK-059 | Configure lcov code coverage reporting (80% threshold) | | |
| TASK-060 | Create GitHub Actions workflow: analyze, test, upload coverage to codecov | | |
| TASK-061 | Add pre-commit hook: dart format, flutter analyze on changed files | | |
| TASK-062 | Create test documentation: naming conventions, coverage requirements | | |

### Implementation Phase 9: Documentation

**GOAL-009**: Complete all Phase 0 documentation

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-063 | Update CODEBASE_MAP.md with new services, models, providers | | |
| TASK-064 | Document ProjectionService, CacheService, NMEAParser APIs with examples | | |
| TASK-065 | Generate dartdoc: run `dart doc .` | | |
| TASK-066 | Update AI_AGENT_INSTRUCTIONS.md with Phase 0 patterns | | |
| TASK-067 | Create architecture diagram using Mermaid or PlantUML | | |
| TASK-068 | Document testing strategy: unit/widget/integration, coverage targets | | |
| TASK-069 | Create CONTRIBUTING.md: code style, PR process, review checklist | | |

## 3. Alternatives

- **ALT-001**: Use GetX or Riverpod instead of Provider
  - **Rejected**: Provider is officially recommended, simpler learning curve, team has experience

- **ALT-002**: Use Hive instead of SQLite
  - **Rejected**: SQLite better for spatial queries, more mature for maritime data

- **ALT-003**: Use Dio instead of custom RetryableHttpClient
  - **Consideration**: Dio has retry/interceptors, but custom gives better CacheService integration
  - **Decision**: Custom for Phase 0, re-evaluate in Phase 2

- **ALT-004**: Delay isolate for NMEA until performance issue observed
  - **Rejected**: ISS-009 shows this causes critical UI blocking - implement from start

- **ALT-005**: Use mutable models for performance
  - **Rejected**: Immutability prevents ISS-007 state inconsistency bugs

## 4. Dependencies

- **DEP-001**: flutter_sdk >=3.16.0
- **DEP-002**: dart_sdk >=3.2.0
- **DEP-003**: provider ^6.1.0
- **DEP-004**: http ^1.1.0
- **DEP-005**: shared_preferences ^2.2.0
- **DEP-006**: sqflite ^2.3.0
- **DEP-007**: path_provider ^2.1.0
- **DEP-008**: equatable ^2.0.5
- **DEP-009**: flutter_test (SDK) 
- **DEP-010**: mockito ^5.4.0
- **DEP-011**: build_runner ^2.4.0

## 5. Files

### Core Services
- **FILE-001**: lib/services/projection_service.dart - Coordinate transformations (prevent ISS-001)
- **FILE-002**: lib/services/cache_service.dart - LRU cache with TTL (prevent ISS-004)
- **FILE-003**: lib/services/http_client.dart - Retryable HTTP client
- **FILE-004**: lib/services/nmea_parser.dart - NMEA parser with isolate (prevent ISS-009)
- **FILE-005**: lib/services/database_service.dart - SQLite wrapper

### Models
- **FILE-006**: lib/models/lat_lng.dart
- **FILE-007**: lib/models/bounds.dart
- **FILE-008**: lib/models/viewport.dart
- **FILE-009**: lib/models/boat_position.dart
- **FILE-010**: lib/models/weather_data.dart
- **FILE-011**: lib/models/wind_data.dart
- **FILE-012**: lib/models/wave_data.dart
- **FILE-013**: lib/models/nmea_message.dart

### Providers
- **FILE-014**: lib/providers/settings_provider.dart
- **FILE-015**: lib/providers/theme_provider.dart
- **FILE-016**: lib/providers/cache_provider.dart

### Theme
- **FILE-017**: lib/theme/app_theme.dart
- **FILE-018**: lib/theme/colors.dart
- **FILE-019**: lib/theme/text_styles.dart
- **FILE-020**: lib/theme/dimensions.dart

### Configuration
- **FILE-021**: lib/main.dart
- **FILE-022**: pubspec.yaml
- **FILE-023**: analysis_options.yaml
- **FILE-024**: .gitignore
- **FILE-025**: .github/workflows/flutter_ci.yml

## 6. Testing

- **TEST-001**: ProjectionService - 100% coverage, round-trip conversions, edge cases
- **TEST-002**: CacheService - >90% coverage, LRU, TTL, invalidation
- **TEST-003**: RetryableHttpClient - >85% coverage, retry logic, timeouts
- **TEST-004**: NMEAParser - >95% coverage, valid/invalid checksums, high message rate
- **TEST-005**: Models - >85% coverage, validation, serialization
- **TEST-006**: ThemeProvider widget tests - switching, persistence
- **TEST-007**: Provider integration tests - initialization, hot reload stability

## 7. Risks & Assumptions

### Risks

- **RISK-001**: Flutter SDK version incompatibility
  - **Mitigation**: Use fvm to lock SDK version
  - **Severity**: Medium

- **RISK-002**: 300-line limit too restrictive
  - **Mitigation**: Refactor with composition
  - **Severity**: Low

- **RISK-003**: 80% coverage target ambitious
  - **Mitigation**: Start with critical paths, increment
  - **Severity**: Low

- **RISK-004**: Isolate implementation complexity
  - **Mitigation**: Use AI_AGENT_INSTRUCTIONS CP.3 pattern
  - **Severity**: Medium

- **RISK-005**: Provider circular dependencies
  - **Mitigation**: ProxyProvider, document hierarchy, early integration tests
  - **Severity**: High (learned from ISS-002, ISS-003)

### Assumptions

- **ASSUMPTION-001**: Team has Flutter/Dart experience (6+ months)
- **ASSUMPTION-002**: Development environment set up
- **ASSUMPTION-003**: Access to test devices (iOS and Android)
- **ASSUMPTION-004**: GitHub Actions available for CI/CD
- **ASSUMPTION-005**: No major Flutter breaking changes during Phase 0

## 8. Related Specifications / Further Reading

### Internal Documentation (MUST READ)
- [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md) - Section A (Failures), Section C (Architecture Rules)
- [AI_AGENT_INSTRUCTIONS.md](../../docs/AI_AGENT_INSTRUCTIONS.md) - Section B (Working Code), Mandatory Behaviors
- [CODEBASE_MAP.md](../../docs/CODEBASE_MAP.md) - Structure, dependency graph
- [KNOWN_ISSUES_DATABASE.md](../../docs/KNOWN_ISSUES_DATABASE.md) - 18 issues, solutions, prevention
- [FEATURE_REQUIREMENTS.md](../../docs/FEATURE_REQUIREMENTS.md) - Feature specs

### External References
- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [NMEA 0183 Standard](https://www.nmea.org/content/STANDARDS/NMEA_0183_Standard)
- [Web Mercator (EPSG:3857)](https://en.wikipedia.org/wiki/Web_Mercator_projection)

### Critical Issue References
- **ISS-001** (Projection Mismatch): Read before TASK-008 to TASK-014
- **ISS-002** (God Objects): Read before TASK-001 to TASK-007
- **ISS-003** (Provider Chaos): Read before TASK-049 to TASK-055
- **ISS-004** (Stale Cache): Read before TASK-015 to TASK-021
- **ISS-006** (Memory Leaks): Applies to all StatefulWidgets
- **ISS-009** (UI Blocking): Read before TASK-024 to TASK-028

---

**Phase 0 Completion Criteria:**

✅ All 69 tasks completed  
✅ Test coverage ≥80%  
✅ All lint rules passing  
✅ CI/CD pipeline green  
✅ Documentation complete  
✅ Architecture review passed  
✅ Code review by 2+ team members  
✅ Integration tests passing on iOS/Android  

**Estimated Effort:** 80-100 developer hours (2 weeks, 2 developers)

**Next Phase:** [Phase 1: Core Navigation](phase-1-core-navigation.md)