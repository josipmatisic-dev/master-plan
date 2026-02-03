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
