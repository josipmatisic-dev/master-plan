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
