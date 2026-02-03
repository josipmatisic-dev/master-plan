# Tasks - FEAT-001 Interactive Map Display

## Plan

1. Add `MapProvider` (Layer 2) with viewport state + update API.
2. Add `ProjectionService` with EPSG:3857 ↔ EPSG:4326 transforms.
3. Add WebView map container widget and minimal JS bridge hooks.
4. Wire provider in `main.dart` and update provider hierarchy docs.
5. Add unit tests for `ProjectionService` and `MapProvider`.
6. Add basic widget test for map container rendering.
7. Run `flutter test --coverage` and `flutter analyze`.

## Dependencies

- `MapProvider` depends on `SettingsProvider` (+ `CacheProvider` when caching is wired).
- `ProjectionService` is stateless, usable across providers/widgets.

## Definition of done

- Providers are acyclic and documented.
- All new files under 300 lines.
- Tests pass with ≥80% coverage for new code.

---

## FEAT-002 GPS Position & Boat Tracking

### Plan (FEAT-002)

1. Create `BoatPosition` model with lat/lng/speed/course/timestamp.
2. Create `BoatProvider` (Layer 2) depending on `NMEAProvider` + `MapProvider`.
3. Wire provider in `main.dart` using `ChangeNotifierProxyProvider`.
4. Implement position extraction from NMEA GPGGA/GPRMC in provider update method.
5. Add track history list with LRU eviction (max 1000 points).
6. Create `BoatMarker` widget consuming `BoatProvider.currentPosition`.
7. Create `TrackOverlay` CustomPainter rendering track history line.
8. Add MOB (Man Overboard) marker capability.
9. Implement ISS-018 workaround (filter unrealistic position jumps).
10. Add unit tests for `BoatProvider` state management.
11. Add widget tests for boat marker positioning.
12. Add integration test for NMEA → BoatProvider → UI flow.
13. Update `CODEBASE_MAP.md` with new files.

### Dependencies (FEAT-002)

- Depends on `NMEAProvider` (already implemented in Phase 4).
- Depends on `MapProvider` for viewport state.
- Depends on `ProjectionService` for coordinate transforms.
- Optional: `SettingsProvider` for track color/thickness preferences.

### Definition of done (FEAT-002)

- BoatProvider in provider hierarchy (acyclic, documented).
- Boat marker renders at correct geographic position on map.
- Track history displays breadcrumb trail.
- MOB marker captures and displays waypoint.
- All files under 300 lines.
- Tests pass with ≥80% coverage for new code.
- ISS-018 filtering implemented and tested.

---

## FEAT-003 Weather Overlays (Basic)

### Plan (FEAT-003)

1. Create `WeatherData`, `WindData`, `WaveData` models.
2. Create `WeatherApi` service with Open-Meteo integration.
3. Implement retry logic (3 attempts, exponential backoff).
4. Implement timeout (10 seconds) and cache fallback.
5. Create `WeatherProvider` (Layer 2) with cache-first strategy.
6. Wire provider in `main.dart` depending on `CacheProvider` + `SettingsProvider`.
7. Implement bounds-based weather fetching (debounced, 10s min interval).
8. Create `WindOverlay` CustomPainter with Beaufort scale coloring.
9. Create `WaveOverlay` CustomPainter (optional).
10. Create `LayerToggle` widget for show/hide controls.
11. Add weather overlay stack to `MapScreen`.
12. Add unit tests for `WeatherApi` retry/timeout.
13. Add unit tests for cache-first logic.
14. Add widget test for wind arrow rendering.
15. Add integration test for weather fetch → cache → overlay pipeline.
16. Update `CODEBASE_MAP.md` with new files.

### Dependencies (FEAT-003)

- Depends on `CacheProvider` (already implemented).
- Depends on `SettingsProvider` for units preferences.
- Depends on `MapProvider` for viewport bounds.
- Depends on `ProjectionService` for coordinate transforms.

### Definition of done (FEAT-003)

- WeatherProvider in hierarchy (acyclic, documented).
- Wind overlay renders arrows at correct positions (verified via integration test).
- Cache-first strategy prevents unnecessary API calls.
- Retry/timeout/fallback working correctly.
- Layer toggles show/hide overlays without reloading data.
- All files under 300 lines.
- Tests pass with ≥80% coverage.
- No ISS-001 regression (projection consistency).

---

## FEAT-004 Weather Forecast & Timeline

### Plan (FEAT-004)

1. Extend `WeatherApi` for forecast endpoints (7-day hourly).
2. Create `ForecastData` model for hourly/daily breakdown.
3. Update `WeatherProvider` with forecast methods.
4. Create `TimelineProvider` (Layer 3) for playback state.
5. Wire provider in `main.dart` depending on `WeatherProvider` + `MapProvider` + `SettingsProvider`.
6. Implement lazy frame loading (max 5 in memory, LRU eviction).
7. Implement frame preloading in background.
8. Create `ForecastScreen` with hourly/daily cards.
9. Create `TimelineScreen` with map + scrubber.
10. Create `TimelineScrubber` widget for time selection.
11. Create `TimelineControls` widget (play/pause/speed).
12. Add playback timer logic with speed controls.
13. Add unit tests for lazy loading and LRU eviction.
14. Add memory test (verify max 5 frames during playback).
15. Add widget tests for timeline interactions.
16. Add integration test for playback → frame load → overlay update.
17. Update `CODEBASE_MAP.md` with new files.

### Dependencies (FEAT-004)

- Depends on `WeatherProvider` (from FEAT-003).
- Depends on `MapProvider` for viewport.
- Depends on `SettingsProvider` for units/preferences.
- Timeline is Layer 3 (max depth per Architecture Rule C.3).

### Definition of done (FEAT-004)

- TimelineProvider in hierarchy (Layer 3, acyclic).
- Forecast screen displays 7-day hourly/daily breakdown.
- Timeline playback works smoothly at all speeds.
- Lazy loading prevents OutOfMemory (ISS-013 mitigation verified).
- Frame preloading provides smooth transitions.
- All files under 300 lines.
- Memory test confirms max 5 frames in cache.
- Tests pass with ≥80% coverage.
- No regression to existing features.

---

## FEAT-016 Navigation Mode Screen

### Plan (FEAT-016)

1. Scaffold `NavigationModeScreen` with MapWebView background, data orbs, route info card, and action bar.
2. Reuse `NavigationSidebar` and place it with responsive spacing.
3. Wire placeholder data for SOG/COG/DEPTH and route summary; add callbacks for actions.
4. Add widget/golden tests for layout at mobile and tablet sizes.
5. Integrate provider data once FEAT-002/boat tracking is available.
6. Document codebase map updates and link navigation entry points from main navigation.

### Dependencies (FEAT-016)

- Depends on FEAT-001 map container and FEAT-015 design system components.
- Consumes data from Settings/Map/Boat providers when wired.

### Definition of done (FEAT-016)

- Navigation mode accessible from navigation/sidebar entry point.
- Orbs, info card, and action bar render without overflow at supported breakpoints.
- Action callbacks stubbed with TODOs until backend wiring is available.
- Tests cover layout presence and glass styling.
