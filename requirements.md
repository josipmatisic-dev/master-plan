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
