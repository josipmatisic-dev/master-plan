# Design - FEAT-001 Interactive Map Display

## Architecture overview

- UI uses a `MapScreen` (future) or existing `HomeScreen` surface to host a WebView-based map container.
- A dedicated `MapProvider` (Layer 2) owns viewport state and exposes updates to UI and services.
- `ProjectionService` performs all coordinate transforms for overlays and viewport sync.
- A `MapTileCacheService` (future) handles tile caching with LRU + TTL, integrated through `CacheProvider`.

## Data flow

1. UI gesture events → `MapProvider.updateViewport()`
2. `MapProvider` emits viewport changes → WebView bridge → map engine
3. Map engine emits viewport changes → WebView bridge → `MapProvider`
4. `ProjectionService` uses viewport state for coordinate transforms
5. Tile fetch → retry/timeout → cache fallback via `CacheProvider`

## Interfaces

- `MapProvider`
  - `Viewport get viewport`
  - `Future<void> updateViewport(Viewport next)`
  - `Stream<MapError> get errors`
- `ProjectionService`
  - `Offset latLngToScreen(LatLng position, Viewport viewport)`
  - `LatLng screenToLatLng(Offset point, Viewport viewport)`

## Error handling matrix

- Timeout → retry (3x) → cache fallback → show toast/banner
- Socket error → cache fallback → show offline indicator
- Map load failure → show error state + retry action

## Testing strategy

- Unit: `ProjectionService` (EPSG math), `MapProvider` state transitions
- Widget: map container renders and responds to viewport updates
- Integration: pan/zoom/rotate and overlay alignment smoke test

## Files to add

- `marine_nav_app/lib/providers/map_provider.dart`
- `marine_nav_app/lib/services/projection_service.dart`
- `marine_nav_app/lib/widgets/map/map_webview.dart`
- Tests under `marine_nav_app/test/`

---

## FEAT-002 GPS Position & Boat Tracking

### Architecture overview (FEAT-002)

- `BoatProvider` (Layer 2) consumes `NMEAProvider` data and maintains vessel position state.
- Position updates flow: NMEA isolate → `NMEAProvider` → `BoatProvider` → UI widgets.
- Track history stored as in-memory list with LRU eviction (max 1000 points).
- Boat marker and track overlays use `ProjectionService` for coordinate conversion.

### Data flow

1. NMEA GPGGA/GPRMC parsed in isolate → `NMEAProvider.currentData` updated
2. `BoatProvider` watches `NMEAProvider` via ProxyProvider update
3. Extract lat/lng/speed/course → create `BoatPosition` model
4. Append to track history (evict old if >1000 points)
5. `notifyListeners()` triggers UI rebuild
6. Boat marker widget reads `BoatProvider.currentPosition`
7. Track overlay widget reads `BoatProvider.trackHistory`
8. ProjectionService converts lat/lng → screen pixels for rendering

### Interfaces

- `BoatProvider`
  - `BoatPosition? get currentPosition`
  - `List<BoatPosition> get trackHistory`
  - `void markMOB()` (capture current position as waypoint)
  - `void clearTrack()`
- `BoatPosition` model
  - `double latitude, longitude`
  - `double? speedKnots, courseTrue, heading`
  - `DateTime timestamp`
  - `double accuracy` (for filtering)

### Error handling (FEAT-002)

- Low accuracy (>50m) → visual indicator on boat marker, no filtering unless ISS-018 occurs
- Unrealistic jumps (>50 m/s) → filter position per ISS-018 workaround
- No GPS signal → show "No Position" state, retain last known position

### Testing strategy (FEAT-002)

- Unit: `BoatProvider` position updates, track history LRU
- Widget: Boat marker renders at correct position, track overlay draws line
- Integration: NMEA → BoatProvider → UI flow with mock NMEA data

### Files to add (FEAT-002)

- `lib/providers/boat_provider.dart`
- `lib/models/boat_position.dart`
- `lib/widgets/overlays/boat_marker.dart`
- `lib/widgets/overlays/track_overlay.dart`
- Tests under `test/unit/providers/` and `test/widget/`

---

## FEAT-003 Weather Overlays (Basic)

### Architecture overview (FEAT-003)

- `WeatherProvider` (Layer 2) manages weather data fetch and caching.
- Uses cache-first strategy: check cache → return cached + background refresh → update cache.
- `WeatherApi` service handles Open-Meteo API communication with retry/timeout.
- Overlay painters use `ProjectionService` + `Viewport` for rendering wind/wave data.

### Data flow

1. Map viewport changes → `WeatherProvider.fetchWeatherForBounds(Bounds)`
2. Check `CacheService` for cached data (key: bounds hash + timestamp)
3. If cached & fresh (<1hr old) → return immediately + schedule background refresh
4. If stale or missing → fetch from Open-Meteo API with retry
5. Parse response → `WeatherData` model (wind points, wave points)
6. Update `CacheService` with TTL=1hr
7. `notifyListeners()` → UI rebuilds overlays
8. Overlay painter iterates wind points, converts lat/lng → screen, renders arrows

### Interfaces

- `WeatherProvider`
  - `WeatherData? get currentWeather`
  - `Future<void> fetchWeatherForBounds(Bounds bounds)`
  - `void toggleOverlay(OverlayType type)` (wind, wave)
  - `bool isOverlayVisible(OverlayType type)`
- `WeatherApi`
  - `Future<WeatherData> fetchWeather(Bounds bounds)`
  - Retry: 3 attempts, exponential backoff (1s, 2s, 4s)
  - Timeout: 10 seconds per request
- `WeatherData` model
  - `List<WindPoint> windPoints` (lat, lng, speed, direction)
  - `List<WavePoint> wavePoints` (lat, lng, height, direction, period)
  - `DateTime timestamp`

### Error handling matrix (FEAT-003)

- Timeout → retry (3x) → cache fallback → show toast "Using cached data"
- Socket error → cache fallback → show offline indicator banner
- API error (4xx/5xx) → cache fallback → log error + show user-friendly message
- No cache available → show error state + retry action

### Testing strategy (FEAT-003)

- Unit: `WeatherApi` retry/timeout logic, cache-first strategy
- Unit: Beaufort scale calculation for wind coloring
- Widget: Wind overlay renders arrows at correct positions
- Integration: Map pan → weather fetch → cache → overlay pipeline

### Files to add (FEAT-003)

- `lib/providers/weather_provider.dart`
- `lib/services/weather_api.dart`
- `lib/models/weather_data.dart`
- `lib/models/wind_data.dart`
- `lib/models/wave_data.dart`
- `lib/widgets/overlays/wind_overlay.dart`
- `lib/widgets/overlays/wave_overlay.dart` (optional)
- `lib/widgets/controls/layer_toggle.dart`
- Tests under `test/unit/` and `test/widget/`

---

## FEAT-004 Weather Forecast & Timeline

### Architecture overview (FEAT-004)

- `TimelineProvider` (Layer 3) manages forecast playback state and frame loading.
- Lazy loading: max 5 frames in memory, LRU eviction, preload adjacent frames.
- `ForecastScreen` displays hourly/daily breakdown, consumes `WeatherProvider` forecast data.
- Timeline scrubber controls playback: play/pause, speed (0.5x-4x), scrub to time.

### Data flow

1. User opens forecast screen → `WeatherProvider.getForecast(location, 7 days)`
2. Fetch 168 hourly frames metadata (timestamp, bounds) from Open-Meteo
3. Store frame metadata, NOT full data (avoid ISS-013 OutOfMemory)
4. User starts playback → `TimelineProvider.play()`
5. Load current frame via `WeatherProvider.getFrameData(timestamp)`
6. Cache frame in `TimelineProvider._frameCache` (max 5 frames)
7. Preload next frame in background (frame[current+1])
8. Timer triggers frame advance based on playback speed
9. Update `MapScreen` overlays with new frame data
10. When cache full, evict frame furthest from current position

### Lazy loading strategy (critical for ISS-013 prevention)

```dart
class TimelineProvider {
  final int _maxCachedFrames = 5;
  final Map<int, WeatherFrame> _frameCache = {};
  int _currentFrameIndex = 0;
  
  Future<WeatherFrame> _loadFrame(int index) async {
    if (_frameCache.containsKey(index)) return _frameCache[index]!;
    
    // Evict if cache full
    if (_frameCache.length >= _maxCachedFrames) {
      final furthest = _getFurthestFrame(_currentFrameIndex);
      _frameCache.remove(furthest);
    }
    
    final frame = await _weatherProvider.getFrameData(index);
    _frameCache[index] = frame;
    _preloadFrame(index + 1); // Background preload
    return frame;
  }
}
```

### Interfaces

- `TimelineProvider`
  - `PlaybackState get state` (paused, playing)
  - `int get currentFrameIndex`
  - `double get playbackSpeed` (0.5x, 1x, 2x, 4x)
  - `Future<void> play()`
  - `void pause()`
  - `void seekToFrame(int frame)`
  - `void setSpeed(double speed)`
- `ForecastScreen`
  - Displays hourly/daily cards
  - Timeline scrubber at bottom
  - Play/pause/speed controls

### Error handling (FEAT-004)

- Frame load failure → retry once → show error toast, pause playback
- Memory pressure → evict all but current frame, pause playback
- API unavailable → use cached frames, show "Offline Mode" banner

### Testing strategy (FEAT-004)

- Unit: TimelineProvider lazy loading, LRU eviction
- Unit: Frame preloading logic
- Widget: Timeline scrubber interaction
- Integration: Playback → frame load → overlay update pipeline
- **Memory test:** Verify max 5 frames in memory during playback (critical)

### Files to add (FEAT-004)

- `lib/providers/timeline_provider.dart`
- `lib/screens/forecast_screen.dart`
- `lib/screens/timeline_screen.dart`
- `lib/widgets/data_displays/timeline_scrubber.dart`
- `lib/widgets/controls/timeline_controls.dart`
- `lib/widgets/cards/forecast_card.dart`
- Tests under `test/unit/providers/` and `test/widget/`

---

## FEAT-016 Navigation Mode Screen

### Architecture overview (FEAT-016)

- `NavigationModeScreen` overlays `MapWebView` with glass UI layers for data orbs, route info, and action bar.
- Reuses `NavigationSidebar` for primary nav and `DataOrb`/`TrueWindWidget` components for consistency with SailStream UI.
- Consumes provider state (SOG/COG/DEPTH, route, tracking) once wired; placeholder values acceptable until FEAT-002 data is integrated.

### Layout and responsiveness

- Uses `ResponsiveUtils` breakpoints: center-aligned orbs on mobile, padded layout on tablet/desktop.
- Sidebar pinned to left with 80px vertical padding; action bar pinned to bottom with glass card.
- All glass surfaces wrap content in `GlassCard` to maintain Ocean Glass aesthetic and 60 FPS repaint boundaries.

### Data flow (future wiring)

1. Provider state updates (SOG/COG/DEPTH/route) → `NavigationModeScreen` rebuilds data orbs and info card.
2. Action bar taps emit intents to routing/tracking handlers (to be added in provider layer).
3. Map gestures remain handled by `MapWebView`; viewport changes will forward to `MapProvider`.

### Error handling (FEAT-016)

- Missing data shows `--` placeholders in orbs and info card without blocking interactions.
- Action handlers should be resilient to null route data; ignore taps gracefully when unavailable.

### Testing strategy (FEAT-016)

- Widget test: renders orbs, sidebar, action bar, and MapWebView layers without overflow on mobile and tablet sizes.
- Golden/snapshot: layout stability for key breakpoints.
