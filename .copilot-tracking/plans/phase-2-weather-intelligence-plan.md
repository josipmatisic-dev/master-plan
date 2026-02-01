---
goal: Phase 2 Weather Intelligence - Weather Integration and Forecasting
version: 1.0
date_created: 2026-02-01
last_updated: 2026-02-01
owner: Development Team
status: 'Planned'
tags: [weather, forecasting, timeline, api, caching]
---

# Phase 2: Weather Intelligence - Implementation Plan

![Status: Planned](https://img.shields.io/badge/status-Planned-blue)

**Duration:** Week 7-10 (20 working days)  
**Effort:** ~160 hours  
**Dependencies:** Phase 0 and Phase 1 Complete

## Introduction

Phase 2 integrates comprehensive weather data into the navigation app, including current conditions, 7-day forecasts, timeline playback, and advanced weather overlays. This phase transforms the app into a weather-intelligent navigation tool.

**Key Objectives:**
- Integrate Open-Meteo API for marine weather data
- Implement 7-day forecast with hourly resolution
- Create interactive timeline playback with scrubber
- Add multiple weather overlays (precipitation, currents, SST)
- Implement offline-first caching strategy
- Display weather forecast graphs and predictions

**Success Metrics:**
- Weather data loads in <3 seconds
- Timeline playback smooth at multiple speeds (0.5x, 1x, 2x, 4x)
- Forecast cached for offline access
- No stale data issues (ISS-004 avoided)
- Test coverage ≥80%

## 1. Requirements & Constraints

### Functional Requirements

- **REQ-201**: Fetch weather data from Open-Meteo API
- **REQ-202**: Display 7-day forecast with hourly breakdown
- **REQ-203**: Timeline playback with play/pause/speed controls
- **REQ-204**: Weather overlays: precipitation, ocean currents, sea surface temperature
- **REQ-205**: Forecast comparison between models (GFS, ECMWF)
- **REQ-206**: Weather alerts and warnings
- **REQ-207**: Cache-first architecture with background refresh (Avoid ISS-004, ISS-010)

### Architecture Requirements

- **REQ-208**: WeatherProvider maximum 300 lines
- **REQ-209**: TimelineProvider maximum 300 lines
- **REQ-210**: All weather data cached with TTL (1 hour)
- **REQ-211**: Lazy load forecast frames (Avoid ISS-013)
- **REQ-212**: Background refresh doesn't block UI

### Security Requirements

- **SEC-201**: Open-Meteo API requests validated
- **SEC-202**: Weather data sanitized before display
- **SEC-203**: No sensitive location data in API requests

### Known Issues to Avoid

- **ISS-004**: CRITICAL - Stale weather data after fetch (multiple cache layers out of sync)
- **ISS-010**: HIGH - Offline mode shows connection error (need cache-first)
- **ISS-013**: CRITICAL - Timeline loading all frames causes OutOfMemory
- **ISS-014**: MEDIUM - WebView JavaScript bridge timeout

## 2. Implementation Steps

### Implementation Phase 1: Open-Meteo API Integration

**GOAL-201**: Integrate Open-Meteo API for marine weather data

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-201 | Create WeatherApi service class | | |
| TASK-202 | Implement fetchMarineWeather(bounds) method | | |
| TASK-203 | Add weather parameter selection (wind, waves, currents, temp) | | |
| TASK-204 | Implement 7-day forecast fetching | | |
| TASK-205 | Add hourly resolution support | | |
| TASK-206 | Implement retry logic with RetryableHttpClient | | |
| TASK-207 | Add response parsing and validation | | |
| TASK-208 | Create unit tests for WeatherApi | | |

### Implementation Phase 2: Weather Data Models

**GOAL-202**: Create comprehensive weather data models

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-209 | Create ForecastData model with time series | | |
| TASK-210 | Create CurrentData model for current conditions | | |
| TASK-211 | Create OceanCurrentData model | | |
| TASK-212 | Create PrecipitationData model | | |
| TASK-213 | Create TemperatureData model (SST) | | |
| TASK-214 | Add freezed code generation | | |
| TASK-215 | Create unit tests for all models | | |

### Implementation Phase 3: Weather Provider with Cache-First

**GOAL-203**: Implement WeatherProvider with cache-first architecture (Avoid ISS-004, ISS-010)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-216 | Create WeatherProvider class (<300 lines) | | |
| TASK-217 | Implement cache-first getWeather() method | | |
| TASK-218 | Add background refresh after cache return | | |
| TASK-219 | Implement coordinated cache invalidation | | |
| TASK-220 | Add TTL-based expiry (1 hour default) | | |
| TASK-221 | Implement bounds-based cache keying | | |
| TASK-222 | Add offline mode handling | | |
| TASK-223 | Create unit tests for WeatherProvider | | |

**Critical Implementation (Avoid ISS-004):**
```dart
Future<WeatherData> getWeather(Bounds bounds) async {
  final cacheKey = 'weather_${bounds.hash}';
  
  // 1. Check cache first (offline-first)
  final cached = await _cache.get<WeatherData>(cacheKey);
  if (cached != null && !cached.isExpired) {
    // Return cached immediately
    _currentWeather = cached;
    notifyListeners();
    
    // Refresh in background
    _refreshInBackground(bounds, cacheKey);
    
    return cached;
  }
  
  // 2. Fetch from network
  try {
    final data = await _api.fetchWeather(bounds)
      .timeout(Duration(seconds: 10));
    
    // 3. Update single cache (coordinated)
    await _cache.set(cacheKey, data, ttl: Duration(hours: 1));
    
    _currentWeather = data;
    notifyListeners();
    
    return data;
  } catch (e) {
    // 4. Return stale cache on error
    if (cached != null) return cached;
    rethrow;
  }
}
```

### Implementation Phase 4: Timeline Playback System

**GOAL-204**: Create timeline playback with lazy loading (Avoid ISS-013)

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-224 | Create TimelineProvider class (<300 lines) | | |
| TASK-225 | Implement lazy frame loading (max 5 frames cached) | | |
| TASK-226 | Add play/pause controls | | |
| TASK-227 | Implement speed controls (0.5x, 1x, 2x, 4x) | | |
| TASK-228 | Add scrubber for seeking | | |
| TASK-229 | Implement frame preloading | | |
| TASK-230 | Add dispose() for timer cleanup (Avoid ISS-006) | | |
| TASK-231 | Create unit tests for TimelineProvider | | |

**Critical Implementation (Avoid ISS-013):**
```dart
class TimelineProvider extends ChangeNotifier {
  final int _maxCachedFrames = 5;
  final Map<int, WeatherFrame> _frameCache = {};
  
  Future<WeatherFrame> _loadFrame(int index) async {
    if (_frameCache.containsKey(index)) {
      return _frameCache[index]!;
    }
    
    // Evict if cache full (LRU)
    if (_frameCache.length >= _maxCachedFrames) {
      final furthest = _getFurthestFrame();
      _frameCache.remove(furthest);
    }
    
    // Load frame
    final frame = await _api.getForecastFrame(index);
    _frameCache[index] = frame;
    
    // Preload next
    _preloadFrame(index + 1);
    
    return frame;
  }
}
```

### Implementation Phase 5: Timeline Controls UI

**GOAL-205**: Create timeline scrubber and playback controls

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-232 | Create TimelineControls widget | | |
| TASK-233 | Implement scrubber slider | | |
| TASK-234 | Add play/pause button | | |
| TASK-235 | Add speed selector (0.5x, 1x, 2x, 4x) | | |
| TASK-236 | Add timestamp display | | |
| TASK-237 | Add frame counter (current/total) | | |
| TASK-238 | Ensure dispose() implemented (ISS-006) | | |
| TASK-239 | Create widget tests for TimelineControls | | |

### Implementation Phase 6: Additional Weather Overlays

**GOAL-206**: Add precipitation, currents, and temperature overlays

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-240 | Create PrecipitationOverlay widget | | |
| TASK-241 | Create OceanCurrentOverlay widget | | |
| TASK-242 | Create SeaTempOverlay widget (SST) | | |
| TASK-243 | Implement color-coded precipitation intensity | | |
| TASK-244 | Implement current vector rendering | | |
| TASK-245 | Implement temperature gradient rendering | | |
| TASK-246 | Add overlay visibility toggles | | |
| TASK-247 | Create widget tests for all overlays | | |

### Implementation Phase 7: Forecast Screen

**GOAL-207**: Create dedicated forecast viewing screen

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-248 | Create ForecastScreen scaffold | | |
| TASK-249 | Add 7-day forecast list | | |
| TASK-250 | Implement hourly breakdown expansion | | |
| TASK-251 | Add weather condition icons | | |
| TASK-252 | Create weather charts (wind, waves, temp) | | |
| TASK-253 | Add model comparison view | | |
| TASK-254 | Implement forecast sharing | | |
| TASK-255 | Create widget tests for ForecastScreen | | |

### Implementation Phase 8: Weather Alerts

**GOAL-208**: Implement weather alerts and warnings

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-256 | Create WeatherAlert model | | |
| TASK-257 | Implement alert detection logic | | |
| TASK-258 | Add alert notification system | | |
| TASK-259 | Create AlertCard widget | | |
| TASK-260 | Implement alert severity levels | | |
| TASK-261 | Add alert dismissal | | |
| TASK-262 | Create unit tests for alert logic | | |

### Implementation Phase 9: Offline Weather Caching

**GOAL-209**: Pre-download weather for offline access

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-263 | Implement region download for offline use | | |
| TASK-264 | Add download progress indicator | | |
| TASK-265 | Implement storage management (size limits) | | |
| TASK-266 | Add offline mode indicator | | |
| TASK-267 | Create download manager UI | | |
| TASK-268 | Test offline functionality | | |

### Implementation Phase 10: Testing & Documentation

**GOAL-210**: Comprehensive testing and documentation

| Task | Description | Completed | Date |
|------|-------------|-----------|------|
| TASK-269 | Unit tests for WeatherApi (≥80% coverage) | | |
| TASK-270 | Unit tests for WeatherProvider (cache-first validation) | | |
| TASK-271 | Unit tests for TimelineProvider (lazy loading validation) | | |
| TASK-272 | Widget tests for all weather UI | | |
| TASK-273 | Integration test for weather flow | | |
| TASK-274 | Performance test for timeline playback | | |
| TASK-275 | Memory test (ISS-013 check - no OOM with 168 frames) | | |
| TASK-276 | Update CODEBASE_MAP.md | | |
| TASK-277 | Update FEATURE_REQUIREMENTS.md | | |
| TASK-278 | Document any new issues | | |

## 3. Alternatives

- **ALT-201**: NOAA APIs instead of Open-Meteo
  - Rejected: Open-Meteo provides better global coverage and simpler API
  
- **ALT-202**: Load all timeline frames upfront
  - Rejected: Causes OOM (ISS-013), lazy loading required
  
- **ALT-203**: Network-first caching
  - Rejected: Causes offline errors (ISS-010), cache-first required

## 4. Dependencies

### External Dependencies

- **DEP-201**: Open-Meteo API (free tier)
- **DEP-202**: fl_chart ^0.65.0 - Chart library
- **DEP-203**: intl ^0.18.0 - Date formatting

### Phase Dependencies

- **DEP-204**: Phase 0 complete (CacheService, HttpClient)
- **DEP-205**: Phase 1 complete (MapProvider, overlays)

## 5. Files

### New Files

- **FILE-201**: `lib/services/weather_api.dart`
- **FILE-202**: `lib/providers/weather_provider.dart`
- **FILE-203**: `lib/providers/timeline_provider.dart`
- **FILE-204**: `lib/models/forecast_data.dart`
- **FILE-205**: `lib/models/ocean_current_data.dart`
- **FILE-206**: `lib/models/precipitation_data.dart`
- **FILE-207**: `lib/widgets/overlays/precipitation_overlay.dart`
- **FILE-208**: `lib/widgets/overlays/current_overlay.dart`
- **FILE-209**: `lib/widgets/overlays/sea_temp_overlay.dart`
- **FILE-210**: `lib/widgets/controls/timeline_controls.dart`
- **FILE-211**: `lib/screens/forecast_screen.dart`
- **FILE-212**: `lib/widgets/cards/weather_card.dart`
- **FILE-213**: `lib/widgets/cards/forecast_card.dart`

### Modified Files

- **FILE-214**: `docs/CODEBASE_MAP.md`
- **FILE-215**: `docs/FEATURE_REQUIREMENTS.md`
- **FILE-216**: `lib/main.dart`

## 6. Testing

### Unit Tests

- **TEST-201**: WeatherApi fetch and parsing
- **TEST-202**: Cache-first weather loading
- **TEST-203**: Timeline lazy frame loading
- **TEST-204**: Weather alert detection
- **TEST-205**: Forecast data model serialization

### Widget Tests

- **TEST-206**: TimelineControls playback
- **TEST-207**: Weather overlays rendering
- **TEST-208**: ForecastScreen display
- **TEST-209**: Alert notifications

### Integration Tests

- **TEST-210**: Full weather + timeline flow
- **TEST-211**: Offline weather access
- **TEST-212**: Timeline memory usage (ISS-013 check)

## 7. Risks & Assumptions

### Risks

- **RISK-201**: Open-Meteo API rate limits
  - Severity: Medium
  - Mitigation: Aggressive caching, request throttling
  
- **RISK-202**: Timeline memory overflow (ISS-013)
  - Severity: Critical
  - Mitigation: Strict frame cache limits, testing
  
- **RISK-203**: Stale cache data (ISS-004)
  - Severity: High
  - Mitigation: Single unified cache, coordinated invalidation

### Assumptions

- **ASSUMPTION-201**: Open-Meteo free tier sufficient
- **ASSUMPTION-202**: 5 cached frames sufficient for timeline
- **ASSUMPTION-203**: 1-hour TTL appropriate for weather data

## 8. Related Specifications / Further Reading

- [MASTER_DEVELOPMENT_BIBLE.md](../../docs/MASTER_DEVELOPMENT_BIBLE.md) - Section D.2 Essential Features
- [KNOWN_ISSUES_DATABASE.md](../../docs/KNOWN_ISSUES_DATABASE.md) - ISS-004, ISS-010, ISS-013, ISS-014
- [AI_AGENT_INSTRUCTIONS.md](../../docs/AI_AGENT_INSTRUCTIONS.md) - CP.1 Weather Data Fetching Pattern
- [phase-2-weather-intelligence-details.md](../details/phase-2-weather-intelligence-details.md)
- [implement-phase-2-weather-intelligence.prompt.md](../prompts/implement-phase-2-weather-intelligence.prompt.md)

---

**Phase 2 Completion Criteria:**

- [ ] All 278 tasks completed
- [ ] Weather data loads in <3 seconds
- [ ] Timeline playback smooth at all speeds
- [ ] No stale data issues (ISS-004 prevented)
- [ ] No OOM from timeline (ISS-013 prevented)
- [ ] Offline mode works (ISS-010 prevented)
- [ ] All tests passing (≥80% coverage)
- [ ] Ready for Phase 3

**Next Phase:** [Phase 3: Polish & Features](phase-3-polish-features-plan.md)
