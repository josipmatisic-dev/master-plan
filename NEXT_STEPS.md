# Next Steps - Marine Navigation App (SailStream)

**Date:** 2026-02-15  
**Current Phase:** Active Development (Weather Overlays + Merge Reconciliation Complete)  
**Status:** 🟡 In Progress — Multiple Feature Branches Active

---

## Executive Summary

The app has significant implementation across multiple features, with **313 tests passing** and **0 lint warnings**. Branch `feat/weather-overlays` has been reconciled with `origin/main` (unified BoatPosition model). Three parallel Copilot CLI instances coordinate via `.copilot-coordination.md`.

### What's Done

- ✅ Core architecture (9 providers, 11 services, 8 models)
- ✅ NMEA data integration (parser, service, provider, instrument parsers)
- ✅ SailStream UI (Ocean Glass + Holographic Cyberpunk themes)
- ✅ Navigation Mode screen with data orbs, compass, XTE
- ✅ Boat position tracking (NMEA + phone GPS fallback, ISS-018 filtering)
- ✅ Weather data layer (WeatherProvider, API client, parser, timeline)
- ✅ Route management (RouteProvider, GeoUtils, RouteMapBridge)
- ✅ Settings, Dashboard, Vessel, Profile screens

### What's In Progress

- 🟡 Weather rendering (WebGL wind/wave pipeline ~30%)
- 🟡 CacheProvider backend (shell only — ISS-019)
- 🟡 MapWebView ↔ Provider full integration

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

### 2. Implement CacheProvider Backend (ISS-019)

**Status:** Shell with 7 TODOs  
**Remaining Work:**

- [ ] Implement disk-backed CacheService with LRU eviction
- [ ] Add TTL support (1-hour for weather, configurable)
- [ ] Wire CacheProvider to CacheService
- [ ] Add weather data caching
- [ ] Add tile caching for offline map support

**Key Files:** `cache_provider.dart`

### 3. MapWebView Full Integration (FEAT-001)

**Status:** WebView renders, JS bridge partially wired  
**Remaining Work:**

- [ ] Complete viewport sync (MapProvider ↔ WebView bidirectional)
- [ ] Boat marker rendering via JS bridge (data flows, rendering partial)
- [ ] Track overlay rendering via JS bridge
- [ ] Route visualization on map (RouteMapBridge exists but needs WebView wiring)

**Key Files:** `map_webview.dart`, `map_provider.dart`, `route_map_bridge.dart`, `map.html`

---

## Infrastructure & Quality

### Testing

**Current:** 313/313 tests passing, 0 lint warnings  
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

- AIS integration (collision warnings, target display)
- Anchor alarm with geofence
- Tides & currents overlay
- Offline mode (cache-first for all data)
- Trip logging and export

### Future Phases

- Harbor alerts & notifications
- Social features (trip sharing, collaborative routes)
- App store deployment (iOS + Android)
- Performance monitoring & crash reporting

---

**Last Updated:** 2026-02-15  
**Next Review:** After weather rendering pipeline completion
