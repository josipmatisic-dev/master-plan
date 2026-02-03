---
description: "Execute Phase 0 Foundation implementation for Marine Navigation App"
instructions: "Follow this prompt to implement the Phase 0 foundation work with all quality standards"
---

# Execute Phase 0 Foundation Implementation

## Context

You are implementing Phase 0 Foundation for the Marine Navigation App, a Flutter/Dart application for yacht navigation.
This phase establishes the core architecture, services, and testing infrastructure that all subsequent phases will build
upon.

**Critical:** This project has failed 4 times previously due to god objects, circular dependencies, and projection
mismatches. The architecture rules in `docs/MASTER_DEVELOPMENT_BIBLE.md` are MANDATORY.

## Your Mission

Implement all tasks in the Phase 0 implementation plan following strict architectural guidelines, security best practices, performance standards, and comprehensive testing requirements.

## Required Reading (BEFORE YOU START)

Read these documents in order to understand context and constraints:

1. **docs/MASTER_DEVELOPMENT_BIBLE.md** - Section A (Failure Analysis) and Section C (Architecture Rules)
2. **.copilot-tracking/plans/phase-0-foundation-1.md** - Complete implementation plan
3. **.copilot-tracking/details/phase-0-foundation-details-1.md** - Detailed technical specifications
4. **.github/instructions/dart-n-flutter.instructions.md** - Flutter/Dart best practices
5. **.github/instructions/spec-driven-workflow-v1.instructions.md** - Development workflow

## Mandatory Architecture Rules

These rules from `docs/MASTER_DEVELOPMENT_BIBLE.md` Section C are NON-NEGOTIABLE:

- **C.1**: Single Source of Truth - No duplicate state
- **C.2**: All coordinate conversions through ProjectionService
- **C.3**: Provider hierarchy documented and acyclic
- **C.4**: Network requests require retry + timeout + cache fallback
- **C.5**: Maximum 300 lines per file
- **C.10**: Dispose everything in dispose() methods

## Quality Standards

### Code Quality (from .github/instructions/dart-n-flutter.instructions.md)

- Follow Effective Dart style guide
- Use `lowerCamelCase` for variables, methods
- Use `UpperCamelCase` for classes, types
- Maximum 80 characters per line (prefer, not strict)
- Use `///` for doc comments on public APIs
- Write tests FIRST (TDD approach)

### Security (from .github/instructions/security-and-owasp.instructions.md)

- No hardcoded secrets or API keys
- All user input validated
- All API responses validated
- Use HTTPS only
- Sanitize error messages

### Performance (from .github/instructions/performance-optimization.instructions.md)

- Minimize widget rebuilds
- Use const constructors where possible
- Dispose resources properly
- Profile memory usage
- Cache appropriately

### Testing

- 80% code coverage minimum for services and models
- Unit tests for all services
- Widget tests for all providers
- Integration test for app initialization
- Test edge cases and error conditions

## Implementation Workflow

### Phase 1: Project Initialization (TASK-001 to TASK-006)

**Step 1.1**: Initialize Flutter Project
```bash
flutter create marine_nav_app --org com.marinenavc --platforms ios,android
cd marine_nav_app
```text

**Step 1.2**: Configure pubspec.yaml

Add dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.0
  http: ^1.0.0
  shared_preferences: ^2.2.0
  path_provider: ^2.1.0
  sqflite: ^2.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0
```text

**Step 1.3**: Create Directory Structure

```bash
mkdir -p lib/{models,providers,services,screens,widgets,utils,theme}
mkdir -p test/{unit/{services,models,utils},widget,integration}
mkdir -p assets/{images,fonts}
```text

**Step 1.4**: Create analysis_options.yaml

Use strict linting from Effective Dart:
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - prefer_single_quotes
    - sort_child_properties_last
```text

**Step 1.5**: Create .gitignore

Include Flutter defaults plus:
```text
/coverage
/.env
/build
*.iml
.DS_Store
```text

**Step 1.6**: Initialize Git

```bash
git init
git add .
git commit -m "Initial Flutter project setup"
```text

### Phase 2: Core Services Layer (TASK-007 to TASK-011)

**Step 2.1**: Implement CacheService (TASK-007)

File: `lib/services/cache_service.dart`

Requirements:
- LRU eviction with 500MB limit
- TTL support for automatic expiry
- Thread-safe operations
- JSON serialization
- Under 300 lines

See detailed spec in `.copilot-tracking/details/phase-0-foundation-details-1.md` Section "CacheService"

**Step 2.2**: Write CacheService Tests (TASK-029)

File: `test/unit/services/cache_service_test.dart`

Tests:
- LRU eviction when limit reached
- TTL expiry (put with 1s TTL, wait 2s, verify null)
- Size limit enforcement
- Concurrent access safety

**Step 2.3**: Implement HttpClient (TASK-008)

File: `lib/services/http_client.dart`

Requirements:
- 3 retry attempts with exponential backoff
- 30 second timeout
- Status code validation
- JSON parsing
- Under 300 lines

See detailed spec in `.copilot-tracking/details/phase-0-foundation-details-1.md` Section "HttpClient"

**Step 2.4**: Write HttpClient Tests (TASK-030)

File: `test/unit/services/http_client_test.dart`

Tests:
- Successful request with 200 response
- Retry on network timeout
- No retry on 404 error
- Timeout after 30 seconds
- JSON parsing

**Step 2.5**: Implement ProjectionService (TASK-009)

File: `lib/services/projection_service.dart`

Requirements:
- WGS84 ↔ Web Mercator transformations
- Screen coordinate transformations
- Accuracy < 0.0001 degrees
- Handle edge cases (poles, dateline)
- Under 300 lines

See detailed spec in `.copilot-tracking/details/phase-0-foundation-details-1.md` Section "ProjectionService"

**Step 2.6**: Write ProjectionService Tests (TASK-031)

File: `test/unit/services/projection_service_test.dart`

Tests:
- Known coordinates transformation accuracy
- Round-trip conversion
- Pole handling
- Dateline crossing
- Screen coordinate transformation

**Step 2.7**: Implement NMEAParser (TASK-010)

File: `lib/services/nmea_parser.dart`

Requirements:
- Support GPGGA, GPRMC, GPVTG
- Checksum validation
- Handle malformed sentences
- Parse 100+ sentences/second
- Under 300 lines

See detailed spec in `.copilot-tracking/details/phase-0-foundation-details-1.md` Section "NMEAParser"

**Step 2.8**: Write NMEAParser Tests (TASK-032)

File: `test/unit/services/nmea_parser_test.dart`

Tests:
- Valid GPGGA sentence
- Invalid checksum rejected
- Malformed sentence handling
- Unknown sentence type
- Coordinate conversion accuracy

**Step 2.9**: Implement DatabaseService (TASK-011)

File: `lib/services/database_service.dart`

Basic SQLite wrapper using sqflite package

### Phase 3: Data Models (TASK-012 to TASK-017)

Implement immutable data models with:
- Final fields
- Validation in constructor
- Equality (override ==, hashCode)
- JSON serialization (toJson, fromJson)
- dartdoc comments

Models to create:
1. LatLng - coordinate pair with validation
2. Bounds - geographic bounding box
3. Viewport - map viewport state
4. BoatPosition - GPS position with heading/speed
5. CacheEntry - cache metadata
6. NMEAMessage - parsed NMEA data

See detailed specs in `.copilot-tracking/details/phase-0-foundation-details-1.md` Section "Data Model Specifications"

### Phase 4: Provider Setup (TASK-018 to TASK-022)

**Provider Dependency Layers:**

```text
Layer 0: SettingsProvider (no dependencies)
Layer 1: ThemeProvider, CacheProvider (depend on SettingsProvider)
```text

**Step 4.1**: Implement SettingsProvider (TASK-018)

File: `lib/providers/settings_provider.dart`

- Use shared_preferences for persistence
- Notify listeners on changes
- Load on app start

**Step 4.2**: Implement ThemeProvider (TASK-019)

File: `lib/providers/theme_provider.dart`

- Depends on SettingsProvider
- Support light/dark mode toggle
- Provide ThemeData for MaterialApp

**Step 4.3**: Implement CacheProvider (TASK-020)

File: `lib/providers/cache_provider.dart`

- Coordinates CacheService
- Depends on SettingsProvider

**Step 4.4**: Document Provider Graph (TASK-021)

Update `docs/CODEBASE_MAP.md` with dependency diagram

**Step 4.5**: Wire Providers in main.dart (TASK-022)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    MultiProvider(
      providers: [
        // Layer 0
        ChangeNotifierProvider(create: (_) => SettingsProvider()..loadSettings()),
        // Layer 1
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(context.read<SettingsProvider>()),
        ),
        ChangeNotifierProvider(
          create: (context) => CacheProvider(context.read<SettingsProvider>()),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```text

### Phase 5: Theme System (TASK-023 to TASK-027)

Create theme files:
1. `lib/theme/colors.dart` - Marine color palette
2. `lib/theme/text_styles.dart` - Typography
3. `lib/theme/dimensions.dart` - Spacing/sizing
4. `lib/theme/app_theme.dart` - ThemeData configuration

Wire to app:
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) => MaterialApp(
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        themeMode: theme.themeMode,
        home: HomeScreen(),
      ),
    );
  }
}
```text

### Phase 6: Testing Infrastructure (TASK-028 to TASK-033)

**Step 6.1**: Create test helpers (TASK-028)

File: `test/test_helpers.dart`

Mock providers and services for testing

**Step 6.2**: Run all tests (TASK-033)

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```text

Verify 80%+ coverage for services and models

### Phase 7: CI/CD Pipeline (TASK-034 to TASK-038)

**Step 7.1**: Create .github/workflows/test.yml (TASK-034)

```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
```text

**Step 7.2**: Create lint workflow (TASK-035)

**Step 7.3**: Create build workflow (TASK-036)

**Step 7.4**: Configure codecov (TASK-037)

**Step 7.5**: Add badges to README (TASK-038)

### Phase 8: Documentation (TASK-039 to TASK-043)

**Step 8.1**: Update docs/CODEBASE_MAP.md (TASK-039)

Add all new services, models, providers with descriptions

**Step 8.2**: Update README.md (TASK-040)

Add setup instructions, architecture overview, badges

**Step 8.3**: Create docs/SETUP_GUIDE.md (TASK-041)

Detailed environment setup instructions

**Step 8.4**: Update docs/AI_AGENT_INSTRUCTIONS.md (TASK-042)

Add any new patterns or rules established

**Step 8.5**: Add dartdoc comments (TASK-043)

All public APIs must have /// comments

## Validation Checklist

Before considering Phase 0 complete, verify:

- [ ] All 43 tasks completed
- [ ] Zero files over 300 lines
- [ ] 80%+ test coverage for services and models
- [ ] All tests passing
- [ ] CI/CD pipeline green
- [ ] No hardcoded secrets
- [ ] Provider dependency graph documented
- [ ] All public APIs have dartdoc comments
- [ ] Memory profiling shows no leaks
- [ ] flutter analyze shows 0 issues
- [ ] flutter format applied to all files

## Getting Help

If you encounter issues:

1. Check `docs/KNOWN_ISSUES_DATABASE.md` for similar problems
2. Review relevant section in `docs/MASTER_DEVELOPMENT_BIBLE.md`
3. Consult Copilot bundle resources:
   - `.github/agents/se-security-reviewer.agent.md` for security questions
   - `.github/agents/se-system-architecture-reviewer.agent.md` for architecture questions
   - `.github/instructions/dart-n-flutter.instructions.md` for Flutter best practices

## Success Metrics

Phase 0 is successful when:

1. ✅ Flutter project initialized with correct structure
2. ✅ All 5 core services implemented and tested (80%+ coverage)
3. ✅ All 6 data models implemented with validation
4. ✅ Provider hierarchy established (Layer 0 and Layer 1)
5. ✅ Theme system complete with light/dark mode
6. ✅ CI/CD pipeline running successfully
7. ✅ Documentation complete and up-to-date
8. ✅ Zero architectural violations (file size, circular deps, etc.)
9. ✅ Zero security issues (no hardcoded secrets)
10. ✅ Performance benchmarks met (see detailed spec)

## Next Steps After Phase 0

Once Phase 0 is complete:

1. Review with team/stakeholders
2. Run security scan with `.github/agents/se-security-reviewer.agent.md`
3. Architecture review with `.github/agents/se-system-architecture-reviewer.agent.md`
4. Proceed to Phase 1: Core Navigation (map display, GPS tracking)

## References

- [Implementation Plan](../plans/phase-0-foundation-1.md)
- [Detailed Specification](../details/phase-0-foundation-details-1.md)
- [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md)
- [AI_AGENT_INSTRUCTIONS.md](../../docs/AI_AGENT_INSTRUCTIONS.md)
- [Effective Dart](https://dart.dev/effective-dart)
- [Flutter Architecture Guide](https://docs.flutter.dev/app-architecture/recommendations)
