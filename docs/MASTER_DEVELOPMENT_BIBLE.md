# Master Development Bible
## Marine Navigation App - Complete Development Reference

**Version:** 5.0  
**Last Updated:** 2024-02-01  
**Status:** Post-Mortem Analysis Complete

---

## Table of Contents

1. [Section A: Complete Failure Analysis](#section-a-complete-failure-analysis)
2. [Section B: Working Code Inventory](#section-b-working-code-inventory)
3. [Section C: Architecture Rules](#section-c-architecture-rules)
4. [Section D: Feature Specifications](#section-d-feature-specifications)
5. [Section E: Technical Decisions](#section-e-technical-decisions)
6. [Section F: Development Phases](#section-f-development-phases)

---

## Section A: Complete Failure Analysis

This section documents all critical failures from Attempts 1-4, their root causes, and lessons learned.

### A.1 Map Overlay Projection Mismatch (Attempt 2, Attempt 4)

**Problem:** Wind vector overlays rendered at incorrect positions when zooming/panning the map.

**Root Cause:** Multiple coordinate projection systems used inconsistently:
- MapTiler SDK uses Web Mercator (EPSG:3857)
- Wind data from Open-Meteo in WGS84 (EPSG:4326)
- Flutter overlay widgets assumed linear screen coordinates

**Failed Code Example:**
```dart
// WRONG: Direct lat/lng to pixel conversion
Widget buildWindArrow(double lat, double lng) {
  return Positioned(
    left: (lng + 180) * screenWidth / 360,  // BROKEN
    top: (90 - lat) * screenHeight / 180,   // BROKEN
    child: WindArrowWidget(),
  );
}
```

**What Went Wrong:**
1. No projection transform between coordinate systems
2. Screen position calculations didn't account for map zoom/pan state
3. WebView map and Flutter overlay had separate viewport states
4. Rotation and tilt transformations completely ignored

**Lesson Learned:** ALL coordinate conversions MUST go through a single ProjectionService that maintains viewport synchronization between WebView and Flutter overlay.

---

### A.2 God Objects and Circular Dependencies (Attempt 1, Attempt 3)

**Problem:** `MapController` grew to 2,847 lines and had circular provider dependencies.

**Root Cause:** Single class trying to manage:
- Map viewport state
- Weather data fetching
- NMEA parsing
- Boat position tracking
- Timeline playback
- User settings
- Cache management
- WebView communication

**Failed Architecture:**
```dart
class MapController extends ChangeNotifier {
  late WeatherService _weatherService;
  late NMEAService _nmeaService;
  late CacheService _cacheService;
  late SettingsService _settingsService;
  
  // _weatherService needs MapController for bounds
  // MapController needs WeatherService for overlays
  // CIRCULAR DEPENDENCY HELL
}
```

**What Went Wrong:**
1. Single Responsibility Principle violated
2. Providers depending on other providers in constructor
3. No clear data flow boundaries
4. Impossible to test in isolation
5. Changes cascaded across entire codebase

**Lesson Learned:** Maximum 300 lines per controller. Use composition over inheritance. Dependencies flow in ONE direction only.

---

### A.3 Provider Wiring Disasters (Attempt 2)

**Problem:** App crashed with "ProviderNotFoundException" on hot reload.

**Root Cause:** Incorrect provider hierarchy and missing providers in widget tree.

**Failed Code:**
```dart
// WRONG: Provider created inside widget build
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(  // RECREATED ON EVERY BUILD
      create: (_) => MapViewModel(),
      child: Consumer<MapViewModel>(
        builder: (context, model, _) {
          // Accessing WeatherProvider that doesn't exist here
          final weather = context.read<WeatherProvider>();
          return Container();
        },
      ),
    );
  }
}
```

**What Went Wrong:**
1. Providers created inside widget build methods
2. Provider hierarchy not matching consumption hierarchy
3. ProxyProvider chains too deep (7 levels)
4. Hot reload destroying provider state

**Lesson Learned:** ALL providers created at app root in main.dart. Use Provider.of with listen: false for one-time reads. Document provider dependency graph.

---

### A.4 Cache Invalidation Race Conditions (Attempt 3)

**Problem:** Stale weather data displayed after fetching new data.

**Root Cause:** Multiple cache layers with no coordination:
- In-memory Map cache
- Disk cache via path_provider
- HTTP cache headers
- WebView cache

**Failed Code:**
```dart
Future<WeatherData> getWeather(Bounds bounds) async {
  // Check memory cache
  if (_memoryCache.containsKey(bounds)) {
    return _memoryCache[bounds]!;  // STALE DATA
  }
  
  // Fetch new data
  final data = await _api.fetchWeather(bounds);
  
  // Update cache (no invalidation of related caches)
  _memoryCache[bounds] = data;
  
  // Disk cache still has old data
  // WebView still showing old overlay
  return data;
}
```

**What Went Wrong:**
1. No cache versioning or timestamps
2. Bounds-based keys didn't account for zoom level differences
3. No cache invalidation cascade
4. Time-based expiry not implemented
5. Cache size limits never enforced (grew to 500MB+)

**Lesson Learned:** Single CacheService with LRU eviction, TTL, and version tags. All caches invalidate together.

---

### A.5 UI Overflow and RenderBox Errors (All Attempts)

**Problem:** "RenderFlex overflowed by 347 pixels" errors on smaller devices.

**Root Cause:** Fixed-size widgets and hardcoded dimensions.

**Failed Code:**
```dart
// WRONG: Fixed heights and no overflow handling
Column(
  children: [
    Container(height: 200, child: MapView()),
    Container(height: 150, child: WeatherChart()),
    Container(height: 100, child: BoatInfo()),
    Container(height: 120, child: Controls()),
    // Total: 570px, but screen is only 667px with status bar
  ],
)
```

**What Went Wrong:**
1. No Flexible or Expanded widgets
2. SafeArea not used
3. No responsive breakpoints
4. Text didn't wrap
5. Landscape mode never tested

**Lesson Learned:** Use Flexible/Expanded everywhere. Test on smallest target device (iPhone SE: 667×375). Use LayoutBuilder for responsive design.

---

### A.6 Memory Leaks from Animation Controllers (Attempt 2, Attempt 3)

**Problem:** Memory usage climbing 50MB every minute, app crashes after 20 minutes.

**Root Cause:** AnimationController not disposed, TickerProviders accumulating.

**Failed Code:**
```dart
class WindArrowWidget extends StatefulWidget {
  @override
  _WindArrowWidgetState createState() => _WindArrowWidgetState();
}

class _WindArrowWidgetState extends State<WindArrowWidget> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    )..repeat();  // NEVER DISPOSED
  }
  
  // Missing dispose() method
}
```

**What Went Wrong:**
1. AnimationControllers created but never disposed
2. Listeners not removed from providers
3. StreamSubscriptions not cancelled
4. Image cache not cleared
5. Hundreds of zombie ticker objects

**Lesson Learned:** EVERY controller/subscription MUST have dispose(). Use lint rules to enforce. Run memory profiler regularly.

---

### A.7 State Management Chaos (Attempt 1, Attempt 4)

**Problem:** App state inconsistent across screens, duplicate API calls, phantom updates.

**Root Cause:** Mixing setState, Provider, and StreamBuilder with no clear pattern.

**What Went Wrong:**
1. Three sources of truth for position data
2. No synchronization between approaches
3. Widget rebuilding excessively
4. State not persisting across navigation
5. Impossible to debug

**Lesson Learned:** ONE state management approach (Provider). Local setState only for pure UI state. Document data flow.

---

### A.8 WebView JavaScript Bridge Sync Issues (Attempt 3, Attempt 4)

**Problem:** Map movements in WebView not triggering Flutter overlay updates for 2-3 seconds.

**Root Cause:** Async communication between WebView and Flutter with no debouncing.

**What Went Wrong:**
1. 60+ messages per second during pan
2. No debouncing or throttling
3. Message queue backed up
4. JSON serialization overhead
5. Overlay updates lagging behind map

**Lesson Learned:** Debounce map events (200ms). Use requestAnimationFrame. Batch updates.

---

### A.9 NMEA Parsing Buffer Overflows (Attempt 2)

**Problem:** App crash when connecting to AIS receiver with high message rate.

**Root Cause:** Synchronous parsing of NMEA sentences in UI thread.

**What Went Wrong:**
1. Network I/O on main thread
2. String parsing blocking UI
3. notifyListeners called excessively
4. No backpressure handling
5. Memory buffer unlimited size

**Lesson Learned:** Use Isolate for NMEA parsing. Batch updates every 200ms. Implement backpressure.

---

### A.10 Offline Mode Data Consistency (Attempt 4)

**Problem:** App showed "No connection" error even with locally cached data.

**Root Cause:** No offline-first architecture, cache only used as fallback.

**What Went Wrong:**
1. Network-first instead of cache-first
2. No stale-while-revalidate pattern
3. Cache not pre-populated
4. No offline indicator to user
5. Critical features required network

**Lesson Learned:** Cache-first architecture. Background sync. Pre-download common areas.

---

## Section B: Working Code Inventory

See AI_AGENT_INSTRUCTIONS.md for detailed working code patterns (B.1-B.8).

Key working components:
- NMEA Parser with checksum validation
- HTTP client with exponential backoff
- LRU disk cache with TTL
- Web Mercator projection service
- Viewport synchronization model
- Beaufort scale calculator
- Marine theme system
- WebView JavaScript integration

---

## Section C: Architecture Rules

### C.1 Single Source of Truth
Each piece of data has exactly ONE authoritative source. No duplicate state across providers, widgets, or caches.

### C.2 Projection Consistency
ALL coordinate transformations go through ProjectionService. No manual lat/lng to pixel math.

### C.3 Provider Discipline
- Maximum 3 dependency layers
- No circular dependencies
- All providers created in main.dart
- Document dependency graph

### C.4 Network Request Discipline
- All requests use RetryableHttpClient
- All requests have timeout (10s default)
- All requests have cache fallback
- Proper error handling (Timeout, Socket, API errors)

### C.5 File Size Limits
- Maximum 300 lines per file
- Maximum 50 lines per method
- Refactor before adding features

### C.6 Overlay Rendering Pipeline
1. Data in WGS84
2. Transform to Web Mercator
3. Convert to screen pixels with Viewport
4. Apply rotation/tilt
5. Render to Canvas
6. Update only on data/viewport change

### C.7 Timeline Playback Control
- Max 100 frames in memory
- Lazy loading
- Pauseable
- Speed controls (0.5x, 1x, 2x, 4x)
- Saved progress

### C.8 Cache Invalidation Strategy
- Version tags
- Time-based expiry (TTL)
- LRU eviction
- Coordinated invalidation

### C.9 No Demo Code in Production
Remove all hardcoded keys, mocks, debug prints, test shortcuts before release.

### C.10 Dispose Everything
Every controller, subscription, listener, timer MUST be disposed.

---

## Section D: Feature Specifications

### D.1 Core Features (Must Have - Phase 1)
- **Map Display:** Interactive map with zoom/pan/rotate, nautical charts, satellite, depth contours
- **NMEA Integration:** GPS position, speed, course, heading, depth, wind
- **Boat Tracking:** Real-time GPS, track history, speed display, ETA, MOB marker
- **Weather Overlays:** Wind vectors, wave height/direction, currents, SST, precipitation

### D.2 Essential Features (Should Have - Phase 2)
- **Weather Forecasting:** 7-day forecast, hourly breakdown, model comparison, confidence
- **Timeline Playback:** Scrub forecast, play/pause, speed controls, export video
- **Dark Mode:** Auto/manual toggle, red light mode, custom schemes
- **Offline Mode:** Download regions, cache weather, offline routing, sync

### D.3 Advanced Features (Nice to Have - Phase 3)
- **Settings:** Units (metric/imperial/nautical), language, map styles, refresh rates
- **Harbor Alerts:** Approaching notifications, marina info, fuel prices, warnings
- **AIS Integration:** Nearby vessels, collision warnings, vessel info, CPA/TCPA
- **Tides:** Tide graphs, predictions, tidal currents, moon phase

### D.4 Polish Features (Phase 3 Continued)
- **Quick Settings:** One-tap toggles, brightness, layer opacity
- **Audio Alerts:** Depth alarm, anchor drag, weather warnings, AIS collision
- **Screenshots:** Capture view, include overlays, annotations, social sharing
- **Performance:** FPS counter, memory stats, network monitor, battery tracking

### D.5 Social Features (Phase 4)
- **Trip Logging:** Auto-save, manual creation, statistics, replay, photos
- **Social Sharing:** Routes, waypoints, reports, community feeds
- **User Profiles:** Boat info, home port, sync, badges
- **Collaborative:** Shared routes, group tracking, chat, reviews

---

## Section E: Technical Decisions

### E.1 Framework: Flutter 3.16+
Cross-platform, high performance, rich ecosystem, geolocation support.

### E.2 State Management: Provider 6.1+
Official recommendation, simple DI, rebuild optimization, good DX.

### E.3 Map Engine: MapTiler SDK + WebView
Nautical chart support, vector tiles, offline capability, 3D terrain, MapLibre GL JS.

### E.4 Weather API: Open-Meteo
Free, ECMWF data, marine variables, 7-day forecasts, hourly resolution.

### E.5 Oceanographic Data: NOAA APIs
Authoritative, real-time, tides/currents, buoy data (CO-OPS, NDBC, NOS).

### E.6 Backend: Supabase
PostgreSQL+PostGIS, real-time subscriptions, auth, storage, RLS.

### E.7 Offline Strategy: Cache-First
Check cache first, return immediately, background refresh, update on success.

Storage: SQLite (structured), Hive (key-value), filesystem (tiles), SharedPreferences (settings).

---

## Section F: Development Phases

### Phase 0: Foundation (Week 1-2)
Setup, base architecture, core services, testing infrastructure.
**Deliverables:** Project init, providers, ProjectionService, CacheService, HTTP client, NMEA parser, theme, CI/CD.

### Phase 1: Core Navigation (Week 3-6)
Map display, GPS tracking, basic overlays.
**Deliverables:** MapWebView, viewport sync, GPS display, track history, wind/wave overlays, basic UI.

### Phase 2: Weather Intelligence (Week 7-10)
Weather integration, forecasting, timeline.
**Deliverables:** Open-Meteo integration, 7-day forecast, timeline scrubber, playback controls, multiple overlays, offline cache.

### Phase 3: Polish & Features (Week 11-14)
Advanced features, UI/UX, performance.
**Deliverables:** Dark mode, settings, harbor alerts, AIS, tides, audio alerts, screenshots, performance monitoring.

### Phase 4: Social & Community (Week 15-18)
Social features, launch prep.
**Deliverables:** Trip logging, social sharing, profiles, collaborative routes, app store assets, beta testing, launch plan.

---

## Appendix

### Glossary
- **AIS:** Automatic Identification System
- **NMEA:** National Marine Electronics Association
- **Web Mercator:** EPSG:3857 projection
- **WGS84:** World Geodetic System 1984
- **LRU:** Least Recently Used
- **TTL:** Time To Live
- **CPA/TCPA:** Closest Point of Approach / Time to CPA

### References
- [Flutter Docs](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [MapLibre GL JS](https://maplibre.org)
- [Open-Meteo API](https://open-meteo.com/en/docs/marine-weather-api)
- [NOAA APIs](https://tidesandcurrents.noaa.gov/api/)
- [NMEA 0183](https://www.nmea.org)

---

**Document End**
