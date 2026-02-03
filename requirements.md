# Requirements - FEAT-001 Interactive Map Display

## User story

As a navigator, I want an interactive nautical map with smooth pan/zoom/rotate and offline tile caching so that I can explore my current area reliably at sea.

## Acceptance criteria (EARS)

- WHEN the app starts, THE SYSTEM SHALL render the map surface within the main screen.
- WHEN the user pans or zooms, THE SYSTEM SHALL update the map at 60 FPS without UI jank.
- WHEN the user rotates the map, THE SYSTEM SHALL rotate the map view and keep overlays aligned via `ProjectionService`.
- WHEN the network is unavailable, THE SYSTEM SHALL render cached tiles for previously visited regions.
- WHEN map tiles are unavailable and no cache exists, THE SYSTEM SHALL show a non-blocking error state and allow retry.
- WHEN the user exceeds zoom limits, THE SYSTEM SHALL clamp zoom between levels 1 and 20.
- WHEN map tiles are fetched, THE SYSTEM SHALL store them in cache with a size limit of 500MB and LRU eviction.
- IF a map request exceeds the timeout, THEN THE SYSTEM SHALL retry with backoff and fall back to cache.

## Constraints

- All coordinate transforms MUST route through `ProjectionService` (EPSG:3857 ↔ EPSG:4326).
- State must live in Provider hierarchy with no circular dependencies.
- Map implementation must stay under 300 lines per file/provider.

## Out of scope (this increment)

- Weather overlays, NMEA input, boat tracking, timeline playback.

---

## FEAT-002 GPS Position & Boat Tracking

### User story (FEAT-002)

As a navigator, I want real-time GPS position tracking with boat marker and track history so that I can monitor my vessel's movement and see where I've been.

### Acceptance criteria (FEAT-002, EARS)

- WHEN NMEA GPGGA/GPRMC data is received, THE SYSTEM SHALL extract latitude, longitude, speed, and course.
- WHEN position updates arrive, THE SYSTEM SHALL render a boat marker overlay on the map at the correct geographic position.
- WHEN the boat moves, THE SYSTEM SHALL add breadcrumb points to a track history with timestamps.
- WHEN track history exceeds 1000 points, THE SYSTEM SHALL apply LRU eviction to maintain memory limits.
- WHEN GPS signal is lost or accuracy degrades, THE SYSTEM SHALL show visual indicator on boat marker without blocking UI.
- WHEN the user taps MOB (Man Overboard), THE SYSTEM SHALL capture current position as a waypoint and persist it.
- IF position jumps unrealistically (>50 m/s), THEN THE SYSTEM SHALL filter it per ISS-018 workaround.

### Constraints (FEAT-002)

- Must use `BoatProvider` (Layer 2) depending on `NMEAProvider` and `MapProvider`.
- All position updates must flow through provider state; no direct widget state.
- Track overlay must use `ProjectionService` for lat/lng → screen coordinate conversion.
- Keep files under 300 lines per Architecture Rule C.5.

### Out of scope (FEAT-002)

- Kalman filtering for GPS smoothing (future enhancement).
- Route planning or waypoint navigation (separate feature).

---

## FEAT-003 Weather Overlays (Basic)

### User story (FEAT-003)

As a navigator, I want wind vector and wave overlays on the map so that I can visualize current weather conditions spatially.

### Acceptance criteria (FEAT-003, EARS)

- WHEN the map viewport changes, THE SYSTEM SHALL fetch weather data for visible bounds from Open-Meteo API.
- WHEN weather data is available, THE SYSTEM SHALL render wind arrows with Beaufort scale coloring.
- WHEN the user toggles wind overlay, THE SYSTEM SHALL show/hide wind vectors without reloading data.
- WHEN network is unavailable, THE SYSTEM SHALL display cached weather data with staleness indicator.
- WHEN weather fetch fails, THE SYSTEM SHALL retry 3 times with exponential backoff, then fall back to cache.
- IF cache is stale (>1 hour old), THEN THE SYSTEM SHALL show warning banner but still display data.
- WHEN wave overlay is enabled, THE SYSTEM SHALL render wave height/direction indicators (optional).

### Constraints (FEAT-003)

- Must use cache-first strategy per Architecture Rule C.4.
- All coordinate transforms through `ProjectionService` (prevents ISS-001 regression).
- Weather data refresh max 1 request per 10 seconds (debounce map pan/zoom).
- Keep overlay painters under 200 lines; extract helpers if needed.

### Out of scope (FEAT-003)

- 7-day forecast timeline (separate FEAT-004).
- Multiple weather model comparison.
- Precipitation or SST overlays.

---

## FEAT-004 Weather Forecast & Timeline

### User story (FEAT-004)

As a navigator, I want a 7-day weather forecast with timeline playback so that I can plan my route based on predicted conditions.

### Acceptance criteria (FEAT-004, EARS)

- WHEN forecast screen opens, THE SYSTEM SHALL display hourly and daily weather breakdown for 7 days.
- WHEN the user scrubs the timeline, THE SYSTEM SHALL update map overlays to show forecasted conditions for selected time.
- WHEN playback is started, THE SYSTEM SHALL animate through forecast frames at selected speed (0.5x, 1x, 2x, 4x).
- WHEN forecast frames load, THE SYSTEM SHALL keep max 5 frames in memory and lazy-load adjacent frames.
- WHEN frame cache is full, THE SYSTEM SHALL evict frames furthest from current position per ISS-013 solution.
- WHEN playback reaches end, THE SYSTEM SHALL pause and allow scrubbing backward.
- IF forecast data is unavailable, THEN THE SYSTEM SHALL show error state with retry action and use cached data if available.

### Constraints (FEAT-004)

- Must use `TimelineProvider` (Layer 3) depending on `WeatherProvider`, `MapProvider`, `SettingsProvider`.
- Lazy frame loading MANDATORY to avoid OutOfMemory (ISS-013 prevention).
- Preload next frame in background during playback for smooth transitions.
- Timeline scrubber must batch updates every 200ms (no excessive notifyListeners).

### Out of scope (FEAT-004)

- Video export of timeline playback.
- Comparison of multiple forecast models.
- Historical weather data playback.

---

## FEAT-016 Navigation Mode Screen

### User story (FEAT-016)

As a navigator, I want a dedicated navigation mode with oversized data orbs and route controls so that I can monitor critical metrics and manage routes quickly while underway.

### Acceptance criteria (FEAT-016, EARS)

- WHEN navigation mode opens, THE SYSTEM SHALL display three large data orbs for SOG, COG, and DEPTH with fallback placeholders when data is missing.
- WHEN a route is active, THE SYSTEM SHALL render the current route line and show the next waypoint name, distance, and ETA in a bottom info card.
- WHEN the user taps `+ Route`, THE SYSTEM SHALL initiate route creation and surface feedback within the navigation mode UI.
- WHEN the user taps `Mark Position`, THE SYSTEM SHALL capture the current location as a waypoint and confirm visually.
- WHEN the user taps `Track`, THE SYSTEM SHALL toggle tracking state and reflect the active state in the action bar.
- WHEN the user taps `Alerts`, THE SYSTEM SHALL present navigation warnings without blocking map interaction.
- WHEN navigation mode is exited, THE SYSTEM SHALL return to the main map without losing active route context.

### Constraints (FEAT-016)

- Must reuse `MapWebView` for the background map with overlays driven by provider state.
- UI must respect responsive breakpoints (mobile/tablet/desktop) via `ResponsiveUtils`.
- Keep files under 300 lines and dispose any controllers if added.

### Out of scope (FEAT-016)

- Persisting user-created routes to storage.
- Real-time NMEA data plumbing; uses placeholder values until FEAT-002 integration.
