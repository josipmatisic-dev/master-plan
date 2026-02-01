# GitHub Copilot Instructions - Marine Navigation App

## Project Overview

This repository contains **master planning documentation** for a Marine Navigation App built with Flutter/Dart. This is a **yacht navigation application** that has been through 4 failed development attempts, with extensive lessons learned documented for future development success.

**Purpose:** Master planning repository documenting architecture, failures, requirements, and best practices for building a production-ready marine navigation app.

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Mapping:** MapTiler SDK (Web Mercator EPSG:3857)
- **Weather Data:** Open-Meteo API (WGS84 EPSG:4326)
- **Navigation Data:** NMEA protocol parsing
- **State Management:** Provider pattern
- **Testing:** Flutter test framework (80% minimum coverage required)

## Critical Documentation

Before making ANY changes, you MUST read these files in order:

1. **[docs/MASTER_DEVELOPMENT_BIBLE.md](docs/MASTER_DEVELOPMENT_BIBLE.md)** (16 KB)
   - Complete failure analysis from 4 previous attempts
   - Architecture rules (Section C) - ALL MANDATORY
   - Working code inventory (Section B) - Reuse proven patterns
   - Technical decisions and development phases

2. **[docs/AI_AGENT_INSTRUCTIONS.md](docs/AI_AGENT_INSTRUCTIONS.md)** (18 KB)
   - Mandatory behaviors for AI agents
   - Forbidden actions and anti-patterns
   - Code patterns and testing requirements

3. **[docs/KNOWN_ISSUES_DATABASE.md](docs/KNOWN_ISSUES_DATABASE.md)** (26 KB)
   - 18 documented issues with root causes and solutions
   - Check here BEFORE implementing similar functionality

4. **[docs/CODEBASE_MAP.md](docs/CODEBASE_MAP.md)** (18 KB)
   - Project structure and component organization
   - Dependency graphs and service relationships

5. **[docs/FEATURE_REQUIREMENTS.md](docs/FEATURE_REQUIREMENTS.md)** (19 KB)
   - Detailed specifications for 14 features
   - User stories and acceptance criteria

## Architecture Rules (MANDATORY)

All rules from MASTER_DEVELOPMENT_BIBLE.md Section C are MANDATORY with NO EXCEPTIONS:

### C.1 Single Source of Truth
- No duplicate state across providers
- One authoritative data source per domain

### C.2 Projection Consistency
- **ALL coordinate conversions MUST go through ProjectionService**
- Never convert lat/lng to screen coordinates directly
- MapTiler uses Web Mercator (EPSG:3857), weather data uses WGS84 (EPSG:4326)

### C.3 Provider Discipline
- Document provider hierarchy in `main.dart`
- NO circular dependencies between providers
- Dependencies flow in ONE direction only

### C.4 Network Resilience
- Every API call MUST have: retry logic + timeout + cache fallback
- Handle offline mode gracefully

### C.5 File Size Limits
- **Maximum 300 lines per file**
- **Maximum 300 lines per controller/provider**
- Split large classes by responsibility

### C.10 Dispose Everything
- All controllers/streams/timers MUST be disposed
- No memory leaks - verify with Flutter DevTools

## Coding Standards

### Flutter/Dart Conventions
Follow all guidelines from `.github/instructions/dart-n-flutter.instructions.md`:
- Use `UpperCamelCase` for types and extensions
- Use `lowerCamelCase` for variables, methods, and constants
- Use `lowercase_with_underscores` for packages and files
- Format code with `dart format`
- Maximum line length: 80 characters

### MVVM Architecture
- **Views** (Screens/Widgets): UI only, minimal logic
- **ViewModels** (ChangeNotifiers): Business logic and state
- **Services**: Data fetching, API calls, external integrations
- **Repositories**: Data access abstraction layer

### Naming Conventions
```dart
// Controllers/ViewModels
class HomeViewModel extends ChangeNotifier { }

// Views/Screens
class HomeScreen extends StatelessWidget { }

// Services
class WeatherApiService { }

// Repositories
abstract class UserRepository { }
```

## Common Patterns (From Working Code)

### Pattern 1: Coordinate Projection
```dart
// CORRECT: Always use ProjectionService
class ProjectionService {
  LatLng screenToLatLng(Offset screenPoint) {
    // Transform considering map state
  }
  
  Offset latLngToScreen(LatLng position) {
    // Transform considering zoom, pan, rotation
  }
}

// WRONG: Never do direct conversion
// BAD: left: (lng + 180) * screenWidth / 360
```

### Pattern 2: Provider Setup
```dart
// CORRECT: Document provider hierarchy
void main() {
  runApp(
    MultiProvider(
      providers: [
        // Level 1: No dependencies
        Provider(create: (_) => ApiService()),
        
        // Level 2: Depends on Level 1
        ProxyProvider<ApiService, WeatherRepository>(
          update: (_, api, __) => WeatherRepositoryImpl(api),
        ),
        
        // Level 3: Depends on Level 2
        ChangeNotifierProxyProvider<WeatherRepository, MapViewModel>(
          create: (_) => MapViewModel(),
          update: (_, repo, vm) => vm!..setRepository(repo),
        ),
      ],
      child: MyApp(),
    ),
  );
}
```

### Pattern 3: Network Calls with Resilience
```dart
// CORRECT: Retry + timeout + cache fallback (including network unavailability)
Future<WeatherData> fetchWeather(LatLng position) async {
  try {
    return await RetryableHttpClient
        .getWithRetry(
          () => _api.getWeather(position),
          maxAttempts: 3,
          retryOn: (e) => e is SocketException,
        )
        .timeout(const Duration(seconds: 10));
  } on TimeoutException catch (_) {
    // Network call timed out after retries - fallback to cache
    return _cache.getWeather(position);
  } on SocketException catch (_) {
    // Network unavailable after retries - fallback to cache
    return _cache.getWeather(position);
  }
}
```

### Pattern 4: Proper Disposal
```dart
class MapViewModel extends ChangeNotifier {
  StreamSubscription? _locationSub;
  Timer? _updateTimer;
  
  @override
  void dispose() {
    _locationSub?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }
}
```

## Forbidden Actions

From AI_AGENT_INSTRUCTIONS.md Section FA (Forbidden Actions):

### FA.1 God Objects
❌ **NEVER** create classes over 300 lines
❌ **NEVER** have a controller manage multiple unrelated concerns
✅ **DO** split by responsibility (SRP)

### Forbidden: Direct Coordinate Conversion
❌ **NEVER** convert lat/lng to pixels directly
❌ **NEVER** use separate projection logic
✅ **DO** always use ProjectionService

### Forbidden: Rewriting Working Code
❌ **NEVER** rewrite Section B code "your way"
❌ **NEVER** introduce new patterns for solved problems
✅ **DO** extend and reuse proven implementations

### Forbidden: Skipping Tests
❌ **NEVER** submit code without tests
❌ **NEVER** accept coverage below 80%
✅ **DO** write tests first (TDD)

### Forbidden: Ignoring Known Issues
❌ **NEVER** implement without checking KNOWN_ISSUES_DATABASE.md
❌ **NEVER** repeat documented mistakes
✅ **DO** learn from past failures

## Testing Requirements

All new code MUST have:
- **Unit tests** for services, repositories, and ViewModels
- **Widget tests** for Views/Screens
- **Minimum 80% code coverage**
- **Test-Driven Development (TDD)** approach:
  1. Write failing test
  2. Implement minimum code to pass
  3. Refactor while tests pass
  4. Add integration tests

## Documentation Updates

Every code change REQUIRES updating:
- `docs/CODEBASE_MAP.md` - If adding new files/services
- `docs/KNOWN_ISSUES_DATABASE.md` - If fixing documented issues
- `docs/FEATURE_REQUIREMENTS.md` - If implementing/changing features
- Code comments - For complex logic (WHY, not WHAT)

## Security Guidelines

Follow `.github/instructions/security-and-owasp.instructions.md`:
- Never hardcode API keys or secrets
- Use environment variables or secure storage
- Validate all user inputs
- Sanitize data before display (prevent XSS)
- Use HTTPS for all network calls
- Implement proper error handling without exposing sensitive info

## Performance Guidelines

Follow `.github/instructions/performance-optimization.instructions.md`:
- Minimize unnecessary widget rebuilds, layout passes, and repaints
- Use `const` constructors where possible
- Lazy load heavy resources
- Cache expensive computations
- Profile with Flutter DevTools before optimizing
- Optimize for 60 FPS on mobile devices

## Workflow

Follow `.github/instructions/spec-driven-workflow-v1.instructions.md`:

1. **ANALYZE** - Understand requirements, check documentation
2. **DESIGN** - Create technical design, implementation plan
3. **IMPLEMENT** - Code in small increments, follow patterns
4. **VALIDATE** - Run tests, verify changes
5. **REFLECT** - Refactor, update docs
6. **HANDOFF** - Create PR with summary

## Planning & Task Management

This repository uses structured planning:
- **[PLANNING_GUIDE.md](PLANNING_GUIDE.md)** - Complete guide to planning workflows
- **`.copilot-tracking/`** - Task-based planning with research validation
- **`/plan/`** - Formal implementation plan specifications

## Key Principles

1. **Learn from failures** - Read the Bible, avoid repeated mistakes
2. **Reuse proven code** - Section B contains battle-tested patterns
3. **Stay small and focused** - 300 lines max, single responsibility
4. **Test everything** - 80% minimum coverage, TDD approach
5. **Document changes** - Keep docs in sync with code
6. **No circular dependencies** - One-way data flow only
7. **Dispose properly** - No memory leaks
8. **Network resilience** - Retry, timeout, cache fallback
9. **Coordinate consistency** - Always use ProjectionService

## Error Handling

All code must handle errors gracefully:
```dart
// Good error handling
try {
  final data = await fetchData();
  return Success(data);
} on NetworkException catch (e) {
  return Failure('Network error: ${e.message}');
} on CacheException catch (e) {
  return Failure('Cache error: ${e.message}');
} catch (e, stack) {
  logger.error('Unexpected error', error: e, stackTrace: stack);
  return Failure('An unexpected error occurred');
}
```

## Resources

- **Custom Agents:** Available in `.github/agents/` for specialized tasks
- **Instructions:** Language/workflow-specific in `.github/instructions/`
- **Prompts:** Reusable prompts in `.github/prompts/`
- **Full Documentation:** See `docs/README.md` for navigation

## Quick Reference

| When you need... | Read this file... |
|-----------------|------------------|
| Failure analysis | `docs/MASTER_DEVELOPMENT_BIBLE.md` Section A |
| Working patterns | `docs/MASTER_DEVELOPMENT_BIBLE.md` Section B |
| Architecture rules | `docs/MASTER_DEVELOPMENT_BIBLE.md` Section C |
| Known issues | `docs/KNOWN_ISSUES_DATABASE.md` |
| Feature specs | `docs/FEATURE_REQUIREMENTS.md` |
| Project structure | `docs/CODEBASE_MAP.md` |
| AI agent rules | `docs/AI_AGENT_INSTRUCTIONS.md` |

---

**Remember:** This project has failed 4 times. The documentation exists to prevent failure #5. Read it, follow it, and build it right.
