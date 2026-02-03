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
