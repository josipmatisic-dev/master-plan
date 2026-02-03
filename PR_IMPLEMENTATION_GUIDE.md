# PR Implementation Guide - Using Custom Agents

**Date:** 2025-02-03  
**Purpose:** Guide for implementing the next 5 PRs using the most appropriate custom agents

This guide maps each PR to the best-suited custom agent(s) from `.github/agents/` and provides specific prompts for each task.

---

## Overview of Available Custom Agents

| Agent | Best For | Key Strengths |
|-------|----------|---------------|
| `blueprint-mode-codex` | Architecture, Core Features | Strict correctness, minimal tool usage, structured workflows |
| `expert-react-frontend-engineer` | UI Components | Modern patterns, performance, TypeScript/strong typing |
| `principal-software-engineer` | Technical Leadership | Engineering excellence, pragmatic decisions, testing strategy |
| `se-technical-writer` | Documentation | Developer docs, technical accuracy, clarity |
| `se-security-reviewer` | Security Analysis | OWASP, vulnerabilities, input validation |
| `janitor` | Code Cleanup | Tech debt, simplification, refactoring |
| `gpt-5-beast-mode` | Complex Problems | Autonomous problem-solving, research, iteration |

---

## PR #1: Complete MapWebView Integration

**Branch:** `feature/map-webview-integration`  
**Estimated Effort:** 2 days  
**Priority:** HIGH

### Recommended Agent: `blueprint-mode-codex`

**Why:** This is core architecture work requiring strict correctness and adherence to architectural rules. The agent's minimal tool usage and structured workflow approach is ideal for WebView/JS bridge work.

### Implementation Prompt

```
Task: Complete MapWebView integration for FEAT-001 per NEXT_STEPS.md PR#1.

Context:
- Read docs/MASTER_DEVELOPMENT_BIBLE.md Section A (especially ISS-008 WebView Sync Lag)
- Read docs/AI_AGENT_INSTRUCTIONS.md
- Current state: lib/widgets/map/map_webview.dart exists but JS bridge not fully wired

Requirements from requirements.md FEAT-001:
1. Implement bi-directional JavaScript bridge for viewport sync
2. Add debouncing (200ms) to prevent message queue backup per ISS-008 solution
3. Wire MapProvider to WebView viewport state updates
4. Add map control methods: setCenter, setZoom, flyTo
5. Add MapTiler API key configuration in SettingsProvider
6. Test on all platforms (Android, iOS, Web)

Files to modify:
- lib/widgets/map/map_webview.dart (~200 lines target)
- lib/providers/map_provider.dart (viewport sync)
- assets/map.html (MapTiler GL JS setup if missing)
- lib/providers/settings_provider.dart (add mapTilerApiKey field)

Architecture constraints:
- All viewport updates MUST flow through MapProvider (single source of truth)
- Debounce JS messages at 200ms (use requestAnimationFrame)
- Validate all messages from WebView (type checking, bounds validation)
- Graceful fallback when WebView unavailable (widget tests)
- Keep files under 300 lines per Architecture Rule C.5

Testing required:
- Integration test: map loads and viewport changes propagate to MapProvider
- Widget test: WebView renders without errors
- Unit test: message validation logic

Before starting:
1. Verify current MapWebView implementation
2. Check if assets/map.html exists and what MapTiler setup it has
3. Review ISS-008 solution in KNOWN_ISSUES_DATABASE.md

Definition of done:
- Map renders MapTiler tiles
- Pan/zoom/rotate work smoothly at 60 FPS
- Viewport state syncs to MapProvider within 200ms
- MapTiler API key configurable in Settings
- All tests passing
- Documentation updated (CODEBASE_MAP.md)
```

### Testing Agent: `principal-software-engineer`

After implementation, use this agent to review testing strategy:

```
Review the testing strategy for MapWebView integration.

Verify:
1. Integration tests cover viewport sync edge cases
2. Widget tests handle WebView unavailable scenario
3. Performance tests validate 60 FPS rendering
4. Message validation prevents malformed data from JS bridge

Recommend additional tests if coverage gaps exist.
```

---

## PR #2: GPS Position & Boat Tracking

**Branch:** `feature/boat-position-tracking`  
**Estimated Effort:** 3 days  
**Priority:** HIGH

### Recommended Agent: `blueprint-mode-codex`

**Why:** Core provider architecture and state management. Requires strict adherence to provider hierarchy rules.

### Implementation Prompt

```
Task: Implement GPS position tracking with BoatProvider per NEXT_STEPS.md PR#2.

Context:
- Read docs/MASTER_DEVELOPMENT_BIBLE.md Section A (especially ISS-002 God Objects, ISS-018 GPS Jumps)
- Read docs/AI_AGENT_INSTRUCTIONS.md
- NMEAProvider already exists and parses GPGGA/GPRMC data
- Current state: No BoatProvider, no boat marker on map

Requirements from requirements.md FEAT-002:
1. Create BoatPosition model (lat, lng, speed, course, heading, timestamp, accuracy)
2. Create BoatProvider (Layer 2) consuming NMEAProvider data
3. Extract position from NMEA GPGGA/GPRMC sentences
4. Maintain track history (max 1000 points, LRU eviction)
5. Filter unrealistic position jumps (>50 m/s) per ISS-018 workaround
6. Create BoatMarker widget overlay
7. Create TrackOverlay CustomPainter for breadcrumb trail
8. Add MOB (Man Overboard) marker capability

Files to create:
- lib/models/boat_position.dart (~120 lines)
- lib/providers/boat_provider.dart (~190 lines)
- lib/widgets/overlays/boat_marker.dart (~150 lines)
- lib/widgets/overlays/track_overlay.dart (~180 lines)

Files to modify:
- lib/main.dart (add BoatProvider to hierarchy)
- lib/screens/map_screen.dart (add boat marker + track overlays to stack)

Architecture constraints:
- BoatProvider MUST be Layer 2 (depends on NMEAProvider, MapProvider)
- Use ChangeNotifierProxyProvider for wiring
- ALL position rendering MUST use ProjectionService for coordinate transforms
- Track history stored in provider, NOT in widget state
- Implement ISS-018 filter: reject if delta > 50 m/s AND accuracy > 50m
- Keep all files under 300 lines

Provider update pattern:
```dart
ChangeNotifierProxyProvider<NMEAProvider, BoatProvider>(
  create: (_) => BoatProvider(),
  update: (_, nmea, boat) => boat!..updateFromNMEA(nmea.currentData),
)
```

Testing required:
- Unit: BoatProvider position updates, track LRU eviction, ISS-018 filtering
- Widget: Boat marker renders at correct position (use mock position)
- Widget: Track overlay renders line connecting points
- Integration: NMEA → BoatProvider → UI flow with mock NMEA data

Before starting:
1. Review NMEAProvider API (currentData, GPGGA/GPRMC fields)
2. Check ISS-018 workaround in KNOWN_ISSUES_DATABASE.md
3. Review ProjectionService API for lat/lng → screen conversion

Definition of done:
- BoatProvider in provider hierarchy (validated with integration test)
- Boat marker displays current position from NMEA
- Track history shows breadcrumb trail
- Position filtering prevents unrealistic jumps
- MOB marker functional
- All tests passing (≥80% coverage)
- Documentation updated
```

---

## PR #3: Basic Weather Overlays

**Branch:** `feature/weather-overlays`  
**Estimated Effort:** 4 days  
**Priority:** MEDIUM

### Recommended Agent: `gpt-5-beast-mode`

**Why:** This requires API integration, cache strategy, and overlay rendering. The beast mode agent can autonomously handle research (Open-Meteo API docs), implement the solution, and iterate on issues.

### Implementation Prompt

```
Task: Implement weather overlays with WeatherProvider per NEXT_STEPS.md PR#3.

Context:
- Read docs/MASTER_DEVELOPMENT_BIBLE.md Section A (especially ISS-001 Projection Mismatch, ISS-004 Cache Consistency)
- Read docs/AI_AGENT_INSTRUCTIONS.md
- Open-Meteo Marine API: https://open-meteo.com/en/docs/marine-weather-api
- Current state: No weather integration, CacheProvider exists

Requirements from requirements.md FEAT-003:
1. Integrate Open-Meteo Marine Weather API
2. Implement cache-first strategy (check cache → return + background refresh → update)
3. Create WeatherProvider (Layer 2) managing weather data
4. Render wind arrows with Beaufort scale coloring
5. Add layer toggle controls (show/hide overlays)
6. Implement retry (3x, exponential backoff) and timeout (10s)
7. Fall back to cache on network failure

Files to create:
- lib/models/weather_data.dart (~150 lines)
- lib/models/wind_data.dart (~80 lines)
- lib/models/wave_data.dart (~80 lines)
- lib/services/weather_api.dart (~220 lines)
- lib/providers/weather_provider.dart (~250 lines)
- lib/widgets/overlays/wind_overlay.dart (~180 lines)
- lib/widgets/overlays/wave_overlay.dart (~180 lines, optional)
- lib/widgets/controls/layer_toggle.dart (~100 lines)

Files to modify:
- lib/main.dart (add WeatherProvider to hierarchy)
- lib/screens/map_screen.dart (add overlay stack + layer toggles)

Architecture constraints:
- WeatherProvider Layer 2 (depends on CacheProvider, SettingsProvider, MapProvider)
- MUST use cache-first strategy per Architecture Rule C.4
- ALL coordinate transforms through ProjectionService (prevents ISS-001)
- Debounce weather fetches (max 1 request per 10 seconds)
- Cache TTL: 1 hour
- Retry logic: 3 attempts, backoff 1s/2s/4s
- Timeout: 10 seconds per request
- Keep files under 300 lines

Open-Meteo API usage:
- Endpoint: `https://marine-api.open-meteo.com/v1/marine`
- Parameters: latitude, longitude, hourly=[wind_speed_10m, wind_direction_10m, wave_height, wave_direction]
- Response format: JSON with time series arrays
- Rate limit: None (free tier)

Testing required:
- Unit: WeatherApi retry/timeout logic
- Unit: Cache-first strategy (cache hit, cache miss, stale cache)
- Unit: Beaufort scale calculation
- Widget: Wind overlay renders arrows at correct positions
- Integration: Map pan → weather fetch → cache → overlay update

Before starting:
1. Research Open-Meteo Marine API documentation
2. Review ISS-001 solution (ProjectionService usage)
3. Review ISS-004 solution (cache-first pattern)
4. Check CacheProvider API for integration

Definition of done:
- Weather fetches from Open-Meteo API successfully
- Wind arrows render at correct geographic positions
- Cache-first prevents redundant API calls
- Retry/timeout/fallback working correctly
- Layer toggles show/hide overlays
- All tests passing (≥80% coverage)
- No ISS-001 regression (verified in integration test)
- Documentation updated
```

### Security Review Agent: `se-security-reviewer`

After implementation, review for security issues:

```
Review the weather API integration for security vulnerabilities.

Check for:
1. API key exposure (if required in future)
2. Input validation on API responses (malformed JSON, unexpected fields)
3. Bounds validation (prevent excessively large area requests)
4. Rate limiting client-side (prevent abuse)
5. HTTPS enforcement
6. Cache poisoning prevention

Recommend security improvements.
```

---

## PR #4: 7-Day Forecast Screen

**Branch:** `feature/forecast-screen`  
**Estimated Effort:** 3 days  
**Priority:** MEDIUM

### Recommended Agent: `expert-react-frontend-engineer`

**Why:** Primarily UI/UX work building forecast cards and charts. While the agent is React-focused, the patterns (component composition, performance, responsive design) translate well to Flutter.

### Implementation Prompt

```
Task: Implement ForecastScreen with 7-day weather forecast per NEXT_STEPS.md PR#4.

Context:
- Read docs/MASTER_DEVELOPMENT_BIBLE.md Section G (SailStream UI Architecture)
- Read docs/AI_AGENT_INSTRUCTIONS.md (especially SailStream Widget Patterns)
- WeatherProvider already exists (from PR#3)
- Current state: No forecast screen, no forecast UI components

Requirements from requirements.md FEAT-004 (partial):
1. Display 7-day weather forecast (hourly and daily breakdown)
2. Use Ocean Glass design system (GlassCard, design tokens)
3. Responsive layout (mobile/tablet/desktop breakpoints)
4. Pull forecast data from WeatherProvider
5. Cache forecast data (TTL: 1 hour)

Files to create:
- lib/screens/forecast_screen.dart (~250 lines)
- lib/widgets/cards/forecast_card.dart (~150 lines)
- lib/widgets/cards/weather_card.dart (~130 lines)
- lib/models/forecast_data.dart (~120 lines)

Files to modify:
- lib/providers/weather_provider.dart (add getForecast method)
- lib/services/weather_api.dart (add forecast endpoint)
- lib/main.dart (add /forecast route)

Design system constraints:
- MUST use Ocean Glass components (GlassCard)
- MUST use design tokens from lib/theme/dimensions.dart, colors.dart
- MUST support responsive breakpoints: mobile (<600px), tablet (600-1200px), desktop (>1200px)
- Typography: OceanTextStyles.heading1, body, dataValue
- Colors: deepNavy, seafoamGreen, teal, safetyOrange
- Spacing: spacingXS (4), spacingS (8), spacing (16), spacingL (24)

UI layout (mobile):
- AppBar with "Forecast" title + back button
- ScrollView body
- Daily forecast cards (7 cards, stacked vertically)
- Each card: date, temp range, wind speed/direction, wave height, weather icon
- Hourly breakdown (expandable accordion per day)

UI layout (tablet/desktop):
- Grid layout (2-3 columns)
- Larger cards with more detail
- Chart visualizations (optional)

Performance requirements:
- Use RepaintBoundary for GlassCard widgets
- Lazy loading for hourly breakdowns
- Smooth scrolling at 60 FPS

Testing required:
- Widget: ForecastScreen renders without overflow at all breakpoints
- Widget: Forecast cards display data correctly
- Golden: Layout snapshot at mobile/tablet sizes

Before starting:
1. Review Ocean Glass design system in MASTER_DEVELOPMENT_BIBLE.md Section G
2. Check existing GlassCard implementation
3. Review ResponsiveUtils API for breakpoint handling

Definition of done:
- ForecastScreen accessible from navigation
- 7-day forecast displays with hourly/daily breakdown
- Ocean Glass design system applied throughout
- Responsive layouts tested at all breakpoints
- Forecast data cached (TTL: 1 hour)
- All tests passing
- Documentation updated
```

---

## PR #5: Timeline Playback

**Branch:** `feature/timeline-playback`  
**Estimated Effort:** 4 days  
**Priority:** MEDIUM

### Recommended Agent: `blueprint-mode-codex`

**Why:** Critical memory management work (ISS-013 prevention). Requires strict adherence to lazy loading architecture and precise implementation of LRU eviction.

### Implementation Prompt

```
Task: Implement timeline playback with TimelineProvider per NEXT_STEPS.md PR#5.

Context:
- Read docs/MASTER_DEVELOPMENT_BIBLE.md Section A (especially ISS-013 Memory Overflow)
- Read docs/KNOWN_ISSUES_DATABASE.md ISS-013 solution
- Read docs/AI_AGENT_INSTRUCTIONS.md
- WeatherProvider and ForecastScreen exist (from PR#3 and PR#4)
- Current state: No timeline playback, no TimelineProvider

Requirements from requirements.md FEAT-004:
1. Create TimelineProvider (Layer 3) for playback state
2. Implement lazy frame loading (max 5 frames in memory)
3. Implement LRU eviction (evict frame furthest from current)
4. Preload adjacent frames in background
5. Add playback controls (play/pause, speed: 0.5x/1x/2x/4x)
6. Add timeline scrubber for manual time selection
7. Batch UI updates (max 200ms interval)

Files to create:
- lib/providers/timeline_provider.dart (~250 lines)
- lib/screens/timeline_screen.dart (~280 lines)
- lib/widgets/data_displays/timeline_scrubber.dart (~150 lines)
- lib/widgets/controls/timeline_controls.dart (~120 lines)

Files to modify:
- lib/main.dart (add TimelineProvider to hierarchy Layer 3)
- lib/providers/weather_provider.dart (add getFrameData method)

Architecture constraints:
- TimelineProvider MUST be Layer 3 (depends on WeatherProvider, MapProvider, SettingsProvider)
- MANDATORY: Max 5 frames in memory at any time (ISS-013 prevention)
- LRU eviction: evict frame with largest distance from currentFrameIndex
- Preload next frame in background (currentIndex + 1)
- Batch notifyListeners() calls (max every 200ms)
- Keep files under 300 lines

ISS-013 Prevention Pattern (CRITICAL):
```dart
class TimelineProvider {
  final int _maxCachedFrames = 5;
  final Map<int, WeatherFrame> _frameCache = {};
  int _currentFrameIndex = 0;
  
  Future<WeatherFrame> _loadFrame(int index) async {
    // Check cache
    if (_frameCache.containsKey(index)) return _frameCache[index]!;
    
    // Evict if full
    if (_frameCache.length >= _maxCachedFrames) {
      final furthest = _frameCache.keys.reduce((a, b) => 
        (a - _currentFrameIndex).abs() > (b - _currentFrameIndex).abs() ? a : b
      );
      _frameCache.remove(furthest);
    }
    
    // Load from API
    final frame = await _weatherProvider.getFrameData(index);
    _frameCache[index] = frame;
    
    // Preload next
    _preloadFrame(index + 1);
    
    return frame;
  }
}
```

Playback timer logic:
```dart
void _scheduleNextFrame() {
  if (_state != PlaybackState.playing) return;
  if (_currentFrame >= _totalFrames - 1) { pause(); return; }
  
  final realDuration = _timestamps[_currentFrame + 1] - _timestamps[_currentFrame];
  final playbackDuration = realDuration * (1 / _speed);
  
  _timer = Timer(playbackDuration, () {
    _currentFrame++;
    notifyListeners();
    _scheduleNextFrame();
  });
}
```

Testing required (CRITICAL):
- Unit: Lazy loading logic
- Unit: LRU eviction correctness
- Unit: Preloading triggers correctly
- **Memory test: Verify NEVER more than 5 frames in _frameCache during playback**
- Widget: Timeline scrubber interaction
- Widget: Playback controls (play/pause/speed)
- Integration: Playback → frame load → overlay update pipeline

Before starting:
1. Review ISS-013 solution in KNOWN_ISSUES_DATABASE.md (lines 742-834)
2. Review TimelineProvider pattern in AI_AGENT_INSTRUCTIONS.md (lines 460-513)
3. Verify WeatherProvider.getFrameData() API

Definition of done:
- TimelineProvider in hierarchy (Layer 3, validated)
- Timeline playback works at all speeds
- Memory test confirms max 5 frames (MANDATORY)
- Frame preloading provides smooth transitions
- Scrubber allows manual time selection
- Playback controls functional
- All tests passing (≥80% coverage)
- No memory leaks (verified with dispose())
- Documentation updated
```

### Memory Testing Agent: `principal-software-engineer`

After implementation, verify memory safety:

```
Review the TimelineProvider implementation for memory safety.

Verify:
1. _maxCachedFrames = 5 is enforced (no exceptions)
2. LRU eviction algorithm is correct
3. dispose() cancels all timers and clears cache
4. No memory leaks from listeners or subscriptions
5. Memory test actually validates frame count during playback

Run memory profiler if available and confirm stable memory usage during 5+ minute playback session.
```

---

## Documentation PR

**Branch:** `docs/update-phase-5-docs`  
**Estimated Effort:** 1 day  
**Priority:** LOW (can be merged with any feature PR)

### Recommended Agent: `se-technical-writer`

**Why:** Specialized in developer documentation, technical accuracy, and clarity.

### Implementation Prompt

```
Task: Update all documentation to reflect completed PRs #1-5.

Context:
- PRs #1-5 have added significant new code
- CODEBASE_MAP.md needs file additions
- PROVIDER_HIERARCHY.md needs Layer 3 provider
- Requirements/design/tasks may need status updates

Files to update:
- docs/CODEBASE_MAP.md (add all new files to structure and module ownership)
- docs/PROVIDER_HIERARCHY.md (add TimelineProvider to Layer 3)
- requirements.md (mark FEAT-001 through FEAT-004 as complete)
- design.md (update with implementation notes if architecture changed)
- tasks.md (mark tasks complete)
- NEXT_STEPS.md (update with completed items, add new next steps if needed)

Documentation requirements:
- Accurate file paths and line counts
- Updated provider dependency graph (if Layer 3 added)
- Clear module ownership table
- Test coverage stats
- Updated roadmap/next steps

Before starting:
1. Review all merged PRs and their file changes
2. Count lines in each new file (adhere to 300-line rule documentation)
3. Verify provider hierarchy remains acyclic
4. Check test coverage reports

Definition of done:
- CODEBASE_MAP.md accurately reflects current codebase
- PROVIDER_HIERARCHY.md shows complete dependency graph
- All planning artifacts updated
- No broken links or outdated references
- Clear and technically accurate
```

---

## Workflow for Each PR

### 1. Pre-Implementation

1. Read NEXT_STEPS.md for PR details
2. Read MASTER_DEVELOPMENT_BIBLE.md relevant sections
3. Read KNOWN_ISSUES_DATABASE.md for related issues
4. Review CODEBASE_MAP.md for affected components
5. Verify Architecture Rules compliance

### 2. Implementation

1. Use recommended custom agent with provided prompt
2. Follow TDD: write failing test → implement → pass test
3. Keep files under 300 lines (refactor if needed)
4. Use ProjectionService for ALL coordinate transforms
5. Dispose all controllers/subscriptions
6. Follow Ocean Glass design system

### 3. Testing

1. Run `flutter analyze` (zero errors/warnings)
2. Run `flutter test --coverage` (≥80% coverage)
3. Use `code_review` tool (address feedback)
4. Use `codeql_checker` tool (fix vulnerabilities)
5. Memory test for timeline playback (if applicable)

### 4. Documentation

1. Update CODEBASE_MAP.md with new files
2. Update PROVIDER_HIERARCHY.md if providers changed
3. Update requirements/design/tasks status
4. Add code comments for complex logic
5. Update KNOWN_ISSUES_DATABASE.md if fixing bugs

### 5. Review & Merge

1. Final `code_review` if significant changes made
2. Ensure all definition of done items checked
3. Commit with clear message following conventions
4. Push branch and create PR (via report_progress if needed)
5. Address review feedback
6. Merge when approved

---

## Agent Selection Quick Reference

| Task Type | Recommended Agent | Reason |
|-----------|-------------------|---------|
| Core Architecture | `blueprint-mode-codex` | Strict correctness, structured workflows |
| API Integration | `gpt-5-beast-mode` | Autonomous research and iteration |
| UI Components | `expert-react-frontend-engineer` | Modern patterns, performance |
| Memory Management | `blueprint-mode-codex` | Precision, safety-critical |
| Testing Strategy | `principal-software-engineer` | Engineering excellence |
| Documentation | `se-technical-writer` | Technical accuracy, clarity |
| Security Review | `se-security-reviewer` | Vulnerability detection |
| Code Cleanup | `janitor` | Refactoring, simplification |

---

## Common Pitfalls to Avoid

### From MASTER_DEVELOPMENT_BIBLE.md Section A:

1. **ISS-001: Projection Mismatch** → Use ProjectionService for ALL transforms
2. **ISS-002: God Objects** → Keep files under 300 lines, single responsibility
3. **ISS-003: Provider Wiring** → Providers ONLY in main.dart
4. **ISS-004: Cache Consistency** → Cache-first strategy, coordinated invalidation
5. **ISS-006: Memory Leaks** → Dispose everything in dispose()
6. **ISS-008: WebView Sync Lag** → Debounce 200ms, batch updates
7. **ISS-009: UI Thread Blocking** → Use Isolate for heavy computation
8. **ISS-013: Memory Overflow** → Lazy loading, max 5 frames in memory

### Quick Architecture Checks:

- ✅ All providers in main.dart?
- ✅ Provider hierarchy acyclic (max 3 layers)?
- ✅ All coordinates through ProjectionService?
- ✅ All files under 300 lines?
- ✅ All controllers disposed?
- ✅ Cache-first for network requests?
- ✅ Tests passing with ≥80% coverage?

---

**Last Updated:** 2025-02-03  
**Next Review:** After each PR completion
