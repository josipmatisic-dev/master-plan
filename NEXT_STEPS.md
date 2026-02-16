# Next Steps - Marine Navigation App (SailStream)

**Date:** 2026-02-17  
**Current Phase:** Active Development (AIS + Anchor Alarm Complete)  
**Status:** 🟡 In Progress — Feature Branch feat/weather-overlays

---

## Executive Summary

The app has significant implementation across multiple features, with **419 tests passing** and **0 lint warnings/errors**. Branch `feat/weather-overlays` is 30+ commits ahead of `main` with all CI checks passing.

### What's Done

- ✅ Core architecture (10 providers, 13 services, 9 models)
- ✅ NMEA data integration (parser, service, provider, instrument parsers, TCP + UDP)
- ✅ SailStream UI (Ocean Glass + Holographic Cyberpunk themes)
- ✅ Navigation Mode screen with data orbs, compass, XTE
- ✅ Boat position tracking (NMEA + phone GPS fallback, ISS-018 filtering)
- ✅ Weather data layer (WeatherProvider, API client, parser, timeline)
- ✅ Route management (RouteProvider, GeoUtils, RouteMapBridge)
- ✅ Settings, Dashboard, Vessel, Profile screens
- ✅ Timeline playback (TimelineProvider, TimelineControls, Grid-based WeatherFrame)
- ✅ AIS vessel tracking (aisstream.io WebSocket, CPA/TCPA collision warnings, 500-target manager)
- ✅ Anchor alarm (geofence model, alarm service, BoatProvider integration, 21 tests)
- ✅ CacheProvider backend (disk-backed CacheService with LRU/TTL)
- ✅ MapProvider native migration (MapLibre controller, removed WebView bridge)

### What's In Progress

- 🟡 Weather rendering (native overlays — wind particles, wave, fog, rain, lightning)
- 🟡 AIS → UI integration (vessel markers on map, collision alerts in nav mode)
- 🟡 Anchor alarm UI (set/clear button, radius slider, drift indicator)

---

## Immediate Next Steps (Priority Order)

### 1. Complete Weather Rendering Pipeline (FEAT-004)

**Status:** Data layer ✅, Rendering ~30%
**Remaining Work:**

- [ ] Complete WebGL wind particle shader integration in `map.html`
- [ ] Wire `WindTextureGenerator` output → WebView JS bridge
- [ ] Finish wave overlay WebGL rendering
- [ ] Test weather overlay alignment with map viewport
- [ ] Performance test: 60 FPS with weather overlays active

**Key Files:** `wind_texture_generator.dart`, `map.html`, `weather_screen.dart`, `wind_overlay.dart`, `wave_overlay.dart`

### 2. Completed Milestones

**CacheProvider Backend (ISS-019)** ✅
- Implemented disk-backed CacheService with LRU/TTL
- Wired to WeatherProvider for offline support
- Fully unit tested

**Weather Data Caching (ISS-020)** ✅
- Cache-first strategy for weather API
- Grid-based frame serialization
- 1-hour TTL enforcement

**Timeline Playback Features (FEAT-005)** ✅
- `TimelineProvider` for frame management
- `TimelineControls` UI widget
- Integration with `MapWebView`

**AIS Vessel Tracking (FEAT-006)** ✅
- AisTarget model with nav status, ship categories, dimensions
- AisService WebSocket client for aisstream.io
- AisCollisionCalculator (CPA/TCPA vector-based)
- AisProvider (500ms batching, max 500 targets, auto-reconnect)
- 22 unit tests

**Anchor Alarm (FEAT-007)** ✅
- AnchorAlarm model (geofence circle, states: safe/warning/triggered)
- AnchorAlarmService (drift monitoring, radius adjustment, state transitions)
- Wired into BoatProvider (auto-checks on each position fix)
- 21 unit tests

---

## Infrastructure & Quality

### Testing

**Current:** 419/419 tests passing, 0 lint warnings/errors  
**Target:** 80%+ coverage for all new code

**Remaining:**

- [ ] Widget tests for weather/dashboard screens
- [ ] Integration tests for map → weather overlay pipeline
- [ ] Performance benchmarks for WebGL rendering

### CI/CD

**Status:** Flutter CI workflow active (`.github/workflows/flutter-ci.yml`)  
**Actions:** Test, analyze, format check, Android APK + Web build on every PR

---

## Long-Term Roadmap

### Upcoming Features

- AIS UI overlay (vessel markers on map, info panels)
- Anchor alarm UI (set/clear, radius adjustment, drift indicator)
- Tides & currents overlay
- Offline mode (cache-first for all data)
- Trip logging and export

### Future Phases

- Harbor alerts & notifications
- Social features (trip sharing, collaborative routes)
- App store deployment (iOS + Android)
- Performance monitoring & crash reporting

---

**Last Updated:** 2026-02-17  
**Next Review:** After AIS UI overlay and anchor alarm UI
