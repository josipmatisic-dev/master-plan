# Next Steps - Marine Navigation App (SailStream)

**Date:** 2025-02-03  
**Current Phase:** Post-Phase 4 (UI Integration Complete)  
**Status:** ✅ Ready for Next Phase

---

## Executive Summary

Phase 4 (UI Integration & Testing) is **complete and validated** with 86/86 tests passing. The app has:

- ✅ Core architecture (providers, services, models)
- ✅ NMEA data integration (parser, service, provider)
- ✅ SailStream UI components (Ocean Glass design system)
- ✅ Navigation Mode screen with real-time data
- ✅ Settings screen with NMEA configuration
- ✅ Home screen with theme controls

**Next Focus:** Complete remaining Phase 1 features and begin Phase 2 (Weather Intelligence).

---

## Immediate Next Steps (Priority Order)

### 1. Complete Phase 1: Core Navigation Features

**Objective:** Finish core map functionality and GPS tracking per MASTER_DEVELOPMENT_BIBLE.md Section D.1

#### 1.1 MapWebView Integration (FEAT-001)

**Status:** Partial - WebView widget exists but not fully wired  
**Remaining Work:**

- [ ] Complete JavaScript bridge for bi-directional communication
- [ ] Implement viewport sync (debounced, 200ms)
- [ ] Add map control methods (setCenter, setZoom, flyTo)
- [ ] Wire MapProvider to WebView state updates
- [ ] Add MapTiler API key configuration in Settings
- [ ] Test map rendering on all platforms (Android, iOS, Web)

**Files to Update:**

- `lib/widgets/map/map_webview.dart` (~200 lines target)
- `lib/providers/map_provider.dart` (update viewport sync)
- `assets/map.html` (MapTiler GL JS setup)
- `lib/providers/settings_provider.dart` (add mapTilerApiKey)

**Testing:**

- Integration test: map loads and responds to viewport changes
- Widget test: WebView renders without errors

#### 1.2 GPS Position Tracking (FEAT-002 Extension)

**Status:** NMEA provider done, boat position tracking needed  
**Remaining Work:**

- [ ] Create `BoatProvider` (Layer 2) for position state
- [ ] Add GPS position tracking from NMEA GPGGA/GPRMC
- [ ] Implement track history (breadcrumb trail)
- [ ] Add boat marker overlay on map
- [ ] Calculate speed, course, heading from NMEA data
- [ ] Add MOB (Man Overboard) marker capability

**Files to Create:**

- `lib/providers/boat_provider.dart` (~190 lines)
- `lib/models/boat_position.dart` (~120 lines)
- `lib/widgets/overlays/boat_marker.dart` (~150 lines)
- `lib/widgets/overlays/track_overlay.dart` (~180 lines)

**Files to Update:**

- `lib/main.dart` (add BoatProvider to hierarchy)
- `docs/CODEBASE_MAP.md` (document new providers/models)

**Testing:**

- Unit test: BoatProvider state management
- Integration test: NMEA → BoatProvider → UI flow
- Widget test: boat marker renders at correct position

#### 1.3 Weather Overlays (Basic)

**Status:** Not started  
**Remaining Work:**

- [ ] Create `WeatherProvider` (Layer 2) for weather data
- [ ] Integrate Open-Meteo API client
- [ ] Add wind vector overlay rendering
- [ ] Add wave height/direction overlay (optional)
- [ ] Implement cache-first strategy per Architecture Rule C.4
- [ ] Add layer toggle controls

**Files to Create:**

- `lib/providers/weather_provider.dart` (~250 lines)
- `lib/services/weather_api.dart` (~220 lines)
- `lib/models/weather_data.dart` (~150 lines)
- `lib/models/wind_data.dart` (~80 lines)
- `lib/models/wave_data.dart` (~80 lines)
- `lib/widgets/overlays/wind_overlay.dart` (~180 lines)
- `lib/widgets/overlays/wave_overlay.dart` (~180 lines)
- `lib/widgets/controls/layer_toggle.dart` (~100 lines)

**Files to Update:**

- `lib/main.dart` (add WeatherProvider to hierarchy)
- `lib/screens/map_screen.dart` (add overlay stack)

**Testing:**

- Unit test: WeatherApi client with retry/timeout
- Unit test: WeatherProvider cache-first logic
- Widget test: Wind overlay renders arrows correctly
- Integration test: weather fetch → cache → overlay pipeline

---

### 2. Begin Phase 2: Weather Intelligence

**Objective:** Add forecast capabilities and timeline playback per Section D.2

#### 2.1 7-Day Forecast (FEAT-003)

**Status:** Not started  
**Remaining Work:**

- [ ] Extend WeatherApi for forecast endpoints
- [ ] Create `ForecastScreen` with hourly/daily breakdown
- [ ] Add forecast data models
- [ ] Implement forecast caching with TTL
- [ ] Add forecast display widgets (cards, charts)

**Files to Create:**

- `lib/screens/forecast_screen.dart` (~250 lines)
- `lib/models/forecast_data.dart` (~120 lines)
- `lib/widgets/cards/forecast_card.dart` (~150 lines)
- `lib/widgets/cards/weather_card.dart` (~130 lines)

**Estimated Effort:** 2-3 days

#### 2.2 Timeline Playback (FEAT-004)

**Status:** Not started  
**Remaining Work:**

- [ ] Create `TimelineProvider` (Layer 3) for playback state
- [ ] Implement lazy frame loading (max 5 in memory)
- [ ] Add timeline scrubber UI component
- [ ] Add play/pause/speed controls
- [ ] Implement preloading for smooth playback
- [ ] Add timeline screen with map overlay

**Files to Create:**

- `lib/providers/timeline_provider.dart` (~250 lines)
- `lib/screens/timeline_screen.dart` (~280 lines)
- `lib/widgets/data_displays/timeline_scrubber.dart` (~150 lines)
- `lib/widgets/controls/timeline_controls.dart` (~120 lines)

**Critical:** Follow ISS-013 solution (lazy loading) to avoid OutOfMemory

**Estimated Effort:** 3-4 days

---

### 3. Infrastructure & Quality

#### 3.1 Testing Coverage

**Current:** 86/86 tests passing (providers, services, integration)  
**Target:** 80%+ coverage for all new code

**Remaining:**

- [ ] Add widget tests for all new screens
- [ ] Add integration tests for map → overlay pipeline
- [ ] Add golden tests for UI layouts
- [ ] Fix pre-existing widget_test.dart issue
- [ ] Setup coverage reporting in CI

#### 3.2 CI/CD Pipeline

**Status:** Workflow exists but may need updates  
**Actions:**

- [ ] Verify Flutter CI workflow runs on all branches
- [ ] Add automated test coverage reporting
- [ ] Add Flutter analyze check (fail on errors)
- [ ] Add build verification for all platforms
- [ ] Setup deployment pipeline (future)

**Files to Check:**

- `.github/workflows/*.yml`

#### 3.3 Documentation Updates

**Required for Each PR:**

- [ ] Update `CODEBASE_MAP.md` with new files
- [ ] Update `PROVIDER_HIERARCHY.md` if providers added
- [ ] Update `requirements.md` / `design.md` / `tasks.md` per feature
- [ ] Add/update code comments for complex logic
- [ ] Update KNOWN_ISSUES_DATABASE.md if fixing bugs

---

## Suggested PR Breakdown

### PR #1: Complete MapWebView Integration

**Branch:** `feature/map-webview-integration`  
**Scope:** FEAT-001 completion  
**Files:** 4 modified  
**Tests:** 3 new (integration + widget)  
**Estimated Effort:** 2 days

**Checklist:**

- [ ] JavaScript bridge functional
- [ ] Viewport sync working (200ms debounce)
- [ ] Map controls (zoom, pan, rotate) operational
- [ ] MapTiler API key configurable
- [ ] Tests passing
- [ ] Documentation updated

### PR #2: GPS Position & Boat Tracking

**Branch:** `feature/boat-position-tracking`  
**Scope:** FEAT-002 extension (BoatProvider)  
**Files:** 5 created, 2 modified  
**Tests:** 5 new (unit + integration + widget)  
**Estimated Effort:** 3 days

**Checklist:**

- [ ] BoatProvider in provider hierarchy
- [ ] GPS position from NMEA working
- [ ] Track history recording
- [ ] Boat marker on map
- [ ] Speed/course/heading calculated
- [ ] Tests passing
- [ ] Documentation updated

### PR #3: Basic Weather Overlays

**Branch:** `feature/weather-overlays`  
**Scope:** Weather integration basics  
**Files:** 8 created, 2 modified  
**Tests:** 6 new  
**Estimated Effort:** 4 days

**Checklist:**

- [ ] WeatherProvider in hierarchy
- [ ] Open-Meteo API integration
- [ ] Wind overlay rendering
- [ ] Cache-first strategy implemented
- [ ] Layer toggles working
- [ ] Tests passing
- [ ] Documentation updated

### PR #4: 7-Day Forecast Screen

**Branch:** `feature/forecast-screen`  
**Scope:** FEAT-003 (Phase 2 start)  
**Files:** 4 created, 1 modified  
**Tests:** 4 new  
**Estimated Effort:** 3 days

**Checklist:**

- [ ] ForecastScreen implemented
- [ ] Hourly/daily breakdown
- [ ] Forecast caching
- [ ] Weather cards/charts
- [ ] Tests passing
- [ ] Documentation updated

### PR #5: Timeline Playback

**Branch:** `feature/timeline-playback`  
**Scope:** FEAT-004  
**Files:** 4 created, 1 modified  
**Tests:** 5 new  
**Estimated Effort:** 4 days

**Checklist:**

- [ ] TimelineProvider (Layer 3)
- [ ] Lazy frame loading
- [ ] Timeline scrubber UI
- [ ] Playback controls
- [ ] Tests passing (memory-safe)
- [ ] Documentation updated

---

## Custom Agents Recommended

Based on `.github/agents/` available:

### For MapWebView & Architecture Work

**Agent:** `blueprint-mode-codex`  
**Reason:** Strict correctness, minimal tool usage, architectural oversight

### For UI Components

**Agent:** `expert-react-frontend-engineer` (adapt for Flutter)  
**Reason:** Modern component patterns, performance optimization

### For Documentation

**Agent:** `se-technical-writer`  
**Reason:** Developer documentation, technical accuracy

### For Testing Strategy

**Agent:** `principal-software-engineer`  
**Reason:** Engineering excellence, pragmatic testing approach

### For Security Review (before deployment)

**Agent:** `se-security-reviewer`  
**Reason:** OWASP Top 10, API security, input validation

---

## Risk Mitigation

### High-Priority Risks

**Risk 1: Overlay Projection Mismatch (ISS-001)**  
**Mitigation:**

- ALL coordinate transforms through ProjectionService
- Add lint rule to prevent manual lat/lng math
- Integration test for zoom/pan accuracy
- Reference: KNOWN_ISSUES_DATABASE.md ISS-001

**Risk 2: Memory Leaks (ISS-006, ISS-013)**  
**Mitigation:**

- Dispose all controllers/subscriptions
- Lazy loading for timeline frames
- Memory profiler in CI
- Reference: Architecture Rule C.10

**Risk 3: Provider Circular Dependencies (ISS-002, ISS-003)**  
**Mitigation:**

- Document hierarchy before coding
- Max 3 dependency layers
- Integration test validates acyclic graph
- All providers in main.dart only

**Risk 4: WebView Sync Lag (ISS-008)**  
**Mitigation:**

- Debounce viewport updates (200ms)
- Use requestAnimationFrame in JS
- Batch UI updates
- Reference: KNOWN_ISSUES_DATABASE.md ISS-008

---

## Definition of Done (Per PR)

- [ ] All acceptance criteria met (see requirements.md)
- [ ] Code compiles without errors/warnings
- [ ] All tests passing (unit + integration + widget)
- [ ] Test coverage ≥80% for new code
- [ ] Files under 300 lines (Architecture Rule C.5)
- [ ] All controllers/subscriptions disposed
- [ ] Provider hierarchy documented if changed
- [ ] CODEBASE_MAP.md updated
- [ ] KNOWN_ISSUES_DATABASE.md updated if fixing bugs
- [ ] Code reviewed (use code_review tool before final commit)
- [ ] Security checked (use codeql_checker tool)
- [ ] No regressions to existing features

---

## Long-Term Roadmap

### Phase 3: Polish & Features (Future)

- Dark mode (already partial support)
- Settings expansion (units, language, map styles)
- Harbor alerts & notifications
- AIS integration (collision warnings)
- Tides & currents
- Audio alerts
- Performance monitoring

### Phase 4: Social & Community (Future)

- Trip logging
- Social sharing
- User profiles
- Collaborative routes
- Community feeds

### Phase 5: Deployment (Future)

- App store preparation
- Beta testing program
- Analytics integration
- Crash reporting
- Production deployment

---

## Notes for AI Agents

**Before Starting ANY Work:**

1. Read MASTER_DEVELOPMENT_BIBLE.md Section A (Failure Analysis)
2. Check KNOWN_ISSUES_DATABASE.md for similar patterns
3. Review CODEBASE_MAP.md for affected components
4. Verify against Architecture Rules (Section C)

**During Development:**

- Use ProjectionService for ALL coordinate transforms
- Create providers ONLY in main.dart
- Dispose EVERYTHING in dispose() methods
- Keep files under 300 lines
- Cache-first for all network requests
- Batch UI updates (max 5 fps for data streams)

**Before Committing:**

- Run `flutter analyze` (zero errors/warnings)
- Run `flutter test --coverage` (≥80% coverage)
- Use code_review tool
- Use codeql_checker tool
- Update documentation

**Prohibited Actions:**

- Manual lat/lng to pixel math (use ProjectionService)
- Providers in widget build methods (only in main.dart)
- Skipping dispose() (memory leaks)
- Fixed dimensions (use Flexible/Expanded)
- Network calls without retry/timeout/cache fallback
- God objects >300 lines (refactor immediately)

---

## Success Metrics

### Technical

- ✅ All tests passing (current: 86/86)
- ⏳ Test coverage ≥80% (target)
- ⏳ Zero lint warnings (target)
- ⏳ Build succeeds on all platforms (target)
- ⏳ Memory usage stable (<100MB) (target)
- ⏳ 60 FPS rendering (target)

### Functional

- ⏳ Map loads and renders smoothly
- ⏳ GPS position displays in real-time
- ⏳ Weather overlays accurate and aligned
- ⏳ Forecast accessible and playable
- ⏳ Offline mode functional (cache-first)
- ⏳ Settings persist across sessions

### Architecture

- ✅ Provider hierarchy acyclic (validated)
- ✅ Files under 300 lines (compliant)
- ✅ Ocean Glass design system applied
- ⏳ All coordinate transforms via ProjectionService
- ⏳ No memory leaks (to be validated)
- ⏳ Proper error handling throughout

---

## Contact & Resources

- **Documentation:** `/docs/` directory
- **Planning:** `/plan/` directory  
- **Tasks:** `.copilot-tracking/` directory
- **Agents:** `.github/agents/` directory
- **Workflows:** `.github/workflows/` directory

**Key Documents:**

- Architecture: `docs/MASTER_DEVELOPMENT_BIBLE.md`
- Instructions: `docs/AI_AGENT_INSTRUCTIONS.md`
- Issues: `docs/KNOWN_ISSUES_DATABASE.md`
- Code Map: `docs/CODEBASE_MAP.md`

---

**Last Updated:** 2025-02-03  
**Next Review:** After PR #1 completion
