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
