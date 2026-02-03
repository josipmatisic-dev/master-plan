# GitHub Copilot Instructions - Marine Navigation App

## Quick context
- This repo is master planning docs; runnable Flutter app lives in
  `marine_nav_app/`.
- Read in order before coding: `docs/MASTER_DEVELOPMENT_BIBLE.md`
  (Sections A/C), `docs/AI_AGENT_INSTRUCTIONS.md`,
  `docs/KNOWN_ISSUES_DATABASE.md`, `docs/CODEBASE_MAP.md`,
  `docs/FEATURE_REQUIREMENTS.md`.
- Reuse working patterns from Section B of the Bible instead of inventing
  new ones.

## Architecture & data flow
- Single source of truth per domain; Provider is the only shared state
  mechanism.
- Provider hierarchy is strict and declared in
  `marine_nav_app/lib/main.dart` and `marine_nav_app/PROVIDER_HIERARCHY.md`:
  - Layer 0: `SettingsProvider`; Layer 1: `ThemeProvider`, `CacheProvider`;
    future Layer 2: Map/Weather.
- **All coordinate transforms must go through `ProjectionService`**
  (MapTiler = EPSG:3857, Open-Meteo = EPSG:4326); never do manual lat/lng
  math.
- Network calls must use retry + timeout + cache fallback (see Bible C.4 and
  `docs/KNOWN_ISSUES_DATABASE.md`).
- File size limit: max 300 lines per Dart file/provider; dispose
  controllers/subscriptions.

## UI system (SailStream / Ocean Glass)
- Design tokens live in `marine_nav_app/lib/theme/`
  (`colors.dart`, `text_styles.dart`, `dimensions.dart`).
- Use `GlassCard` (`lib/widgets/glass/glass_card.dart`) for frosted surfaces;
  it wraps `RepaintBoundary` for 60 FPS.
- Responsive layout helpers are in `lib/utils/responsive_utils.dart` with
  mobile/tablet/desktop breakpoints.

## Workflows & commands
- Local dev lives under `marine_nav_app/`.
- CI runs: `flutter test --coverage`,
  `flutter analyze --fatal-infos --fatal-warnings`,
  `dart format --output=none --set-exit-if-changed .`, plus
  `flutter build apk --debug` and `flutter build web`
  (see `.github/workflows/README.md`).
- Tests live in `marine_nav_app/test/`; target ≥80% coverage for new code.

## Documentation sync
- When adding files/services or changing features, update
  `docs/CODEBASE_MAP.md`, `docs/KNOWN_ISSUES_DATABASE.md`, and
  `docs/FEATURE_REQUIREMENTS.md`.
- Keep provider dependency changes documented in
  `marine_nav_app/PROVIDER_HIERARCHY.md`.
