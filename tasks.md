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
