---
goal: Phase 0 Foundation - Setup and Core Architecture
version: 1.0
date_created: 2026-02-01
last_updated: 2026-02-01
owner: Development Team
status: 'Planned'
tags: [foundation, architecture, phase-0, setup, infrastructure]
---

# Phase 0 Foundation - Setup and Core Architecture

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

This implementation plan defines the complete Phase 0 foundation work for the Marine Navigation App, establishing the
base architecture, core services, testing infrastructure, and development standards that will support all subsequent
phases.

## 1. Requirements & Constraints

### Project Requirements

- **REQ-001**: Flutter/Dart development using official best practices from Effective Dart and Flutter Architecture Recommendations (see `.github/instructions/dart-n-flutter.instructions.md`)
- **REQ-002**: Specification-driven workflow as defined in `.github/instructions/spec-driven-workflow-v1.instructions.md`
- **REQ-003**: All code must follow security guidelines from `.github/instructions/security-and-owasp.instructions.md`
- **REQ-004**: Performance optimization standards from `.github/instructions/performance-optimization.instructions.md`
- **REQ-005**: Documentation updates synchronized with code changes per `.github/instructions/update-docs-on-code-change.instructions.md`

### Architecture Constraints (from docs/MASTER_DEVELOPMENT_BIBLE.md Section C)

- **CON-001**: Maximum 300 lines per file to prevent god objects (Rule C.5)
- **CON-002**: Single Source of Truth - no duplicate state (Rule C.1)
- **CON-003**: All coordinate conversions through ProjectionService (Rule C.2)
- **CON-004**: Provider hierarchy must be documented and acyclic (Rule C.3)
- **CON-005**: All network requests require retry + timeout + cache fallback (Rule C.4)
- **CON-006**: All resources must be disposed in dispose() methods (Rule C.10)

### Security Requirements

- **SEC-001**: No hardcoded API keys or secrets in code
- **SEC-002**: All external API calls must validate and sanitize responses
- **SEC-003**: Secure storage for user data and credentials
- **SEC-004**: Input validation for all user-provided data

### Performance Guidelines

- **PER-001**: Map rendering at 60 FPS during pan/zoom operations
- **PER-002**: UI must remain responsive during background data processing
- **PER-003**: Memory leaks prevented through proper disposal
- **PER-004**: Cache size limits enforced (500MB for map tiles)

### Testing Requirements

- **TEST-REQ-001**: Minimum 80% code coverage for all new code
- **TEST-REQ-002**: Unit tests for all services and utilities
- **TEST-REQ-003**: Widget tests for all custom widgets
- **TEST-REQ-004**: Integration tests for critical user flows

### Documentation Guidelines

- **DOC-001**: All public APIs must have dartdoc comments
- **DOC-002**: Update CODEBASE_MAP.md when adding new files/services
- **DOC-003**: Complex logic requires inline comments explaining "why"
- **DOC-004**: Update FEATURE_REQUIREMENTS.md when implementing features

## 2. Implementation Steps

### Implementation Phase 1: Project Initialization

**GOAL-001**: Set up Flutter project with proper structure and dependencies

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-001 | Initialize Flutter project with `flutter create marine_nav_app` using proper package name | | |
| TASK-002 | Configure pubspec.yaml with core dependencies: provider (^6.1.0), http (^1.0.0), shared_preferences (^2.2.0), path_provider (^2.1.0) | | |
| TASK-003 | Set up project directory structure per docs/CODEBASE_MAP.md (lib/models, lib/providers, lib/services, lib/screens, lib/widgets, lib/utils, lib/theme) | | |
| TASK-004 | Create .gitignore with Flutter defaults plus /coverage, /.env, /build | | |
| TASK-005 | Create analysis_options.yaml with strict linting rules from Effective Dart | | |
| TASK-006 | Initialize git repository and create initial commit | | |

### Implementation Phase 2: Core Services Layer

**GOAL-002**: Implement foundational services following architecture rules

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-007 | Implement lib/services/cache_service.dart with LRU eviction, TTL support, and 500MB size limit (max 300 lines, follows CON-001) | | |
| TASK-008 | Implement lib/services/http_client.dart with retry logic (3 attempts), exponential backoff, timeout (30s), follows CON-005 | | |
| TASK-009 | Implement lib/services/projection_service.dart for coordinate transformations between WGS84 (EPSG:4326) and Web Mercator (EPSG:3857), follows CON-003 | | |
| TASK-010 | Implement lib/services/nmea_parser.dart for NMEA 0183 sentence parsing (GPGGA, GPRMC, GPVTG initially) with checksum validation | | |
| TASK-011 | Create lib/services/database_service.dart wrapper for SQLite using sqflite package for local data persistence | | |

### Implementation Phase 3: Data Models

**GOAL-003**: Create immutable data models with proper validation

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-012 | Implement lib/models/lat_lng.dart - immutable coordinate pair with validation (-90 to 90 lat, -180 to 180 lng) | | |
| TASK-013 | Implement lib/models/bounds.dart - geographic bounds with SW/NE corners, includes contains() and intersects() methods | | |
| TASK-014 | Implement lib/models/viewport.dart - map viewport state (center, zoom, bearing, pitch) | | |
| TASK-015 | Implement lib/models/boat_position.dart - GPS position with heading, speed, timestamp | | |
| TASK-016 | Implement lib/models/cache_entry.dart - cache metadata with TTL, LRU timestamp, size | | |
| TASK-017 | Implement lib/models/nmea_message.dart - parsed NMEA sentence base class and specific types (GGA, RMC, VTG) | | |

### Implementation Phase 4: Provider Setup

**GOAL-004**: Establish provider hierarchy with documented dependencies

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-018 | Create lib/providers/settings_provider.dart (Layer 0 - no dependencies) for user preferences, units, language | | |
| TASK-019 | Create lib/providers/theme_provider.dart (Layer 1 - depends on SettingsProvider) for light/dark mode | | |
| TASK-020 | Create lib/providers/cache_provider.dart (Layer 1 - depends on SettingsProvider) coordinating CacheService | | |
| TASK-021 | Document provider dependency graph in docs/CODEBASE_MAP.md following CON-004 | | |
| TASK-022 | Set up all providers in lib/main.dart using MultiProvider with correct hierarchy | | |

### Implementation Phase 5: Theme System

**GOAL-005**: Implement Marine color palette and responsive theme

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-023 | Create lib/theme/colors.dart with Marine palette (ocean blues, coral accents, neutral grays) | | |
| TASK-024 | Create lib/theme/text_styles.dart with Roboto font family, scale from 12sp to 32sp | | |
| TASK-025 | Create lib/theme/dimensions.dart with spacing scale (4, 8, 16, 24, 32, 48) | | |
| TASK-026 | Implement lib/theme/app_theme.dart with light and dark ThemeData configurations | | |
| TASK-027 | Wire theme to ThemeProvider in main.dart with MaterialApp | | |

### Implementation Phase 6: Testing Infrastructure

**GOAL-006**: Set up comprehensive testing framework

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-028 | Configure test/test_helpers.dart with common test utilities and mocks | | |
| TASK-029 | Write test/unit/services/cache_service_test.dart covering LRU eviction, TTL expiry, size limits | | |
| TASK-030 | Write test/unit/services/http_client_test.dart covering retry logic, timeouts, error handling | | |
| TASK-031 | Write test/unit/services/projection_service_test.dart covering coordinate transformations accuracy | | |
| TASK-032 | Write test/unit/services/nmea_parser_test.dart covering valid/invalid sentences, checksum validation | | |
| TASK-033 | Set up flutter_test integration and configure coverage reporting with lcov | | |

### Implementation Phase 7: CI/CD Pipeline

**GOAL-007**: Automate testing, linting, and builds

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-034 | Create .github/workflows/test.yml for automated testing on push/PR | | |
| TASK-035 | Create .github/workflows/lint.yml for dart analyze and flutter format checks | | |
| TASK-036 | Create .github/workflows/build.yml for Android and iOS build verification | | |
| TASK-037 | Configure codecov or similar for coverage reporting | | |
| TASK-038 | Add status badges to README.md | | |

### Implementation Phase 8: Documentation

**GOAL-008**: Complete Phase 0 documentation

| Task | Description | Completed | Date |
| ------ | ------------- | ----------- | ------ |
| TASK-039 | Update docs/CODEBASE_MAP.md with all implemented services, models, providers | | |
| TASK-040 | Document setup instructions in project README.md | | |
| TASK-041 | Create docs/SETUP_GUIDE.md with detailed environment setup steps | | |
| TASK-042 | Update docs/AI_AGENT_INSTRUCTIONS.md if new patterns established | | |
| TASK-043 | Add dartdoc comments to all public APIs (minimum requirement per DOC-001) | | |

## 3. Alternatives

- **ALT-001**: Use BLoC pattern instead of Provider - Rejected due to additional complexity and team unfamiliarity; Provider is officially recommended by Flutter team
- **ALT-002**: Use GetX for state management - Rejected due to violation of Flutter best practices and reliance on global state
- **ALT-003**: Use REST API wrapper packages (dio, retrofit) - Rejected in favor of minimal http package to maintain control and reduce dependencies
- **ALT-004**: Use code generation for models (freezed, json_serializable) - Deferred to Phase 2 when JSON parsing needs become clear
- **ALT-005**: Use Flutter's built-in test framework without additional tooling - Accepted; will add integration test tools if needed in later phases

## 4. Dependencies

### Flutter/Dart Dependencies (pubspec.yaml)

- **DEP-001**: flutter SDK (stable channel, >=3.19.0)
- **DEP-002**: provider (^6.1.0) - State management
- **DEP-003**: http (^1.0.0) - Network requests
- **DEP-004**: shared_preferences (^2.2.0) - Key-value storage
- **DEP-005**: path_provider (^2.1.0) - File system paths
- **DEP-006**: sqflite (^2.3.0) - SQLite database
- **DEP-007**: flutter_test (SDK) - Testing framework
- **DEP-008**: flutter_lints (^3.0.0) - Linting rules
- **DEP-009**: mockito (^5.4.0) - Mocking framework for tests
- **DEP-010**: build_runner (^2.4.0) - Code generation (if needed)

### External Resources

- **DEP-011**: MapTiler API (for Phase 1) - Map tile provider
- **DEP-012**: Open-Meteo API (for Phase 2) - Weather data
- **DEP-013**: NOAA API (for Phase 3) - Tides and buoys data

### Documentation References

- **DEP-014**: docs/MASTER_DEVELOPMENT_BIBLE.md - Architecture rules and failure analysis
- **DEP-015**: docs/AI_AGENT_INSTRUCTIONS.md - Development guidelines
- **DEP-016**: docs/CODEBASE_MAP.md - Project structure
- **DEP-017**: .github/instructions/dart-n-flutter.instructions.md - Flutter best practices

## 5. Files

See full file list in detailed specification document: `.copilot-tracking/details/phase-0-foundation-details-1.md`

## 6. Testing

### Unit Tests

- **TEST-001**: CacheService LRU eviction - Verify oldest entries removed when limit reached
- **TEST-002**: CacheService TTL expiry - Verify expired entries not returned
- **TEST-003**: HttpClient retry logic - Verify 3 retry attempts with exponential backoff
- **TEST-004**: HttpClient timeout - Verify 30s timeout enforced
- **TEST-005**: ProjectionService WGS84 to Web Mercator - Verify coordinate transformation accuracy
- **TEST-006**: ProjectionService Web Mercator to WGS84 - Verify reverse transformation accuracy
- **TEST-007**: NMEAParser checksum validation - Verify valid checksums accepted, invalid rejected
- **TEST-008**: NMEAParser GPGGA parsing - Verify position, time, quality extracted correctly
- **TEST-009**: NMEAParser GPRMC parsing - Verify position, speed, course extracted
- **TEST-010**: SettingsProvider state changes - Verify notifyListeners() called on updates
- **TEST-011**: ThemeProvider dark mode toggle - Verify theme switches correctly

### Coverage Requirements

- **TEST-012**: Minimum 80% coverage for services layer
- **TEST-013**: Minimum 80% coverage for models layer
- **TEST-014**: Minimum 70% coverage for providers layer

## 7. Risks & Assumptions

### Risks

- **RISK-001**: Coordinate projection accuracy - Projection transformations may have precision errors at extreme zoom
levels. Mitigation: Extensive unit testing with known coordinates, compare against reference implementations
- **RISK-002**: NMEA parser compatibility - Different NMEA devices may have non-standard sentence formats. Mitigation: Defensive parsing, extensive logging, graceful handling of unknown sentences
- **RISK-003**: Cache eviction edge cases - LRU eviction during concurrent access may cause race conditions. Mitigation: Mutex/lock protection for cache operations, thorough concurrent testing
- **RISK-004**: Provider dependency cycles - Complex provider dependencies could create circular references.
Mitigation: Document and enforce strict layered architecture, automated dependency graph validation
- **RISK-005**: Memory leaks - Improper disposal of resources could cause memory growth. Mitigation: Mandatory dispose() implementation, memory profiling in CI

### Assumptions

- **ASSUMPTION-001**: Flutter stable channel provides sufficient features; beta/dev channels not required
- **ASSUMPTION-002**: MapTiler and Open-Meteo APIs will remain available and free for development/testing
- **ASSUMPTION-003**: Target devices are modern smartphones (iOS 12+, Android 6.0+) with adequate performance
- **ASSUMPTION-004**: Users have internet connectivity for initial setup; offline mode added in Phase 2
- **ASSUMPTION-005**: NMEA devices follow NMEA 0183 standard; proprietary formats addressed as discovered
- **ASSUMPTION-006**: Team members have basic Flutter/Dart experience; advanced patterns explained in code comments

## 8. Related Specifications / Further Reading

### Internal Documentation

- [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md) - Complete failure analysis and architecture rules
- [AI_AGENT_INSTRUCTIONS.md](../../docs/AI_AGENT_INSTRUCTIONS.md) - Mandatory development behaviors
- [CODEBASE_MAP.md](../../docs/CODEBASE_MAP.md) - Project structure and dependencies
- [FEATURE_REQUIREMENTS.md](../../docs/FEATURE_REQUIREMENTS.md) - Detailed feature specifications
- [Phase 0 Detailed Specification](../details/phase-0-foundation-details-1.md) - Complete technical details

### Copilot Bundle Resources

#### Agents
- [implementation-plan.agent.md](../../.github/agents/implementation-plan.agent.md) - Generate implementation plans
- [specification.agent.md](../../.github/agents/specification.agent.md) - Create technical specifications
- [se-security-reviewer.agent.md](../../.github/agents/se-security-reviewer.agent.md) - Security review
- [se-system-architecture-reviewer.agent.md](../../.github/agents/se-system-architecture-reviewer.agent.md) - Architecture review

#### Instructions
- [dart-n-flutter.instructions.md](../../.github/instructions/dart-n-flutter.instructions.md) - Effective Dart and Flutter best practices
- [spec-driven-workflow-v1.instructions.md](../../.github/instructions/spec-driven-workflow-v1.instructions.md) - Specification-driven development
- [security-and-owasp.instructions.md](../../.github/instructions/security-and-owasp.instructions.md) - Security guidelines
- [performance-optimization.instructions.md](../../.github/instructions/performance-optimization.instructions.md) - Performance best practices

#### Prompts
- [create-specification.prompt.md](../../.github/prompts/create-specification.prompt.md) - Generate specifications
- [breakdown-feature-implementation.prompt.md](../../.github/prompts/breakdown-feature-implementation.prompt.md) - Task breakdown

### External References

- [Effective Dart](https://dart.dev/effective-dart) - Official Dart style guide
- [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture/recommendations) - Official architecture recommendations
- [Provider Package](https://pub.dev/packages/provider) - State management documentation
- [NMEA 0183 Standard](https://www.nmea.org) - NMEA protocol specification
